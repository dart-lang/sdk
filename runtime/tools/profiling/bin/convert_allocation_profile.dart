// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ffi';

import 'package:fixnum/fixnum.dart' hide Int32;

import 'package:profiling/src/perf/perf_data.dart';
import 'package:profiling/src/symbols.dart';
import 'package:profiling/src/pprof/generated/profile.pb.dart' as pprof;

/// `PERF_RECORD_SAMPLE` with the following optional fields:
///
/// `PERF_SAMPLE_IP`, `PERF_SAMPLE_TID`, `PERF_SAMPLE_TIME`, `PERF_SAMPLE_CALLCHAIN`,
/// `PERF_SAMPLE_CPU`, `PERF_SAMPLE_PERIOD`, `PERF_SAMPLE_RAW`.
///
/// https://github.com/torvalds/linux/blob/3e9bff3bbe1355805de919f688bef4baefbfd436/include/uapi/linux/perf_event.h#L947
final class SampleEvent extends Struct {
  external EventHeader header;

  /// Enabled by `PERF_SAMPLE_IP`
  @Uint64()
  external int ip;

  /// Enabled by `PERF_SAMPLE_TID`
  @Uint32()
  external int pid;

  /// Enabled by `PERF_SAMPLE_TID`
  @Uint32()
  external int tid;

  /// Enabled by `PERF_SAMPLE_TIME`
  @Uint64()
  external int time;

  /// Enabled by `PERF_SAMPLE_CPU`
  @Uint32()
  external int cpu;

  /// Enabled by `PERF_SAMPLE_CPU`
  @Uint32()
  external int res;

  /// Enabled by `PERF_SAMPLE_PERIOD`
  @Uint64()
  external int period;

  /// Enabled by `PERF_SAMPLE_CALLCHAIN`
  @Uint64()
  external int nr;

  /// Enabled by `PERF_SAMPLE_CALLCHAIN`
  @Array.variable()
  external Array<Uint64> ips;
}

/// Data recorded by the probe stored in a `PERF_SAMPLE_RAW`.
///
/// The `size` field is part of `PERF_SAMPLE_RAW` encoding the rest are
/// part of probe data itself. Format for the recorded data can be recovered
/// by loading tracepoint information from an optional section identified
/// by `HEADER_TRACING_DATA` ([OptionalSection.tracingData]). However encoding
/// of that section is extremely bespoke (see `trace-event-read.c` below), so
/// instead of fiddling with that we simply hardcode expected format of the
/// probe. This obviously needs to be kept in sync with `set_uprobe.dart`
/// script.
///
/// ```
/// $ sudo cat /sys/kernel/tracing/events/uprobes/alloc/format
/// name: alloc
/// ID: 1976
/// format:
///         field:unsigned short common_type;       offset:0;       size:2; signed:0;
///         field:unsigned char common_flags;       offset:2;       size:1; signed:0;
///         field:unsigned char common_preempt_count;       offset:3;       size:1; signed:0;
///         field:int common_pid;   offset:4;       size:4; signed:1;
///
///         field:unsigned long __probe_ip; offset:8;       size:8; signed:0;
///         field:s64 addr; offset:16;      size:8; signed:1;
///         field:s64 top;  offset:24;      size:8; signed:1;
///         field:u32 cid;  offset:32;      size:4; signed:0;
/// print fmt: "(%lx) addr=%Ld top=%Ld cid=%u", REC->__probe_ip, REC->addr, REC->top, REC->cid
/// ```
///
/// [^1]: https://github.com/torvalds/linux/blob/3e9bff3bbe1355805de919f688bef4baefbfd436/tools/perf/util/trace-event-read.c#L375
@Packed(1)
final class ProbeData extends Struct {
  @Uint32()
  external int size;

  @Uint16()
  external int commonType;

  @Uint8()
  external int commonFlags;

  @Uint8()
  external int commonPreemptCount;

  @Int32()
  external int commonPid;

  @Uint64()
  external int probeIp;

  @Uint64()
  external int addr;

  @Uint64()
  external int top;

  @Uint32()
  external int cid;

  @override
  String toString() =>
      'Probe{addr=${addr.formatAsAddress()},top=${top.formatAsAddress()},cid=$cid}';
}

/// Lazily populated mapping between file offsets in a binary and profile
/// location ids.
///
/// This class handles convertion of the file offset to the corresponding
/// symbol name and futher into corresponding location id inside the profile.
final class SymbolsIndex {
  final ProfileBuilder profileBuilder;

  final Symbols symbols;
  final List<Int64?> ids;

  SymbolsIndex(this.profileBuilder, this.symbols)
      : ids = List<Int64?>.filled(symbols.fileOffsets.length, null);

  static final lineRe =
      RegExp(r"^(?<addr>[0-9a-f]+)\s+(?<typ>\w+)\s+(?<name>.*)$");

  /// Return location id corresponding to the given [fileOffset].
  ///
  /// This function will lazily allocate new ids as necessary by
  /// calling [ProfileBuilder.addSymbol].
  Int64? symbolId(int fileOffset) {
    final index = symbols.symbolIndex(fileOffset);
    if (index != null) {
      return (ids[index] ??= profileBuilder.addSymbol(symbols.names[index]));
    }
    return null;
  }
}

final class Mapping {
  final int baseAddress;
  final int length;
  final String path;
  final int offset;

  Mapping({
    required this.baseAddress,
    required this.length,
    required this.path,
    required this.offset,
  });
}

/// Symbols information for the whole address space.
final class AddressSpaceSymbols {
  /// Base addresses for mapping ranges.
  ///
  /// To simplify search we also add ranges that don't have any symbols here.
  /// Consider for example that we have two mappings `[A, A')` and `[B, B')`
  /// with symbols (`Sym(A)` and `Sym(B)` respectively). In this case:
  ///   * [baseAddresses] will contain `[0, A, A', B, B']` and
  ///   * [symbolsIndexes] will contain `[null, SA, null, SymB, null]`.
  final Int64List baseAddresses;

  /// Symbol indexes corresponding to mappings in [baseAddresses].
  final List<SymbolsIndex?> symbolsIndexes;

  /// File offsets corresponding to mappings in [baseAddresses].
  final Int64List fileOffsets;

  AddressSpaceSymbols._(
      this.baseAddresses, this.symbolsIndexes, this.fileOffsets);

  Int64? symbolId(int address) {
    // We use linear search because we assume the number of mappings
    // is very small (~2).
    final limit = baseAddresses.length - 1;
    for (var i = 0; i < limit; i++) {
      final start = baseAddresses[i];
      final end = baseAddresses[i + 1];
      if (start <= address && address < end) {
        final fileOffset = address - start + fileOffsets[i];
        return symbolsIndexes[i]?.symbolId(fileOffset);
      }
    }
    return null;
  }

  /// Construct [AddressSpaceSymbols] from [Mapping] records loaded from
  /// `perf.data`.
  static AddressSpaceSymbols fromMappings(
      List<Mapping> mappings, ProfileBuilder profileBuilder) {
    // Try loading symbols for each mapping and keep those that
    // actually have symbols. Sort resulting list by base address.
    final mappingsWithSymbols = <(Mapping, SymbolsIndex)>[];
    for (var event in mappings) {
      final symbolsIndex = profileBuilder.symbolsIndexFor(event.path);
      if (symbolsIndex != null) {
        mappingsWithSymbols.add((event, symbolsIndex));
      }
    }
    mappingsWithSymbols
        .sort((a, b) => a.$1.baseAddress.compareTo(b.$1.baseAddress));

    // Build `AddressSpaceSymbols` from mappings with symbols.
    //
    // Note: we need to accomodate for a situation when two mappings are
    // adjacent. However we assume that number of mappings is rather small
    // so we don't optimize this code too much.
    final result = <({int baseAddress, SymbolsIndex? index, int fileOffset})>[];
    void addEntry({
      required int baseAddress,
      required SymbolsIndex? index,
      required int fileOffset,
    }) {
      if (result.isNotEmpty && result.last.baseAddress == baseAddress) {
        // Collapse end of the previous mapping and the start of the new
        // mapping.
        if (result.last.index != null) {
          throw StateError('Unexpected intersection of address ranges');
        }
        result.removeLast();
      }
      result.add(
          (baseAddress: baseAddress, index: index, fileOffset: fileOffset));
    }

    addEntry(baseAddress: 0, index: null, fileOffset: 0);
    for (var e in mappingsWithSymbols) {
      addEntry(
        baseAddress: e.$1.baseAddress,
        index: e.$2,
        fileOffset: e.$1.offset,
      );
      addEntry(
        baseAddress: e.$1.baseAddress + e.$1.length,
        index: null,
        fileOffset: 0,
      );
    }

    // Split result into individual components.
    return AddressSpaceSymbols._(
      Int64List.fromList(
        result.map((e) => e.baseAddress).toList(growable: false),
      ),
      result.map((e) => e.index).toList(growable: false),
      Int64List.fromList(
        result.map((e) => e.fileOffset).toList(growable: false),
      ),
    );
  }
}

/// A trie node representing a callstack frame.
///
/// To minimize the size of the produced `pprof.profile` we collapse all
/// matching callstacks into a single `pprof.Sample` entry in the profile.
/// This is done by through a simple [trie][1] data structure.
///
/// Nodes corresponding to callstacks from original profile will have not-null
/// non-zero [totalBytes] associated with them. Path to these nodes should
/// be flushed into [pprof.Profile] as individual [pprof.Sample] entries
/// at the end of conversion. See [flushTo].
///
/// [1]: https://en.wikipedia.org/wiki/Trie
final class CallStackTrieNode {
  /// [pprof.Profile] location id corresponding to this frame.
  final Int64 id;

  /// Total number of bytes allocated by this frame.
  int totalBytes = 0;

  /// Callees of this frame.
  late final Map<Int64, CallStackTrieNode> children =
      <Int64, CallStackTrieNode>{};

  CallStackTrieNode({required this.id});

  CallStackTrieNode operator [](Int64 id) =>
      children[id] ??= CallStackTrieNode(id: id);

  void flushTo(pprof.Profile profile, List<Int64> path) {
    if (totalBytes != 0) {
      profile.sample.add(
        pprof.Sample(locationId: path.reversed)..value.add(Int64(totalBytes)),
      );
    }
    for (var child in children.values) {
      path.add(child.id);
      child.flushTo(profile, path);
      path.removeLast();
    }
  }
}

/// Helper for building [pprof.Profile].
///
/// It takes care of indexing symbols and managing their ids.
final class ProfileBuilder {
  final profile = pprof.Profile();

  final symbolTable = <String, Int64>{};
  final locationIds = <String, Int64>{};

  final callStackTrieRoot = CallStackTrieNode(id: Int64(-1));

  ProfileBuilder() {
    addString("");
    profile.sampleType.add(pprof.ValueType(
      type: addString('space'),
      unit: addString('bytes'),
    ));
  }

  Int64 addString(String str) {
    var id = symbolTable[str];
    if (id != null) {
      return id;
    }
    id = symbolTable[str] = Int64(symbolTable.length);
    profile.stringTable.add(str);
    return id;
  }

  Int64 addSymbol(String symbol) {
    var id = locationIds[symbol];
    if (id != null) {
      return id;
    }
    id = locationIds[symbol] = Int64(locationIds.length + 1);
    profile.function.add(pprof.Function_(id: id, name: addString(symbol)));
    profile.location
        .add(pprof.Location(id: id, line: [pprof.Line(functionId: id)]));
    return id;
  }

  SymbolsIndex? symbolsIndexFor(String path) {
    final symbols = Symbols.load(path);
    if (symbols == null) {
      return null;
    }
    return SymbolsIndex(this, symbols);
  }

  pprof.Profile finishProfile() {
    callStackTrieRoot.flushTo(profile, []);
    return profile;
  }
}

/// Helper for converting raw callstack into its symbolized form.
///
/// We assume that callstack for each new sample usually shares its prefix
/// (e.g. outermost callers, like `main`) with the previously processed
/// sample. This allows us to reuse location ids from the previous sample
/// for the large portion of the stack.
final class SymbolizedCallStackBuilder {
  /// Depth of the current stack.
  int depth = 0;

  /// Raw addresses for each frame in the caller to callee order.
  ///
  /// We do not clear this array between samples allowing us to detect
  /// situations when we can reuse entries. Only entries `0..depth-1`
  /// correspond to the current stack. Other entries originate from
  /// previous samples and might be out of sync with the current sample.
  ///
  /// (`0` is the outermost caller, `1` is its callee, etc).
  final pcs = Int64List(200);

  /// Trie nodes corresponding to each frame in the stack.
  ///
  /// For entries in the `0..depth-2` range `nodes[i]` is parent of
  /// `nodes[i+1]` .
  ///
  final nodes = List<CallStackTrieNode?>.filled(200, null);

  /// Trie node for the last frame (either `nodes[depth-1]` or root trie node
  /// if [depth] is `0`).
  CallStackTrieNode last;

  /// `true` when the callstack which is currently being built matches
  /// the prefix of the previous callstack.
  bool prefixMatches = true;

  SymbolizedCallStackBuilder(ProfileBuilder builder)
      : last = builder.callStackTrieRoot;

  void add(int pc, AddressSpaceSymbols syms) {
    if (pcs[depth] != pc) {
      // Mismatch between newly added `pc` and the `pc` we have from the
      // previous sample. We need to lookup location id for it.
      final id = syms.symbolId(pc);
      if (id == null) {
        // No symbol - drop the frame.
        return;
      }

      pcs[depth] = pc;
      last = last[id];

      // We might still hit the same node in the trie.
      if (nodes[depth] != last) {
        nodes[depth] = last;
        // From here onward we can't reuse `nodes` because the path has
        // diverged.
        prefixMatches = false;
      }
    } else if (!prefixMatches) {
      // Address might match - but the path we got here might be different. This
      // means we can reuse `id` from the node, but not the node itself.
      final id = nodes[depth]!.id;
      nodes[depth] = last = last[id];
    } else {
      // This pc *and* the all previous nodes match. We can just reuse
      // the node.
      last = nodes[depth]!;
    }
    depth++;
  }

  void addTo(ProfileBuilder builder, int allocatedBytes) {
    last.totalBytes += allocatedBytes;
  }

  void reset(ProfileBuilder builder) {
    depth = 0;
    last = builder.callStackTrieRoot;
    prefixMatches = true;
  }
}

@pragma('vm:never-inline')
pprof.Profile buildProfileFromPerfData(String path) {
  final raf = File(path).openSync();

  final profileBuilder = ProfileBuilder();
  final perfData = PerfData(raf);

  // Check that input file has expected format.
  final allAttrs = perfData.readAttrs();
  if (allAttrs.length != 1) {
    perfData.reportError(
        'Expected single perf_event_attrs structure, got ${allAttrs.length}');
  }

  final attrs = allAttrs.first;

  if (attrs.type != TypeId.tracepoint) {
    perfData.reportError('Expected to find a file with tracepoint events');
  }

  const expectedSampleFormat = SampleFormat.ip |
      SampleFormat.tid |
      SampleFormat.time |
      SampleFormat.callchain |
      SampleFormat.cpu |
      SampleFormat.period |
      SampleFormat.raw;
  if (attrs.sampleType != expectedSampleFormat) {
    perfData.reportError(
        'Expected to sample format ${SampleFormat.format(expectedSampleFormat)}'
        ' got ${SampleFormat.format(attrs.sampleType)}: difference '
        '${SampleFormat.format(attrs.sampleType ^ expectedSampleFormat)}');
  }

  final mappings = <Mapping>[];
  perfData.readEvents((type, chunk, pos) {
    if (type == EventType.mmap2) {
      final event = Struct.create<Mmap2Event>(chunk, pos);
      mappings.add(Mapping(
        baseAddress: event.addr,
        length: event.len,
        path: event.filename.toStringFromZeroTerminated(),
        offset: event.pgoffs,
      ));
    } else if (type == EventType.sample && mappings.isNotEmpty) {
      // TODO: we miss one sample here.
      return false; // Break iteration.
    }
    return true;
  });

  final syms = AddressSpaceSymbols.fromMappings(mappings, profileBuilder);
  final stack = SymbolizedCallStackBuilder(profileBuilder);
  perfData.readEvents((type, chunk, pos) {
    if (type == EventType.sample) {
      final sample = Struct.create<SampleEvent>(chunk, pos);
      final probeData = Struct.create<ProbeData>(
          chunk, pos + sizeOf<SampleEvent>() + sample.nr * 8);

      for (var i = sample.nr - 1; i > 1; i--) {
        stack.add(sample.ips[i], syms);
      }
      if (stack.depth > 0) {
        // Accumulate [totalBytes] in the last node.
        stack.last.totalBytes += probeData.top - probeData.addr - 1;
      }

      // Reset the stack for the next sample.
      stack.reset(profileBuilder);
    }

    return true;
  });

  print('All data loaded - creating profile.');
  return profileBuilder.finishProfile();
}

void main(List<String> args) async {
  final perfDataPath = args[0];
  print('loading $perfDataPath');
  final profile = buildProfileFromPerfData(perfDataPath);
  print('created ${profile.sample.length} samples');

  print('Serializing proto (pprof.profile)');
  final result = profile.writeToBuffer();
  print('... ${result.length} bytes');
  File('pprof.profile').writeAsBytesSync(result);
  print('Done');
}
