module Emerald::Test
  class << self
    def mock_coupon(details)
      # Set up a list that is cleared whenever stubs are cleared
      unless mock_coupons.length > 0
        stub(:mock_coupons).and_return({})
      end
      mock_coupons[details[:code]] = Emerald::Coupon.new(details)
    end

    def mock_coupons
      {}
    end

    def find_mock_coupon(code, purchase)
      mock_coupons[code]
    end
  end
end