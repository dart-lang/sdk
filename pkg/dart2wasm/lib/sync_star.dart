// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart2wasm/class_info.dart';
import 'package:dart2wasm/closures.dart';
import 'package:dart2wasm/code_generator.dart';

import 'package:kernel/ast.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

/// Placement of a control flow graph target within a statement. This
/// distinction is necessary since some statements need to have two targets
/// associated with them.
///
/// The meanings of the variants are:
///
///  - [Inner]: Loop entry of a [DoStatement], condition of a [ForStatement] or
///             [WhileStatement], the `else` branch of an [IfStatement], or the
///             initial entry target for a function body.
///  - [After]: After a statement, the resumption point of a [YieldStatement],
///             or the final state (iterator done) of a function body.
enum StateTargetPlacement { Inner, After }

/// Representation of target in the `sync*` control flow graph.
class StateTarget {
  int index;
  TreeNode node;
  StateTargetPlacement placement;

  StateTarget(this.index, this.node, this.placement);

  String toString() {
    String place = placement == StateTargetPlacement.Inner ? "in" : "after";
    return "$index: $place $node";
  }
}

/// Identify which statements contain `yield` or `yield*` statements, and assign
/// target indices to all control flow targets of these.
///
/// Target indices are assigned in program order.
class _YieldFinder extends StatementVisitor<void> {
  final SyncStarCodeGenerator codeGen;

  // The number of `yield` or `yield*` statements seen so far.
  int yieldCount = 0;

  _YieldFinder(this.codeGen);

  List<StateTarget> get targets => codeGen.targets;

  void find(FunctionNode function) {
    // Initial state
    addTarget(function.body!, StateTargetPlacement.Inner);
    assert(function.body is Block || function.body is ReturnStatement);
    recurse(function.body!);
    // Final state
    addTarget(function.body!, StateTargetPlacement.After);
  }

  /// Recurse into a statement and then remove any targets added by the
  /// statement if it doesn't contain any `yield` or `yield*` statements.
  void recurse(Statement statement) {
    int yieldCountIn = yieldCount;
    int targetsIn = targets.length;
    statement.accept(this);
    if (yieldCount == yieldCountIn) targets.length = targetsIn;
  }

  void addTarget(TreeNode node, StateTargetPlacement placement) {
    targets.add(StateTarget(targets.length, node, placement));
  }

  @override
  void defaultStatement(Statement node) {
    // Statements not explicitly handled in this visitor can never contain any
    // `yield` or `yield*` statements. It is assumed that this holds for all
    // [BlockExpression]s in the function.
  }

  @override
  void visitBlock(Block node) {
    for (Statement statement in node.statements) {
      recurse(statement);
    }
  }

  @override
  void visitDoStatement(DoStatement node) {
    addTarget(node, StateTargetPlacement.Inner);
    recurse(node.body);
  }

  @override
  void visitForStatement(ForStatement node) {
    addTarget(node, StateTargetPlacement.Inner);
    recurse(node.body);
    addTarget(node, StateTargetPlacement.After);
  }

  @override
  void visitIfStatement(IfStatement node) {
    recurse(node.then);
    if (node.otherwise != null) {
      addTarget(node, StateTargetPlacement.Inner);
      recurse(node.otherwise!);
    }
    addTarget(node, StateTargetPlacement.After);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    recurse(node.body);
    addTarget(node, StateTargetPlacement.After);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    for (SwitchCase c in node.cases) {
      addTarget(c, StateTargetPlacement.Inner);
      recurse(c.body);
    }
    addTarget(node, StateTargetPlacement.After);
  }

  @override
  void visitTryCatch(TryCatch node) {
    recurse(node.body);
    for (Catch c in node.catches) {
      addTarget(c, StateTargetPlacement.Inner);
      recurse(c.body);
    }
    addTarget(node, StateTargetPlacement.After);
  }

  @override
  void visitTryFinally(TryFinally node) {
    recurse(node.body);
    addTarget(node, StateTargetPlacement.Inner);
    recurse(node.finalizer);
    addTarget(node, StateTargetPlacement.After);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    addTarget(node, StateTargetPlacement.Inner);
    recurse(node.body);
    addTarget(node, StateTargetPlacement.After);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    yieldCount++;
    addTarget(node, StateTargetPlacement.After);
  }
}

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
  final List<StateTarget> targets = [];

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
    setupParametersAndContexts(member);
    generateTypeChecks(member.function!.typeParameters, member.function!,
        translator.paramInfoFor(reference));
    generateBodies(member.function!);
  }

  @override
  w.BaseFunction generateLambda(Lambda lambda, Closures closures) {
    this.closures = closures;
    setupLambdaParametersAndContexts(lambda);
    generateBodies(lambda.functionNode);
    return function;
  }

  void generateBodies(FunctionNode functionNode) {
    // Number and categorize CFG targets.
    _YieldFinder(this).find(functionNode);
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
          translator.stackTraceInfo.nullableType
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
    DartType returnType = functionNode.returnType;
    DartType elementType = returnType is InterfaceType &&
            returnType.classNode == translator.coreTypes.iterableClass
        ? returnType.typeArguments.single
        : DynamicType();
    translator.functions.allocateClass(syncStarIterableInfo.classId);
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

  /// Clones the context pointed to by the [srcContext] local. Returns a local
  /// pointing to the cloned context.
  ///
  /// It is assumed that the context is the function-level context for the
  /// `sync*` function.
  w.Local cloneContext(
      FunctionNode functionNode, Context context, w.Local srcContext) {
    assert(context.owner == functionNode);

    final w.Local destContext = addLocal(context.currentLocal.type);
    b.struct_new_default(context.struct);
    b.local_set(destContext);

    void copyCapture(TreeNode node) {
      Capture? capture = closures.captures[node];
      if (capture != null) {
        assert(capture.context == context);
        b.local_get(destContext);
        b.local_get(srcContext);
        b.struct_get(context.struct, capture.fieldIndex);
        b.struct_set(context.struct, capture.fieldIndex);
      }
    }

    if (context.containsThis) {
      b.local_get(destContext);
      b.local_get(srcContext);
      b.struct_get(context.struct, context.thisFieldIndex);
      b.struct_set(context.struct, context.thisFieldIndex);
    }
    if (context.parent != null) {
      b.local_get(destContext);
      b.local_get(srcContext);
      b.struct_get(context.struct, context.parentFieldIndex);
      b.struct_set(context.struct, context.parentFieldIndex);
    }
    functionNode.positionalParameters.forEach(copyCapture);
    functionNode.namedParameters.forEach(copyCapture);
    functionNode.typeParameters.forEach(copyCapture);

    return destContext;
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
    restoreContextsAndThis(context, cloneContextFor: functionNode);

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

  void restoreContextsAndThis(Context? context,
      {FunctionNode? cloneContextFor}) {
    if (context != null) {
      assert(!context.isEmpty);
      b.local_get(suspendStateLocal);
      b.struct_get(suspendStateInfo.struct, FieldIndex.suspendStateContext);
      b.ref_cast(context.currentLocal.type as w.RefType);
      b.local_set(context.currentLocal);

      if (context.owner == cloneContextFor) {
        context.currentLocal =
            cloneContext(cloneContextFor!, context, context.currentLocal);
      }

      while (context!.parent != null) {
        assert(!context.parent!.isEmpty);
        b.local_get(context.currentLocal);
        b.struct_get(context.struct, context.parentFieldIndex);
        b.ref_as_non_null();
        context = context.parent!;
        b.local_set(context.currentLocal);
      }
      if (context.containsThis) {
        b.local_get(context.currentLocal);
        b.struct_get(context.struct, context.thisFieldIndex);
        b.ref_as_non_null();
        b.local_set(thisLocal!);
      }
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

    restoreContextsAndThis(context);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    assert(node.expression == null);
    emitReturn();
  }
}
