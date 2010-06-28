class SpecialOffer < ActiveRecord::Base
  include Workflowable
  include Sluggable
  
  belongs_to :author, :class_name => "User", :counter_cache => true
  belongs_to :subcategory
  has_many :newsletters_special_offers
  has_many :newsletters, :through => :newsletters_special_offers 
  
  validates_presence_of :title, :description
  validates_length_of :description, :maximum => 600
  validates_uniqueness_of :title, :scope => "author_id", :message => "is already used for another of your special offers" 

  def summary
    short_description
  end
    
  def short_description
    if description.nil?
      ""
    else
      description[0..300]
    end
  end

  def self.all_offers(user)
    special_offers = SpecialOffer.find_all_by_author_id(user.id, :order => "state, updated_at desc")
    gift_vouchers = GiftVoucher.find_all_by_author_id(user.id, :order => "state, updated_at desc")
    offers = special_offers + gift_vouchers
    offers = offers.sort_by(&:updated_at)
    return offers.reverse!
  end
  
  def self.all_published_offers(user)
    special_offers = SpecialOffer.find_all_by_author_id_and_state(user.id, "published", :order => "published_at desc")
    gift_vouchers = GiftVoucher.find_all_by_author_id_and_state(user.id, "published", :order => "published_at desc")
    offers = special_offers + gift_vouchers
    offers = offers.sort_by(&:published_at)
    return offers.reverse!
  end
  
	def self.count_published_special_offers
	  SpecialOffer.find_all_by_state("published").size
  end

end
