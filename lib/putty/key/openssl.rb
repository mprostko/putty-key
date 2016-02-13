require 'openssl'

module PuTTY
  module Key
    module OpenSSL
      module ClassMethods
        def from_ppk(ppk)
          raise ArgumentError, 'ppk must not be nil' unless ppk

          case ppk.algorithm
          when 'ssh-rsa'
            ::OpenSSL::PKey::RSA.new.tap do |pkey|
              _, pkey.e, pkey.n = Util.ssh_unpack(ppk.public_blob, :string, :mpint, :mpint)
              pkey.d, pkey.p, pkey.q, pkey.iqmp = Util.ssh_unpack(ppk.private_blob, :mpint, :mpint, :mpint, :mpint)
              pkey.dmp1 = pkey.d % (pkey.p - 1)
              pkey.dmq1 = pkey.d % (pkey.q - 1)
            end
          else
            raise ArgumentError, "Unsupported algorithm: #{ppk.algorithm}"
          end
        end
      end

      module RSA
        def to_ppk
          PPK.new.tap do |ppk|
            ppk.algorithm = 'ssh-rsa'
            ppk.public_blob = Util.ssh_pack('ssh-rsa', e, n)
            ppk.private_blob = Util.ssh_pack(d, p, q, iqmp)
          end
        end
      end

      def self.global_install
        ::OpenSSL::PKey::RSA.class_eval do
          include RSA
        end

        ::OpenSSL::PKey.module_eval do
          extend ClassMethods
        end
      end
    end

    refine ::OpenSSL::PKey::RSA do
      include OpenSSL::RSA
    end

    refine ::OpenSSL::PKey.singleton_class do
      include OpenSSL::ClassMethods
    end
  end
end