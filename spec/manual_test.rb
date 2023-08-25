require 'spec_helper'
require 'pp'
include TonSdkRubySmc




describe TonSdkRubySmc do
  before(:all) do
  end

  it 'manual_test' do
    pk_s = "e4b86837416ee13bfc0556e755011c2a568d92a25e27768df2b8d3c76a67f567"
    sk_s = "9c10a3c105a762d5be4514a7cd660a51ae10cfc7af442d6342c40a24b8e3bc8c"

    pwv2 = TonSdkRubySmc::PWV2.new(pk_s)

    option = PWV2Transfer.new(
      Address.new("0:6eda13af7d950c4dc0da1a780a2fc58a3d5464907eedc7b3895935dc98132ba2"),
      false,
      Coins.new(1),
      3,
      Builder.new().store_uint(0, 32).store_string("Hello").cell
    )

    message = pwv2.build_transfer([option], 0, sk_s)

    expect(message.cell.hash).to eq('6e683ea19f90f492a582b1e64504629b663918c34b2ab103fa8bce1a27bc77da')
  end

  it 'manual_test_2' do
    wallet_v4_test_ds = TonSdkRuby.deserialize(base64_to_bytes("te6cckEBCAEAyQABUQAAAAspqaMXUc5Q68ztD9zHUgosrPZTyB+0nzT5xXCp4bsjx/cYbY3AAQIDwIgCAwIBIAQFAEO/9jsePQjkPjU1x2jEudHn1Z/rrqiTE9d4ZhTt1yON1dnAAgFIBgcAQr+SvwA2hUZR43X7UuhyDRghD0YBoVMOS3PTISzSXdq+vwBBvwosD7WN05GfEUtgHzt7E7D2+NDJKlyw45e3xZjC0P1yAEG/DjPflx5+T4LDKSMezvHE0MIjE3d1UUiI8XIyVHf33naT0ZHp")).first.parse
    parsed_storage = WalletV4.parse_storage(wallet_v4_test_ds)
    p parsed_storage
  end

  it 'manual_test_off_metadata' do
    wallet_v4_test_ds = TonSdkRuby.deserialize(base64_to_bytes("te6cckECBAEAASoAAQ4BSEFIQTogAQH+cXdlcnR5dWlvYXNkZmdoamtsWnhjdmJubTEyMzQ1Njc4OTBxd2VydHl1aW9hc2RmZ2hqa2xaeGN2Ym5tMTIzNDU2Nzg5MHF3ZXJ0eXVpb2FzZGZnaGprbFp4Y3Zibm0xMjM0NTY3ODkwcXdlcnR5dWlvYXNkZmdoamtsWnhjdgIB/mJubTEyMzQ1Njc4OTBxd2VydHl1aW9hc2RmZ2hqa2xaeGN2Ym5tMTIzNDU2Nzg5MHF3ZXJ0eXVpb2FzZGZnaGprbFp4Y3Zibm0xMjM0NTY3ODkwcXdlcnR5dWlvYXNkZmdoamtsWnhjdmJubTEyMzQ1Njc4OTBxd2VydHl1aW8DADRhc2RmZ2hqa2xaeGN2Ym5tMTIzNDU2Nzg5MJHi95c=")).first.parse
    parsed_storage = MetaData.parse_token_metadata(wallet_v4_test_ds)
    p parsed_storage
  end

  it 'manual_test_on_metadata' do
    wallet_v4_test_ds = TonSdkRuby.deserialize(base64_to_bytes("te6cckECDwEAAU4AAQMAwAECASACBAFDv/CC62Y7V6ABkvSmrEZyiN8t/t252hvuKPZSHIvr0h8ewAMAggBodHRwczovL3B1bmstbWV0YXZlcnNlLmZyYTEuZGlnaXRhbG9jZWFuc3BhY2VzLmNvbS9sb2dvL3B1bmsucG5nAgEgBQoCASAGCAFBv0VGpv/ht5z92GutPbh0MT3N4vsF5qdKp/NVLZYXx50TBwAMACRQVU5LAUG/btT5QqeEjOLLBmt3oRKMah/4xD9Dii3OJGErqf+riwMJAAoAUFVOSwIBIAsNAUG/Ugje9G9aHU+dzmarMJ9KhRMF8Wb5Hvedkj71jjT5ogkMAFAATGVnZW5kYXJ5IHRva2VuIG9uIGxlZ2VuZGFyeSBibG9ja2NoYWluAUG/XQH6XjwGkBxFBGxrLdzqWvdk/qDu1yoQ1ATyMSzrJH0OAAQAOeHryaE=")).first.parse
    parsed_storage = MetaData.parse_token_metadata(wallet_v4_test_ds)
    puts '+++++++++'
    pp parsed_storage
  end
end
