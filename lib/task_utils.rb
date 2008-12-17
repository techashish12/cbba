class TaskUtils

  def self.mark_down_old_full_members
    User.full_members.each do |m|
      if m.member_since < 1.month.ago
        m.update_attribute(:new_user, false)
      end
    end
  end

  def self.rotate_user_positions_in_subcategories
    Subcategory.all.each do |sub|
      s_users = sub.subcategories_users.find(:all, :include => "user", :conditions => "users.free_listing is false")
#      s_users = SubcategoriesUser.find_by_sql("select su.* from subcategories_users su, users u where su.subactegsu.user_id = u.id and u.free_listing is false order by su.position")
      #if there is only 1, no rotation is needed
#      puts "========= s_users before: #{s_users.inspect}"
      unless s_users.empty? || s_users.size <= 1
        first = s_users.first
        pos = 1
        s_users.each do |su|
#          puts "====== su: #{su.inspect}"
          if su != first
#            puts "====== setting to: #{pos}"
            su.update_attribute(:position, pos)
            pos += 1
          end
        end
        #put first at the end
        first.update_attribute(:position, pos)
      end
#      puts "========= s_users after: #{s_users.inspect}"
    end    
  end

	def self.count_users
		Category.all.each do |c|
			c.update_attribute(:users_counter, User.count_all_by_subcategories(*c.subcategories))
		end
		Subcategory.all.each do |s|
			s.update_attribute(:users_counter, User.count_all_by_subcategories(s))
		end
	end

#  def self.create_default_roles
#    YAML::load(ERB.new(IO.read(File.dirname(__FILE__) +"/../test/fixtures/roles.yml")).result)
#  end

  #better to call after the exisitg users have been imported (because Norma, Julie, etc. will
  #be listed there as practicioners)
  def self.create_default_admins
    #IMPORTANT: keep the following line to make sure that the admin role exists
    Role.find_or_create_by_name("admin")
    default_region = Region.find_or_create_by_name("Wellington")
    default_district = District.find_by_name_and_region_id("Wellington City", default_region.id)
    if default_district.nil?
      default_district = District.create(:name => "Wellington City", :region_id => default_region.id  )
    end
    default_category = Category.find_or_create_by_name("Coaching")
    default_subcategory = Subcategory.find_by_category_id_and_name(default_category.id, "Life coaching")
    if default_subcategory.nil?
      default_subcategory = Subcategory.create(:name => "Life coaching", :category_id => default_category.id  )
    end
    $admins.each do |admin|
      user = User.find_by_email(admin[:email])
      if user.nil?
        user = User.new(:first_name => admin[:first_name], :last_name => admin[:last_name],
          :email => admin[:email], :free_listing => false,
          :professional => true, :subcategory1_id => default_subcategory.id,
          :membership_type => "full_member",
          :password => "monkey", :password_confirmation => "monkey",
          :receive_newsletter => false, :district_id => default_district.id  )
        if user && user.valid?
          user.register!
          user.activate!
          user.add_role("admin")
        else
          puts "Could not create user #{admin[:email]}, because of errors:"
          user.errors.full_messages.each do |m|
            puts "* #{m}"
          end
        end
      else
        if user.free_listing?
          user.update_attributes(:membership_type => "full_member", :free_listing => false )
        end
        user.add_role("admin")
      end
    end
  end
end