require 'spec_helper'

# Tests depend on these values, so sorry.
def build_mock_package
  Emerald::Package.new( {"id"=>1,
   "code"=>"wellcheck",
   "name"=>"Baseline",
   "description"=>"Get started with WellnessFX",
   "active"=>true,
   "cost_in_cents"=>14900,
   "created_at"=>"2012-05-29T17:25:52Z",
   "updated_at"=>"2012-05-29T17:25:52Z",
   "variants"=>
    [{"name"=>"Vitamin D", "cost_in_cents"=>4000, "code"=>"vitamin_d", 'default' => false},
      {"name"=>"Vitamin B", "cost_in_cents"=>1000, "code"=>"vitamin_b", 'default' => false}
    ]
  })
end

def build_mock_coupon
  Emerald::Coupon.new({"code"=>"test",
   "created_at"=>"2012-05-29T20:31:22Z",
   "description"=>"Test coupon",
   "discount_in_cents"=>1500,
   "id"=>1,
   "organization"=>"",
   "product_key"=>"wellcheck",
   "updated_at"=>"2012-05-29T20:31:22Z"})
end

describe Emerald do
  before do
    @mock_coupon = build_mock_coupon
    @mock_package = build_mock_package
  end
  describe Emerald::Package do
    it 'should respond to .active?' do
      @mock_package.should respond_to(:active?)
    end
    describe 'default and choosable variants' do
      before do
        @mock_package.variants << Emerald::Variant.new(name: 'default variant', code: 'default_variant', cost_in_cents: 12345, default: true)
      end
      it 'should return #choosable_variants' do
        @mock_package.choosable_variants.map(&:code).should == ['vitamin_d', 'vitamin_b']
      end
      it 'should return #default_variants' do
        @mock_package.default_variants.map(&:code).should == ['default_variant']
      end
    end
  end

  describe Emerald::Purchase do
    # We're testing with @mock_package for all of these, so this will save us
    # some typing
    def purchase(options={})
      Emerald::Purchase.new(@mock_package, options)
    end
    describe 'initialization' do
      it 'should set the package' do
        purchase.package.should == @mock_package
      end
      it 'should raise PackageNotFound with invalid package code' do
        Emerald.stub(:url).and_return('http://emerald-acceptance.herokuapp.com')
        expect { Emerald::Purchase.new('asdfasdf', available_in_state: 'CA') }.to raise_error(Emerald::Error::PackageNotFound, 'asdfasdf')
      end
      it 'should set the organization' do
        purchase(organization: 'test org').organization.should == 'test org'
      end
      it 'should default the credit to 0 if none is passed' do
        purchase.credit.should == Emerald::Credit.new({"credit_in_cents"=>0})
      end
      it 'should set the credit if passed' do
        purchase(credit: 1).credit.should == Emerald::Credit.new({"credit_in_cents"=>1})
      end
      it 'should not default the discount if none is passed' do
        purchase.discount.should be_nil
      end
      it 'should set the discount if passed' do
        purchase(discount: 1).discount.should == Emerald::Discount.new({"discount_in_cents"=>1})
      end
    end

    # XXX: This test depends on Emerald being up, but it was easier than trying
    # to scaffold out a bunch of packages and variants and shit
    describe 'upgrade_for' do
      before do
        Emerald.stub(:url).and_return('http://emerald-acceptance.herokuapp.com')
      end
      it 'should return a purchase object' do
        Emerald::Purchase.upgrade_for('consult.physician.45', available_in_state: 'CA').should be_a Emerald::Purchase
      end
      it 'should be base_package' do
        Emerald::Purchase.upgrade_for('consult.physician.45', available_in_state: 'CA').package.code.should == 'base_package'
      end
      it 'should only have one line item (the consult)' do
        purchase = Emerald::Purchase.upgrade_for('consult.physician.45', available_in_state: 'CA')
        purchase.variants.length.should == 1
        purchase.variants.first.code.should =~ /consult/
      end
      it 'should have the consult marked as default' do
        purchase = Emerald::Purchase.upgrade_for('consult.physician.45', available_in_state: 'CA')
        purchase.variants.first.should be_default
      end
      it 'should have the consult default_code equal to the consult to be upgraded from' do
        purchase = Emerald::Purchase.upgrade_for('consult.physician.45', available_in_state: 'CA')
        purchase.variants.first.default_code.should == "consult.physician.45"
      end
    end

    describe 'coupon=' do
      context 'when valid coupon code' do
        before do
          Emerald.stub(:find_coupon).and_return(@mock_coupon)
        end
        it 'should set the coupon' do
          purchase.tap {|p| p.coupon = 'asdf' }.coupon.should == @mock_coupon
        end
        it 'should not change discount_in_cents. should change purchase total' do
          @mock_coupon.discount_in_cents = 9999999
          p = purchase(coupon_code: 'asdf')
          p.coupon.discount_in_cents.should == 9999999
          p.total_in_cents.should == 0
        end
      end
      context 'when coupon object' do
        it 'should set the coupon' do
          purchase.tap {|p| p.coupon = @mock_coupon}.coupon.should == @mock_coupon
        end
      end
      context 'with invalid coupon' do
        before do
          Emerald.stub(:find_coupon).and_return(nil)
        end
        it 'should set coupon to nil' do
          purchase.tap {|p| p.coupon = 'asdf'}.coupon.should be_nil
        end
      end
    end

    describe '#credit=' do
      it "should set the credit" do
        purchase(credit: 1100).credit.credit_in_cents.should == 1100
      end
      context "with no coupons" do
        it "should not change credit_in_cents. should change purchase total" do
          # purchase = 14900
          p = purchase(credit: 15000)
          p.credit.credit_in_cents.should == 15000
          p.total_in_cents.should == 0
        end
      end
      context "with coupons" do
        it "should not change credit_in_cents. should change the purchase total" do
          # mock_coupon = 1500
          p = purchase(credit: 100)
          p.coupon = @mock_coupon
          p.credit.credit_in_cents.should == 100
          p.total_in_cents.should == 13300 # 14900 - 1500 - 100
        end
        it "should calculate total appropriately if coupon is removed" do
          p = purchase(credit: 150)
          p.coupon = @mock_coupon
          p.total_in_cents.should == 13250 # 14900 - 1500 - 150
          p.coupon = nil
          p.credit.credit_in_cents.should == 150
          p.total_in_cents.should == 14750 # 14900 - 150
        end
      end
      context "with discount" do
        pending "should not change credit_in_cents. should change total" do
          p = purchase(credit: 1500)
          p.total_in_cents.should == 13400 # 14900 - 1500
          p.credit.credit_in_cents.should == 1500
          p.discount = 1500 # should not affect it but
          p.total_in_cents.should == 13400
        end
      end
    end

    describe "#discount=" do
      it "should set the discount" do
        p = purchase(discount: 1100)
        p.discount.discount_in_cents.should == 1100
        p.total_in_cents.should == 13800 # 14900 - 1100
      end
      context "with no coupons" do
        it "should not change discount_in_cents.  should change the total" do
          p = purchase(discount: 15000)
          p.discount.discount_in_cents.should == 15000
          p.total_in_cents.should == 0
        end
      end
      context "with coupons" do
        it "should not use discount if a coupon is added" do
          p = purchase(discount: 15000)
          p.coupon = @mock_coupon
          p.discount.discount_in_cents.should == 15000
          p.total_in_cents.should == 13400 # 14900 - 1500
        end
        it "should retain discount_in_cents and calculate total appropriately if coupon is removed" do
          p = purchase(discount: 15000)
          p.coupon = @mock_coupon
          p.coupon = nil
          p.discount.discount_in_cents.should == 15000
          p.total_in_cents.should == 0
        end
      end
      context "with credit" do
        pending "should not change discount_in_cents to be <= the subtotal minus credit" do
          p = purchase(discount: 15000)
          p.credit = 1500
          p.discount.discount_in_cents.should == 15000
          p.total_in_cents.should == 0
        end
      end
    end

    describe 'variants' do
      context 'with invalid variants' do
        it 'should raise VariantNotFound' do
          expect { purchase(variants: ['asdfasdf']) }.to raise_error(Emerald::Error::VariantNotFound, 'asdfasdf')
        end
      end
      it 'should add the package default variants when creating a new purchase' do
        @mock_package.variants << Emerald::Variant.new(name: 'default variant', code: 'default_variant', cost_in_cents: 12345, default: true)
        purchase.variants.detect {|v| v.code == 'default_variant'}.should_not be_nil
      end
      it 'should return an array of variant objects, not strings' do
        purchase(variants: ['vitamin_b']).variants.first.should == @mock_package.find_variant_by_code('vitamin_b')
      end
      it 'should raise TypeError if you assign a non-array to variants' do
        expect { purchase(variants: 'asdf') }.to raise_error(TypeError)
      end
    end

    describe 'subtotal_in_cents' do
      it 'should subtract cost of default variants' do
        @mock_package.variants << Emerald::Variant.new(name: 'default variant', code: 'default_variant', cost_in_cents: 12345, default: true)
        purchase.subtotal_in_cents.should == @mock_package.cost_in_cents
      end
      it 'should be package cost with no variants' do
        purchase.subtotal_in_cents.should == @mock_package.cost_in_cents
      end
      it 'should be the sum of package cost and variant cost, and ignore coupon' do
        Emerald.stub(:find_coupon).and_return(@mock_coupon)
        purchase(variants: ['vitamin_d', 'vitamin_b'], coupon_code: 'asdf').subtotal_in_cents.should == @mock_package.cost_in_cents +
          @mock_package.find_variant_by_code('vitamin_d').cost_in_cents +
          @mock_package.find_variant_by_code('vitamin_b').cost_in_cents
      end
      it 'should have subtotal helper method' do
        purchase.subtotal.should == purchase.subtotal_in_cents / 100.0
      end
      it "should ignore credit" do
        purchase(credit: 1000).subtotal_in_cents.should == @mock_package.cost_in_cents
      end
      it "should ignore credit" do
        purchase(discount: 1000).subtotal_in_cents.should == @mock_package.cost_in_cents
      end
      it "should accurately determine total when reconstituted from a hash" do
        purchase.tap{|p| p.instance_variable_set(:@credit, nil)}.subtotal_in_cents.should == 14900
      end
    end

    describe 'total_in_cents' do
      it 'should be subtotal with no coupon' do
        purchase.total_in_cents.should == purchase.subtotal_in_cents
      end
      it 'should be subtotal minus coupon discount with coupon' do
        Emerald.stub(:find_coupon).and_return(@mock_coupon)
        test_purchase = purchase(variants: ['vitamin_d'], coupon_code: 'asdf')
        test_purchase.total_in_cents.should == test_purchase.subtotal_in_cents - @mock_coupon.discount_in_cents
      end
      it 'should have total helper method' do
        purchase.total.should == purchase.total_in_cents / 100.0
      end
      it "should be subtotal minus credit" do
        purchase(credit: 1000).total_in_cents.should == purchase.total_in_cents - 1000
      end
      it "should be subtotal minus discount" do
        purchase(discount: 1000).total_in_cents.should == purchase.total_in_cents - 1000
      end
      it "should accurately determine total when reconstituted from a hash" do
        purchase.tap{|p| p.instance_variable_set(:@credit, nil)}.total_in_cents.should == 14900
      end
    end
  end
end
