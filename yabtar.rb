#!/usr/bin/env ruby

def read_and_print_one_record (f)
    # __u32 magic;        /* MAGIC << 8 | version */
    puts (d_magic = f.read(4)).unpack("H*")

    # __u32 sequence;     /* event number */
    puts (d_seq = f.read(4)).unpack('L<')

    # __u64 time;     /* in microseconds */
    puts (d_time = f.read(8)).unpack('Q<')

    # __u64 sector;       /* disk offset */
    puts (d_sector = f.read(8)).unpack('Q<')

    # __u32 bytes;        /* transfer length */
    puts (d_bytes = f.read(4)).unpack('L<')

    # __u32 action;       /* what happened */
    # puts "b%032b" % (data = f.read(4)).unpack('L<') #.pack('L<*')
    puts "0x%08x" % (d_action = f.read(4)).unpack('L<') #.pack('L<*')

    # __u32 pid;      /* who did it */
    puts (d_pid = f.read(4)).unpack('L<')

    # __u32 device;       /* device number */
    puts (d_dev = f.read(4)).unpack('L<')

    # __u32 cpu;      /* on what cpu did it happen */
    puts (d_cpu = f.read(4)).unpack('L<')

    # __u16 error;        /* completion error */
    puts (d_error = f.read(2)).unpack('S<')

    # __u16 pdu_len;      /* length of data after this trace */
    puts "pdu_len:"
    puts (d_len = f.read(2)).unpack('S<')
    len = d_len.unpack('S<')[0]

    if len > 0
        puts (d_extra = f.read(len))
    else
        puts "EXTRA DATA EMPTY"
    end
end

File.open(ARGV[0], "rb") do |f|
    #while not f.eof
    #    read_and_print_one_record(f)
    #end

    4.times do
        read_and_print_one_record(f)
    end
end

