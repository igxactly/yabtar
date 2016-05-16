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

class BlktraceStatistics
    def initialize
        @recordsHash = Hash.new
        @statisticsHash = Hash.new

        @statisticsHash['count'] = 0
        @statisticsHash['DRV-Q'] = 0
        @statisticsHash['C-DRV'] = 0
    end

    def add_record (r)
        if @recordsHash[r.sector] == nil
            @recordsHash[r.sector] = Hash.new
        end

        recordGroup = @recordsHash[r.sector]

        #FIXME: Hardcoded action lists.
        #FIXME: Move bin/str action representation into a method
        a = case r.action
        when 0x00110001
            'Q'
        when 0x40010011
            'DRV'
        when 0x00810008
            'C'
        end

        recordGroup.store(a, r)

        # puts @recordsHash, "\n\n"

        if (['Q', 'DRV', 'C'] - recordGroup.keys).empty?
            @statisticsHash['DRV-Q'] += recordGroup['DRV'].time - recordGroup['Q'].time
            @statisticsHash['C-DRV'] += recordGroup['C'].time - recordGroup['DRV'].time
            @statisticsHash['count'] += 1

            @recordsHash.delete(r.sector)
        end
    end

    def to_s ()
        cnt = @statisticsHash['count']
        avg_drv_q = @statisticsHash['DRV-Q'].to_f / cnt / 1000
        avg_c_drv = @statisticsHash['C-DRV'].to_f / cnt / 1000

        return 'BlktraceStatistics: cnt:%u avgDRV-Q:%fus avgC-DRV:%fus' % [cnt, avg_drv_q, avg_c_drv]
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
    # __u64 time;     /* in microseconds */ ??? it seems it is not US but NS
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

#################
# main program flow starts here

Signal.trap("PIPE", "EXIT")

statistics = BlktraceStatistics.new

File.open(ARGV[0], "rb") do |f|
    while not f.eof
        record = read_and_parse_one_record(f)
        statistics.add_record(record)

        puts record
    end
end

puts "\n\n"
puts statistics


