require 'digest/sha1'

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  include Authorization::AasmRoles

  validates_format_of :name, :with => RE_NAME_OK, :message => MSG_NAME_BAD, :allow_nil => true
  validates_length_of :name, :maximum => 100
  validates_presence_of :email, :region
  validates_length_of :email, :within => 6..100 #r@a.wk
  validates_uniqueness_of :email, :case_sensitive => false
  validates_format_of :email, :with => RE_EMAIL_OK, :message => MSG_EMAIL_BAD
  
  # Relationships
  has_and_belongs_to_many :roles
  belongs_to :region
  belongs_to :district
  has_many :articles

	#around filters
	before_create :assemble_phone_numbers

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :email, :first_name, :last_name, :password, :password_confirmation, :receive_newsletter, :professional, :address1, :address2, :district_id, :region_id, :mobile_prefix, :mobile_suffix, :phone_prefix, :phone_suffix, :category1, :category2, :category3, :free_listing, :business_name
	attr_accessor :mobile_prefix, :mobile_suffix, :phone_prefix, :phone_suffix

	def assemble_phone_numbers
		if self.class.method_defined?(:mobile=)
			self.mobile = "#{mobile_prefix}-#{mobile_suffix}"
		end
		if self.class.method_defined?(:phone=)
			self.phone = "#{phone_prefix}-#{phone_suffix}"
		end
	end

	def validate
		if self.class.method_defined?(:professional?) && self.class.method_defined?(:free_listing?) && professional? && free_listing?
			if district_id.blank?
				errors.add(:district_id, "can't be blank")
			end
			if business_name.blank?
				errors.add(:business_name, "can't be blank")
			end
		end
	end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(email, password)
    u = find_in_state :first, :active, :conditions => { :email => email } # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end
  
  # Check if a user has a role.
  def has_role?(role)
    list ||= self.roles.map(&:name)
    list.include?(role.to_s) || list.include?('admin')
  end

  def name
    "#{first_name.capitalize} #{last_name.capitalize}"
  end
  
  protected
    
  def make_activation_code
    self.deleted_at = nil
    self.activation_code = self.class.make_token
  end
end
