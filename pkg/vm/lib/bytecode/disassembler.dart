// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.disassembler;

import 'dart:typed_data';

import 'package:vm/bytecode/dbc.dart';

class _Instruction {
  final Opcode opcode;
  final List<int> operands;
  _Instruction(this.opcode, this.operands);
}

class BytecodeDisassembler {
  static const int kOpcodeMask = 0xFF;
  static const int kBitsPerInt = 64;

  List<_Instruction> _instructions;
  int _labelCount;
  Map<int, int> _labels;

  String disassemble(List<int> bytecode) {
    _init(bytecode);
    _scanForJumpTargets();
    return _disasm();
  }

  void _init(List<int> bytecode) {
    final uint8list = new Uint8List.fromList(bytecode);
    // TODO(alexmarkov): endianness?
    Uint32List words = uint8list.buffer.asUint32List();

    _instructions = new List<_Instruction>(words.length);
    for (int i = 0; i < words.length; i++) {
      _instructions[i] = _decodeInstruction(words[i]);
    }

    _labelCount = 0;
    _labels = <int, int>{};
  }

  _Instruction _decodeInstruction(int word) {
    final opcode = Opcode.values[word & kOpcodeMask];
    final format = BytecodeFormats[opcode];
    return new _Instruction(opcode, _decodeOperands(format, word));
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
      if (instr.opcode == Opcode.kJump) {
        final target = i + instr.operands[0];
        assert(0 <= target && target < _instructions.length);
        _labels[target] ??= (++_labelCount);
      }
    }
  }

  String _disasm() {
    StringBuffer out = new StringBuffer();
    for (int i = 0; i < _instructions.length; i++) {
      int label = _labels[i];
      if (label != null) {
        out.writeln('L$label:');
      }
      _writeInstruction(out, i, _instructions[i]);
    }
    return out.toString();
  }

  void _writeInstruction(StringBuffer out, int bci, _Instruction instr) {
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
        return 'L${_labels[bci + value] ?? (throw 'Label not found')}';
    }
    throw 'Unexpected operand format $fmt';
  }
}
