class SwapsController < ApplicationController

  def create
    set_shift
    @user = current_user
    if @shift.users.include?(@user)
      @swap = Swap.new(requesting_user_id: @user.id,
        shift_id: @shift.id)
      if @swap.save
        render "/swaps/create.json", status: :ok
      else
        render json: @swap.errors, status: :unprocessable_entity
      end
    else
      render json: '{}', status: :unauthorized
    end
  end
  
  def index
    set_calendar
    if @calendar.users.include?(current_user)
      @swaps = @calendar.swaps
      render "/swaps/index.json", status: :ok
    else
      render json: '{}', status: :unauthorized
    end
  end

  def update
    set_swap
    @user = current_user
    if @swap.shift.calendar.users.include?(current_user)
      if !@swap.accepting_user_id
        if @swap.update_attributes(accepting_user_id: @user.id)
          UserMailer.with(swap: @swap).swap_complete_email.deliver_now
          render "/swaps/update.json", status: :ok
        else
          render json: @swap.errors, status: :unprocessable_entity
        end
      else
        render json: {error: "swap already accepted"}, status: :unprocessable_entity
      end
    else
      render json: '{}', status: :unauthorized
    end
  end

  def complete
    @swap = current_swap
    case params[:decision]
    when "accept"
      Usershift.find_by(user_id: @swap.requesting_user_id,
        shift_id: @swap.shift_id).destroy
      @usershift = Usershift.new(user_id: @swap.accepting_user_id,
        shift_id: @swap.shift_id)
      if @usershift.save
        @swap.destroy
        #send accept email
        render json: @usershift, status: :ok
      else
        render json: @usershift.errors, status: :unprocessable_entity
      end
    when "deny"
      @accepting_user = @swap.accepting_user
      @swap.accepting_user_id = nil
      if @swap.save
        render json: {error: "swap denied"}, status: :ok
        #send denial email
      else
        render json: @swap.errors, status: :unprocessable_entity
      end
    end
  end

  private

  def set_calendar
    @calendar = Calendar.find(params[:calendar_id])
  end

  def set_shift
    @shift = Shift.find(params[:shift_id])
  end

  def set_swap
    @swap = Swap.find(params[:id])
  end

  def current_swap
    authenticate_with_http_token do |token, options|
      return  Swap.find_by_api_token(token)
    end
  end

end
