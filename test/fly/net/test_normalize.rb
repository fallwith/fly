# frozen_string_literal: true

require 'test_helper'

# TestNormalize = test lib/fly/net/normalize.rb
class TestNormalize < Minitest::Test
  def test_normalizes_data
    expected = ['a string', 'a_symbol', %w[an array], { 'a' => 'hash' }, 123, 3.2, '', nil]
    input = ['a string',
             :a_symbol,
             %w[an array],
             { a: :hash },
             123,
             3.2.to_r,
             '',
             nil]
    output = Fly::Net::Normalize.normalize(input)

    assert_equal expected, output
  end

  def test_8bit_is_converted_to_iso88591
    string = 'Hello, World!'.dup.force_encoding(Encoding::ASCII_8BIT)
    output = Fly::Net::Normalize.normalize(string)

    assert_equal Encoding::ISO_8859_1, output.encoding
  end

  def test_encoding_errors_are_handled
    string = 'Hello, World!'.dup.force_encoding(Encoding::UTF_16)
    string.stub :encode!, -> { raise EncodingError }, [Encoding::UTF_8] do
      output = Fly::Net::Normalize.normalize(string)

      assert_equal Encoding::ISO_8859_1, output.encoding
    end
  end
end
