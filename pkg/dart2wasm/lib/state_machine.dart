// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'closures.dart';
import 'code_generator.dart';
import 'translator.dart';

/// Placement of a control flow graph target within a statement. This
/// distinction is necessary since some statements need to have two targets
/// associated with them.
///
/// The meanings of the variants are:
///
///  - [Inner]: Loop entry of a [DoStatement], condition of a [ForStatement] or
///             [WhileStatement], the `else` branch of an [IfStatement], or the
///             initial entry target for a function body.
///
///  - [After]: After a statement, the resumption point of a suspension point
///             ([YieldStatement] or [AwaitExpression]), or the final state
///             (iterator done) of a function body.
enum _StateTargetPlacement { Inner, After }

/// Representation of target in the `sync*` control flow graph.
class StateTarget {
  final int index;
  final TreeNode node;
  final _StateTargetPlacement _placement;

  StateTarget._(this.index, this.node, this._placement);

  @override
  String toString() {
    String place = _placement == _StateTargetPlacement.Inner ? "in" : "after";
    return "$index: $place $node";
  }
}

/// Identify which statements contain `await` or `yield` statements, and assign
/// target indices to all control flow targets of these.
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
    addTarget(function.body!, _StateTargetPlacement.Inner);
    assert(function.body is Block || function.body is ReturnStatement);
    recurse(function.body!);
    // Final state
    addTarget(function.body!, _StateTargetPlacement.After);
    return targets;
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

  void addTarget(TreeNode node, _StateTargetPlacement placement) {
    targets.add(StateTarget._(targets.length, node, placement));
  }

  @override
  void visitBlock(Block node) {
    for (Statement statement in node.statements) {
      recurse(statement);
    }
  }

  @override
  void visitDoStatement(DoStatement node) {
    addTarget(node, _StateTargetPlacement.Inner);
    recurse(node.body);
  }

  @override
  void visitForStatement(ForStatement node) {
    addTarget(node, _StateTargetPlacement.Inner);
    recurse(node.body);
    addTarget(node, _StateTargetPlacement.After);
  }

  @override
  void visitIfStatement(IfStatement node) {
    recurse(node.then);
    if (node.otherwise != null) {
      addTarget(node, _StateTargetPlacement.Inner);
      recurse(node.otherwise!);
    }
    addTarget(node, _StateTargetPlacement.After);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    recurse(node.body);
    addTarget(node, _StateTargetPlacement.After);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    for (SwitchCase c in node.cases) {
      addTarget(c, _StateTargetPlacement.Inner);
      recurse(c.body);
    }
    addTarget(node, _StateTargetPlacement.After);
  }

  @override
  void visitTryFinally(TryFinally node) {
    // [TryFinally] blocks are always compiled to as CFG, even when they don't
    // have awaits. This is to keep the code size small: with normal
    // compilation finalizer blocks need to be duplicated based on
    // continuations, which we don't need in the CFG implementation.
    yieldCount++;
    recurse(node.body);
    addTarget(node, _StateTargetPlacement.Inner);
    recurse(node.finalizer);
    addTarget(node, _StateTargetPlacement.After);
  }

  @override
  void visitTryCatch(TryCatch node) {
    // Also always compile [TryCatch] blocks to the CFG to be able to set
    // finalizer continuations.
    yieldCount++;
    recurse(node.body);
    for (Catch c in node.catches) {
      addTarget(c, _StateTargetPlacement.Inner);
      recurse(c.body);
    }
    addTarget(node, _StateTargetPlacement.After);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    addTarget(node, _StateTargetPlacement.Inner);
    recurse(node.body);
    addTarget(node, _StateTargetPlacement.After);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    yieldCount++;
    addTarget(node, _StateTargetPlacement.After);
  }

  // Handle awaits. After the await transformation await can only appear in a
  // RHS of a top-level assignment, or as a top-level statement.
  @override
  void visitExpressionStatement(ExpressionStatement node) {
    final expression = node.expression;

    // Handle awaits in RHS of assignments.
    if (expression is VariableSet) {
      final value = expression.value;
      if (value is AwaitExpression) {
        yieldCount++;
        addTarget(value, _StateTargetPlacement.After);
        return;
      }
    }

    // Handle top-level awaits.
    if (expression is AwaitExpression) {
      yieldCount++;
      addTarget(node, _StateTargetPlacement.After);
      return;
    }

    super.visitExpressionStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  // Any other await expression means the await transformer is buggy and didn't
  // transform the expression as expected.
  @override
  void visitAwaitExpression(AwaitExpression node) {
    // Await expressions should've been converted to `VariableSet` statements
    // by `_AwaitTransformer`.
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

class ExceptionHandlerStack {
  /// Current exception handler stack. A CFG block generated when this is not
  /// empty should have a Wasm `try` instruction wrapping the block.
  ///
  /// A `catch` block will jump to the next handler on the stack (the last
  /// handler in the list), which then jumps to the next if the exception type
  /// test fails.
  ///
  /// Because CFG blocks for [Catch] blocks and finalizers will have Wasm `try`
  /// blocks for the parent handlers, we can use a Wasm `throw` instruction
  /// (instead of jumping to the parent handler) in [Catch] blocks and
  /// finalizers for rethrowing.
  final List<_ExceptionHandler> _handlers = [];

  /// Maps Wasm `try` blocks to number of handlers in [_handlers] that they
  /// cover for.
  final List<int> _tryBlockNumHandlers = [];

  final StateMachineCodeGenerator codeGen;

  ExceptionHandlerStack(this.codeGen);

  void _pushTryCatch(TryCatch node) {
    final catcher = _Catcher.fromTryCatch(
        codeGen, node, codeGen.innerTargets[node.catches.first]!);
    _handlers.add(catcher);
  }

  Finalizer _pushTryFinally(TryFinally node) {
    final finalizer =
        Finalizer._(codeGen, node, _nextFinalizer, codeGen.innerTargets[node]!);
    _handlers.add(finalizer);
    return finalizer;
  }

  void _pop() {
    _handlers.removeLast();
  }

  int get numHandlers => _handlers.length;

  int get coveredHandlers => _tryBlockNumHandlers.fold(0, (i1, i2) => i1 + i2);

  int get _numFinalizers {
    int i = 0;
    for (final handler in _handlers) {
      if (handler is Finalizer) {
        i += 1;
      }
    }
    return i;
  }

  Finalizer? get _nextFinalizer {
    for (final handler in _handlers.reversed) {
      if (handler is Finalizer) {
        return handler;
      }
    }
    return null;
  }

  void forEachFinalizer(
      void Function(Finalizer finalizer, bool lastFinalizer) f) {
    Finalizer? finalizer = _nextFinalizer;
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
  void _generateTryBlocks(w.InstructionsBuilder b) {
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
  void _terminateTryBlocks() {
    int nextHandlerIdx = _handlers.length - 1;
    final b = codeGen.b;
    for (final int nCoveredHandlers in _tryBlockNumHandlers.reversed) {
      final stackTraceLocal =
          b.addLocal(codeGen.translator.stackTraceInfo.repr.nonNullableType);

      final exceptionLocal =
          b.addLocal(codeGen.translator.topInfo.nonNullableType);

      void generateCatchBody() {
        // Set continuations of finalizers that can be reached by this `catch`
        // (or `catch_all`) as "rethrow".
        for (int i = 0; i < nCoveredHandlers; i += 1) {
          final handler = _handlers[nextHandlerIdx - i];
          if (handler is Finalizer) {
            handler.setContinuationRethrow(() => b.local_get(exceptionLocal),
                () => b.local_get(stackTraceLocal));
          }
        }

        // Set the untyped "current exception" variable. Catch blocks will do the
        // type tests as necessary using this variable and set their exception
        // and stack trace locals.
        codeGen
            .setSuspendStateCurrentException(() => b.local_get(exceptionLocal));
        codeGen.setSuspendStateCurrentStackTrace(
            () => b.local_get(stackTraceLocal));

        codeGen._jumpToTarget(_handlers[nextHandlerIdx].target);
      }

      b.catch_(codeGen.translator.exceptionTag);
      b.local_set(stackTraceLocal);
      b.local_set(exceptionLocal);

      generateCatchBody();

      // Generate a `catch_all` to catch JS exceptions if any of the covered
      // handlers can catch JS exceptions.
      bool canHandleJSExceptions = false;
      for (int handlerIdx = nextHandlerIdx;
          handlerIdx > nextHandlerIdx - nCoveredHandlers;
          handlerIdx -= 1) {
        final handler = _handlers[handlerIdx];
        canHandleJSExceptions |= handler.canHandleJSExceptions;
      }

      if (canHandleJSExceptions) {
        b.catch_all();

        // We can't inspect the thrown object in a `catch_all` and get a stack
        // trace, so we just attach the current stack trace.
        codeGen.call(codeGen.translator.stackTraceCurrent.reference);
        b.local_set(stackTraceLocal);

        // We create a generic JavaScript error.
        codeGen.call(codeGen.translator.javaScriptErrorFactory.reference);
        b.local_set(exceptionLocal);

        generateCatchBody();
      }

      b.end(); // end catch

      nextHandlerIdx -= nCoveredHandlers;
    }

    _tryBlockNumHandlers.clear();
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

  bool get canHandleJSExceptions;
}

class _Catcher extends _ExceptionHandler {
  final List<VariableDeclaration> _exceptionVars = [];
  final List<VariableDeclaration> _stackTraceVars = [];
  final StateMachineCodeGenerator codeGen;
  bool _canHandleJSExceptions = false;

  _Catcher.fromTryCatch(this.codeGen, TryCatch node, super.target) {
    for (Catch catch_ in node.catches) {
      _exceptionVars.add(catch_.exception!);
      _stackTraceVars.add(catch_.stackTrace!);
      _canHandleJSExceptions |=
          guardCanMatchJSException(codeGen.translator, catch_.guard);
    }
  }

  @override
  bool get canHandleJSExceptions => _canHandleJSExceptions;

  void setException(void Function() pushException) {
    for (final exceptionVar in _exceptionVars) {
      codeGen.setVariable(exceptionVar, pushException);
    }
  }

  void setStackTrace(void Function() pushStackTrace) {
    for (final stackTraceVar in _stackTraceVars) {
      codeGen.setVariable(stackTraceVar, pushStackTrace);
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
  final StateMachineCodeGenerator codeGen;

  Finalizer._(this.codeGen, TryFinally node, this.parentFinalizer, super.target)
      : _continuationVar =
            (node.parent as Block).statements[0] as VariableDeclaration,
        _exceptionVar =
            (node.parent as Block).statements[1] as VariableDeclaration,
        _stackTraceVar =
            (node.parent as Block).statements[2] as VariableDeclaration;

  @override
  bool get canHandleJSExceptions => true;

  void setContinuationFallthrough() {
    codeGen.setVariable(_continuationVar, () {
      codeGen.b.i64_const(continuationFallthrough);
    });
  }

  void setContinuationReturn() {
    codeGen.setVariable(_continuationVar, () {
      codeGen.b.i64_const(continuationReturn);
    });
  }

  void setContinuationRethrow(
      void Function() pushException, void Function() pushStackTrace) {
    codeGen.setVariable(_continuationVar, () {
      codeGen.b.i64_const(continuationRethrow);
    });
    codeGen.setVariable(_exceptionVar, pushException);
    codeGen.setVariable(_stackTraceVar, pushStackTrace);
  }

  void setContinuationJump(int index) {
    codeGen.setVariable(_continuationVar, () {
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
  void jump(StateMachineCodeGenerator codeGen);
}

/// Target of a [BreakStatement] that can be implemented with a Wasm `br`
/// instruction.
///
/// This [LabelTarget] is used when the [LabeledStatement] is compiled using
/// the normal code generator (instead of async code generator).
class _DirectLabelTarget implements LabelTarget {
  final w.Label label;

  _DirectLabelTarget(this.label);

  @override
  void jump(StateMachineCodeGenerator codeGen) {
    codeGen.b.br(label);
  }
}

/// Target of a [BreakStatement] when the [LabeledStatement] is compiled to
/// CFG.
class _IndirectLabelTarget implements LabelTarget {
  /// Number of finalizers wrapping the [LabeledStatement].
  final int finalizerDepth;

  /// CFG state for the [LabeledStatement] continuation.
  final StateTarget stateTarget;

  _IndirectLabelTarget(this.finalizerDepth, this.stateTarget);

  @override
  void jump(StateMachineCodeGenerator codeGen) {
    final currentFinalizerDepth = codeGen.exceptionHandlers._numFinalizers;
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
      codeGen._jumpToTarget(stateTarget);
    } else {
      codeGen._jumpToTarget(codeGen.exceptionHandlers._nextFinalizer!.target);
    }
  }
}

/// Exception and stack trace variables of a [Catch] block. These variables are
/// used to get the exception and stack trace to throw when compiling
/// [Rethrow].
class CatchVariables {
  final VariableDeclaration exception;
  final VariableDeclaration stackTrace;

  CatchVariables._(this.exception, this.stackTrace);
}

abstract class StateMachineEntryAstCodeGenerator extends AstCodeGenerator {
  final w.FunctionBuilder function;
  StateMachineEntryAstCodeGenerator(
      Translator translator, Member enclosingMember, this.function)
      : super(translator, function.type, enclosingMember);

  /// Generate the outer function.
  ///
  /// - Outer function: the `async` or `sync*` function.
  ///
  ///   In case of `async` this function should return a future.
  ///
  ///   In case of `sync*`, this function should return an iterable.
  ///
  void generateOuter(
      FunctionNode functionNode, Context? context, Source functionSource);
}

abstract class ProcedureStateMachineEntryCodeGenerator
    extends StateMachineEntryAstCodeGenerator {
  final Procedure member;

  ProcedureStateMachineEntryCodeGenerator(
      Translator translator, w.FunctionBuilder function, this.member)
      : super(translator, member, function);

  @override
  void generateInternal() {
    final source = member.enclosingComponent!.uriToSource[member.fileUri]!;
    closures = Closures(translator, member);
    setSourceMapSource(source);
    setSourceMapFileOffset(member.fileOffset);

    // We don't support inlining state machine functions atm. Only when we
    // inline and have call-site guarantees we would use the unchecked entry.
    setupParametersAndContexts(member, useUncheckedEntry: false);

    Context? context = closures.contexts[member.function];
    if (context != null && context.isEmpty) context = context.parent;

    generateOuter(member.function, context, source);
    addNestedClosuresToCompilationQueue();
  }
}

abstract class LambdaStateMachineEntryCodeGenerator
    extends StateMachineEntryAstCodeGenerator {
  final Lambda lambda;

  LambdaStateMachineEntryCodeGenerator(Translator translator,
      Member enclosingMember, this.lambda, Closures closures)
      : super(translator, enclosingMember, lambda.function) {
    this.closures = closures;
  }

  @override
  void generateInternal() {
    final source = lambda.functionNodeSource;
    setSourceMapSource(source);
    setSourceMapFileOffset(lambda.functionNode.fileOffset);
    setupLambdaParametersAndContexts(lambda);

    Context? context = closures.contexts[lambda.functionNode];
    if (context != null && context.isEmpty) context = context.parent;

    generateOuter(lambda.functionNode, context, source);
  }
}

/// A [CodeGenerator] that compiles the function to a state machine based on
/// the suspension points in the function (`await` expressions and `yield`
/// statements).
///
/// This is used to compile `async` and `sync*` functions.
abstract class StateMachineCodeGenerator extends AstCodeGenerator {
  final w.FunctionBuilder function;
  final FunctionNode functionNode;
  final Source functionSource;

  StateMachineCodeGenerator(
      Translator translator,
      this.function,
      Member enclosingMember,
      this.functionNode,
      this.functionSource,
      Closures closures)
      : super(translator, function.type, enclosingMember) {
    this.closures = closures;
  }

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

  /// The local for the CFG target block index.
  late final w.Local targetIndexLocal;

  /// Exception handlers wrapping the current CFG block. Used to generate Wasm
  /// `try` and `catch` blocks around the CFG blocks.
  late final ExceptionHandlerStack exceptionHandlers;

  /// Maps jump targets to their CFG targets. Used when jumping to a CFG block
  /// on `break`. Keys are [LabeledStatement]s or [SwitchCase]s.
  final Map<TreeNode, LabelTarget> labelTargets = {};

  /// Current [Catch] block stack, used to compile [Rethrow].
  ///
  /// Because there can be an `await` in a [Catch] block before a [Rethrow], we
  /// can't compile [Rethrow] to Wasm `rethrow`. Instead we `throw` using the
  /// [Rethrow]'s parent [Catch] block's exception and stack variables.
  List<CatchVariables> catchVariableStack = [];

  @override
  void generateInternal() {
    setSourceMapSource(functionSource);
    setSourceMapFileOffset(functionNode.fileOffset);

    // Number and categorize CFG targets.
    targets = _YieldFinder(translator.options.enableAsserts).find(functionNode);
    for (final target in targets) {
      switch (target._placement) {
        case _StateTargetPlacement.Inner:
          innerTargets[target.node] = target;
          break;
        case _StateTargetPlacement.After:
          afterTargets[target.node] = target;
          break;
      }
    }

    exceptionHandlers = ExceptionHandlerStack(this);

    Context? context = closures.contexts[functionNode];
    if (context != null && context.isEmpty) context = context.parent;

    generateInner(functionNode, context);
  }

  /// Store the exception value emitted by [emitValue] in suspension state.
  /// [getSuspendStateCurrentException] should return the value even after
  /// suspending the function and continuing it later.
  void setSuspendStateCurrentException(void Function() emitValue);

  /// Get the value set by [setSuspendStateCurrentException].
  void getSuspendStateCurrentException();

  /// Same as [setSuspendStateCurrentException], but for the exception stack
  /// trace.
  void setSuspendStateCurrentStackTrace(void Function() emitValue);

  /// Same as [getSuspendStateCurrentException], but for the exception stack
  /// trace.
  void getSuspendStateCurrentStackTrace();

  /// Store the return value emitted by [emitValue] in suspension state.
  /// [getSuspendStateReturnValue] should return the value ven after suspending
  /// the function and continuing it later.
  void setSuspendStateCurrentReturnValue(void Function() emitValue);

  /// Get the value set by [setSuspendStateCurrentReturnValue].
  void getSuspendStateCurrentReturnValue();

  /// Generate a return from the function. For `async` functions, this should
  /// call the completer and return. For `sync*`, this should terminate
  /// iteration by returning `false`.
  void emitReturn(void Function() emitValue);

  /// Generate the inner functions.
  ///
  /// - Inner function: the function that will be called for resumption.
  void generateInner(FunctionNode functionNode, Context? context);

  void emitTargetLabel(StateTarget target) {
    currentTargetIndex++;
    assert(
        target.index == currentTargetIndex,
        'target.index = ${target.index}, '
        'currentTargetIndex = $currentTargetIndex, '
        'target.node.location = ${target.node.location}');
    exceptionHandlers._terminateTryBlocks();
    b.end();
    exceptionHandlers._generateTryBlocks(b);
  }

  void _jumpToTarget(StateTarget target,
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
    _jumpToTarget(inner, condition: node.condition);
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
    _jumpToTarget(after, condition: node.condition, negated: true);
    visitStatement(node.body);

    emitForStatementUpdate(node);

    _jumpToTarget(inner);
    emitTargetLabel(after);
  }

  @override
  void visitIfStatement(IfStatement node) {
    StateTarget? after = afterTargets[node];
    if (after == null) return super.visitIfStatement(node);
    StateTarget? inner = innerTargets[node];

    _jumpToTarget(inner ?? after, condition: node.condition, negated: true);
    visitStatement(node.then);
    if (node.otherwise != null) {
      _jumpToTarget(after);
      emitTargetLabel(inner!);
      visitStatement(node.otherwise!);
    }
    emitTargetLabel(after);
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    StateTarget? after = afterTargets[node];
    if (after == null) {
      final w.Label label = b.block();
      labelTargets[node] = _DirectLabelTarget(label);
      visitStatement(node.body);
      labelTargets.remove(node);
      b.end();
    } else {
      labelTargets[node] =
          _IndirectLabelTarget(exceptionHandlers._numFinalizers, after);
      visitStatement(node.body);
      labelTargets.remove(node);
      emitTargetLabel(after);
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
      _jumpToTarget(nullTarget);
      b.end();
      b.local_get(switchValueNullableLocal);
      b.ref_as_non_null();
      // Unbox if necessary
      translator.convertType(
          b, switchValueNullableLocal.type, switchValueNonNullableLocal.type);
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
          switchInfo.compare(
            switchValueNonNullableLocal,
            () => wrap(exp, switchInfo.nonNullableType),
          );
          b.if_();
          _jumpToTarget(innerTargets[c]!);
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
      _jumpToTarget(defaultLabel);
    }

    // Add jump infos
    for (final SwitchCase case_ in node.cases) {
      labelTargets[case_] = _IndirectLabelTarget(
          exceptionHandlers._numFinalizers, innerTargets[case_]!);
    }

    // Emit case bodies
    for (SwitchCase c in node.cases) {
      emitTargetLabel(innerTargets[c]!);
      visitStatement(c.body);
      _jumpToTarget(after);
    }

    // Remove jump infos
    for (final SwitchCase case_ in node.cases) {
      labelTargets.remove(case_);
    }

    emitTargetLabel(after);
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

    exceptionHandlers._pushTryCatch(node);
    exceptionHandlers._generateTryBlocks(b);
    visitStatement(node.body);
    _jumpToTarget(after);
    exceptionHandlers._terminateTryBlocks();
    exceptionHandlers._pop();

    void emitCatchBlock(Catch catch_, Catch? nextCatch, bool emitGuard) {
      if (emitGuard) {
        getSuspendStateCurrentException();
        b.ref_as_non_null();
        types.emitIsTest(this, catch_.guard,
            translator.coreTypes.objectNonNullableRawType, catch_.location);
        b.i32_eqz();
        // When generating guards we can't generate the catch body inside the
        // `if` block for the guard as the catch body can have suspension
        // points and generate target labels.
        b.if_();
        if (nextCatch != null) {
          _jumpToTarget(innerTargets[nextCatch]!);
        } else {
          // Rethrow.
          getSuspendStateCurrentException();
          b.ref_as_non_null();
          getSuspendStateCurrentStackTrace();
          b.ref_as_non_null();
          // TODO (omersa): When there is a finalizer we can jump to it
          // directly, instead of via throw/catch. Would that be faster?
          exceptionHandlers.forEachFinalizer(
              (finalizer, last) => finalizer.setContinuationRethrow(
                    () => _getVariableBoxed(catch_.exception!),
                    () => _getVariable(catch_.stackTrace!),
                  ));
          b.throw_(translator.exceptionTag);
        }
        b.end();
      }

      // Set exception and stack trace variables.
      setVariable(catch_.exception!, () {
        getSuspendStateCurrentException();
        // Type test already passed, convert the exception.
        translator.convertType(b, translator.topInfo.nullableType,
            translator.translateType(catch_.exception!.type));
      });
      setVariable(catch_.stackTrace!, () => getSuspendStateCurrentStackTrace());

      catchVariableStack
          .add(CatchVariables._(catch_.exception!, catch_.stackTrace!));

      visitStatement(catch_.body);

      catchVariableStack.removeLast();

      _jumpToTarget(after);
    }

    for (int catchIdx = 0; catchIdx < node.catches.length; catchIdx += 1) {
      final Catch catch_ = node.catches[catchIdx];

      final nextCatchIdx = catchIdx + 1;
      final Catch? nextCatch = nextCatchIdx < node.catches.length
          ? node.catches[nextCatchIdx]
          : null;

      emitTargetLabel(innerTargets[catch_]!);

      final bool shouldEmitGuard =
          catch_.guard != translator.coreTypes.objectNonNullableRawType;

      emitCatchBlock(catch_, nextCatch, shouldEmitGuard);

      if (!shouldEmitGuard) {
        break;
      }
    }

    // Rethrow. Note that we don't override finalizer continuations here, they
    // should be set by the original `throw` site.
    getSuspendStateCurrentException();
    b.ref_as_non_null();
    getSuspendStateCurrentStackTrace();
    b.ref_as_non_null();
    b.throw_(translator.exceptionTag);

    emitTargetLabel(after);
  }

  @override
  void visitTryFinally(TryFinally node) {
    allocateContext(node);

    final StateTarget finalizerTarget = innerTargets[node]!;
    final StateTarget fallthroughContinuationTarget = afterTargets[node]!;

    // Body
    final finalizer = exceptionHandlers._pushTryFinally(node);
    exceptionHandlers._generateTryBlocks(b);
    visitStatement(node.body);

    // Set continuation of the finalizer.
    finalizer.setContinuationFallthrough();

    _jumpToTarget(finalizerTarget);
    exceptionHandlers._terminateTryBlocks();
    exceptionHandlers._pop();

    // Finalizer
    {
      emitTargetLabel(finalizerTarget);
      visitStatement(node.finalizer);

      // Check continuation.

      // Fallthrough
      assert(continuationFallthrough == 0); // update eqz below if changed
      finalizer.pushContinuation();
      b.i32_eqz();
      b.if_();
      _jumpToTarget(fallthroughContinuationTarget);
      b.end();

      // Return
      finalizer.pushContinuation();
      b.i32_const(continuationReturn);
      b.i32_eq();
      b.if_();
      emitReturn(() => getSuspendStateCurrentReturnValue());
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

    emitTargetLabel(fallthroughContinuationTarget);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    StateTarget? inner = innerTargets[node];
    if (inner == null) return super.visitWhileStatement(node);
    StateTarget after = afterTargets[node]!;

    allocateContext(node);
    emitTargetLabel(inner);
    _jumpToTarget(after, condition: node.condition, negated: true);
    visitStatement(node.body);
    _jumpToTarget(inner);
    emitTargetLabel(after);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    // This should be overriddenin `sync*` code generator.
    throw 'Unexpected yield statement: $node (${node.location})';
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    final Finalizer? firstFinalizer = exceptionHandlers._nextFinalizer;
    final value = node.expression;

    if (firstFinalizer == null) {
      emitReturn(() {
        if (value == null) {
          b.ref_null(translator.topInfo.struct);
        } else {
          wrap(value, translator.topInfo.nullableType);
        }
      });
      return;
    }

    if (value == null) {
      b.ref_null(translator.topInfo.struct);
    } else {
      wrap(value, translator.topInfo.nullableType);
    }

    final returnValueLocal = addLocal(translator.topInfo.nullableType);
    b.local_set(returnValueLocal);

    // Set return value for the last finalizer to return.
    setSuspendStateCurrentReturnValue(() => b.local_get(returnValueLocal));

    // Update continuation variables of finalizers. Last finalizer returns
    // the value.
    exceptionHandlers.forEachFinalizer((finalizer, last) {
      if (last) {
        finalizer.setContinuationReturn();
      } else {
        finalizer.setContinuationJump(finalizer.parentFinalizer!.target.index);
      }
    });

    // Jump to the first finalizer
    _jumpToTarget(firstFinalizer.target);
  }

  @override
  w.ValueType visitThrow(Throw node, w.ValueType expectedType) {
    final exceptionLocal = addLocal(translator.topInfo.nonNullableType);
    wrap(node.expression, translator.topInfo.nonNullableType);
    b.local_set(exceptionLocal);

    final stackTraceLocal =
        addLocal(translator.stackTraceInfo.repr.nonNullableType);
    call(translator.stackTraceCurrent.reference);
    b.local_set(stackTraceLocal);

    exceptionHandlers.forEachFinalizer((finalizer, last) {
      finalizer.setContinuationRethrow(() => b.local_get(exceptionLocal),
          () => b.local_get(stackTraceLocal));
    });

    // TODO (omersa): An alternative would be to directly jump to the parent
    // handler, or call `completeOnError` if we're not in a try-catch or
    // try-finally. Would that be more efficient?
    b.local_get(exceptionLocal);
    b.local_get(stackTraceLocal);
    call(translator.errorThrow.reference);

    b.unreachable();
    return expectedType;
  }

  @override
  w.ValueType visitRethrow(Rethrow node, w.ValueType expectedType) {
    final catchVars = catchVariableStack.last;

    exceptionHandlers.forEachFinalizer((finalizer, last) {
      finalizer.setContinuationRethrow(
        () => _getVariableBoxed(catchVars.exception),
        () => _getVariable(catchVars.stackTrace),
      );
    });

    // TODO (omersa): Similar to `throw` compilation above, we could directly
    // jump to the target block or call `completeOnError`.
    getSuspendStateCurrentException();
    b.ref_as_non_null();
    getSuspendStateCurrentStackTrace();
    b.ref_as_non_null();
    b.throw_(translator.exceptionTag);
    b.unreachable();
    return expectedType;
  }

  /// Similar to the [VariableSet] visitor, but the value is pushed to the
  /// stack by the callback [pushValue].
  void setVariable(VariableDeclaration variable, void Function() pushValue) {
    final w.Local? local = locals[variable];
    final Capture? capture = closures.captures[variable];
    if (capture != null) {
      assert(capture.written);
      b.local_get(capture.context.currentLocal);
      pushValue();
      b.struct_set(capture.context.struct, capture.fieldIndex);
    } else {
      if (local == null) {
        throw "Write of undefined variable $variable";
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
        throw "Write of undefined variable $variable";
      }
      b.local_get(local);
      return local.type;
    }
  }

  /// Same as [_getVariable], but boxes the value if it's not already boxed.
  void _getVariableBoxed(VariableDeclaration variable) {
    final varType = _getVariable(variable);
    translator.convertType(b, varType, translator.topInfo.nullableType);
  }
}
