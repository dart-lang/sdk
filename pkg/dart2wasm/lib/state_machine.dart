// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'async.dart';
import 'code_generator.dart';

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
enum StateTargetPlacement { Inner, After }

/// Representation of target in the `sync*` control flow graph.
class StateTarget {
  final int index;
  final TreeNode node;
  final StateTargetPlacement placement;

  StateTarget(this.index, this.node, this.placement);

  @override
  String toString() {
    String place = placement == StateTargetPlacement.Inner ? "in" : "after";
    return "$index: $place $node";
  }
}

/// Identify which statements contain `await` or `yield` statements, and assign
/// target indices to all control flow targets of these.
///
/// Target indices are assigned in program order.
class YieldFinder extends RecursiveVisitor {
  final List<StateTarget> targets = [];
  final bool enableAsserts;

  // The number of `await` statements seen so far.
  int yieldCount = 0;

  YieldFinder(this.enableAsserts);

  List<StateTarget> find(FunctionNode function) {
    // Initial state
    addTarget(function.body!, StateTargetPlacement.Inner);
    assert(function.body is Block || function.body is ReturnStatement);
    recurse(function.body!);
    // Final state
    addTarget(function.body!, StateTargetPlacement.After);
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
    yieldCount++;
    recurse(node.body);
    addTarget(node, StateTargetPlacement.Inner);
    recurse(node.finalizer);
    addTarget(node, StateTargetPlacement.After);
  }

  @override
  void visitTryCatch(TryCatch node) {
    // Also always compile [TryCatch] blocks to the CFG to be able to set
    // finalizer continuations.
    yieldCount++;
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
    yieldCount++;
    addTarget(node, StateTargetPlacement.After);
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
        addTarget(value, StateTargetPlacement.After);
        return;
      }
    }

    // Handle top-level awaits.
    if (expression is AwaitExpression) {
      yieldCount++;
      addTarget(node, StateTargetPlacement.After);
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

  final AsyncCodeGenerator codeGen;

  ExceptionHandlerStack(this.codeGen);

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

  void forEachFinalizer(
      void Function(Finalizer finalizer, bool lastFinalizer) f) {
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
  void generateTryBlocks(w.InstructionsBuilder b) {
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
    int nextHandlerIdx = _handlers.length - 1;
    for (final int nCoveredHandlers in _tryBlockNumHandlers.reversed) {
      final stackTraceLocal = codeGen
          .addLocal(codeGen.translator.stackTraceInfo.repr.nonNullableType);

      final exceptionLocal =
          codeGen.addLocal(codeGen.translator.topInfo.nonNullableType);

      void generateCatchBody() {
        // Set continuations of finalizers that can be reached by this `catch`
        // (or `catch_all`) as "rethrow".
        for (int i = 0; i < nCoveredHandlers; i += 1) {
          final handler = _handlers[nextHandlerIdx - i];
          if (handler is Finalizer) {
            handler.setContinuationRethrow(
                () => codeGen.b.local_get(exceptionLocal),
                () => codeGen.b.local_get(stackTraceLocal));
          }
        }

        // Set the untyped "current exception" variable. Catch blocks will do the
        // type tests as necessary using this variable and set their exception
        // and stack trace locals.
        codeGen.setCurrentException(() => codeGen.b.local_get(exceptionLocal));
        codeGen.setCurrentExceptionStackTrace(
            () => codeGen.b.local_get(stackTraceLocal));

        codeGen.jumpToTarget(_handlers[nextHandlerIdx].target);
      }

      codeGen.b.catch_(codeGen.translator.exceptionTag);
      codeGen.b.local_set(stackTraceLocal);
      codeGen.b.local_set(exceptionLocal);

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
        codeGen.b.catch_all();

        // We can't inspect the thrown object in a `catch_all` and get a stack
        // trace, so we just attach the current stack trace.
        codeGen.call(codeGen.translator.stackTraceCurrent.reference);
        codeGen.b.local_set(stackTraceLocal);

        // We create a generic JavaScript error.
        codeGen.call(codeGen.translator.javaScriptErrorFactory.reference);
        codeGen.b.local_set(exceptionLocal);

        generateCatchBody();
      }

      codeGen.b.end(); // end catch

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

class Catcher extends _ExceptionHandler {
  final List<VariableDeclaration> _exceptionVars = [];
  final List<VariableDeclaration> _stackTraceVars = [];
  final AsyncCodeGenerator codeGen;
  bool _canHandleJSExceptions = false;

  Catcher.fromTryCatch(this.codeGen, TryCatch node, super.target) {
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
  final AsyncCodeGenerator codeGen;

  Finalizer(this.codeGen, TryFinally node, this.parentFinalizer, super.target)
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
    codeGen.getVariable(_exceptionVar);
  }

  void pushStackTrace() {
    codeGen.getVariable(_stackTraceVar);
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
