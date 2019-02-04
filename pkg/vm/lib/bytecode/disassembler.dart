// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.disassembler;

import 'dart:typed_data';

import 'package:kernel/ast.dart' show listEquals, listHashCode;

import 'dbc.dart';
import 'exceptions.dart';

class Instruction {
  final Opcode opcode;
  final List<int> operands;
  Instruction(this.opcode, this.operands);

  @override
  int get hashCode => opcode.index.hashCode ^ listHashCode(operands);

  @override
  bool operator ==(other) {
    return (other is Instruction) &&
        (opcode == other.opcode) &&
        listEquals(operands, other.operands);
  }
}

class BytecodeDisassembler {
  static const int kOpcodeMask = 0xFF;
  static const int kBitsPerInt = 64;

  List<Instruction> _instructions;
  int _labelCount;
  Map<int, String> _labels;
  Map<int, List<String>> _markers;

  String disassemble(List<int> bytecode, ExceptionsTable exceptionsTable,
      {List<Map<int, String>> annotations}) {
    _init(bytecode);
    _scanForJumpTargets();
    _markTryBlocks(exceptionsTable);
    if (annotations != null) {
      _markAnnotations(annotations);
    }
    return _disasm();
  }

  void _init(List<int> bytecode) {
    final uint8list = new Uint8List.fromList(bytecode);
    // TODO(alexmarkov): endianness?
    Uint32List words = uint8list.buffer.asUint32List();

    _instructions = new List<Instruction>(words.length);
    for (int i = 0; i < words.length; i++) {
      _instructions[i] = decodeInstruction(words[i]);
    }

    _labelCount = 0;
    _labels = <int, String>{};
    _markers = <int, List<String>>{};
  }

  Instruction decodeInstruction(int word) {
    final opcode = Opcode.values[word & kOpcodeMask];
    final format = BytecodeFormats[opcode];
    return new Instruction(opcode, _decodeOperands(format, word));
  }

  List<int> _decodeOperands(Format format, int word) {
    switch (format.encoding) {
      case Encoding.k0:
        return const [];
      case Encoding.kA:
        return [_unsigned(word, 8, 8)];
      case Encoding.kAD:
        return [_unsigned(word, 8, 8), _unsigned(word, 16, 16)];
      case Encoding.kAX:
        return [_unsigned(word, 8, 8), _signed(word, 16, 16)];
      case Encoding.kD:
        return [_unsigned(word, 16, 16)];
      case Encoding.kX:
        return [_signed(word, 16, 16)];
      case Encoding.kABC:
        return [
          _unsigned(word, 8, 8),
          _unsigned(word, 16, 8),
          _unsigned(word, 24, 8)
        ];
      case Encoding.kABY:
        return [
          _unsigned(word, 8, 8),
          _unsigned(word, 16, 8),
          _signed(word, 24, 8)
        ];
      case Encoding.kT:
        return [_signed(word, 8, 24)];
    }
    throw 'Unexpected format $format';
  }

  int _unsigned(int word, int pos, int bits) =>
      (word >> pos) & ((1 << bits) - 1);

  int _signed(int word, int pos, int bits) =>
      _unsigned(word, pos, bits) <<
      (kBitsPerInt - bits) >>
      (kBitsPerInt - bits);

  void _scanForJumpTargets() {
    for (int i = 0; i < _instructions.length; i++) {
      final instr = _instructions[i];
      if (isJump(instr.opcode)) {
        final target = i + instr.operands[0];
        assert(0 <= target && target < _instructions.length);
        if (!_labels.containsKey(target)) {
          final label = 'L${++_labelCount}';
          _labels[target] = label;
          _addMarker(target, '$label:');
        }
      }
    }
  }

  void _markTryBlocks(ExceptionsTable exceptionsTable) {
    for (var tryBlock in exceptionsTable.blocks) {
      final int tryIndex = tryBlock.tryIndex;
      _addMarker(tryBlock.startPC, 'Try #$tryIndex start:');
      _addMarker(tryBlock.endPC, 'Try #$tryIndex end:');
      _addMarker(tryBlock.handlerPC, 'Try #$tryIndex handler:');
    }
  }

  void _markAnnotations(List<Map<int, String>> annotations) {
    for (var map in annotations) {
      map.forEach((int pc, String annotation) {
        _addMarker(pc, '# $annotation');
      });
    }
  }

  void _addMarker(int pc, String marker) {
    final markers = (_markers[pc] ??= <String>[]);
    markers.add(marker);
  }

  String _disasm() {
    StringBuffer out = new StringBuffer();
    for (int i = 0; i < _instructions.length; i++) {
      List<String> markers = _markers[i];
      if (markers != null) {
        markers.forEach(out.writeln);
      }
      writeInstruction(out, i, _instructions[i]);
    }
    return out.toString();
  }

  void writeInstruction(StringBuffer out, int bci, Instruction instr) {
    final format = BytecodeFormats[instr.opcode];
    assert(format != null);

    out.write('  ');

    const int kOpcodeWidth = 20;
    const String kOpcodePrefix = 'Opcode.k';

    String opcode = instr.opcode.toString();
    assert(opcode.startsWith(kOpcodePrefix));
    opcode = opcode.substring(kOpcodePrefix.length);

    if (instr.operands.isEmpty) {
      out.writeln(opcode);
      return;
    }

    out.write(opcode.padRight(kOpcodeWidth));

    for (int i = 0; i < instr.operands.length; i++) {
      if (i == 0) {
        out.write(' ');
      } else {
        out.write(', ');
      }
      final operand =
          _formatOperand(bci, format.operands[i], instr.operands[i]);
      out.write(operand);
    }

    out.writeln();
  }

  String _formatOperand(int bci, Operand fmt, int value) {
    switch (fmt) {
      case Operand.none:
        break;
      case Operand.imm:
        return '$value';
      case Operand.lit:
        return 'CP#$value';
      case Operand.reg:
        return 'r$value';
      case Operand.xeg:
        return (value < 0) ? 'FP[$value]' : 'r$value';
      case Operand.tgt:
        return (_labels == null)
            ? value.toString()
            : _labels[bci + value] ?? (throw 'Label not found');
      case Operand.spe:
        return SpecialIndex.values[value]
            .toString()
            .substring('SpecialIndex.'.length);
    }
    throw 'Unexpected operand format $fmt';
  }
}
