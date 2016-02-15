class HelpController < ApplicationController
  def index
  end
  def help_mail
    if params.has_key?("nobots")
      # ignore the spam
    else
      help_request = DatabankMailer.contact_help(params)
      help_request.deliver_now
    end
    redirect_to '/help', notice: "Your email has been sent to the Research Data Service Team. "
  end
end