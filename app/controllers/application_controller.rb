class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  helper_method :current_user, :logged_in?

  include CanCan::ControllerAdditions

  rescue_from Exception::StandardError, with: :error_occurred

  after_filter :store_location

  def store_location
    return unless request.get?
    if (request.path != '/login' &&
        request.path != '/logout' &&
        !request.xhr?) # don't store ajax calls
      session[:previous_url] = request.fullpath
    end
    if (request.path == '/welcome/deposit_login_modal')
      session[:previous_url] = '/datasets/new'
    end
  end

  def redirect_path
    session[:previous_url] || main_app.root_url
  end

  protected

  def error_occurred(exception)

    if exception.class == CanCan::AccessDenied
      alert_message = exception.message

      if exception.subject.class == Dataset && exception.action == :new
        if current_user && current_user.role == 'no_deposit'
          redirect_to redirect_path, alert: "ACCOUNT NOT ELIGIBLE TO DEPOSIT DATA.<br/>Faculty, staff, and graduate students are eligible to deposit data in Illinois Data Bank.<br/>Please <a href='/help'>contact the Research Data Service</a> if this determination is in error, or if you have any questions."
        else

          redirect_to '/welcome/deposit_login_modal'
        end

      else
        redirect_to redirect_path, alert: alert_message
      end

    else

      # raise exception

      exception_string = "*** Standard Error caught in application_controller.rb on #{IDB_CONFIG[:root_url_text]} ***\nclass: #{exception.class}\nmessage: #{exception.message}\n"

      max_lines_to_log = 5
      line_number = 1
      exception_string << "stack:\n"
      exception.backtrace.each do |line|
        exception_string << line
        exception_string << "\n"
        line_number = line_number + 1
        break if line_number > max_lines_to_log
      end

      Rails.logger.warn(exception_string)

      if current_user
        exception_string << "\nCurrent User: #{current_user.name} | #{current_user.email}"
      end

      notification = DatabankMailer.error(exception_string)
      notification.deliver_now
      redirect_to ('/500.html')

    end

  end

  def record_not_found(exception)

    Rails.logger.warn exception

    redirect_to redirect_path, :alert => "An error occurred and has been logged for review by Research Data Service Staff."

  end

  private

  def current_user
    begin
      @current_user ||= User.find(session[:user_id]) if session[:user_id]
    rescue ActiveRecord::RecordNotFound
      session[:user_id] = nil
    end
  end

  def set_current_user(user)
    @current_user = user
    session[:current_user_id] = user.id
  end

  def unset_current_user
    @current_user = nil
    session[:current_user_id] = nil
  end

  def logged_in?
    current_user.present?
  end

  def require_logged_in
    unless logged_in?
      session[:login_return_uri] = request.env['REQUEST_URI']
      redirect_to(login_path)
    end
  end

end
