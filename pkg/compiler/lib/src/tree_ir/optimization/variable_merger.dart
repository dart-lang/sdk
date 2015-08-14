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
class VariableMerger extends RecursiveVisitor implements Pass {
  String get passName => 'Variable merger';

  void rewrite(FunctionDefinition node) {
    rewriteFunction(node);
    visitStatement(node.body);
  }

  @override
  void visitInnerFunction(FunctionDefinition node) {
    rewriteFunction(node);
  }

  /// Rewrites the given function.
  /// This is called for the outermost function and inner functions.
  void rewriteFunction(FunctionDefinition node) {
    BlockGraphBuilder builder = new BlockGraphBuilder();
    builder.build(node);
    _computeLiveness(builder.blocks);
    Map<Variable, Variable> subst =
        _computeRegisterAllocation(builder.blocks, node.parameters);
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

  @override
  void visitInnerFunction(FunctionDefinition node) {
    // Do nothing. Inner functions are traversed in VariableMerger.
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

/// For testing purposes, this flag can be passed to merge variables that
/// originated from different source variables.
///
/// Correctness should not depend on the fact that we only merge variables
/// originating from the same source variable. Setting this flag makes a bug
/// more likely to provoke a test case failure.
const bool NO_PRESERVE_VARS = const bool.fromEnvironment('NO_PRESERVE_VARS');

/// Based on liveness information, computes a map of variable substitutions to
/// merge variables.
///
/// Constructs a register interference graph. This is an undirected graph of
/// variables, with an edge between two variables if they cannot be merged
/// (because they are live simultaneously).
///
/// We then compute a graph coloring, where the color of a node denotes which
/// variable it will be substituted by.
///
/// We never merge variables that originated from distinct source variables,
/// so we build a separate register interference graph for each source variable.
Map<Variable, Variable> _computeRegisterAllocation(List<Block> blocks,
                                                   List<Variable> parameters) {
  Map<Variable, Set<Variable>> interference = <Variable, Set<Variable>>{};

  /// Group for the given variable. We attempt to merge variables in the same
  /// group.
  /// By default, variables are grouped based on their source variable name,
  /// but this can be disabled for testing purposes.
  String group(Variable variable) {
    if (NO_PRESERVE_VARS) return '';
    // Group variables based on the source variable's name, not its element,
    // so if multiple locals are declared with the same name, they will
    // map to the same (hoisted) variable in the output.
    return variable.element == null ? '' : variable.element.name;
  }

  Set<Variable> empty = new Set<Variable>();

  // At the assignment to a variable x, add an edge to every variable that is
  // live after the assignment (if it came from the same source variable).
  for (Block block in blocks) {
    // Group the liveOut set by source variable.
    Map<String, Set<Variable>> liveOut = <String, Set<Variable>>{};
    for (Variable variable in block.liveOut) {
      liveOut.putIfAbsent(
          group(variable),
          () => new Set<Variable>()).add(variable);
      interference.putIfAbsent(variable, () => new Set<Variable>());
    }
    // Get variables that are live at the catch block.
    Set<Variable> liveCatch = block.catchBlock != null
        ? block.catchBlock.liveIn
        : empty;
    // Add edges for each variable being assigned here.
    for (VariableAccess access in block.accesses.reversed) {
      Variable variable = access.variable;
      interference.putIfAbsent(variable, () => new Set<Variable>());
      Set<Variable> live =
          liveOut.putIfAbsent(group(variable), () => new Set<Variable>());
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

  Map<String, List<Variable>> registers = <String, List<Variable>>{};
  Map<Variable, Variable> subst = <Variable, Variable>{};

  // Parameters are special in that they must have a ParameterElement and
  // cannot be merged with each other. Ensure that they are not substituted.
  // Other variables can still be substituted by a parameter.
  for (Variable parameter in parameters) {
    if (parameter.isCaptured) continue;
    subst[parameter] = parameter;
    registers[group(parameter)] = <Variable>[parameter];
  }

  for (Variable v1 in variables) {
    // Parameters have already been assigned a substitute; skip those.
    if (subst.containsKey(v1)) continue;

    List<Variable> register = registers[group(v1)];

    // Optimization: For the first variable in a group, allocate a new color
    // without iterating over its interference edges.
    if (register == null) {
      registers[group(v1)] = <Variable>[v1];
      subst[v1] = v1;
      continue;
    }

    // Optimization: If there are no interference edges for this variable,
    // assign it the first color without copying the register list.
    Set<Variable> interferenceSet = interference[v1];
    if (interferenceSet.isEmpty) {
      subst[v1] = register[0];
      continue;
    }

    // Find an unused color.
    Set<Variable> potential = new Set<Variable>.from(register);
    for (Variable v2 in interferenceSet) {
      Variable v2subst = subst[v2];
      if (v2subst != null) {
        potential.remove(v2subst);
        if (potential.isEmpty) break;
      }
    }

    if (potential.isEmpty) {
      // If no free color was found, add this variable as a new color.
      register.add(v1);
      subst[v1] = v1;
    } else {
      subst[v1] = potential.first;
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

  @override
  void visitInnerFunction(FunctionDefinition node) {
    // Do nothing. Inner functions are traversed in VariableMerger.
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
