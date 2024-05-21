// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'class_info.dart';
import 'closures.dart';
import 'code_generator.dart';
import 'state_machine.dart';

/// A specialized code generator for generating code for `sync*` functions.
///
/// This will create an "outer" function which is a small function that just
/// instantiates and returns a [_SyncStarIterable], plus an "inner" function
/// containing the body of the `sync*` function.
///
/// For the inner function, all statements containing any `yield` or `yield*`
/// statements will be translated to an explicit control flow graph implemented
/// via a switch (via the Wasm `br_table` instruction) in a loop. This enables
/// the function to suspend its execution at yield points and jump back to the
/// point of suspension when the execution is resumed.
///
/// Local state is preserved via the closure contexts, which will implicitly
/// capture all local variables in a `sync*` function even if they are not
/// captured by any lambdas.
class SyncStarCodeGenerator extends CodeGenerator {
  SyncStarCodeGenerator(super.translator, super.function, super.reference);

  /// Targets of the CFG, indexed by target index.
  late final List<StateTarget> targets;

  // Targets categorized by placement and indexed by node.
  final Map<TreeNode, StateTarget> innerTargets = {};
  final Map<TreeNode, StateTarget> afterTargets = {};

  /// The loop around the switch.
  late final w.Label masterLoop;

  /// The target labels of the switch, indexed by target index.
  late final List<w.Label> labels;

  /// The target index of the entry label for the current `sync*` CFG node.
  int currentTargetIndex = -1;

  // Locals containing special values.
  late final w.Local suspendStateLocal;
  late final w.Local pendingExceptionLocal;
  late final w.Local pendingStackTraceLocal;
  late final w.Local targetIndexLocal;

  late final ClassInfo suspendStateInfo =
      translator.classInfo[translator.suspendStateClass]!;
  late final ClassInfo syncStarIterableInfo =
      translator.classInfo[translator.syncStarIterableClass]!;
  late final ClassInfo syncStarIteratorInfo =
      translator.classInfo[translator.syncStarIteratorClass]!;

  @override
  void generate() {
    closures = Closures(translator, member);
    setupParametersAndContexts(member.reference);
    _generateBodies(member.function!);
  }

  @override
  w.BaseFunction generateLambda(Lambda lambda, Closures closures) {
    this.closures = closures;
    setupLambdaParametersAndContexts(lambda);
    _generateBodies(lambda.functionNode);
    return function;
  }

  void _generateBodies(FunctionNode functionNode) {
    // Number and categorize CFG targets.
    targets = YieldFinder(translator.options.enableAsserts).find(functionNode);
    for (final target in targets) {
      switch (target.placement) {
        case StateTargetPlacement.Inner:
          innerTargets[target.node] = target;
          break;
        case StateTargetPlacement.After:
          afterTargets[target.node] = target;
          break;
      }
    }

    // Wasm function containing the body of the `sync*` function.
    final resumeFun = m.functions.define(
        m.types.defineFunction([
          suspendStateInfo.nonNullableType,
          translator.topInfo.nullableType,
          translator.stackTraceInfo.repr.nullableType
        ], const [
          w.NumType.i32
        ]),
        "${function.functionName} inner");

    Context? context = closures.contexts[functionNode];
    if (context != null && context.isEmpty) context = context.parent;

    generateOuter(functionNode, context, resumeFun);

    // Forget about the outer function locals containing the type arguments,
    // so accesses to the type arguments in the inner function will fetch them
    // from the context.
    typeLocals.clear();

    generateInner(functionNode, context, resumeFun);
  }

  void generateOuter(
      FunctionNode functionNode, Context? context, w.BaseFunction resumeFun) {
    // Instantiate a [_SyncStarIterable] containing the context and resume
    // function for this `sync*` function.
    DartType elementType = functionNode.emittedValueType!;
    translator.functions.recordClassAllocation(syncStarIterableInfo.classId);
    b.i32_const(syncStarIterableInfo.classId);
    b.i32_const(initialIdentityHash);
    types.makeType(this, elementType);
    if (context != null) {
      assert(!context.isEmpty);
      b.local_get(context.currentLocal);
    } else {
      b.ref_null(w.HeapType.struct);
    }
    b.global_get(translator.makeFunctionRef(resumeFun));
    b.struct_new(syncStarIterableInfo.struct);
    b.end();
  }

  void generateInner(FunctionNode functionNode, Context? context,
      w.FunctionBuilder resumeFun) {
    // Set the current Wasm function for the code generator to the inner
    // function of the `sync*`, which is to contain the body.
    function = resumeFun;

    // Parameters passed from [_SyncStarIterator.moveNext].
    suspendStateLocal = function.locals[0];
    pendingExceptionLocal = function.locals[1];
    pendingStackTraceLocal = function.locals[2];

    // Set up locals for contexts and `this`.
    thisLocal = null;
    Context? localContext = context;
    while (localContext != null) {
      if (!localContext.isEmpty) {
        localContext.currentLocal = function
            .addLocal(w.RefType.def(localContext.struct, nullable: true));
        if (localContext.containsThis) {
          assert(thisLocal == null);
          thisLocal = function.addLocal(localContext
              .struct.fields[localContext.thisFieldIndex].type.unpacked
              .withNullability(false));
          translator.globals.instantiateDummyValue(b, thisLocal!.type);
          b.local_set(thisLocal!);

          preciseThisLocal = thisLocal;
        }
      }
      localContext = localContext.parent;
    }

    // Read target index from the suspend state.
    targetIndexLocal = addLocal(w.NumType.i32);
    b.local_get(suspendStateLocal);
    b.struct_get(suspendStateInfo.struct, FieldIndex.suspendStateTargetIndex);
    b.local_set(targetIndexLocal);

    // Switch on the target index.
    masterLoop = b.loop(const [], const [w.NumType.i32]);
    labels = List.generate(targets.length, (_) => b.block()).reversed.toList();
    w.Label defaultLabel = b.block();
    b.local_get(targetIndexLocal);
    b.br_table(labels, defaultLabel);
    b.end(); // defaultLabel
    b.unreachable();

    // Initial state, executed on first [moveNext] on the iterator.
    StateTarget initialTarget = targets.first;
    emitTargetLabel(initialTarget);

    // Clone context on first execution.
    b.restoreSuspendStateContext(suspendStateLocal, suspendStateInfo.struct,
        FieldIndex.suspendStateContext, closures, context, thisLocal,
        cloneContextFor: functionNode);

    visitStatement(functionNode.body!);

    // Final state: just keep returning.
    emitTargetLabel(targets.last);
    emitReturn();
    b.end(); // masterLoop

    b.end();
  }

  void emitTargetLabel(StateTarget target) {
    currentTargetIndex++;
    assert(target.index == currentTargetIndex);
    b.end();
  }

  void emitReturn() {
    // Set state target to final state.
    b.local_get(suspendStateLocal);
    b.i32_const(targets.last.index);
    b.struct_set(suspendStateInfo.struct, FieldIndex.suspendStateTargetIndex);

    // Return `false`.
    b.i32_const(0);
    b.return_();
  }

  void jumpToTarget(StateTarget target,
      {Expression? condition, bool negated = false}) {
    if (condition == null && negated) return;
    if (target.index > currentTargetIndex) {
      // Forward jump directly to the label.
      branchIf(condition, labels[target.index], negated: negated);
    } else {
      // Backward jump via the switch.
      w.Label block = b.block();
      branchIf(condition, block, negated: !negated);
      b.i32_const(target.index);
      b.local_set(targetIndexLocal);
      b.br(masterLoop);
      b.end(); // block
    }
  }

  @override
  void visitDoStatement(DoStatement node) {
    StateTarget? inner = innerTargets[node];
    if (inner == null) return super.visitDoStatement(node);

    emitTargetLabel(inner);
    allocateContext(node);
    visitStatement(node.body);
    jumpToTarget(inner, condition: node.condition);
  }

  @override
  void visitForStatement(ForStatement node) {
    StateTarget? inner = innerTargets[node];
    if (inner == null) return super.visitForStatement(node);
    StateTarget after = afterTargets[node]!;

    allocateContext(node);
    for (VariableDeclaration variable in node.variables) {
      visitStatement(variable);
    }
    emitTargetLabel(inner);
    jumpToTarget(after, condition: node.condition, negated: true);
    visitStatement(node.body);

    emitForStatementUpdate(node);

    jumpToTarget(inner);
    emitTargetLabel(after);
  }

  @override
  void visitIfStatement(IfStatement node) {
    StateTarget? after = afterTargets[node];
    if (after == null) return super.visitIfStatement(node);
    StateTarget? inner = innerTargets[node];

    jumpToTarget(inner ?? after, condition: node.condition, negated: true);
    visitStatement(node.then);
    if (node.otherwise != null) {
      jumpToTarget(after);
      emitTargetLabel(inner!);
      visitStatement(node.otherwise!);
    }
    emitTargetLabel(after);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    StateTarget? after = afterTargets[node];
    if (after == null) return super.visitLabeledStatement(node);

    visitStatement(node.body);
    emitTargetLabel(after);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    StateTarget? target = afterTargets[node.target];
    if (target == null) return super.visitBreakStatement(node);

    jumpToTarget(target);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    StateTarget? after = afterTargets[node];
    if (after == null) return super.visitSwitchStatement(node);

    // TODO(51342): Implement this.
    unimplemented(node, "switch in sync*", const []);
  }

  @override
  void visitTryCatch(TryCatch node) {
    StateTarget? after = afterTargets[node];
    if (after == null) return super.visitTryCatch(node);

    // TODO(51343): implement this.
    unimplemented(node, "try/catch in sync*", const []);
  }

  @override
  void visitTryFinally(TryFinally node) {
    StateTarget? after = afterTargets[node];
    if (after == null) return super.visitTryFinally(node);

    // TODO(51343): implement this.
    unimplemented(node, "try/finally in sync*", const []);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    StateTarget? inner = innerTargets[node];
    if (inner == null) return super.visitWhileStatement(node);
    StateTarget after = afterTargets[node]!;

    emitTargetLabel(inner);
    jumpToTarget(after, condition: node.condition, negated: true);
    allocateContext(node);
    visitStatement(node.body);
    jumpToTarget(inner);
    emitTargetLabel(after);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    StateTarget after = afterTargets[node]!;

    // Evaluate operand and store it to `_current` for `yield` or
    // `_yieldStarIterable` for `yield*`.
    b.local_get(suspendStateLocal);
    b.struct_get(suspendStateInfo.struct, FieldIndex.suspendStateIterator);
    wrap(node.expression, translator.topInfo.nullableType);
    if (node.isYieldStar) {
      b.ref_cast(translator.objectInfo.nonNullableType);
      b.struct_set(syncStarIteratorInfo.struct,
          FieldIndex.syncStarIteratorYieldStarIterable);
    } else {
      b.struct_set(
          syncStarIteratorInfo.struct, FieldIndex.syncStarIteratorCurrent);
    }

    // Find the current context.
    Context? context;
    TreeNode contextOwner = node;
    do {
      contextOwner = contextOwner.parent!;
      context = closures.contexts[contextOwner];
    } while (
        contextOwner.parent != null && (context == null || context.isEmpty));

    // Store context.
    if (context != null) {
      assert(!context.isEmpty);
      b.local_get(suspendStateLocal);
      b.local_get(context.currentLocal);
      b.struct_set(suspendStateInfo.struct, FieldIndex.suspendStateContext);
    }

    // Set state target to label after yield.
    b.local_get(suspendStateLocal);
    b.i32_const(after.index);
    b.struct_set(suspendStateInfo.struct, FieldIndex.suspendStateTargetIndex);

    // Return `true`.
    b.i32_const(1);
    b.return_();

    // Resume.
    emitTargetLabel(after);

    // For `yield*`, check for pending exception.
    if (node.isYieldStar) {
      w.Label exceptionCheck = b.block();
      b.local_get(pendingExceptionLocal);
      b.br_on_null(exceptionCheck);
      b.local_get(pendingStackTraceLocal);
      b.ref_as_non_null();
      b.throw_(translator.exceptionTag);
      b.end(); // exceptionCheck
    }

    b.restoreSuspendStateContext(suspendStateLocal, suspendStateInfo.struct,
        FieldIndex.suspendStateContext, closures, context, thisLocal);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    assert(node.expression == null);
    emitReturn();
  }
}
