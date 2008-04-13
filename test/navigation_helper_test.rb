require 'test/unit'
# require 'active_support'
# (for a frozen version of Rails...)
# require File.dirname(__FILE__) + '/../../../rails/activesupport/lib/active_support'
require File.dirname(__FILE__) + '/../lib/navigation_helper'

class NavigationHelperTest < Test::Unit::TestCase
  include NavigationHelper
	
  def setup
    @alinks = [:one, :two, :three]
    @hlinks = [:one, 'one', :two, 'two', :three, 'three']
  end
  
  def test_should_raise_invalid_sections_error
    nav = Navigation.new({:one => 'one'}, {})
  rescue Errors::InvalidSections => e
    assert_equal e.message, Errors::InvalidSections.new.message
    assert_nil nav    
  end
  
  def test_should_raise_invalid_array_count_error
    nav = Navigation.new([:one, 'one', :two], {})
  rescue Errors::InvalidArrayCount => e
    assert_equal e.message, Errors::InvalidArrayCount.new.message
    assert_nil nav
  end
  
  def test_should_raise_invalid_type_error
    nav = Navigation.new(['one', 'two', 'three', 'four'], {})
  rescue Errors::InvalidType => e
    assert_equal e.message, Errors::InvalidType.new.message
    assert_nil nav
  end
  
  def test_should_not_want_subtitles
    assert !navigation.wants_subtitles?
  end
  
  def test_should_want_subtitles
    assert subtitle_navigation.wants_subtitles?
  end
  
  def test_should_want_hover_text
    nav = subtitle_navigation(:hover_text => true)
    assert nav.wants_hover_text?
    assert !nav.wants_subtitles?
  end
  
  def test_should_still_want_subtitles
    nav = subtitle_navigation(:hover_text => false)
    assert nav.wants_subtitles?
    assert !nav.wants_hover_text?
  end
  
  def test_should_return_array_of_links
    links = subtitle_navigation.sections
    @alinks.each do |link|
      assert links.include?(link)
      assert link.is_a?(Symbol)
    end
    assert_equal @alinks - links, []
  end
  
  def test_subtitles_should_be_set
    SUBTITLES.clear
    assert_equal SUBTITLES, {}
    links = subtitle_navigation.sections
    assert_not_equal SUBTITLES, {}
    assert_equal SUBTITLES.size, links.size
    links.each do |link|
      assert SUBTITLES.has_key?(link)
    end
  end
  
  def test_should_capitalize_links_by_default
    nav = navigation
    assert_equal 'One', nav.text_for(:one)
    assert_equal 'One Two', nav.text_for(:one_two)
    assert_equal 'One Two Three', nav.text_for(:one_two_three)
  end
  
  def test_should_support_a_single_authorized_link
    nav = navigation(:authorize => [@alinks.first])
    assert_equal Array(@alinks.first), nav.methods_to_authorize
  end
  
  def test_should_support_multiple_authorized_links
    nav = navigation(:authorize => [@alinks.first, @alinks.last])
    assert_equal [@alinks.first, @alinks.last], nav.methods_to_authorize
  end
  
  def test_should_support_all_authorized_links
    nav = navigation(:authorize => [:all])
    assert_equal @alinks, nav.methods_to_authorize
  end
  
  def test_default_auth_method_should_be_logged_in
    assert_not_nil navigation.authorization_method
    assert_equal :logged_in?, navigation.authorization_method
  end
  
  def test_should_support_custom_auth_method
    nav = navigation(:authorize => [@alinks.first], :with => :auth_method)
    assert_equal :auth_method, nav.authorization_method
  end
  
  protected
    def navigation(options={})
      Navigation.new(@alinks, options)
    end
  	
    def subtitle_navigation(options={})
      Navigation.new(@hlinks, options)
    end
end