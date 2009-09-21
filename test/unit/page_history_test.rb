require File.dirname(__FILE__) + '/../test_helper'

class Page_HistoryTest < Test::Unit::TestCase

  def setup
    @pepe = User.make :login => "pepe"
    @manu = User.make :login => "manu"
    @page = Page.make :stars_count => 0
    User.current = @pepe
  end

  def test_change_page_title
    @page.title = "Other title"
    @page.save!
    assert_equal 1, @page.page_history.count
    assert_equal @pepe, @page.page_history.last.user
    assert_equal PageHistory::ChangeName, @page.page_history.last.class
  end

  def test_add_star
    @upart = @page.add(@pepe, :star => true )
    @upart.save!
    @page.reload
    assert_equal 1, @page.page_history.count
    assert_equal @pepe, @page.page_history.last.user
    assert_equal PageHistory::AddStar, @page.page_history.last.class
  end

  def test_remove_star
    @upart = @page.add(@pepe, :star => true )
    @upart.save!
    @upart = @page.add(@pepe, :star => nil)
    @upart.save!
    @page.reload
    assert_equal 2, @page.page_history.count
    assert_equal @pepe, @page.page_history.last.user
    assert_equal PageHistory::RemoveStar, @page.page_history.last.class
  end  

  def test_mark_as_public
    @page.public = true
    @page.save
    assert_equal 1, @page.page_history.count
    assert_equal @pepe, @page.page_history.last.user
    assert_equal PageHistory::MakePublic, @page.page_history.last.class
  end

  def test_mark_as_private
    @page.public = false
    @page.save
    assert_equal 1, @page.page_history.count
    assert_equal @pepe, @page.page_history.last.user
    assert_equal PageHistory::MakePrivate, @page.page_history.last.class
  end

  def test_page_deleted
    @page.delete
    assert_equal 1, @page.page_history.count
    assert_equal @pepe, @page.page_history.last.user
    assert_equal PageHistory::Deleted, @page.page_history.last.class
  end

  def test_add_tag
    return true
    @page.tag_list.add("people, fight")
    assert_equal ['people', 'fight'], @page.tags
  end

  def test_remove_tag
    true
  end

  def test_add_attachment
    true
  end

  def test_remove_attachment
    true
  end

  def test_start_watching
    @upart = @page.add(@pepe, :watch => true)
    @upart.save!
    @page.reload
    assert_equal 1, @page.page_history.count
    assert_equal @pepe, @page.page_history.last.user
    assert_equal PageHistory::StartWatching, @page.page_history.last.class
  end

  def test_stop_watching
    @upart = @page.add(@pepe, :watch => true)
    @upart.save!
    @page.reload
    @upart = @page.add(@pepe, :watch => nil)
    @upart.save!
    @page.reload
    assert_equal 2, @page.page_history.count
    assert_equal @pepe, @page.page_history.last.user
    assert_equal PageHistory::StopWatching, @page.page_history.last.class
  end

  def test_share_page
    true
  end

  def test_update_content
    true
  end

  def test_add_comment
    true
  end

  def test_page_destroyed
    # hmm we need to figure out another way to store this action
    # to be notified since when the page record is destroyed all
    # hisotries are destroyed too
    true
  end

end
