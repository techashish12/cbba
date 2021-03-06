# Settings specified here will take precedence over those in config/environment.rb
require 'xero_gateway'
require 'xero_gateway/address'
require 'xero_gateway/phone'
require 'xero_gateway/money'
require 'xero_gateway/dates'
require 'xero_gateway/contact'
require 'xero_gateway/line_item'
require 'xero_gateway/invoice'
require 'xero_gateway/response'

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

config.after_initialize do
  ActiveMerchant::Billing::Base.mode = :test
  ::GATEWAY = ActiveMerchant::Billing::BogusGateway.new
end

$xero_gateway = XeroGateway::Gateway.new(
  :customer_key => "ZDYWYWY1ODG1ZTG0NGQ5ZTKYNGZMYM",
  :api_key => "MDCYODC0ZMNJOTBJNDI1NZG0N2I0MZ",
  :xero_url => "https://networktest.xero.com/api.xro/1.0"
  )