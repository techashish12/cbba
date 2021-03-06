require File.dirname(__FILE__) + '/../test_helper'

class CategoryTest < ActiveSupport::TestCase

	fixtures :all

  def test_user_count_for_country
    practitioners = categories(:practitioners)
    nz = countries(:nz)
    TaskUtils.count_users
    
    assert practitioners.user_count_for_country(nz) > 0
  end

  def test_from_param
    practitioners = categories(:practitioners)
    assert_equal practitioners, Category.from_param(practitioners.name)
    assert_nil Category.from_param('')
  end

  def test_list_categories
    practitioners = categories(:practitioners)
    coaches = categories(:coaches)
		assert_equal practitioners, Category.list_categories.first
		assert_equal coaches, Category.list_categories.third
  end
end
