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
  final VariableDeclaration asyncJumpVariable =
      new VariableDeclaration(":await_jump_var", initializer: new IntLiteral(0));
  final VariableDeclaration asyncContextVariable =
      new VariableDeclaration(":await_ctx_var");

  RecursiveContinuationRewriter(this.helper);

  Program rewriteProgram(Program node) {
    return node.accept(this);
  }

  visitFunctionNode(FunctionNode node) {
    switch (node.asyncMarker) {
      case AsyncMarker.Sync:
        return super.visitFunctionNode(node);
      case AsyncMarker.SyncStar:
        return new SyncStarFunctionRewriter(helper, node).rewrite();
      case AsyncMarker.Async:
        return new AsyncFunctionRewriter(helper, node).rewrite();
      case AsyncMarker.AsyncStar:
        return new AsyncStarFunctionRewriter(helper, node).rewrite();
      case AsyncMarker.SyncYielding:
        break; // Already transformed.
    }
  }
}

abstract class ContinuationRewriterBase extends RecursiveContinuationRewriter {
  final FunctionNode enclosingFunction;

  int currentTryDepth;  // Nesting depth for try-blocks.
  int currentCatchDepth = 0;  // Nesting depth for catch-blocks.
  int capturedTryDepth = 0;  // Deepest yield point within a try-block.
  int capturedCatchDepth = 0;  // Deepest yield point within a catch-block.

  ContinuationRewriterBase(HelperNodes helper,
                           this.enclosingFunction,
                           {this.currentTryDepth: 0})
      : super(helper);

  Statement createContinuationPoint([value]) {
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
      new Iterable.generate(capturedTryDepth, (depth) =>
        new VariableDeclaration(":saved_try_context_var${depth}"));

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
    final function = new FunctionNode(
        buildClosureBody(),
        positionalParameters: [iteratorVariable],
        requiredParameterCount: 1,
        asyncMarker: AsyncMarker.SyncYielding);
    final closureFunction =
        new FunctionDeclaration(nestedClosureVariable, function);

    // return new _SyncIterable(:sync_body);
    final arguments = new Arguments([new VariableGet(nestedClosureVariable)]);
    final returnStatement = new ReturnStatement(new ConstructorInvocation(
        helper.syncIterableConstructor, arguments));

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

    var statements = [];
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

  ExpressionLifter expressionRewriter;

  AsyncRewriterBase(helper, enclosingFunction)
     // Body is wrapped in the try-catch so initial currentTryDepth is 1.
     : super(helper, enclosingFunction, currentTryDepth: 1) {
  }

  setupAsyncContinuations(List<Statement> statements) {
    expressionRewriter = new ExpressionLifter(this, enclosingFunction);

    // var :async_op_then;
    statements.add(thenContinuationVariable);

    // var :async_op_error;
    statements.add(catchErrorContinuationVariable);

    // :async_op([:result, :exception, :stack_trace]) {
    //     modified <node.body>;
    // }
    final parameters = [
        expressionRewriter.asyncResult,
        new VariableDeclaration(':exception'),
        new VariableDeclaration(':stack_trace'),
    ];
    final function = new FunctionNode(
        buildWrappedBody(),
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
    final boundThenClosure = new StaticInvocation(
        helper.asyncThenWrapper,
        new Arguments([new VariableGet(nestedClosureVariable)]));
    final thenClosureVariableAssign = new ExpressionStatement(new VariableSet(
        thenContinuationVariable, boundThenClosure));
    statements.add(thenClosureVariableAssign);

    // :async_op_error = _asyncErrorWrapperHelper(asyncBody);
    final boundCatchErrorClosure = new StaticInvocation(
        helper.asyncErrorWrapper,
        new Arguments([new VariableGet(nestedClosureVariable)]));
    final catchErrorClosureVariableAssign =
        new ExpressionStatement(new VariableSet(
          catchErrorContinuationVariable , boundCatchErrorClosure));
    statements.add(catchErrorClosureVariableAssign);
  }

  Statement buildWrappedBody() {
    // No explicit return at the end of the body => we will add one!
    var body = addReturnStatementIfNecessary(enclosingFunction.body);
    var userBody = buildClosureBody(body);

    var exceptionVariable = new VariableDeclaration(":exception");
    var stackTraceVariable = new VariableDeclaration(":stack_trace");

    var completeErrorStatement =
        buildCatchBody(exceptionVariable, stackTraceVariable);

    var catchBody = new Block(<Statement>[completeErrorStatement]);
    var catches = [new Catch(exceptionVariable,
                             catchBody,
                             stackTrace: stackTraceVariable)];
    return new TryCatch(userBody, catches);
  }

  addReturnStatementIfNecessary(Statement body) {
    if (body is Block) {
      Block block = body;
      if (block.statements.isEmpty ||
          block.statements.last is! ReturnStatement) {
        var returnStatement = new ReturnStatement();
        block.statements.add(returnStatement);
        returnStatement.parent = block;
      }
    } else if (body is! ReturnStatement) {
      var returnStatement = new ReturnStatement();
      body = new Block([body, returnStatement]);
    }
    return body;
  }

  Statement buildClosureBody(Statement node);

  Statement buildCatchBody(Statement exceptionVariable,
                           Statement stackTraceVariable);

  visitForInStatement(ForInStatement node) {
    if (node.isAsync) {
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
      var iteratorVariable = new VariableDeclaration(
          ':for-iterator',
          initializer: new ConstructorInvocation(
            helper.streamIteratorConstructor,
            new Arguments([expressionRewriter.rewrite(node.iterable)])));

      // await iterator.moveNext()
      var condition = new AwaitExpression(new MethodInvocation(
            new VariableGet(iteratorVariable),
            new Name('moveNext'),
            new Arguments([])));

      // var <variable> = iterator.current;
      var valueVariable = node.variable;
      valueVariable.initializer = new PropertyGet(
          new VariableGet(iteratorVariable),
          new Name('current'));
      valueVariable.initializer.parent = valueVariable;

      var whileBody = new Block([valueVariable, node.body]);
      var tryBody = new WhileStatement(condition, whileBody);

      // iterator.cancel();
      var tryFinalizer = new ExpressionStatement(
          new MethodInvocation(
            new VariableGet(iteratorVariable),
            new Name('cancel'),
            new Arguments([])));

      var tryFinally = new TryFinally(tryBody, tryFinalizer);

      var block = new Block([
          iteratorVariable,
          tryFinally,
      ]);
      return block.accept(this);
    } else {
      return super.visitForInStatement(node);
    }
  }

  defaultExpression(TreeNode node) {
    return expressionRewriter.rewrite(node);
  }
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

    super.setupAsyncContinuations(statements);

    // :controller = new _AsyncController(:async_op);
    var arguments = new Arguments([new VariableGet(nestedClosureVariable)]);
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

  Statement buildClosureBody(Statement node) {
    // The body will insert calls to
    //    :controller.add()
    //    :controller.addStream()
    //    :controller.addError()
    //    :controller.close()
    return node.accept(this);
  }

  Statement buildCatchBody(exceptionVariable, stackTraceVariable) {
    return new ExpressionStatement(
        new MethodInvocation(
          new VariableGet(controllerVariable),
          new Name("completeError", helper.asyncLibrary),
          new Arguments([new VariableGet(exceptionVariable),
                         new VariableGet(stackTraceVariable)])));
  }

  visitYieldStatement(YieldStatement node) {
    var transformedExpression = node.expression.accept(this);

    var addExpression = new MethodInvocation(
          new VariableGet(controllerVariable),
          new Name(node.isYieldStar ? 'addStream' : 'add', helper.asyncLibrary),
          new Arguments([transformedExpression]));

    var addAndReturnOrYield = new IfStatement(
        addExpression,
        new ReturnStatement(new NullLiteral()),
        createContinuationPoint());
    return new Block([addAndReturnOrYield]);
  }

  visitReturnStatement(ReturnStatement node) {
    // async* functions cannot have normal [ReturnStatement]s in them.
    assert(node.expression == null || node.expression is NullLiteral);

    var close = new ExpressionStatement(
        new MethodInvocation(
          new VariableGet(controllerVariable),
          new Name("close", helper.asyncLibrary),
          new Arguments([])));
    var returnStatement = new ReturnStatement();
    return new Block([close, returnStatement]);
  }
}

class AsyncFunctionRewriter extends AsyncRewriterBase {
  VariableDeclaration completerVariable;

  AsyncFunctionRewriter(helper, enclosingFunction)
      : super(helper, enclosingFunction);

  FunctionNode rewrite() {
    var statements = <Statement>[];

    // var :completer = new Completer.sync();
    completerVariable = new VariableDeclaration(
        ":completer",
        initializer: new StaticInvocation(helper.completerConstructor,
                                          new Arguments([])),
        isFinal: true);
    statements.add(completerVariable);

    super.setupAsyncContinuations(statements);

    // new Future.microtask(:async_op);
    var newMicrotaskStatement = new ExpressionStatement(
        new StaticInvocation(
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

  Statement buildClosureBody(Statement node) {
    // TODO(kustermann): Can we assume the frontend will insert proper
    // [ReturnStatement]s?

    // Translating the body will insert calls to
    //     :completer.completeError()
    //     :completer.complete()
    return node.accept(this);
  }

  Statement buildCatchBody(exceptionVariable, stackTraceVariable) {
    return new ExpressionStatement(
        new MethodInvocation(
          new VariableGet(completerVariable),
          new Name("completeError", helper.asyncLibrary),
          new Arguments([new VariableGet(exceptionVariable),
                         new VariableGet(stackTraceVariable)])));
  }

  visitReturnStatement(ReturnStatement node) {
    var transformedExpression;
    if (node.expression == null) {
      transformedExpression = new NullLiteral();
    } else {
      transformedExpression = expressionRewriter.rewrite(node.expression);
    }

    // Note: transformed expression can't be used directly as part of the
    // method invocation because it might contain yield points and
    // expression stack might not be empty.
    var resultVar = new VariableDeclaration(':async-temp',
                                            initializer: transformedExpression);
    var completeCompleter = new ExpressionStatement(
        new MethodInvocation(
          new VariableGet(completerVariable),
          new Name("complete", helper.asyncLibrary),
          new Arguments([new VariableGet(resultVar)])));
    var returnStatement = new ReturnStatement(new NullLiteral());
    return new Block([resultVar, completeCompleter, returnStatement]);
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
      this.awaitHelper
  );

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
    var streamIteratorClass = findClass(asyncLibrary, '_StreamIteratorImpl');
    var syncIterableClass = findClass(coreLibrary, '_SyncIterable');
    var streamControllerClass = findClass(
        asyncLibrary, '_AsyncStarStreamController');

    return new HelperNodes(
        asyncLibrary,
        coreLibrary,
        findProcedure(coreLibrary, 'print'),
        findFactoryConstructor(completerClass, 'sync'),
        findConstructor(syncIterableClass, ''),
        findConstructor(streamIteratorClass , ''),
        findFactoryConstructor(futureClass, 'microtask'),
        findConstructor(streamControllerClass, ''),
        findProcedure(asyncLibrary, '_asyncThenWrapperHelper'),
        findProcedure(asyncLibrary, '_asyncErrorWrapperHelper'),
        findProcedure(asyncLibrary, '_awaitHelper'));
    }
}
