// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.continuation;

import 'dart:math' as math;

import '../ast.dart';
import '../core_types.dart';
import '../type_algebra.dart' show Substitution;
import '../type_environment.dart';

import 'async.dart';

class ContinuationVariables {
  static const awaitJumpVar = ':await_jump_var';
  static const asyncFuture = ':async_future';
  static const isSync = ":is_sync";
  static const awaitContextVar = ':await_ctx_var';
  static const asyncCompleter = ':async_completer';
  static const asyncOp = ':async_op';
  static const asyncOpThen = ':async_op_then';
  static const asyncOpError = ':async_op_error';
  static const controller = ':controller';
  static const controllerStreamVar = ':controller_stream';
  static const forIterator = ':for-iterator';
  static const returnValue = ':return_value';
  static const stream = ':stream';
  static const syncForIterator = ':sync-for-iterator';
  static const syncOpGen = ':sync_op_gen';
  static const syncOp = ':sync_op';
  // sync_op(..) parameter.
  static const iteratorParam = ':iterator';
  // (a)sync_op(..) parameters.
  static const exceptionParam = ':exception';
  static const stackTraceParam = ':stack_trace';

  static const savedTryContextVarPrefix = ':saved_try_context_var';
  static const exceptionVarPrefix = ':exception';
  static const stackTraceVarPrefix = ':stack_trace';

  static String savedTryContextVar(int depth) =>
      '$savedTryContextVarPrefix$depth';
  static String exceptionVar(int depth) => '$exceptionVarPrefix$depth';
  static String stackTraceVar(int depth) => '$stackTraceVarPrefix$depth';
}

void transformLibraries(
    TypeEnvironment typeEnvironment, List<Library> libraries,
    {required bool productMode}) {
  var helper =
      new HelperNodes.fromCoreTypes(typeEnvironment.coreTypes, productMode);
  var rewriter = new RecursiveContinuationRewriter(
      helper, new StatefulStaticTypeContext.stacked(typeEnvironment));
  for (var library in libraries) {
    rewriter.rewriteLibrary(library);
  }
}

Component transformComponent(
    TypeEnvironment typeEnvironment, Component component,
    {required bool productMode}) {
  var helper =
      new HelperNodes.fromCoreTypes(typeEnvironment.coreTypes, productMode);
  var rewriter = new RecursiveContinuationRewriter(
      helper, new StatefulStaticTypeContext.stacked(typeEnvironment));
  return rewriter.rewriteComponent(component);
}

Procedure transformProcedure(
    TypeEnvironment typeEnvironment, Procedure procedure,
    {required bool productMode}) {
  var helper =
      new HelperNodes.fromCoreTypes(typeEnvironment.coreTypes, productMode);
  var rewriter = new RecursiveContinuationRewriter(
      helper, new StatefulStaticTypeContext.stacked(typeEnvironment));
  return rewriter.transform(procedure);
}

class RecursiveContinuationRewriter extends RemovingTransformer {
  final HelperNodes helper;

  final VariableDeclaration awaitJumpVariable = new VariableDeclaration(
      ContinuationVariables.awaitJumpVar,
      initializer: new IntLiteral(0));
  final VariableDeclaration awaitContextVariable =
      new VariableDeclaration(ContinuationVariables.awaitContextVar);

  StatefulStaticTypeContext staticTypeContext;

  RecursiveContinuationRewriter(this.helper, this.staticTypeContext);

  Component rewriteComponent(Component node) {
    return transform(node);
  }

  Library rewriteLibrary(Library node) {
    return transform(node);
  }

  @override
  TreeNode visitField(Field node, TreeNode? removalSentinel) {
    staticTypeContext.enterMember(node);
    final result = super.visitField(node, removalSentinel);
    staticTypeContext.leaveMember(node);
    return result;
  }

  @override
  TreeNode visitConstructor(Constructor node, TreeNode? removalSentinel) {
    staticTypeContext.enterMember(node);
    final result = super.visitConstructor(node, removalSentinel);
    staticTypeContext.leaveMember(node);
    return result;
  }

  @override
  TreeNode visitProcedure(Procedure node, TreeNode? removalSentinel) {
    staticTypeContext.enterMember(node);
    final result =
        node.isAbstract ? node : super.visitProcedure(node, removalSentinel);
    staticTypeContext.leaveMember(node);
    return result;
  }

  @override
  TreeNode visitLibrary(Library node, TreeNode? removalSentinel) {
    staticTypeContext.enterLibrary(node);
    Library result = super.visitLibrary(node, removalSentinel) as Library;
    staticTypeContext.leaveLibrary(node);
    return result;
  }

  @override
  TreeNode visitFunctionNode(FunctionNode node, TreeNode? removalSentinel) {
    switch (node.asyncMarker) {
      case AsyncMarker.Sync:
      case AsyncMarker.SyncYielding:
        node.transformOrRemoveChildren(
            new RecursiveContinuationRewriter(helper, staticTypeContext));
        return node;
      case AsyncMarker.SyncStar:
        return new SyncStarFunctionRewriter(helper, node, staticTypeContext)
            .rewrite();
      case AsyncMarker.Async:
        return new AsyncFunctionRewriter(helper, node, staticTypeContext)
            .rewrite();
      case AsyncMarker.AsyncStar:
        return new AsyncStarFunctionRewriter(helper, node, staticTypeContext)
            .rewrite();
    }
  }

  @override
  TreeNode visitForInStatement(ForInStatement stmt, TreeNode? removalSentinel) {
    if (stmt.isAsync) {
      return super.visitForInStatement(stmt, removalSentinel);
    }

    // Transform
    //
    //   for ({var/final} T <variable> in <iterable>) { ... }
    //
    // Into
    //
    //  {
    //    final Iterator<T> :sync-for-iterator = <iterable>.iterator;
    //    for (; :sync-for-iterator.moveNext() ;) {
    //        {var/final} T variable = :sync-for-iterator.current;
    //        ...
    //      }
    //    }
    //  }
    final CoreTypes coreTypes = staticTypeContext.typeEnvironment.coreTypes;

    // The CFE might invoke this transformation despite the program having
    // compile-time errors. So we will not transform this [stmt] if the
    // `stmt.iterable` is an invalid expression or has an invalid type and
    // instead eliminate the entire for-in and replace it with a invalid
    // expression statement.
    final iterable = stmt.iterable;
    final iterableType = iterable.getStaticType(staticTypeContext);
    if (iterableType is InvalidType) {
      return ExpressionStatement(
          InvalidExpression('Invalid iterable type in for-in'));
    }

    // The NNBD sdk declares that Iterable.get:iterator returns a non-nullable
    // `Iterator<E>`.
    assert(const [
      Nullability.nonNullable,
      Nullability.legacy
    ].contains(coreTypes.iterableGetIterator.function.returnType.nullability));

    final DartType elementType = stmt.getElementType(staticTypeContext);
    final iteratorType = InterfaceType(
        coreTypes.iteratorClass, staticTypeContext.nonNullable, [elementType]);

    final syncForIterator = VariableDeclaration(
        ContinuationVariables.syncForIterator,
        initializer: InstanceGet(InstanceAccessKind.Instance, iterable,
            coreTypes.iterableGetIterator.name,
            interfaceTarget: coreTypes.iterableGetIterator,
            resultType: iteratorType)
          ..fileOffset = iterable.fileOffset,
        type: iteratorType)
      ..fileOffset = iterable.fileOffset;

    final condition = InstanceInvocation(
        InstanceAccessKind.Instance,
        VariableGet(syncForIterator),
        coreTypes.iteratorMoveNext.name,
        Arguments([]),
        interfaceTarget: coreTypes.iteratorMoveNext,
        functionType: coreTypes.iteratorMoveNext.getterType as FunctionType)
      ..fileOffset = iterable.fileOffset;

    final variable = stmt.variable
      ..initializer = (InstanceGet(InstanceAccessKind.Instance,
          VariableGet(syncForIterator), coreTypes.iteratorGetCurrent.name,
          interfaceTarget: coreTypes.iteratorGetCurrent,
          resultType: elementType)
        ..fileOffset = stmt.bodyOffset);

    final Block body = Block([variable, stmt.body])
      ..fileOffset = stmt.bodyOffset;

    return transform(
        Block([syncForIterator, ForStatement([], condition, [], body)]));
  }
}

abstract class ContinuationRewriterBase extends RecursiveContinuationRewriter {
  final FunctionNode enclosingFunction;

  int currentTryDepth = 0; // Nesting depth for try-blocks.
  int currentCatchDepth = 0; // Nesting depth for catch-blocks.
  int capturedTryDepth = 0; // Deepest yield point within a try-block.
  int capturedCatchDepth = 0; // Deepest yield point within a catch-block.

  ContinuationRewriterBase(HelperNodes helper, this.enclosingFunction,
      StatefulStaticTypeContext staticTypeContext)
      : super(helper, staticTypeContext);

  /// Given a container [type], which is an instantiation of the given
  /// [containerClass] extract its element type.
  ///
  /// This is used to extract element type from Future<T>, Iterable<T> and
  /// Stream<T> instantiations.
  ///
  /// If instantiation is not valid (has more than 1 type argument) then
  /// this function returns [InvalidType].
  static DartType elementTypeFrom(Class containerClass, DartType type) {
    if (type is InterfaceType) {
      if (type.classNode == containerClass) {
        if (type.typeArguments.length == 0) {
          return const DynamicType();
        } else if (type.typeArguments.length == 1) {
          return type.typeArguments[0];
        } else {
          return const InvalidType();
        }
      }
    }
    return const DynamicType();
  }

  static DartType elementTypeFromFutureOr(DartType type) {
    if (type is FutureOrType) {
      return type.typeArgument;
    }
    return const DynamicType();
  }

  DartType elementTypeFromReturnType(Class expected) =>
      elementTypeFrom(expected, enclosingFunction.returnType);

  DartType elementTypeFromAsyncReturnType() =>
      elementTypeFromFutureOr(enclosingFunction.returnType);

  Statement createContinuationPoint([Expression? value]) {
    if (value == null) value = new NullLiteral();
    capturedTryDepth = math.max(capturedTryDepth, currentTryDepth);
    capturedCatchDepth = math.max(capturedCatchDepth, currentCatchDepth);
    return new YieldStatement(value, isNative: true);
  }

  @override
  TreeNode visitTryCatch(TryCatch node, TreeNode? removalSentinel) {
    // ignore: unnecessary_null_comparison
    if (node.body != null) {
      ++currentTryDepth;
      node.body = transform(node.body);
      node.body.parent = node;
      --currentTryDepth;
    }

    ++currentCatchDepth;
    transformCatchList(node.catches, node);
    --currentCatchDepth;
    return node;
  }

  @override
  TreeNode visitTryFinally(TryFinally node, TreeNode? removalSentinel) {
    // ignore: unnecessary_null_comparison
    if (node.body != null) {
      ++currentTryDepth;
      node.body = transform(node.body);
      node.body.parent = node;
      --currentTryDepth;
    }
    // ignore: unnecessary_null_comparison
    if (node.finalizer != null) {
      ++currentCatchDepth;
      node.finalizer = transform(node.finalizer);
      node.finalizer.parent = node;
      --currentCatchDepth;
    }
    return node;
  }

  Iterable<VariableDeclaration> createCapturedTryVariables() =>
      new Iterable.generate(
          capturedTryDepth,
          (depth) => new VariableDeclaration(
              ContinuationVariables.savedTryContextVar(depth)));

  Iterable<VariableDeclaration> createCapturedCatchVariables() =>
      new Iterable.generate(capturedCatchDepth).expand((depth) => [
            new VariableDeclaration(ContinuationVariables.exceptionVar(depth)),
            new VariableDeclaration(ContinuationVariables.stackTraceVar(depth)),
          ]);

  List<VariableDeclaration> variableDeclarations() {
    awaitJumpVariable.type = staticTypeContext.typeEnvironment.coreTypes
        .intRawType(staticTypeContext.nonNullable);
    return [awaitJumpVariable, awaitContextVariable]
      ..addAll(createCapturedTryVariables())
      ..addAll(createCapturedCatchVariables());
  }
}

// Transformer that rewrites all variable references to a given function's
// parameters.
// This allows us to e.g. "shadow" the original parameter variables with copies
// unique to given sub-closure to prevent shared variables being overwritten.
class ShadowRewriter extends Transformer {
  final FunctionNode enclosingFunction;
  Map<VariableDeclaration, VariableDeclaration?> _shadowedParameters = {};

  ShadowRewriter(this.enclosingFunction) {
    for (final parameter in enclosingFunction.positionalParameters
        .followedBy(enclosingFunction.namedParameters)) {
      // Put in placeholers so we can allocate new variables lazily- i.e. only
      // if they're later referenced.
      _shadowedParameters[parameter] = null;
    }
  }

  // Return all used parameters.
  Iterable<VariableDeclaration> get shadowedParameters =>
      _shadowedParameters.values.whereType<VariableDeclaration>();

  VariableDeclaration _rewrite(VariableDeclaration variable) {
    if (_shadowedParameters.containsKey(variable)) {
      // Fill in placeholder.
      VariableDeclaration? placeholder = _shadowedParameters[variable];
      if (placeholder == null) {
        placeholder = _shadowedParameters[variable] = VariableDeclaration(
          variable.name,
          type: variable.type,
          initializer: VariableGet(variable),
        );
      }
      variable = placeholder;
    }
    return variable;
  }

  @override
  TreeNode visitVariableGet(VariableGet node) {
    node = super.visitVariableGet(node) as VariableGet;
    return node..variable = _rewrite(node.variable);
  }

  @override
  TreeNode visitVariableSet(VariableSet node) {
    node = super.visitVariableSet(node) as VariableSet;
    return node..variable = _rewrite(node.variable);
  }
}

class SyncStarFunctionRewriter extends ContinuationRewriterBase {
  final VariableDeclaration iteratorParameter;

  SyncStarFunctionRewriter(HelperNodes helper, FunctionNode enclosingFunction,
      StatefulStaticTypeContext staticTypeContext)
      : iteratorParameter =
            VariableDeclaration(ContinuationVariables.iteratorParam)
              ..type = InterfaceType(
                  helper.syncIteratorClass, staticTypeContext.nullable, [
                // Note: This is dynamic since nested iterators (of potentially
                // different type) are handled by shared internal synthetic
                // code.
                const DynamicType(),
              ]),
        super(helper, enclosingFunction, staticTypeContext);

  FunctionNode rewrite() {
    // We need to preserve the original parameters passed to the sync* function
    // because each iteration should start from those parameters. To achieve
    // this we shadow the original parameters with new variables (which are
    // initialised to the original parameter values) and rewrite
    // the body to use these variables instead.
    final shadowRewriter = ShadowRewriter(enclosingFunction);
    enclosingFunction.body = shadowRewriter.transform(enclosingFunction.body!)
      ..parent = enclosingFunction;

    // TODO(cskau): Figure out why inlining this below causes segfaults.
    // Maybe related to http://dartbug.com/41596 ?
    final syncOpFN = FunctionNode(buildClosureBody(),
        positionalParameters: [
          iteratorParameter,
          new VariableDeclaration(ContinuationVariables.exceptionParam),
          new VariableDeclaration(ContinuationVariables.stackTraceParam),
        ],
        requiredParameterCount: 3,
        // Note: SyncYielding functions have no Dart equivalent. Since they are
        // synchronous, we use Sync. (Note also that the Dart VM backend uses
        // the Dart async marker to decide if functions are debuggable.)
        asyncMarker: AsyncMarker.SyncYielding,
        dartAsyncMarker: AsyncMarker.Sync,
        returnType: helper.coreTypes.boolLegacyRawType)
      ..fileOffset = enclosingFunction.fileOffset
      ..fileEndOffset = enclosingFunction.fileEndOffset;
    final syncOpType =
        syncOpFN.computeThisFunctionType(staticTypeContext.nonNullable);

    final syncOpGenVariable = VariableDeclaration(
        ContinuationVariables.syncOpGen,
        type: FunctionType([], syncOpType, staticTypeContext.nonNullable));

    final syncOpVariable = VariableDeclaration(ContinuationVariables.syncOp);
    final syncOpDecl = FunctionDeclaration(syncOpVariable, syncOpFN)
      ..fileOffset = enclosingFunction.fileOffset;

    enclosingFunction.body = Block([
      // :sync_op_gen() {
      //   :await_jump_var;
      //   :await_ctx_var;
      //   bool sync_op(:iterator, e, st) yielding {
      //     modified <node.body> ...
      //   };
      //   return sync_op;
      // }
      FunctionDeclaration(
          syncOpGenVariable,
          FunctionNode(
              Block([
                // :await_jump_var, :await_ctx_var.
                ...variableDeclarations(),
                // Shadow any used function parameters with local copies.
                ...shadowRewriter.shadowedParameters,
                // :sync_op(..) { .. }
                syncOpDecl,
                // return sync_op;
                ReturnStatement(VariableGet(syncOpVariable)),
              ]),
              returnType: syncOpType))
        ..fileOffset = enclosingFunction.fileOffset,

      // return _SyncIterable<T>(:sync_op_gen);
      ReturnStatement(ConstructorInvocation(
          helper.syncIterableConstructor,
          Arguments([
            VariableGet(syncOpGenVariable)
          ], types: [
            ContinuationRewriterBase.elementTypeFrom(
                helper.iterableClass, enclosingFunction.returnType)
          ]))),
    ])
      ..parent = enclosingFunction;
    enclosingFunction.asyncMarker = AsyncMarker.Sync;

    return enclosingFunction;
  }

  Statement buildClosureBody() {
    // The body will insert calls to
    //    :iterator.current_=
    //    :iterator.isYieldEach=
    // and return `true` as long as it did something and `false` when it's done.
    return new Block(<Statement>[
      transform(enclosingFunction.body!),
      new ReturnStatement(new BoolLiteral(false))
        ..fileOffset = enclosingFunction.fileEndOffset
    ]);
  }

  @override
  TreeNode visitYieldStatement(YieldStatement node, TreeNode? removalSentinel) {
    Expression transformedExpression = transform(node.expression);

    var statements = <Statement>[];
    if (node.isYieldStar) {
      statements.add(new ExpressionStatement(new InstanceSet(
          InstanceAccessKind.Instance,
          VariableGet(iteratorParameter),
          helper.syncIteratorYieldEachIterable.name,
          transformedExpression,
          interfaceTarget: helper.syncIteratorYieldEachIterable)));
    } else {
      statements.add(new ExpressionStatement(new InstanceSet(
          InstanceAccessKind.Instance,
          VariableGet(iteratorParameter),
          helper.syncIteratorCurrent.name,
          transformedExpression,
          interfaceTarget: helper.syncIteratorCurrent)));
    }

    statements.add(createContinuationPoint(new BoolLiteral(true))
      ..fileOffset = node.fileOffset);
    return new Block(statements);
  }

  @override
  TreeNode visitReturnStatement(
      ReturnStatement node, TreeNode? removalSentinel) {
    // sync* functions cannot return a value.
    assert(node.expression == null || node.expression is NullLiteral);
    node.expression = new BoolLiteral(false)..parent = node;
    return node;
  }
}

abstract class AsyncRewriterBase extends ContinuationRewriterBase {
  // :async_op has type ([dynamic result, dynamic e, StackTrace? s]) -> dynamic
  final VariableDeclaration nestedClosureVariable;

  // :async_op_then has type (dynamic result) -> dynamic
  final VariableDeclaration thenContinuationVariable;

  // :async_op_error has type (Object e, StackTrace s) -> dynamic
  final VariableDeclaration catchErrorContinuationVariable;

  LabeledStatement? labeledBody;

  ExpressionLifter? expressionRewriter;

  AsyncRewriterBase(HelperNodes helper, FunctionNode enclosingFunction,
      StatefulStaticTypeContext staticTypeContext)
      : nestedClosureVariable = VariableDeclaration(
            ContinuationVariables.asyncOp,
            type: FunctionType([
              const DynamicType(),
              const DynamicType(),
              helper.coreTypes.stackTraceRawType(staticTypeContext.nullable),
            ], const DynamicType(), staticTypeContext.nonNullable,
                requiredParameterCount: 0)),
        thenContinuationVariable = VariableDeclaration(
            ContinuationVariables.asyncOpThen,
            type: FunctionType(const [const DynamicType()], const DynamicType(),
                staticTypeContext.nonNullable)),
        catchErrorContinuationVariable =
            VariableDeclaration(ContinuationVariables.asyncOpError,
                type: FunctionType([
                  helper.coreTypes.objectRawType(staticTypeContext.nonNullable),
                  helper.coreTypes
                      .stackTraceRawType(staticTypeContext.nonNullable),
                ], const DynamicType(), staticTypeContext.nonNullable)),
        super(helper, enclosingFunction, staticTypeContext) {}

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
      expressionRewriter!.asyncResult,
      new VariableDeclaration(ContinuationVariables.exceptionParam),
      new VariableDeclaration(ContinuationVariables.stackTraceParam),
    ];

    // Note: SyncYielding functions have no Dart equivalent. Since they are
    // synchronous, we use Sync. (Note also that the Dart VM backend uses the
    // Dart async marker to decide if functions are debuggable.)
    final function = new FunctionNode(buildWrappedBody(),
        positionalParameters: parameters,
        requiredParameterCount: 0,
        asyncMarker: AsyncMarker.SyncYielding,
        dartAsyncMarker: AsyncMarker.Sync)
      ..fileOffset = enclosingFunction.fileOffset
      ..fileEndOffset = enclosingFunction.fileEndOffset;

    // The await expression lifter might have created a number of
    // [VariableDeclarations].
    // TODO(kustermann): If we didn't need any variables we should not emit
    // these.
    statements.addAll(variableDeclarations());
    statements.addAll(expressionRewriter!.variables);

    // Now add the closure function itself.
    final closureFunction =
        new FunctionDeclaration(nestedClosureVariable, function)
          ..fileOffset = enclosingFunction.parent!.fileOffset;
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
    ++currentTryDepth;
    labeledBody = new LabeledStatement(null);
    labeledBody!.body = visitDelimited(enclosingFunction.body!)
      ..parent = labeledBody;
    --currentTryDepth;

    var exceptionVariable = VariableDeclaration('exception');
    var stackTraceVariable = VariableDeclaration('stack_trace',
        type:
            helper.coreTypes.stackTraceRawType(staticTypeContext.nonNullable));

    return new TryCatch(
      buildReturn(labeledBody!),
      <Catch>[
        new Catch(
            exceptionVariable,
            new Block(<Statement>[
              buildCatchBody(exceptionVariable, stackTraceVariable)
            ]),
            stackTrace: stackTraceVariable)
      ],
      isSynthetic: true,
    );
  }

  Statement buildCatchBody(VariableDeclaration exceptionVariable,
      VariableDeclaration stackTraceVariable);

  Statement buildReturn(Statement body);

  List<Statement> statements = <Statement>[];

  @override
  TreeNode visitExpressionStatement(
      ExpressionStatement stmt, TreeNode? removalSentinel) {
    stmt.expression = expressionRewriter!.rewrite(stmt.expression, statements)
      ..parent = stmt;
    statements.add(stmt);
    return removalSentinel ?? EmptyStatement();
  }

  @override
  TreeNode visitBlock(Block stmt, TreeNode? removalSentinel) {
    var saved = statements;
    statements = <Statement>[];
    for (var statement in stmt.statements) {
      transform(statement);
    }
    saved.add(new Block(statements));
    statements = saved;
    return removalSentinel ?? EmptyStatement();
  }

  @override
  TreeNode visitEmptyStatement(EmptyStatement stmt, TreeNode? removalSentinel) {
    statements.add(stmt);
    return removalSentinel ?? EmptyStatement();
  }

  @override
  TreeNode visitAssertBlock(AssertBlock stmt, TreeNode? removalSentinel) {
    var saved = statements;
    statements = <Statement>[];
    for (var statement in stmt.statements) {
      transform(statement);
    }
    saved.add(new Block(statements));
    statements = saved;
    return removalSentinel ?? EmptyStatement();
  }

  @override
  TreeNode visitAssertStatement(
      AssertStatement stmt, TreeNode? removalSentinel) {
    var condEffects = <Statement>[];
    var cond = expressionRewriter!.rewrite(stmt.condition, condEffects);
    if (stmt.message == null) {
      stmt.condition = cond..parent = stmt;
      // If the translation of the condition produced a non-empty list of
      // statements, ensure they are guarded by whether asserts are enabled.
      statements.add(
          condEffects.isEmpty ? stmt : new AssertBlock(condEffects..add(stmt)));
      return removalSentinel ?? EmptyStatement();
    }

    // The translation depends on the translation of the message, by cases.
    Statement result;
    var msgEffects = <Statement>[];
    stmt.message = expressionRewriter!.rewrite(stmt.message!, msgEffects)
      ..parent = stmt;
    if (condEffects.isEmpty) {
      if (msgEffects.isEmpty) {
        // The condition rewrote to ([], C) and the message rewrote to ([], M).
        // The result is
        //
        // assert(C, M)
        stmt.condition = cond..parent = stmt;
        result = stmt;
      } else {
        // The condition rewrote to ([], C) and the message rewrote to (S*, M)
        // where S* is non-empty.  The result is
        //
        // assert { if (C) {} else { S*; assert(false, M); }}
        stmt.condition = new BoolLiteral(false)..parent = stmt;
        result = new AssertBlock([
          new IfStatement(
              cond, new EmptyStatement(), new Block(msgEffects..add(stmt)))
        ]);
      }
    } else {
      if (msgEffects.isEmpty) {
        // The condition rewrote to (S*, C) where S* is non-empty and the
        // message rewrote to ([], M).  The result is
        //
        // assert { S*; assert(C, M); }
        stmt.condition = cond..parent = stmt;
        condEffects.add(stmt);
      } else {
        // The condition rewrote to (S0*, C) and the message rewrote to (S1*, M)
        // where both S0* and S1* are non-empty.  The result is
        //
        // assert { S0*; if (C) {} else { S1*; assert(false, M); }}
        stmt.condition = new BoolLiteral(false)..parent = stmt;
        condEffects.add(new IfStatement(
            cond, new EmptyStatement(), new Block(msgEffects..add(stmt))));
      }
      result = new AssertBlock(condEffects);
    }
    statements.add(result);
    return removalSentinel ?? EmptyStatement();
  }

  Statement visitDelimited(Statement stmt) {
    var saved = statements;
    statements = <Statement>[];
    transform(stmt);
    Statement result =
        statements.length == 1 ? statements.first : new Block(statements);
    statements = saved;
    return result;
  }

  @override
  TreeNode visitLabeledStatement(
      LabeledStatement stmt, TreeNode? removalSentinel) {
    stmt.body = visitDelimited(stmt.body)..parent = stmt;
    statements.add(stmt);
    return removalSentinel ?? EmptyStatement();
  }

  @override
  TreeNode visitBreakStatement(BreakStatement stmt, TreeNode? removalSentinel) {
    statements.add(stmt);
    return removalSentinel ?? EmptyStatement();
  }

  @override
  TreeNode visitWhileStatement(WhileStatement stmt, TreeNode? removalSentinel) {
    Statement body = visitDelimited(stmt.body);
    List<Statement> effects = <Statement>[];
    Expression cond = expressionRewriter!.rewrite(stmt.condition, effects);
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
    return removalSentinel ?? EmptyStatement();
  }

  @override
  TreeNode visitDoStatement(DoStatement stmt, TreeNode? removalSentinel) {
    Statement body = visitDelimited(stmt.body);
    List<Statement> effects = <Statement>[];
    stmt.condition = expressionRewriter!.rewrite(stmt.condition, effects)
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
    return removalSentinel ?? EmptyStatement();
  }

  @override
  TreeNode visitForStatement(ForStatement stmt, TreeNode? removalSentinel) {
    // Because of for-loop scoping and variable capture, it is tricky to deal
    // with await in the loop's variable initializers or update expressions.
    bool isSimple = true;
    int length = stmt.variables.length;
    List<List<Statement>> initEffects =
        new List<List<Statement>>.generate(length, (int i) {
      VariableDeclaration decl = stmt.variables[i];
      List<Statement> statements = <Statement>[];
      if (decl.initializer != null) {
        decl.initializer = expressionRewriter!
            .rewrite(decl.initializer!, statements)
          ..parent = decl;
      }
      isSimple = isSimple && statements.isEmpty;
      return statements;
    });

    length = stmt.updates.length;
    List<List<Statement>> updateEffects =
        new List<List<Statement>>.generate(length, (int i) {
      List<Statement> statements = <Statement>[];
      stmt.updates[i] = expressionRewriter!.rewrite(stmt.updates[i], statements)
        ..parent = stmt;
      isSimple = isSimple && statements.isEmpty;
      return statements;
    });

    Statement body = visitDelimited(stmt.body);
    Expression? cond = stmt.condition;
    List<Statement>? condEffects;
    if (cond != null) {
      condEffects = <Statement>[];
      cond = expressionRewriter!.rewrite(stmt.condition!, condEffects);
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
            .add(new IfStatement(cond!, body, new BreakStatement(labeled)));
        stmt.body = new Block(condEffects)..parent = stmt;
        statements.add(labeled);
      }
      return removalSentinel ?? EmptyStatement();
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
    // Add assignments to the loop variables from the previous iterations temp
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
            new ExpressionStatement(new VariableSet(decl, decl.initializer!)));
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
      loopBody.addAll(condEffects!);
    } else {
      cond = new BoolLiteral(true);
    }
    loopBody.add(
        new IfStatement(cond, new Block(newBody), new BreakStatement(labeled)));
    labeled.body =
        new WhileStatement(new BoolLiteral(true), new Block(loopBody))
          ..parent = labeled;
    statements.add(new Block(<Statement>[]
      ..addAll(temps)
      ..add(labeled)));
    return removalSentinel ?? EmptyStatement();
  }

  @override
  TreeNode visitForInStatement(ForInStatement stmt, TreeNode? removalSentinel) {
    if (stmt.isAsync) {
      // Transform
      //
      //   await for (T variable in <stream-expression>) { ... }
      //
      // To (in product mode):
      //
      //   {
      //     :stream = <stream-expression>;
      //     _StreamIterator<T> :for-iterator = new _StreamIterator<T>(:stream);
      //     try {
      //       while (await :for-iterator.moveNext()) {
      //         T <variable> = :for-iterator.current;
      //         ...
      //       }
      //     } finally {
      //       if (:for-iterator._subscription != null)
      //           await :for-iterator.cancel();
      //     }
      //   }
      //
      // Or (in non-product mode):
      //
      //   {
      //     :stream = <stream-expression>;
      //     _StreamIterator<T> :for-iterator = new _StreamIterator<T>(:stream);
      //     try {
      //       while (let _ = _asyncStarMoveNextHelper(:stream) in
      //           await :for-iterator.moveNext()) {
      //         T <variable> = :for-iterator.current;
      //         ...
      //       }
      //     } finally {
      //       if (:for-iterator._subscription != null)
      //           await :for-iterator.cancel();
      //     }
      //   }
      var valueVariable = stmt.variable;

      var streamVariable = new VariableDeclaration(ContinuationVariables.stream,
          initializer: stmt.iterable,
          type: stmt.iterable.getStaticType(staticTypeContext));

      final streamIteratorType = new InterfaceType(helper.streamIteratorClass,
          staticTypeContext.nullable, [valueVariable.type]);
      var forIteratorVariable = VariableDeclaration(
          ContinuationVariables.forIterator,
          initializer: new ConstructorInvocation(
              helper.streamIteratorConstructor,
              new Arguments(<Expression>[new VariableGet(streamVariable)],
                  types: [valueVariable.type])),
          type: streamIteratorType);

      // await :for-iterator.moveNext()
      var condition = new AwaitExpression(new InstanceInvocation(
          InstanceAccessKind.Instance,
          VariableGet(forIteratorVariable),
          helper.streamIteratorMoveNext.name,
          new Arguments([]),
          interfaceTarget: helper.streamIteratorMoveNext,
          functionType:
              helper.streamIteratorMoveNext.getterType as FunctionType))
        ..fileOffset = stmt.fileOffset;

      Expression whileCondition;
      if (helper.productMode) {
        whileCondition = condition;
      } else {
        // _asyncStarMoveNextHelper(:stream)
        var asyncStarMoveNextCall = new StaticInvocation(
            helper.asyncStarMoveNextHelper,
            new Arguments([new VariableGet(streamVariable)]))
          ..fileOffset = stmt.fileOffset;

        // let _ = asyncStarMoveNextCall in (condition)
        whileCondition = new Let(
            new VariableDeclaration(null, initializer: asyncStarMoveNextCall),
            condition);
      }

      // T <variable> = :for-iterator.current;
      valueVariable.initializer = new InstanceGet(InstanceAccessKind.Instance,
          VariableGet(forIteratorVariable), helper.streamIteratorCurrent.name,
          interfaceTarget: helper.streamIteratorCurrent,
          resultType: valueVariable.type)
        ..fileOffset = stmt.bodyOffset;
      valueVariable.initializer!.parent = valueVariable;

      var whileBody = new Block(<Statement>[valueVariable, stmt.body]);
      var tryBody = new WhileStatement(whileCondition, whileBody);

      // if (:for-iterator._subscription != null) await :for-iterator.cancel();
      final DartType subscriptionType =
          Substitution.fromInterfaceType(streamIteratorType).substituteType(
              helper.coreTypes.streamIteratorSubscription.getterType);
      var tryFinalizer = new IfStatement(
          new Not(new EqualsNull(new InstanceGet(
              InstanceAccessKind.Instance,
              VariableGet(forIteratorVariable),
              helper.coreTypes.streamIteratorSubscription.name,
              interfaceTarget: helper.coreTypes.streamIteratorSubscription,
              resultType: subscriptionType))),
          new ExpressionStatement(new AwaitExpression(new InstanceInvocation(
              InstanceAccessKind.Instance,
              VariableGet(forIteratorVariable),
              helper.streamIteratorCancel.name,
              new Arguments(<Expression>[]),
              interfaceTarget: helper.streamIteratorCancel,
              functionType:
                  helper.streamIteratorCancel.getterType as FunctionType))),
          null);

      var tryFinally = new TryFinally(tryBody, tryFinalizer);

      var block = new Block(
          <Statement>[streamVariable, forIteratorVariable, tryFinally]);
      transform<Statement>(block);
      return removalSentinel ?? EmptyStatement();
    } else {
      super.visitForInStatement(stmt, removalSentinel);
      return removalSentinel ?? EmptyStatement();
    }
  }

  @override
  TreeNode visitSwitchStatement(
      SwitchStatement stmt, TreeNode? removalSentinel) {
    stmt.expression = expressionRewriter!.rewrite(stmt.expression, statements)
      ..parent = stmt;
    for (var switchCase in stmt.cases) {
      // Expressions in switch cases cannot contain await so they do not need to
      // be translated.
      switchCase.body = visitDelimited(switchCase.body)..parent = switchCase;
    }
    statements.add(stmt);
    return removalSentinel ?? EmptyStatement();
  }

  @override
  TreeNode visitContinueSwitchStatement(
      ContinueSwitchStatement stmt, TreeNode? removalSentinel) {
    statements.add(stmt);
    return removalSentinel ?? EmptyStatement();
  }

  @override
  TreeNode visitIfStatement(IfStatement stmt, TreeNode? removalSentinel) {
    stmt.condition = expressionRewriter!.rewrite(stmt.condition, statements)
      ..parent = stmt;
    stmt.then = visitDelimited(stmt.then)..parent = stmt;
    if (stmt.otherwise != null) {
      stmt.otherwise = visitDelimited(stmt.otherwise!)..parent = stmt;
    }
    statements.add(stmt);
    return removalSentinel ?? EmptyStatement();
  }

  @override
  TreeNode visitTryCatch(TryCatch stmt, TreeNode? removalSentinel) {
    ++currentTryDepth;
    stmt.body = visitDelimited(stmt.body)..parent = stmt;
    --currentTryDepth;

    ++currentCatchDepth;
    for (var clause in stmt.catches) {
      clause.body = visitDelimited(clause.body)..parent = clause;
    }
    --currentCatchDepth;
    statements.add(stmt);
    return removalSentinel ?? EmptyStatement();
  }

  @override
  TreeNode visitTryFinally(TryFinally stmt, TreeNode? removalSentinel) {
    ++currentTryDepth;
    stmt.body = visitDelimited(stmt.body)..parent = stmt;
    --currentTryDepth;
    ++currentCatchDepth;
    stmt.finalizer = visitDelimited(stmt.finalizer)..parent = stmt;
    --currentCatchDepth;
    statements.add(stmt);
    return removalSentinel ?? EmptyStatement();
  }

  @override
  TreeNode visitYieldStatement(YieldStatement stmt, TreeNode? removalSentinel) {
    stmt.expression = expressionRewriter!.rewrite(stmt.expression, statements)
      ..parent = stmt;
    statements.add(stmt);
    return removalSentinel ?? EmptyStatement();
  }

  @override
  TreeNode visitVariableDeclaration(
      VariableDeclaration stmt, TreeNode? removalSentinel) {
    if (stmt.initializer != null) {
      stmt.initializer = expressionRewriter!
          .rewrite(stmt.initializer!, statements)
        ..parent = stmt;
    }
    statements.add(stmt);
    return removalSentinel ?? EmptyStatement();
  }

  @override
  TreeNode visitFunctionDeclaration(
      FunctionDeclaration stmt, TreeNode? removalSentinel) {
    stmt.function = transform(stmt.function)..parent = stmt;
    statements.add(stmt);
    return removalSentinel ?? EmptyStatement();
  }

  @override
  TreeNode defaultExpression(TreeNode node, TreeNode? removalSentinel) =>
      throw 'unreachable $node';
}

class AsyncStarFunctionRewriter extends AsyncRewriterBase {
  VariableDeclaration? controllerVariable;

  AsyncStarFunctionRewriter(HelperNodes helper, FunctionNode enclosingFunction,
      StatefulStaticTypeContext staticTypeContext)
      : super(helper, enclosingFunction, staticTypeContext);

  FunctionNode rewrite() {
    var statements = <Statement>[];

    final elementType = elementTypeFromReturnType(helper.streamClass);

    // _AsyncStarStreamController<T> :controller;
    controllerVariable = new VariableDeclaration(
        ContinuationVariables.controller,
        type: new InterfaceType(helper.asyncStarStreamControllerClass,
            staticTypeContext.nullable, [elementType]));
    statements.add(controllerVariable!);

    // dynamic :controller_stream;
    VariableDeclaration controllerStreamVariable =
        new VariableDeclaration(ContinuationVariables.controllerStreamVar);
    statements.add(controllerStreamVariable);

    setupAsyncContinuations(statements);

    // :controller = new _AsyncStarStreamController<T>(:async_op);
    var arguments = new Arguments(
        <Expression>[new VariableGet(nestedClosureVariable)],
        types: [elementType]);
    var buildController = new ConstructorInvocation(
        helper.asyncStarStreamControllerConstructor, arguments)
      ..fileOffset = enclosingFunction.fileOffset;
    var setController = new ExpressionStatement(
        new VariableSet(controllerVariable!, buildController));
    statements.add(setController);

    // :controller_stream = :controller.stream;
    var completerGet = new VariableGet(controllerVariable!);
    statements.add(new ExpressionStatement(new VariableSet(
        controllerStreamVariable,
        new InstanceGet(InstanceAccessKind.Instance, completerGet,
            helper.asyncStarStreamControllerStream.name,
            interfaceTarget: helper.asyncStarStreamControllerStream,
            resultType: Substitution.fromInterfaceType(
                    controllerVariable!.type as InterfaceType)
                .substituteType(
                    helper.asyncStarStreamControllerStream.getterType)))));

    // return :controller_stream;
    var returnStatement =
        new ReturnStatement(new VariableGet(controllerStreamVariable));
    statements.add(returnStatement);

    enclosingFunction.body = new Block(statements)..parent = enclosingFunction;
    enclosingFunction.asyncMarker = AsyncMarker.Sync;
    return enclosingFunction;
  }

  @override
  Statement buildWrappedBody() {
    ++currentTryDepth;
    Statement body = super.buildWrappedBody();
    --currentTryDepth;

    var finallyBody = new ExpressionStatement(new InstanceInvocation(
        InstanceAccessKind.Instance,
        new VariableGet(controllerVariable!),
        helper.asyncStarStreamControllerClose.name,
        new Arguments([]),
        interfaceTarget: helper.asyncStarStreamControllerClose,
        functionType:
            helper.asyncStarStreamControllerClose.getterType as FunctionType));

    var tryFinally = new TryFinally(body, new Block(<Statement>[finallyBody]));
    return tryFinally;
  }

  @override
  Statement buildCatchBody(VariableDeclaration exceptionVariable,
      VariableDeclaration stackTraceVariable) {
    return new ExpressionStatement(new InstanceInvocation(
        InstanceAccessKind.Instance,
        new VariableGet(controllerVariable!),
        helper.asyncStarStreamControllerAddError.name,
        new Arguments(<Expression>[
          new VariableGet(exceptionVariable),
          new VariableGet(stackTraceVariable)
        ]),
        interfaceTarget: helper.asyncStarStreamControllerAddError,
        functionType: helper.asyncStarStreamControllerAddError.getterType
            as FunctionType));
  }

  @override
  Statement buildReturn(Statement body) {
    // Async* functions cannot return a value.  The returns from the function
    // have been translated into breaks from the labeled body.
    return new Block(<Statement>[
      body,
      new ReturnStatement()..fileOffset = enclosingFunction.fileEndOffset,
    ]);
  }

  @override
  TreeNode visitYieldStatement(YieldStatement stmt, TreeNode? removalSentinel) {
    Expression expr = expressionRewriter!.rewrite(stmt.expression, statements);

    final Procedure addMethod = stmt.isYieldStar
        ? helper.asyncStarStreamControllerAddStream
        : helper.asyncStarStreamControllerAdd;
    final FunctionType addMethodFunctionType = Substitution.fromInterfaceType(
            controllerVariable!.type as InterfaceType)
        .substituteType(addMethod.getterType) as FunctionType;
    var addExpression = new InstanceInvocation(
        InstanceAccessKind.Instance,
        new VariableGet(controllerVariable!),
        addMethod.name,
        new Arguments(<Expression>[expr]),
        interfaceTarget: addMethod,
        functionType: addMethodFunctionType)
      ..fileOffset = stmt.fileOffset;

    statements.add(new IfStatement(
        addExpression,
        new ReturnStatement(new NullLiteral()),
        createContinuationPoint()..fileOffset = stmt.fileOffset));
    return removalSentinel ?? EmptyStatement();
  }

  @override
  TreeNode visitReturnStatement(
      ReturnStatement node, TreeNode? removalSentinel) {
    // Async* functions cannot return a value.
    assert(node.expression == null || node.expression is NullLiteral);
    statements
        .add(new BreakStatement(labeledBody!)..fileOffset = node.fileOffset);
    return removalSentinel ?? EmptyStatement();
  }
}

class AsyncFunctionRewriter extends AsyncRewriterBase {
  VariableDeclaration? returnVariable;
  VariableDeclaration? asyncFutureVariable;
  VariableDeclaration? isSyncVariable;

  // In general an async functions such as
  //
  //     Future<X> foo() async { return <expr>; }
  //
  // can return as `<expr>` either X or Future<X>, i.e. it can return
  // FutureOr<X>
  //
  // If we know it doesn't return any object of type `Future`, we can optimize
  // the future completion process by avoiding some expensive `is Future<T>`
  // type checks on the returned value.
  late bool canReturnFuture;

  AsyncFunctionRewriter(HelperNodes helper, FunctionNode enclosingFunction,
      StatefulStaticTypeContext staticTypeContext)
      : super(helper, enclosingFunction, staticTypeContext);

  FunctionNode rewrite() {
    var statements = <Statement>[];

    // The original function return type should be Future<T> or FutureOr<T>
    // because the function is async. If it was, we make a Completer<T>,
    // otherwise we make a malformed type.  In a "Future<T> foo() async {}"
    // function the body can either return a "T" or a "Future<T>" => a
    // "FutureOr<T>".
    DartType valueType = elementTypeFromReturnType(helper.futureClass);
    if (valueType == const DynamicType()) {
      valueType = elementTypeFromAsyncReturnType();
    }
    final DartType returnType =
        FutureOrType(valueType, staticTypeContext.nullable);
    final futureTypeArguments = <DartType>[valueType];

    final futureType = InterfaceType(helper.futureImplClass,
        staticTypeContext.nonNullable, futureTypeArguments);

    // final _Future<T> :async_future = _Future<T>();
    asyncFutureVariable = VariableDeclaration(ContinuationVariables.asyncFuture,
        initializer: ConstructorInvocation(helper.futureImplConstructor,
            Arguments([], types: futureTypeArguments))
          ..fileOffset = enclosingFunction.body?.fileOffset ?? -1,
        isFinal: true,
        type: futureType);
    statements.add(asyncFutureVariable!);

    // bool :is_sync = false;
    isSyncVariable = VariableDeclaration(ContinuationVariables.isSync,
        initializer: BoolLiteral(false),
        type: helper.coreTypes.boolLegacyRawType);
    statements.add(isSyncVariable!);

    // asy::FutureOr<T>* :return_value;
    returnVariable = VariableDeclaration(ContinuationVariables.returnValue,
        type: returnType);
    statements.add(returnVariable!);

    canReturnFuture = false;

    setupAsyncContinuations(statements);

    // If we could prove the function doesn't return a `Future` we change the
    // type of `:return_value`.
    if (!canReturnFuture) {
      returnVariable!.type =
          valueType.withDeclaredNullability(Nullability.nullable);
    }

    // :async_op();
    final startStatement = ExpressionStatement(LocalFunctionInvocation(
        nestedClosureVariable, Arguments([]),
        functionType: FunctionType(
            [], const DynamicType(), staticTypeContext.nonNullable))
      ..fileOffset = enclosingFunction.fileOffset);
    statements.add(startStatement);

    // :is_sync = true;
    final setIsSync =
        ExpressionStatement(VariableSet(isSyncVariable!, BoolLiteral(true)));
    statements.add(setIsSync);

    // return :async_future;
    statements.add(ReturnStatement(VariableGet(asyncFutureVariable!)));

    enclosingFunction.body = Block(statements)..parent = enclosingFunction;
    enclosingFunction.asyncMarker = AsyncMarker.Sync;
    return enclosingFunction;
  }

  // :async_op's try-catch catch body:
  @override
  Statement buildCatchBody(exceptionVariable, stackTraceVariable) {
    // _completeOnAsyncError(_future, e, st, :is_sync)
    return ExpressionStatement(StaticInvocation(
        helper.completeOnAsyncError,
        Arguments([
          VariableGet(asyncFutureVariable!),
          VariableGet(exceptionVariable),
          VariableGet(stackTraceVariable),
          VariableGet(isSyncVariable!)
        ])));
  }

  // :async_op's try-catch try body:
  @override
  Statement buildReturn(Statement body) {
    // Returns from the body have all been translated into assignments to the
    // return value variable followed by a break from the labeled body.

    // .. body ..
    // _completeOnAsyncReturn(_future, returnVariable, :is_sync)
    // return;
    return Block(<Statement>[
      body,
      ExpressionStatement(StaticInvocation(
          canReturnFuture
              ? helper.completeOnAsyncReturn
              : helper.completeWithNoFutureOnAsyncReturn,
          Arguments([
            VariableGet(asyncFutureVariable!),
            VariableGet(returnVariable!),
            VariableGet(isSyncVariable!)
          ]))),
      ReturnStatement()..fileOffset = enclosingFunction.fileEndOffset
    ]);
  }

  @override
  TreeNode visitReturnStatement(
      ReturnStatement node, TreeNode? removalSentinel) {
    final expression = node.expression;
    if (expression != null && !canReturnFuture) {
      final returnedType = staticTypeContext.getExpressionType(expression);
      canReturnFuture = _canHoldFutureObject(returnedType);
    }

    final transformedExpression = node.expression == null
        ? NullLiteral()
        : expressionRewriter!.rewrite(node.expression!, statements);
    statements.add(ExpressionStatement(
        VariableSet(returnVariable!, transformedExpression)
          ..fileOffset = node.fileOffset));
    statements.add(BreakStatement(labeledBody!));
    return removalSentinel ?? EmptyStatement();
  }

  bool _canHoldFutureObject(DartType type) {
    // Any supertype or subtype of `FutureOr` may hold a `Future` object.
    final env = staticTypeContext.typeEnvironment;

    if (type is TypeParameterType) {
      type = type.parameter.defaultType;
    }

    if (type is FutureOrType) return true;

    // Any supertype of Future (which includes Future/Object/dynamic) can hold
    // Future objects.
    if (env.isSubtypeOf(
        helper.futureType, type, SubtypeCheckMode.ignoringNullabilities)) {
      return true;
    }

    // Any subtype of Future (which includes Future/_Future and any user-defined
    // implementations) can hold Future objects.
    if (env.isSubtypeOf(
        type, helper.futureType, SubtypeCheckMode.ignoringNullabilities)) {
      return true;
    }
    return false;
  }
}

class HelperNodes {
  final Procedure asyncErrorWrapper;
  final Library asyncLibrary;
  final Procedure asyncStarStreamControllerAdd;
  final Procedure asyncStarStreamControllerAddError;
  final Procedure asyncStarStreamControllerAddStream;
  final Class asyncStarStreamControllerClass;
  final Procedure asyncStarStreamControllerClose;
  final Constructor asyncStarStreamControllerConstructor;
  final Member asyncStarStreamControllerStream;
  final Procedure asyncStarMoveNextHelper;
  final Procedure asyncThenWrapper;
  final Procedure awaitHelper;
  final Procedure completeOnAsyncReturn;
  final Procedure completeWithNoFutureOnAsyncReturn;
  final Procedure completeOnAsyncError;
  final Library coreLibrary;
  final CoreTypes coreTypes;
  final Class futureClass;
  final Class futureOrClass;
  final Class futureImplClass;
  final Constructor futureImplConstructor;
  final Class iterableClass;
  final Class streamClass;
  final Procedure streamIteratorCancel;
  final Class streamIteratorClass;
  final Constructor streamIteratorConstructor;
  final Member streamIteratorCurrent;
  final Procedure streamIteratorMoveNext;
  final Constructor syncIterableConstructor;
  final Class syncIteratorClass;
  final Member syncIteratorCurrent;
  final Member syncIteratorYieldEachIterable;
  final Class boolClass;
  final Procedure unsafeCast;
  final DartType futureType;

  bool productMode;

  HelperNodes._(
      this.asyncErrorWrapper,
      this.asyncLibrary,
      this.asyncStarStreamControllerAdd,
      this.asyncStarStreamControllerAddError,
      this.asyncStarStreamControllerAddStream,
      this.asyncStarStreamControllerClass,
      this.asyncStarStreamControllerClose,
      this.asyncStarStreamControllerConstructor,
      this.asyncStarStreamControllerStream,
      this.asyncStarMoveNextHelper,
      this.asyncThenWrapper,
      this.awaitHelper,
      this.completeOnAsyncReturn,
      this.completeWithNoFutureOnAsyncReturn,
      this.completeOnAsyncError,
      this.coreLibrary,
      this.coreTypes,
      this.futureClass,
      this.futureOrClass,
      this.futureImplClass,
      this.futureImplConstructor,
      this.iterableClass,
      this.streamClass,
      this.streamIteratorCancel,
      this.streamIteratorClass,
      this.streamIteratorConstructor,
      this.streamIteratorCurrent,
      this.streamIteratorMoveNext,
      this.syncIterableConstructor,
      this.syncIteratorClass,
      this.syncIteratorCurrent,
      this.syncIteratorYieldEachIterable,
      this.boolClass,
      this.productMode,
      this.unsafeCast)
      : futureType = InterfaceType(
            futureClass, Nullability.nonNullable, [DynamicType()]);

  factory HelperNodes.fromCoreTypes(CoreTypes coreTypes, bool productMode) {
    return new HelperNodes._(
        coreTypes.asyncErrorWrapperHelperProcedure,
        coreTypes.asyncLibrary,
        coreTypes.asyncStarStreamControllerAdd,
        coreTypes.asyncStarStreamControllerAddError,
        coreTypes.asyncStarStreamControllerAddStream,
        coreTypes.asyncStarStreamControllerClass,
        coreTypes.asyncStarStreamControllerClose,
        coreTypes.asyncStarStreamControllerDefaultConstructor,
        coreTypes.asyncStarStreamControllerStream,
        coreTypes.asyncStarMoveNextHelper,
        coreTypes.asyncThenWrapperHelperProcedure,
        coreTypes.awaitHelperProcedure,
        coreTypes.completeOnAsyncReturn,
        coreTypes.completeWithNoFutureOnAsyncReturn,
        coreTypes.completeOnAsyncError,
        coreTypes.coreLibrary,
        coreTypes,
        coreTypes.futureClass,
        coreTypes.deprecatedFutureOrClass,
        coreTypes.futureImplClass,
        coreTypes.futureImplConstructor,
        coreTypes.iterableClass,
        coreTypes.streamClass,
        coreTypes.streamIteratorCancel,
        coreTypes.streamIteratorClass,
        coreTypes.streamIteratorDefaultConstructor,
        coreTypes.streamIteratorCurrent,
        coreTypes.streamIteratorMoveNext,
        coreTypes.syncIterableDefaultConstructor,
        coreTypes.syncIteratorClass,
        coreTypes.syncIteratorCurrent,
        coreTypes.syncIteratorYieldEachIterable,
        coreTypes.boolClass,
        productMode,
        coreTypes.index.getTopLevelMember('dart:_internal', 'unsafeCast')
            as Procedure);
  }
}
