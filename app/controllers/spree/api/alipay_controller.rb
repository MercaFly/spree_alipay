module Spree
  module Api
    module V1
      class AlipayController < Spree::Api::BaseController

        def index

        end


        {"notify_id"=>"87febfa3a71272e6541e81411efcfb6lbq",
         "notify_type"=>"trade_status_sync",
         "sign"=>"Ti72p03vv56razlmtOwNF/8QjTTdbYytMHGgKRZMkIWcEKf8bjPuMpWcpZcHRT8mHSt4pBsqc9pm9q4VJCiepthuU1fcEHQL9XJnZnVrPMauisFm4BttteAO0F14w1wXvRlCyNeJdmeMtfYT24c8wPf6XPv9BCLabQc/QEu1ySk=",
         "trade_no"=>"2017061421001003690222511005",
         "total_fee"=>"0.02",
         "out_trade_no"=>"Q83TGF2G5PQ1CLT",
         "currency"=>"EUR",
         "notify_time"=>"2017-06-14 01:42:16",
         "trade_status"=>"TRADE_FINISHED",
         "sign_type"=>"RSA"}
        def notify


          out_trade_no = params['out_trade_no']

          trade_nos = out_trade_no.split('-')
          paymenr_number = trade_nos[1]

          payment = Spree::Payment.find_by_number(paymenr_number)

          payment.response_code = params[:trade_no]
          payment.state = 'completed'
          payment.save

          response = ActiveMerchant::Billing::Response.new(
              true,
              'Transaction successful',
              params
          )

          payment.log_entries.create(
              :details => response.to_yaml
          )

          render json: {
              'result' => true
          }
        end


        MOBILE_SECURITY_PARAMS = %w( trade_no out_trade_no )
        def mobile_security
# check_required_params(params, MOBILE_SECURITY_PARAMS)

# notify_url out_trade_no subject total_fee body

          @order = find_order

          payment_params = {
              amount: @order.total,
              payment_method: payment_method
          }
          payment = @order.payments.create!(payment_params)

          out_trade_no = @order.number + '-' + payment.number

          url = payment_method.set_mobile_security_url(out_trade_no,@order, {})

          render json: {
              "url" => url
          }
        end


        private
        def self.check_required_params(params, names)
          names.each do |name|
            warn("Alipay Warn: missing required option: #{name}") unless params.has_key?(name)
          end
        end

        def payment_method
          Spree::PaymentMethod.find_by_type('Spree::Gateway::AlipayTrade') || raise(ActiveRecord::RecordNotFound)
        end

        def find_order
          @order = Spree::Order.find_by_number!(params[:order_number]) || raise(ActiveRecord::RecordNotFound)
        end

      end
    end
  end
end
