// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library file contains data structures and helper methods for parsing
/// `perf.data` files produced by `perf` tool on Linux.
///
/// Format of this file is documented in:
///
///   * https://github.com/torvalds/linux/blob/3e9bff3bbe1355805de919f688bef4baefbfd436/tools/perf/Documentation/perf.data-file-format.txt
///   * https://github.com/torvalds/linux/blob/3e9bff3bbe1355805de919f688bef4baefbfd436/tools/perf/util/header.h
///   * https://github.com/torvalds/linux/blob/3e9bff3bbe1355805de919f688bef4baefbfd436/include/uapi/linux/perf_event.h
///
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// `struct perf_header`: header of the `perf.data` file.
///
/// https://github.com/torvalds/linux/blob/3e9bff3bbe1355805de919f688bef4baefbfd436/tools/perf/util/header.h#L64
final class Header extends Struct {
  @Array(8)
  external Array<Uint8> magic;

  @Uint64()
  external int size;

  @Uint64()
  external int attrSize;

  external FileSection attrs;
  external FileSection data;
  external FileSection eventTypes;

  @Uint64()
  external int flags;

  @Array(3)
  external Array<Uint64> flags1;
}

/// `struct perf_file_section`: section inside `perf.data` file.
///
/// https://github.com/torvalds/linux/blob/3e9bff3bbe1355805de919f688bef4baefbfd436/tools/perf/util/header.h#L59
final class FileSection extends Struct {
  @Uint64()
  external int offset;

  @Uint64()
  external int size;

  @override
  String toString() {
    return 'PerfFileSection{offset=$offset,size=$size}';
  }
}

/// Optional sections inside `perf.data` file.
///
/// The section is present iff corresponding bit in [PerfHeader.flags] is set.
///
/// `PerfFileSection` descriptors for present sections will follow in sequence
/// immediately after the data section (i.e. the first `PerfFileSection` will
/// be located at `header.data.offset + header.data.size` offset).
///
/// See [PerfData.readOptionalSectionHeaders].
///
/// https://github.com/torvalds/linux/blob/3e9bff3bbe1355805de919f688bef4baefbfd436/tools/perf/util/header.h#L15
enum OptionalSection {
  reserved,
  tracingData,
  buildId,
  hostname,
  osRelease,
  version,
  arch,
  nrCpus,
  cpuDesc,
  cpuId,
  totalMem,
  cmdLine,
  eventDesc,
  cpuTopology,
  numaTopology,
  branchStack,
  groupDesc,
  auxTrace,
  stat,
  cache,
  sampleTime,
  sampleTopology,
  clockId,
  dirFormat,
  bpfProgInfo,
  bpfBtf,
  compressed,
  cpuPmuCaps,
  clockData,
  hybridTopology,
  pmuCaps
}

/// `perf_event_header`: common header of all event entries.
///
/// https://github.com/torvalds/linux/blob/3e9bff3bbe1355805de919f688bef4baefbfd436/include/uapi/linux/perf_event.h#L815
final class EventHeader extends Struct {
  @Uint32()
  external int type;

  @Uint16()
  external int misc;

  @Uint16()
  external int size;

  @override
  String toString() => 'PerfEventHeader{type=$type,misc=$misc,size=$size}';
}

/// `perf_event_attr`: configuration of the event monitored by `perf`.
///
/// https://github.com/torvalds/linux/blob/3e9bff3bbe1355805de919f688bef4baefbfd436/include/uapi/linux/perf_event.h#L389
final class EventAttr extends Struct {
  /// Major type: hardware/software/tracepoint/etc.
  ///
  /// See [EventType].
  @Uint32()
  external int type;

  @Uint32()
  external int size;

  /// Type specific configuration information.
  @Uint64()
  external int config;

  @Uint64()
  external int samplePeriodOrFreq;

  @Uint64()
  external int sampleType;

  @Uint64()
  external int readFormat;

  /// Various bit fields which we currently don't care about.
  ///
  /// https://github.com/torvalds/linux/blob/3e9bff3bbe1355805de919f688bef4baefbfd436/include/uapi/linux/perf_event.h#L414
  @Uint64()
  external int flags;

  @Uint32()
  external int wakeupEventOrWatermark;
  @Uint32()
  external int bpType;

  /// Union of `bp_addr`/`kprobe_func`/`uprobe_path`/`config1`
  @Uint64()
  external int config1;

  /// Union of `bp_len`/`kprobe_addr`/`probe_offset`/`config2`
  @Uint64()
  external int config2;

  /// One of `enum perf_branch_sample_type`
  @Uint64()
  external int branchSampleType;

  /// Defines set of user regs to dump on samples.
  /// See asm/perf_regs.h for details.
  @Uint64()
  external int sampleRegsUser;

  /// Defines size of the user stack to dump on samples.
  @Uint32()
  external int sampleStackUser;

  @Int32()
  external int clockid;

  /// Defines set of regs to dump for each sample
  /// state captured on:
  ///  - precise = 0: PMU interrupt
  ///  - precise > 0: sampled instruction
  ///
  /// See asm/perf_regs.h for details.
  @Uint64()
  external int sampleRegsIntr;

  /// Wakeup watermark for AUX area
  @Uint32()
  external int auxWatermark;
  @Uint16()
  external int sampleMaxStack;
  @Uint16()
  external int reserved2;
  @Uint32()
  external int auxSampleSize;
  @Uint32()
  external int reserved3;

  /// User provided data if sigtrap=1, passed back to user via
  /// siginfo_t::si_perf_data, e.g. to permit user to identify the event.
  /// Note, siginfo_t::si_perf_data is long-sized, and sig_data will be
  /// truncated accordingly on 32 bit architectures.
  @Uint64()
  external int sigData;

  /// Extension of config2
  @Uint64()
  external int config3;
}

/// `enum perf_event_type`: type of the recorded event.
///
/// https://github.com/torvalds/linux/blob/3e9bff3bbe1355805de919f688bef4baefbfd436/include/uapi/linux/perf_event.h#L838
extension type const EventType(int _) implements int {
  /// `PERF_RECORD_MMAP`
  ///
  /// https://github.com/torvalds/linux/blob/3e9bff3bbe1355805de919f688bef4baefbfd436/include/uapi/linux/perf_event.h#L879
  static const mmap = EventType(1);

  /// `PERF_RECORD_SAMPLE`
  ///
  /// https://github.com/torvalds/linux/blob/3e9bff3bbe1355805de919f688bef4baefbfd436/include/uapi/linux/perf_event.h#L947
  static const sample = EventType(9);

  /// `PERF_RECORD_MMAP2`
  ///
  /// https://github.com/torvalds/linux/blob/3e9bff3bbe1355805de919f688bef4baefbfd436/include/uapi/linux/perf_event.h#L1035
  static const mmap2 = EventType(10);
}

/// `enum perf_type_id`
///
/// https://github.com/torvalds/linux/blob/3e9bff3bbe1355805de919f688bef4baefbfd436/include/uapi/linux/perf_event.h#L29
extension type const TypeId(int index) implements int {
  static const hardware = TypeId(0);
  static const software = TypeId(1);
  static const tracepoint = TypeId(2);
  static const hwCache = TypeId(3);
  static const raw = TypeId(4);
  static const breakpoint = TypeId(5);
}

/// `enum perf_event_sample_format`: additional information recorded for sample.
///
/// Bits that can be set in [PerfEventAttr.sampleType] to request information
/// in the overflow packets.
///
/// https://github.com/torvalds/linux/blob/3e9bff3bbe1355805de919f688bef4baefbfd436/include/uapi/linux/perf_event.h#L139
extension type const SampleFormat(int bit) implements int {
  /// `PERF_SAMPLE_IP`
  static const ip = SampleFormat(1 << 0);

  /// `PERF_SAMPLE_TID`
  static const tid = SampleFormat(1 << 1);

  /// `PERF_SAMPLE_TIME`
  static const time = SampleFormat(1 << 2);

  /// `PERF_SAMPLE_ADDR`
  static const addr = SampleFormat(1 << 3);

  /// `PERF_SAMPLE_READ`
  static const read = SampleFormat(1 << 4);

  /// `PERF_SAMPLE_CALLCHAIN`
  static const callchain = SampleFormat(1 << 5);

  /// `PERF_SAMPLE_ID`
  static const id = SampleFormat(1 << 6);

  /// `PERF_SAMPLE_CPU`
  static const cpu = SampleFormat(1 << 7);

  /// `PERF_SAMPLE_PERIOD`
  static const period = SampleFormat(1 << 8);

  /// `PERF_SAMPLE_STREAM_ID`
  static const streamId = SampleFormat(1 << 9);

  /// `PERF_SAMPLE_RAW`
  static const raw = SampleFormat(1 << 10);

  /// `PERF_SAMPLE_BRANCH_STACK`
  static const branchStack = SampleFormat(1 << 11);

  /// `PERF_SAMPLE_REGS_USER`
  static const regsUser = SampleFormat(1 << 12);

  /// `PERF_SAMPLE_STACK_USER`
  static const stackUser = SampleFormat(1 << 13);

  /// `PERF_SAMPLE_WEIGHT`
  static const weight = SampleFormat(1 << 14);

  /// `PERF_SAMPLE_DATA_SRC`
  static const dataSrc = SampleFormat(1 << 15);

  /// `PERF_SAMPLE_IDENTIFIER`
  static const identifier = SampleFormat(1 << 16);

  /// `PERF_SAMPLE_TRANSACTION`
  static const transaction = SampleFormat(1 << 17);

  /// `PERF_SAMPLE_REGS_INTR`
  static const regsIntr = SampleFormat(1 << 18);

  /// `PERF_SAMPLE_PHYS_ADDR`
  static const physAddr = SampleFormat(1 << 19);

  /// `PERF_SAMPLE_AUX`
  static const aux = SampleFormat(1 << 20);

  /// `PERF_SAMPLE_CGROUP`
  static const cgroup = SampleFormat(1 << 21);

  /// `PERF_SAMPLE_DATA_PAGE_SIZE`
  static const dataPageSize = SampleFormat(1 << 22);

  /// `PERF_SAMPLE_CODE_PAGE_SIZE`
  static const codePageSize = SampleFormat(1 << 23);

  /// `PERF_SAMPLE_WEIGHT_STRUCT`
  static const weightStruct = SampleFormat(1 << 24);

  static const bitNames = {
    ip: "ip",
    tid: "tid",
    time: "time",
    addr: "addr",
    read: "read",
    callchain: "callchain",
    id: "id",
    cpu: "cpu",
    period: "period",
    streamId: "streamId",
    raw: "raw",
    branchStack: "branchStack",
    regsUser: "regsUser",
    stackUser: "stackUser",
    weight: "weight",
    dataSrc: "dataSrc",
    identifier: "identifier",
    transaction: "transaction",
    regsIntr: "regsIntr",
    physAddr: "physAddr",
    aux: "aux",
    cgroup: "cgroup",
    dataPageSize: "dataPageSize",
    codePageSize: "codePageSize",
    weightStruct: "weightStruct",
  };

  static String format(int mask) {
    return SampleFormat.bitNames.entries
        .where((e) => (mask & e.key) != 0)
        .map((e) => e.value)
        .join('|');
  }
}

/// `PERF_RECORD_MMAP`
///
/// The `MMAP` events record the `PROT_EXEC` mappings so that we can
///	correlate userspace `IP`s to code.
///
/// https://github.com/torvalds/linux/blob/3e9bff3bbe1355805de919f688bef4baefbfd436/include/uapi/linux/perf_event.h#L879
final class MmapEvent extends Struct {
  external EventHeader header;

  @Uint32()
  external int pid;

  @Uint32()
  external int tid;

  @Uint64()
  external int addr;

  @Uint64()
  external int len;

  @Uint64()
  external int pgoffs;

  @Array.variable()
  external Array<Uint8> filename;

  @override
  String toString() => 'MmapEvent{addr=${addr.formatAsAddress()},'
      'len=$len,pgoffs=$pgoffs,'
      'filename=${filename.toStringFromZeroTerminated()}}';
}

final class BuildId extends Struct {
  @Uint8()
  external int size;

  @Uint8()
  external int reserved1;

  @Uint16()
  external int reserved2;

  @Array(20)
  external Array<Uint8> buildId;
}

final class Ino extends Struct {
  @Uint32()
  external int maj;

  @Uint32()
  external int min;

  @Uint64()
  external int ino;

  @Uint64()
  external int inoGeneration;
}

final class BuildIdOrIno extends Union {
  external BuildId buildId;
  external Ino ino;
}

/// `PERF_RECORD_MMAP2`
///
/// The `MMAP2` records are an augmented version of `MMAP` (see [MapEvent]),
/// they add `maj`, `min`, `ino` numbers to be used to uniquely identify each
/// mapping.
///
/// https://github.com/torvalds/linux/blob/3e9bff3bbe1355805de919f688bef4baefbfd436/include/uapi/linux/perf_event.h#L1035
final class Mmap2Event extends Struct {
  external EventHeader header;

  @Uint32()
  external int pid;

  @Uint32()
  external int tid;

  @Uint64()
  external int addr;

  @Uint64()
  external int len;

  @Uint64()
  external int pgoffs;

  external BuildIdOrIno buildIdOrIno;

  @Uint32()
  external int prot;

  @Uint32()
  external int flags;

  @Array.variable()
  external Array<Uint8> filename;

  @override
  String toString() => 'Mmap2Event{addr=${addr.formatAsAddress()},'
      'len=$len,pgoffs=$pgoffs,'
      'filename=${filename.toStringFromZeroTerminated()}}';
}

extension ArrayToString on Array<Uint8> {
  String toStringFromFixedLength(int length) =>
      String.fromCharCodes([for (var i = 0; i < length; i++) this[i]]);

  String toStringFromZeroTerminated() {
    final sb = StringBuffer();
    for (var i = 0; this[i] != 0; i++) {
      sb.writeCharCode(this[i]);
    }
    return sb.toString();
  }
}

extension FormatAsAddress on int {
  String formatAsAddress() => toRadixString(16);
}

const int kb = 1024;
const int mb = 1024 * kb;

final class StreamingSectionReader {
  final RandomAccessFile f;
  final FileSection section;

  final chunk = Uint8List(256 * mb);

  /// Number of bytes available in the chunk.
  int chunkBytes = 0;

  /// Offset from the start of the section to the start of the chunk.
  int chunkOffset = 0;

  /// Position within the chunk.
  int pos = 0;

  StreamingSectionReader(this.f, this.section) {
    f.setPositionSync(section.offset);
    refill();
  }

  bool ensure(int bytes) {
    if (chunkBytes < (pos + bytes)) {
      refill();
    }
    return chunkBytes >= (pos + bytes);
  }

  void refill() {
    final int leftOverBytes = chunkBytes - pos;
    for (int i = 0; i < leftOverBytes; i++) {
      chunk[i] = chunk[i + pos];
    }
    chunkOffset += pos;
    pos = 0;

    // Are there any more bytes left to read?
    if (chunkOffset >= section.size) {
      chunkBytes = 0;
      return;
    }

    print(
        "processed $chunkOffset bytes of ${section.size} total (${(chunkOffset / section.size * 100).floor()} %)");

    final bytesAlreadyRead = chunkOffset + leftOverBytes;
    final bytesToRead =
        math.min(section.size - bytesAlreadyRead, chunk.length - leftOverBytes);
    final bytesRead =
        f.readIntoSync(chunk, leftOverBytes, leftOverBytes + bytesToRead);
    chunkBytes = bytesRead + leftOverBytes;
  }
}

final class PerfData {
  final RandomAccessFile f;

  final Header header;

  PerfData(this.f)
      : header = Struct.create<Header>(f.readSync(sizeOf<Header>())) {
    final magic = header.magic.toStringFromFixedLength(8);
    if (magic != 'PERFILE2') {
      reportError('Incorrect magic in ${f.path} - $magic');
    }
  }

  List<EventAttr> readAttrs() {
    f.setPositionSync(header.attrs.offset);
    final attrs = f.readSync(header.attrs.size);

    final result = <EventAttr>[];
    int pos = 0;
    while (pos + sizeOf<EventAttr>() < attrs.length) {
      final attr = Struct.create<EventAttr>(attrs, pos);
      result.add(attr);
      pos += attr.size;
    }
    return result;
  }

  Map<OptionalSection, FileSection> readOptionalSectionHeaders() {
    f.setPositionSync(header.data.offset + header.data.size);
    final optionalHeaders =
        f.readSync(sizeOf<FileSection>() * OptionalSection.values.length);

    int headerIndex = 0;
    return {
      for (final flag in OptionalSection.values)
        if (header.flags & (1 << flag.index) != 0)
          flag: Struct.create<FileSection>(
              optionalHeaders, sizeOf<FileSection>() * headerIndex++),
    };
  }

  late final _dataReader = StreamingSectionReader(f, header.data);

  @pragma('vm:prefer-inline')
  void readEvents(bool Function(int type, Uint8List chunk, int pos) callback) {
    final reader = _dataReader;

    while (true) {
      if (!reader.ensure(sizeOf<EventHeader>())) {
        // No more events.
        return;
      }

      // Note: `reader.ensure` might refill the chunk and invalidate
      // created struct so extract values eagerly.
      final EventHeader(:type, :size) =
          Struct.create<EventHeader>(reader.chunk, reader.pos);
      if (!reader.ensure(size)) {
        return;
      }

      // At this point we are guaranteed to have the whole event in the chunk
      // starting at `reader.pos`.
      if (!callback(type, reader.chunk, reader.pos)) {
        reader.pos += size;
        return;
      }
      reader.pos += size;
    }
  }

  Never reportError(String message) => throw ParseError(f.path, message);
}

final class ParseError extends Error {
  final String file;
  final String message;

  ParseError(this.file, this.message);

  @override
  String toString() => 'Failed to parse $file: $message';
}
