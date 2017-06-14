module Spree
  module Api
    module V1
      class AlipayController < Spree::Api::BaseController

        def notify
          notify_type = params['notify_type']
          return notify_error unless notify_type == 'trade_status_sync'
          trade_status = params['trade_status']
          return notify_error unless trade_status == 'TRADE_FINISHED'

          out_trade_no = params['out_trade_no']
          trade_nos = out_trade_no.split('-')
          payment_number = trade_nos[1]
          payment = Spree::Payment.find_by_number(payment_number)
          payment.response_code = params[:trade_no]
          payment.state = 'completed'
          payment.save
          response = ActiveMerchant::Billing::Response.new(
            true,
            'Transaction successful',
            params
          )
          payment.log_entries.create(
            details: response.to_yaml
          )

          @order = find_order(trade_nos[0])
          @order.next unless @order.completed?

          render json: {
            success: true
          }
        end

        def mobile_security
          @order = find_order(params[:order_number])
          payment_params = {
            amount: @order.total,
            payment_method: payment_method
          }
          payment = @order.payments.create!(payment_params)
          out_trade_no = @order.number + '-' + payment.number
          url = payment_method.set_mobile_security_url(out_trade_no,@order, {})
          render json: {
            url: url
          }
        end

        private

        def payment_method
          Spree::PaymentMethod.find_by_type('Spree::Gateway::AlipayTrade') || raise(ActiveRecord::RecordNotFound)
        end

        def find_order(order_number)
          @order = Spree::Order.find_by_number!(order_number) || raise(ActiveRecord::RecordNotFound)
        end

        def notify_error
          render json: {
            success: false
          }
        end

      end
    end
  end
end
