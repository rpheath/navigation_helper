message = <<-MESSAGE
  
  *********************************************************************************
  Don't forget to add named routes that match the sections passed into
  the navigation helper.
  
  Example:
    <%= navigation [:home, :about, :contact_me] -%>

    # doing the above would require these named routes to exist:
    
                     # routes.rb
    home_path        # map.home '...',       :controller => '...', :action => '...'
    about_path       # map.about '...',      :controller => '...', :action => '...'
    contact_me_path  # map.contact_me '...', :controller => '...', :action => '...'
  
  Enjoy!
  *********************************************************************************
  
MESSAGE

puts message