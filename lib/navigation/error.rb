module RPH
  module Navigation
    module Error
      class NavigationError < RuntimeError
        # getter/setter for setting custom error messages
    	  def self.message(msg=nil);  msg.nil? ? @message : self.message = msg; end
    	  def self.message=(msg);     @message = msg;                           end
      end
      
      class InvalidSections < NavigationError 
        message "Must pass an array of sections"
      end
      class InvalidArrayCount < NavigationError
        message "If using subtitles, must have 1-1 match for each section/subtitle (note: use '' if a subtitle is blank)"
      end
      class InvalidType < NavigationError
        message "Must use symbols for sections, not strings (only use strings for subtitles)"
      end
    end
  end
end