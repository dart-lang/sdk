// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import '../../debug_info.dart';
import '../serialize/printer.dart';
import '../serialize/serialize.dart';
import 'ir.dart';

class Instructions implements Serializable {
  /// The locals used by this group of instructions.
  final List<Local> locals;

  /// Names of the locals in `locals`.
  ///
  /// Most of the locals won't have names, so this is a [Map] instead of [List]
  /// like [locals], with local indices as keys and names as values.
  final Map<int, String> localNames;

  /// A sequence of Wasm instructions.
  final List<Instruction> instructions;

  final Map<Instruction, StackTrace>? _stackTraces;

  final List<String> _traceLines;

  /// A string trace.
  late final trace = _traceLines.join();

  /// Debug info bytecode indexed by instruction index.
  final Uint8List? debugInfo;

  /// Create a new instruction sequence.
  Instructions(
    List<Local> locals,
    this.localNames,
    List<Instruction> instructions,
    Map<Instruction, StackTrace>? stackTraces,
    List<String> traceLines,
    this.debugInfo,
  ) : locals = locals.isEmpty ? const [] : locals.toList(growable: false),
      instructions = instructions.toList(growable: false),
      _stackTraces = stackTraces == null
          ? null
          : (stackTraces.isEmpty ? const {} : stackTraces),
      _traceLines = traceLines.isEmpty
          ? const []
          : traceLines.toList(growable: false);

  void collectUsedTypes(Set<DefType> usedTypes) {
    for (final local in locals) {
      final localDefType = local.type.containedDefType;
      if (localDefType != null) usedTypes.add(localDefType);
    }
    for (final instruction in instructions) {
      usedTypes.addAll(instruction.usedDefTypes);
      for (final valueType in instruction.usedValueTypes) {
        final type = valueType.containedDefType;
        if (type != null) usedTypes.add(type);
      }
    }
  }

  /// Serializes the instructions into [s].
  ///
  /// If [recordDebugInfo] is true and [debugInfo] is present, converts the
  /// instruction-offset based [debugInfo] into function-body-relative
  /// byte-offset based debug info and returns it.
  @override
  Uint8List? serialize(Serializer s, [bool recordDebugInfo = false]) {
    final debugInfo = this.debugInfo;
    if (recordDebugInfo && debugInfo != null && debugInfo.isNotEmpty) {
      final reader = DebugInfoReader(debugInfo);
      final writer = DebugInfoWriter();
      bool hasMapping = reader.moveNext();
      final bodyStart = s.offset;

      for (int i = 0; i < instructions.length; i++) {
        final instr = instructions[i];
        if (_stackTraces != null) s.debugTrace(_stackTraces[instr]!);

        final relOffset = s.offset - bodyStart;
        while (hasMapping && reader.offset <= i) {
          if (reader.hasSourcePosition) {
            writer.setSourcePositionWithIndices(
              relOffset,
              reader.fileIndex,
              reader.line,
              reader.col,
              reader.nameIndex,
            );
          } else {
            writer.clearSourcePosition(relOffset);
          }
          hasMapping = reader.moveNext();
        }

        instr.serialize(s);
      }

      writer.clearSourcePosition(s.offset - bodyStart);
      return writer.build();
    } else {
      for (int i = 0; i < instructions.length; i++) {
        final instr = instructions[i];
        if (_stackTraces != null) s.debugTrace(_stackTraces[instr]!);
        instr.serialize(s);
      }
      return null;
    }
  }

  void printInitializerTo(IrPrinter p) {
    for (int k = 0; k < instructions.length; ++k) {
      final i = instructions[k];
      if (i is End) return;
      if (p.preferMultiline) {
        p.write('(');
        i.printTo(p);
        p.writeln(')');
      } else {
        p.write(k > 0 ? ' (' : '(');
        i.printTo(p);
        p.write(')');
      }
    }
  }

  void printTo(IrPrinter p) {
    p.beginLabeledBlock(null);

    final debugInfo = this.debugInfo;
    final reader =
        (p.printSourcePositions && debugInfo != null && debugInfo.isNotEmpty)
        ? DebugInfoReader(debugInfo, p.module.debugInfoTables)
        : null;
    bool hasMapping = reader?.moveNext() ?? false;

    Uri? currentFileUri;
    int? currentLine;
    int? currentCol;
    bool currentHasPosition = false;

    Uri? lastPrintedFileUri;
    int? lastPrintedLine;
    int? lastPrintedCol;

    for (int k = 0; k < instructions.length; ++k) {
      final i = instructions[k];

      if (reader != null) {
        while (hasMapping && reader.offset <= k) {
          currentHasPosition = reader.hasSourcePosition;
          if (currentHasPosition) {
            currentFileUri = reader.fileUri;
            currentLine = reader.line;
            currentCol = reader.col;
          } else {
            currentFileUri = null;
            currentLine = null;
            currentCol = null;
          }
          hasMapping = reader.moveNext();
        }

        if (currentHasPosition && currentFileUri != null) {
          final lineChanged =
              currentFileUri != lastPrintedFileUri ||
              currentLine != lastPrintedLine;
          final colChanged = currentCol != lastPrintedCol;
          if (lineChanged || colChanged) {
            lastPrintedFileUri = currentFileUri;
            lastPrintedLine = currentLine;
            lastPrintedCol = currentCol;
            p.printSourcePosition(
              currentFileUri,
              currentLine!,
              currentCol!,
              printUrl: lineChanged,
            );
          }
        } else {
          if (lastPrintedFileUri != null) {
            p.printUnmapped();
          }
          lastPrintedFileUri = null;
          lastPrintedLine = null;
          lastPrintedCol = null;
        }
      }

      final isTry =
          i is BeginNoEffectTry ||
          i is BeginOneOutputTry ||
          i is BeginFunctionTry;
      final isTryTable =
          i is BeginNoEffectTryTable ||
          i is BeginOneOutputTryTable ||
          i is BeginFunctionTryTable;
      final isIf =
          i is BeginNoEffectIf || i is BeginOneOutputIf || i is BeginFunctionIf;
      final isBlock =
          i is BeginNoEffectBlock ||
          i is BeginOneOutputBlock ||
          i is BeginFunctionBlock;
      final isLoop =
          i is BeginNoEffectLoop ||
          i is BeginOneOutputLoop ||
          i is BeginFunctionLoop;
      if (isTry || isIf || isBlock || isTryTable || isLoop) {
        p.beginLabeledBlock(i);
        i.printTo(p);
        p.writeln();
        p.indent();
        continue;
      }

      final isCatch = i is CatchLegacy || i is CatchAllLegacy;
      final isElse = i is Else;
      if (isCatch || isElse) {
        p.deindent();
        i.printTo(p);
        p.writeln();
        p.indent();
        continue;
      }

      final isEnd = i is End;
      if (isEnd) {
        final labelInfo = p.endLabeledBlock();
        if (labelInfo?.target != null) {
          // The outermost label belongs to the function and it wasn't indented
          // so we don't have to deindent either.
          p.deindent();
        }
        final isLast = k == (instructions.length - 1);
        if (!isLast) {
          i.printTo(p);
          if (labelInfo != null && labelInfo.used) {
            p.write(' ');
            p.write(labelInfo.name!);
          }
          p.writeln();
        }
        continue;
      }

      i.printTo(p);
      p.writeln();
    }
    p.endLabeledBlock();
  }

  static Instructions deserializeConst(
    Deserializer d,
    Types types,
    Functions functions,
    Globals globals,
  ) {
    final instructions = <Instruction>[];
    while (true) {
      final instruction = Instruction.deserializeConst(
        d,
        types,
        functions,
        globals,
      );
      instructions.add(instruction);
      if (instruction is End) break;
    }
    return Instructions(const [], const {}, instructions, null, const [], null);
  }

  static Instructions deserialize(
    Deserializer d,
    Module module,
    Types types,
    Functions functions,
    Tables tables,
    Memories memories,
    Tags tags,
    Globals globals,
    DataSegments dataSegments,
  ) {
    final instructions = <Instruction>[];
    while (true) {
      final instruction = Instruction.deserialize(
        d,
        types,
        tables,
        tags,
        globals,
        dataSegments,
        memories,
        functions,
      );
      instructions.add(instruction);
      if (instruction is End) break;
    }
    return Instructions(const [], const {}, instructions, null, const [], null);
  }
}
