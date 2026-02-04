// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/flow_graph.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/visitor.dart';

/// Converts IR (either graph or a single instruction) to the text form.
final class IrToText extends VoidInstructionVisitor {
  final StringBuffer _buffer = StringBuffer();
  final bool printDominators;
  final bool printLoops;
  final String? Function(Instruction)? annotator;

  IrToText(
    FlowGraph graph, {
    this.printDominators = false,
    this.printLoops = false,
    this.annotator,
    Iterable<Block>? blockOrder,
  }) {
    blockOrder ??= graph.reversePostorder;
    for (final block in blockOrder) {
      block.accept(this);
    }
  }

  IrToText.instruction(
    Instruction instr, {
    this.printDominators = false,
    this.printLoops = false,
    this.annotator,
  }) {
    instr.accept(this);
  }

  String toString() => _buffer.toString();

  @override
  void defaultInstruction(Instruction instr) {
    _printReferenceIfNeeded(instr);
    _buffer.write(opcode(instr));
    _buffer.write('(');
    _printInputs(instr);
    _buffer.write(')');
    final extraInfo = annotator?.call(instr);
    if (extraInfo != null && extraInfo.isNotEmpty) {
      _buffer.write(' ');
      _buffer.write(extraInfo);
    }
  }

  @override
  void defaultBlock(Block block) {
    super.defaultBlock(block);
    if (block.exceptionHandler != null) {
      _buffer.write(' exception-handler:${reference(block.exceptionHandler!)}');
    }
    if (printDominators) {
      if (block.dominator != null) {
        _buffer.write(' idom:${reference(block.dominator!)}');
      }
      if (block.dominatedBlocks.isNotEmpty) {
        _buffer.write(' dominates:${block.dominatedBlocks.map(reference)}');
      }
    }
    if (printLoops) {
      final loop = block.loop;
      if (loop != null) {
        if (block == loop.header) {
          _buffer.write(
            ' loop-header (depth:${loop.depth}' +
                ' body:${loop.body.map(reference)}' +
                ' back-edges:${loop.backEdges.map(reference)})',
          );
        } else {
          _buffer.write(' in-loop:${reference(loop.header)}');
        }
      }
    }
    _buffer.writeln();
    for (final instr in block) {
      _buffer.write('  ');
      instr.accept(this);
      _buffer.writeln();
    }
  }

  void _printReferenceIfNeeded(Instruction instr) {
    if (instr is Definition && instr.hasUses || instr is Block) {
      _buffer.write(reference(instr));
      _buffer.write(' = ');
    }
  }

  void _printInputs(Instruction instr) {
    switch (instr) {
      case Parameter():
        _buffer.write(instr.variable.name);
      case LoadLocal():
        _buffer.write(instr.variable.name);
      case StoreLocal():
        _buffer.write(instr.variable.name);
        _buffer.write(', ');
      case LoadField():
        _buffer.write(instr.field);
        if (instr.inputCount > 0) {
          _buffer.write(', ');
        }
      case StoreField():
        _buffer.write(instr.field);
        _buffer.write(', ');
      case TypeLiteral():
        _buffer.write(instr.uninstantiatedType.getDisplayString());
        _buffer.write(', ');
      case _:
    }
    for (int i = 0, n = instr.inputCount; i < n; ++i) {
      if (i != 0) _buffer.write(', ');
      _buffer.write(reference(instr.inputDefAt(i)));
    }
    switch (instr) {
      case JoinBlock():
        _buffer.write(instr.predecessors.map(reference).join(', '));
      case Goto():
        _buffer.write(reference(instr.target));
      case Branch():
        _buffer.write(', true: ');
        _buffer.write(reference(instr.trueSuccessor));
        _buffer.write(', false: ');
        _buffer.write(reference(instr.falseSuccessor));
      case CompareAndBranch():
        _buffer.write(', true: ');
        _buffer.write(reference(instr.trueSuccessor));
        _buffer.write(', false: ');
        _buffer.write(reference(instr.falseSuccessor));
      case TryEntry():
        _buffer.write('try-body: ');
        _buffer.write(reference(instr.tryBody));
        _buffer.write(', catch-block: ');
        _buffer.write(reference(instr.catchBlock));
      case Constant():
        _buffer.write(instr.value.valueToString());
      case TypeCast():
        _buffer.write(', ');
        _buffer.write(instr.testedType);
        if (!instr.isChecked) {
          _buffer.write(', unchecked');
        }
      case TypeTest():
        _buffer.write(', ');
        _buffer.write(instr.testedType);
      case TypeArguments():
        if (instr.inputCount > 0) _buffer.write(', ');
        _buffer.write('<');
        _buffer.write(
          instr.types.map((type) => type.getDisplayString()).join(', '),
        );
        _buffer.write('>');
      case ParallelMove():
        _buffer.write(instr.moves.join(', '));
      case _:
    }
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
    AllocateObject() => 'AllocateObject ${instr.type}',
    BinaryIntOp() => 'BinaryIntOp ${instr.op.token}',
    UnaryIntOp() => 'UnaryIntOp ${instr.op.token}',
    BinaryDoubleOp() => 'BinaryDoubleOp ${instr.op.token}',
    UnaryDoubleOp() => 'UnaryDoubleOp ${instr.op.token}',
    UnaryBoolOp() => 'UnaryBoolOp ${instr.op.token}',
    ParallelMove() => 'ParallelMove ${instr.stage.name}',
    _ => instr.runtimeType.toString(),
  };
}
