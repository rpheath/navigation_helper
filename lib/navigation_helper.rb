# = NavigationHelper
# Use this plugin if you are seeking a navigation solution that keeps track of 
# the current tab or section, and returns an unordered list of links for easy
# styling in CSS.
# 
# == Installation
# You can install this plugin by issuing the following command:
#
#  ruby script/install plugin http://svn.rpheath.com/code/plugins/navigation_helper
#
# == Examples
# see the README for more details and a full list of example usage
module NavigationHelper
  SUBTITLES = {}
	
  module Errors
    class InvalidSections < RuntimeError 
      def message; "#{self.class}: Must pass an array of sections"; end
    end
    class InvalidArrayCount < RuntimeError
      def message; "#{self.class}: If using subtitles, must have 1-1 match for each section/subtitle (note: use '' if a subtitle is blank)"; end
    end
    class InvalidType < RuntimeError
      def message; "#{self.class}: Must use symbols for sections, not strings (only use strings for subtitles)"; end
    end
  end
	
  # Navigation class is used to extract some of the cruft out of the helper itself
  # 
  # If you need to extend the functionality, add methods to the Navigation class as
  # the navigation helper generates a new instance of this class
  class Navigation	
    include Errors
  
    def initialize(sections, options)
      @sections = sections
      @options = options
      validate_sections
      fill_subtitles if has_subtitles?
    end
		
    # will return the links passed in, removing subtitles if they exist
    def sections
      has_subtitles? ? parse(@sections) : @sections
    end
		
    # default behavior if subtitles are present without the <tt>:hover_text => true</tt> option
    def wants_subtitles?
      has_subtitles? && !wants_hover_text?
    end
		
    # determines if the subtitles are to be shown as link titles onhover
    def wants_hover_text?
      has_subtitles? && @options.has_key?(:hover_text) && @options[:hover_text]
    end
		
    # turns <tt>:contact_me</tt> into 'Contact Me'
    def text_for(link)
      link.to_s.humanize.split.inject([]) do |words, word|
        words << word.capitalize
      end.join(' ')
    end
		
    # returns the method used for checking if links are allowed to
    # be added to the list (defaults to <tt>logged_in?</tt> method)
    def authorization_method
      method = :logged_in?
      if @options.has_key?(:authorize)
        method = @options[:with] if @options.has_key?(:with)
      end
      method
    end
		
    # returns an array of the methods that require authorization
    # (returns all methods if <tt>[:all]</tt> is passed in)
    def methods_to_authorize
      methods = []
      if requires_authorization?
        methods = @options.values_at(:authorize).flatten
      end
      authorize_all?(methods) ? sections : methods
    end
		
    private
      # distinguishes between sections and subtitles, returning sections
      def parse(sections)
        temp = []
        sections.each_with_index do |section, index|
          temp << section if section.is_a?(Symbol) && index.even?
        end
        temp
      end
		  
      # loads the SUBTITLES constant with key/value relationships for section/subtitle
      def fill_subtitles
        @sections.in_groups_of(2) { |group| SUBTITLES[group[0]] = group[1] }
      end
			
      # assumed that if all items are symbols, subtitles are not present
      def has_subtitles?
        !@sections.all? { |section| section.is_a?(Symbol) }
      end
					
      def requires_authorization?
        @options.has_key?(:authorize) && !@options[:authorize].blank?
      end
			
      def authorize_all?(methods)
        return false if methods.blank?
        methods.size == 1 && methods[0] == :all
      end

      def validate_sections
        raise(InvalidSections, InvalidSections.new.message) unless sections_is_an_array?
        if has_subtitles?
          raise(InvalidArrayCount, InvalidArrayCount.new.message) unless one_to_one_match_for_sections_and_subtitles?
        end
        raise(InvalidType, InvalidType.new.message) unless valid_types?
      end
      
      def sections_is_an_array?
        @sections.is_a?(Array)
      end
      
      def one_to_one_match_for_sections_and_subtitles?
        @sections.size % 2 == 0
      end

      def valid_types?
        !(@sections.first.is_a?(String) || @sections.all? { |section| section.is_a?(String) })
      end
  end
	
  # InstanceMethods will be mixed in with ActionView::Base which will
  # make the navigation helper available to any view
  module InstanceMethods
    # called from any view and will return an unordered list containing
    # links to the sections passed in
    #
    # Example:
    #   <%= navigation [:home, :about, :contact_me] -%>
    #
    # ...would render...
    #
    #   <ul class="nav_bar">
    #     <li class="current"><a href="/home">Home</a></li>
    #     <li><a href="/about">About</a></li>
    #     <li><a href="/contact">Contact Me</a></li>
    #   </ul>
    #
    # Configuration Options:
    # * +authorize+ - specifies which of the sections require authorization before showing up
    #   (note: use <tt>:authorize => [:all]</tt> if all sections require authorization... i.e, an admin menu)
    # * +with+ - specifies the method to use to authorize against (defaults to <tt>logged_in?</tt> method...
    #   Note - requires the <tt>authorize</tt> option to work)
    # * +hover_text+ - specifies to use the subtitles as hovertext instead of showing up as span's under the links
    def navigation(sections, options={})
      navigation = Navigation.new(sections, options)
      items = []
      navigation.sections.each do |link|
        current_tab = controller.class.instance_variable_get("@current_tab") || controller.controller_name.to_sym
        css = (link == current_tab ? 'current' : '')
        if navigation.methods_to_authorize.include?(link)
          items << content_tag(:li, construct(navigation, link), :class => css + ' authorized_nav_link') if authorized?(navigation)
        else
          items << content_tag(:li, construct(navigation, link), :class => css)
        end
      end	
      items.blank? ? '' : content_tag(:ul, items, :class => 'nav_bar')
    end
		
    private
      # builds the actual link and determines if subtitles are present
      def construct(nav, section)
        text = nav.text_for(section)
        link = link_to(text, send("#{section.to_s.downcase}_path"))
        
        if nav.wants_hover_text?
          link = link_to(text, send("#{section.to_s.downcase}_path"), :title => SUBTITLES[section])
        elsif nav.wants_subtitles?
          link += content_tag(:span, SUBTITLES[section])
        end
  			
        link
      end
  		
      # checks if the authorization method exists, and then checks
      # the boolean value it returns
      def authorized?(navigation)
        controller.respond_to?(navigation.authorization_method) && controller.send(navigation.authorization_method)
      end 
  end
	
  # ClassMethods will be extended by ActionController::Base which will
  # make the current_tab method available to any controller inhereting 
  # from ActionController::Base
  module ClassMethods
    # used to set the current tab for any controller (defaults to current controller's name)
    # 
    # Example:
    #   class PublicController < ApplicationController
    #     current_tab :home
    #   end
    def current_tab(tab=nil)
      @current_tab = tab unless tab.nil?
      @current_tab ||= controller.controller_name.to_sym
    end
  end
end
