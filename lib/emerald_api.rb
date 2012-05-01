##
# This class lets you look up purchase-related information
# on Emerald.

class Emerald
  cattr_accessor :url

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
        resp.body
      else
        nil
      end
    rescue Faraday::Error::ConnectionFailed
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
        coupon
      else
        nil
      end
    rescue Faraday::Error::ConnectionFailed
      nil
    end
  end
end

