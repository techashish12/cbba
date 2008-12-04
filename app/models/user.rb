require File.dirname(__FILE__) + '/../../lib/helpers'
require 'digest/sha1'

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  include Authorization::AasmRoles
	include SubcategoriesSystem
	
  validates_format_of :name, :with => RE_NAME_OK, :message => MSG_NAME_BAD, :allow_nil => true
  validates_length_of :name, :maximum => 100
  validates_presence_of :email, :district
  validates_length_of :email, :within => 6..100 #r@a.wk
#  validates_uniqueness_of :email, :case_sensitive => false
  validates_format_of :email, :with => RE_EMAIL_OK, :message => MSG_EMAIL_BAD
  
	# Relationships
  has_many :roles_users
  has_many :roles, :through => :roles_users
  belongs_to :region
  belongs_to :district
  has_many :articles
  has_many :approved_articles, :class_name => "articles"
  has_many :rejected_articles, :class_name => "articles"
	has_many :subcategories_users
	has_many :subcategories, :through => :subcategories_users
	has_many :categories_users
	has_many :categories, :through => :categories_users

	# #around filters
	before_create :assemble_phone_numbers, :set_region_from_district, :set_membership_type
	before_update :assemble_phone_numbers, :set_region_from_district, :set_membership_type

	# HACK HACK HACK -- how to do attr_accessible from here? prevents a user from
	# submitting a crafted form that bypasses activation anything else you want
	# your user to change should be added here.
  attr_accessible :email, :first_name, :last_name, :password, :password_confirmation, :receive_newsletter, :professional, :address1, :address2, :district_id, :region_id, :mobile, :mobile_prefix, :mobile_suffix, :phone, :phone_prefix, :phone_suffix, :subcategory1_id, :subcategory2_id, :subcategory3_id, :free_listing, :business_name, :suburb, :city, :membership_type
	attr_accessor :mobile_prefix, :mobile_suffix, :phone_prefix, :phone_suffix, :membership_type


  def set_membership_type
    case membership_type
    when "full_membership"
      self.free_listing=false
    else
      self.free_listing=true
    end
    #!IMPORTANT: always return true in an around filter: see http://www.dansketcher.com/2006/12/30/activerecordrecordnotsaved-before_save-problem/
    return true
  end

	def full_name
		res = name
		unless business_name.blank? || business_name == name
			res << " - #{business_name}"
		end
		return res
	end

	def self.reviewers
		User.find_by_sql("select u.* from users u, roles r, roles_users ru where u.id = ru.user_id and ru.role_id = r.id and r.name='reviewer'")
	end

	def self.find_all_by_region_and_subcategories(region, *subcategories)
		User.find_by_sql(["select u.* from users u, subcategories_users su where u.state='active' and u.id = su.user_id and u.region_id = ? and su.subcategory_id in (?) order by free_listing", region.id, subcategories])
	end

	def self.find_all_by_subcategories(*subcategories)
		User.find_by_sql(["select u.* from users u, subcategories_users su where u.state='active' and u.id = su.user_id and su.subcategory_id in (?) order by free_listing", subcategories])
	end

	def self.count_all_by_subcategories(*subcategories)
		User.count_by_sql(["select count(u.*) as count from users u, subcategories_users su where u.state='active' and u.id = su.user_id and su.subcategory_id in (?)", subcategories])
	end

	def self.search_results(category_id, subcategory_id, region_id, district_id, page)
		if subcategory_id.nil?
			if district_id.nil?
				User.paginate_by_sql(["select u.* from users u, roles_users ru, roles r, categories_users cu where u.state='active' and cu.user_id = u.id and cu.category_id = ? and u.region_id = ? and (u.free_listing is true or (r.name='full_member')) and r.id = ru.role_id and ru.user_id=u.id order by free_listing, cu.position", category_id, region_id], :page => page, :per_page => $search_results_per_page )
			else
				User.paginate_by_sql(["select u.* from users u, roles_users ru, roles r, categories_users cu where u.state='active' and cu.user_id = u.id and cu.category_id = ? and u.district_id = ? and (u.free_listing is true or (r.name='full_member')) and r.id = ru.role_id and ru.user_id=u.id order by free_listing, cu.position", category_id, district_id], :page => page, :per_page => $search_results_per_page )
			end
		else
			if district_id.nil?
				User.paginate_by_sql(["select u.* from subcategories_users su, users u, roles_users ru, subcategories s, roles r where u.state='active' and su.subcategory_id = s.id and su.user_id = u.id and s.id = ? and u.region_id = ? and (u.free_listing is true or (r.name='full_member')) and r.id = ru.role_id and ru.user_id=u.id order by free_listing, su.position", subcategory_id, region_id],  :page => page, :per_page => $search_results_per_page )
			else
				User.paginate_by_sql(["select u.* from subcategories_users su, users u, roles_users ru, subcategories s, roles r where u.state='active' and su.subcategory_id = s.id and su.user_id = u.id and s.id = ? and u.district_id = ? and (u.free_listing is true or (r.name='full_member')) and r.id = ru.role_id and ru.user_id=u.id order by free_listing, su.position", subcategory_id, district_id], :page => page, :per_page => $search_results_per_page )
			end
		end
	end

	def set_region_from_district
		unless self.district.nil?
			self.region = self.district.region
		end
	end

	def assemble_phone_numbers
		if help.blank_phone_number?(mobile)
			self.mobile = "#{mobile_prefix}-#{mobile_suffix}"
		end
		if help.blank_phone_number?(phone)
			self.phone = "#{phone_prefix}-#{phone_suffix}"
		end
	end

  def disassemble_phone_numbers
    unless phone.blank? && !phone.include?("-")
      phone_bits = phone.split("-")
      self.phone_prefix = phone_bits.first
      self.phone_suffix = phone_bits.last
    end
    unless mobile.blank? && !mobile.include?("-")
      mobile_bits = mobile.split("-")
      self.mobile_prefix = mobile_bits.first
      self.mobile_suffix = mobile_bits.last
    end
  end

	def validate
		if professional? && free_listing?
			if business_name.blank?
				errors.add(:business_name, "can't be blank")
			end
		end
	end

	# Authenticates a user by their login name and unencrypted password.  Returns
	# the user or nil.
	#
	# uff.  this is really an authorization, not authentication routine. We really
	# need a Dispatch Chain here or something. This will also let us return a human
	# error message.
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
    "#{first_name.nil? ? "" : first_name.capitalize} #{last_name.nil? ? "" : last_name.capitalize}"
  end
  
protected

  def make_activation_code
    self.deleted_at = nil
    self.activation_code = self.class.make_token
  end
end
