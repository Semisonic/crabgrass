class Widget < ActiveRecord::Base

  #
  # Class methods for Widget registry
  #

  def self.widgets
    if @widgets.nil?
      self.initialize_registry('widgets.yml')
    end
    @widgets ||= {}
  end

  def self.initialize_registry(filename)
    seed_filename = [RAILS_ROOT, 'config', filename].join('/')
    @widgets = YAML.load_file(seed_filename) || {}
  end

  def self.register(name, options)
    underscore = name.underscore
    prefix = underscore.sub /_widget$/, ''
    sane_defaults = {
      :icon => "/images/widgets/#{prefix}.png",
      :translation => underscore.to_sym,
      :description => "#{underscore}_description".to_sym,
      :settings => [:title],
      :columns => []
    }
    options.reverse_merge! sane_defaults
    widgets[name] = options
  end

  SECTIONS = ['main', 'sidebar', 'main_storage', 'sidebar_storage']

  def self.id_for_section(section)
    section = section.sub 'sort_list_', ''
    SECTIONS.index(section) + 1
  end

  belongs_to :profile

  serialize :options, Hash

  has_many :menu_items do

    # working around the fact that acts_as_tree does not know scopes
    # we only want to have siblings within the same widget in case
    # parent_id is nil.
    def with_siblings(menu_item)
      self.find_all_by_parent_id menu_item.parent_id
    end

    # this also makes sure all menu items belong to the same
    # widget.
    def update_order(menu_item_ids)
      menu_item_ids.each_with_index do |id, position|
        # find the menu_item with this id
        menu_item = self.find(id)
        menu_item.update_attribute(:position, position)
      end
      self
    end

  end

  # we need this for method missing - so let's make sure
  # it can get called.
  def name
    read_attribute(:name)
  end

  def options
    read_attribute(:options) or {}
  end

  def type_options
    name and Widget.widgets[name]
  end

  def validate
    if type_options.nil?
      errors.add_to_base "Invalid name #{name} for a Widget."
      return
    end
    invalid_keys = self.options.find do |k,v|
      !type_options[:settings].include?(k)
    end
    if invalid_keys.any?
      errors.add_to_base "Invalid keys #{invalid_keys.join","} for #{name}."
    end
  end

  def partial
    "widgets/#{directory}/show"
  end

  def edit_partial
    "widgets/#{directory}/edit"
  end

  def directory
    name.underscore.sub! /_widget$/, ''
  end

  def small?
    type_options and type_options[:width] == 1
  end

  def width
    if self.section == 2
      18
    elsif self.small?
      10
    else
      25
    end
  end

  def title
    self.options[:title]
  end

  def short_title
    t = self.title
    t = self.name.sub(/Widget$/, '') if t.blank?
    t.size <= self.width ? t : t[0..self.width-3] + '...'
  end

  def method_missing(method, *args)
    if type_options and type_options[:settings].include?(method)
      self.options[method]
    else
      super
    end
  end

end