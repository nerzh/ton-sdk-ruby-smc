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

require 'ton-sdk-ruby'
require_relative './ton-sdk-ruby-smc/helpers/constants'
require_relative './ton-sdk-ruby-smc/version'
require_relative './ton-sdk-ruby-smc/wallets/pwv2'
require_relative './ton-sdk-ruby-smc/wallets/wallet_v3'
require_relative './ton-sdk-ruby-smc/wallets/wallet_v4'
require_relative './ton-sdk-ruby-smc/helpers/helpers'
require_relative './ton-sdk-ruby-smc/tokens/jetton'
require_relative './ton-sdk-ruby-smc/tokens/nft'
require_relative './ton-sdk-ruby-smc/tokens/metadata'
require_relative './ton-sdk-ruby-smc/wallets/highload_wallet_v2'


module TonSdkRubySmc
end
