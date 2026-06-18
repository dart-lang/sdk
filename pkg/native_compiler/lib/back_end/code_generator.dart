// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/ir_to_text.dart';
import 'package:cfg/ir/visitor.dart';
import 'package:cfg/passes/pass.dart';
import 'package:cfg/utils/bit_vector.dart';
import 'package:native_compiler/back_end/assembler.dart';
import 'package:native_compiler/back_end/back_end_state.dart';
import 'package:native_compiler/back_end/code.dart';
import 'package:native_compiler/back_end/code_metadata.dart';
import 'package:native_compiler/back_end/locations.dart';
import 'package:native_compiler/back_end/stack_frame.dart';
import 'package:native_compiler/runtime/object_layout.dart';
import 'package:native_compiler/runtime/vm_defs.dart';

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

  /// Instruction being generated.
  Instruction? _currentInstruction;

  /// Maps block preorder number to a preorder number of
  /// the first non-empty block.
  late final Int32List _firstNonEmptyBlock = _computeFirstNonEmptyBlock();

  /// Maps preorder number of a block to
  /// a [Label] corresponding to the block entry.
  late final List<Label> _blockLabels = List<Label>.generate(
    graph.preorder.length,
    (i) => Label(),
  );

  /// Slow paths generated after all blocks.
  final List<SlowPath> _slowPaths = [];

  /// Metadata describing exception handlers in the generated code.
  late final ExceptionHandlers _exceptionHandlers;

  /// Metadata describing call sites in the generated code.
  late final PcDescriptors _pcDescriptors;

  /// Metadata describing moves between exception site and exception handler.
  CatchEntryMoves? _catchEntryMoves;

  /// Metadata describing source positions in the generated code.
  late final CodeSourceMap _codeSourceMap;

  CodeGenerator(this.backEndState) : super('CodeGen');

  VMOffsets get vmOffsets => backEndState.vmOffsets;
  ObjectLayout get objectLayout => backEndState.objectLayout;
  List<Block> get codeGenBlockOrder => backEndState.codeGenBlockOrder;
  StackFrame get stackFrame => backEndState.stackFrame;

  Location loc(OperandId operandId) =>
      backEndState.operandLocations[operandId]!.physicalLocation;
  Location inputLoc(Instruction instr, int inputIndex) =>
      loc(OperandId.input(instr.id, inputIndex));

  Register inputReg(Instruction instr, int inputIndex) =>
      inputLoc(instr, inputIndex) as Register;
  Register temporaryReg(Instruction instr, int tempIndex) =>
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

  void addCallSiteMetadata() {
    final exceptionHandler = _currentInstruction!.block!.exceptionHandler;
    final exceptionHandlerIndex = (exceptionHandler != null)
        ? _exceptionHandlers.getHandler(exceptionHandler).index
        : -1;
    _pcDescriptors.add(
      CallSite(
        _asm.currentPcOffset,
        exceptionHandlerIndex,
        _currentInstruction!.sourcePosition,
      ),
    );
    if (exceptionHandler != null) {
      (_catchEntryMoves ??= CatchEntryMoves()).add(
        ExceptionSite(
          _asm.currentPcOffset,
          // TODO: add moves
        ),
      );
    }
    _codeSourceMap.add(
      CodeSourcePosition(
        _asm.currentPcOffset,
        _currentInstruction!.sourcePosition,
      ),
    );
  }

  @override
  void run() {
    final blocks = codeGenBlockOrder;
    assert(blocks.first is EntryBlock);
    assert(blocks.length == graph.preorder.length);

    final asyncMarker = graph.function.asyncMarker;
    _exceptionHandlers = ExceptionHandlers(
      hasAsyncHandler: asyncMarker == .Async || asyncMarker == .AsyncStar,
    );
    _pcDescriptors = PcDescriptors();
    _codeSourceMap = CodeSourceMap();

    _asm = createAssembler();

    enterFrame();
    for (int i = 0, n = blocks.length; i < n; ++i) {
      _currentBlockIndex = i;
      final block = currentBlock = blocks[i];
      generateBlock(block);
    }
    _currentBlockIndex = -1;

    for (final slowPath in _slowPaths) {
      currentInstruction = _currentInstruction = slowPath.instruction;
      _asm.bind(slowPath.entry);
      slowPath.generator();
    }
    currentInstruction = _currentInstruction = null;

    backEndState.consumeGeneratedCode(
      Code(
        graph.function.toString(),
        graph.function,
        _asm.bytes,
        _asm.objectPool,
        _exceptionHandlers,
        _pcDescriptors,
        _catchEntryMoves,
        _codeSourceMap,
      ),
    );
  }

  Assembler createAssembler();

  void enterFrame();

  void generateBlock(Block block) {
    currentInstruction = _currentInstruction = block;
    _asm.bind(blockLabel(block));
    block.accept(this);
    for (final instr in block) {
      currentInstruction = _currentInstruction = instr;
      instr.accept(this);
    }
    currentInstruction = _currentInstruction = null;
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

  Label addSlowPath(void Function() generator) {
    final entry = Label();
    _slowPaths.add(SlowPath(_currentInstruction!, entry, generator));
    return entry;
  }

  @override
  void visitEntryBlock(EntryBlock instr) {}

  @override
  void visitJoinBlock(JoinBlock instr) {}

  @override
  void visitTargetBlock(TargetBlock instr) {}

  @override
  void visitCatchBlock(CatchBlock instr) {
    _exceptionHandlers.getHandler(instr).pcOffset = _asm.currentPcOffset;
  }

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

  /// Ensure that all destinations are distinct and
  /// stack locations are not used both as a source and destination.
  static bool _verifyParallelMoveDestinations(ParallelMove instr) {
    final destinations = <Location>{};
    for (final move in instr.moves) {
      final to = switch (move) {
        Move() => move.to.physicalLocation,
        LoadConstant() => move.to.physicalLocation,
        _ => throw 'Unexpected move ${move.runtimeType} $move',
      };
      if (!destinations.add(to)) {
        throw 'Non-unique destination location $to in ${IrToText.instruction(instr)}';
      }
    }
    for (final move in instr.moves) {
      if (move is Move) {
        final from = move.from.physicalLocation;
        final to = move.to.physicalLocation;
        if (from != to &&
            from is StackLocation &&
            destinations.contains(from)) {
          throw 'Stack location $from is used both as a source and destination in ${IrToText.instruction(instr)}';
        }
      }
    }
    return true;
  }

  @override
  void visitParallelMove(ParallelMove instr) {
    // TODO: merge subsequent ParallelMove instructions.
    assert(_verifyParallelMoveDestinations(instr));
    final moves = <Move>[];
    for (final move in instr.moves) {
      if (move is Move) {
        final from = move.from.physicalLocation;
        final to = move.to.physicalLocation;
        if (from != to) {
          if (from is StackLocation && to is StackLocation) {
            // Moves into spill slots cannot participate in cycles.
            // Generate them eagerly as they require a temporary register
            // which can be occupied while breaking a cycle.
            final temp = getMoveTempRegister(RegisterClass.cpu);
            generateMove(from, temp);
            generateMove(temp, to);
          } else {
            moves.add(Move(from, to));
          }
        }
      }
    }
    // The algorithm is described in Laurence Rideau, Bernard Paul Serpette, Xavier Leroy (2008)
    // "Tilting at windmills with Coq: formal verification of a compilation algorithm for parallel moves".
    final pending = BitVector(moves.length);
    final processed = BitVector(moves.length);
    for (var i = 0; i < moves.length; ++i) {
      if (!processed[i]) {
        _generateOneMove(i, moves, pending, processed);
      }
    }
    for (final move in instr.moves) {
      if (move is LoadConstant) {
        generateLoadConstant(move.value, move.to.physicalLocation);
      }
    }
  }

  void _generateOneMove(
    int i,
    List<Move> moves,
    BitVector pending,
    BitVector processed,
  ) {
    pending[i] = true;
    final dst = moves[i].to;
    for (var j = 0; j < moves.length; ++j) {
      if (processed[j]) {
        continue;
      }
      if (dst == moves[j].from) {
        if (pending[j]) {
          final temp = getMoveTempRegister(
            (moves[j].from is FPRegister || moves[j].to is FPRegister)
                ? RegisterClass.fpu
                : RegisterClass.cpu,
          );
          generateMove(moves[j].from, temp);
          moves[j].from = temp;
        } else {
          _generateOneMove(j, moves, pending, processed);
        }
      }
    }
    generateMove(moves[i].from, moves[i].to);
    processed[i] = true;
  }

  Location getMoveTempRegister(RegisterClass registerClass);
  void generateMove(Location from, Location to);
  void generateLoadConstant(ConstantValue value, Location to);

  @override
  void visitTypeParameters(TypeParameters instr) =>
      throw 'Unexpected TypeParameters (should be lowered)';

  @override
  void visitAllocateListLiteral(AllocateListLiteral instr) =>
      throw 'Unexpected AllocateListLiteral (should be lowered)';

  @override
  void visitAllocateMapLiteral(AllocateMapLiteral instr) =>
      throw 'Unexpected AllocateMapLiteral (should be lowered)';

  @override
  void visitAllocateRecordLiteral(AllocateRecordLiteral instr) =>
      throw 'Unexpected AllocateRecordLiteral (should be lowered)';

  @override
  void visitStringInterpolation(StringInterpolation instr) =>
      throw 'Unexpected StringInterpolation (should be lowered)';

  @override
  void visitInstantiateClosure(InstantiateClosure instr) =>
      throw 'Unexpected InstantiateClosure (should be lowered)';
}

class SlowPath(
  final Instruction instruction,
  final Label entry,
  final void Function() generator,
);
