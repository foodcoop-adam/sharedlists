require File.dirname(__FILE__) + '/../test_helper'

class FileImportTest < Test::Unit::TestCase

  # read optional parse options for file
  def self.read_options(file)
    optsfile = file.gsub(/\..*?$/, '.opts')
    File.exist?(optsfile) or return {}
    YAML::load(File.new(optsfile)).symbolize_keys
  end

  # for each file to import, add tests
  Dir.glob('test/files/*_file_*.{csv,xls,xlsx,ods,xml}') do |file|
    filename = File.basename(file).gsub '.', '_'
    type = filename.match(/(.*)_file/)[1]
    opts = read_options(file)

    if opts[:type].nil? # skip detection test when type given
      define_method "test_detect_#{filename}" do
        cls = FileHelper::detect(File.new(file), opts)
        assert_equal FileHelper::file_formats.key(cls), type
      end
    end

    define_method "test_parse_#{filename}" do
      articles = []
      FileHelper::parse(File.new(file), opts.merge({type: type})) {|a| articles << a }
      expected = normalize(read_expected(file))
      articles = normalize(articles)
      assert_equal articles.count, expected.count
      expected.zip(articles).each {|x| assert_equal x[0],x[1]}
    end

  end

  # read expected result for file
  def read_expected(file)
    expfile = file.gsub(/\..*?$/, '.yml')
    YAML::load(File.new(expfile))
  end

  # normalizes for comparison
  def normalize(article)
    if article.instance_of? Array
      return article.map {|a| normalize(a)}
    else
      # remove empty fields
      article.reject! {|k,v| v.blank?}
      # skip generated numbers
      if not article[:number].blank?
        article[:number].match(/^:/) and article.delete(:number)
      end
      # convert numeric fields to number
      [:unit_quantity,:price,:tax,:deposit,:quantity].each do |k|
        article[k] and article[k] = article[k].to_f
      end
      # remove non-content fields
      article.reject! {|k,v| k==:srcdata || k==:upload_list}
      # run through validations that may do some conversion
      article = Article.new(article)
      article.valid?
      return article.attributes.reject {|k,v| v.blank?}
    end
  end

end
