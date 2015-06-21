require 'active_model'
require 'addressable/uri'

class UrlValidator < ActiveModel::EachValidator
  USER = /^[^\s:@]+$/
  PASSWORD = /^(|[^\s:@]+)$/

  IPv4_PART = /\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]/

  IP_ADDRESS = /^#{IPv4_PART}(\.#{IPv4_PART}){3}$/
  DOMAIN_NAME = /^(xn--)?[[[:alnum:]]_]+([-.][[[:alnum:]]_]+)*\.[[:alnum:]]{2,6}\.?$/u
  PRIVATE_IP_RANGES = /^(10\.#{IPv4_PART}\.#{IPv4_PART}\.#{IPv4_PART} |
    169\.254\.#{IPv4_PART}\.#{IPv4_PART} |
    172\.(1[6-9]|2[0-9]|31)\.#{IPv4_PART}\.#{IPv4_PART} |
    192\.168\.#{IPv4_PART}\.#{IPv4_PART})$/x

  def validate_each(record, attribute, value)
    valid = begin
      @uri = Addressable::URI.parse(value)
      raise Addressable::URI::InvalidURIError unless valid_domain?
      raise Addressable::URI::InvalidURIError unless valid_authority?
      raise Addressable::URI::InvalidURIError unless valid_path?
      /https?/i =~ @uri.scheme
    rescue
      false
    end
    unless valid
      record.errors[attribute] << (options[:message] || "is an invalid URL")
    end
  end

  private
  def valid_path?
    (/\s/ =~ @uri.path).nil? # imperfect
  end

  def valid_authority?
    return true if @uri.user.blank? && @uri.password.blank?
    !((USER =~ @uri.user).nil?) && !((PASSWORD =~ @uri.password).nil?)
  end

  def valid_domain?
    (valid_domain_name? || valid_ip_address?) && !localhost? && !private_ip_address?
  end

  def private_ip_address?
    !((PRIVATE_IP_RANGES =~ @uri.hostname).nil?)
  end

  def localhost?
    !((/^(127\.0\.0\.1|localhost)$/ =~ @uri.hostname).nil?)
  end

  def valid_ip_address?
    !((IP_ADDRESS =~ @uri.hostname).nil?)
  end

  def valid_domain_name?
    !((DOMAIN_NAME =~ @uri.hostname).nil?)
  end
end

