EffectiveDatatables.setup do |config|
  # Authorization Method
  #
  # This method is called by all controller actions with the appropriate action and resource
  # If the method returns false, an effective::AccessDenied Error will be raised (see README.md for complete info)
  #
  # Use via Proc (and with CanCan):
  # config.authorization_method = Proc.new { |controller, action, resource| authorize!(action, resource) }
  #
  # Use via custom method:
  # config.authorization_method = :my_authorization_method
  #
  # And then in your application_controller.rb:
  #
  # def my_authorization_method(action, resource)
  #   current_user.is?(:admin)
  # end
  #
  # Or disable the check completely:
  # config.authorization_method = false

  config.authorization_method = Proc.new { |controller, action, resource| true } # All users can see every screen

  # Date & DateTime Format
  # By default, format Date and DateTime values with the following
  config.date_format = '%Y-%m-%d'
  config.datetime_format = '%Y-%m-%dT%H:%MZ'

  # Boolean format
  # If :yes_no, display as yes_no instead of true/false
  config.boolean_format = :yes_no

  # Format integer columns with the following proc or function
  config.integer_format = :number_with_delimiter

  # Default number of entries shown per page
  # Valid options are: 10, 25, 50, 100, 250, 1000, :all
  config.default_entries = 25

  # When using the actions_column DSL method, apply the following behavior
  # Valid values for each action are:
  # true (always include a link to this action)
  # false (never include a link to this action)
  # :authorize (include link only if authorized - only works with ActiveRecord collections)
  #
  # When :authorize, a single check will be made via the above authorization_method
  # to see if the current_user has permission to :show/:edit/:destroy the collection class, i.e. Post
  # EffectiveDatatables.authorized? (:show || :edit || :destroy), Post
  #
  # For performance reasons, we only check the class once, not every individual resource.
  # You can override this default by calling `actions_column show: false, edit: true, destroy: :authorize`
  config.actions_column = {
      show: true,
      edit: false,
      destroy: false,
      unarchive: false
  }

end
