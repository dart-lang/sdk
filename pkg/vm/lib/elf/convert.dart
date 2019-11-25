// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";

import "dwarf.dart";

String _stackTracePiece(CallInfo call, int depth) => "#${depth}\t${call}";

final _traceLineRE = RegExp(r'    #(\d{2}) pc ([0-9a-f]+)  (.*)$');

Iterable<int> collectPCAddresses(Iterable<String> lines) {
  final ret = <int>[];
  for (var line in lines) {
    final match = _traceLineRE.firstMatch(line);
    if (match == null) continue;
    ret.add(int.parse("0x" + match[2]));
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

  _DwarfStackTraceEventSink(this._sink, this._dwarf,
      {this.includeInternalFrames = false});

  void close() => _sink.close();
  void addError(Object e, [StackTrace st]) => _sink.addError(e, st);
  Future addStream(Stream<String> stream) => stream.forEach(add);

  void add(String line) {
    final match = _traceLineRE.firstMatch(line);
    if (match == null) {
      _sink.add(line);
      return;
    }
    // We don't use the original frame depths because we may elide frames.
    // If we match a stack frame with a depth of 0, then we're starting a
    // new stack frame.
    if (int.parse(match[1]) == 0) {
      _cachedDepth = 0;
    }
    final location = int.parse("0x" + match[2]);
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
    _sink.add(line.substring(0, match.start) +
        _stackTracePiece(callInfo.first, _cachedDepth++));
    for (int i = 1; i < callInfo.length; i++) {
      _sink.add(_stackTracePiece(callInfo[i], _cachedDepth++));
    }
  }
}
