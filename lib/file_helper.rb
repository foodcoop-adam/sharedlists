require 'digest/sha1'
require 'tempfile'

module FileHelper

  class ConversionFailedException < Exception; end

  # return list of known file formats
  #   each file_format module has
  #   #name              return a human-readable file format name
  #   #outlist_unlisted  if returns true, unlisted articles are outlisted
  #   #detect            return a likelyhood (0-1) of being able to process
  #   #parse             parse the data
  def self.file_formats
    {
      'foodsoft' => FoodsoftFile,
      'bnn' => BnnFile,
      'borkenstein' => Borkenstein,
      'dnb_xml' => DnbXmlFile,
      'dnb_csv' => DnbCsvFile,
      'terrasana' => TerrasanaFile,
      'bdtotaal' => BdtotaalFile,
      'wimbijma' => WimbijmaCsvFile,
      'vriesia' => VriesiaFile,
      'willemdrees' => WillemdreesFile,
      'bioromeo' => BioromeoFile,
      'mattisson' => MattissonFile,
    }
  end

  # return file format, detect if needed
  def self.get(file, opts={})
    (opts[:type].nil? or opts[:type]=='auto') ? detect(file, opts) : file_formats[opts[:type]]
  end

  # detect file format
  def self.detect(file, opts={})
    file = ensure_file_format(file, opts)
    formats = file_formats.values.map {|f| file.rewind; [f, f::detect(file, opts)]}
    formats.sort_by! {|f| f[1]}
    file.rewind
    formats.last[1] < 0.5 and raise Exception.new("Could not detect file-format, please select one.")
    formats.last[0]
  end

  # parse file by type (one of #file_formats, or 'auto')
  # file is either File, Tempfile or Http::UploadedFile object
  def self.parse(file, opts={}, &blk)
    file = ensure_file_format(file, opts)
    parser = get(file, opts)
    # TODO handle wrong or undetected type
    if block_given?
      parser::parse(file, opts, &blk)
    else
      data = []
      parser::parse(file, opts) { |a| data << a }
      data
    end
  end

  # return most probable column separator character from first line
  def self.csv_guess_col_sep(file)
    seps = [",", ";", "\t", "|"]
    position = file.tell
    firstline = file.readline
    file.seek(position)
    seps.map {|x| [firstline.count(x),x]}.sort_by {|x| -x[0]}[0][1]
  end

  # read file until start of regexp
  def self.skip_until(file, regexp, maxlines=nil)
    i=0
    begin
      i += 1; return unless maxlines.nil? or i <= maxlines
      file.eof? and return nil
      position = file.tell
      line = file.readline
    end until line.match regexp
    file.seek(position)
    file
  end

  # generate an article number for suppliers that do not have one
  def self.generate_number(article)
    # something unique, but not too unique
    s = "#{article[:name]}-#{article[:unit_quantity]}x#{article[:unit]}"
    s = s.downcase.gsub(/[^a-z0-9.]/,'')
    # prefix abbreviated sha1-hash with colon to indicate that it's a generated number
    article[:number] = ':'+Digest::SHA1.hexdigest(s)[-7..-1]
    article
  end


  protected

  # make sure we have a csv for a spreadsheet, and that it's a File, and the encoding is set
  def self.ensure_file_format(file, opts)
    # catch original filename from uploaded files (see `Http::UploadedFile`)
    if file.respond_to?(:tempfile)
      filename = file.original_filename
      file = file.tempfile
    else
      filename = file.path
    end
    # convert spreadsheets
    if filename.match /\.(xls|xlsx|ods|sxc)$/i
      Rails.logger.debug "Converting spreadsheet to CSV: #{file.path}"
      # for a temporary file, we want to have a temporary file back
      if file.kind_of?(Tempfile)
        file = convert_to_csv_temp(file)
      else
        %x(libreoffice --headless --convert-to csv '#{file.path}' --outdir '#{File.dirname(file)}' >/dev/null)
        filecsv = file.path.gsub(/\.\w+$/, '.csv')
        raise ConversionFailedException unless File.exist?(filecsv)
        file = File.new(filecsv)
      end
    end
    # set encoding once
    if opts[:encoding].blank? or opts[:encoding].to_s == 'auto'
      encdet = CharDet.detect(file.read(4096))
      opts[:encoding] = encdet.encoding if encdet.confidence > 0.6
      file.rewind
    end
    file.set_encoding(opts[:encoding]) unless opts[:encoding].blank?
    file
  end

  # create a temporary csv for a spreadsheet
  def self.convert_to_csv_temp(file)
    # first store in temporary directory because libreoffice doesn't allow to specify a filename
    Dir.mktmpdir do |tmpdir|
      %x(libreoffice --headless --convert-to csv '#{file.path}' --outdir '#{tmpdir}' >/dev/null)
      filebase = File.basename(file).gsub(/\.\w+$/, '')
      filecsv = File.join(tmpdir, "#{filebase}.csv")
      raise ConversionFailedException unless File.exist?(filecsv)
      File.chmod(0600, filecsv)
      # then move csv to temporary file that can be passed around
      file = Tempfile.new(["#{filebase}.", '.csv'])
      File.open(file, 'wb') do |dst|
        File.open(filecsv, 'rb') do |src|
          dst.write src.read(4096) while not src.eof
        end
      end
      file
    end
  end

end
