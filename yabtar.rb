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
        @trace_batches = Hash.new
        @num_batches = 0

        @totals = Hash.new
        @minimums = Hash.new
        @maximums = Hash.new

        @totals['DRV-Q'] = 0
        @totals['C-DRV'] = 0
        @minimums['DRV-Q'] = 0
        @minimums['C-DRV'] = 0
        @maximums['DRV-Q'] = 0
        @maximums['C-DRV'] = 0
    end

    def add_record (r)
        a = case (r.action & 0x0000FFFF)
            when 0x0001
                'Q'
            when 0x0011
                'DRV'
            when 0x0008
                'C'
            end

        if @trace_batches[r.sector] == nil or a == 'Q' # some trace may be dropped?
            @trace_batches[r.sector] = Hash.new
        end

        # if (['Q', 'DRV', 'C'] - recordGroup.keys).empty?
        # ????? Q then DRV then C?
        # end

        recordGroup = @trace_batches[r.sector]

        #TODO: separate blktrace data structure definitions?
=begin

enum blktrace_act {
    __BLK_TA_QUEUE = 1,     /* queued */
    __BLK_TA_BACKMERGE,     /* back merged to existing rq */
    __BLK_TA_FRONTMERGE,        /* front merge to existing rq */
    __BLK_TA_GETRQ,         /* allocated new request */
    __BLK_TA_SLEEPRQ,       /* sleeping on rq allocation */
    __BLK_TA_REQUEUE,       /* request requeued */
    __BLK_TA_ISSUE,         /* sent to driver */
    __BLK_TA_COMPLETE,      /* completed by driver */
    __BLK_TA_PLUG,          /* queue was plugged */
    __BLK_TA_UNPLUG_IO,     /* queue was unplugged by io */
    __BLK_TA_UNPLUG_TIMER,      /* queue was unplugged by timer */
    __BLK_TA_INSERT,        /* insert request */
    __BLK_TA_SPLIT,         /* bio was split */
    __BLK_TA_BOUNCE,        /* bio was bounced */
    __BLK_TA_REMAP,         /* bio was remapped */
    __BLK_TA_ABORT,         /* request aborted */
    __BLK_TA_DRV_DATA,      /* driver-specific binary data */
};

=end

        #FIXME: Hardcoded action lists.
        #FIXME: Move bin/str action representation into a method

        recordGroup.store(a, r)
        # puts @trace_batches, "\n\n"

        #FIXME: Hardcoded action lists.
        if (['Q', 'DRV', 'C'] - recordGroup.keys).empty?
            drv_q = recordGroup['DRV'].time - recordGroup['Q'].time
            c_drv = recordGroup['C'].time - recordGroup['DRV'].time

            if drv_q < 0
                puts "Warning: minus!! %d" % drv_q
                puts r
            end

            if c_drv < 0
                puts "Warning: minus!! %d" % c_drv
                puts r
            end

            @totals['DRV-Q'] += drv_q
            @totals['C-DRV'] += c_drv

            @num_batches += 1

            #FIXME: Hardcoded action lists.
            if (not @minimums['DRV-Q']) or (@minimums['DRV-Q'] == 0) or (@minimums['DRV-Q'] > drv_q)
                @minimums['DRV-Q'] = drv_q
            end

            if (not @minimums['C-DRV']) or (@minimums['C-DRV'] == 0) or (@minimums['C-DRV'] > c_drv)
                @minimums['C-DRV'] = c_drv
            end

            if (not @maximums['DRV-Q']) or (@maximums['DRV-Q'] < drv_q)
                @maximums['DRV-Q'] = drv_q
            end

            if (not @maximums['C-DRV']) or (@maximums['C-DRV'] < c_drv)
                @maximums['C-DRV'] = c_drv
            end

            @trace_batches.delete(r.sector)
        end
    end

    def get_averages ()
        cnt = @num_batches

        if cnt > 0
            avg_drv_q = @totals['DRV-Q'].to_f / cnt
            avg_c_drv = @totals['C-DRV'].to_f / cnt
        else
            avg_drv_q = avg_c_drv = 0
        end

        return {'DRV-Q'=>avg_drv_q, 'C-DRV'=>avg_c_drv}
    end

    def to_s ()
        cnt = @num_batches
        avg_drv_q = @totals['DRV-Q'].to_f / cnt
        avg_c_drv = @totals['C-DRV'].to_f / cnt

        if @num_batches > 0
            return "BlktraceStatistics: cnt=%u\n  avg DRV-Q=%fus C-DRV=%fus\n  min DRV-Q=%fus C-DRV=%fus\n  max DRV-Q=%fus C-DRV=%fus" %
                ([cnt] + [avg_drv_q, avg_c_drv, @minimums['DRV-Q'], @minimums['C-DRV'], @maximums['DRV-Q'], @maximums['C-DRV']].map{|x| (x / 1000)})
        else
            return "BlktraceStatistics: cnt=%u\n  Nothing is collected" % [cnt]
        end
    end
end

def read_and_parse_one_record (f)
    r = BlktraceRecord.new

    # # # # # #
    # Reference:
    #   struct blk
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
require 'json'

Signal.trap("PIPE", "EXIT")

read_statistics = BlktraceStatistics.new
write_statistics = BlktraceStatistics.new

$count = 0
File.open(ARGV[0], "rb") do |f|
    while not f.eof
        record = read_and_parse_one_record(f)

        rw = case (record.action & 0x00030000)
             when 0x00010000
                 'R'
             when 0x00020000
                 'W'
             else
                 nil
             end

        if rw == 'R'
            # write_statistics.add_record(record)
            read_statistics.add_record(record)
        elsif rw == 'W'
            write_statistics.add_record(record)
        else
            # puts record
        end
    end
end

puts "\n\n"
puts "yabtar_read_stat:", read_statistics
puts "yabtar_write_stat:", write_statistics

puts "\n\n"
File.open(ARGV[1], "w") do |f|
# "total"=>statistics.instance_variable_get(:@totals),
    t = JSON.generate(
        {
            "R"=>
            {
                "min"=>read_statistics.instance_variable_get(:@minimums),
                "max"=>read_statistics.instance_variable_get(:@maximums),
                "mean"=>read_statistics.get_averages
            },
            "W"=>
            {
                "min"=>write_statistics.instance_variable_get(:@minimums),
                "max"=>write_statistics.instance_variable_get(:@maximums),
                "mean"=>write_statistics.get_averages
            }

        })
    puts 'json: ', t
    f.write(t)
end

puts "\n\n"
puts "statistics written to outfile"

