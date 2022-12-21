// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'constants.dart' as constants;
import 'dwarf.dart';

String _stackTracePiece(CallInfo call, int depth) =>
    '#${depth.toString().padRight(6)} $call';

// The initial header line in a non-symbolic stack trace.
const _headerStartLine =
    '*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***';

// A pattern matching the os/arch line of the non-symbolic stack trace header.
//
// This RegExp has been adjusted to parse the header line found in
// non-symbolic stack traces and the modified version in signal handler stack
// traces.
final _osArchLineRE = RegExp(r'os(?:=|: )(\S+?),? '
    r'arch(?:=|: )(\S+?),? comp(?:=|: )(yes|no),? sim(?:=|: )(yes|no)');

// A pattern matching the last line of the non-symbolic stack trace header.
//
// This RegExp has been adjusted to parse the header line found in
// non-symbolic stack traces and the modified version in signal handler stack
// traces.
final _instructionsLineRE = RegExp(r'isolate_instructions(?:=|: )([\da-f]+),? '
    r'vm_instructions(?:=|: )([\da-f]+)');

/// Header information for a non-symbolic Dart stack trace.
class StackTraceHeader {
  String? _os;
  String? _arch;
  bool? _compressed;
  bool? _simulated;
  int? _isolateStart;
  int? _vmStart;

  String? get os => _os;
  String? get architecture => _arch;
  bool? get compressedPointers => _compressed;
  bool? get usingSimulator => _simulated;

  static StackTraceHeader fromStarts(int isolateStart, int vmStart,
          {String? architecture}) =>
      StackTraceHeader()
        .._isolateStart = isolateStart
        .._vmStart = vmStart
        .._arch = architecture;

  /// Try and parse the given line as one of the recognized lines in the
  /// header of a non-symbolic stack trace.
  ///
  /// Returns whether the line was recognized and parsed successfully.
  bool tryParseHeaderLine(String line) {
    if (line.contains(_headerStartLine)) {
      // This is the start of a new non-symbolic stack trace, so reset all the
      // stored information to be parsed anew.
      _os = null;
      _arch = null;
      _compressed = null;
      _simulated = null;
      _isolateStart = null;
      _vmStart = null;
      return true;
    }
    RegExpMatch? match = _osArchLineRE.firstMatch(line);
    if (match != null) {
      _os = match[1]!;
      _arch = match[2]!;
      _compressed = match[3]! == "yes";
      _simulated = match[4]! == "yes";
      // The architecture line always proceeds the instructions section line,
      // so reset these to null just in case we missed the header line.
      _isolateStart = null;
      _vmStart = null;
      return true;
    }
    match = _instructionsLineRE.firstMatch(line);
    if (match != null) {
      _isolateStart = int.parse(match[1]!, radix: 16);
      _vmStart = int.parse(match[2]!, radix: 16);
      return true;
    }
    return false;
  }

  /// The [PCOffset] for the given absolute program counter address.
  PCOffset? offsetOf(int address) {
    if (_isolateStart == null || _vmStart == null) return null;
    final isolateOffset = address - _isolateStart!;
    var vmOffset = address - _vmStart!;
    if (vmOffset > 0 && vmOffset == min(vmOffset, isolateOffset)) {
      return PCOffset(vmOffset, InstructionsSection.vm,
          os: _os,
          architecture: _arch,
          compressedPointers: _compressed,
          usingSimulator: _simulated);
    } else {
      return PCOffset(isolateOffset, InstructionsSection.isolate,
          os: _os,
          architecture: _arch,
          compressedPointers: _compressed,
          usingSimulator: _simulated);
    }
  }
}

/// A Dart DWARF stack trace contains up to four pieces of information:
///   - The zero-based frame index from the top of the stack.
///   - The absolute address of the program counter.
///   - The virtual address of the program counter, if the snapshot was
///     loaded as a dynamic library, otherwise not present.
///   - The location of the virtual address, which is one of the following:
///     - A dynamic symbol name, a plus sign, and an integer offset.
///     - The path to the snapshot, if it was loaded as a dynamic library,
///       otherwise the string "<unknown>".
const _symbolOffsetREString = r'(?<symbol>' +
    constants.vmSymbolName +
    r'|' +
    constants.isolateSymbolName +
    r')\+(?<offset>(?:0x)?[\da-f]+)';
final _symbolOffsetRE = RegExp(_symbolOffsetREString);
final _traceLineRE = RegExp(
    r'    #(\d+) abs (?<absolute>[\da-f]+)(?: virt (?<virtual>[\da-f]+))? '
    r'(?<rest>.*)$');

/// Parses strings of the format <static symbol>+<integer offset>, where
/// <static symbol> is one of the static symbols used for Dart instruction
/// sections.
///
/// Unless forceHexadecimal is true, an integer offset without a "0x" prefix or
/// any hexdecimal digits will be parsed as decimal.
///
/// Returns null if the string is not of the expected format.
PCOffset? tryParseSymbolOffset(String s,
    {bool forceHexadecimal = false, StackTraceHeader? header}) {
  final match = _symbolOffsetRE.firstMatch(s);
  if (match == null) return null;
  final symbolString = match.namedGroup('symbol')!;
  final offsetString = match.namedGroup('offset')!;
  int? offset;
  if (!forceHexadecimal && !offsetString.startsWith('0x')) {
    offset = int.tryParse(offsetString);
  }
  if (offset == null) {
    final digits = offsetString.startsWith('0x')
        ? offsetString.substring(2)
        : offsetString;
    offset = int.tryParse(digits, radix: 16);
  }
  if (offset == null) return null;
  switch (symbolString) {
    case constants.vmSymbolName:
      return PCOffset(offset, InstructionsSection.vm,
          os: header?.os,
          architecture: header?.architecture,
          compressedPointers: header?.compressedPointers,
          usingSimulator: header?.usingSimulator);
    case constants.isolateSymbolName:
      return PCOffset(offset, InstructionsSection.isolate,
          os: header?.os,
          architecture: header?.architecture,
          compressedPointers: header?.compressedPointers,
          usingSimulator: header?.usingSimulator);
    default:
      break;
  }
  return null;
}

PCOffset? _retrievePCOffset(StackTraceHeader header, RegExpMatch? match) {
  if (match == null) return null;
  final restString = match.namedGroup('rest')!;
  // Try checking for symbol information first, since we don't need the header
  // information to translate it.
  if (restString.isNotEmpty) {
    final offset = tryParseSymbolOffset(restString, header: header);
    if (offset != null) return offset;
  }
  // If we're parsing the absolute address, we can only convert it into
  // a PCOffset if we saw the instructions line of the stack trace header.
  final addressString = match.namedGroup('absolute')!;
  final address = int.parse(addressString, radix: 16);
  final pcOffset = header.offsetOf(address);
  if (pcOffset != null) return pcOffset;
  // If all other cases failed, check for a virtual address. Until this package
  // depends on a version of Dart which only prints virtual addresses when the
  // virtual addresses in the snapshot are the same as in separately saved
  // debugging information, the other methods should be tried first.
  final virtualString = match.namedGroup('virtual');
  if (virtualString != null) {
    final address = int.parse(virtualString, radix: 16);
    return PCOffset(address, InstructionsSection.none,
        os: header.os,
        architecture: header.architecture,
        compressedPointers: header.compressedPointers,
        usingSimulator: header.usingSimulator);
  }
  return null;
}

/// The [PCOffset]s for frames of the non-symbolic stack traces in [lines].
Iterable<PCOffset> collectPCOffsets(Iterable<String> lines) sync* {
  final header = StackTraceHeader();
  for (var line in lines) {
    if (header.tryParseHeaderLine(line)) {
      continue;
    }
    final match = _traceLineRE.firstMatch(line);
    final offset = _retrievePCOffset(header, match);
    if (offset != null) yield offset;
  }
}

/// A [StreamTransformer] that scans lines for non-symbolic stack traces.
///
/// A [NativeStackTraceDecoder] scans a stream of lines for non-symbolic
/// stack traces containing only program counter address information. Such
/// stack traces are generated by the VM when executing a snapshot compiled
/// with `--dwarf-stack-traces`.
///
/// The transformer assumes that there may be text preceding the stack frames
/// on individual lines, like in log files, but that there is no trailing text.
/// For each stack frame found, the transformer attempts to locate a function
/// name, file name and line number using the provided DWARF information.
///
/// If no information is found, or the line is not a stack frame, then the line
/// will be unchanged in the output stream.
///
/// If the located information corresponds to Dart internals and
/// [includeInternalFrames] is false, then the output stream contains no
/// entries for the line.
///
/// Otherwise, the output stream contains one or more lines with symbolic stack
/// frames for the given non-symbolic stack frame line. Multiple symbolic stack
/// frame lines are generated when the PC address corresponds to inlined code.
/// In the output stream, each symbolic stack frame is prefixed by the non-stack
/// frame portion of the original line.
class DwarfStackTraceDecoder extends StreamTransformerBase<String, String> {
  final Dwarf _dwarf;
  final bool _includeInternalFrames;

  DwarfStackTraceDecoder(this._dwarf, {bool includeInternalFrames = false})
      : _includeInternalFrames = includeInternalFrames;

  @override
  Stream<String> bind(Stream<String> stream) async* {
    var depth = 0;
    final header = StackTraceHeader();
    await for (final line in stream) {
      // If we successfully parse a header line, then we reset the depth to 0.
      if (header.tryParseHeaderLine(line)) {
        depth = 0;
        yield line;
        continue;
      }
      // If at any point we can't get appropriate information for the current
      // line as a stack trace line, then just pass the line through unchanged.
      final lineMatch = _traceLineRE.firstMatch(line);
      final offset = _retrievePCOffset(header, lineMatch);
      final callInfo = offset?.callInfoFrom(_dwarf,
          includeInternalFrames: _includeInternalFrames);
      if (callInfo == null) {
        yield line;
        continue;
      }
      // No lines to output (as this corresponds to Dart internals).
      if (callInfo.isEmpty) continue;
      // Output the lines for the symbolic frame with the prefix found on the
      // original non-symbolic frame line.
      final prefix = line.substring(0, lineMatch!.start);
      for (final call in callInfo) {
        yield prefix + _stackTracePiece(call, depth++);
      }
    }
  }
}
