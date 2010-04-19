require File.expand_path(File.dirname(__FILE__) + '/../../../test/mod_test_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../../test/blueprints')

Engines::Testing.set_fixture_path

class Moderation < Mod
  migrates :users, :sites, :groups, :pages, :posts, :moderated_flags, :profiles
end

def setup_site_with_moderation
  @mod = User.make :login=>"mod"
  @mods = Group.make_owned_by :user=>@mod
  @mods.add_user! @mod
  @site = Site.make :moderation_group => @mods,
    :name => "moderation",
    :domain => "test.host"
  @mods.site = @site
end
