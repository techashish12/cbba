require File.dirname(__FILE__) + '/../../lib/helpers'
require 'recaptcha'

class ApplicationController < ActionController::Base
  include ExceptionNotifiable
  include AuthenticatedSystem
  include RoleRequirementSystem
  include ApplicationHelper  

  helper :all # include all helpers, all the time
  protect_from_forgery
  filter_parameter_logging :password, :password_confirmation
  filter_parameter_logging :card_number, :card_verification
  
  layout :my_layout


	#  before_filter :tags
  before_filter :get_country, :featured_quotes, :current_category, :search_terms, :categories, :counters, :resident_experts, :except => :change_category
  # before_filter :set_subdomain_user
  
  def get_stats
    @payments = Payment.find(:all, :conditions => {:created_at => @start_date..@end_date, :status => "completed"} )
    @pending_payments = Payment.find(:all, :conditions => {:created_at => @start_date..@end_date, :status => "pending"} )
    @total_payments = @payments.inject(0){|sum, p| sum+p.amount} || 0
    @signups = User.find(:all, :conditions => {:created_at => @start_date..@end_date } )
    @published_profiles = UserProfile.find(:all, :conditions => {:published_at => @start_date..@end_date, :state => "published"} )
    @draft_profiles = UserProfile.find(:all, :conditions => {:created_at => @start_date..@end_date, :state => "draft"} )
    @published_articles = Article.find(:all, :conditions => {:published_at => @start_date..@end_date } )
    @published_SOs = SpecialOffer.find(:all, :conditions => {:published_at => @start_date..@end_date } )
    @published_GVs = GiftVoucher.find(:all, :conditions => {:published_at => @start_date..@end_date } )
    @public_newsletter_signups = Contact.find(:all, :conditions => {:created_at => @start_date..@end_date })    
  end


	protected
	exception_data :additional_data

  def get_country
    @country = nil
    if params[:country_code]
      @country = Country.find_by_country_code(params[:country_code])
    end
    if @country.nil?
      @country = Country.extract_country_code_from_host(request.host)
    end
  end

  def redirect_with_context(default_url, visiting_user=current_user)
    if @context == "profile"
      if logged_in? && visiting_user == current_user
        redirect_to expanded_user_url(current_user, :selected_tab_id => @selected_tab_id)
      else
        if visiting_user.nil?
          redirect_to default_url
        else
          redirect_to expanded_user_url(visiting_user, :selected_tab_id => @selected_tab_id)
        end
      end
    else
      if @context == "review"
        redirect_to reviewer_url(:action => "index")
      else
        #default
        redirect_to default_url
      end
    end
  end
  
  def get_context
    @context = params[:context]
    @selected_tab_id = params[:selected_tab_id]
  end

  def search_terms
		@what = url_decode(params[:what])
		@where = url_decode(params[:where])    
  end

  def render_optional_error_file(status_code)
    case status_code
      when :not_found
        render_404
      when :internal_server_error
        render_500
      else
        super
    end
  end

  def render_404
    respond_to do |type| 
      type.html do
        logger.warn("Error 404 for request: #{request.inspect}")
        redirect_to notfound_url
      end
      type.all  { render :nothing => true, :status => 404 } 
    end
    true  # so we can do "render_404 and return"
  end

  def render_500
    respond_to do |type| 
      type.html do
        logger.error("Error 500 for request: #{request.inspect}")
        redirect_to customerror_url
      end
      type.all  { render :nothing => true, :status => 500 } 
    end
    true  # so we can do "render_404 and return"
  end

	def additional_data
		{ :user => current_user}
	end
	
  def get_selected_user
    @selected_user = User.find_by_slug(params[:selected_user])
  end

  def verify_human
    if session[:verify_human_count].blank? || session[:verify_human_count] > 10
      my_test = verify_recaptcha
      log_bam_user_event UserEvent::VERIFY_CATPCHA, "", my_test ? "Success" : "Failure"
      if my_test
        session[:verify_human_count] = 1
      else
        logger.debug("=== failed captcha with response: #{params[:recaptcha_response_field]}")
      end
      return my_test
    else
      session[:verify_human_count] += 1
      return true
    end
  end

  def featured_quotes
    @featured_quotes = Quote.homepage_featured
  end

  def resident_experts
    @featured_resident_experts = User.homepage_featured_resident_experts(@country)
  end

	def get_districts_and_subcategories(country_id)
	  get_regions(country_id)
    get_districts(country_id)
	  get_subcategories
	  get_all_countries
	end

  def get_countries
    @countries_array = Country.active.collect {|d| [ d.name, d.id ]}
  end

  def get_all_countries
      @countries_array = Country.all.collect {|d| [ d.name, d.id ]}
  end

  def get_full_countries
    @countries = Country.active
  end
  
  def get_countries_with_nil
    @countries_array = Country.active.collect {|d| [ d.name, d.id ]}
    @countries_array << ["Other country", nil]
  end

  def admin_required
    unless logged_in? && current_user.admin?
      access_denied
    end
  end

  def resident_expert_admin_required
    unless logged_in? && current_user.resident_expert_admin?
      access_denied
    end
  end

  def full_member_required
    unless logged_in? && current_user.full_member?
      access_denied
    end
  end

	def my_layout
		if params[:format] == "js"
			return false
		else
			return "michael_main"
		end
	end

	def get_related_articles
		if params[:subcategory_id].nil?
			@articles = Article.find_all_by_subcategories(*@category.subcategories)
		else
			@articles = Article.find_all_by_subcategories(Subcategory.find(params[:subcategory_id]))
		end
	end

	def current_category
    if !params[:category_slug].nil?
			@category = Category.find_by_slug(params[:category_slug])
      if @category.nil?
  		  flash[:error]="Could not find category #{params[:category_slug]}"
  		  redirect_to root_url
      else
			  @category_id = @category.id
		  end
		end
	end

#	def search_init
#		selected_subcategory_id = params[:what] unless params[:what].blank?
#		if params[:where].blank?
#			selected_district_id = current_user.district_id unless current_user.nil?
#		else
#			if params[:where].starts_with?("r-")
#				selected_district_id = nil
#				region_id = params[:where].split("-")[1].to_i
#			else
#				selected_district_id = params[:where].to_i
#			end
#		end
#		@what_subcategories = Subcategory.options(@category, selected_subcategory_id)
#		@where_districts = District.options(region_id, selected_district_id)
#	end

	def categories
		@categories = Category.list_categories
	end

	def counters
	  get_full_countries
	  @counters = {}
	  @countries.each do |country|
  		@counters[country] = country.counters.published
	  end
		@total_users = User.active.count
		@total_articles = Article.published.count
	end

  def tags
    @tags = Tag.tags(:limit => 20)  
  end

	def get_blog_categories
		@blog_categories = BlogCategory.find(:all, :order => "name").collect {|d| [ d.name, d.id ]}
	end

	def get_blog_subcategories
		@blog_subcategories = BlogSubcategory.find(:all, :include => "blog_category", :order => "blog_categories.name, blog_subcategories.name").collect {|d| [ d.full_name, d.id ]}
	end

	def get_subcategories(except_subcategories=[])
	  if except_subcategories.blank?
		  @subcategories = Subcategory.find(:all, :include => "category", :order => "categories.name, subcategories.name").collect {|d| [ d.full_name, d.id ]}
	  else
      @subcategories = Subcategory.find(:all, :include => "category", :conditions => "subcategories.id NOT IN (#{except_subcategories.map(&:id).join(',')})", :order => "categories.name, subcategories.name").collect {|d| [ d.full_name, d.id ]}
    end
	end

	def get_districts(country_id)
		@districts = District.find(:all, :conditions => ["districts.country_id = ?", country_id], :include => "region", :order => "regions.name, districts.name").collect {|d| [ d.full_name, d.id ]}
	end

	def get_regions(country_id)
		@regions = Region.find(:all, :conditions => ["country_id = ?", country_id], :order => "name" ).collect {|r| [ r.name, r.id ]}
	end
	
  private
    def set_subdomain_user
      @subdomain_user = User.find_by_subdomain!(request.subdomains.first)
      if !@subdomain_user.nil? && @subdomain_user.published?
        puts "======== found #{@subdomain_user.inspect}"
        puts "========= request: #{request.inspect}"
        if request["PATH_INFO"] == "/"
          redirect_to :controller => "users", :action => "show", :name => @subdomain_user.slug    
        end
      end
    end
end

