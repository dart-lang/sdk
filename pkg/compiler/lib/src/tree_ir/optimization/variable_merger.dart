// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tree_ir.optimization.variable_merger;

import 'optimization.dart' show Pass;
import '../tree_ir_nodes.dart';

/// Merges variables based on liveness and source variable information.
///
/// This phase cleans up artifacts introduced by the translation through CPS,
/// where each source variable is translated into several copies. The copies
/// are merged again when they are not live simultaneously.
class VariableMerger implements Pass {
  String get passName => 'Variable merger';

  final bool minifying;

  VariableMerger({this.minifying: false});

  void rewrite(FunctionDefinition node) {
    BlockGraphBuilder builder = new BlockGraphBuilder()..build(node);
    _computeLiveness(builder.blocks);
    PriorityPairs priority = new PriorityPairs()..build(node);
    Map<Variable, Variable> subst = _computeRegisterAllocation(
        builder.blocks, node.parameters, priority,
        minifying: minifying);
    new SubstituteVariables(subst).apply(node);
  }
}

/// A read or write access to a variable.
class VariableAccess {
  Variable variable;
  bool isRead;
  bool get isWrite => !isRead;

  VariableAccess.read(this.variable) : isRead = true;
  VariableAccess.write(this.variable) : isRead = false;
}

/// Basic block in a control-flow graph.
class Block {
  /// List of predecessors in the control-flow graph.
  final List<Block> predecessors = <Block>[];

  /// Entry to the catch block for the enclosing try, or `null`.
  final Block catchBlock;

  /// List of nodes with this block as [catchBlock].
  final List<Block> catchPredecessors = <Block>[];

  /// Sequence of read and write accesses in the block.
  final List<VariableAccess> accesses = <VariableAccess>[];

  /// Auxiliary fields used by the liveness analysis.
  bool inWorklist = true;
  Set<Variable> liveIn;
  Set<Variable> liveOut = new Set<Variable>();
  Set<Variable> gen = new Set<Variable>();
  Set<Variable> kill = new Set<Variable>();

  /// Adds a read operation to the block and updates gen/kill sets accordingly.
  void addRead(Variable variable) {
    // Operations are seen in forward order.
    // If the read is not preceded by a write, then add it to the GEN set.
    if (!kill.contains(variable)) {
      gen.add(variable);
    }
    accesses.add(new VariableAccess.read(variable));
  }

  /// Adds a write operation to the block and updates gen/kill sets accordingly.
  void addWrite(Variable variable) {
    // If the write is not preceded by a read, then add it to the KILL set.
    if (!gen.contains(variable)) {
      kill.add(variable);
    }
    accesses.add(new VariableAccess.write(variable));
  }

  Block(this.catchBlock) {
    if (catchBlock != null) {
      catchBlock.catchPredecessors.add(this);
    }
  }
}

/// Builds a control-flow graph suitable for performing liveness analysis.
class BlockGraphBuilder extends RecursiveVisitor {
  Map<Label, Block> _jumpTarget = <Label, Block>{};
  Block _currentBlock;
  List<Block> blocks = <Block>[];

  /// Variables with an assignment that should be treated as final.
  ///
  /// Such variables cannot be merged with any other variables, so we exclude
  /// them from the control-flow graph entirely.
  Set<Variable> _ignoredVariables = new Set<Variable>();

  void build(FunctionDefinition node) {
    _currentBlock = newBlock();
    node.parameters.forEach(write);
    visitStatement(node.body);
  }

  /// Creates a new block with the current exception handler or [catchBlock]
  /// if provided.
  Block newBlock({Block catchBlock}) {
    if (catchBlock == null && _currentBlock != null) {
      catchBlock = _currentBlock.catchBlock;
    }
    Block block = new Block(catchBlock);
    blocks.add(block);
    return block;
  }

  /// Starts a new block after the end of [block].
  void branchFrom(Block block, {Block catchBlock}) {
    _currentBlock = newBlock(catchBlock: catchBlock)..predecessors.add(block);
  }

  /// Starts a new block with the given blocks as predecessors.
  void joinFrom(Block block1, Block block2) {
    assert(block1.catchBlock == block2.catchBlock);
    _currentBlock = newBlock(catchBlock: block1.catchBlock);
    _currentBlock.predecessors.add(block1);
    _currentBlock.predecessors.add(block2);
  }

  /// Called when reading from [variable].
  ///
  /// Appends a read operation to the current basic block.
  void read(Variable variable) {
    if (variable.isCaptured) return;
    if (_ignoredVariables.contains(variable)) return;
    _currentBlock.addRead(variable);
  }

  /// Called when writing to [variable].
  ///
  /// Appends a write operation to the current basic block.
  void write(Variable variable) {
    if (variable.isCaptured) return;
    if (_ignoredVariables.contains(variable)) return;
    _currentBlock.addWrite(variable);
  }

  /// Called to indicate that [variable] should not be merged, and therefore
  /// be excluded from the control-flow graph.
  /// Subsequent calls to [read] and [write] will ignore it.
  void ignoreVariable(Variable variable) {
    _ignoredVariables.add(variable);
  }

  visitVariableUse(VariableUse node) {
    read(node.variable);
  }

  visitAssign(Assign node) {
    visitExpression(node.value);
    write(node.variable);
  }

  visitIf(If node) {
    visitExpression(node.condition);
    Block afterCondition = _currentBlock;
    branchFrom(afterCondition);
    visitStatement(node.thenStatement);
    Block afterThen = _currentBlock;
    branchFrom(afterCondition);
    visitStatement(node.elseStatement);
    joinFrom(_currentBlock, afterThen);
  }

  visitLabeledStatement(LabeledStatement node) {
    Block join = _jumpTarget[node.label] = newBlock();
    visitStatement(node.body); // visitBreak will add predecessors to join.
    _currentBlock = join;
    visitStatement(node.next);
  }

  visitBreak(Break node) {
    _jumpTarget[node.target].predecessors.add(_currentBlock);
  }

  visitContinue(Continue node) {
    _jumpTarget[node.target].predecessors.add(_currentBlock);
  }

  visitWhileTrue(WhileTrue node) {
    Block join = _jumpTarget[node.label] = newBlock();
    join.predecessors.add(_currentBlock);
    _currentBlock = join;
    visitStatement(node.body); // visitContinue will add predecessors to join.
  }

  visitFor(For node) {
    Block entry = _currentBlock;
    _currentBlock = _jumpTarget[node.label] = newBlock();
    node.updates.forEach(visitExpression);
    joinFrom(entry, _currentBlock);
    visitExpression(node.condition);
    Block afterCondition = _currentBlock;
    branchFrom(afterCondition);
    visitStatement(node.body); // visitContinue will add predecessors to join.
    branchFrom(afterCondition);
    visitStatement(node.next);
  }

  visitTry(Try node) {
    Block outerCatchBlock = _currentBlock.catchBlock;
    Block catchBlock = newBlock(catchBlock: outerCatchBlock);
    branchFrom(_currentBlock, catchBlock: catchBlock);
    visitStatement(node.tryBody);
    Block afterTry = _currentBlock;
    _currentBlock = catchBlock;
    // Catch parameters cannot be hoisted to the top of the function, so to
    // avoid complications with scoping, we do not attempt to merge them.
    node.catchParameters.forEach(ignoreVariable);
    visitStatement(node.catchBody);
    Block afterCatch = _currentBlock;
    _currentBlock = newBlock(catchBlock: outerCatchBlock);
    _currentBlock.predecessors.add(afterCatch);
    _currentBlock.predecessors.add(afterTry);
  }

  visitConditional(Conditional node) {
    visitExpression(node.condition);
    Block afterCondition = _currentBlock;
    branchFrom(afterCondition);
    visitExpression(node.thenExpression);
    Block afterThen = _currentBlock;
    branchFrom(afterCondition);
    visitExpression(node.elseExpression);
    joinFrom(_currentBlock, afterThen);
  }

  visitLogicalOperator(LogicalOperator node) {
    visitExpression(node.left);
    Block afterLeft = _currentBlock;
    branchFrom(afterLeft);
    visitExpression(node.right);
    joinFrom(_currentBlock, afterLeft);
  }
}

/// Collects prioritized variable pairs -- pairs that lead to significant code
/// reduction if merged into one variable.
///
/// These arise from moving assigments `v1 = v2`, and compoundable assignments
/// `v1 = v2 [+] E` where [+] is a compoundable operator.
//
// TODO(asgerf): We could have a more fine-grained priority level. All pairs
//   are treated as equally important, but some pairs can eliminate more than
//   one assignment.
//   Also, some assignments are more important to remove than others, as they
//   can block a later optimization, such rewriting a loop, or removing the
//   'else' part of an 'if'.
//
class PriorityPairs extends RecursiveVisitor {
  final Map<Variable, List<Variable>> _priority = <Variable, List<Variable>>{};

  void build(FunctionDefinition node) {
    visitStatement(node.body);
  }

  void _prioritize(Variable x, Variable y) {
    _priority.putIfAbsent(x, () => new List<Variable>()).add(y);
    _priority.putIfAbsent(y, () => new List<Variable>()).add(x);
  }

  visitAssign(Assign node) {
    super.visitAssign(node);
    Expression value = node.value;
    if (value is VariableUse) {
      _prioritize(node.variable, value.variable);
    } else if (value is ApplyBuiltinOperator &&
        isCompoundableOperator(value.operator) &&
        value.arguments[0] is VariableUse) {
      VariableUse use = value.arguments[0];
      _prioritize(node.variable, use.variable);
    }
  }

  /// Returns the other half of every priority pair containing [variable].
  List<Variable> getPriorityPairsWith(Variable variable) {
    return _priority[variable] ?? const <Variable>[];
  }

  bool hasPriorityPairs(Variable variable) {
    return _priority.containsKey(variable);
  }
}

/// Computes liveness information of the given control-flow graph.
///
/// The results are stored in [Block.liveIn] and [Block.liveOut].
void _computeLiveness(List<Block> blocks) {
  // We use a LIFO queue as worklist. Blocks are given in AST order, so by
  // inserting them in this order, we initially visit them backwards, which
  // is a good ordering.
  // The choice of LIFO for re-inserted blocks is currently arbitrary,
  List<Block> worklist = new List<Block>.from(blocks);
  while (!worklist.isEmpty) {
    Block block = worklist.removeLast();
    block.inWorklist = false;

    bool changed = false;

    // The liveIn set is computed as:
    //
    //    liveIn = (liveOut - kill) + gen
    //
    // We do the computation in two steps:
    //
    //    1. liveIn = gen
    //    2. liveIn += (liveOut - kill)
    //
    // However, since liveIn only grows, and gen never changes, we only have
    // to do the first step at the first iteration. Moreover, the gen set is
    // not needed anywhere else, so we don't even need to copy it.
    if (block.liveIn == null) {
      block.liveIn = block.gen;
      block.gen = null;
      changed = true;
    }

    // liveIn += (liveOut - kill)
    for (Variable variable in block.liveOut) {
      if (!block.kill.contains(variable)) {
        if (block.liveIn.add(variable)) {
          changed = true;
        }
      }
    }

    // If anything changed, propagate liveness backwards.
    if (changed) {
      // Propagate live variables to predecessors.
      for (Block predecessor in block.predecessors) {
        int lengthBeforeChange = predecessor.liveOut.length;
        predecessor.liveOut.addAll(block.liveIn);
        if (!predecessor.inWorklist &&
            predecessor.liveOut.length != lengthBeforeChange) {
          worklist.add(predecessor);
          predecessor.inWorklist = true;
        }
      }

      // Propagate live variables to catch predecessors.
      for (Block pred in block.catchPredecessors) {
        bool changed = false;
        int lengthBeforeChange = pred.liveOut.length;
        pred.liveOut.addAll(block.liveIn);
        if (pred.liveOut.length != lengthBeforeChange) {
          changed = true;
        }
        // Assigning to a variable that is live in the catch block, does not
        // kill the variable, because we conservatively assume that an exception
        // could be thrown immediately before the assignment.
        // Therefore remove live variables from all kill sets inside the try.
        // Since the kill set is only used to subtract live variables from a
        // set, the analysis remains monotone.
        lengthBeforeChange = pred.kill.length;
        pred.kill.removeAll(block.liveIn);
        if (pred.kill.length != lengthBeforeChange) {
          changed = true;
        }
        if (changed && !pred.inWorklist) {
          worklist.add(pred);
          pred.inWorklist = true;
        }
      }
    }
  }
}

/// Based on liveness information, computes a map of variable substitutions to
/// merge variables.
///
/// Constructs a register interference graph. This is an undirected graph of
/// variables, with an edge between two variables if they cannot be merged
/// (because they are live simultaneously).
///
/// We then compute a graph coloring, where the color of a node denotes which
/// variable it will be substituted by.
Map<Variable, Variable> _computeRegisterAllocation(
    List<Block> blocks, List<Variable> parameters, PriorityPairs priority,
    {bool minifying}) {
  Map<Variable, Set<Variable>> interference = <Variable, Set<Variable>>{};

  bool allowUnmotivatedMerge(Variable x, Variable y) {
    if (minifying) return true;
    // Do not allow merging temporaries with named variables if they are
    // not connected by a phi.  That would leads to confusing mergings like:
    //    var v0 = receiver.length;
    //        ==>
    //    receiver = receiver.length;
    return x.element?.name == y.element?.name;
  }

  bool allowPhiMerge(Variable x, Variable y) {
    if (minifying) return true;
    // Temporaries may be merged with a named variable if this eliminates a phi.
    // The presence of the phi implies that the two variables can contain the
    // same value, so it is not that confusing that they get the same name.
    return x.element == null ||
        y.element == null ||
        x.element.name == y.element.name;
  }

  Set<Variable> empty = new Set<Variable>();

  // At the assignment to a variable x, add an edge to every variable that is
  // live after the assignment (if it came from the same source variable).
  for (Block block in blocks) {
    // Track the live set while traversing the block.
    Set<Variable> live = new Set<Variable>();
    for (Variable variable in block.liveOut) {
      live.add(variable);
      interference.putIfAbsent(variable, () => new Set<Variable>());
    }
    // Get variables that are live at the catch block.
    Set<Variable> liveCatch =
        block.catchBlock != null ? block.catchBlock.liveIn : empty;
    // Add edges for each variable being assigned here.
    for (VariableAccess access in block.accesses.reversed) {
      Variable variable = access.variable;
      interference.putIfAbsent(variable, () => new Set<Variable>());
      if (access.isRead) {
        live.add(variable);
      } else {
        if (!liveCatch.contains(variable)) {
          // Assignment to a variable that is not live in the catch block.
          live.remove(variable);
        }
        for (Variable other in live) {
          interference[variable].add(other);
          interference[other].add(variable);
        }
      }
    }
  }

  // Sort the variables by descending degree.
  // The most constrained variables will be assigned a color first.
  List<Variable> variables = interference.keys.toList();
  variables.sort((x, y) => interference[y].length - interference[x].length);

  List<Variable> registers = <Variable>[];
  Map<Variable, Variable> subst = <Variable, Variable>{};

  /// Called when [variable] has been assigned [target] as its register/color.
  /// Will immediately try to satisfy its priority pairs by assigning the same
  /// color the other half of each pair.
  void searchPriorityPairs(Variable variable, Variable target) {
    if (!priority.hasPriorityPairs(variable)) {
      return; // Most variables (around 90%) do not have priority pairs.
    }
    List<Variable> worklist = <Variable>[variable];
    while (worklist.isNotEmpty) {
      Variable v1 = worklist.removeLast();
      for (Variable v2 in priority.getPriorityPairsWith(v1)) {
        // If v2 already has a color, we cannot change it.
        if (subst.containsKey(v2)) continue;

        // Do not merge differently named variables.
        if (!allowPhiMerge(v1, v2)) continue;

        // Ensure the graph coloring remains valid. If a neighbour of v2 already
        // has the desired color, we cannot assign the same color to v2.
        if (interference[v2].any((v3) => subst[v3] == target)) continue;

        subst[v2] = target;
        target.element ??= v2.element; // Preserve the name.
        worklist.add(v2);
      }
    }
  }

  void assignRegister(Variable variable, Variable registerRepresentative) {
    subst[variable] = registerRepresentative;
    // Ensure this register is never assigned to a variable with another name.
    // This also ensures that named variables keep their name when merged
    // with a temporary.
    registerRepresentative.element ??= variable.element;
    searchPriorityPairs(variable, registerRepresentative);
  }

  void assignNewRegister(Variable variable) {
    registers.add(variable);
    subst[variable] = variable;
    searchPriorityPairs(variable, variable);
  }

  // Parameters cannot be merged with each other. Ensure that they are not
  // substituted.  Other variables can still be substituted by a parameter.
  for (Variable parameter in parameters) {
    if (parameter.isCaptured) continue;
    registers.add(parameter);
    subst[parameter] = parameter;
  }

  // Try to merge parameters with locals to eliminate phis.
  for (Variable parameter in parameters) {
    searchPriorityPairs(parameter, parameter);
  }

  v1loop: for (Variable v1 in variables) {
    // Ignore if the variable has already been assigned a register.
    if (subst.containsKey(v1)) continue;

    // Optimization: If there are no interference edges for this variable,
    // find a color for it without copying the register list.
    Set<Variable> interferenceSet = interference[v1];
    if (interferenceSet.isEmpty) {
      // Use the first register where naming constraints allow the merge.
      for (Variable v2 in registers) {
        if (allowUnmotivatedMerge(v1, v2)) {
          assignRegister(v1, v2);
          continue v1loop;
        }
      }
      // No register allows merging with this one, create a new register.
      assignNewRegister(v1);
      continue;
    }

    // Find an unused color.
    Set<Variable> potential = new Set<Variable>.from(
        registers.where((v2) => allowUnmotivatedMerge(v1, v2)));
    for (Variable v2 in interferenceSet) {
      Variable v2subst = subst[v2];
      if (v2subst != null) {
        potential.remove(v2subst);
        if (potential.isEmpty) break;
      }
    }

    if (potential.isEmpty) {
      // If no free color was found, add this variable as a new color.
      assignNewRegister(v1);
    } else {
      assignRegister(v1, potential.first);
    }
  }

  return subst;
}

/// Performs variable substitution and removes redundant assignments.
class SubstituteVariables extends RecursiveTransformer {
  Map<Variable, Variable> mapping;

  SubstituteVariables(this.mapping);

  Variable replaceRead(Variable variable) {
    Variable w = mapping[variable];
    if (w == null) return variable; // Skip ignored variables.
    w.readCount++;
    variable.readCount--;
    return w;
  }

  Variable replaceWrite(Variable variable) {
    Variable w = mapping[variable];
    if (w == null) return variable; // Skip ignored variables.
    w.writeCount++;
    variable.writeCount--;
    return w;
  }

  void apply(FunctionDefinition node) {
    for (int i = 0; i < node.parameters.length; ++i) {
      node.parameters[i] = replaceWrite(node.parameters[i]);
    }
    node.body = visitStatement(node.body);
  }

  Expression visitVariableUse(VariableUse node) {
    node.variable = replaceRead(node.variable);
    return node;
  }

  Expression visitAssign(Assign node) {
    node.variable = replaceWrite(node.variable);
    node.value = visitExpression(node.value);

    // Remove assignments of form "x := x"
    if (node.value is VariableUse) {
      VariableUse value = node.value;
      if (value.variable == node.variable) {
        --node.variable.writeCount;
        return value;
      }
    }

    return node;
  }

  Statement visitExpressionStatement(ExpressionStatement node) {
    node.expression = visitExpression(node.expression);
    node.next = visitStatement(node.next);
    if (node.expression is VariableUse) {
      VariableUse use = node.expression;
      --use.variable.readCount;
      return node.next;
    }
    return node;
  }
}
