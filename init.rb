ActionView::Base.send :include, RPH::Navigation::InstanceMethods
ActionController::Base.send :extend, RPH::Navigation::ClassMethods