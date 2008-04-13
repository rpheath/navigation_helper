ActionView::Base.send :include, NavigationHelper::InstanceMethods
ActionController::Base.send :extend, NavigationHelper::ClassMethods