#!/usr/bin/env ruby
class BlktraceRecord
    attr_accessor :seq, :time, :cpu, :pid, :action
    attr_accessor :dev, :sector, :bytes
    attr_accessor :error, :pdu_len, :pdu_data

    def to_s
        return 'BlktraceRecord:' +
            [seq, time, cpu, pid, "0x%08x" % action, dev, sector, bytes,
             error, pdu_len, pdu_data].join(' ')
    end
end

def read_and_parse_one_record (f)
    puts "\n\n"

    r = BlktraceRecord.new

    # __u32 magic;        /* MAGIC << 8 | version */
    d_magic = f.read(4).unpack('H*')[0]
    # puts d_magic

    # __u32 sequence;     /* event number */
    puts d_seq = f.read(4).unpack('L<')[0]
    r.seq = d_seq

    # __u64 time;     /* in microseconds */
    puts d_time = f.read(8).unpack('Q<')[0]
    r.time = d_time

    # __u64 sector;       /* disk offset */
    puts d_sector = f.read(8).unpack('Q<')[0]
    r.sector = d_sector

    # __u32 bytes;        /* transfer length */
    puts d_bytes = f.read(4).unpack('L<')[0]
    r.bytes = d_bytes

    # __u32 action;       /* what happened */
    puts "0x%08x" % (d_action = f.read(4).unpack('L<')[0])
    r.action = d_action

    # __u32 pid;      /* who did it */
    puts d_pid = f.read(4).unpack('L<')[0]
    r.pid = d_pid

    # __u32 device;       /* device number */
    puts d_dev = f.read(4).unpack('L<')[0]
    r.dev = d_dev

    # __u32 cpu;      /* on what cpu did it happen */
    puts d_cpu = f.read(4).unpack('L<')[0]
    r.cpu = d_cpu

    # __u16 error;        /* completion error */
    puts d_error = f.read(2).unpack('S<')[0]
    r.error = d_error

    # __u16 pdu_len;      /* length of data after this trace */
    puts d_len = f.read(2).unpack('S<')[0]
    r.pdu_len = d_len

    if d_len > 0
        puts (d_extra = f.read(d_len))
        r.pdu_data = d_extra
    else
        puts "EXTRA DATA EMPTY"
        r.pdu_data = ""
    end

    return r
end

File.open(ARGV[0], "rb") do |f|
    #while not f.eof
    #    read_and_print_one_record(f)
    #end

    4.times do
        record = read_and_parse_one_record(f)
        puts record
    end
end

