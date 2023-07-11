// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart2wasm/class_info.dart';
import 'package:dart2wasm/closures.dart';
import 'package:dart2wasm/code_generator.dart';
import 'package:dart2wasm/sync_star.dart'
    show StateTarget, StateTargetPlacement;

import 'package:kernel/ast.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

/// Identify which statements contain `await` statements, and assign target
/// indices to all control flow targets of these.
///
/// Target indices are assigned in program order.
class _YieldFinder extends RecursiveVisitor {
  final List<StateTarget> targets = [];
  final bool enableAsserts;

  // The number of `await` statements seen so far.
  int yieldCount = 0;

  _YieldFinder(this.enableAsserts);

  List<StateTarget> find(FunctionNode function) {
    // Initial state
    addTarget(function.body!, StateTargetPlacement.Inner);
    assert(function.body is Block || function.body is ReturnStatement);
    recurse(function.body!);
    // Final state
    addTarget(function.body!, StateTargetPlacement.After);
    return this.targets;
  }

  /// Recurse into a statement and then remove any targets added by the
  /// statement if it doesn't contain any `await` statements.
  void recurse(Statement statement) {
    final yieldCountIn = yieldCount;
    final targetsIn = targets.length;
    statement.accept(this);
    if (yieldCount == yieldCountIn) {
      targets.length = targetsIn;
    }
  }

  void addTarget(TreeNode node, StateTargetPlacement placement) {
    targets.add(StateTarget(targets.length, node, placement));
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
  void visitTryFinally(TryFinally node) {
    // [TryFinally] blocks are always compiled to as CFG, even when they don't
    // have awaits. This is to keep the code size small: with normal
    // compilation finalizer blocks need to be duplicated based on
    // continuations, which we don't need in the CFG implementation.
    yieldCount += 1;
    recurse(node.body);
    addTarget(node, StateTargetPlacement.Inner);
    recurse(node.finalizer);
    addTarget(node, StateTargetPlacement.After);
  }

  @override
  void visitTryCatch(TryCatch node) {
    // Also always compile [TryCatch] blocks to the CFG to be able to set
    // finalizer continuations.
    yieldCount += 1;
    recurse(node.body);
    for (Catch c in node.catches) {
      addTarget(c, StateTargetPlacement.Inner);
      recurse(c.body);
    }
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
    throw 'Yield statement in async function: $node (${node.location})';
  }

  // Handle awaits. After the await transformation await can only appear in a
  // RHS of a top-level assignment, or as a top-level statement.
  @override
  void visitVariableSet(VariableSet node) {
    if (node.value is AwaitExpression) {
      yieldCount++;
      addTarget(node, StateTargetPlacement.After);
    } else {
      super.visitVariableSet(node);
    }
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    if (node.expression is AwaitExpression) {
      yieldCount++;
      addTarget(node, StateTargetPlacement.After);
    } else {
      super.visitExpressionStatement(node);
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  // Any other await expression means the await transformer is buggy and didn't
  // transform the expression as expected.
  @override
  void visitAwaitExpression(AwaitExpression node) {
    throw 'Unexpected await expression: $node (${node.location})';
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    if (enableAsserts) {
      super.visitAssertStatement(node);
    }
  }

  @override
  void visitAssertBlock(AssertBlock node) {
    if (enableAsserts) {
      super.visitAssertBlock(node);
    }
  }
}

class _ExceptionHandlerStack {
  /// Current exception handler stack. A CFG block generated when this is not
  /// empty should have a Wasm `try` instruction wrapping the block.
  ///
  /// A `catch` block will jump to the last handler, which then jumps to the
  /// next if the exception type test fails.
  ///
  /// Because the CFG blocks for [Catch] blocks and finalizers will have Wasm
  /// `try` blocks for the parent handlers, we can use a Wasm `throw`
  /// instruction (instead of jumping to the parent handler) in [Catch] blocks
  /// and finalizers for rethrowing.
  final List<_ExceptionHandler> _handlers = [];

  /// Maps Wasm `try` blocks to number of handlers in [_handlers] that they
  /// cover for.
  final List<int> _tryBlockNumHandlers = [];

  final AsyncCodeGenerator codeGen;

  _ExceptionHandlerStack(this.codeGen);

  void pushTryCatch(TryCatch node) {
    final catcher = Catcher.fromTryCatch(
        codeGen, node, codeGen.innerTargets[node.catches.first]!);
    _handlers.add(catcher);
  }

  Finalizer pushTryFinally(TryFinally node) {
    final finalizer =
        Finalizer(codeGen, node, nextFinalizer, codeGen.innerTargets[node]!);
    _handlers.add(finalizer);
    return finalizer;
  }

  void pop() {
    _handlers.removeLast();
  }

  int get numHandlers => _handlers.length;

  int get coveredHandlers => _tryBlockNumHandlers.fold(0, (i1, i2) => i1 + i2);

  int get numFinalizers {
    int i = 0;
    for (final handler in _handlers) {
      if (handler is Finalizer) {
        i += 1;
      }
    }
    return i;
  }

  Finalizer? get nextFinalizer {
    for (final handler in _handlers.reversed) {
      if (handler is Finalizer) {
        return handler;
      }
    }
    return null;
  }

  void forEachFinalizer(void f(Finalizer finalizer, bool lastFinalizer)) {
    Finalizer? finalizer = nextFinalizer;
    while (finalizer != null) {
      Finalizer? next = finalizer.parentFinalizer;
      f(finalizer, next == null);
      finalizer = next;
    }
  }

  /// Generates Wasm `try` blocks for Dart `try` blocks wrapping the current
  /// CFG block.
  ///
  /// Call this when generating a new CFG block.
  void generateTryBlocks(w.Instructions b) {
    final handlersToCover = _handlers.length - coveredHandlers;

    if (handlersToCover == 0) {
      return;
    }

    b.try_();
    _tryBlockNumHandlers.add(handlersToCover);
  }

  /// Terminates Wasm `try` blocks generated by [generateTryBlocks].
  ///
  /// Call this right before terminating a CFG block.
  void terminateTryBlocks() {
    int handlerIdx = _handlers.length - 1;
    while (_tryBlockNumHandlers.isNotEmpty) {
      int nCoveredHandlers = _tryBlockNumHandlers.removeLast();

      codeGen.b.catch_(codeGen.translator.exceptionTag);

      final stackTraceLocal =
          codeGen.addLocal(codeGen.translator.stackTraceInfo.nonNullableType);
      codeGen.b.local_set(stackTraceLocal);

      final exceptionLocal =
          codeGen.addLocal(codeGen.translator.topInfo.nonNullableType);
      codeGen.b.local_set(exceptionLocal);

      final nextHandler = _handlers[handlerIdx];

      while (nCoveredHandlers != 0) {
        final handler = _handlers[handlerIdx];
        handlerIdx -= 1;
        if (handler is Finalizer) {
          handler.setContinuationRethrow(
              () => codeGen.b.local_get(exceptionLocal),
              () => codeGen.b.local_get(stackTraceLocal));
        }
        nCoveredHandlers -= 1;
      }

      // Set the untyped "current exception" variable. Catch blocks will do the
      // type tests as necessary using this variable and set their exception
      // and stack trace locals.
      codeGen._setCurrentException(() => codeGen.b.local_get(exceptionLocal));
      codeGen._setCurrentExceptionStackTrace(
          () => codeGen.b.local_get(stackTraceLocal));

      codeGen.jumpToTarget(nextHandler.target);

      codeGen.b.end(); // end catch
    }
  }
}

/// Represents an exception handler (`catch` or `finally`).
///
/// Note: for a [TryCatch] with multiple [Catch] blocks we jump to the first
/// [Catch] block on exception, which checks the exception type and jumps to
/// the next one if necessary.
abstract class _ExceptionHandler {
  /// CFG block for the `catch` or `finally` block.
  final StateTarget target;

  _ExceptionHandler(this.target);
}

class Catcher extends _ExceptionHandler {
  final List<VariableDeclaration> _exceptionVars = [];
  final List<VariableDeclaration> _stackTraceVars = [];
  final AsyncCodeGenerator codeGen;

  Catcher.fromTryCatch(this.codeGen, TryCatch node, super.target) {
    for (Catch catch_ in node.catches) {
      _exceptionVars.add(catch_.exception!);
      _stackTraceVars.add(catch_.stackTrace!);
    }
  }

  void setException(void pushException()) {
    for (final exceptionVar in _exceptionVars) {
      codeGen._setVariable(exceptionVar, pushException);
    }
  }

  void setStackTrace(void pushStackTrace()) {
    for (final stackTraceVar in _stackTraceVars) {
      codeGen._setVariable(stackTraceVar, pushStackTrace);
    }
  }
}

const int continuationFallthrough = 0;
const int continuationReturn = 1;
const int continuationRethrow = 2;

// For larger continuation values, `value - continuationJump` gives us the
// target block index to jump.
const int continuationJump = 3;

class Finalizer extends _ExceptionHandler {
  final VariableDeclaration _continuationVar;
  final VariableDeclaration _exceptionVar;
  final VariableDeclaration _stackTraceVar;
  final Finalizer? parentFinalizer;
  final AsyncCodeGenerator codeGen;

  Finalizer(this.codeGen, TryFinally node, this.parentFinalizer, super.target)
      : _continuationVar =
            (node.parent as Block).statements[0] as VariableDeclaration,
        _exceptionVar =
            (node.parent as Block).statements[1] as VariableDeclaration,
        _stackTraceVar =
            (node.parent as Block).statements[2] as VariableDeclaration;

  void setContinuationFallthrough() {
    codeGen._setVariable(_continuationVar, () {
      codeGen.b.i64_const(continuationFallthrough);
    });
  }

  void setContinuationReturn() {
    codeGen._setVariable(_continuationVar, () {
      codeGen.b.i64_const(continuationReturn);
    });
  }

  void setContinuationRethrow(void pushException(), void pushStackTrace()) {
    codeGen._setVariable(_continuationVar, () {
      codeGen.b.i64_const(continuationRethrow);
    });
    codeGen._setVariable(_exceptionVar, pushException);
    codeGen._setVariable(_stackTraceVar, pushStackTrace);
  }

  void setContinuationJump(int index) {
    codeGen._setVariable(_continuationVar, () {
      codeGen.b.i64_const(index + continuationJump);
    });
  }

  /// Push continuation of the finalizer block onto the stack as `i32`.
  void pushContinuation() {
    codeGen.visitVariableGet(VariableGet(_continuationVar), w.NumType.i64);
    codeGen.b.i32_wrap_i64();
  }

  void pushException() {
    codeGen._getVariable(_exceptionVar);
  }

  void pushStackTrace() {
    codeGen._getVariable(_stackTraceVar);
  }
}

/// Represents target of a `break` statement.
abstract class LabelTarget {
  void jump(AsyncCodeGenerator codeGen);
}

/// Target of a [BreakStatement] that can be implemented with a Wasm `br`
/// instruction.
///
/// This [LabelTarget] is used when the [LabeledStatement] is compiled using
/// the normal code generator (instead of async code generator).
class DirectLabelTarget implements LabelTarget {
  final w.Label label;

  DirectLabelTarget(this.label);

  @override
  void jump(AsyncCodeGenerator codeGen) {
    codeGen.b.br(label);
  }
}

/// Target of a [BreakStatement] when the [LabeledStatement] is compiled to
/// CFG.
class IndirectLabelTarget implements LabelTarget {
  /// Number of finalizers wrapping the [LabeledStatement].
  final int finalizerDepth;

  /// CFG state for the [LabeledStatement] continuation.
  final StateTarget stateTarget;

  IndirectLabelTarget(this.finalizerDepth, this.stateTarget);

  @override
  void jump(AsyncCodeGenerator codeGen) {
    final currentFinalizerDepth = codeGen.exceptionHandlers.numFinalizers;
    final finalizersToRun = currentFinalizerDepth - finalizerDepth;

    // Control flow overridden by a `break`, reset finalizer continuations.
    var i = finalizersToRun;
    codeGen.exceptionHandlers.forEachFinalizer((finalizer, last) {
      if (i <= 0) {
        // Finalizer won't be run by the `break`, reset continuation.
        finalizer.setContinuationFallthrough();
      } else {
        // Finalizer will be run by the `break`. Each finalizer jumps to the
        // next, last finalizer jumps to the `break` target.
        finalizer.setContinuationJump(i == 1
            ? stateTarget.index
            : finalizer.parentFinalizer!.target.index);
      }
      i -= 1;
    });

    if (finalizersToRun == 0) {
      codeGen.jumpToTarget(stateTarget);
    } else {
      codeGen.jumpToTarget(codeGen.exceptionHandlers.nextFinalizer!.target);
    }
  }
}

/// Exception and stack trace variables of a [Catch] block. These variables are
/// used to get the exception and stack trace to throw when compiling
/// [Rethrow].
class CatchVariables {
  final VariableDeclaration exception;
  final VariableDeclaration stackTrace;

  CatchVariables(this.exception, this.stackTrace);
}

class AsyncCodeGenerator extends CodeGenerator {
  AsyncCodeGenerator(super.translator, super.function, super.reference);

  /// Targets of the CFG, indexed by target index.
  late final List<StateTarget> targets;

  // Targets categorized by placement and indexed by node.
  final Map<TreeNode, StateTarget> innerTargets = {};
  final Map<TreeNode, StateTarget> afterTargets = {};

  /// The loop around the switch.
  late final w.Label masterLoop;

  /// The target labels of the switch, indexed by target index.
  late final List<w.Label> labels;

  /// The target index of the entry label for the current CFG node.
  int currentTargetIndex = -1;

  /// The local in the inner function for the async state, with type
  /// `ref _AsyncSuspendState`.
  late final w.Local suspendStateLocal;

  /// The local in the inner function for the value of the last awaited future,
  /// with type `ref null #Top`.
  late final w.Local awaitValueLocal;

  /// The local for the CFG target block index.
  late final w.Local targetIndexLocal;

  /// Exception handlers wrapping the current CFG block. Used to generate Wasm
  /// `try` and `catch` blocks around the CFG blocks.
  late final _ExceptionHandlerStack exceptionHandlers;

  /// Maps jump targets to their CFG targets. Used when jumping to a CFG block
  /// on `break`. Keys are [LabeledStatement]s or [SwitchCase]s.
  final Map<TreeNode, LabelTarget> labelTargets = {};

  late final ClassInfo asyncSuspendStateInfo =
      translator.classInfo[translator.asyncSuspendStateClass]!;

  /// Current [Catch] block stack, used to compile [Rethrow].
  ///
  /// Because there can be an `await` in a [Catch] block before a [Rethrow], we
  /// can't compile [Rethrow] to Wasm `rethrow`. Instead we `throw` using the
  /// [Rethrow]'s parent [Catch] block's exception and stack variables.
  List<CatchVariables> catchVariableStack = [];

  @override
  void generate() {
    closures = Closures(this);
    setupParametersAndContexts(member);
    generateTypeChecks(member.function!.typeParameters, member.function!,
        translator.paramInfoFor(reference));
    _generateBodies(member.function!);
  }

  @override
  w.DefinedFunction generateLambda(Lambda lambda, Closures closures) {
    this.closures = closures;
    setupLambdaParametersAndContexts(lambda);
    _generateBodies(lambda.functionNode);
    return function;
  }

  void _generateBodies(FunctionNode functionNode) {
    // Number and categorize CFG targets.
    targets = _YieldFinder(translator.options.enableAsserts).find(functionNode);
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

    exceptionHandlers = _ExceptionHandlerStack(this);

    // Wasm function containing the body of the `async` function
    // (`_AyncResumeFun`).
    final w.DefinedFunction resumeFun = m.addFunction(
        m.addFunctionType([
          asyncSuspendStateInfo.nonNullableType, // _AsyncSuspendState
          translator.topInfo.nullableType, // Object?, await value
          translator.topInfo.nullableType, // Object?, error value
          translator
              .stackTraceInfo.nullableType // StackTrace?, error stack trace
        ], [
          // Inner function does not return a value, but it's Dart type is
          // `void Function(...)` and all Dart functions return a value, so we
          // add a return type.
          translator.topInfo.nullableType
        ]),
        "${function.functionName} inner");

    Context? context = closures.contexts[functionNode];
    if (context != null && context.isEmpty) context = context.parent;

    _generateOuter(functionNode, context, resumeFun);

    // Forget about the outer function locals containing the type arguments,
    // so accesses to the type arguments in the inner function will fetch them
    // from the context.
    typeLocals.clear();

    _generateInner(functionNode, context, resumeFun);
  }

  void _generateOuter(FunctionNode functionNode, Context? context,
      w.DefinedFunction resumeFun) {
    // Outer (wrapper) function creates async state, calls the inner function
    // (which runs until first suspension point, i.e. `await`), and returns the
    // completer's future.

    // (1) Create async state.

    final asyncStateLocal = function
        .addLocal(w.RefType(asyncSuspendStateInfo.struct, nullable: false));

    // AsyncResumeFun _resume
    b.global_get(translator.makeFunctionRef(resumeFun));

    // WasmStructRef? _context
    if (context != null) {
      assert(!context.isEmpty);
      b.local_get(context.currentLocal);
    } else {
      b.ref_null(w.HeapType.struct);
    }

    // _AsyncCompleter _completer
    final DartType returnType = functionNode.returnType;
    final DartType completerType;
    if (returnType is InterfaceType &&
        returnType.classNode == translator.coreTypes.futureClass) {
      // Return type = Future<T>, completer type = _AsyncCompleter<T>.
      completerType = returnType.typeArguments.single;
    } else if (returnType is FutureOrType) {
      // Return type = FutureOr<T>, completer type = _AsyncCompleter<T>.
      completerType = returnType.typeArgument;
    } else {
      // In all other cases we use _AsyncCompleter<dynamic>.
      completerType = const DynamicType();
    }
    types.makeType(this, completerType);
    b.call(translator.functions
        .getFunction(translator.makeAsyncCompleter.reference));

    // Allocate `_AsyncSuspendState`
    b.call(translator.functions
        .getFunction(translator.newAsyncSuspendState.reference));
    b.local_set(asyncStateLocal);

    // (2) Call inner function.
    //
    // Note: the inner function does not throw, so we don't need a `try` block
    // here.

    b.local_get(asyncStateLocal);
    b.ref_null(translator.topInfo.struct); // await value
    b.ref_null(translator.topInfo.struct); // error value
    b.ref_null(translator.stackTraceInfo.struct); // stack trace
    b.call(resumeFun);
    b.drop(); // drop null

    // (3) Return the completer's future.

    b.local_get(asyncStateLocal);
    final completerFutureGetter = translator.functions
        .getFunction(translator.completerFuture.getterReference);
    b.struct_get(
        asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateCompleter);
    translator.convertType(
        function,
        asyncSuspendStateInfo.struct.fields[5].type.unpacked,
        completerFutureGetter.type.inputs[0]);
    b.call(completerFutureGetter);
    b.end();
  }

  /// Clones the context pointed to by the [srcContext] local. Returns a local
  /// pointing to the cloned context.
  ///
  /// It is assumed that the context is the function-level context for the
  /// `async` function.
  w.Local _cloneContext(
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

  void _generateInner(FunctionNode functionNode, Context? context,
      w.DefinedFunction resumeFun) {
    // void Function(_AsyncSuspendState, Object?)

    // Set the current Wasm function for the code generator to the inner
    // function of the `async`, which is to contain the body.
    function = resumeFun;

    suspendStateLocal = function.locals[0]; // ref _AsyncSuspendState
    awaitValueLocal = function.locals[1]; // ref null #Top

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
    b.struct_get(
        asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateTargetIndex);
    b.local_set(targetIndexLocal);

    // The outer `try` block calls `completeOnError` on exceptions.
    b.try_();

    // Switch on the target index.
    masterLoop = b.loop(const [], const []);
    labels = List.generate(targets.length, (_) => b.block()).reversed.toList();
    w.Label defaultLabel = b.block();
    b.local_get(targetIndexLocal);
    b.br_table(labels, defaultLabel);
    b.end(); // defaultLabel
    b.unreachable();

    // Initial state
    final StateTarget initialTarget = targets.first;
    _emitTargetLabel(initialTarget);

    // Clone context on first execution.
    _restoreContextsAndThis(context, cloneContextFor: functionNode);

    visitStatement(functionNode.body!);

    // Final state: return.
    _emitTargetLabel(targets.last);
    b.local_get(suspendStateLocal);
    b.struct_get(
        asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateCompleter);
    // Non-null Dart field represented as nullable Wasm field.
    b.ref_as_non_null();
    b.ref_null(translator.topInfo.struct);
    b.call(translator.functions
        .getFunction(translator.completerComplete.reference));
    b.return_();
    b.end(); // masterLoop

    b.catch_(translator.exceptionTag);

    final stackTraceLocal = addLocal(translator.stackTraceInfo.nonNullableType);
    b.local_set(stackTraceLocal);

    final exceptionLocal = addLocal(translator.topInfo.nonNullableType);
    b.local_set(exceptionLocal);

    b.local_get(suspendStateLocal);
    b.struct_get(
        asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateCompleter);
    b.ref_as_non_null();
    b.local_get(exceptionLocal);
    b.local_get(stackTraceLocal);
    b.call(translator.functions
        .getFunction(translator.completerCompleteError.reference));
    b.return_();

    b.end(); // end try

    b.unreachable();
    b.end();
  }

  // Note: These two locals are only available in "inner" functions.
  w.Local get pendingExceptionLocal => function.locals[2];
  w.Local get pendingStackTraceLocal => function.locals[3];

  void _emitTargetLabel(StateTarget target) {
    currentTargetIndex++;
    assert(
        target.index == currentTargetIndex,
        'target.index = ${target.index}, '
        'currentTargetIndex = $currentTargetIndex, '
        'target.node.location = ${target.node.location}');
    exceptionHandlers.terminateTryBlocks();
    b.end();
    exceptionHandlers.generateTryBlocks(b);
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

  void _restoreContextsAndThis(Context? context,
      {FunctionNode? cloneContextFor}) {
    if (context != null) {
      assert(!context.isEmpty);
      b.local_get(suspendStateLocal);
      b.struct_get(
          asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateContext);
      b.ref_cast(context.currentLocal.type as w.RefType);
      b.local_set(context.currentLocal);

      if (context.owner == cloneContextFor) {
        context.currentLocal =
            _cloneContext(cloneContextFor!, context, context.currentLocal);
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

    _emitTargetLabel(inner);
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
    _emitTargetLabel(inner);
    jumpToTarget(after, condition: node.condition, negated: true);
    visitStatement(node.body);

    emitForStatementUpdate(node);

    jumpToTarget(inner);
    _emitTargetLabel(after);
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
      _emitTargetLabel(inner!);
      visitStatement(node.otherwise!);
    }
    _emitTargetLabel(after);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    StateTarget? after = afterTargets[node];
    if (after == null) {
      final w.Label label = b.block();
      labelTargets[node] = DirectLabelTarget(label);
      visitStatement(node.body);
      labelTargets.remove(node);
      b.end();
    } else {
      labelTargets[node] =
          IndirectLabelTarget(exceptionHandlers.numFinalizers, after);
      visitStatement(node.body);
      labelTargets.remove(node);
      _emitTargetLabel(after);
    }
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    labelTargets[node.target]!.jump(this);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    StateTarget? after = afterTargets[node];
    if (after == null) return super.visitSwitchStatement(node);

    final switchInfo = SwitchInfo(this, node);

    bool isNullable = dartTypeOf(node.expression).isPotentiallyNullable;

    // Special cases
    final SwitchCase? defaultCase = switchInfo.defaultCase;
    final SwitchCase? nullCase = switchInfo.nullCase;

    // When the type is nullable we use two variables: one for the nullable
    // value, one after the null check, with non-nullable type.
    w.Local switchValueNonNullableLocal = addLocal(switchInfo.nonNullableType);
    w.Local? switchValueNullableLocal =
        isNullable ? addLocal(switchInfo.nullableType) : null;

    // Initialize switch value local
    wrap(node.expression,
        isNullable ? switchInfo.nullableType : switchInfo.nonNullableType);
    b.local_set(
        isNullable ? switchValueNullableLocal! : switchValueNonNullableLocal);

    // Compute value and handle null
    if (isNullable) {
      final StateTarget nullTarget = nullCase != null
          ? innerTargets[nullCase]!
          : defaultCase != null
              ? innerTargets[defaultCase]!
              : after;

      b.local_get(switchValueNullableLocal!);
      b.ref_is_null();
      b.if_();
      jumpToTarget(nullTarget);
      b.end();
      b.local_get(switchValueNullableLocal);
      b.ref_as_non_null();
      // Unbox if necessary
      translator.convertType(function, switchValueNullableLocal.type,
          switchValueNonNullableLocal.type);
      b.local_set(switchValueNonNullableLocal);
    }

    // Compare against all case values
    for (SwitchCase c in node.cases) {
      for (Expression exp in c.expressions) {
        if (exp is NullLiteral ||
            exp is ConstantExpression && exp.constant is NullConstant) {
          // Null already checked, skip
        } else {
          wrap(exp, switchInfo.nonNullableType);
          b.local_get(switchValueNonNullableLocal);
          switchInfo.compare();
          b.if_();
          jumpToTarget(innerTargets[c]!);
          b.end();
        }
      }
    }

    // No explicit cases matched
    if (node.isExplicitlyExhaustive) {
      b.unreachable();
    } else {
      final StateTarget defaultLabel =
          defaultCase != null ? innerTargets[defaultCase]! : after;
      jumpToTarget(defaultLabel);
    }

    // Add jump infos
    for (final SwitchCase case_ in node.cases) {
      labelTargets[case_] = IndirectLabelTarget(
          exceptionHandlers.numFinalizers, innerTargets[case_]!);
    }

    // Emit case bodies
    for (SwitchCase c in node.cases) {
      _emitTargetLabel(innerTargets[c]!);
      visitStatement(c.body);
      jumpToTarget(after);
    }

    // Remove jump infos
    for (final SwitchCase case_ in node.cases) {
      labelTargets.remove(case_);
    }

    _emitTargetLabel(after);
  }

  @override
  void visitContinueSwitchStatement(ContinueSwitchStatement node) {
    labelTargets[node.target]!.jump(this);
  }

  @override
  void visitTryCatch(TryCatch node) {
    StateTarget? after = afterTargets[node];
    if (after == null) return super.visitTryCatch(node);

    allocateContext(node);

    for (Catch c in node.catches) {
      if (c.exception != null) {
        visitVariableDeclaration(c.exception!);
      }
      if (c.stackTrace != null) {
        visitVariableDeclaration(c.stackTrace!);
      }
    }

    exceptionHandlers.pushTryCatch(node);
    exceptionHandlers.generateTryBlocks(b);
    visitStatement(node.body);
    jumpToTarget(after);
    exceptionHandlers.terminateTryBlocks();
    exceptionHandlers.pop();

    void emitCatchBlock(Catch catch_, Catch? nextCatch, bool emitGuard) {
      if (emitGuard) {
        _getCurrentException();
        b.ref_as_non_null();
        types.emitTypeTest(
            this, catch_.guard, translator.coreTypes.objectNonNullableRawType);
        b.i32_eqz();
        // When generating guards we can't generate the catch body inside the
        // `if` block for the guard as the catch body can have suspension
        // points and generate target labels.
        b.if_();
        if (nextCatch != null) {
          jumpToTarget(innerTargets[nextCatch]!);
        } else {
          // Rethrow.
          _getCurrentException();
          b.ref_as_non_null();
          _getCurrentExceptionStackTrace();
          b.ref_as_non_null();
          // TODO (omersa): When there is a finalizer we can jump to it
          // directly, instead of via throw/catch. Would that be faster?
          exceptionHandlers.forEachFinalizer(
              (finalizer, _last) => finalizer.setContinuationRethrow(
                    () => _getVariableBoxed(catch_.exception!),
                    () => _getVariable(catch_.stackTrace!),
                  ));
          b.throw_(translator.exceptionTag);
        }
        b.end();
      }

      // Set exception and stack trace variables.
      _setVariable(catch_.exception!, () {
        _getCurrentException();
        // Type test already passed, convert the exception.
        translator.convertType(
            function,
            asyncSuspendStateInfo
                .struct
                .fields[FieldIndex.asyncSuspendStateCurrentException]
                .type
                .unpacked,
            translator.translateType(catch_.exception!.type));
      });
      _setVariable(catch_.stackTrace!, () => _getCurrentExceptionStackTrace());

      catchVariableStack
          .add(CatchVariables(catch_.exception!, catch_.stackTrace!));

      visitStatement(catch_.body);

      catchVariableStack.removeLast();

      jumpToTarget(after);
    }

    for (int catchIdx = 0; catchIdx < node.catches.length; catchIdx += 1) {
      final Catch catch_ = node.catches[catchIdx];
      final Catch? nextCatch =
          node.catches.length < catchIdx ? node.catches[catchIdx + 1] : null;

      _emitTargetLabel(innerTargets[catch_]!);

      final bool shouldEmitGuard =
          catch_.guard != translator.coreTypes.objectNonNullableRawType;

      emitCatchBlock(catch_, nextCatch, shouldEmitGuard);

      if (!shouldEmitGuard) {
        break;
      }
    }

    // Rethrow. Note that we don't override finalizer continuations here, they
    // should be set by the original `throw` site.
    _getCurrentException();
    b.ref_as_non_null();
    _getCurrentExceptionStackTrace();
    b.ref_as_non_null();
    b.throw_(translator.exceptionTag);

    _emitTargetLabel(after);
  }

  @override
  void visitTryFinally(TryFinally node) {
    allocateContext(node);

    final StateTarget finalizerTarget = innerTargets[node]!;
    final StateTarget fallthroughContinuationTarget = afterTargets[node]!;

    // Body
    final finalizer = exceptionHandlers.pushTryFinally(node);
    exceptionHandlers.generateTryBlocks(b);
    visitStatement(node.body);

    // Set continuation of the finalizer.
    finalizer.setContinuationFallthrough();

    jumpToTarget(finalizerTarget);
    exceptionHandlers.terminateTryBlocks();
    exceptionHandlers.pop();

    // Finalizer
    {
      _emitTargetLabel(finalizerTarget);
      visitStatement(node.finalizer);

      // Check continuation.

      // Fallthrough
      assert(continuationFallthrough == 0); // update eqz below if changed
      finalizer.pushContinuation();
      b.i32_eqz();
      b.if_();
      jumpToTarget(fallthroughContinuationTarget);
      b.end();

      // Return
      finalizer.pushContinuation();
      b.i32_const(continuationReturn);
      b.i32_eq();
      b.if_();
      b.local_get(suspendStateLocal);
      b.struct_get(
          asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateCompleter);
      // Non-null Dart field represented as nullable Wasm field.
      b.ref_as_non_null();
      b.local_get(suspendStateLocal);
      b.struct_get(asyncSuspendStateInfo.struct,
          FieldIndex.asyncSuspendStateCurrentReturnValue);
      b.call(translator.functions
          .getFunction(translator.completerComplete.reference));
      b.return_();
      b.end();

      // Rethrow
      finalizer.pushContinuation();
      b.i32_const(continuationRethrow);
      b.i32_eq();
      b.if_();
      finalizer.pushException();
      b.ref_as_non_null();
      finalizer.pushStackTrace();
      b.ref_as_non_null();
      b.throw_(translator.exceptionTag);
      b.end();

      // Any other value: jump to the target.
      finalizer.pushContinuation();
      b.i32_const(continuationJump);
      b.i32_sub();
      b.local_set(targetIndexLocal);
      b.br(masterLoop);
    }

    _emitTargetLabel(fallthroughContinuationTarget);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    StateTarget? inner = innerTargets[node];
    if (inner == null) return super.visitWhileStatement(node);
    StateTarget after = afterTargets[node]!;

    _emitTargetLabel(inner);
    jumpToTarget(after, condition: node.condition, negated: true);
    allocateContext(node);
    visitStatement(node.body);
    jumpToTarget(inner);
    _emitTargetLabel(after);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    throw 'Yield statement in async function: $node (${node.location})';
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    final Finalizer? firstFinalizer = exceptionHandlers.nextFinalizer;

    if (firstFinalizer == null) {
      b.local_get(suspendStateLocal);
      b.struct_get(
          asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateCompleter);
      // Non-null Dart field represented as nullable Wasm field.
      b.ref_as_non_null();
    }

    final value = node.expression;
    if (value == null) {
      b.ref_null(translator.topInfo.struct);
    } else {
      wrap(value, translator.topInfo.nullableType);
    }

    if (firstFinalizer == null) {
      b.call(translator.functions
          .getFunction(translator.completerComplete.reference));
      b.return_();
    } else {
      final returnValueLocal = addLocal(translator.topInfo.nullableType);
      b.local_set(returnValueLocal);

      // Set return value
      b.local_get(suspendStateLocal);
      b.local_get(returnValueLocal);
      b.struct_set(asyncSuspendStateInfo.struct,
          FieldIndex.asyncSuspendStateCurrentReturnValue);

      // Update continuation variables of finalizers. Last finalizer returns
      // the value.
      exceptionHandlers.forEachFinalizer((finalizer, last) {
        if (last) {
          finalizer.setContinuationReturn();
        } else {
          finalizer
              .setContinuationJump(finalizer.parentFinalizer!.target.index);
        }
      });

      // Jump to the first finalizer
      jumpToTarget(firstFinalizer.target);
    }
  }

  @override
  w.ValueType visitThrow(Throw node, w.ValueType expectedType) {
    final exceptionLocal = addLocal(translator.topInfo.nonNullableType);
    wrap(node.expression, translator.topInfo.nonNullableType);
    b.local_set(exceptionLocal);

    final stackTraceLocal = addLocal(translator.stackTraceInfo.nonNullableType);
    call(translator.stackTraceCurrent.reference);
    b.local_set(stackTraceLocal);

    exceptionHandlers.forEachFinalizer((finalizer, _last) {
      finalizer.setContinuationRethrow(() => b.local_get(exceptionLocal),
          () => b.local_get(stackTraceLocal));
    });

    // TODO (omersa): An alternative would be to directly jump to the parent
    // handler, or call `completeOnError` if we're not in a try-catch or
    // try-finally. Would that be more efficient?
    b.local_get(exceptionLocal);
    b.local_get(stackTraceLocal);
    b.throw_(translator.exceptionTag);

    b.unreachable();
    return expectedType;
  }

  @override
  w.ValueType visitRethrow(Rethrow node, w.ValueType expectedType) {
    final catchVars = catchVariableStack.last;

    exceptionHandlers.forEachFinalizer((finalizer, _last) {
      finalizer.setContinuationRethrow(
        () => _getVariableBoxed(catchVars.exception),
        () => _getVariable(catchVars.stackTrace),
      );
    });

    // TODO (omersa): Similar to `throw` compilation above, we could directly
    // jump to the target block or call `completeOnError`.
    _getCurrentException();
    b.ref_as_non_null();
    _getCurrentExceptionStackTrace();
    b.ref_as_non_null();
    b.throw_(translator.exceptionTag);
    b.unreachable();
    return expectedType;
  }

  // Handle awaits
  @override
  void visitExpressionStatement(ExpressionStatement node) {
    final expression = node.expression;
    if (expression is VariableSet) {
      final value = expression.value;
      if (value is AwaitExpression) {
        _generateAwait(value, expression.variable);
        return;
      }
    }

    super.visitExpressionStatement(node);
  }

  void _generateAwait(AwaitExpression node, VariableDeclaration awaitValueVar) {
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
      b.struct_set(
          asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateContext);
    }

    // Set state target to label after await.
    final StateTarget after = afterTargets[node.parent]!;
    b.local_get(suspendStateLocal);
    b.i32_const(after.index);
    b.struct_set(
        asyncSuspendStateInfo.struct, FieldIndex.asyncSuspendStateTargetIndex);

    b.local_get(suspendStateLocal);
    wrap(node.operand, translator.topInfo.nullableType);
    b.call(translator.functions.getFunction(translator.awaitHelper.reference));
    b.return_();

    // Generate resume label
    _emitTargetLabel(after);

    _restoreContextsAndThis(context);

    // Handle exceptions
    final exceptionBlock = b.block();
    b.local_get(pendingExceptionLocal);
    b.br_on_null(exceptionBlock);

    exceptionHandlers.forEachFinalizer((finalizer, _last) {
      finalizer.setContinuationRethrow(() {
        b.local_get(pendingExceptionLocal);
        b.ref_as_non_null();
      }, () => b.local_get(pendingStackTraceLocal));
    });

    b.local_get(pendingStackTraceLocal);
    b.ref_as_non_null();

    b.throw_(translator.exceptionTag);
    b.end(); // exceptionBlock

    _setVariable(awaitValueVar, () {
      b.local_get(awaitValueLocal);
      translator.convertType(
          function, awaitValueLocal.type, translateType(awaitValueVar.type));
    });
  }

  void _setVariable(VariableDeclaration variable, void pushValue()) {
    final w.Local? local = locals[variable];
    final Capture? capture = closures.captures[variable];
    if (capture != null) {
      assert(capture.written);
      b.local_get(capture.context.currentLocal);
      pushValue();
      b.struct_set(capture.context.struct, capture.fieldIndex);
    } else {
      if (local == null) {
        throw "Write of undefined variable ${variable}";
      }
      pushValue();
      b.local_set(local);
    }
  }

  w.ValueType _getVariable(VariableDeclaration variable) {
    final w.Local? local = locals[variable];
    final Capture? capture = closures.captures[variable];
    if (capture != null) {
      if (!capture.written && local != null) {
        b.local_get(local);
        return local.type;
      } else {
        b.local_get(capture.context.currentLocal);
        b.struct_get(capture.context.struct, capture.fieldIndex);
        return capture.context.struct.fields[capture.fieldIndex].type.unpacked;
      }
    } else {
      if (local == null) {
        throw "Write of undefined variable ${variable}";
      }
      b.local_get(local);
      return local.type;
    }
  }

  /// Same as [_getVariable], but boxes the value if it's not already boxed.
  void _getVariableBoxed(VariableDeclaration variable) {
    final varType = _getVariable(variable);
    translator.convertType(function, varType, translator.topInfo.nullableType);
  }

  void _getCurrentException() {
    b.local_get(suspendStateLocal);
    b.struct_get(asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateCurrentException);
  }

  void _setCurrentException(void Function() emitValue) {
    b.local_get(suspendStateLocal);
    emitValue();
    b.struct_set(asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateCurrentException);
  }

  void _getCurrentExceptionStackTrace() {
    b.local_get(suspendStateLocal);
    b.struct_get(asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateCurrentExceptionStackTrace);
  }

  void _setCurrentExceptionStackTrace(void Function() emitValue) {
    b.local_get(suspendStateLocal);
    emitValue();
    b.struct_set(asyncSuspendStateInfo.struct,
        FieldIndex.asyncSuspendStateCurrentExceptionStackTrace);
  }
}
