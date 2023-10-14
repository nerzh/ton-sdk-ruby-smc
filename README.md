# ton-sdk-ruby-smc

Ruby library for interaction with TON (The Open Network) smart contract

## Installation

Install ton-sdk-ruby-smc:

- `gem install ton-sdk-ruby-smc`

## Example

```ruby
require 'ton-sdk-ruby'
require 'ton-sdk-ruby-smc'

class TonSmc
  include TonSdkRuby
  include TonSdkRubySmc
  
  def send_wallet_v3
    api_key = "..."
    t_center = TonCenter.new(api_key)
    provider = Provider.new(t_center)
    
    # Create mnemonic
    # mnemonic = TonMnemonic.parse("seed phrase")
    mnemonic = TonMnemonic.new
    public = mnemonic.keys[:public]
    secret = mnemonic.keys[:secret]
    p 'mnemonic', mnemonic.seed
    p 'public', public
    p 'secret', secret
    
    # Create wallet_v3
    wallet = WalletV3.new(public)
    address = wallet.address.to_s({bounceable: true})
    p "transfer > 0.2 TON to this address:", address
    
    # Awaiting deposit
    p 'awaiting deposit ...'
    while true
      sleep(1)
      balance = provider.get_address_balance(address)['result']
      break if (balance.to_f / 1_000_000_000) > 0.2
    end
    p 'got deposit, initializing transfer to itself...'
    
    comment = Builder.new.store_uint(0, 32).store_string('My first transaction').cell
    transfers = [
      WalletV3Transfer.new(Address.new(address), true, Coins.new(0.001), 3, comment)
    ]
    # In first transaction wallet will be deployed, seqno = 0 and is_init = true
    # in case of first transaction. Seqno can be received later using wallet.parse_storage
    seqno = 0
    is_init = true
    transfer = wallet.build_transfer(transfers, seqno, secret, is_init)
    boc = bytes_to_base64(serialize(transfer.cell))
    p "Send BOC", boc
    # Send an external message
    p provider.send_boc(boc)
  end

  def send_wallet_v4
    api_key = "..."
    provider = Provider.new(TonCenter.new(api_key))

    # Create mnemonic
    # mnemonic = TonMnemonic.parse("...")
    mnemonic = TonMnemonic.new
    public = mnemonic.keys[:public]
    secret = mnemonic.keys[:secret]
    p 'mnemonic', mnemonic.seed
    p 'public', public
    p 'secret', secret

    # Create wallet_v4
    wallet = WalletV4.new(public)
    address = wallet.address.to_s({bounceable: true})
    p "transfer > 0.2 TON to this address:", address

    # Awaiting deposit
    p 'awaiting deposit ...'
    while true
      sleep(1)
      balance = provider.get_address_balance(address)['result']
      break if (balance.to_f / 1_000_000_000) > 0.2
    end
    p 'got deposit, initializing transfer to itself...'

    comment = Builder.new.store_uint(0, 32).store_string('My first transaction').cell
    transfers = [
      WalletV4Transfer.new(Address.new(address), true, Coins.new(0.001), 3, comment)
    ]
    # In first transaction wallet will be deployed, seqno = 0 and is_init = true
    # in case of first transaction. Seqno can be received later using wallet.parse_storage
    seqno, init = nil, nil

    while true
      sleep 0.5
      wallet_info = provider.get_extended_address_information(wallet.address.to_s)
      break unless wallet_info["result"].nil?
    end

    if wallet_info["result"]["account_state"]["@type"] == "uninited.accountState"
      seqno, init = 0, true
    else
      init = false
      sleep 0.5
      seqno_result = provider.run_get_method(wallet.address.to_s, "seqno")
      seqno = seqno_result['result']["stack"][0][1].to_i(16)
      puts "got seqno: %d" % seqno
    end

    is_init = init
    transfer = wallet.build_transfer(transfers, seqno, secret, is_init)
    boc = bytes_to_base64(serialize(transfer.cell))
    p "Send BOC", boc
    # Send an external message
    p provider.send_boc(boc)
  end
end

TonSmc.new.send_wallet_v3
TonSmc.new.send_wallet_v4
```

## License

LGPL-3.0

## Mentions

I would like to thank [cryshado](https://github.com/cryshado) for their valuable advice and help in developing this library.
