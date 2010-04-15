require File.dirname(__FILE__) + '/../test_helper'

class SuperAdmin
  class UserTest < ActiveSupport::TestCase
    skip_if :mod_disabled?
    fixtures :users, :sites, :groups

    def setup
      Conf.enable_site_testing
    end

    def test_mixin_is_working
      assert users(:blue).respond_to?(:superadmin?), 'the superadmin user mixin should be applied'
    end

  end
end
