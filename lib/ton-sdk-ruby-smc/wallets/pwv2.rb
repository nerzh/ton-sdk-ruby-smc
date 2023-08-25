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
    The source code and LICENSE of the "ton-preprocessed-wallet-v2":
    https://github.com/pyAndr3w/ton-preprocessed-wallet-v2

"PWV2_CODE = ..." is a compiled version (byte code) of
the "ton-preprocessed-wallet-v2" in the bag of cells
serialization in hexadecimal representation.

  code cell hash(sha256): 45EBBCE9B5D235886CB6BFE1C3AD93B708DE058244892365C9EE0DFE439CB7B5

Respect the rights of open source software. Thanks!
If you notice copyright violation, please create an issue.
https://github.com/nerzh/ton-sdk-ruby-smc/issues
=end

module TonSdkRubySmc
  include TonSdkRuby

  PWV2_CODE = 'B5EE9C7241010101003D000076FF00DDD40120F90001D0D33FD30FD74CED44D0D3FFD70B0F20A4830FA90822C8CBFFCB0FC9ED5444301046BAF2A1F823BEF2A2F910F2A3F800ED552E766412'

  class PWV2Transfer
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

  class PWV2
    attr_accessor :code, :pubkey, :init, :address

    def initialize(pubkey, wc = 0)
      @pubkey = pubkey
      @code = deserialize(hex_to_bytes(PWV2_CODE)).first
      @init = build_state_init
      @address = Address.new("#{wc}:#{init.cell.hash}")
    end
    
    def self.parse_storage(storage_slice)
      {
        pubkey: storage_slice.load_bytes(32),
        seqno: storage_slice.load_uint(16)
      }
    end
    
    def build_transfer(transfers, seqno, private_key, is_init = false, timeout = 60)
      raise 'Transfers must be an [PWV2Transfer]' unless transfers.size > 0 && transfers.first.is_a?(PWV2Transfer)
      raise "PWV2 can handle only 255 transfers at once" unless transfers.size <= 255
      actions = []
    
      transfers.each do |t|
        info = CommonMsgInfo.new(
          IntMsgInfo.new(
            tag: 'int_msg_info',
            dest: t.destination,
            bounce: t.bounce,
            value: t.value
          )
        )
    
        action = OutAction.new(
          ActionSendMsg.new(
            tag: 'action_send_msg',
            mode: t.mode,
            out_msg: Message.new(
              MessageOptions.new(
                info: info,
                body: t.body,
                init: t.init
              )
            )
          )
        )
    
        actions.push(action)
      end
    
      outlist = OutList.new(OutListOptions.new(actions: actions))
    
      msg_inner = Builder.new
        # .store_uint((Time.now.to_i + timeout).to_s, 64)
        .store_uint((1000 + timeout).to_s, 64)
        .store_uint(seqno.to_s, 16)
        .store_ref(outlist.cell)
        .cell
        
      sign = sign_cell(msg_inner, private_key)
    
      msg_body = Builder.new
        .store_bytes(sign.unpack('C*'))
        .store_ref(msg_inner)
        
      info = CommonMsgInfo.new(
        ExtInMsgInfo.new(
          tag: 'ext_in_msg_info',
          dest: @address
        )
      )
    
      init_t = is_init ? init : nil
      
      m_cell = msg_body.cell

      Message.new(
        MessageOptions.new(
          info: info,
          init: init_t,
          body: m_cell
        )
      )
    end

    private

    def build_state_init()
      data = Builder.new() 
      data.store_bytes(hex_to_bytes(pubkey))
      data.store_uint(0, 16)
      
      options = StateInitOptions.new(code: code, data: data.cell)
      TonSdkRuby::StateInit.new(options)
    end
  end
end
























