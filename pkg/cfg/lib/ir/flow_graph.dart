// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/dominators.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/local_variable.dart';
import 'package:cfg/ir/loops.dart';
import 'package:cfg/ir/use_lists.dart';
import 'package:cfg/utils/arena.dart';

/// Control-flow graph of instructions implementing a single function.
///
/// [FlowGraph] is also an arena to allocate use lists.
class FlowGraph extends Uint32Arena {
  final CFunction function;

  /// Local variables used in this graph.
  /// The first [function.numberOfParameters] variables represent function parameters.
  final List<LocalVariable> localVariables = [];

  /// All instructions used in this graph.
  /// [Instruction.id] is an index in this list.
  final List<Instruction> instructions = [];

  /// Empty array of uses. Used by all instructions with 0 inputs.
  late final UsesArray emptyUsesArray = UsesArray.allocate(this, 0);

  /// Mapping between constant values and corresponding [Constant]
  /// instructions in the graph.
  final Map<ConstantValue, Constant> _constants = {};

  /// New [Constant] instructions are inserted after this instruction.
  late Instruction _constantInsertionPoint;

  /// Entry basic block in this control-flow graph.
  late final EntryBlock entryBlock;

  /// Basic block preorder.
  final List<Block> preorder = [];

  /// Basic block postorder.
  final List<Block> postorder = [];

  /// Basic block reverse postorder.
  Iterable<Block> get reversePostorder => postorder.reversed;

  /// Computed dominators.
  Dominators? _dominators;

  /// Computed loops.
  Loops? _loops;

  /// Whether this graph was converted to SSA form.
  bool inSSAForm = false;

  /// Create a new control-flow graph for the given [function].
  FlowGraph(this.function) {
    entryBlock = EntryBlock(this, function.sourcePosition);
    _constantInsertionPoint = entryBlock;
  }

  /// Return a [Constant] instruction with given [value], adding it to
  /// the graph if necessary.
  Constant getConstant(ConstantValue value) =>
      _constants[value] ??= _createConstant(value);

  Constant _createConstant(ConstantValue value) {
    final instr = Constant(this, value);
    final insertionPoint = _constantInsertionPoint;
    if (insertionPoint.next != null) {
      instr.insertAfter(insertionPoint);
    } else {
      insertionPoint.appendInstruction(instr);
    }
    _constantInsertionPoint = instr;
    return instr;
  }

  /// Remove given [Constant] instruction from the graph.
  /// The instruction should be unused.
  void removeConstant(Constant instr) {
    assert(!instr.hasUses);
    _constants.remove(instr.value);
    if (instr == _constantInsertionPoint) {
      _constantInsertionPoint = instr.previous!;
    }
  }

  /// Populate [preorder], [postorder], [Block.predecessors],
  /// [Block.preorderNumber] and [Block.postorderNumber].
  void discoverBlocks() {
    preorder.clear();
    postorder.clear();

    final stack = <(Block, int)>[];
    _discoverBlock(null, entryBlock);
    stack.add((entryBlock, entryBlock.successors.length - 1));
    while (stack.isNotEmpty) {
      final (block, successorIndex) = stack.removeLast();
      if (successorIndex >= 0) {
        stack.add((block, successorIndex - 1));
        final successor = block.successors[successorIndex];
        if (_discoverBlock(block, successor)) {
          stack.add((successor, successor.successors.length - 1));
        }
      } else {
        // All successors have been processed.
        block.postorderNumber = postorder.length;
        postorder.add(block);
      }
    }
    assert(postorder.length == preorder.length);

    invalidateDominators();
    invalidateLoops();
  }

  /// Detect that a block has been visited as part of the current
  /// [discoverBlocks] ([discoverBlocks] can be called multiple times).
  /// The block will be 'marked' by (1) having a preorder number in the range of the
  /// [preorder] and (2) being in the preorder list at that index.
  bool _isVisited(Block block) {
    final preorderNumber = block.preorderNumber;
    return preorderNumber >= 0 &&
        preorderNumber < preorder.length &&
        preorder[preorderNumber] == block;
  }

  /// Visit control-flow edge between [predecessor] and [block].
  ///
  /// Must be called on all graph blocks in preorder.
  /// Sets [Block.preorderNumber], populates [Block.predecessors] and
  /// [FlowGraph.preorder].
  /// Returns true when called the first time on this particular block
  /// within one graph traversal, and false on all successive calls.
  bool _discoverBlock(Block? predecessor, Block block) {
    // If this block has a predecessor (i.e., is not the graph entry) we can
    // assume the preorder array is non-empty.
    assert(predecessor == null || preorder.isNotEmpty);
    // Blocks with a single predecessor cannot have been reached before.
    assert(block is JoinBlock || !_isVisited(block));

    // If the block has already been reached, add current block as a
    // basic-block predecessor and we are done.
    if (_isVisited(block)) {
      block.predecessors.add(predecessor!);
      return false;
    }

    // Otherwise, clear the predecessors which might have been computed on
    // some earlier call to DiscoverBlocks and record this predecessor.
    block.predecessors.clear();
    if (predecessor != null) block.predecessors.add(predecessor);

    // Assign the preorder number and add the block to the list.
    block.preorderNumber = preorder.length;
    preorder.add(block);

    return true;
  }

  /// Returns dominators for this graph, computing them if necessary.
  Dominators get dominators => _dominators ??= computeDominators(this);

  /// Invalidate all information about dominators.
  /// Dominators will be recalculated once again when needed.
  ///
  /// Should be called when blocks have changed.
  void invalidateDominators() {
    _dominators = null;
  }

  /// Invalidate numbering of instructions which is
  /// used to implement [Instruction.isDominatedBy].
  /// Numbering of instructions will be recalculated once again when needed.
  ///
  /// Should be called when instructions were added or moved.
  void invalidateInstructionNumbering() {
    _dominators?.invalidateInstructionNumbering();
  }

  /// Returns loops for this graph, computing them if necessary.
  Loops get loops => _loops ??= computeLoops(this);

  /// Invalidate all information about loops.
  /// Loops will be recalculated once again when needed.
  ///
  /// Should be called when blocks have changed.
  void invalidateLoops() {
    _loops = null;
  }
}
