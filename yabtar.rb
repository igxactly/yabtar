#!/usr/bin/env ruby

File.open(ARGV[0]) do |f|
    f.each_byte do |b|
        printf "0x%02x\n", b #.to_s(16)
    end
end


