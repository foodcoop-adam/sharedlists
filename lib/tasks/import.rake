# encoding:utf-8
desc "Import articles from file."
task :import, [:filename, :supplier_tag] => :environment do |t, args|
  if args.filename.blank? or args.supplier_tag.blank?
    puts "Usage: rake import <filename> <supplier id or name>"
    exit 1
  end
  supplier = Supplier.where(id: args.supplier_tag).first
  supplier = Supplier.where(name: args.supplier_tag).first if supplier.blank?
  puts "Unknown supplier" and exit 1 if supplier.blank?

  outlisted_counter, new_counter, updated_counter, invalid_articles =
      supplier.update_articles_from_file(File.new(args.filename))
  # show result
  # @todo remove code duplication with mail_sync
  puts "* imported: #{new_counter} new, #{updated_counter} updated, #{outlisted_counter} outlisted, #{invalid_articles.size} invalid"
  invalid_articles.each do |article|
    puts "- invalid article '#{article.name}'"
    article.errors.each do |attr, msg|
      msg.split("\n").each do |l|
        puts "  · #{attr.blank? ? '' : "#{attr}: "} #{l}"
      end
    end
  end
end
