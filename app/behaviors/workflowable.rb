module Workflowable
  def self.included(base)
		base.send :include, Authorization::AasmRoles::StatefulRolesInstanceMethods
		base.send :include, AASM

    base.send :include, WorkflowInstanceMethods
    base.send :extend, WorkflowClassMethods
    base.send :belongs_to, :approved_by, :class_name => "User"
    base.send :belongs_to, :rejected_by, :class_name => "User"
    base.send :aasm_column, :state
    base.send :aasm_initial_state, :draft
    base.send :aasm_state, :draft
    base.send :aasm_state, :published, :enter => :on_publish_enter
    
    base.send :aasm_event, :publish do
      transitions :from => :draft, :to => :published, :guard => Proc.new {|item| item.paid_items_left?}
    end

    base.send :aasm_event, :remove do
      transitions :from => :published, :to => :draft, :on_transition => :remove_published_information_and_decrement_count
    end

    base.send :aasm_event, :reject do
      transitions :from => :published, :to => :draft, :on_transition => :decrement_published_count
    end

    base.send :after_destroy, :decrement_published_count

    base.send :named_scope, :latest, :conditions => ["published_at > ?", 1.month.ago]
    base.send :named_scope, :approved, :conditions => ["state = 'published' and approved_at IS NOT NULL and (rejected_at IS NULL or approved_at > rejected_at)"]

  end
  module WorkflowClassMethods
    
    def last_published_at(country)
      self.first(:order=>"published_at DESC", :conditions=>["country_id = ? and published_at IS NOT NULL", country.id]).try(:published_at)
    end
        
    def currently_selected_and_last_10_published(newsletter)
      res = Set.new
      newsletter.send(self.to_s.tableize.to_sym).each do |i|
        res << i
      end
      self.find(:all, :conditions => "state = 'published' AND published_at is not null AND rejected_at is null",  :order => "published_at desc", :limit => 10).each do |i|
        res << i
      end
      res
    end
    
    def published_in_last_2_months(start=Time.now)
      self.find(:all, :conditions => ["state = 'published' AND published_at BETWEEN ? AND ?  AND rejected_at is null", start.advance(:months => -2), Time.now])
    end
    
    def count_reviewable
      self.count(:all, :conditions => "approved_by_id is null and state = 'published'")
    end
    def reviewable
      self.find(:all, :conditions => "approved_by_id is null and state = 'published'")
    end
  end
  module WorkflowInstanceMethods
    
    def on_publish_enter
      email_reviewers_and_increment_count
    end
        
    def label(url="")
      if url.blank?
        res = "#{self.title}<br/>"
      else
        res = "<a href=\"#{url}\">#{self.title}</a><br/>"
      end
      sub = ""
      sub << "#{self.subcategory.name} - " if self.respond_to?(:subcategory) && !self.subcategory.nil?
      sub << "offered by #{self.author.name}" if self.respond_to?(:author) && !self.author.nil?
      res << sub[0..0].upcase
      res << sub[1..sub.length]
    end

    def paid_items_left?
      !self.respond_to?(:author) || (self.respond_to?(:author) && !self.author.respond_to?("paid_#{self.class.to_s.tableize}")) || (self.respond_to?(:author) && self.author.respond_to?("paid_#{self.class.to_s.tableize}") && self.class.to_s != "UserProfile" && self.author.send("#{self.class.to_s.tableize}".to_sym).published.size < self.author.send("paid_#{self.class.to_s.tableize}"))
    end

    def path_method
      self.class.to_s.tableize.singularize+"_url"
    end

    def workflow_css_class
      "workflow-#{self.state}"
    end

    def decrement_published_count
      sym = "published_#{self.class.to_s.tableize}_count".to_sym
      if self.respond_to?(:author) && self.author.respond_to?(sym)
        self.author.update_attribute(sym, self.author.send(sym)-1)
      end      
      if self.respond_to?(:subcategories)
        self.subcategories.each do |s|
          if s.respond_to?(sym) && s.method(sym).arity == 0
            s.update_attribute(sym, s.send(sym)-1)
          end
        end
      else
        if self.respond_to?(:subcategory) && self.subcategory.respond_to?(sym) && self.subcategory.method(sym).arity == 0
          self.subcategory.update_attribute(sym, self.subcategory.send(sym)-1)
        end
      end
    end

    def remove_published_information_and_decrement_count
      self.update_attributes(:approved_at => nil, :approved_by => nil, :published_at => nil)
      country = self.author.country
      sym = "published_#{self.class.to_s.tableize}_count".to_sym
      if self.respond_to?(:author) && self.author.respond_to?(sym)
        self.author.update_attribute(sym, self.author.send(sym)-1)
      end
      if self.respond_to?(:subcategories)
        self.subcategories.each do |subcat|
          if subcat.respond_to?(sym) && subcat.method(sym).arity == 0
            subcat.update_attribute(sym, subcat.send(sym)-1)
          else
            cs = CountriesSubcategory.find_by_country_id_and_subcategory_id(country.id, subcat.id)
            if cs.nil?
              test_cs = CountriesSubcategory.first
              if test_cs.respond_to?(sym)
                CountriesSubcategory.create(:country_id => country.id, :subcategory_id => subcat.id,
                                        sym => 0)
              end
            else
              if cs.respond_to?(sym) && cs.method(sym).arity == 0
                count = cs.send(sym)
                count = 0 if count.nil?
                cs.update_attribute(sym, count-1)
              end
            end
          end
        end
      else
        if self.respond_to?(:subcategory)
          if self.subcategory.respond_to?(sym) && self.subcategory.method(sym).arity == 0
            self.subcategory.update_attribute(sym, self.subcategory.send(sym)-1)
          else
            cs = CountriesSubcategory.find_by_country_id_and_subcategory_id(country.id, self.subcategory.id)            
            if cs.nil?
              test_cs = CountriesSubcategory.first
              if test_cs.respond_to?(sym)
                CountriesSubcategory.create(:country_id => country.id, :subcategory_id => self.subcategory.id,
                                        sym => 1)
              end
            else
              if cs.respond_to?(sym) && cs.method(sym).arity == 0
                count = cs.send(sym)
                count = 0 if count.nil?
                cs.update_attribute(sym, count-1)
              end
            end
          end
        end
      end
    end

  	def email_reviewers_and_increment_count
      self.published_at = Time.now.utc
      User.reviewers.each do |r|
        UserMailer.deliver_stuff_to_review(self, r)
      end
      sym = "published_#{self.class.to_s.tableize}_count".to_sym
      if self.respond_to?(:author) && self.author.respond_to?(sym)
        self.author.update_attribute(sym, self.author.send(sym)+1)
      end
      country = self.author.country
      if country.nil?
        country = Country.default_country
      end
      if self.respond_to?(:subcategories)
        self.subcategories.each do |subcat|
          if subcat.respond_to?(sym) && subcat.method(sym).arity == 0
            subcat.update_attribute(sym, subcat.send(sym)+1)
          else
            cs = CountriesSubcategory.find_by_country_id_and_subcategory_id(country.id, subcat.id)
            if cs.nil?
              test_cs = CountriesSubcategory.first
              if test_cs.respond_to?(sym)
                CountriesSubcategory.create(:country_id => country.id, :subcategory_id => subcat.id,
                                      sym => 1)
              end
            else
              if cs.respond_to?(sym) && cs.method(sym).arity == 0
                count = cs.send(sym)
                count = 0 if count.nil?
                cs.update_attribute(sym, count+1)
              end
            end
          end
        end
      else
        if self.respond_to?(:subcategory)
          if self.subcategory.respond_to?(sym) && self.subcategory.method(sym).arity == 0
            self.subcategory.update_attribute(sym, self.subcategory.send(sym)+1)
          else
            cs = CountriesSubcategory.find_by_country_id_and_subcategory_id(country.id, self.subcategory.id)            
            if cs.nil?
              test_cs = CountriesSubcategory.first
              if test_cs.respond_to?(sym)
                CountriesSubcategory.create(:country_id => country.id, :subcategory_id => self.subcategory.id,
                                      sym => 1)
              end
            else
              if cs.respond_to?(sym) && cs.method(sym).arity == 0
                count = cs.send(sym)
                count = 0 if count.nil?
                cs.update_attribute(sym, count+1)
              end
            end
          end
        end
      end
    end

    def reviewable?
      state == "published" && approved_by.nil?
    end
    
    def approved?
      state == "published" && !approved_at.nil? && (rejected_at.nil? || approved_at > rejected_at)
    end
  end
end