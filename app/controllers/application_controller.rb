class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  helper_method :current_user

  include CanCan::ControllerAdditions

  rescue_from CanCan::AccessDenied do |exception|

    alert_message = exception.message

    if exception.subject.class == Dataset && exception.action == :new
      alert_message = "Log in to deposit data."
    end

    redirect_to main_app.root_url, :alert => alert_message
  end

  private

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
end
