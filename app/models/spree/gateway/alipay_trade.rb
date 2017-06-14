require 'alipay'
module Spree
  class Gateway::AlipayTrade < Gateway
    preference :pid, :string
    preference :key, :string
    preference :sign_type, :string, :default => 'RSA'
    preference :MD5_key, :string
    preference :seller_email, :string
    preference :return_url, :string
    preference :notify_url, :string


    def supports?(source)
      true
    end

    def provider_class
      Spree::Alipay::Service
    end

    def provider
      setup_alipay
      Spree::Alipay::Service
    end

    def empty_success
      Class.new do
        def success?; true; end
        def authorization; nil; end
      end.new
    end    

    def cancel(response)
      empty_success
    end

    def auto_capture?
      true
    end

    def source_required?
      false
    end

    def method_type
      'alipay_trade'
    end

    def purchase(money, source, gateway_options)
      nil
    end

    def credit(money, source, gateway_options)
      refund(money, source, gateway_options)
    end

    def set_mobile_security_url(out_trade_no, order, gateway_options={})
      raise unless preferred_pid && preferred_key && preferred_seller_email
      subject      = gateway_options[:subject] || order.number
      total_amount = order.total
      options = {
          :out_trade_no      => out_trade_no,
          :subject           => subject,
          :currency          => 'EUR',
          :total_fee         => 0.01,
          :return_url        => preferred_return_url,
          :notify_url        => preferred_notify_url,
          :body              => 'sssssss',
          :forex_biz          => 'FP'
      }

      provider.mobile_securitypay_pay_string(options)
    end

    def actions
      %w(credit)
    end

    def set_forex_trade(out_trade_no, order, return_url, notify_url, gateway_options={})
      raise unless preferred_pid && preferred_key && preferred_seller_email

      subject      = gateway_options[:subject] || order.number

      options = {
          :out_trade_no      => out_trade_no,
          :subject           => subject,
          :currency          => "EUR",
          :total_fee         => total_amount,
          :return_url        => return_url,
          :notify_url        => notify_url
      }

      provider.create_forex_trade_url(options)
    end

    def refund(money, source, gateway_options)
      payment = Spree::Payment.find_by(:response_code => source)
      out_return_no = source + Time.now.strftime('%Y%m%d%H%M%S')
      out_trade_no = payment.order.number + '-' + payment.number
      params = {
          :out_return_no => out_return_no,
          :out_trade_no => out_trade_no,
          :currency => 'EUR',
          :return_amount => 0.01,
          :reason => gateway_options[:originator].reason.name,
      }
      url = provider.forex_refund_url(params, {:key => preferred_MD5_key, :sign_type => 'MD5'})
      xml_result = Net::HTTP.get(url)
      hash_result  = Hash.from_xml(xml_result)
      if hash_result["alipay"]["is_success"] == 'T'
        ActiveMerchant::Billing::Response.new(true, 'Refund success', {}, :test => false, :authorization => out_return_no)
      else
        ActiveMerchant::Billing::Response.new(false, 'Refund Failed:' + hash_result['alipay']['error'], {}, :test => false)
      end



    end

    private

    def setup_alipay
      Alipay.pid = preferred_pid
      Alipay.key = preferred_key
      Alipay.sign_type = preferred_sign_type
    end
  end
end
