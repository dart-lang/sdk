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

// A pattern matching a build ID in the non-symbolic stack trace header.
//
// This RegExp has been adjusted to parse the header line found in
// non-symbolic stack traces and the modified version in signal handler stack
// traces.
const _buildIdREString = r"build_id(?:=|: )'([\da-f]+)'";
final _buildIdRE = RegExp(_buildIdREString);

// A pattern matching a loading unit in the non-symbolic stack trace header.
//
// This RegExp has been adjusted to parse the header line found in
// non-symbolic stack traces and the modified version in signal handler stack
// traces.
final _loadingUnitLineRE = RegExp(r'loading_unit(?:=|: )([\d]+),? (?:' +
    _buildIdREString +
    r',? )?dso_base(?:=|: )([\da-f]+),? instructions(?:=|: )([\da-f]+)');

// A pattern matching the isolate DSO base in the non-symbolic stack trace
// header.
//
// This RegExp has been adjusted to parse the header line found in
// non-symbolic stack traces and the modified version in signal handler stack
// traces.
final _isolateDsoBaseLineRE = RegExp(r'isolate_dso_base(?:=|: )([\da-f]+)');

// A pattern matching the last line of the non-symbolic stack trace header.
//
// This RegExp has been adjusted to parse the header line found in
// non-symbolic stack traces and the modified version in signal handler stack
// traces.
final _instructionsLineRE = RegExp(r'isolate_instructions(?:=|: )([\da-f]+),? '
    r'vm_instructions(?:=|: )([\da-f]+)');

/// Information for a loading unit.
class LoadingUnit {
  /// The id of the loading unit.
  final int id;

  /// The base address at which the loading unit was loaded.
  final int dsoBase;

  /// The address at which the loading unit instructions were loaded.
  final int start;

  /// The build ID of the loading unit, when available.
  final String? buildId;

  LoadingUnit(this.id, this.dsoBase, this.start, {this.buildId});

  void writeToStringBuffer(StringBuffer buffer) {
    buffer
      ..write('LoadingUnit(')
      ..write(id)
      ..write(', start: ')
      ..write(start.toRadixString(16))
      ..write(', dso_base: ')
      ..write(dsoBase.toRadixString(16));
    if (buildId != null) {
      buffer
        ..write(", buildId: '")
        ..write(buildId)
        ..write("'");
    }
    buffer.write(")");
  }

  @override
  String toString() {
    final b = StringBuffer();
    writeToStringBuffer(b);
    return b.toString();
  }
}

/// Header information for a non-symbolic Dart stack trace.
class StackTraceHeader {
  String? _os;
  String? _arch;
  bool? _compressed;
  bool? _simulated;
  String? _buildId;
  Map<int, LoadingUnit>? _units;
  int? _isolateStart;
  int? _vmStart;
  int? _isolateDsoBase;

  String? get os => _os;
  String? get architecture => _arch;
  String? get buildId => _buildId;
  Map<int, LoadingUnit>? get units => _units;
  bool? get compressedPointers => _compressed;
  bool? get usingSimulator => _simulated;
  int? get vmStart => _vmStart;
  int? get isolateStart => _isolateStart;
  int? get isolateDsoBase => _isolateDsoBase;

  static StackTraceHeader fromStarts(int isolateStart, int vmStart,
          {String? architecture}) =>
      StackTraceHeader()
        .._isolateStart = isolateStart
        .._vmStart = vmStart
        .._arch = architecture;

  static StackTraceHeader fromLines(List<String> lines, {bool lossy = false}) {
    final result = StackTraceHeader();
    for (final line in lines) {
      result.tryParseHeaderLine(line, lossy: lossy);
    }
    return result;
  }

  /// Try and parse the given line as one of the recognized lines in the
  /// header of a non-symbolic stack trace.
  ///
  /// If [lossy] is true, then the parser assumes that some header lines may
  /// have been lost (e.g., due to log truncation) and recreates missing parts
  /// of the header from other parsed parts if possible.
  ///
  /// Returns whether the line was recognized and parsed successfully.
  bool tryParseHeaderLine(String line, {bool lossy = false}) {
    if (line.contains(_headerStartLine)) {
      // This is the start of a new non-symbolic stack trace, so reset all the
      // stored information to be parsed anew.
      _os = null;
      _arch = null;
      _compressed = null;
      _simulated = null;
      _buildId = null;
      _isolateStart = null;
      _isolateDsoBase = null;
      _vmStart = null;
      _units = null;
      return true;
    }
    RegExpMatch? match;
    match = _osArchLineRE.firstMatch(line);
    if (match != null) {
      _os = match[1]!;
      _arch = match[2]!;
      _compressed = match[3]! == "yes";
      _simulated = match[4]! == "yes";
      if (lossy) {
        // Reset all stored information that is parsed after this point,
        // just in case we've missed earlier lines in this header.
        _buildId = null;
        _isolateStart = null;
        _isolateDsoBase = null;
        _vmStart = null;
        _units = null;
      }
      return true;
    }
    // Have to check for loading units first because they can include a
    // build ID, so the build ID RegExp matches them as well.
    match = _loadingUnitLineRE.firstMatch(line);
    if (match != null) {
      _units ??= <int, LoadingUnit>{};
      final id = int.parse(match[1]!);
      final buildId = match[2];
      final dsoBase = int.parse(match[3]!, radix: 16);
      final start = int.parse(match[4]!, radix: 16);
      _units![id] = LoadingUnit(id, dsoBase, start, buildId: buildId);
      if (lossy) {
        // Reset all stored information that is parsed after this point,
        // just in case we've missed earlier lines in this header.
        _isolateStart = null;
        _isolateDsoBase = null;
        _vmStart = null;
      }
      return true;
    }
    match = _buildIdRE.firstMatch(line);
    if (match != null) {
      _buildId = match[1]!;
      if (lossy) {
        // Reset all stored information that is parsed after this point,
        // just in case we've missed earlier lines in this header.
        _isolateStart = null;
        _isolateDsoBase = null;
        _vmStart = null;
        _units = null;
      }
      return true;
    }
    match = _isolateDsoBaseLineRE.firstMatch(line);
    if (match != null) {
      _isolateDsoBase = int.parse(match[1]!, radix: 16);
      if (lossy) {
        // Reset all stored information that is parsed after this point,
        // just in case we've missed earlier lines in this header.
        _isolateStart = null;
        _vmStart = null;
      }
      return true;
    }
    match = _instructionsLineRE.firstMatch(line);
    if (match != null) {
      _isolateStart = int.parse(match[1]!, radix: 16);
      _vmStart = int.parse(match[2]!, radix: 16);
      if (_units != null) {
        final rootUnit = _units![constants.rootLoadingUnitId];
        if (lossy && rootUnit == null) {
          // We missed the header entry for the root loading unit, but it can
          // be reconstructed from other header lines.
          _units![constants.rootLoadingUnitId] = LoadingUnit(
            constants.rootLoadingUnitId,
            _isolateDsoBase!,
            _isolateStart!,
            buildId: _buildId,
          );
        } else {
          assert(rootUnit != null);
          assert(_isolateStart == rootUnit!.start);
          assert(_isolateDsoBase == rootUnit!.dsoBase);
          assert(_buildId == null || _buildId == rootUnit!.buildId);
        }
      }
      return true;
    }
    return false;
  }

  // Returns the closest positive offset, unless both offsets are negative in
  // which case it returns the negative offset closest to zero.
  int _closestOffset(int offset1, int offset2) {
    if (offset1 < 0) {
      if (offset2 < 0) return max(offset1, offset2);
      return offset2;
    }
    if (offset2 < 0) return offset1;
    return min(offset1, offset2);
  }

  /// The [PCOffset] for the given absolute program counter address.
  PCOffset? offsetOf(int address) {
    if (_isolateStart == null || _vmStart == null) return null;
    var vmOffset = address - _vmStart!;
    var unitOffset = address - _isolateStart!;
    var unitBuildId = _buildId;
    var unitId = constants.rootLoadingUnitId;
    if (units != null) {
      for (final unit in units!.values) {
        final newOffset = address - unit.start;
        if (newOffset == _closestOffset(unitOffset, newOffset)) {
          unitOffset = newOffset;
          unitBuildId = unit.buildId;
          unitId = unit.id;
        }
      }
    }
    if (unitOffset == _closestOffset(vmOffset, unitOffset)) {
      return PCOffset(unitOffset, InstructionsSection.isolate,
          os: _os,
          architecture: _arch,
          compressedPointers: _compressed,
          usingSimulator: _simulated,
          buildId: unitBuildId,
          unitId: unitId);
    }
    // The VM section is always stored in the root loading unit.
    return PCOffset(vmOffset, InstructionsSection.vm,
        os: _os,
        architecture: _arch,
        compressedPointers: _compressed,
        usingSimulator: _simulated,
        buildId: _buildId,
        unitId: constants.rootLoadingUnitId);
  }

  void writeToStringBuffer(StringBuffer buffer) {
    var printedField = false;
    void printField(String name, dynamic value) {
      buffer
        ..writeln(printedField ? ',' : '')
        ..write('  ')
        ..write(name)
        ..write(': ')
        ..write(value);
      printedField = true;
    }

    buffer.write('StackTraceHeader(');
    if (_vmStart != null) {
      printField('vmStart', _vmStart!.toRadixString(16));
    }
    if (_isolateStart != null) {
      printField('isolateStart', _isolateStart!.toRadixString(16));
    }
    if (_isolateDsoBase != null) {
      printField('isolateDsoBase', _isolateDsoBase!.toRadixString(16));
    }
    if (_arch != null) {
      final b = StringBuffer();
      if (_simulated == true) {
        b.write('SIM');
      }
      b.write(_arch!.toUpperCase());
      if (_compressed == true) {
        b.write('C');
      }
      printField('arch', b.toString());
    } else {
      if (_simulated != null) {
        printField('simulated', _simulated);
      }
      if (_compressed != null) {
        printField('compressed', _compressed);
      }
    }
    if (_buildId != null) {
      printField('buildId', "'$_buildId'");
    }
    if (_units != null) {
      final b = StringBuffer();
      b.writeln('{');
      for (final unitId in _units!.keys) {
        b.write('    $unitId => ');
        _units![unitId]!.writeToStringBuffer(b);
        b.writeln(',');
      }
      b.write('}');
      printField('units', b.toString());
    }
    buffer.write(')');
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    writeToStringBuffer(buffer);
    return buffer.toString();
  }
}

(InstructionsSection, int)? _tryParseSymbolOffset(String s,
    {bool forceHexadecimal = false}) {
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
      return (InstructionsSection.vm, offset);
    case constants.isolateSymbolName:
      return (InstructionsSection.isolate, offset);
    default:
      break;
  }
  return null;
}

/// Parses strings of the format <static symbol>+<integer offset>, where
/// <static symbol> is one of the static symbols used for Dart instruction
/// sections.
///
/// Unless forceHexadecimal is true, an integer offset without a "0x" prefix or
/// any hexadecimal digits will be parsed as decimal.
///
/// Assumes that the symbol should be resolved in the root loading unit.
///
/// Returns null if the string is not of the expected format.
PCOffset? tryParseSymbolOffset(String s,
    {bool forceHexadecimal = false,
    String? buildId,
    StackTraceHeader? header}) {
  final result = _tryParseSymbolOffset(s, forceHexadecimal: forceHexadecimal);
  if (result == null) return null;
  return PCOffset(result.$2, result.$1,
      os: header?.os,
      architecture: header?.architecture,
      compressedPointers: header?.compressedPointers,
      usingSimulator: header?.usingSimulator,
      buildId: header?.buildId,
      unitId: constants.rootLoadingUnitId);
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
final _traceLineRE = RegExp(r'\s*#(\d+) abs (?<absolute>[\da-f]+)'
    r'(?: unit (?<unitId>\d+))?'
    r'(?: virt (?<virtual>[\da-f]+))?'
    r' (?<rest>.*)$');

PCOffset? _retrievePCOffset(StackTraceHeader header, RegExpMatch? match) {
  if (match == null) return null;
  // Retrieve the unit ID for this stack frame, if one was provided.
  var unitId = constants.rootLoadingUnitId;
  var buildId = header.buildId;
  if (match.namedGroup('unitId') != null) {
    unitId = int.parse(match.namedGroup('unitId')!);
    final unit = header.units?[unitId];
    if (unit == null) {
      // The given non-root loading unit wasn't found in the header.
      return null;
    }
    buildId = unit.buildId;
  }
  if (unitId == constants.rootLoadingUnitId) {
    // Try checking for symbol information first, since we don't need the header
    // information to translate it for the root loading unit.
    final restString = match.namedGroup('rest')!;
    if (restString.isNotEmpty) {
      final result = _tryParseSymbolOffset(restString);
      if (result != null) {
        return PCOffset(result.$2, result.$1,
            os: header.os,
            architecture: header.architecture,
            compressedPointers: header.compressedPointers,
            usingSimulator: header.usingSimulator,
            buildId: buildId,
            unitId: unitId);
      }
    }
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
  if (match.namedGroup('virtual') != null) {
    final address = int.parse(match.namedGroup('virtual')!, radix: 16);
    return PCOffset(address, InstructionsSection.none,
        os: header.os,
        architecture: header.architecture,
        compressedPointers: header.compressedPointers,
        usingSimulator: header.usingSimulator,
        buildId: buildId,
        unitId: unitId);
  }
  return null;
}

/// The [PCOffset]s for frames of the non-symbolic stack traces in [lines].
Iterable<PCOffset> collectPCOffsets(Iterable<String> lines,
    {bool lossy = false}) sync* {
  final header = StackTraceHeader();
  for (var line in lines) {
    if (header.tryParseHeaderLine(line, lossy: lossy)) {
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
  final Map<int, Dwarf>? _dwarfByUnitId;
  final Iterable<Dwarf>? _unitDwarfs;
  final bool _includeInternalFrames;

  DwarfStackTraceDecoder(
    this._dwarf, {
    Map<int, Dwarf>? dwarfByUnitId,
    Iterable<Dwarf>? unitDwarfs,
    bool includeInternalFrames = false,
  })  : _dwarfByUnitId = dwarfByUnitId,
        _unitDwarfs = unitDwarfs,
        _includeInternalFrames = includeInternalFrames;

  @override
  Stream<String> bind(Stream<String> stream) async* {
    var depth = 0;
    final header = StackTraceHeader();
    await for (final line in stream) {
      // If we successfully parse a header line, then we reset the depth to 0.
      if (header.tryParseHeaderLine(line, lossy: true)) {
        depth = 0;
        yield line;
        continue;
      }
      // If at any point we can't get appropriate information for the current
      // line as a stack trace line, then just pass the line through unchanged.
      final lineMatch = _traceLineRE.firstMatch(line);
      final offset = _retrievePCOffset(header, lineMatch);
      if (offset == null) {
        yield line;
        continue;
      }
      Dwarf dwarf = _dwarf;
      final unitId = offset.unitId;
      if (unitId != null && unitId != constants.rootLoadingUnitId) {
        Dwarf? unitDwarf;
        // Prefer the map that specifies loading unit IDs over the iterable.
        if (_dwarfByUnitId != null) {
          unitDwarf = _dwarfByUnitId![unitId];
        }
        if (unitDwarf == null &&
            _unitDwarfs != null &&
            offset.buildId != null) {
          for (final d in _unitDwarfs!) {
            if (d.buildId(offset.architecture) == offset.buildId) {
              unitDwarf = d;
            }
          }
        }
        // Don't attempt to translate if we couldn't find the correct debugging
        // information for this loading unit.
        if (unitDwarf == null) {
          yield line;
          continue;
        }
        dwarf = unitDwarf;
      }
      final callInfo = offset.callInfoFrom(dwarf,
          includeInternalFrames: _includeInternalFrames);
      if (callInfo == null) {
        yield line;
        continue;
      }
      // No lines to output (as this corresponds to Dart internals).
      if (callInfo.isEmpty) continue;
      // Output the lines for the symbolic frame with the prefix found on the
      // original non-symbolic frame line, modulo all whitespace between the
      // prefix and stack trace information converted to a single space.
      //
      // If there was no prefix, just swallow any initial whitespace, since
      // symbolic Dart stacktrace lines have no initial whitespace.
      String prefix = line.substring(0, lineMatch!.start);
      if (prefix.isNotEmpty) {
        prefix += ' ';
      }
      for (final call in callInfo) {
        yield prefix + _stackTracePiece(call, depth++);
      }
    }
  }
}
