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

=begin
    The source code and LICENSE of the "HighloadWalletV2":
    https://github.com/ton-blockchain/ton

"HIGHLOADWALLET_V2_CODE = ..." is a compiled version (byte code) of
the "HighloadWalletV2" in the bag of cells
serialization in hexadecimal representation.

  code cell hash(sha256): 9494d1cc8edf12f05671a1a9ba09921096eb50811e1924ec65c3c629fbb80812

Respect the rights of open source software. Thanks!
If you notice copyright violation, please create an issue.
https://github.com/nerzh/ton-sdk-ruby-smc/issues
=end

require 'date'

module TonSdkRubySmc
  include TonSdkRuby

  class HighloadWalletV2Transfer
    include TonSdkRuby
    extend TonSdkRuby
    extend TonSdkRubySmc

    attr_accessor :destination, :bounce, :value, :mode, :body, :init

    def initialize(destination, bounce, value, mode, body = nil, init = nil)
      @destination = destination # Address
      @bounce = bounce # Boolean
      @value = value  # Coins
      @mode = mode # Integer
      @body = body # Cell
      @init = init # StateInit
    end
  end

  class HighloadWalletV2
    include TonSdkRuby
    extend TonSdkRuby
    extend TonSdkRubySmc

    HIGHLOADWALLET_V2_CODE = "B5EE9C724101090100E5000114FF00F4A413F4BCF2C80B010201200203020148040501EAF28308D71820D31FD33FF823AA1F5320B9F263ED44D0D31FD33FD3FFF404D153608040F40E6FA131F2605173BAF2A207F901541087F910F2A302F404D1F8007F8E16218010F4786FA5209802D307D43001FB009132E201B3E65B8325A1C840348040F4438AE63101C8CB1F13CB3FCBFFF400C9ED54080004D03002012006070017BD9CE76A26869AF98EB85FFC0041BE5F976A268698F98E99FE9FF98FA0268A91040207A0737D098C92DBFC95DD1F140034208040F4966FA56C122094305303B9DE2093333601926C21E2B39F9E545A"

    attr_accessor :code, :pubkey, :init, :address, :sub_wallet_id

    def initialize(pubkey, workchain = 0, sub_wallet_id = 0)
      @pubkey = pubkey
      @sub_wallet_id = sub_wallet_id
      @code = deserialize(hex_to_bytes(HIGHLOADWALLET_V2_CODE)).first
      @init = build_state_init
      @address = Address.new("#{workchain}:#{init.cell.hash}")
    end

    def self.generate_query_id(timeout, random_id = nil)
      now = Time.now.to_i
      random = random_id || rand(0..(2**32 - 1))
      (now + timeout) << 32 | random
    end

    def build_transfer(transfers, private_key, is_init = false, timeout = 60, query_id = nil)
      raise "Transfers must be an [WalletV4Transfer]" unless transfers.size > 0 && transfers.first.is_a?(HighloadWalletV2Transfer)
      raise "HighloadWallet v2 can handle only 254 transfers at once" unless (transfers.size <= 254 && transfers.size > 0)

      query_id ||= HighloadWalletV2.generate_query_id(timeout)
      body = Builder.new
                    .store_uint(sub_wallet_id, 32)
                    .store_uint(query_id, 64)

      dict = HashmapE.new(16, {
        serializers: {
          key: ->(number) {
            Builder.new.store_int(number, 16).bits
          },
          value: ->(transfer) {
            internal_message = Message.new(
              MessageOptions.new(
                info: CommonMsgInfo.new(
                  IntMsgInfo.new(
                    dest: transfer.destination,
                    bounce: transfer.bounce,
                    value: transfer.value,
                    )
                ),
                body: transfer.body,
                init: transfer.init,
                )
            )

            Builder.new
                       .store_uint(transfer.mode, 8)
                       .store_ref(internal_message.cell)
                       .cell
          }
        }
      })

      transfers.each_with_index do |transfer, index|
        dict.set(index, transfer)
      end

      body.store_dict(dict)
      signature = sign_cell(body.cell, private_key)

      message_body = Builder.new
                            .store_bytes(signature.unpack('C*'))
                            .store_slice(body.cell.parse)

      state_init = is_init ? init : nil

      Message.new(
        MessageOptions.new(
          info: CommonMsgInfo.new(
            ExtInMsgInfo.new(
              dest: address
            )
          ),
          body: message_body.cell,
          init: state_init
        )
      )
    end

    private

    def build_state_init
      data = Builder.new
      data.store_uint(sub_wallet_id, 32)
      data.store_uint(0, 64)
      data.store_bytes(hex_to_bytes(pubkey))
      data.store_dict(HashmapE.new(16))

      options = StateInitOptions.new(code: code, data: data.cell)
      TonSdkRuby::StateInit.new(options)
    end
  end
end
