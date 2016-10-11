// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../compiler.dart';
import '../elements/elements.dart';
import '../js_backend/js_backend.dart';
import '../resolution/tree_elements.dart';
import '../types/types.dart';
import 'jump_handler.dart';
import 'locals_handler.dart';
import 'nodes.dart';

/// Base class for objects that build up an SSA graph.
///
/// This contains helpers for building the graph and tracking information about
/// the current state of the graph being built.
abstract class GraphBuilder {
  /// Holds the resulting SSA graph.
  final HGraph graph = new HGraph();

  // TODO(het): remove this
  /// A reference to the compiler.
  Compiler compiler;

  /// The JavaScript backend we are targeting in this compilation.
  JavaScriptBackend get backend;

  /// The tree elements for the element being built into an SSA graph.
  TreeElements get elements;

  /// Used to track the locals while building the graph.
  LocalsHandler localsHandler;

  /// A stack of instructions.
  ///
  /// We build the SSA graph by simulating a stack machine.
  List<HInstruction> stack = <HInstruction>[];

  /// The count of nested loops we are currently building.
  ///
  /// The loop nesting is consulted when inlining a function invocation. The
  /// inlining heuristics take this information into account.
  int loopDepth = 0;

  /// A mapping from jump targets to their handlers.
  Map<JumpTarget, JumpHandler> jumpTargets = <JumpTarget, JumpHandler>{};

  void push(HInstruction instruction) {
    add(instruction);
    stack.add(instruction);
  }

  HInstruction pop() {
    return stack.removeLast();
  }

  /// Pops the most recent instruction from the stack and 'boolifies' it.
  ///
  /// Boolification is checking if the value is '=== true'.
  HInstruction popBoolified();

  /// Pushes a boolean checking [expression] against null.
  pushCheckNull(HInstruction expression) {
    push(new HIdentity(
        expression, graph.addConstantNull(compiler), null, backend.boolType));
  }

  void dup() {
    stack.add(stack.last);
  }

  HBasicBlock _current;

  /// The current block to add instructions to. Might be null, if we are
  /// visiting dead code, but see [isReachable].
  HBasicBlock get current => _current;

  void set current(c) {
    isReachable = c != null;
    _current = c;
  }

  /// The most recently opened block. Has the same value as [current] while
  /// the block is open, but unlike [current], it isn't cleared when the
  /// current block is closed.
  HBasicBlock lastOpenedBlock;

  /// Indicates whether the current block is dead (because it has a throw or a
  /// return further up). If this is false, then [current] may be null. If the
  /// block is dead then it may also be aborted, but for simplicity we only
  /// abort on statement boundaries, not in the middle of expressions. See
  /// [isAborted].
  bool isReachable = true;

  HParameterValue lastAddedParameter;

  Map<ParameterElement, HInstruction> parameters =
      <ParameterElement, HInstruction>{};

  HBasicBlock addNewBlock() {
    HBasicBlock block = graph.addNewBlock();
    // If adding a new block during building of an expression, it is due to
    // conditional expressions or short-circuit logical operators.
    return block;
  }

  void open(HBasicBlock block) {
    block.open();
    current = block;
    lastOpenedBlock = block;
  }

  HBasicBlock close(HControlFlow end) {
    HBasicBlock result = current;
    current.close(end);
    current = null;
    return result;
  }

  HBasicBlock closeAndGotoExit(HControlFlow end) {
    HBasicBlock result = current;
    current.close(end);
    current = null;
    result.addSuccessor(graph.exit);
    return result;
  }

  void goto(HBasicBlock from, HBasicBlock to) {
    from.close(new HGoto());
    from.addSuccessor(to);
  }

  bool isAborted() {
    return current == null;
  }

  /// Creates a new block, transitions to it from any current block, and
  /// opens the new block.
  HBasicBlock openNewBlock() {
    HBasicBlock newBlock = addNewBlock();
    if (!isAborted()) goto(current, newBlock);
    open(newBlock);
    return newBlock;
  }

  void add(HInstruction instruction) {
    current.add(instruction);
  }

  HParameterValue addParameter(Entity parameter, TypeMask type) {
    HParameterValue result = new HParameterValue(parameter, type);
    if (lastAddedParameter == null) {
      graph.entry.addBefore(graph.entry.first, result);
    } else {
      graph.entry.addAfter(lastAddedParameter, result);
    }
    lastAddedParameter = result;
    return result;
  }

  HSubGraphBlockInformation wrapStatementGraph(SubGraph statements) {
    if (statements == null) return null;
    return new HSubGraphBlockInformation(statements);
  }

  HSubExpressionBlockInformation wrapExpressionGraph(SubExpression expression) {
    if (expression == null) return null;
    return new HSubExpressionBlockInformation(expression);
  }
}
