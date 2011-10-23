
=begin

A definition of a site.

In crabgrass, 'sites' are several social networks hosted on the same rails
instance sharing a single data store. Different sites are identified by
different domain names, but all of the domains point to a single IP address.
Each site can have a unique visual appearance, it can limit the tools available
to its users, but all of their code and data is shared (of course, it's possible
to hide data between sides)

  create_table "sites", :force => true do |t|
    t.string  "name"
    t.string  "domain"
    t.string  "email_sender"
    t.integer "pagination_size",      :limit => 11
    t.integer "super_admin_group_id", :limit => 11
    t.integer "council_id",           :limit => 11
    t.text    "translators"
    t.string  "translation_group"
    t.string  "default_language"
    t.text    "available_page_types"
    t.text    "evil"
    t.boolean "tracking"
    t.boolean "default",                            :default => false
    t.integer "network_id",           :limit => 11
    t.integer "custom_appearance_id", :limit => 11
    t.boolean "has_networks",                       :default => true
    t.string  "signup_redirect_url"
    t.string  "login_redirect_url"
    t.string  "title"
    t.boolean "enforce_ssl"
    t.boolean "show_exceptions"
    t.boolean "require_user_email"
    t.boolean "never_pester_users" 		:default => false
    t.boolean "show expanded group wikis"	:default => false
    t.boolean "all_profiles_visible"	:default => false
  end

end

Example data for serialized fields:

  translators => ['blue', 'green', 'red']

  available_page_types => ['Discussion', 'Wiki', 'RateMany']

  evil => {"google_analytics"=>{"https"=>false, "enabled"=>false, "site_id"=>"UA-XXXXXX-X"}}

=end

class Site < ActiveRecord::Base

  attr_accessible :title, :default_language, :email_sender, :translation_group, :tracking, :chat, :show_exceptions, :enforce_ssl, :never_pester_users, :show_expanded_group_wikis, :available_page_types, :all_profiles_visible, :profiles, :profile_fields, :signup_mode, :require_user_email

  belongs_to :network
  belongs_to :custom_appearance, :dependent => :destroy
  belongs_to :council, :class_name => 'Group'

  has_many :groups
  serialize :translators, Array
  serialize :available_page_types, Array
  serialize :evil, Hash
  serialize :profile_fields
  serialize :profiles

  # this is evil, but used in several important places:
  # (1) for i18n, to be able to customize the strings on a per site basis
  # (2) acts_as_site_limited, to be able to automatically limit all queries
  #     to the current site.
  def self.current; Thread.current[:site]; end
  def self.current=(site); Thread.current[:site] = site; end

  ##
  ## FINDERS
  ##

  named_scope :for_domain, lambda {|domain|
    {:conditions => ['sites.domain = ? AND sites.id IN (?)', domain, Conf.enabled_site_ids]}
  }

  def self.default
    Site.find(:first, :conditions => ["sites.default = ? AND sites.id in (?)", true, Conf.enabled_site_ids])
  end

  # def stylesheet_render_options(path)
  #   {:text => "body {background-color: purple;} \n /* #{path.inspect} */"}
  # end

  ##
  ## CONFIGURATION & DEFAULT VALUES
  ##

  # we initialize the sites from the config so they can easily be turned
  # on and off

  def self.load_all_from_config(configs)
    ids = configs.map do |site_config|
      if site = Site.load_from_config(site_config)
        site.id
      else
        self.print_loading_error(site_config)
        nil
      end
    end
    self.print_available_names if ids.include?(nil)
    ids.compact
  end

  def self.load_from_config(site_config)
    site = Site.find_by_name(site_config['name'])
    site.load_config(site_config)
  end

  def self.print_loading_error(site_config)
    puts "ERROR (%s): site name '%s' not found in database!" %
    [Conf.configuration_filename, site_config['name']]
  end

  def self.print_available_names
    puts "Available site names are:"
    puts "  " + self.all.map(&:name).join(', ')
    puts "To create a site, run:\n  rake cg:site:create NAME=<name> RAILS_ENV=<env>"
  end

  # For the attributes, use the site's value first, if possible, and
  # fall back to Conf if the value is not set. We can also proxy attributes
  # which do not actually exist in the sites table but which do exist in the
  # configuration file.
  #
  # These defaults are defined in lib/crabgrass/conf.rb (and are changed by
  # whatever crabgrass.*.yml gets loaded).
  def self.proxy_to_conf(*attributes)
    attributes.each do |attribute|
      define_method(attribute) { (value = read_attribute(attribute.to_s.sub(/\?$/,''))).nil? ? Conf.send(attribute) : value }
    end
  end

  proxy_to_conf :name, :title, :pagination_size, :default_language,
    :email_sender, :email_sender_name, :available_page_types, :tracking, :evil,
    :enforce_ssl, :show_exceptions, :require_user_email, :require_user_full_info, :domain, :profiles,
    :profile_fields, :all_profiles_visible, :chat?, :translation_group, :limited?, :signup_mode, :dev_email

  # this is mostly defined in mods
  # returns site if config is valid and nil or false otherwise
  def load_config(site_config)
    self
  end

  def profile_field_enabled?(field)
    profile_fields.nil? or profile_fields.include?(field.to_s)
  end

  def profile_enabled?(profile)
    profiles.nil? or profiles.include?(profile.to_s)
  end

  def profiles=(args)
    if(args.kind_of?(Hash))
      write_attribute(:profiles, args.keys.select {|k| args[k].to_i == 1 }.map(&:to_s))
    else
      write_attribute(:profiles, args)
    end
  end

  def profile_fields=(args)
    if(args.kind_of?(Hash))
      write_attribute(:profile_fields, args.keys.select {|k| args[k].to_i == 1 }.map(&:to_s))
    else
      write_attribute(:profile_fields, args)
    end
  end

  def needs_email_verification?
    self.signup_mode == Conf::SIGNUP_MODE[:verify_email]
  end

  ##
  ## RELATIONS
  ##

  # gets all the pages for all the groups in the site
  # this does not work. network.pages only contains
  # the pages that have a group_participation by the network itself.
  #def pages
  #  pages = []
  #  self.network.pages.each do |page|
  #    pages <<  page unless pages.include?(page)
  #  end
  #  self.network.users.each do |user|
  #    user.pages.each do |page|
  #      pages << page unless pages.include?(page)
  #    end
  #  end
  #  pages
  #end

  # gets all the ids of all the groups in the site
  def group_ids
    self.groups.map{|g| g.id}
  end


  def tools_for(group)
    if group && group.group_setting.allowed_tools
      group.group_setting.allowed_tools
    else
      available_page_types
    end
  end

  ##
  ## CUSTOM STRINGS
  ##

  def string(symbol, language_code)
    nil
  end

  ##
  ## LOGGING IN
  ##

  # Where does the user go when they login? Let the site decide.
  def login_redirect(user)
    if self.login_redirect_url
      self.login_redirect_url
    elsif self.network
      '/'
    else
      {:controller => '/pages/my_work'}
     end
  end

  # if user has +access+ to site, return true.
  # otherwise, raise PermissionDenied
  def has_access!(access, user)
    if access == :admin and self.network.has_a_council?
      ok = user.member_of?(self.network.council)
    end
    ok or raise PermissionDenied.new
  end

  # TODO : find a place to define all the elements, a site's user can see
  #        (means: things, where we log, if he has already seen them)
  #

  # tells the site, that a user has seen something
  #def seen_by_user(user,element)
  # membership = self.network.memberships.find_by_user_id(user.id)
  # membership.seen ||= []
  # membership.seen.push(element).uniq
  # membership.save
  #end

  # the user forgot, that he had seen this
  #def unsee(user,element)
  #  membership = self.network.memberships.find_by_user_id(user.id)
  #  membership.seen.delete(element)
  #end

  # tells us, that a user of this site has already seen this
  #def seen_for_user?(user,element)
  #  membership = self.network.memberships.find_by_user_id(user.id)
  #  ( membership.seen && membership.seen.include?(element.to_s)) ? true : false
  #end

  ##
  ## RELATIONSHIP TO USERS
  ##

  def add_user!(user)
    if network and !user.member_of?(network)
      network.add_user!(user)
    end
  end

  ##
  ## RELATIONSHIP TO GROUPS
  ##

  def add_group!(group)
    if network and !group.member_of?(network) and group.normal?
      network.groups << group
    end
  end

end
