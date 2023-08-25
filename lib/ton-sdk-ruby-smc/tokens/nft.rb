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

  class NFT
    
=begin
transfer#5fcc3d14 query_id:uint64 new_owner:MsgAddress response_destination:MsgAddress 
                  custom_payload:(Maybe ^Cell) forward_amount:(VarUInteger 16) 
                  forward_payload:(Either Cell ^Cell) = InternalMsgBody;
=end
    def self.build_transfer(query_id, new_owner, response_destination, forward_amount, forward_payload, custom_payload = nil)
      require_type('query_id', query_id, Integer)
      require_type('new_owner', new_owner, Address)
      require_type('response_destionation', response_destionation, Address)
      require_type('custom_payload', custom_payload, Cell) unless custom_payload.nil?
      require_type('forward_amount', forward_amount, Coins)
      require_type('forward_payload', forward_payload, Cell)

      body = Builder.new
      body.store_uint(0x5fcc3d14, 32)
      body.store_uint(query_id, 64)
      body.store_address(new_owner)
      body.store_address(response_destionation)
      body.store_maybe_ref(custom_payload)
      body.store_coins(forward_amount)      
      
      if (body.bits.size + forward_payload.bits.size > 1023) || body.refs.size + forward_payload.refs.size > 4
        body.store_bit(1)
        body.store_ref(forward_payload)
      else
        body.store_bit(0)
        body.store_slice(forward_payload.parse)
      end
      body.cell
    end
  end
end