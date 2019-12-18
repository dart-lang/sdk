// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:math";

import "dwarf.dart";

String _stackTracePiece(CallInfo call, int depth) => "#${depth}\t${call}";

final _traceStart = 'Warning: This VM has been configured to produce '
    'stack traces that violate the Dart standard.';
final _traceInstructionsStartRE = RegExp(r'isolate_instructions: ([0-9a-f]+) '
    r'vm_instructions: ([0-9a-f]+)$');
final _traceLineRE =
    RegExp(r'    #(\d{2}) abs ([0-9a-f]+)(?: virt [0-9a-f]+)? (.*)$');

enum InstructionSection { vm, isolate }

class PCOffset {
  final int offset;
  final InstructionSection section;

  PCOffset(this.offset, this.section);

  int virtualAddress(Dwarf dwarf) {
    switch (section) {
      case InstructionSection.vm:
        return dwarf.convertToVMVirtualAddress(offset);
      case InstructionSection.isolate:
        return dwarf.convertToIsolateVirtualAddress(offset);
    }
  }

  int get hashCode => offset.hashCode;

  bool operator ==(Object other) {
    return other is PCOffset &&
        offset == other.offset &&
        section == other.section;
  }
}

class StackTraceHeader {
  final int _isolateStart;
  final int _vmStart;

  StackTraceHeader(this._isolateStart, this._vmStart);

  factory StackTraceHeader.fromMatch(Match match) {
    if (match == null) {
      return null;
    }
    final isolateAddr = int.parse("0x" + match[1]);
    final vmAddr = int.parse("0x" + match[2]);
    return StackTraceHeader(isolateAddr, vmAddr);
  }

  PCOffset convertAbsoluteAddress(int address) {
    int isolateOffset = address - _isolateStart;
    int vmOffset = address - _vmStart;
    if (vmOffset > 0 && vmOffset == min(vmOffset, isolateOffset)) {
      return PCOffset(vmOffset, InstructionSection.vm);
    } else {
      return PCOffset(isolateOffset, InstructionSection.isolate);
    }
  }
}

PCOffset retrievePCOffset(StackTraceHeader header, Match match) {
  assert(header != null && match != null);
  final address = int.parse("0x" + match[2]);
  return header.convertAbsoluteAddress(address);
}

// Returns the [PCOffset] for each frame's absolute PC address if [lines]
// contains one or more DWARF stack traces.
Iterable<PCOffset> collectPCOffsets(Iterable<String> lines) {
  final ret = <PCOffset>[];
  StackTraceHeader header = null;
  for (var line in lines) {
    if (line.endsWith(_traceStart)) {
      header = null;
    }
    final startMatch = _traceInstructionsStartRE.firstMatch(line);
    if (startMatch != null) {
      header = StackTraceHeader.fromMatch(startMatch);
      continue;
    }
    final lineMatch = _traceLineRE.firstMatch(line);
    if (lineMatch != null) {
      ret.add(retrievePCOffset(header, lineMatch));
    }
  }
  return ret;
}

// Scans a stream of lines for Dart DWARF-based stack traces (i.e., Dart stack
// traces where the frame entries include PC addresses). For each stack frame
// found, the transformer attempts to locate a function name, file name and line
// number using the provided DWARF information.
//
// If no information is found, or the line is not a stack frame, the line is
// output to the sink unchanged.
//
// If the located information corresponds to Dart internals, the frame will be
// dropped.
//
// Otherwise, at least one altered stack frame is generated and replaces the
// stack frame portion of the original line. If the PC address corresponds to
// inlined code, then multiple stack frames may be generated. When multiple
// stack frames are generated, only the first replaces the stack frame portion
// of the original line, and the remaining frames are separately output.
class DwarfStackTraceDecoder extends StreamTransformerBase<String, String> {
  final Dwarf _dwarf;
  final bool includeInternalFrames;

  DwarfStackTraceDecoder(this._dwarf, {this.includeInternalFrames = false});

  Stream<String> bind(Stream<String> stream) => Stream<String>.eventTransformed(
      stream,
      (sink) => _DwarfStackTraceEventSink(sink, _dwarf,
          includeInternalFrames: includeInternalFrames));
}

class _DwarfStackTraceEventSink implements EventSink<String> {
  final EventSink<String> _sink;
  final Dwarf _dwarf;
  final bool includeInternalFrames;
  int _cachedDepth = 0;
  StackTraceHeader _cachedHeader = null;

  _DwarfStackTraceEventSink(this._sink, this._dwarf,
      {this.includeInternalFrames = false});

  void close() => _sink.close();
  void addError(Object e, [StackTrace st]) => _sink.addError(e, st);
  Future addStream(Stream<String> stream) => stream.forEach(add);

  void add(String line) {
    // Reset any stack-related state when we see the start of a new
    // stacktrace.
    if (line.endsWith(_traceStart)) {
      _cachedDepth = 0;
      _cachedHeader = null;
    }
    final startMatch = _traceInstructionsStartRE.firstMatch(line);
    if (startMatch != null) {
      _cachedHeader = StackTraceHeader.fromMatch(startMatch);
      _sink.add(line);
      return;
    }
    final lineMatch = _traceLineRE.firstMatch(line);
    if (lineMatch == null) {
      _sink.add(line);
      return;
    }
    final location =
        retrievePCOffset(_cachedHeader, lineMatch).virtualAddress(_dwarf);
    final callInfo = _dwarf
        .callInfo(location, includeInternalFrames: includeInternalFrames)
        ?.toList();
    if (callInfo == null) {
      // If we can't get appropriate information for the stack trace line,
      // then just return the line unchanged.
      _sink.add(line);
      return;
    } else if (callInfo.isEmpty) {
      // No lines to output (as this corresponds to Dart internals).
      return;
    }
    _sink.add(line.substring(0, lineMatch.start) +
        _stackTracePiece(callInfo.first, _cachedDepth++));
    for (int i = 1; i < callInfo.length; i++) {
      _sink.add(_stackTracePiece(callInfo[i], _cachedDepth++));
    }
  }
}
