class PaymentsController < ApplicationController
  before_filter :login_required
  before_filter :get_payment, :only => [:edit, :edit_debit, :edit_debit_charities, :thank_you_direct_debit, :update] 
  
  def thank_you_direct_debit
    UserMailer.deliver_thank_you_direct_debit(current_user, @payment)
  end

  def index
    @payments = current_user.payments.find(:all, :order => "status desc" )
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @payments }
    end
  end

  # GET /payments/1/edit
  def edit
    log_bam_user_event(UserEvent::STARTED_PAYMENT, "", "Credit card")
    @payment.update_attribute(:payment_card_type, "credit_card")
    @payment.first_name = current_user.first_name
    @payment.last_name = current_user.last_name
    @payment.address1 = current_user.address1
    @payment.city = current_user.city
    unless @payment.pending?
      flash[:error] = "This payment is not pending"
      redirect_back_or_default root_url
    end
  end

  def edit_debit
    log_bam_user_event(UserEvent::STARTED_PAYMENT, "", "Direct debit")
    @payment.update_attribute(:payment_card_type, "direct_debit")
    unless @payment.pending?
      flash[:error] = "This payment is not pending"
      redirect_back_or_default root_url
    end
  end
  
  def edit_debit_charities
    @payment.update_attribute(:payment_card_type, "direct_debit")
    if @payment.pending?
      unless @payment.charity.blank?
        redirect_to :controller => "payments", :action => "edit_debit", :id => @payment.id
      end
    else
      flash[:error] = "This payment is not pending"
      redirect_back_or_default root_url
    end
  end

  # PUT /payments/1
  # PUT /payments/1.xml
  def update
    params[:payment].merge!(:ip_address => request.remote_ip)
    if @payment.update_attributes(params[:payment])
      if @payment.payment_card_type == "direct_debit"
        redirect_to :controller => "payments", :action => "edit_debit", :id => @payment.id
      else
        if @payment.purchase
          log_bam_user_event(UserEvent::PAYMENT_SUCCESS, "", "#{@payment.order.description} for #{amount_view(@payment.total)}")
          flash[:notice] = "Thank you for your payment. Features are now activated"
          redirect_to expanded_user_url(current_user)
        else
          log_bam_user_event(UserEvent::PAYMENT_FAILURE, "", "#{@payment.errors.full_messages.to_sentence}")
          logger.debug "======= #{@payment.errors.inspect}"
          render :action => 'edit'
        end
      end
    else
      if @payment.payment_card_type == "direct_debit"
        render :action => 'edit_debit_charities'
      else
        render :action => 'edit'
      end
    end
  end
  
  private
  
  def get_payment
    @payment = current_user.payments.find(params[:id])
  end
end

