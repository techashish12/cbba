require File.dirname(__FILE__) + '/../test_helper'

class UsersControllerTest < ActionController::TestCase
	fixtures :all


  def test_membership_full
    cyrille = users(:cyrille)
    get :membership, {}, {:user_id => cyrille.id }
    assert_response :success
    assert_nil assigns(:payment)
    assert_match %r{You are a full member of BeAmazing since}, @response.body
    assert_match %r{Your membership is valid until}, @response.body
  end

  def test_membership_new_pending
    pending_user = users(:pending_user)
    get :membership, {}, {:user_id => pending_user.id }
    assert_response :success
    assert_not_nil assigns(:payment)
    assert_match %r{Your membership has not been activated yet}, @response.body
  end

  def test_membership_renew_pending
    suspended_user1 = users(:suspended_user1)
    get :membership, {}, {:user_id => suspended_user1.id }
    assert_response :success
    assert_nil assigns(:payment)
    assert_match %r{Your membership has expired}, @response.body
  end

  def test_renew_membership
    cyrille = users(:cyrille)
    old_payments_size = cyrille.payments.size
    post :renew_membership, {}, {:user_id => cyrille.id }
    assert_not_nil assigns(:payment)
    assert_equal 19999, assigns(:payment).amount
    assert_redirected_to edit_payment_path(assigns(:payment))
    cyrille.reload
    assert_equal old_payments_size+1, cyrille.payments.size
    
    #the 2nd time, now payment should be created
    post :renew_membership, {}, {:user_id => cyrille.id }
    assert_not_nil assigns(:payment)
    assert_redirected_to edit_payment_path(assigns(:payment))
    cyrille.reload
    assert_equal old_payments_size+1, cyrille.payments.size

  end

  def test_index
    get :index
    assert_response :success
    assert !assigns(:full_members).blank?
  end

  def test_edit
    cyrille = users(:cyrille)
    get :edit, {}, {:user_id => cyrille.id }
    assert_response :success
  end

  def test_articles_full_member
    cyrille = users(:cyrille)
    get :articles, {}, {:user_id => cyrille.id }
    assert_response :success
  end

  def test_articles_full_member2
    amcloughlin = users(:amcloughlin)
    get :articles, {}, {:user_id => amcloughlin.id }
    assert_response :unauthorized
  end

  def test_new_photo
    cyrille = users(:cyrille)
    get :new_photo, {}, {:user_id => cyrille.id }
    assert_response :success
    #make sure that we don't have a layout as it only used as AJAX
    assert_select "div#header", :count => 0
  end

	def test_publish
		norma = users(:norma)
		ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

		post :publish, {}, {:user_id => norma.id}
		norma.user_profile.reload
		assert_not_nil norma.user_profile.published_at

    # #an email should be sent to reviewers
		assert ActionMailer::Base.deliveries.size > 0
	end
  
  def test_show
    old_size = UserEvent.all.size
    rmoore = users(:rmoore)
    cyrille = users(:cyrille)
    auckland = regions(:auckland)
    coaching = categories(:coaching)

    get :show, {:name => rmoore.slug, :region => auckland.slug, :main_expertise => coaching.slug}, {:user_id => rmoore.id }
    # #visits to own profile should not be recorded
    assert_equal old_size, UserEvent.all.size
    get :show, {:name => cyrille.slug, :region => auckland.slug, :main_expertise => coaching.slug}, {:user_id => rmoore.id }
    assert_equal old_size+1, UserEvent.all.size
  end

  def test_show2
    sgardiner = users(:sgardiner)
    auckland = regions(:auckland)
    coaching = categories(:coaching)
    get :show, {:name => sgardiner.slug, :region => auckland.slug, :main_expertise => coaching.slug  }, {:user_id => sgardiner.id }
    assert_select "input[value=Publish]"
    assert_select "a[href=/tabs/create]"
  end

  def test_show3
    cyrille = users(:cyrille)
    get :show, {:id => cyrille.slug}, {:user_id => cyrille.id }
    # #Cyrille's profile is already published: not button should be shown
    assert_select "input[value=Publish]", :count => 0
  end

  def test_show_free_listing
    amcloughlin = users(:amcloughlin)
    get :show, {:id => amcloughlin.slug}, {:user_id => amcloughlin.id }
    assert_select "a[href=/tabs/create]", 0
  end

  def test_show_draft_profile
    norma = users(:norma)
    cyrille = users(:cyrille)
    auckland = regions(:auckland)
    coaching = categories(:coaching)

    get :show, {:name => norma.slug, :region => auckland.slug, :main_expertise => coaching.slug}, {:user_id => cyrille.id }
#    puts "============= #{@response.body}"
    assert @response.body =~ /Profile coming soon/
  end

  def test_show_how_to
    improve = how_tos(:improve)
    money = how_tos(:money)
    cyrille = users(:cyrille)
    auckland = regions(:auckland)
    coaching = categories(:coaching)

    get :show, {:name => cyrille.slug, :region => auckland.slug, :main_expertise => coaching.slug, :selected_tab_id => Tab::ARTICLES, }, {:user_id => cyrille.id }
    assert !assigns(:articles).blank?
    assert assigns(:articles).include?(improve)
    assert assigns(:articles).include?(money)
  end
  
  def test_show_how_to_for_anonymous_users
    improve = how_tos(:improve)
    money = how_tos(:money)
    long = articles(:long)
    cyrille = users(:cyrille)
    auckland = regions(:auckland)
    coaching = categories(:coaching)
    
    get :show, {:name => cyrille.slug, :region => auckland.slug, :main_expertise => coaching.slug, :selected_tab_id => Tab::ARTICLES, }, { }
    assert !assigns(:articles).blank?
    assert assigns(:articles).include?(money)
    assert !assigns(:articles).include?(improve)
    assert assigns(:articles).index(money) < assigns(:articles).index(long)
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
    #    puts assigns(:user).errors.inspect
		assert_equal "Your details have been updated", flash[:notice]
    rmoore.reload
		assert_equal "09-111111", rmoore.phone
	end

	def test_update_mobile
		cyrille = users(:cyrille)
    TaskUtils.rotate_user_positions_in_subcategories
    cyrille.subcategories_users.reload
    assert_not_nil cyrille.subcategories_users[0]
    #position should not be nil
    assert_not_nil cyrille.subcategories_users[0].position
    old_position = cyrille.subcategories_users[0].position
		post :update, {:id => "123", :user => {:mobile_prefix => "027", :mobile_suffix => "999999" }}, {:user_id => cyrille.id }
		assert_equal "Your details have been updated", flash[:notice]
    cyrille = User.find_by_email(cyrille.email)
		assert_equal "027-999999", cyrille.mobile
    assert !cyrille.subcategories_users.blank?
    assert_not_nil cyrille.subcategories_users[0]
    #position should stay unchanged
    assert_not_nil cyrille.subcategories_users[0].position
    assert_equal old_position, cyrille.subcategories_users[0].position
	end

  def test_update_main_expertise
    sgardiner = users(:sgardiner)
    hypnotherapy = subcategories(:hypnotherapy)
    aromatherapy = subcategories(:aromatherapy)
    assert_equal hypnotherapy.name, sgardiner.main_expertise
		post :update, {:id => "123", :user => {:subcategory1_id => aromatherapy.id, :subcategory2_id => hypnotherapy.id}}, {:user_id => sgardiner.id }
    assert_equal 0, assigns(:user).errors.size
    sgardiner.subcategories_users.reload

    #IMPORTANT: do not reload as the reload does not go through the after_find callback...
    sgardiner = User.find_by_email(sgardiner.email)
    assert_equal aromatherapy.id, sgardiner.subcategory1_id
    assert_equal aromatherapy.name, sgardiner.main_expertise
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
    hypnotherapy = subcategories(:hypnotherapy)
		post :create, :user => {:email => "cyrille@stuff.com", :password => "testtest23", :first_name => "Cyrille", :last_name => "Stuff",
      :password_confirmation => "testtest23", :district_id => district.id, :membership_type => "free_listing",
      :subcategory1_id => hypnotherapy.id
      }
		assert_not_nil assigns(:user)
#    puts assigns(:user).errors.inspect
		assert_equal 0, assigns(:user).errors.size
		assert_equal old_size+1, User.all.size
	end
  def test_create_with_same_name
		district = District.first
    hypnotherapy = subcategories(:hypnotherapy)
		post :create, :user => {:email => "cyrille@stuff.com", :password => "testtest23", :first_name => "Cyrille", :last_name => "Bonnet",
      :password_confirmation => "testtest23", :district_id => district.id, :membership_type => "free_listing",
      :subcategory1_id => hypnotherapy.id, :business_name => "Bioboy Inc", :professional => true,
      }
		assert_not_nil assigns(:user)
#    puts assigns(:user).errors.inspect
		assert_equal 1, assigns(:user).errors.size
	end
  def test_create_free_listing
		old_size = User.all.size
		district = districts(:wellington_wellington_city)
		wellington = regions(:wellington)
    hypnotherapy = subcategories(:hypnotherapy)
		post :create, :user => {:email => "cyrille@stuff.com", :password => "testtest23",
      :password_confirmation => "testtest23", :professional => true, :district_id => district.id, :mobile_prefix => "027",
      :mobile_suffix => "8987987", :first_name => "Cyrille", :last_name => "Stuff", :membership_type => "free_listing",
      :subcategory1_id => hypnotherapy.id }
    assert_redirected_to user_membership_path
		assert_not_nil assigns(:user)
    # # 	puts assigns(:user).errors.inspect
		assert_equal 0, assigns(:user).errors.size
		assert_equal old_size+1, User.all.size
		new_user = User.find_by_email("cyrille@stuff.com")
		assert_not_nil(new_user)
		assert_equal "027-8987987", new_user.mobile
		assert_equal wellington, new_user.region
    assert new_user.active?
	end
  def test_create_full_membership
		old_size = User.all.size
		district = districts(:wellington_wellington_city)
		wellington = regions(:wellington)
    hypnotherapy = subcategories(:hypnotherapy)
		post :create, :user => {:email => "cyrille@stuff.com", :password => "testtest23",
      :password_confirmation => "testtest23", :professional => true, :district_id => district.id, :mobile_prefix => "027",
      :mobile_suffix => "8987987", :first_name => "Cyrille", :last_name => "Stuff", :membership_type => "full_member", :subcategory1_id => hypnotherapy.id   }
    assert_not_nil assigns(:payment)
    assert_redirected_to edit_payment_path(assigns(:payment))
		assert_not_nil assigns(:user)
    # # 	puts assigns(:user).errors.inspect
		assert_equal 0, assigns(:user).errors.size
		assert_equal old_size+1, User.all.size
		new_user = User.find_by_email("cyrille@stuff.com")
		assert_not_nil(new_user)
		assert_equal "027-8987987", new_user.mobile
		assert_equal wellington, new_user.region
    # #2 tabs: one for about cyrille and one for hypnotherapy
    assert_equal 2, new_user.tabs.size
	end
  def test_create_full_membership_with_error
    hypnotherapy = subcategories(:hypnotherapy)
		post :create, :user => {:email => "cyrille@stuff.com", :password => "testtest23",
      :password_confirmation => "testtest23", :professional => true, :district_id => "", :mobile_prefix => "027",
      :mobile_suffix => "8987987", :first_name => "Cyrille", :last_name => "Stuff", :membership_type => "full_member", :subcategory1_id => hypnotherapy.id   }
    assert_template "new"
#    puts @response.body
    assert_select "option[value=#{hypnotherapy.id}][selected=selected]"
		assert_not_nil assigns(:user)
    # # 	puts assigns(:user).errors.inspect
		assert_equal 1, assigns(:user).errors.size
	end
end
