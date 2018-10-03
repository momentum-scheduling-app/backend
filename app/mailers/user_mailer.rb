class UserMailer < ApplicationMailer
  default from: 'notifications@example.com'

  def welcome_email
    welcome_page = "https://scheduler-79e4e.firebaseapp.com/welcome"
    @user = params[:user]
    @invitation = params[:invitation]
    @url  = welcome_page + '?token=' + params[:invitation].api_token
    mail(to: @user.email, subject: 'Welcome to our Scheduling Site!')
  end

  def added_email
    @user = params[:user]
    @url = "https://scheduler-79e4e.firebaseapp.com/login"
    mail(to: @user.email, subject: "You've been added to a new calendar on our Scheduling Site!")
  end

end
