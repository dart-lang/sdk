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
  final bool isWide;
  final List<int> operands;
  final int pc;

  Instruction(this.opcode, this.isWide, this.operands, this.pc);

  Format get format => BytecodeFormats[opcode];

  int get length => instructionSize(format.encoding, isWide);

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
  Uint8List _bytecode;
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

  List<Instruction> decode(Uint8List bytecode) {
    _init(bytecode);
    return _instructions;
  }

  void _init(List<int> bytecode) {
    _bytecode = new Uint8List.fromList(bytecode);

    _instructions = new List<Instruction>();
    for (int pos = 0; pos < _bytecode.length;) {
      final instr = decodeInstructionAt(pos);
      _instructions.add(instr);
      pos += instr.length;
    }

    _labelCount = 0;
    _labels = <int, String>{};
    _markers = <int, List<String>>{};
  }

  Instruction decodeInstructionAt(int pos) {
    Opcode opcode = Opcode.values[_bytecode[pos]];
    bool isWide = isWideOpcode(opcode);
    if (isWide) {
      opcode = fromWideOpcode(opcode);
    }

    final format = BytecodeFormats[opcode];
    final operands = _decodeOperands(format, pos, isWide);
    return new Instruction(opcode, isWide, operands, pos);
  }

  List<int> _decodeOperands(Format format, int pos, bool isWide) {
    switch (format.encoding) {
      case Encoding.k0:
        return const [];
      case Encoding.kA:
        return [_bytecode[pos + 1]];
      case Encoding.kD:
        return isWide ? [_decodeUint32At(pos + 1)] : [_bytecode[pos + 1]];
      case Encoding.kX:
        return isWide
            ? [_decodeUint32At(pos + 1).toSigned(32)]
            : [_bytecode[pos + 1].toSigned(8)];
      case Encoding.kT:
        return isWide
            ? [
                (_bytecode[pos + 1] +
                        (_bytecode[pos + 2] << 8) +
                        (_bytecode[pos + 3] << 16))
                    .toSigned(24)
              ]
            : [_bytecode[pos + 1].toSigned(8)];
      case Encoding.kAE:
        return [
          _bytecode[pos + 1],
          isWide ? _decodeUint32At(pos + 2) : _bytecode[pos + 2],
        ];
      case Encoding.kAY:
        return [
          _bytecode[pos + 1],
          isWide
              ? _decodeUint32At(pos + 2).toSigned(32)
              : _bytecode[pos + 2].toSigned(8)
        ];
      case Encoding.kDF:
        return isWide
            ? [_decodeUint32At(pos + 1), _bytecode[pos + 5]]
            : [_bytecode[pos + 1], _bytecode[pos + 2]];
      case Encoding.kABC:
        return [_bytecode[pos + 1], _bytecode[pos + 2], _bytecode[pos + 3]];
    }
    throw 'Unexpected format $format';
  }

  _decodeUint32At(int pos) =>
      _bytecode[pos] +
      (_bytecode[pos + 1] << 8) +
      (_bytecode[pos + 2] << 16) +
      (_bytecode[pos + 3] << 24);

  void _scanForJumpTargets() {
    for (int i = 0; i < _instructions.length; i++) {
      final instr = _instructions[i];
      if (isJump(instr.opcode)) {
        final target = instr.pc + instr.operands[0];
        assert(0 <= target && target < _bytecode.length);
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
    for (Instruction instr in _instructions) {
      List<String> markers = _markers[instr.pc];
      if (markers != null) {
        markers.forEach(out.writeln);
      }
      writeInstruction(out, instr);
    }
    return out.toString();
  }

  void writeInstruction(StringBuffer out, Instruction instr) {
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
          _formatOperand(instr.pc, format.operands[i], instr.operands[i]);
      out.write(operand);
    }

    out.writeln();
  }

  String _formatOperand(int pc, Operand fmt, int value) {
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
            : _labels[pc + value] ?? (throw 'Label not found');
      case Operand.spe:
        return SpecialIndex.values[value]
            .toString()
            .substring('SpecialIndex.'.length);
    }
    throw 'Unexpected operand format $fmt';
  }
}
