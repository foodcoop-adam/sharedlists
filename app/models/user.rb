class User < ActiveRecord::Base

  has_many :user_accesses, :dependent => :destroy
  has_many :suppliers, :through => :user_accesses

  attr_accessible :email, :password, :password_confirmation

  attr_accessor :password
  before_save :encrypt_password

  validates_confirmation_of :password
  validates_presence_of :password, :on => :create
  validates_presence_of :email
  validates_uniqueness_of :email

  def self.authenticate(email, password)
    user = find_by_email(email)
    if user && user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      user
    else
      nil
    end
  end

  def encrypt_password
    if password.present?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, password_salt)
    end
  end

  def has_access_to?(supplier)
    admin? or !UserAccess.first(:conditions => {:supplier_id => supplier.id, :user_id => id}).nil?
  end

  def admin?
    !!admin
  end

end
