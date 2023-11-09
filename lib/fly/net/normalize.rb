# frozen_string_literal: true

module Fly
  module Net
    # Fly::Net::Normalize - handles "normalization" of data (complex structures
    #                       are formatted so that they will be understood by
    #                       New Relic once converted to JSON
    module Normalize
      module_function

      VALID_ENCODINGS = [Encoding::ISO_8859_1, Encoding::UTF_8].freeze

      def normalize(object)
        return object if object.respond_to?(:empty?) && object.empty?

        case object
        when Symbol, String then normalize_string(object.to_s)
        when Array then normalize_array(object)
        when Rational then object.to_f
        when Hash then normalize_hash(object)
        else object
        end
      end

      def normalize_array(array)
        array.map { |i| normalize(i) }
      end

      def normalize_hash(hash)
        hash.each_with_object({}) do |(k, v), h|
          h[normalize(k)] = normalize(v)
        end
      end

      def normalize_string(string)
        return string if VALID_ENCODINGS.include?(string.encoding) && string.valid_encoding?

        normal = string.dup # force_encoding is destructive
        if normal.encoding == Encoding::ASCII_8BIT || !normal.valid_encoding?
          normal.force_encoding(Encoding::ISO_8859_1)
        else
          normal.encode!(Encoding::UTF_8)
        end
      rescue EncodingError
        normal.force_encoding(Encoding::ISO_8859_1)
      end
    end
  end
end
