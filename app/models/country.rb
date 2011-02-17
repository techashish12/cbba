class Country < ActiveRecord::Base
  has_many :users
  has_many :articles
  has_many :contacts
  has_many :counters
  has_many :districts
  has_many :gift_vouchers
  has_many :how_tos
  has_many :regions
  has_many :special_offers
  has_many :countries_subcategories
  
  def to_s
    "#{self.id}: #{self.name}"
  end

  def featured_full_members
    User.find(:all, :include => "user_profile", :conditions => ["user_profiles.state = 'published' and users.country_id = ? and paid_photo is true and free_listing is false and users.state='active'", self.id], :order => "feature_rank", :limit => $number_full_members_on_homepage)
  end

  
  def self.default_country
    Country.find_by_country_code("nz")
  end
end
