module Emerald::Test
  class << self
    def mock_coupon(details)
      # Set up a list that is cleared whenever stubs are cleared
      unless mock_coupons.length > 0
        stub(:mock_coupons).and_return([])
      end
      mock_coupons << Emerald::Coupon.new(details)
    end

    def mock_coupons
      {}
    end

    def find_mock_coupon(code, purchase)
      mock_coupons.find do |coupon|
        # Filter on all the parameters we would normally send to Emerald, if they were set by mock_coupon
        coupon[:code] == code && [nil, purchase.package.code].include?(coupon[:product_key]) && [nil, purchase.organization].include?(coupon[:organization])
      end
    end
  end
end