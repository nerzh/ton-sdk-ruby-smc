require 'spec_helper'
require 'pp'
include TonSdkRubySmc

describe TonSdkRubySmc do
  before(:all) do
  end

  it 'manual_test' do
    m = TonMnemonic.new()
    
    pk_s = "e4b86837416ee13bfc0556e755011c2a568d92a25e27768df2b8d3c76a67f567"
    sk_s = "9c10a3c105a762d5be4514a7cd660a51ae10cfc7af442d6342c40a24b8e3bc8c"
    # full = sk_s + pk_s
    m.keys = {
      public: pk_s,
      secret: sk_s
    }
    
    pwv2 = TonSdkRubySmc::PWV2.new(m.keys[:public])
    
    option = PWV2Transfer.new(
      Address.new("0:6eda13af7d950c4dc0da1a780a2fc58a3d5464907eedc7b3895935dc98132ba2"),
      false,
      Coins.new(1),
      3,
      Builder.new().store_uint(0, 32).store_string("Hello").cell
    )
    
    message = pwv2.build_transfer([option], 0, m.keys[:secret])
    # message = pwv2.build_transfer([option], 0, full)
    
    
    # pp message.cell
    # p serialize(message.cell)
    p TonSdkRuby.bytes_to_base64(serialize(message.cell))
    
    p "m hash", message.cell.hash
    # p TonSdkRubySmc::PWV2_CODE
  end
end



















