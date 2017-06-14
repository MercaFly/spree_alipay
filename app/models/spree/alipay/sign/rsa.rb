require 'openssl'
require 'base64'

module Spree
  module Alipay
    module Sign
      class RSA
        def self.sign(key, string)

          #byebug
          key = key.gsub! "\\n","\n"
          #key = "-----BEGIN RSA PRIVATE KEY-----\nMIICXQIBAAKBgQDBO2AuptFuoykJJhxtoOx2CdXIaIZk9IdD6mHFgLxgGJQjmLaSMwlsXOGvaD7F/Td1XbEV21bch4gFv1ol3ewbDIZzKnM44VqcsnRHY0MHQRqIVwgyMWihG8Z6O2QV8Q2qI3tnarFcK/8/mf3PcNmWjT/XSdO8iPy+IR95C+yJjwIDAQABAoGATrPlX/r4EG0KOLy6FXjW9tjYpzDTlGj4cxQS0IO3thgstjbsHa4F54oJLg1yi+ev3/DSQMm+nkHhiB3BFO1HzaNF41dbIRqpmKcl9iYU4TRWgZwgky8OL64RIuzkOCNWXmISiKGJRtyzxrxpv13dk46v99FrVovq3AnLdsTcbYECQQDmy7hQhsEEACaoEptwQ4E0MtspISN78VgIn8CDDZjQrW5a3vXsPEBaDt1+j52+ghff7ElGhSXLGb0twKqDYpfPAkEA1lV+9zVrQU8JJvIhh1gbze+0ShZdU3J7rn2ncyjz4XKVOH65oh2tdkkol0ckw0KQch53YCRN9O621CrjSL2iQQJAaLjdbCSI5jDPWYn/38Oxl6bPzOzNdgq/gEJEjvKXeXCIV1E90zBPns2J8UhnMi9DeAZ2BTqbOHn4Xg9DD5Sn/wJBAKjmtOggi4Xqv56WPn/GmhqeI+giWacR149468UfZ5io0Bi2HJk5Y+GL41XbNYg941Ba293CnkA/AYqOxY8kCUECQQDPsPrxhd3vpHV9rPCH6NJcX8Ks6t07kmrQwTSPDtbwquWRE1p0EMVj3ZcBL/mylnnHHfsVpd/lnQ7WntmFDFb/\n-----END RSA PRIVATE KEY-----\n"
          rsa = OpenSSL::PKey::RSA.new(key)
          Base64.strict_encode64(rsa.sign('sha1', string))
        end

        def self.verify?(key, string, sign)
          rsa = OpenSSL::PKey::RSA.new(key)
          rsa.verify('sha1', Base64.strict_decode64(sign), string)
        end
      end
    end
  end
end


