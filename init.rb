require 'navigation'

ActionView::Base.send :include, RPH::Navigation::InstanceMethods
ActionController::Base.class_eval do
  extend RPH::Navigation::ClassMethods
  class_inheritable_accessor :_current_tab
end