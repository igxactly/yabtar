#!/usr/bin/env ruby

File.open(ARGV[0], "rb") do |f|
=begin
    puts (data = f.read(64)).unpack('H*')
    puts data.unpack('L>*').pack('L<*').unpack('H*')
=end

    # __u32 magic;        /* MAGIC << 8 | version */
    puts (data = f.read(4)).unpack('L>*').pack('L<*').unpack('H*')

    # __u32 sequence;     /* event number */
    puts (data = f.read(4)).unpack('L>*').pack('L<*').unpack('L*')

    # __u64 time;     /* in microseconds */
    puts (data = f.read(8)).unpack('Q>*').pack('Q<*').unpack('Q*')

    # __u64 sector;       /* disk offset */
    puts (data = f.read(8)).unpack('Q>*').pack('Q<*').unpack('Q*')

    # __u32 bytes;        /* transfer length */
    puts (data = f.read(4)).unpack('L>*').pack('L<*').unpack('L*')

    # __u32 action;       /* what happened */
    # puts "b%032b" % (data = f.read(4)).unpack('L<') #.pack('L<*')
    puts "0x%08x" % (data = f.read(4)).unpack('L<') #.pack('L<*')

    # __u32 pid;      /* who did it */
    puts (data = f.read(4)).unpack('L>*').pack('L<*').unpack('L*')

    # __u32 device;       /* device number */
    puts (data = f.read(4)).unpack('L>*').pack('L<*').unpack('L*')

    # __u32 cpu;      /* on what cpu did it happen */
    puts (data = f.read(4)).unpack('L>*').pack('L<*').unpack('L*')

    # __u16 error;        /* completion error */
    puts (data = f.read(2)).unpack('S>*').pack('S<*').unpack('S*')

    # __u16 pdu_len;      /* length of data after this trace */
    puts "pdu_len:"
    puts (data = f.read(2)).unpack('S<')
    len = data.unpack('S<')[0]

    puts (data = f.read(len))

    #AGAIN
    # __u32 magic;        /* MAGIC << 8 | version */
    puts (data = f.read(4)).unpack('L>*').pack('L<*').unpack('H*')
end
