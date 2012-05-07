##
# This class lets you look up purchase-related information
# on Emerald.

require 'faraday'
require 'faraday_middleware'

class Emerald
  class << self
    attr_accessor :url
  end

  private
  def self.connection
    if self.url.nil?
      raise "You need to set Emerald.url before using this library!"
    else
      conn = Faraday.new(:url => self.url) do |builder|
        builder.use FaradayMiddleware::Mashify
        builder.use FaradayMiddleware::ParseJson
        builder.adapter Faraday.default_adapter
      end
    end
  end

  public
  ##
  # Looks up a package by its code ("product key" on Emerald).
  # Returns nil if it's not found.
  #
  def self.find_package(code)
    begin
      resp = connection.get("/emerald_api/packages/show/#{code}")
      if resp.success?
        package = resp.body
        package.cost = package.cost_in_cents / 100.0
        package
      else
        nil
      end
    rescue Faraday::Error::ConnectionFailed,Faraday::Error::ParsingError
      nil
    end
  end

  ##
  # Lists all packages on Emerald.
  #
  def self.packages
    begin
      resp = connection.get("/emerald_api/packages/index")
      if resp.success?
        resp.body.map {|package| package.cost = package.cost_in_cents / 100.0; package}
      else
        nil
      end
    rescue Faraday::Error::ConnectionFailed,Faraday::Error::ParsingError
      nil
    end
  end

  ##
  # Looks up a coupon by its code and product key. You need
  # to pass in an object that responds to #code as the `purchase`
  # argument.
  #
  def self.find_coupon(code, purchase)
    begin
      resp = connection.get("/emerald_api/coupons/show/#{code}") do |req|
        req.params[:product_key] = purchase.code
      end
      if resp.success?
        coupon = resp.body
        coupon.discount = coupon.discount_in_cents / 100.0
        coupon
      else
        nil
      end
    rescue Faraday::Error::ConnectionFailed,Faraday::Error::ParsingError
      nil
    end
  end
end

