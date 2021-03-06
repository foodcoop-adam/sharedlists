class Supplier < ActiveRecord::Base
  has_many :articles, :dependent => :destroy
  has_many :user_accesses, :dependent => :destroy
  has_many :users, :through => :user_accesses
  
  # save lists in an array in database
  serialize :lists

  geocoded_by :address
  after_validation :geocode, :if => Proc.new { self.address_changed? }
  
  validates_presence_of :name, :address, :phone
  validates_presence_of :bnn_host, :bnn_user, :bnn_password, :bnn_sync, :if => Proc.new { |s| s.bnn_sync }
  validates_presence_of :mail_from, :if => Proc.new { |s| s.mail_sync }
  validates_format_of   :mail_from, :with => /^(([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\s*(,\s*|$))+$/i, :if => Proc.new { |s| s.mail_sync }

  scope :bnn_sync, :conditions => {:bnn_sync => true}
  scope :mail_sync, :conditions => {:mail_sync => true}
  
  # @return [String] BNN file directory
  def bnn_path
    Rails.root.join('supplier_assets', 'bnn_files', id.to_s)
  end
  # @return [String] Mail attachments directory
  def mail_path
    Rails.root.join('supplier_assets', 'mail_attachments', id.to_s)
  end

  # @return [Array<String>] Email addresses for (import) notifications, if any
  def mail_notify_addresses
    mail_from.split(',').map(&:strip).reject(&:blank?) unless mail_from.blank?
  end
  # @return [Regexp] Regexp for checking mail-from address for mail import
  def mail_from_regexp
    Regexp.new("^(#{Regexp.union(mail_notify_addresses).source})$") unless mail_from.blank?
  end

  def sync_bnn_files
    new_files = FtpSync::sync(self)

    unless new_files.empty?
      logger.info "New bnn files for #{name}: #{new_files.inspect}"

      new_files.each do |file|
        logger.debug "parse #{file}..."
        outlisted_counter, new_counter, updated_counter, invalid_articles =
            update_articles_from_file(File.join(bnn_path, file), type: 'bnn')
        logger.info "#{file} successfully parsed: #{new_counter} new, #{updated_counter} updated, #{outlisted_counter} outlisted, #{invalid_articles.size} invalid"
      end

      if $missing_bnn_codes
        logger.info "missing bnn-codes: #{$missing_bnn_codes.uniq.sort.join(", ")}"
      end
    end
  end
  
  # parses file and updates articles
  # returns counter for outlisted, new and updated articles
  # also returns articles, where creation or update fails (invalid_articles)
  def update_articles_from_file(file, opts={})
    
    specials = invalid_articles = Array.new
    outlisted_counter, new_counter, updated_counter = 0, 0, 0
    listed = Array.new
    upload_lists = Hash.new(0)

    FileHelper::parse(file, opts) do |parsed_article, status|
      parsed_article[:upload_list] = opts[:upload_list] if opts[:upload_list]
      upload_lists[parsed_article[:upload_list]] += 1 if parsed_article[:upload_list]

      article = articles.find_by_number(parsed_article[:number])
      # create new article
      if status.nil? and article.nil?
        new_article = articles.build(parsed_article)
        if new_article.valid? && new_article.save
          new_counter += 1
          listed << new_article.id
        else
          invalid_articles << new_article
        end

      # update existing article
      elsif status.nil? and article
        updated_counter += 1 if article.update_attributes(parsed_article)
        listed << article.id

      # delete outlisted article
      elsif status == :outlisted and article
        article.destroy && outlisted_counter += 1

      # remember special info for article; store data to allow article after its special
      elsif status == :special
        specials << article

      # mention parsing problems
      elsif status.is_a?(String)
        new_article = articles.build(parsed_article)
        new_article.valid?
        new_article.errors[''] = status
        invalid_articles << new_article

      end
    end
    
    # updates articles with special infos
    specials.each do |special|
      if article = articles.find_by_number(special[:number])
        if article.note
          article.note += " | #{special[:note]}"
        else
          article.note = special[:note]
        end
        article.save
      end
    end

    # remove unlisted articles when requested
    outlist_unlisted = (opts[:outlist_unlisted] or FileHelper::get(file, opts).outlist_unlisted)
    if outlist_unlisted
      # WARNING delete_all is fast but does not destroy associations or run callbacks
      to_delete = articles.where('id NOT IN (?)', listed)
      to_delete = to_delete.where(upload_list: upload_lists.keys()) unless upload_lists.empty?
      outlisted_counter += to_delete.delete_all
    end

    return [outlisted_counter, new_counter, updated_counter, invalid_articles]
  end

  def articles_updated_at
    articles.order('articles.updated_on DESC').first.try(:updated_on)
  end
end

# == Schema Information
#
# Table name: suppliers
#
#  id            :integer(4)      not null, primary key
#  name          :string(255)     not null
#  address       :string(255)     not null
#  phone         :string(255)     not null
#  phone2        :string(255)
#  fax           :string(255)
#  email         :string(255)
#  url           :string(255)
#  delivery_days :string(255)
#  note          :string(255)
#  created_on    :datetime
#  updated_on    :datetime
#  lists         :string(255)
#  bnn_sync      :boolean(1)      default(FALSE)
#  bnn_host      :string(255)
#  bnn_user      :string(255)
#  bnn_password  :string(255)
#

