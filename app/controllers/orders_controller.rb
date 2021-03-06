class OrdersController < ApplicationController
  def create
    @order = current_user.orders.pending.first
    if @order.nil?
      @order = Order.new(params[:order])
      @order.user_id = current_user.id
      worked = @order.save
    else
      @order.user_id = current_user.id
      worked = @order.update_attributes(params[:order])
    end
    if worked
      redirect_to payment_action_with_id_url(@order.payment.id, :action => "edit")
    else
      flash[:error] = "Please select one of the features"
      redirect_to user_promote_url
    end
  end
  def update
    @order = current_user.orders.pending.first
    if @order.update_attributes(params[:order])
      redirect_to payment_action_with_id_url(@order.payment.id, :action => "edit")
    else
      flash[:error] = "Please select one of the features"
      redirect_to user_promote_url
    end
  end
end
