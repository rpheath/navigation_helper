require File.join(File.dirname(__FILE__), 'spec_helper')
require 'active_support'

describe "NavigationHelper Plugin: Navigator class" do
  E = RPH::Navigation::Error
  N = RPH::Navigation::Navigator
  
  module NavigationSpecHelper
    def nav_without_subtitles(options={})
      N.new(@links, options)
    end
  	
    def nav_with_subtitles(options={})
      N.new(@subtitle_links, options)
    end
    
    def nav_with_custom_routes(options={})
      N.new(@custom_route_links, options)
    end
  end
      
  before(:each) do
    @links = [:one, :two, :three]
    @subtitle_links = [:one, 'one', :two, 'two', :three, 'three']
    @custom_route_links = [{:one => '/some/where'}, :two, :three]
  end
  
  describe "errors" do
    before(:each) do
      @navigation = nil
    end
    
    it "should raise InvalidSections error" do
      lambda { 
        @navigation = N.new({:one => 'one'}, {})
      }.should raise_error(E::InvalidSections, E::InvalidSections.message)
      @navigation.should be_nil    
    end
    
    it "should raise InvalidArrayCount error" do
      lambda {
        @navigation = N.new([:one, 'one', :two], {})
      }.should raise_error(E::InvalidArrayCount, E::InvalidArrayCount.message)
      @navigation.should be_nil
    end
    
    it "should raise InvalidType error" do
      lambda {
        @navigation = N.new(['one', 'two', 'three', 'four'], {})
      }.should raise_error(E::InvalidType, E::InvalidType.message)
      @navigation.should be_nil
    end
  end
  
  describe "behavior" do
    include NavigationSpecHelper
    
    before(:each) do
      @navigation = nav_without_subtitles
      @subtitle_navigation = nav_with_subtitles
      @custom_route_navigation = nav_with_custom_routes
    end
    
    it "should be an instance of NavigationHelper::Navigation" do
      [@navigation, @subtitle_navigation, @custom_route_navigation].each do |nav|
        nav.should be_an_instance_of(N)
      end
    end
    
    it "should return an array of links" do
      links = nav_without_subtitles.sections
      (@links - links).should eql([])
      links.each do |link| 
        link.is_a?(Symbol).should be_true 
      end
    end
    
    it "should parse subtitles and return an array of links" do
      links = nav_with_subtitles.sections
      (@links - links).should eql([])
      links.each do |link| 
        link.is_a?(Symbol).should be_true 
      end
    end
    
    it "should capitalize links by default" do
      nav = nav_without_subtitles
      nav.text_for(:one).should eql('One')
      nav.text_for(:one_two).should eql('One Two')
      nav.text_for(:one_two_three).should eql('One Two Three')
    end
    
    describe "subtitles" do
      before(:each) do
        @sub_titles = RPH::Navigation::SUBTITLES
        RPH::Navigation::SUBTITLES.clear
      end
      
      it "should not want subtitles" do
        @navigation.wants_subtitles?.should eql(false)
      end

      it "should want subtitles" do
        @subtitle_navigation.wants_subtitles?.should eql(true)
      end

      it "should want subtitles even if hover text is explicitly set to false" do
        nav = nav_with_subtitles(:hover_text => false)
        nav.wants_hover_text?.should eql(false)
        nav.wants_subtitles?.should eql(true)
      end

      it "should want hover text instead of subtitles" do
        nav = nav_with_subtitles(:hover_text => true)
        nav.wants_hover_text?.should eql(true)
        nav.wants_subtitles?.should eql(false)
      end
      
      it "should set subtitles" do
        links = nav_with_subtitles.sections
        @sub_titles.size.should eql(links.size)
        links.each do |link|
          @sub_titles.has_key?(link).should be_true
        end
      end
      
      it "should not set subtitles" do
        links = nav_without_subtitles.sections
        @sub_titles.should == {}
      end
    end
    
    describe "authorized links" do
      it "should support a single authorized link" do
        nav = nav_without_subtitles(:authorize => [@links.first])
        nav.methods_to_authorize.should eql([@links.first])
      end
      
      it "should support multiple authorized links" do
        nav = nav_without_subtitles(:authorize => [@links.first, @links.last])
        nav.methods_to_authorize.should eql([@links.first, @links.last])
      end
      
      it "should support authorizing all links by passing :all symbol" do
        nav = nav_without_subtitles(:authorize => [:all])
        nav.methods_to_authorize.should eql(@links)
      end
      
      it "should have an authorized CSS class" do
        nav = nav_without_subtitles(:authorize => [:all])
        nav.authorized_css.should eql('authorized_nav_link')
      end
      
      it "should support a custom authorized CSS class" do
        nav = nav_without_subtitles(:authorize => [:all], :authorized_css => 'something_else')
        nav.authorized_css.should eql('something_else')
      end
      
      it "should not have an authorized CSS class if no links are to be authorized" do
        nav_without_subtitles.authorized_css.should be_empty
      end
      
      it "should have a authorization method default of 'logged_in?'" do
        nav_without_subtitles.authorization_method.should_not be_nil
        nav_without_subtitles.authorization_method.should eql(:logged_in?)
      end
      
      it "should support a custom authorization method" do
        nav = nav_without_subtitles(:authorize => [@links.first], :with => :custom_auth_method)
        nav.authorization_method.should eql(:custom_auth_method)
      end
    end
  end  
end