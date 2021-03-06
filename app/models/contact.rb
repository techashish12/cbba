class Contact < ActiveRecord::Base
  include AASM
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  include ContactSystem

  aasm_column :state
  
  aasm_initial_state :unconfirmed

  aasm_state :unconfirmed
  aasm_state :active
  aasm_state :inactive
  
  aasm_event :confirm do
    transitions :from => :unconfirmed, :to => :active
  end

  aasm_event :deactivate do
    transitions :from => :active, :to => :inactive
  end
  
  aasm_event :reactivate do
    transitions :from => :inactive, :to => :active
  end

  belongs_to :region
  belongs_to :district
  belongs_to :country

  validates_presence_of :email
  validates_format_of :name, :with => RE_NAME_OK, :message => MSG_NAME_BAD, :allow_nil => true
  validates_length_of :name, :maximum => 100
  validates_uniqueness_of :email, :case_sensitive => false
  validates_format_of :email, :with => RE_EMAIL_OK, :message => MSG_EMAIL_BAD
  validates_length_of :email, :within => 6..100 #r@a.wk
  
  named_scope :wants_newsletter, :conditions => "receive_newsletter is true"

  before_validation :generate_pwd_if_blank
  after_create :generate_activation_code, :send_confirmation_email

  def self.can_be_deleted
    Contact.find(:all, :conditions => ["state='unconfirmed' and created_at <= ?", User::DELETE_UNCONFIRMED_USERS_AFTER_IN_DAYS.days.ago])
  end

  def send_confirmation_email
    UserMailer.deliver_new_user_confirmation_email(self)
  end
  
  def generate_activation_code
    self.update_attribute(:activation_code, Digest::SHA1.hexdigest("#{email}#{Time.now}#{id}"))
  end
  
  def full_name
    "#{name} [#{email}]"
  end
  
  def send_free_tool
    UserMailer.deliver_free_tool(self)
  end
  
  def self.authenticate(email, password)
    u = User.find_in_state(:first, :active, :conditions => {:email => email})
    if u && u.authenticated?(password)
      return u
    else
      c = Contact.find_in_state(:first, :active, :conditions => {:email => email})
      if c && c.authenticated?(password)
        return c
      else
        return nil
      end
    end
  end
  
  def generate_pwd_if_blank
    if self.password.blank? && self.password_confirmation.blank?
      self.password = self.password_confirmation = self.class.generate_random_password
    end
  end
  
  def validate
    unless Contact.find_by_email(self.email).blank? && User.find_by_email(self.email).blank?
      errors.add(:email ,"is already in use. Please select a different one or select 'Password forgotten'.")
    end
  end

  def renew_token
    new_token = Digest::SHA1.hexdigest("#{email}#{Time.now}#{id}")
    self.update_attribute(:unsubscribe_token, new_token)
    return new_token
  end
  
  def full_member?
    false
  end
  
end
