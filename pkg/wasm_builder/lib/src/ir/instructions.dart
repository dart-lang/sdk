// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../source_map.dart';
import '../serialize/serialize.dart';
import '../serialize/printer.dart';
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

  /// Mappings for the instructions in [_instructions] to their source code.
  ///
  /// Since we add mappings as we generate instructions, this will be sorted
  /// based on [SourceMapping.instructionOffset].
  final List<SourceMapping>? _sourceMappings;

  /// Create a new instruction sequence.
  Instructions(this.locals, this.localNames, this.instructions,
      this._stackTraces, this._traceLines, this._sourceMappings);

  @override
  void serialize(Serializer s) {
    final sourceMappings = _sourceMappings;
    int sourceMappingIdx = 0;
    for (int instructionIdx = 0;
        instructionIdx < instructions.length;
        instructionIdx += 1) {
      final i = instructions[instructionIdx];
      if (_stackTraces != null) s.debugTrace(_stackTraces[i]!);

      if (sourceMappings != null) {
        // Skip to the mapping that covers the current instruction.
        while (sourceMappingIdx < sourceMappings.length - 1 &&
            sourceMappings[sourceMappingIdx + 1].instructionOffset <=
                instructionIdx) {
          sourceMappingIdx += 1;
        }

        if (sourceMappingIdx < sourceMappings.length) {
          final mapping = sourceMappings[sourceMappingIdx];
          if (mapping.instructionOffset <= instructionIdx) {
            s.sourceMapSerializer.addMapping(s.offset, mapping.sourceInfo);
            sourceMappingIdx += 1;
          }
        }
      }

      i.serialize(s);
    }

    s.sourceMapSerializer.addMapping(s.offset, null);
  }

  void printInitializerTo(IrPrinter p) {
    for (int k = 0; k < instructions.length; ++k) {
      final i = instructions[k];
      if (i is End) return;
      p.write(k > 0 ? ' (' : '(');
      i.printTo(p);
      p.write(')');
    }
  }

  void printTo(IrPrinter p) {
    p.beginLabeledBlock(null);
    for (int k = 0; k < instructions.length; ++k) {
      final i = instructions[k];

      final isTry = i is BeginNoEffectTry ||
          i is BeginOneOutputTry ||
          i is BeginFunctionTry;
      final isTryTable = i is BeginNoEffectTryTable ||
          i is BeginOneOutputTryTable ||
          i is BeginFunctionTryTable;
      final isIf =
          i is BeginNoEffectIf || i is BeginOneOutputIf || i is BeginFunctionIf;
      final isBlock = i is BeginNoEffectBlock ||
          i is BeginOneOutputBlock ||
          i is BeginFunctionBlock;
      final isLoop = i is BeginNoEffectLoop ||
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
      final instruction =
          Instruction.deserializeConst(d, types, functions, globals);
      instructions.add(instruction);
      if (instruction is End) break;
    }
    return Instructions([], {}, instructions, null, [], null);
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
          d, types, tables, tags, globals, dataSegments, memories, functions);
      instructions.add(instruction);
      if (instruction is End) break;
    }
    return Instructions([], {}, instructions, null, [], null);
  }
}
