module MenuItemsHelper

  def display_menu_item(menu_item)
    if menu_item.link.blank?
      menu_item.title
    else
      link_to menu_item.title, menu_item.link
    end
  end

  def edit_menu_item_link(menu_item)
    if menu_item.may_have_children?
      link_to_modal(I18n.t(:edit),
        :title => menu_item.title,
        :url => edit_widget_menu_item_url(@widget, menu_item))
    else
      toggle_object_display(I18n.t(:edit), menu_item, :list, :form)
    end
  end

  def list_menu_items(items)
    render :partial => '/menu_items/list',
      :locals => { :menu_items => items }
  end

  def save_to_widget_link(menu_item)
    link_to_modal I18n.t(:save_button),
      :submit => 'submit',
      :title => @widget.title,
      :url => edit_widget_url(@widget)
  end

  def back_to_widget_link
    link_to_modal I18n.t(:cancel),
      :title => @widget.title,
      :url => edit_widget_url(@widget)
  end

  def submit_menu_item_link(menu_item)
    if menu_item.new_record?
      submit_link I18n.t(:add_button)
    else
      submit_link I18n.t(:save_button)
    end
  end

  def toggle_object_display(body, object, *symbols)
    link_to_function(body, nil) do |page|
      symbols.each do |sym|
        dom_id = dom_id(object, sym)
        # work around an issue with how haml creates dom_ids
        dom_id << "_new" if object.new_record?
        page.toggle dom_id
      end
    end
  end

  def destroy_menu_item_remote_function(menu_item, spinner_id)
    remote_function({
      :url => widget_menu_item_url(@widget, menu_item),
      :method => :delete,
      :update => 'menu_items_form_container',
      :loading => show_spinner(spinner_id),
      :complete => hide_spinner(spinner_id)
    })
  end

#  def edit_menu_item_remote_function(menu_item, button_id)
#    remote_function({
#      :url => {:controller => 'groups/menu_items', :action => 'edit', :id => @group.name},
#      :with => %Q['menu_item_id=' + #{menu_item.id}],
#      :loading => spinner_icon_on('pencil', button_id),
#      :complete => spinner_icon_off('pencil', button_id)
#    })
#  end

  def save_menu_item_remote_function(menu_item, spinner_id)
    remote_function({
      :url => widget_menu_item_url(@widget, menu_item),
      :loading => show_spinner(spinner_id),
      :complete => hide_spinner(spinner_id)
    })
  end

#  def cancel_add_menu_item_function(menu_item, button_id)
#    update_page do |page|
#      page.remove dom_id(menu_item)
#    end
#  end

#  def cancel_edit_menu_item_remote_function(menu_item, button_id)
#    remote_function({
#      :url => {:controller => 'groups/menu_items', :action => 'edit', :id => @group.name},
#      :with => %Q['menu_item_id=' + #{menu_item.id}],
#      :loading => spinner_icon_on('pencil', button_id),
#      :complete => spinner_icon_off('pencil', button_id)
#    })
#  end

#  def add_menu_item_button(spinner_id, disabled=false)
#    button_to_remote(I18n.t(:add_button), {
#      :url    => groups_menu_items_url(:action=>'new'),
#      :html   => {:action => groups_menu_items_url(:action=>'new')}, # non-ajax fallback
#      :loading => show_spinner(spinner_id),
#      :loaded => hide_spinner(spinner_id)
#    },
#      :id => 'add_menu_item_button'
#    )
#  end

#  def cancel_menu_item_button(spinner_id)
#    url = groups_menu_items_url(:action=>'update', :_method => :put)
#    button_to_remote I18n.t(:cancel),
#      :url      => url, # same as for the form. Update without data will just reload.
#      :html     => {:action => url}, # non-ajax fallback
#      :update => 'menu_items_list_container',
#      :loading  => show_spinner(spinner_id)
#  end

  def sort_menu_items_js(container_id, spinner_id)
    sortable_element container_id,
        :tag => 'li',
        :handle => 'menu_item_drag_handle',
        :constraint => :vertical,
        :url => sort_widget_menu_items_url(@widget),
        :method => :put,
        :loading => show_spinner(spinner_id),
        :loaded => hide_spinner(spinner_id)
  end
end