require 'digest/sha1'

class Password < ActiveRecord::Base
  attr_accessor :email
  
  # Relationships
  belongs_to :user
  
  # Validations
  validates_presence_of :email
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => 'is not a valid email address'

  protected
  
  def validate
    if !email.blank? && email.match(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i) && user.blank?
      errors.add_to_base("This email address could not be found on our system")
    end
  end
  
  def before_create
    self.reset_code = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join )
    self.expiration_date = 2.weeks.from_now
  end
end