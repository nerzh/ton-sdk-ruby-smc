=begin
    ton-sdk-ruby-smc – commonly used tvm contracts ruby package

    Copyright (C) 2023 Oleh Hudeichuk

    This file is part of ton-sdk-ruby-smc.

    ton-sdk-ruby-smc is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation, either version 3 of
the License, or (at your option) any later version.

  ton-sdk-ruby-smc is distributed in the hope that it will be useful,
                                                              but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License
                                    along with ton-sdk-ruby-smc. If not, see <https://www.gnu.org/licenses/>.


=end

module TonSdkRubySmc
  include TonSdkRuby

  class MetaData
    extend TonSdkRuby
    extend TonSdkRubySmc

    def self.parse_token_metadata(da_slice)
      require_type('da_slice', da_slice, Slice)
      pum_purum_tag = da_slice.load_uint(8)
      result = {}
      if pum_purum_tag == 0x01
        result[:tag] = 'offchain'
        result[:data] = parse_off_chain_metadata(da_slice)
        result
      else
        result[:tag] = 'onchain'
        result[:data] = parse_on_chain_metadata(da_slice)
        result
      end
    end

    private

    def self.parse_on_chain_metadata(slice)
      deserializers = {
        key: -> (k) do
          slice = Slice.parse(Builder.new.store_bits(k).cell)
          just_value = slice.load_bytes(32)
          bytes_to_hex(just_value)
        end,
        value: -> (v) do
          v.parse.load_ref
        end
      }

      result_vot_da = {}
      dick = slice.load_dict(256, {deserializers: deserializers})
      dick.each do |key, value|
        TOKEN_ATTRIBUTES_SHA256.each do |name, hash|
          if hash == key
            cs = value.parse
            da_content_tag = cs.load_uint(8)
            if da_content_tag == 0x00
              result_vot_da[name] = parse_off_chain_metadata(cs)
            else
              raise 'Chuncked data unsupported'
            end
          end
        end
      end
      result_vot_da
    end

    def self.parse_off_chain_metadata(slice)
      string = slice.load_string(slice.bits.size / 8)
      while slice.refs.size > 0
        slice = slice.load_ref.parse
        string += slice.load_string(slice.bits.size / 8)
      end
      string
    end
  end
end
