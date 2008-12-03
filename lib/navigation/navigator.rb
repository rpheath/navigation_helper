module RPH
  module Navigation
    # Navigation class is used to extract some of the cruft out of the helper itself
    # 
    # If you need to extend the functionality, add methods to the Navigation class as
    # the navigation helper generates a new instance of this class
    class Navigator	
      include Error
      
      def initialize(sections, options)
        @sections, @options = sections, options

        validate_sections!
        update_routes! if has_custom_routes?
        fill_subtitles! if has_subtitles?
      end
      
    private      
      # loads the SUBTITLES constant with key/value relationships for section/subtitle
      def fill_subtitles!
        @sections.in_groups_of(2) { |group| SUBTITLES[group.first] = group.last }
      end
	    
      # assumes that if any of the items are strings, subtitles are present
      def has_subtitles?
        @sections.any? { |section| section.is_a?(String) }
      end
      
      # updates the ROUTES hash with the user-defined route
      def update_routes!
        @sections.each_with_index do |section, index|
          next unless section.is_a?(Hash)
          
          # make sense of the key/value pair
          tab, route = section.keys.first, section.values.first
          
          # set the custom route
          ROUTES[tab] = route
          
          # ensure that @sections doesn't gets rid of that hash
          # (we don't need it anymore)
          @sections[index] = tab
        end
      end
      
      # assumes that if any item is a Hash, it must have a custom route
      def has_custom_routes?
        @sections.any? { |section| section.is_a?(Hash) }
      end
			
      def requires_authorization?
        @options.has_key?(:authorize) && !@options[:authorize].blank?
      end
	
      def authorize_all?(methods)
        return false if methods.blank?
        methods.size == 1 && methods.first == :all
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
	  
	  protected
	    # distinguishes between sections and subtitles, returning sections
      def parse(sections)
        returning(temp = []) do
          sections.each_with_index do |section, index|
            temp << section if section.is_a?(Symbol) && index.even?
          end
        end
      end
  
      # ensures that the links passed in are valid
      def validate_sections!
        raise(InvalidSections, InvalidSections.message) unless sections_is_an_array?
        if has_subtitles?
          raise(InvalidArrayCount, InvalidArrayCount.message) unless one_to_one_match_for_sections_and_subtitles?
        end
        raise(InvalidType, InvalidType.message) unless valid_types?
      end
	  
	  public
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
        link.to_s.titleize
      end
	
      # returns the method used for checking if links are allowed to
      # be added to the list (defaults to <tt>logged_in?</tt> method)
      def authorization_method
        @options.has_key?(:authorize) && @options.has_key?(:with) ? @options[:with] : :logged_in?
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
  
      # returns the additional CSS class to be set on all authorized links
      def authorized_css
        return '' if methods_to_authorize.blank?
        @options[:authorized_css] ||= 'authorized_nav_link'
      end
    end
  end
end