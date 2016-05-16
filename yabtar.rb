#!/usr/bin/env ruby

File.open(ARGV[0], "rb") do |f|
    puts (data = f.read(64)).unpack('H*')

    puts data.unpack('L>*').pack('L<*').unpack('H*')

     #.pack('H*').unpack('N*').pack('V*').unpack('H*')
=begin
    (data = f.read(64)).each_byte do |b|
        puts b.to_s(16)
    end #.to_s() #.pack('H*').unpack('N*').pack('V*').unpack('H*')
=end

=begin
    f.each_byte do |b|
        printf "%02x ", b
    end
=end
end


