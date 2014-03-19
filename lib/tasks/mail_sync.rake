# encoding:utf-8

# need to require mailman here so that initializer is loaded
require 'mailman'

# helper class
class SharedLists::MailAndLog
  def initialize
    @info = []
    @error_count = 0
    @logger = (Mailman.config.logger or Rails.logger)
  end

  def info(msg)
    @logger.info msg
    @info << msg
  end
  def error(msg)
    @logger.error msg
    @info << msg
    @error_count += 1 
  end

  def deliver
    if @info.length > 0 and defined?(SYNC_MAIL_RESULT_TO)
      SyncMailer.sync_result(SYNC_MAIL_RESULT_TO, @info.join("\n"), @error_count).deliver
    end
  end
end

desc "Retrieve attachments from email box. Update articles."
task :sync_mail_files, [:daemon] => :environment do |t, args|
  require 'fileutils'
  require 'time'

  # run as daemon only when requested
  if args[:daemon]
    Mailman.config.ignore_stdin = false
    Mailman.config.graceful_death = true
    Mailman.config.logger = Logger.new(Rails.root.join('log', 'sync_mail_files.log'))
  else
    Mailman.config.poll_interval = 0
  end

  # if you want to poll once then exit, uncomment this line
  Mailman::Application.run do

    Supplier.mail_sync.all.each do |supplier|
      from(supplier.mail_from).subject(/#{supplier.mail_subject}/i) do
        log = SharedLists::MailAndLog.new
        log.info "Sync mail: message from #{supplier.name} at #{Time.now}"

        # get attachment
        filename = nil
        message.attachments.each do |attch|
          if attch.filename.match /\.(xls|xlsx|ods|sxc|csv|tsv|xml)$/i
            FileUtils.mkdir_p(supplier.mail_path)
            filename = "#{message.date.strftime '%Y%m%d'}_#{attch.filename.gsub(/[^-a-z0-9_\.]+/i, '_')}"
            filename = supplier.mail_path.join(filename)
            begin
              File.open(filename, "w+b", 0640) { |f| f.write attch.body.decoded }
            rescue Exception => e
              log.error "* error: could not write attachment #{filename}"
            end
          end
        end
        unless filename
          log.error "* error: no spreadsheet attachment found"
          break
        end

        # import!
        begin
          outlisted_counter, new_counter, updated_counter, invalid_articles =
              supplier.update_articles_from_file(File.new(filename))
          # show result
          log.info "* imported: #{new_counter} new, #{updated_counter} updated, #{outlisted_counter} outlisted, #{invalid_articles.size} invalid"
          invalid_articles.each do |article|
            log.error "- invalid article '#{article.name}'"
            article.errors.each do |attr, msg|
              msg.split("\n").each {|l| log.info "  · #{attr.blank? ? '' : (attr+': ')}" + l}
            end
          end
        rescue FileHelper::ConversionFailedException
          log.error"* error: could not convert spreadsheet"
        end
        log.info ''
        log.deliver
      end
    end
  end

end
