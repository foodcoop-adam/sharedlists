desc "Retrieve attachments from email box. Update articles."
task :sync_mail_files => :environment do
  require 'fileutils'
  Mailman.config.poll_interval = 0
  Mailman::Application.run do
    # TODO make sure an exception in one mail does not stop processing other mails
    Supplier.mail_sync.all.each do |supplier|
      from(supplier.mail_from).subject(/#{supplier.mail_subject}/) do
        puts "Sync mail: message from #{supplier.name}"
        # get attachment
        filename = nil
        message.attachments.each do |attch|
          if attch.filename.match /\.(xls|xlsx|ods|sxc|csv|tsv|xml)$/i
            FileUtils.mkdir_p(supplier.mail_path)
            # TODO prefix filenames with date to avoid overwriting them later
            filename = supplier.mail_path.join(attch.filename.gsub(/[^-a-z0-9_\.]+/i, '_'))
            begin
              File.open(filename, "w+b", 0640) { |f| f.write attch.body.decoded }
            rescue Exception => e
              puts "- error: could not write attachment #{filename}"
            end
          end
        end
        unless filename
          puts "- error: no spreadsheet attachment found"
          break
        end
        # import!
        outlisted_counter, new_counter, updated_counter, invalid_articles =
            supplier.update_articles_from_file(File.new(filename))
        puts "- imported: #{new_counter} new, #{updated_counter} updated, #{outlisted_counter} outlisted, #{invalid_articles.size} invalid"
      end
    end
  end
end
