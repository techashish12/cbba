class AddSlugToBlogSubcategories < ActiveRecord::Migration
  def self.up
    add_column :blog_subcategories, :slug, :string
    BlogSubcategory.all.each do |s|
      s.save
    end
  end

  def self.down
    remove_column :blog_subcategories, :slug
  end
end
