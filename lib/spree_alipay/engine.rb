module SpreeAlipay
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_alipay'

    config.autoload_paths += %W(#{config.root}/lib)

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      # load ruby files
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*.rb')) do |c|
        require_dependency(c)
      end
    end

    config.to_prepare &method(:activate).to_proc

    initializer "spree.alipay_payment.payment_methods", :after => "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << Spree::Gateway::AlipayTrade
    end
  end
end
