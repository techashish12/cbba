require File.dirname(__FILE__) + '/../test_helper'

class MassEmailTest < ActiveSupport::TestCase
  fixtures :all

  def test_deliver
		ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    
    test_password = mass_emails(:test_password)
    test_password.recipients_full_members = true
    test_password.deliver
    assert_equal User.active.full_members.size, ActionMailer::Base.deliveries.size
    assert_equal "<br/>#{User.active.full_members.map(&:name_with_email).join('<br/>')}", test_password.sent_to
  end

  def test_unknown_attributes
    assert_equal ["bla"], mass_emails(:unknown_attributes).unknown_attributes(users(:cyrille))
  end

  def test_transformed_body
    assert_equal "This is 10% my friend", mass_emails(:test_transformed).transformed_body(users(:cyrille))
  end

  def test_transformed_body2
    assert_equal "Dear Cyrille,<br/><br/>This email is a test. Your company Bioboy Inc is now on beamazing. Your email is:<br/>cbonnet99@yahoo.fr<br/><br/>", mass_emails(:test_email).transformed_body(users(:cyrille))
  end
  
  def test_transformed_body_password
    cyrille = users(:cyrille)
    old_password_salt = cyrille.salt
    old_crypted_password = cyrille.crypted_password
    assert mass_emails(:test_password).transformed_body(users(:cyrille)).starts_with?("This is your new password:")
    cyrille.reload
    assert old_crypted_password != cyrille.crypted_password
  end
  
  def test_transformed_body_profile
    assert_equal "This is my profile: USER_PROFILE_URL<br/><br/>", mass_emails(:test_transformed_profile).transformed_body(users(:cyrille))
  end
  
end
