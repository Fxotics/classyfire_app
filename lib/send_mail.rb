require 'mail'
require 'net/smtp'


module SendEmail

DESTINATION_EMAIL = ""
  
  def SendEmail.send(subject_task,username,password,send_to)
    # puts "Send to:"
    # send_to = gets.chomp
    # DESTINATION_EMAIL = username

    if  send_to  == "" || send_to == " "  
      DESTINATION_EMAIL.replace username
      # DESTINATION_EMAIL.replace  username
    else
    #   DESTINATION_EMAIL = send_to
      DESTINATION_EMAIL.replace send_to
    end


    subject = "Email sent from Ruby - #{subject_task}"
    date = Time.now

    msg = <<END_OF_MESSAGE

    Completed #{subject_task} at #{date}.

END_OF_MESSAGE

    # Resource used: https://rubydoc.info/gems/mail/Mail/SMTP
    # Using 'mail' gem
    #   - installation (Linux): sudo gem install mail

    # Setting up the connection with Gmail server 'smtp.gmail.com' to send it via SMTP.
    #    1) Port is 25 (default) or 587
    #    2) Ensure to enable TLS encryption (:enable_starttls_auto => true); otherwise it won't connect to Gmail server
    #    3) Since server is Gmail, it requires authentication --> Username & password (USE ENVIROMENT VARIABLES!)
    #    4) No need to set up a domain.

    Mail.defaults do
      delivery_method :smtp, { :address              => "smtp.gmail.com",
                              :port                 => 25, #587
                              #  :domain               => 'your.host.name',
                              :user_name            => username,
                              :password             => password,
                              :authentication       => 'plain',
                              :enable_starttls_auto => true  }
    end

    Mail.deliver do
      to DESTINATION_EMAIL
      from username
      subject subject
      body msg
    end
    
    puts "Sent email to #{DESTINATION_EMAIL}!"
  end
end