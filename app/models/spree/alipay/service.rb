module Spree
  module Alipay
    module Service
      GATEWAY_URL = 'https://mapi.alipay.com/gateway.do'
      # GATEWAY_URL = 'https://openapi.alipaydev.com/gateway.do'.freeze

      MOBILE_SECURITY_PAY_REQUIRED_PARAMS = %w( notify_url out_trade_no subject total_fee body )
      def self.mobile_securitypay_pay_string(params, options = {})
        params = Utils.stringify_keys(params)
        check_required_params(params, MOBILE_SECURITY_PAY_REQUIRED_PARAMS)
        sign_type = options[:sign_type] || Alipay.sign_type
        key = options[:key] || Alipay.key
        raise ArgumentError, "only support RSA sign_type" if sign_type != 'RSA'

        params = {
            'partner'        => options[:pid] || Alipay.pid,
            'seller_id'      => options[:pid] || Alipay.pid,
            'payment_type'   => '1',
            'service'        => 'mobile.securitypay.pay',
            '_input_charset' => 'utf-8'
        }.merge(params)

        string = Spree::Alipay::Mobile::Sign.params_to_string(params)
        sign = CGI.escape(Spree::Alipay::Sign::RSA.sign(key, string))

        %Q(#{string}&sign="#{sign}"&sign_type="RSA")
      end

      CREATE_FOREX_SINGLE_REFUND_URL_REQUIRED_PARAMS = %w( out_return_no out_trade_no return_amount currency reason )
      def self.forex_refund_url(params, options = {})
        params = Utils.stringify_keys(params)
        check_required_params(params, CREATE_FOREX_SINGLE_REFUND_URL_REQUIRED_PARAMS)

        params = {
            'service'        => 'forex_refund',
            'partner'        => options[:pid] || Alipay.pid,
            '_input_charset' => 'utf-8',
            'gmt_return'     => Time.now.getlocal('+08:00').strftime('%Y%m%d%H%M%S')
        }.merge(params)

        request_uri(params, options)
      end

      SEND_GOODS_CONFIRM_BY_PLATFORM_REQUIRED_PARAMS = %w( trade_no logistics_name )
      SEND_GOODS_CONFIRM_BY_PLATFORM_OPTIONAL_PARAMS = %w( transport_type create_transport_type )
      def self.send_goods_confirm_by_platform(params, options = {})
        params = Utils.stringify_keys(params)
        check_required_params(params, SEND_GOODS_CONFIRM_BY_PLATFORM_REQUIRED_PARAMS)
        check_optional_params(params, SEND_GOODS_CONFIRM_BY_PLATFORM_OPTIONAL_PARAMS)

        params = {
            'service'        => 'send_goods_confirm_by_platform',
            'partner'        => options[:pid] || Alipay.pid,
            '_input_charset' => 'utf-8'
        }.merge(params)

        Net::HTTP.get(request_uri(params, options))
      end

      CREATE_FOREX_TRADE_REQUIRED_PARAMS = %w( notify_url subject out_trade_no currency )
      CREATE_FOREX_TRADE_OPTIONAL_PARAMS = %w( total_fee rmb_fee )
      def self.create_forex_trade_url(params, options = {})
        params = Utils.stringify_keys(params)
        check_required_params(params, CREATE_FOREX_TRADE_REQUIRED_PARAMS)
        check_optional_params(params, CREATE_FOREX_TRADE_OPTIONAL_PARAMS)
        params = {
            'service'         => 'create_forex_trade',
            '_input_charset'  => 'utf-8',
            'partner'         => options[:pid] || Alipay.pid,
        }.merge(params)

        request_uri(params, options).to_s
      end

      CLOSE_TRADE_REQUIRED_OPTIONAL_PARAMS = %w( trade_no out_order_no )
      def self.close_trade(params, options = {})
        params = Utils.stringify_keys(params)
        check_optional_params(params, CLOSE_TRADE_REQUIRED_OPTIONAL_PARAMS)

        params = {
            'service'        => 'close_trade',
            '_input_charset' => 'utf-8',
            'partner'        => options[:pid] || Alipay.pid
        }.merge(params)

        Net::HTTP.get(request_uri(params, options))
      end

      SINGLE_TRADE_QUERY_OPTIONAL_PARAMS = %w( trade_no out_trade_no )
      def self.single_trade_query(params, options = {})
        params = Utils.stringify_keys(params)
        check_optional_params(params, SINGLE_TRADE_QUERY_OPTIONAL_PARAMS)

        params =   {
            "service"         => 'single_trade_query',
            "_input_charset"  => "utf-8",
            "partner"         => options[:pid] || Alipay.pid,
        }.merge(params)

        Net::HTTP.get(request_uri(params, options))
      end

      def self.account_page_query(params, options = {})
        params = {
            service: 'account.page.query',
            _input_charset: 'utf-8',
            partner: options[:pid] || Alipay.pid,
        }.merge(params)

        Net::HTTP.get(request_uri(params, options))
      end

      BATCH_TRANS_NOTIFY_REQUIRED_PARAMS = %w( notify_url account_name detail_data batch_no batch_num batch_fee email )
      def self.batch_trans_notify_url(params, options = {})
        params = Utils.stringify_keys(params)
        check_required_params(params, BATCH_TRANS_NOTIFY_REQUIRED_PARAMS)

        params = {
            'service'        => 'batch_trans_notify',
            '_input_charset' => 'utf-8',
            'partner'        => options[:pid] || Alipay.pid,
            'pay_date'       => Time.now.strftime("%Y%m%d")
        }.merge(params)

        request_uri(params, options).to_s
      end

      CREATE_FOREX_TRADE_WAP_REQUIRED_PARAMS = %w( out_trade_no subject merchant_url currency )
      def self.create_forex_trade_wap_url(params, options = {})
        params = Utils.stringify_keys(params)
        check_required_params(params, CREATE_FOREX_TRADE_WAP_REQUIRED_PARAMS)

        params = {
            'service'        => 'create_forex_trade_wap',
            '_input_charset' => 'utf-8',
            'partner'        => options[:pid] || Alipay.pid,
            'seller_id'      => options[:pid] || Alipay.pid
        }.merge(params)

        request_uri(params, options).to_s
      end

      def self.request_uri(params, options = {})
        uri = URI(GATEWAY_URL)
        uri.query = URI.encode_www_form(sign_params(params, options))
        uri
      end

      def self.sign_params(params, options = {})
        params.merge(
            'sign_type' => (options[:sign_type] || Alipay.sign_type),
            'sign'      => Alipay::Sign.generate(params, options)
        )
      end

      def self.check_required_params(params, names)
        return if !Alipay.debug_mode?

        names.each do |name|
          warn("Alipay Warn: missing required option: #{name}") unless params.has_key?(name)
        end
      end

      def self.check_optional_params(params, names)
        return if !Alipay.debug_mode?

        warn("Alipay Warn: must specify either #{names.join(' or ')}") if names.all? {|name| params[name].nil? }
      end
    end
  end
  end