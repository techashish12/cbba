require 'recaptcha/client_helper'
require 'recaptcha/verify'

module Recaptcha
  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 2
    TINY  = 2

    STRING = [MAJOR, MINOR, TINY].join('.')
  end

  
  RECAPTCHA_API_SERVER_URL        = 'http://www.google.com/recaptcha/api'
  RECAPTCHA_API_SECURE_SERVER_URL = 'https://www.google.com/recaptcha/api'
  RECAPTCHA_VERIFY_URL            = 'http://www.google.com/recaptcha/api/verify'

  SKIP_VERIFY_ENV = ['test', 'cucumber']

  class RecaptchaError < StandardError
  end
end