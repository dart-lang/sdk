// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/visitor.dart';
import 'package:cfg/passes/pass.dart';
import 'package:native_compiler/back_end/assembler.dart';
import 'package:native_compiler/back_end/back_end_state.dart';
import 'package:native_compiler/back_end/locations.dart';
import 'package:native_compiler/back_end/object_pool.dart';

/// Generated code for a function.
class Code {
  final CFunction function;
  final Uint8List instructions;
  final ObjectPool objectPool;

  /// Offset of instructions in the resulting image.
  int? instructionsImageOffset;

  Code(this.function, this.instructions, this.objectPool);
}

/// Comsumer of the generated code.
typedef CodeConsumer = void Function(Code);

/// Base class for architecture-specific code generator.
///
/// Contains common algorithms and code generation snippets which can be
/// used on multiple architectures.
abstract base class CodeGenerator extends Pass
    implements InstructionVisitor<void> {
  final BackEndState backEndState;

  late final Assembler _asm;

  /// Index of the current block in [codeGenBlockOrder].
  int _currentBlockIndex = -1;

  /// Maps block preorder number to a preorder number of
  /// the first non-empty block.
  late final Int32List _firstNonEmptyBlock = _computeFirstNonEmptyBlock();

  /// Maps preorder number of a block to
  /// a [Label] corresponding to the block entry.
  late final List<Label> _blockLabels = List<Label>.generate(
    graph.preorder.length,
    (i) => Label(),
  );

  CodeGenerator(this.backEndState) : super('CodeGen');

  List<Block> get codeGenBlockOrder => backEndState.codeGenBlockOrder;

  Location loc(OperandId operandId) =>
      backEndState.operandLocations[operandId]!.physicalLocation;
  Location inputLoc(Instruction instr, int inputIndex) =>
      loc(OperandId.input(instr.id, inputIndex));

  Register inputReg(Instruction instr, int inputIndex) =>
      inputLoc(instr, inputIndex) as Register;
  Register tempReg(Instruction instr, int tempIndex) =>
      loc(OperandId.temp(instr.id, tempIndex)) as Register;
  Register outputReg(Instruction instr) =>
      loc(OperandId.result(instr.id)) as Register;

  FPRegister inputFPReg(Instruction instr, int inputIndex) =>
      inputLoc(instr, inputIndex) as FPRegister;
  FPRegister tempFPReg(Instruction instr, int tempIndex) =>
      loc(OperandId.temp(instr.id, tempIndex)) as FPRegister;
  FPRegister outputFPReg(Instruction instr) =>
      loc(OperandId.result(instr.id)) as FPRegister;

  Block firstNonEmptyBlocks(Block block) =>
      graph.preorder[_firstNonEmptyBlock[block.preorderNumber]];

  Label blockLabel(Block block) => _blockLabels[block.preorderNumber];

  bool canFallThroughTo(Block block) {
    assert(_currentBlockIndex >= 0);
    if (_currentBlockIndex == codeGenBlockOrder.length - 1) {
      // The last block cannot fall through.
      return false;
    }
    final nextBlock = codeGenBlockOrder[_currentBlockIndex + 1];
    return _firstNonEmptyBlock[block.preorderNumber] ==
        _firstNonEmptyBlock[nextBlock.preorderNumber];
  }

  @override
  void run() {
    final blocks = codeGenBlockOrder;
    assert(blocks.first is EntryBlock);
    assert(blocks.length == graph.preorder.length);

    _asm = createAssembler();

    enterFrame();
    for (int i = 0, n = blocks.length; i < n; ++i) {
      _currentBlockIndex = i;
      final block = currentBlock = blocks[i];
      generateBlock(block);
    }
    _currentBlockIndex = -1;

    backEndState.consumeGeneratedCode(
      Code(graph.function, _asm.bytes, _asm.objectPool),
    );
  }

  Assembler createAssembler();

  void enterFrame();

  void generateBlock(Block block) {
    _asm.bind(blockLabel(block));
    block.accept(this);
    for (final instr in block) {
      currentInstruction = instr;
      instr.accept(this);
    }
  }

  /// Returns true if no code should be generated for this block.
  bool isEmptyBlock(Block block) => block is! CatchBlock && block.next is Goto;

  /// For each block, calculate the first non-empty block
  /// which cannot be skipped while generating code. Handles cycles.
  Int32List _computeFirstNonEmptyBlock() {
    final numBlocks = graph.preorder.length;
    final firstNonEmpty = Int32List(numBlocks);
    final emptyBlocks = <Block>[];
    for (var i = 1; i < numBlocks; ++i) {
      if (firstNonEmpty[i] != 0) {
        continue;
      }
      firstNonEmpty[i] = i;
      Block block = graph.preorder[i];
      if (!isEmptyBlock(block)) continue;
      // Collect empty blocks until reaching an non-empty block or
      // an empty block which has been seen already.
      for (;;) {
        emptyBlocks.add(block);
        block = block.successors.single;
        if (firstNonEmpty[block.preorderNumber] != 0) {
          break;
        }
        firstNonEmpty[block.preorderNumber] = block.preorderNumber;
        if (!isEmptyBlock(block)) {
          break;
        }
      }
      final nonEmpty = firstNonEmpty[block.preorderNumber];
      for (final block in emptyBlocks) {
        firstNonEmpty[block.preorderNumber] = nonEmpty;
      }
      emptyBlocks.clear();
    }
    return firstNonEmpty;
  }

  @override
  void visitEntryBlock(EntryBlock instr) {}

  @override
  void visitJoinBlock(JoinBlock instr) {}

  @override
  void visitTargetBlock(TargetBlock instr) {}

  @override
  void visitCatchBlock(CatchBlock instr) {}

  @override
  void visitGoto(Goto instr) {
    final target = instr.target;
    if (!canFallThroughTo(target)) {
      _asm.jump(blockLabel(target));
    }
  }

  @override
  void visitTryEntry(TryEntry instr) {
    final target = instr.tryBody;
    if (!canFallThroughTo(target)) {
      _asm.jump(blockLabel(target));
    }
  }

  @override
  void visitPhi(Phi instr) {
    // Generated via ParallelMove instructions inserted by register allocator.
  }

  @override
  void visitParallelMove(ParallelMove instr) {
    // TODO: merge subsequent ParallelMove instructions.
    final map = <Location, Location>{};
    for (final move in instr.moves) {
      if (move is Move && move.from != move.to) {
        assert(!map.containsKey(move.from));
        map[move.from] = move.to;
      }
    }
    for (final move in instr.moves) {
      if (move is Move && map.containsKey(move.from)) {
        if (map.containsKey(move.to)) {
          _generateDependentMoves(move.from, move.to, map);
        } else {
          generateMove(move.from, move.to);
          map.remove(move.from);
        }
      }
    }
    for (final move in instr.moves) {
      if (move is LoadConstant) {
        generateLoadConstant(move.value, move.to);
      }
    }
  }

  void _generateDependentMoves(
    Location from,
    Location to,
    Map<Location, Location> moves,
  ) {
    assert(from != to);
    final pendingList = <Location>[from];
    final pendingSet = <Location>{from};
    // Visit the chain of dependent moves until it ends or cycle is found.
    while (moves.containsKey(to)) {
      if (pendingSet.contains(to)) {
        // Moves form a cycle. Save value on the stack to generate moves.
        // TODO: regalloc should provide scratch register(s) for
        // ParallelMove instructions if there are available registers.
        // TODO: we can also allocate a scratch register from ParallelMove
        // itself, resusing source registers which are already moved out or
        // destination registers which are not moved in yet.
        // TODO: as a last resort, allocate a scratch space on the stack and
        // avoid any push/pop.
        generatePush(to);
        for (final from in pendingList.reversed) {
          if (from == to) {
            generatePop(moves.remove(from)!);
            break;
          }
          generateMove(from, moves.remove(from)!);
        }
        break;
      }
      from = to;
      to = moves[from]!;
      pendingList.add(from);
      pendingSet.add(from);
    }
    for (final from in pendingList.reversed) {
      generateMove(from, moves.remove(from)!);
    }
  }

  void generateMove(Location from, Location to);
  void generateLoadConstant(ConstantValue value, Location to);
  void generatePush(Location loc);
  void generatePop(Location loc);

  @override
  void visitAllocateListLiteral(AllocateListLiteral instr) =>
      throw 'Unexpected AllocateListLiteral (should be lowered)';

  @override
  void visitAllocateMapLiteral(AllocateMapLiteral instr) =>
      throw 'Unexpected AllocateMapLiteral (should be lowered)';

  @override
  void visitStringInterpolation(StringInterpolation instr) =>
      throw 'Unexpected StringInterpolation (should be lowered)';
}
