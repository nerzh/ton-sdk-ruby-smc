#!/usr/bin/env ruby

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

LIB_NAME = 'ton-sdk-ruby-smc'

script_file_path = File.expand_path(File.dirname(__FILE__))
GEM_DIR = "#{script_file_path}"

version_file = "#{GEM_DIR}/lib/#{LIB_NAME}/version.rb"
file = File.read(version_file)

p 'check version'
if file[/VERSION = "(\d+)\.(\d+)\.(\d+)"/]
  major = $1
  minor = $2
  current = $3
  version = "#{major}.#{minor}.#{current.to_i + 1}"
  p version
  data = file
  data.gsub!(/VERSION\s+=[\s\S]+?$/, "VERSION = \"#{version}\"")
  p data
  p version_file
  p 'update version'

  puts "make release? Y/N"
  File.open(version_file, 'wb') { |f| f.write(data) }
  option = gets
  if option.strip.downcase == 'y'
    system(%{cd #{GEM_DIR} && git add .})
    system(%{cd #{GEM_DIR} && git commit -m 'version #{version}'})
    system(%{cd #{GEM_DIR} && bash -lc 'rake release'})
  end
end

