// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.ngrams;

import 'dart:io';
import 'dart:typed_data';

import 'package:kernel/ast.dart' show listEquals, listHashCode;

import 'dbc.dart';
import 'disassembler.dart' show Instruction, BytecodeDisassembler;

bool isControlFlowInstr(Instruction instr) => isControlFlow(instr.opcode);

class NGram {
  List<Instruction> instrs;
  BytecodeDisassembler _disassembler;

  NGram(this.instrs, {bool mergePushes = false}) {
    if (mergePushes) {
      _mergePushes(instrs);
    }
    _canonicalize(instrs);
  }

  /// Tests if any instructions that are not the last instruction in the window
  /// are a jump, throw, or call.
  bool get controlFlowIsNotLast =>
      instrs.sublist(0, instrs.length - 1).any(isControlFlowInstr);

  @override
  int get hashCode => listHashCode(instrs);

  @override
  bool operator ==(other) =>
      (other is NGram) && listEquals(instrs, other.instrs);

  @override
  String toString() {
    StringBuffer out = new StringBuffer();
    for (var instr in instrs) {
      _disassembler.writeInstruction(out, instr);
    }
    return out.toString();
  }

  /// Rewrites all Push-like instructions as 'Push r0'.
  static void _mergePushes(List<Instruction> instrs) {
    for (int i = 0; i < instrs.length; i++) {
      if (isPush(instrs[i].opcode)) {
        instrs[i] = new Instruction(Opcode.kPush, false, <int>[0], 0);
      }
    }
  }

  /// Rewrites the operands of instructions so that ngrams that differ only in
  /// operands can be considered the same.
  ///
  /// Each type of operand is considered to come from a different space, and
  /// each operand is re-indexed in that space starting from 0 such that each
  /// distinct operand before canonicalization remains distinct afterwords. E.g.
  ///
  /// Push r3
  /// Push r3
  /// Push r4
  ///
  /// Becomes
  ///
  /// Push r0
  /// Push r0
  /// Push r1
  static void _canonicalize(List<Instruction> instrs) {
    Map<Operand, Map<int, int>> operandMaps = <Operand, Map<int, int>>{
      // No mapping for Operand.none.
      Operand.imm: <int, int>{},
      Operand.lit: <int, int>{},
      Operand.reg: <int, int>{},
      Operand.xeg: <int, int>{},
      Operand.tgt: <int, int>{},
      // No mapping for Operand.spe.
    };
    for (Instruction instr in instrs) {
      Format fmt = BytecodeFormats[instr.opcode];
      for (int i = 0; i < instr.operands.length; i++) {
        Operand op = fmt.operands[i];
        if (!operandMaps.containsKey(op)) {
          continue;
        }
        int newOperand = operandMaps[op]
            .putIfAbsent(instr.operands[i], () => operandMaps[op].length);
        instr.operands[i] = newOperand;
      }
    }
  }
}

class NGramReader {
  List<Instruction> _instructions;

  Map<NGram, int> _ngramCounts = <NGram, int>{};

  NGramReader(String traceFilename) {
    File traceFile = File(traceFilename);
    Uint8List bytecode = traceFile.readAsBytesSync();
    final disassembler = new BytecodeDisassembler();
    _instructions = disassembler.decode(bytecode);
  }

  Map<NGram, int> get ngramCounts => _ngramCounts;

  void readAllNGrams(int windowSize,
      {bool basicBlocks: true, bool mergePushes: false}) {
    int offset = 0;
    while (offset + windowSize < _instructions.length) {
      List<Instruction> window =
          _instructions.sublist(offset, offset + windowSize);
      offset += 1;
      NGram ngram = new NGram(window, mergePushes: mergePushes);
      if (basicBlocks && ngram.controlFlowIsNotLast) {
        continue;
      }
      _ngramCounts.update(ngram, (count) => count + 1, ifAbsent: () => 1);
    }
  }

  void writeNGramStats(String outputFilename,
      {bool sort = true, int minCount = 1000}) {
    File outputFile = new File(outputFilename);
    IOSink file = outputFile.openWrite();
    List<MapEntry<NGram, int>> entries =
        _ngramCounts.entries.where((e) => e.value > minCount).toList();
    if (sort) {
      entries.sort((e1, e2) => e2.value - e1.value);
    }
    entries.forEach((e) {
      file.write("count: ${e.value}\n${e.key}\n");
    });
    file.close();
  }
}
