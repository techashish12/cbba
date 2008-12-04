require File.dirname(__FILE__) + '/../test_helper'

class ImporUtilsTest < ActiveSupport::TestCase

	def test_import_districts
		old_count = District.count
		ImportUtils.import_districts
		assert District.count > old_count
	end
	def test_import_users
		old_count = District.count
		ImportUtils.import_districts
		assert District.count > old_count
		old_count_users = User.count
		ImportUtils.import_users
		assert User.count > old_count_users
		user1 = User.find_by_email("info@yogaindailylife.org.nz")
		assert !user1.receive_newsletter?
		assert user1.has_role?('free_listing')
		assert !user1.subcategories.empty?
		assert !user1.categories.empty?
		assert_not_nil user1.subcategories.first.category
		user2 = User.find_by_email("annette@bodysystems.co.nz")
		assert user2.receive_newsletter?
		assert user2.has_role?('full_member')
		assert !user2.phone.blank?
		assert_not_equal "-", user2.phone
		assert_equal 'active', user2.state
	end
end