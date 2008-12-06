require File.dirname(__FILE__) + '/../test_helper'

class UsersControllerTest < ActionController::TestCase
	fixtures :all

  def test_show
    old_size = UserEvent.all.size
    rmoore = users(:rmoore)
    yoga = articles(:yoga)
    
    get :show, :id => rmoore.slug, :article_id => yoga.id
    assert_equal old_size+1, UserEvent.all.size
    assert_not_nil UserEvent.find(:all, :order => "logged_at desc").first.article_id
    
  end

	def test_update_password
		cyrille = users(:cyrille)
		post :update_password, {:user => {:password => "bleblete", :password_confirmation => "bleblete"  }}, {:user_id => cyrille.id }
		assert_equal "Your password has been updated", flash[:notice]
		assert_not_nil User.authenticate(cyrille.email, "bleblete")
	end

	def test_update_phone
		cyrille = users(:cyrille)
    
		post :update, {:id => "123", :user => {:phone_prefix => "06", :phone_suffix => "999999" }}, {:user_id => cyrille.id }
		assert_equal "Your details have been updated", flash[:notice]
    cyrille.reload
		assert_equal "06-999999", cyrille.phone
  end
  
	def test_update_phone2
    rmoore = users(:rmoore)
		post :update, {:id => "123", :user => {:business_name => "My biz", :phone_prefix => "09", :phone_suffix => "111111" }}, {:user_id => rmoore.id }
    puts assigns(:user).errors.inspect
		assert_equal "Your details have been updated", flash[:notice]
    rmoore.reload
		assert_equal "09-111111", rmoore.phone
	end

	def test_update_mobile
		cyrille = users(:cyrille)

		post :update, {:id => "123", :user => {:mobile_prefix => "027", :mobile_suffix => "999999" }}, {:user_id => cyrille.id }
		assert_equal "Your details have been updated", flash[:notice]
    cyrille.reload
		assert_equal "027-999999", cyrille.mobile
	end

	def test_update_mobile2
    rmoore = users(:rmoore)

		post :update, {:id => "123", :user => {:business_name => "My biz", :mobile_prefix => "021", :mobile_suffix => "999999" }}, {:user_id => rmoore.id }
		assert_equal "Your details have been updated", flash[:notice]
    rmoore.reload
		assert_equal "021-999999", rmoore.mobile
	end

	def test_update_mobile3
    norma = users(:norma)

		post :update, {:id => "123", :user => {:mobile_prefix => "021", :mobile_suffix => "999999" }}, {:user_id => norma.id }
		assert_equal "Your details have been updated", flash[:notice]
    norma.reload
		assert_equal "021-999999", norma.mobile
	end

  def test_create
		old_size = User.all.size
		district = District.first
		post :create, :user => {:email => "cyrille@stuff.com", :password => "testtest23",
      :password_confirmation => "testtest23", :district_id => district.id, :membership_type => "free_listing"}
		assert_not_nil assigns(:user)
    # # 	puts assigns(:user).errors.inspect
		assert_equal 0, assigns(:user).errors.size
		assert_equal old_size+1, User.all.size
	end
  def test_create_free_listing
		old_size = User.all.size
		district = districts(:wellington_wellington_city)
		wellington = regions(:wellington)
		post :create, :user => {:email => "cyrille@stuff.com", :password => "testtest23",
      :password_confirmation => "testtest23", :professional => true, :district_id => district.id, :mobile_prefix => "027",
      :mobile_suffix => "8987987", :business_name => "My biz", :membership_type => "free_listing"  }
		assert_not_nil assigns(:user)
    # # 	puts assigns(:user).errors.inspect
		assert_equal 0, assigns(:user).errors.size
		assert_equal old_size+1, User.all.size
		new_user = User.find_by_email("cyrille@stuff.com")
		assert_not_nil(new_user)
		assert_equal "027-8987987", new_user.mobile
		assert_equal wellington, new_user.region
	end
  def test_create_full_membership
		old_size = User.all.size
    old_tab_size = Tab.all.size
		district = districts(:wellington_wellington_city)
		wellington = regions(:wellington)
    hypnotherapy = subcategories(:hypnotherapy)
		post :create, :user => {:email => "cyrille@stuff.com", :password => "testtest23",
      :password_confirmation => "testtest23", :professional => true, :district_id => district.id, :mobile_prefix => "027",
      :mobile_suffix => "8987987", :business_name => "My biz", :membership_type => "full_member", :subcategory1_id => hypnotherapy.id   }
    assert_redirected_to "payments/new?payment_type=full_member"
		assert_not_nil assigns(:user)
#		puts assigns(:user).errors.inspect
		assert_equal 0, assigns(:user).errors.size
		assert_equal old_size+1, User.all.size
		new_user = User.find_by_email("cyrille@stuff.com")
		assert_not_nil(new_user)
		assert_equal "027-8987987", new_user.mobile
		assert_equal wellington, new_user.region
    #2 tabs: one for about cyrille and one for hypnotherapy
    assert_equal old_tab_size+2, Tab.all.size
	end
end
