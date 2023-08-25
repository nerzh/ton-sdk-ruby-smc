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
The source code and LICENSE of the "wallet v4 r2" smart contract:
https://github.com/toncenter/tonweb/blob/master/src/contract/wallet/WalletSources.md

"WALLET_V4_CODE = ..." is a compiled version (byte code) of
the smart contract "wallet-v4-r2-code.fif" in the bag of cells
serialization in hexadecimal representation.

code cell hash(sha256): FEB5FF6820E2FF0D9483E7E0D62C817D846789FB4AE580C878866D959DABD5C0

Respect the rights of open source software. Thanks! :)
If you notice copyright violation, please create an issue:
https://github.com/nerzh/ton-sdk-ruby-smc/issues
=end

module TonSdkRubySmc
  include TonSdkRuby

  WALLET_V4_CODE = "B5EE9C72410214010002D4000114FF00F4A413F4BCF2C80B010201200203020148040504F8F28308D71820D31FD31FD31F02F823BBF264ED44D0D31FD31FD3FFF404D15143BAF2A15151BAF2A205F901541064F910F2A3F80024A4C8CB1F5240CB1F5230CBFF5210F400C9ED54F80F01D30721C0009F6C519320D74A96D307D402FB00E830E021C001E30021C002E30001C0039130E30D03A4C8CB1F12CB1FCBFF1011121302E6D001D0D3032171B0925F04E022D749C120925F04E002D31F218210706C7567BD22821064737472BDB0925F05E003FA403020FA4401C8CA07CBFFC9D0ED44D0810140D721F404305C810108F40A6FA131B3925F07E005D33FC8258210706C7567BA923830E30D03821064737472BA925F06E30D06070201200809007801FA00F40430F8276F2230500AA121BEF2E0508210706C7567831EB17080185004CB0526CF1658FA0219F400CB6917CB1F5260CB3F20C98040FB0006008A5004810108F45930ED44D0810140D720C801CF16F400C9ED540172B08E23821064737472831EB17080185005CB055003CF1623FA0213CB6ACB1FCB3FC98040FB00925F03E20201200A0B0059BD242B6F6A2684080A06B90FA0218470D4080847A4937D29910CE6903E9FF9837812801B7810148987159F31840201580C0D0011B8C97ED44D0D70B1F8003DB29DFB513420405035C87D010C00B23281F2FFF274006040423D029BE84C600201200E0F0019ADCE76A26840206B90EB85FFC00019AF1DF6A26840106B90EB858FC0006ED207FA00D4D422F90005C8CA0715CBFFC9D077748018C8CB05CB0222CF165005FA0214CB6B12CCCCC973FB00C84014810108F451F2A7020070810108D718FA00D33FC8542047810108F451F2A782106E6F746570748018C8CB05CB025006CF165004FA0214CB6A12CB1FCB3FC973FB0002006C810108D718FA00D33F305224810108F459F2A782106473747270748018C8CB05CB025005CF165003FA0213CB6ACB1F12CB3FC973FB00000AF400C9ED54696225E5"
  SUB_WALLET_ID = 698983191

  class WalletV4Transfer
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

  class WalletV4
    attr_accessor :code, :pubkey, :init, :address, :sub_wallet_id

    def initialize(pubkey, wc = 0, sub_wallet_id = SUB_WALLET_ID)
      @pubkey = pubkey
      @sub_wallet_id = sub_wallet_id
      @code = deserialize(hex_to_bytes(WALLET_V4_CODE)).first
      @init = build_state_init
      @address = Address.new("#{wc}:#{init.cell.hash}")
    end

    def self.parse_storage(storage_slice)
      raise "Must be a Slice" unless storage_slice.is_a?(Slice)
      deserializers = {
        key: ->(k) do
          slice = Slice.parse(Builder.new.store_bits(k).cell)
          wc = slice.load_int(8)
          addr = slice.load_bytes(32)
          Address.new("#{wc}:#{bytes_to_hex(addr)}")
        end,
        value: ->(v) { nil },
      }

      {
        seqno: storage_slice.load_uint(32),
        sub_wallet_id: storage_slice.load_uint(32),
        pubkey: storage_slice.load_bytes(32),
        plugins_list: storage_slice
          .load_dict(8 + 256, { deserializers: deserializers }).each { |key, value| { key: key, value: value } }
          .map { |item| item[:key] },
      }
    end

    def build_transfer(transfers, seqno, private_key, timeout = 60)
      raise "Transfers must be an [WalletV3Transfer]" unless transfers.size > 0 && transfers.first.is_a?(WalletV3Transfer)
      raise "Wallet v3 can handle only 4 transfers at once" unless transfers.size <= 4
      body = Builder.new()
      body.store_uint(sub_wallet_id, 32)
      body.store_uint((Time.now.to_i + timeout).to_s, 32)
      body.store_uint(seqno, 32)
      transfers.each do |t|
        info = CommonMsgInfo.new(
          IntMsgInfo.new(
            tag: "int_msg_info",
            dest: t.destination,
            bounce: t.bounce,
            value: t.value,
          )
        )

        message = Message.new(
          MessageOptions.new(
            info: info,
            body: t.body,
            init: t.init,
          )
        )

        body.store_uint(t.mode, 8)
        body.store_ref(message.cell)
      end

      sign = sign_cell(body.cell, private_key)

      message_body = Builder.new
      message_body.store_bytes(sign.unpack('C*'))
      message_body.store_slice(body.cell.parse)

      info = CommonMsgInfo.new(
        ExtInMsgInfo.new(
          tag: "ext_in_msg_info",
          dest: @address,
        )
      )
      init_t = seqno == 0 ? init : nil
      m_cell = msg_body.cell

      Message.new(
        MessageOptions.new(
          info: info,
          init: init_t,
          body: m_cell,
        )
      )
    end

    private

    def build_state_init()
      data = Builder.new()
      data.store_uint(0, 32)
      data.store_uint(sub_wallet_id, 32)
      data.store_bytes(hex_to_bytes(pubkey))
      data.store_bit(0)

      options = StateInitOptions.new(code: code, data: data.cell)
      TonSdkRuby::StateInit.new(options)
    end
  end
end
