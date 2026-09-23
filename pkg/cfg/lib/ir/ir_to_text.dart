// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/flow_graph.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/visitor.dart';

/// Converts IR (either graph or a single instruction) to the text form.
final class IrToText extends VoidInstructionVisitor {
  final List<String> lines = [];
  final StringBuffer _currentLine = StringBuffer();
  final bool printDominators;
  final bool printLoops;
  final String? Function(Instruction)? annotator;
  final Map<Instruction, InstructionTextPosition>? positions;

  IrToText(
    FlowGraph graph, {
    this.printDominators = false,
    this.printLoops = false,
    this.annotator,
    this.positions,
    Iterable<Block>? blockOrder,
  }) {
    blockOrder ??= graph.reversePostorder;
    for (final block in blockOrder) {
      block.accept(this);
    }
    lines.add('');
  }

  IrToText.instruction(
    Instruction instr, {
    this.printDominators = false,
    this.printLoops = false,
    this.annotator,
  }) : positions = null {
    instr.accept(this);
    if (_currentLine.isNotEmpty) {
      _writeln();
    }
  }

  @override
  String toString() => lines.join('\n');

  @override
  void defaultInstruction(Instruction instr) {
    _printReferenceIfNeeded(instr);
    final line = lines.length;
    final col = instr is Block ? 0 : _currentLine.length;
    _currentLine.write(opcode(instr));
    _currentLine.write('(');
    final inputCols = _printInputs(instr);
    _currentLine.write(')');
    positions?[instr] = InstructionTextPosition(line, col, inputCols);
    final extraInfo = annotator?.call(instr);
    if (extraInfo != null && extraInfo.isNotEmpty) {
      _currentLine.write(' ');
      _currentLine.write(extraInfo);
    }
  }

  @override
  void defaultBlock(Block block) {
    super.defaultBlock(block);
    if (block.exceptionHandler != null) {
      _currentLine.write(
        ' exception-handler:${reference(block.exceptionHandler!)}',
      );
    }
    if (printDominators) {
      if (block.dominator != null) {
        _currentLine.write(' idom:${reference(block.dominator!)}');
      }
      if (block.dominatedBlocks.isNotEmpty) {
        _currentLine.write(
          ' dominates:${block.dominatedBlocks.map(reference)}',
        );
      }
    }
    if (printLoops) {
      final loop = block.loop;
      if (loop != null) {
        if (block == loop.header) {
          _currentLine.write(
            ' loop-header (depth:${loop.depth}' +
                ' body:${loop.body.map(reference)}' +
                ' back-edges:${loop.backEdges.map(reference)})',
          );
        } else {
          _currentLine.write(' in-loop:${reference(loop.header)}');
        }
      }
    }
    _writeln();
    for (final instr in block) {
      _currentLine.write('  ');
      instr.accept(this);
      _writeln();
    }
  }

  void _printReferenceIfNeeded(Instruction instr) {
    if (instr is Definition && instr.hasUses || instr is Block) {
      _currentLine.write(reference(instr));
      _currentLine.write(' = ');
    }
  }

  List<int> _printInputs(Instruction instr) {
    switch (instr) {
      case Parameter():
        _currentLine.write(instr.variable.name);
      case LoadLocal():
        _currentLine.write(instr.variable.name);
      case StoreLocal():
        _currentLine.write(instr.variable.name);
        _currentLine.write(', ');
      case LoadField():
        _currentLine.write(instr.field);
        if (instr.inputCount > 0) {
          _currentLine.write(', ');
        }
      case StoreField():
        _currentLine.write(instr.field);
        _currentLine.write(', ');
      case TypeLiteral():
        _currentLine.write(instr.uninstantiatedType.getDisplayString());
        _currentLine.write(', ');
      case SubtypeCheck():
        _currentLine.write('type: ');
        _currentLine.write(instr.type);
        _currentLine.write(', bound: ');
        _currentLine.write(instr.bound);
        _currentLine.write(', name:');
        _currentLine.write(instr.name);
        if (instr.inputCount > 0) {
          _currentLine.write(', ');
        }
      case _:
    }
    List<int>? inputCols;
    final n = instr.inputCount;
    if (positions != null && n > 0) {
      inputCols = List<int>.filled(n, 0);
    }
    for (var i = 0; i < n; ++i) {
      if (i != 0) _currentLine.write(', ');
      inputCols?[i] = _currentLine.length;
      _currentLine.write(reference(instr.inputDefAt(i)));
    }
    switch (instr) {
      case JoinBlock():
        _currentLine.write(instr.predecessors.map(reference).join(', '));
      case Goto():
        _currentLine.write(reference(instr.target));
      case Branch():
        _currentLine.write(', true: ');
        _currentLine.write(reference(instr.trueSuccessor));
        _currentLine.write(', false: ');
        _currentLine.write(reference(instr.falseSuccessor));
      case CompareAndBranch():
        _currentLine.write(', true: ');
        _currentLine.write(reference(instr.trueSuccessor));
        _currentLine.write(', false: ');
        _currentLine.write(reference(instr.falseSuccessor));
      case TryEntry():
        _currentLine.write('try-body: ');
        _currentLine.write(reference(instr.tryBody));
        _currentLine.write(', catch-block: ');
        _currentLine.write(reference(instr.catchBlock));
      case Constant():
        _currentLine.write(instr.value.valueToString());
      case TypeCast():
        _currentLine.write(', ');
        _currentLine.write(instr.testedType);
        if (!instr.isChecked) {
          _currentLine.write(', unchecked');
        }
      case TypeTest():
        _currentLine.write(', ');
        _currentLine.write(instr.testedType);
      case TypeArguments():
        if (instr.inputCount > 0) _currentLine.write(', ');
        _currentLine.write('<');
        _currentLine.write(
          instr.types.map((type) => type.getDisplayString()).join(', '),
        );
        _currentLine.write('>');
      case AllocateClosure():
        _currentLine.write(instr.closureLayout);
      case ParallelMove():
        _currentLine.write(instr.moves.join(', '));
      case _:
    }
    return inputCols ?? const [];
  }

  void _writeln() {
    lines.add(_currentLine.toString());
    _currentLine.clear();
  }

  static String reference(Instruction instr) => switch (instr) {
    Definition() => 'v${instr.id}',
    Block() => 'B${instr.id}',
    _ => 'instr${instr.id}',
  };

  String opcode(Instruction instr) => switch (instr) {
    Comparison() => 'Comparison ${instr.op.token}',
    CompareAndBranch() => 'CompareAndBranch ${instr.op.token}',
    DirectCall() => 'DirectCall ${instr.target}',
    InterfaceCall() => 'InterfaceCall ${instr.interfaceTarget}',
    DynamicCall() =>
      'DynamicCall ${switch (instr.kind) {
        DynamicCallKind.method => '',
        DynamicCallKind.getter => 'get ',
        DynamicCallKind.setter => 'set ',
      }}${instr.selector}',
    ExternalCall() => 'ExternalCall ${instr.target}',
    AllocateObject() => 'AllocateObject ${instr.type}',
    Suspend() => 'Suspend ${instr.op.name}',
    BinaryIntOp() => 'BinaryIntOp ${instr.op.token}',
    UnaryIntOp() => 'UnaryIntOp ${instr.op.token}',
    BinaryDoubleOp() => 'BinaryDoubleOp ${instr.op.token}',
    UnaryDoubleOp() => 'UnaryDoubleOp ${instr.op.token}',
    UnaryBoolOp() => 'UnaryBoolOp ${instr.op.token}',
    ParallelMove() => 'ParallelMove ${instr.stage.name}',
    AllocateArray() => 'AllocateArray ${instr.kind.name}',
    AllocateRecord() => 'AllocateRecord ${instr.type}',
    _ => instr.runtimeType.toString(),
  };
}

/// Line and column positions of an [Instruction] in textual IR output.
class InstructionTextPosition {
  /// The 0-based line number of the instruction.
  final int line;

  /// The 0-based column number of the instruction's opcode.
  final int column;

  /// The 0-based column numbers of each input operand.
  final List<int> inputColumns;

  const InstructionTextPosition(this.line, this.column, this.inputColumns);

  InstructionTextPosition withLineOffset(int offset) =>
      InstructionTextPosition(line + offset, column, inputColumns);
}
