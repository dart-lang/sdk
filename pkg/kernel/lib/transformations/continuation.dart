// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.continuation;

import 'dart:math' as math;

import '../ast.dart';
import '../visitor.dart';

import 'async.dart';

Program transformProgram(Program program) {
  var helper = new HelperNodes.fromProgram(program);
  var rewriter = new RecursiveContinuationRewriter(helper);
  return rewriter.rewriteProgram(program);
}

class RecursiveContinuationRewriter extends Transformer {
  final HelperNodes helper;
  final VariableDeclaration asyncJumpVariable = new VariableDeclaration(
      ":await_jump_var",
      initializer: new IntLiteral(0));
  final VariableDeclaration asyncContextVariable =
      new VariableDeclaration(":await_ctx_var");

  RecursiveContinuationRewriter(this.helper);

  Program rewriteProgram(Program node) {
    return node.accept(this);
  }

  visitFunctionNode(FunctionNode node) {
    switch (node.asyncMarker) {
      case AsyncMarker.Sync:
      case AsyncMarker.SyncYielding:
        node.transformChildren(new RecursiveContinuationRewriter(helper));
        return node;
      case AsyncMarker.SyncStar:
        return new SyncStarFunctionRewriter(helper, node).rewrite();
      case AsyncMarker.Async:
        return new AsyncFunctionRewriter(helper, node).rewrite();
      case AsyncMarker.AsyncStar:
        return new AsyncStarFunctionRewriter(helper, node).rewrite();
    }
  }
}

abstract class ContinuationRewriterBase extends RecursiveContinuationRewriter {
  final FunctionNode enclosingFunction;

  int currentTryDepth; // Nesting depth for try-blocks.
  int currentCatchDepth = 0; // Nesting depth for catch-blocks.
  int capturedTryDepth = 0; // Deepest yield point within a try-block.
  int capturedCatchDepth = 0; // Deepest yield point within a catch-block.

  ContinuationRewriterBase(HelperNodes helper, this.enclosingFunction,
      {this.currentTryDepth: 0})
      : super(helper);

  Statement createContinuationPoint([Expression value]) {
    if (value == null) value = new NullLiteral();
    capturedTryDepth = math.max(capturedTryDepth, currentTryDepth);
    capturedCatchDepth = math.max(capturedCatchDepth, currentCatchDepth);
    return new YieldStatement(value, isNative: true);
  }

  TreeNode visitTryCatch(TryCatch node) {
    if (node.body != null) {
      currentTryDepth++;
      node.body = node.body.accept(this);
      node.body?.parent = node;
      currentTryDepth--;
    }

    currentCatchDepth++;
    transformList(node.catches, this, node);
    currentCatchDepth--;
    return node;
  }

  TreeNode visitTryFinally(TryFinally node) {
    if (node.body != null) {
      currentTryDepth++;
      node.body = node.body.accept(this);
      node.body?.parent = node;
      currentTryDepth--;
    }
    if (node.finalizer != null) {
      node.finalizer = node.finalizer.accept(this);
      node.finalizer?.parent = node;
    }
    return node;
  }

  Iterable<VariableDeclaration> createCapturedTryVariables() =>
      new Iterable.generate(capturedTryDepth,
          (depth) => new VariableDeclaration(":saved_try_context_var${depth}"));

  Iterable<VariableDeclaration> createCapturedCatchVariables() =>
      new Iterable.generate(capturedCatchDepth).expand((depth) => [
            new VariableDeclaration(":exception${depth}"),
            new VariableDeclaration(":stack_trace${depth}"),
          ]);

  List<VariableDeclaration> variableDeclarations() =>
      [asyncJumpVariable, asyncContextVariable]
        ..addAll(createCapturedTryVariables())
        ..addAll(createCapturedCatchVariables());
}

class SyncStarFunctionRewriter extends ContinuationRewriterBase {
  final VariableDeclaration iteratorVariable =
      new VariableDeclaration(":iterator");

  SyncStarFunctionRewriter(helper, enclosingFunction)
      : super(helper, enclosingFunction);

  FunctionNode rewrite() {
    // :sync_body(:iterator) {
    //     modified <node.body>;
    // }
    final nestedClosureVariable = new VariableDeclaration(":sync_op");
    final function = new FunctionNode(buildClosureBody(),
        positionalParameters: [iteratorVariable],
        requiredParameterCount: 1,
        asyncMarker: AsyncMarker.SyncYielding);
    final closureFunction =
        new FunctionDeclaration(nestedClosureVariable, function);

    // return new _SyncIterable(:sync_body);
    final arguments = new Arguments([new VariableGet(nestedClosureVariable)]);
    final returnStatement = new ReturnStatement(
        new ConstructorInvocation(helper.syncIterableConstructor, arguments));

    enclosingFunction.body = new Block([]
      ..addAll(variableDeclarations())
      ..addAll([closureFunction, returnStatement]));
    enclosingFunction.body.parent = enclosingFunction;
    enclosingFunction.asyncMarker = AsyncMarker.Sync;
    return enclosingFunction;
  }

  Statement buildClosureBody() {
    // The body will insert calls to
    //    :iterator.current_=
    //    :iterator.isYieldEach=
    // and return `true` as long as it did something and `false` when it's done.
    return enclosingFunction.body.accept(this);
  }

  visitYieldStatement(YieldStatement node) {
    var transformedExpression = node.expression.accept(this);

    var statements = <Statement>[];
    if (node.isYieldStar) {
      var markYieldEach = new ExpressionStatement(new PropertySet(
          new VariableGet(iteratorVariable),
          new Name("isYieldEach", helper.coreLibrary),
          new BoolLiteral(true)));
      statements.add(markYieldEach);
    }

    var setCurrentIteratorValue = new ExpressionStatement(new PropertySet(
        new VariableGet(iteratorVariable),
        new Name("_current", helper.coreLibrary),
        transformedExpression));

    statements.add(setCurrentIteratorValue);
    statements.add(createContinuationPoint(new BoolLiteral(true)));
    return new Block(statements);
  }
}

abstract class AsyncRewriterBase extends ContinuationRewriterBase {
  final VariableDeclaration nestedClosureVariable =
      new VariableDeclaration(":async_op");
  final VariableDeclaration thenContinuationVariable =
      new VariableDeclaration(":async_op_then");
  final VariableDeclaration catchErrorContinuationVariable =
      new VariableDeclaration(":async_op_error");

  LabeledStatement labeledBody;

  ExpressionLifter expressionRewriter;

  AsyncRewriterBase(helper, enclosingFunction)
      // Body is wrapped in the try-catch so initial currentTryDepth is 1.
      : super(helper, enclosingFunction, currentTryDepth: 1) {}

  void setupAsyncContinuations(List<Statement> statements) {
    expressionRewriter = new ExpressionLifter(this);

    // var :async_op_then;
    statements.add(thenContinuationVariable);

    // var :async_op_error;
    statements.add(catchErrorContinuationVariable);

    // :async_op([:result, :exception, :stack_trace]) {
    //     modified <node.body>;
    // }
    final parameters = <VariableDeclaration>[
      expressionRewriter.asyncResult,
      new VariableDeclaration(':exception'),
      new VariableDeclaration(':stack_trace'),
    ];
    final function = new FunctionNode(buildWrappedBody(),
        positionalParameters: parameters,
        requiredParameterCount: 0,
        asyncMarker: AsyncMarker.SyncYielding);

    // The await expression lifter might have created a number of
    // [VariableDeclarations].
    // TODO(kustermann): If we didn't need any variables we should not emit
    // these.
    statements.addAll(variableDeclarations());
    statements.addAll(expressionRewriter.variables);

    // Now add the closure function itself.
    final closureFunction =
        new FunctionDeclaration(nestedClosureVariable, function);
    statements.add(closureFunction);

    // :async_op_then = _asyncThenWrapperHelper(asyncBody);
    final boundThenClosure = new StaticInvocation(helper.asyncThenWrapper,
        new Arguments(<Expression>[new VariableGet(nestedClosureVariable)]));
    final thenClosureVariableAssign = new ExpressionStatement(
        new VariableSet(thenContinuationVariable, boundThenClosure));
    statements.add(thenClosureVariableAssign);

    // :async_op_error = _asyncErrorWrapperHelper(asyncBody);
    final boundCatchErrorClosure = new StaticInvocation(
        helper.asyncErrorWrapper,
        new Arguments(<Expression>[new VariableGet(nestedClosureVariable)]));
    final catchErrorClosureVariableAssign = new ExpressionStatement(
        new VariableSet(
            catchErrorContinuationVariable, boundCatchErrorClosure));
    statements.add(catchErrorClosureVariableAssign);
  }

  Statement buildWrappedBody() {
    labeledBody = new LabeledStatement(null);
    labeledBody.body = visitDelimited(enclosingFunction.body)
      ..parent = labeledBody;

    var exceptionVariable = new VariableDeclaration(":exception");
    var stackTraceVariable = new VariableDeclaration(":stack_trace");

    return new TryCatch(buildReturn(labeledBody), <Catch>[
      new Catch(
          exceptionVariable,
          new Block(<Statement>[
            buildCatchBody(exceptionVariable, stackTraceVariable)
          ]),
          stackTrace: stackTraceVariable)
    ]);
  }

  Statement buildCatchBody(
      Statement exceptionVariable, Statement stackTraceVariable);

  Statement buildReturn(Statement body);

  List<Statement> statements = <Statement>[];

  TreeNode visitInvalidStatement(InvalidStatement stmt) {
    statements.add(stmt);
    return null;
  }

  TreeNode visitExpressionStatement(ExpressionStatement stmt) {
    stmt.expression = expressionRewriter.rewrite(stmt.expression, statements)
      ..parent = stmt;
    statements.add(stmt);
    return null;
  }

  TreeNode visitBlock(Block stmt) {
    var saved = statements;
    statements = <Statement>[];
    for (var statement in stmt.statements) {
      statement.accept(this);
    }
    saved.add(new Block(statements));
    statements = saved;
    return null;
  }

  TreeNode visitEmptyStatement(EmptyStatement stmt) {
    statements.add(stmt);
    return null;
  }

  TreeNode visitAssertStatement(AssertStatement stmt) {
    // TODO!
    return null;
  }

  Statement visitDelimited(Statement stmt) {
    var saved = statements;
    statements = <Statement>[];
    stmt.accept(this);
    Statement result =
        statements.length == 1 ? statements.first : new Block(statements);
    statements = saved;
    return result;
  }

  Statement visitLabeledStatement(LabeledStatement stmt) {
    stmt.body = visitDelimited(stmt.body)..parent = stmt;
    statements.add(stmt);
    return null;
  }

  Statement visitBreakStatement(BreakStatement stmt) {
    statements.add(stmt);
    return null;
  }

  TreeNode visitWhileStatement(WhileStatement stmt) {
    Statement body = visitDelimited(stmt.body);
    List<Statement> effects = <Statement>[];
    Expression cond = expressionRewriter.rewrite(stmt.condition, effects);
    if (effects.isEmpty) {
      stmt.condition = cond..parent = stmt;
      stmt.body = body..parent = stmt;
      statements.add(stmt);
    } else {
      // The condition rewrote to a non-empty sequence of statements S* and
      // value V.  Rewrite the loop to:
      //
      // L: while (true) {
      //   S*
      //   if (V) {
      //     [body]
      //   else {
      //     break L;
      //   }
      // }
      LabeledStatement labeled = new LabeledStatement(stmt);
      stmt.condition = new BoolLiteral(true)..parent = stmt;
      effects.add(new IfStatement(cond, body, new BreakStatement(labeled)));
      stmt.body = new Block(effects)..parent = stmt;
      statements.add(labeled);
    }
    return null;
  }

  TreeNode visitDoStatement(DoStatement stmt) {
    Statement body = visitDelimited(stmt.body);
    List<Statement> effects = <Statement>[];
    stmt.condition = expressionRewriter.rewrite(stmt.condition, effects)
      ..parent = stmt;
    if (effects.isNotEmpty) {
      // The condition rewrote to a non-empty sequence of statements S* and
      // value V.  Add the statements to the end of the loop body.
      Block block = body is Block ? body : body = new Block(<Statement>[body]);
      for (var effect in effects) {
        block.statements.add(effect);
        effect.parent = body;
      }
    }
    stmt.body = body..parent = stmt;
    statements.add(stmt);
    return null;
  }

  TreeNode visitForStatement(ForStatement stmt) {
    // Because of for-loop scoping and variable capture, it is tricky to deal
    // with await in the loop's variable initializers or update expressions.
    bool isSimple = true;
    int length = stmt.variables.length;
    List<List<Statement>> initEffects = new List<List<Statement>>(length);
    for (int i = 0; i < length; ++i) {
      VariableDeclaration decl = stmt.variables[i];
      initEffects[i] = <Statement>[];
      if (decl.initializer != null) {
        decl.initializer = expressionRewriter.rewrite(
            decl.initializer, initEffects[i])..parent = decl;
      }
      isSimple = isSimple && initEffects[i].isEmpty;
    }

    length = stmt.updates.length;
    List<List<Statement>> updateEffects = new List<List<Statement>>(length);
    for (int i = 0; i < length; ++i) {
      updateEffects[i] = <Statement>[];
      stmt.updates[i] = expressionRewriter.rewrite(
          stmt.updates[i], updateEffects[i])..parent = stmt;
      isSimple = isSimple && updateEffects[i].isEmpty;
    }

    Statement body = visitDelimited(stmt.body);
    Expression cond = stmt.condition;
    List<Statement> condEffects;
    if (cond != null) {
      condEffects = <Statement>[];
      cond = expressionRewriter.rewrite(stmt.condition, condEffects);
    }

    if (isSimple) {
      // If the condition contains await, we use a translation like the one for
      // while loops, but leaving the variable declarations and the update
      // expressions in place.
      if (condEffects == null || condEffects.isEmpty) {
        if (cond != null) stmt.condition = cond..parent = stmt;
        stmt.body = body..parent = stmt;
        statements.add(stmt);
      } else {
        LabeledStatement labeled = new LabeledStatement(stmt);
        // No condition in a for loop is the same as true.
        stmt.condition = null;
        condEffects
            .add(new IfStatement(cond, body, new BreakStatement(labeled)));
        stmt.body = new Block(condEffects)..parent = stmt;
        statements.add(labeled);
      }
      return null;
    }

    // If the rewrite of the initializer or update expressions produces a
    // non-empty sequence of statements then the loop is desugared.  If the loop
    // has the form:
    //
    // label: for (Type x = init; cond; update) body
    //
    // it is translated as if it were:
    //
    // {
    //   bool first = true;
    //   Type temp;
    //   label: while (true) {
    //     Type x;
    //     if (first) {
    //       first = false;
    //       x = init;
    //     } else {
    //       x = temp;
    //       update;
    //     }
    //     if (cond) {
    //       body;
    //       temp = x;
    //     } else {
    //       break;
    //     }
    //   }
    // }

    // Place the loop variable declarations at the beginning of the body
    // statements and move their initializers to a guarded list of statements.
    // Add assignments to the loop variables from the previous iteration's temp
    // variables before the updates.
    //
    // temps.first is the flag 'first'.
    // TODO(kmillikin) bool type for first.
    List<VariableDeclaration> temps = <VariableDeclaration>[
      new VariableDeclaration.forValue(new BoolLiteral(true), isFinal: false)
    ];
    List<Statement> loopBody = <Statement>[];
    List<Statement> initializers = <Statement>[
      new ExpressionStatement(
          new VariableSet(temps.first, new BoolLiteral(false)))
    ];
    List<Statement> updates = <Statement>[];
    List<Statement> newBody = <Statement>[body];
    for (int i = 0; i < stmt.variables.length; ++i) {
      VariableDeclaration decl = stmt.variables[i];
      temps.add(new VariableDeclaration(null, type: decl.type));
      loopBody.add(decl);
      if (decl.initializer != null) {
        initializers.addAll(initEffects[i]);
        initializers.add(
            new ExpressionStatement(new VariableSet(decl, decl.initializer)));
        decl.initializer = null;
      }
      updates.add(new ExpressionStatement(
          new VariableSet(decl, new VariableGet(temps.last))));
      newBody.add(new ExpressionStatement(
          new VariableSet(temps.last, new VariableGet(decl))));
    }
    // Add the updates to their guarded list of statements.
    for (int i = 0; i < stmt.updates.length; ++i) {
      updates.addAll(updateEffects[i]);
      updates.add(new ExpressionStatement(stmt.updates[i]));
    }
    // Initializers or updates could be empty.
    loopBody.add(new IfStatement(new VariableGet(temps.first),
        new Block(initializers), new Block(updates)));

    LabeledStatement labeled = new LabeledStatement(null);
    if (cond != null) {
      loopBody.addAll(condEffects);
    } else {
      cond = new BoolLiteral(true);
    }
    loopBody.add(
        new IfStatement(cond, new Block(newBody), new BreakStatement(labeled)));
    labeled.body = new WhileStatement(
        new BoolLiteral(true), new Block(loopBody))..parent = labeled;
    statements.add(new Block(<Statement>[]
      ..addAll(temps)
      ..add(labeled)));
    return null;
  }

  TreeNode visitForInStatement(ForInStatement stmt) {
    if (stmt.isAsync) {
      // Transform
      //
      //   await for (var variable in <stream-expression>) { ... }
      //
      // To:
      //
      //   {
      //     var :for-iterator = new StreamIterator(<stream-expression>);
      //     try {
      //       while (await :for-iterator.moveNext()) {
      //         var <variable> = :for-iterator.current;
      //         ...
      //       }
      //     } finally {
      //       :for-iterator.cancel();
      //     }
      //   }
      var iteratorVariable = new VariableDeclaration(':for-iterator',
          initializer: new ConstructorInvocation(
              helper.streamIteratorConstructor,
              new Arguments(<Expression>[stmt.iterable])));

      // await iterator.moveNext()
      var condition = new AwaitExpression(new MethodInvocation(
          new VariableGet(iteratorVariable),
          new Name('moveNext'),
          new Arguments(<Expression>[])));

      // var <variable> = iterator.current;
      var valueVariable = stmt.variable;
      valueVariable.initializer = new PropertyGet(
          new VariableGet(iteratorVariable), new Name('current'));
      valueVariable.initializer.parent = valueVariable;

      var whileBody = new Block(<Statement>[valueVariable, stmt.body]);
      var tryBody = new WhileStatement(condition, whileBody);

      // iterator.cancel();
      var tryFinalizer = new ExpressionStatement(new MethodInvocation(
          new VariableGet(iteratorVariable),
          new Name('cancel'),
          new Arguments(<Expression>[])));

      var tryFinally = new TryFinally(tryBody, tryFinalizer);

      var block = new Block(<Statement>[iteratorVariable, tryFinally]);
      block.accept(this);
    } else {
      stmt.iterable = expressionRewriter.rewrite(stmt.iterable, statements)
        ..parent = stmt;
      stmt.body = visitDelimited(stmt.body)..parent = stmt;
      statements.add(stmt);
    }
    return null;
  }

  TreeNode visitSwitchStatement(SwitchStatement stmt) {
    stmt.expression = expressionRewriter.rewrite(stmt.expression, statements)
      ..parent = stmt;
    for (var switchCase in stmt.cases) {
      // Expressions in switch cases cannot contain await so they do not need to
      // be translated.
      switchCase.body = visitDelimited(switchCase.body)..parent = switchCase;
    }
    statements.add(stmt);
    return null;
  }

  TreeNode visitContinueSwitchStatement(ContinueSwitchStatement stmt) {
    statements.add(stmt);
    return null;
  }

  TreeNode visitIfStatement(IfStatement stmt) {
    stmt.condition = expressionRewriter.rewrite(stmt.condition, statements)
      ..parent = stmt;
    stmt.then = visitDelimited(stmt.then)..parent = stmt;
    if (stmt.otherwise != null) {
      stmt.otherwise = visitDelimited(stmt.otherwise)..parent = stmt;
    }
    statements.add(stmt);
    return null;
  }

  TreeNode visitTryCatch(TryCatch stmt) {
    ++currentTryDepth;
    stmt.body = visitDelimited(stmt.body)..parent = stmt;
    --currentTryDepth;

    ++currentCatchDepth;
    for (var clause in stmt.catches) {
      clause.body = visitDelimited(clause.body)..parent = clause;
    }
    --currentCatchDepth;
    statements.add(stmt);
    return null;
  }

  TreeNode visitTryFinally(TryFinally stmt) {
    ++currentTryDepth;
    stmt.body = visitDelimited(stmt.body)..parent = stmt;
    --currentTryDepth;
    stmt.finalizer = visitDelimited(stmt.finalizer)..parent = stmt;
    statements.add(stmt);
    return null;
  }

  TreeNode visitYieldStatement(YieldStatement stmt) {
    stmt.expression = expressionRewriter.rewrite(stmt.expression, statements)
      ..parent = stmt;
    statements.add(stmt);
    return null;
  }

  TreeNode visitVariableDeclaration(VariableDeclaration stmt) {
    if (stmt.initializer != null) {
      stmt.initializer = expressionRewriter.rewrite(
          stmt.initializer, statements)..parent = stmt;
    }
    statements.add(stmt);
    return null;
  }

  TreeNode visitFunctionDeclaration(FunctionDeclaration stmt) {
    stmt.function = stmt.function.accept(this)..parent = stmt;
    statements.add(stmt);
    return null;
  }

  defaultExpression(TreeNode node) => throw 'unreachable';
}

class AsyncStarFunctionRewriter extends AsyncRewriterBase {
  VariableDeclaration controllerVariable;

  AsyncStarFunctionRewriter(helper, enclosingFunction)
      : super(helper, enclosingFunction);

  FunctionNode rewrite() {
    var statements = <Statement>[];

    // var :controller;
    controllerVariable = new VariableDeclaration(":controller");
    statements.add(controllerVariable);

    setupAsyncContinuations(statements);

    // :controller = new _AsyncController(:async_op);
    var arguments =
        new Arguments(<Expression>[new VariableGet(nestedClosureVariable)]);
    var buildController = new ConstructorInvocation(
        helper.streamControllerConstructor, arguments);
    var setController = new ExpressionStatement(
        new VariableSet(controllerVariable, buildController));
    statements.add(setController);

    // return :controller.stream;
    var completerGet = new VariableGet(controllerVariable);
    var returnStatement = new ReturnStatement(
        new PropertyGet(completerGet, new Name('stream', helper.asyncLibrary)));
    statements.add(returnStatement);

    enclosingFunction.body = new Block(statements);
    enclosingFunction.body.parent = enclosingFunction;
    enclosingFunction.asyncMarker = AsyncMarker.Sync;
    return enclosingFunction;
  }

  Statement buildCatchBody(exceptionVariable, stackTraceVariable) {
    return new ExpressionStatement(new MethodInvocation(
        new VariableGet(controllerVariable),
        new Name("completeError", helper.asyncLibrary),
        new Arguments(<Expression>[
          new VariableGet(exceptionVariable),
          new VariableGet(stackTraceVariable)
        ])));
  }

  Statement buildReturn(Statement body) {
    // Async* functions cannot return a value.  The returns from the function
    // have been translated into breaks from the labeled body.
    return new Block(<Statement>[
      body,
      new ExpressionStatement(new MethodInvocation(
          new VariableGet(controllerVariable),
          new Name("close", helper.asyncLibrary),
          new Arguments(<Expression>[]))),
      new ReturnStatement()
    ]);
  }

  TreeNode visitYieldStatement(YieldStatement stmt) {
    Expression expr = expressionRewriter.rewrite(stmt.expression, statements);

    var addExpression = new MethodInvocation(
        new VariableGet(controllerVariable),
        new Name(stmt.isYieldStar ? 'addStream' : 'add', helper.asyncLibrary),
        new Arguments(<Expression>[expr]));

    statements.add(new IfStatement(addExpression,
        new ReturnStatement(new NullLiteral()), createContinuationPoint()));
    return null;
  }

  TreeNode visitReturnStatement(ReturnStatement node) {
    // Async* functions cannot return a value.
    assert(node.expression == null || node.expression is NullLiteral);
    statements
        .add(new BreakStatement(labeledBody)..fileOffset = node.fileOffset);
    return null;
  }
}

class AsyncFunctionRewriter extends AsyncRewriterBase {
  VariableDeclaration completerVariable;
  VariableDeclaration returnVariable;

  AsyncFunctionRewriter(helper, enclosingFunction)
      : super(helper, enclosingFunction);

  FunctionNode rewrite() {
    var statements = <Statement>[];

    // var :completer = new Completer.sync();
    completerVariable = new VariableDeclaration(":completer",
        initializer: new StaticInvocation(
            helper.completerConstructor, new Arguments([])),
        isFinal: true);
    statements.add(completerVariable);

    returnVariable = new VariableDeclaration(":return_value");
    statements.add(returnVariable);

    setupAsyncContinuations(statements);

    // new Future.microtask(:async_op);
    var newMicrotaskStatement = new ExpressionStatement(new StaticInvocation(
        helper.futureMicrotaskConstructor,
        new Arguments([new VariableGet(nestedClosureVariable)])));
    statements.add(newMicrotaskStatement);

    // return :completer.future;
    var completerGet = new VariableGet(completerVariable);
    var returnStatement = new ReturnStatement(
        new PropertyGet(completerGet, new Name('future', helper.asyncLibrary)));
    statements.add(returnStatement);

    enclosingFunction.body = new Block(statements);
    enclosingFunction.body.parent = enclosingFunction;
    enclosingFunction.asyncMarker = AsyncMarker.Sync;
    return enclosingFunction;
  }

  Statement buildCatchBody(exceptionVariable, stackTraceVariable) {
    return new ExpressionStatement(new MethodInvocation(
        new VariableGet(completerVariable),
        new Name("completeError", helper.asyncLibrary),
        new Arguments([
          new VariableGet(exceptionVariable),
          new VariableGet(stackTraceVariable)
        ])));
  }

  Statement buildReturn(Statement body) {
    // Returns from the body have all been translated into assignments to the
    // return value variable followed by a break from the labeled body.
    return new Block(<Statement>[
      body,
      new ExpressionStatement(new MethodInvocation(
          new VariableGet(completerVariable),
          new Name("complete", helper.asyncLibrary),
          new Arguments([new VariableGet(returnVariable)]))),
      new ReturnStatement()
    ]);
  }

  visitReturnStatement(ReturnStatement node) {
    var expr = node.expression == null
        ? new NullLiteral()
        : expressionRewriter.rewrite(node.expression, statements);
    statements
        .add(new ExpressionStatement(new VariableSet(returnVariable, expr)));
    statements
        .add(new BreakStatement(labeledBody)..fileOffset = node.fileOffset);
    return null;
  }
}

class HelperNodes {
  final Library asyncLibrary;
  final Library coreLibrary;
  final Procedure printProcedure;
  final Procedure completerConstructor;
  final Procedure futureMicrotaskConstructor;
  final Constructor streamControllerConstructor;
  final Constructor syncIterableConstructor;
  final Constructor streamIteratorConstructor;
  final Procedure asyncThenWrapper;
  final Procedure asyncErrorWrapper;
  final Procedure awaitHelper;

  HelperNodes(
      this.asyncLibrary,
      this.coreLibrary,
      this.printProcedure,
      this.completerConstructor,
      this.syncIterableConstructor,
      this.streamIteratorConstructor,
      this.futureMicrotaskConstructor,
      this.streamControllerConstructor,
      this.asyncThenWrapper,
      this.asyncErrorWrapper,
      this.awaitHelper);

  factory HelperNodes.fromProgram(Program program) {
    Library findLibrary(String name) {
      Uri uri = Uri.parse(name);
      for (var library in program.libraries) {
        if (library.importUri == uri) return library;
      }
      throw 'Library "$name" not found';
    }

    Class findClass(Library library, String name) {
      for (var klass in library.classes) {
        if (klass.name == name) return klass;
      }
      throw 'Class "$name" not found';
    }

    Procedure findFactoryConstructor(Class klass, String name) {
      for (var procedure in klass.procedures) {
        if (procedure.isStatic && procedure.name.name == name) return procedure;
      }
      throw 'Factory constructor "$klass.$name" not found';
    }

    Constructor findConstructor(Class klass, String name) {
      for (var constructor in klass.constructors) {
        if (constructor.name.name == name) return constructor;
      }
      throw 'Constructor "$klass.$name" not found';
    }

    Procedure findProcedure(Library library, String name) {
      for (var procedure in library.procedures) {
        if (procedure.name.name == name ||
            procedure.name.name == '${library.name}::${name}') {
          return procedure;
        }
      }
      throw 'Procedure "$name" not found';
    }

    var asyncLibrary = findLibrary('dart:async');
    var coreLibrary = findLibrary('dart:core');

    var completerClass = findClass(asyncLibrary, 'Completer');
    var futureClass = findClass(asyncLibrary, 'Future');

    // The VM's dart:async implementation has renamed _StreamIteratorImpl to
    // _StreamIterator.  To support both old and new library implementations we
    // look for the old name first and then the new name.
    var streamIteratorClass;
    try {
      streamIteratorClass = findClass(asyncLibrary, '_StreamIteratorImpl');
    } catch (e) {
      if (e == 'Class "_StreamIteratorImpl" not found') {
        streamIteratorClass = findClass(asyncLibrary, '_StreamIterator');
      } else {
        rethrow;
      }
    }

    var syncIterableClass = findClass(coreLibrary, '_SyncIterable');
    var streamControllerClass =
        findClass(asyncLibrary, '_AsyncStarStreamController');

    return new HelperNodes(
        asyncLibrary,
        coreLibrary,
        findProcedure(coreLibrary, 'print'),
        findFactoryConstructor(completerClass, 'sync'),
        findConstructor(syncIterableClass, ''),
        findConstructor(streamIteratorClass, ''),
        findFactoryConstructor(futureClass, 'microtask'),
        findConstructor(streamControllerClass, ''),
        findProcedure(asyncLibrary, '_asyncThenWrapperHelper'),
        findProcedure(asyncLibrary, '_asyncErrorWrapperHelper'),
        findProcedure(asyncLibrary, '_awaitHelper'));
  }
}
