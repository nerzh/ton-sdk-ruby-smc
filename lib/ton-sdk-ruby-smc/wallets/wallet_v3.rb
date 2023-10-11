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
The source code and LICENSE of the "wallet v3 r2" smart contract:
https://github.com/toncenter/tonweb/blob/master/src/contract/wallet/WalletSources.md

"WALLET_V3_CODE = ..." is a compiled version (byte code) of
the smart contract "wallet-v3-r2-code.fif" in the bag of cells
serialization in hexadecimal representation.

code cell hash(sha256): 84DAFA449F98A6987789BA232358072BC0F76DC4524002A5D0918B9A75D2D599

Respect the rights of open source software. Thanks! :)
If you notice copyright violation, please create an issue:
https://github.com/nerzh/ton-sdk-ruby-smc/issues
=end

module TonSdkRubySmc
  include TonSdkRuby

  WALLET_V3_CODE = "B5EE9C724101010100710000DEFF0020DD2082014C97BA218201339CBAB19F71B0ED44D0D31FD31F31D70BFFE304E0A4F2608308D71820D31FD31FD31FF82313BBF263ED44D0D31FD31FD3FFD15132BAF2A15144BAF2A204F901541055F910F2A3F8009320D74A96D307D402FB00E8D101A4C8CB1FCB1FCBFFC9ED5410BD6DAD"
  SUB_WALLET_ID = 698983191

  class WalletV3Transfer
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

  class WalletV3
    include TonSdkRuby
    extend TonSdkRuby
    extend TonSdkRubySmc

    attr_accessor :code, :pubkey, :init, :address, :sub_wallet_id

    def initialize(pubkey, wc = 0, sub_wallet_id = SUB_WALLET_ID)
      @pubkey = pubkey
      @sub_wallet_id = sub_wallet_id
      @code = deserialize(hex_to_bytes(WALLET_V3_CODE)).first
      @init = build_state_init
      @address = Address.new("#{wc}:#{init.cell.hash}")
    end

    def self.parse_storage(storage_slice)
      raise 'Must be a Slice' unless storage_slice.is_a?(Slice)
      {
        seqno: storage_slice.load_uint(32),
        sub_wallet_id: storage_slice.load_uint(32),
        pubkey: storage_slice.load_bytes(32)
      }
    end

    def build_transfer(transfers, seqno, private_key, is_init = false, timeout = 60)
      raise 'Transfers must be an [WalletV3Transfer]' unless transfers.size > 0 && transfers.first.is_a?(WalletV3Transfer)
      raise "Wallet v3 can handle only 4 transfers at once" unless transfers.size <= 4
      body = Builder.new()
      body.store_uint(sub_wallet_id, 32)
      body.store_uint((Time.now.to_i + timeout), 32)
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
          tag: 'ext_in_msg_info',
          dest: address
        )
      )
      init_t = is_init ? init : nil
      m_cell = message_body.cell

      message = Message.new(
        MessageOptions.new(
          info: info,
          init: init_t,
          body: m_cell
        )
      )

      message
    end

    private

    def build_state_init()
      data = Builder.new()
      data.store_uint(0, 32)
      data.store_uint(sub_wallet_id, 32)
      data.store_bytes(hex_to_bytes(pubkey))

      options = StateInitOptions.new(code: code, data: data.cell)
      TonSdkRuby::StateInit.new(options)
    end
  end
end
