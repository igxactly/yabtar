#!/usr/bin/env ruby
class BlktraceRecord
    attr_accessor :seq, :time, :cpu, :pid, :action
    attr_accessor :dev, :sector, :bytes
    attr_accessor :error, :pdu_len, :pdu_data

    def to_s
        return 'BlktraceRecord:' +
            [seq, time, cpu, pid, "0x%08x" % action, dev, sector, bytes,
             error, pdu_len, pdu_data.gsub(/[\x00-\x08\x0A-\x1F\x7F]/, ' ')].join(' ')
    end
end

def read_and_parse_one_record (f)
    r = BlktraceRecord.new

    # # # # # #
    # Reference:
    #   struct blk_trace
    #    - definition is in include/uapi/linux/blktrace_api.h
    #
    # __u32 magic;        /* MAGIC << 8 | version */
    # __u32 sequence;     /* event number */
    # __u64 time;     /* in microseconds */
    # __u64 sector;       /* disk offset */
    # __u32 bytes;        /* transfer length */
    # __u32 action;       /* what happened */
    # __u32 pid;      /* who did it */
    # __u32 device;       /* device number */
    # __u32 cpu;      /* on what cpu did it happen */
    # __u16 error;        /* completion error */
    # __u16 pdu_len;      /* length of data after this trace */

    d_magic = f.read(4).unpack('H*')[0]
    r.seq = f.read(4).unpack('L<')[0]
    r.time = f.read(8).unpack('Q<')[0]
    r.sector = f.read(8).unpack('Q<')[0]
    r.bytes = f.read(4).unpack('L<')[0]
    r.action = f.read(4).unpack('L<')[0]
    r.pid = f.read(4).unpack('L<')[0]
    r.dev = f.read(4).unpack('L<')[0]
    r.cpu = f.read(4).unpack('L<')[0]
    r.error = f.read(2).unpack('S<')[0]
    r.pdu_len = f.read(2).unpack('S<')[0]

    if r.pdu_len > 0
        r.pdu_data = f.read(r.pdu_len)
    else
        r.pdu_data = ""
    end

    return r
end

Signal.trap("PIPE", "EXIT")

File.open(ARGV[0], "rb") do |f|
    while not f.eof
        record = read_and_parse_one_record(f)
        puts record
    end
end

