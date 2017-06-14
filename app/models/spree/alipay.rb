module Spree
  module Alipay
    @debug_mode = false
    @sign_type = 'MD5'

    class << self
      attr_accessor :pid, :key, :sign_type, :debug_mode

      def debug_mode?
        !!@debug_mode
      end
    end
  end
end