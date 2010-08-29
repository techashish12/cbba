class BlogCategory < ActiveRecord::Base
  include Sluggable

  has_many :blog_subcategories
  has_many :articles_blog_categories
end
