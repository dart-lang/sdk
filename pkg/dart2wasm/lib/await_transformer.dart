// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart2wasm/async.dart' as asyncCodeGen;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';

/// This pass lifts `await` expressions to the top-level. After the pass, all
/// `await` expressions will have the form:
///
///   final $temp = await <simple expr>;
///
/// where `<simple expr>` is an expression without `await`.
///
/// `await`s in block expressions are also lifted to the statement level.
///
/// The idea is that after this pass every `await` will have a simple
/// continuation of "assign the awaited value to the variable, continue with
/// the next statement". This allows simple code generation for async inner
/// functions.
///
/// The implementation is mostly copied from the old VM async/await transformer
/// with some changes. The old pass was removed in commit 94c120a.
void transformLibraries(
    List<Library> libraries, ClassHierarchy hierarchy, CoreTypes coreTypes) {
  final typeEnv = TypeEnvironment(coreTypes, hierarchy);

  var rewriter =
      _AwaitTransformer(StatefulStaticTypeContext.stacked(typeEnv), coreTypes);

  for (var library in libraries) {
    rewriter.transform(library);
  }
}

class _AwaitTransformer extends Transformer {
  final StatefulStaticTypeContext staticTypeContext;

  final CoreTypes coreTypes;

  List<Statement> statements = <Statement>[];

  late final _ExpressionTransformer expressionTransformer;

  _AwaitTransformer(this.staticTypeContext, this.coreTypes) {
    expressionTransformer =
        _ExpressionTransformer(this, staticTypeContext, coreTypes);
  }

  @override
  TreeNode visitField(Field node) {
    staticTypeContext.enterMember(node);
    super.visitField(node);
    staticTypeContext.leaveMember(node);
    return node;
  }

  @override
  TreeNode visitConstructor(Constructor node) {
    staticTypeContext.enterMember(node);
    final result = super.visitConstructor(node);
    staticTypeContext.leaveMember(node);
    return result;
  }

  @override
  TreeNode visitProcedure(Procedure node) {
    staticTypeContext.enterMember(node);
    final result = node.isAbstract ? node : super.visitProcedure(node);
    staticTypeContext.leaveMember(node);
    return result;
  }

  @override
  TreeNode visitFunctionNode(FunctionNode node) {
    final Statement? body = node.body;
    if (body != null) {
      final transformer = _AwaitTransformer(staticTypeContext, coreTypes);
      Statement newBody = transformer.transform(body);

      final List<Statement> newStatements = [
        ...transformer.expressionTransformer.variables,
        ...transformer.statements,
      ];

      if (newStatements.isNotEmpty) {
        newBody = Block([
          ...newStatements,
          ...newBody is Block ? newBody.statements : [newBody]
        ]);
      }

      node.body = newBody..parent = node;
    }
    return node;
  }

  @override
  TreeNode visitAssertBlock(AssertBlock stmt) {
    final savedStatements = statements;
    statements = [];
    for (final stmt in stmt.statements) {
      statements.add(transform(stmt));
    }
    final newBlock = AssertBlock(statements);
    statements = savedStatements;
    return newBlock;
  }

  @override
  TreeNode visitAssertStatement(AssertStatement stmt) {
    final List<Statement> condEffects = [];
    final cond = expressionTransformer.rewrite(stmt.condition, condEffects);
    final msg = stmt.message;
    if (msg == null) {
      stmt.condition = cond..parent = stmt;
      // If the translation of the condition produced a non-empty list of
      // statements, ensure they are guarded by whether asserts are enabled.
      return condEffects.isEmpty ? stmt : AssertBlock(condEffects..add(stmt));
    }

    // The translation depends on the translation of the message.
    final List<Statement> msgEffects = [];
    stmt.message = expressionTransformer.rewrite(msg, msgEffects)
      ..parent = stmt;
    if (condEffects.isEmpty) {
      if (msgEffects.isEmpty) {
        // The condition rewrote to ([], C) and the message rewrote to ([], M).
        // The result is
        //
        // assert(C, M)
        stmt.condition = cond..parent = stmt;
        return stmt;
      } else {
        // The condition rewrote to ([], C) and the message rewrote to (S*, M)
        // where S* is non-empty.  The result is
        //
        // assert { if (C) {} else { S*; assert(false, M); }}
        stmt.condition = BoolLiteral(false)..parent = stmt;
        return AssertBlock([
          IfStatement(cond, EmptyStatement(), Block(msgEffects..add(stmt)))
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
        stmt.condition = BoolLiteral(false)..parent = stmt;
        condEffects.add(
            IfStatement(cond, EmptyStatement(), Block(msgEffects..add(stmt))));
      }
      return AssertBlock(condEffects);
    }
  }

  @override
  TreeNode visitBlock(Block stmt) {
    final savedStatements = statements;
    statements = [];
    for (final statement in stmt.statements) {
      final newStatement = transform(statement);
      statements.add(newStatement);
    }
    final newBlock = Block(statements);
    statements = savedStatements;
    return newBlock;
  }

  @override
  TreeNode visitBreakStatement(BreakStatement stmt) => stmt;

  @override
  TreeNode visitContinueSwitchStatement(ContinueSwitchStatement stmt) => stmt;

  Statement visitDelimited(Statement stmt) {
    final saved = statements;
    statements = [];
    statements.add(transform(stmt));
    final result =
        statements.length == 1 ? statements.first : Block(statements);
    statements = saved;
    return result;
  }

  @override
  TreeNode visitDoStatement(DoStatement stmt) {
    Statement body = visitDelimited(stmt.body); // block or single statement
    final List<Statement> effects = [];
    stmt.condition = expressionTransformer.rewrite(stmt.condition, effects)
      ..parent = stmt;
    if (effects.isNotEmpty) {
      // The condition rewrote to a non-empty sequence of statements S* and
      // value V.  Add the statements to the end of the loop body.
      final Block block = body is Block ? body : body = Block([body]);
      for (final effect in effects) {
        block.statements.add(effect);
        effect.parent = body;
      }
    }
    stmt.body = body..parent = stmt;
    return stmt;
  }

  @override
  TreeNode visitEmptyStatement(EmptyStatement stmt) => stmt;

  @override
  TreeNode visitExpressionStatement(ExpressionStatement stmt) {
    stmt.expression = expressionTransformer.rewrite(stmt.expression, statements)
      ..parent = stmt;
    return stmt;
  }

  @override
  TreeNode visitForInStatement(ForInStatement stmt) {
    throw 'For statement at ${stmt.location}';
  }

  @override
  TreeNode visitForStatement(ForStatement stmt) {
    // Because of for-loop scoping and variable capture, it is tricky to deal
    // with await in the loop's variable initializers or update expressions.
    bool isSimple = true;
    int length = stmt.variables.length;
    List<List<Statement>> initEffects =
        List<List<Statement>>.generate(length, (int i) {
      VariableDeclaration decl = stmt.variables[i];
      List<Statement> statements = <Statement>[];
      if (decl.initializer != null) {
        decl.initializer = expressionTransformer.rewrite(
            decl.initializer!, statements)
          ..parent = decl;
      }
      isSimple = isSimple && statements.isEmpty;
      return statements;
    });

    length = stmt.updates.length;
    List<List<Statement>> updateEffects =
        List<List<Statement>>.generate(length, (int i) {
      List<Statement> statements = <Statement>[];
      stmt.updates[i] = expressionTransformer.rewrite(
          stmt.updates[i], statements)
        ..parent = stmt;
      isSimple = isSimple && statements.isEmpty;
      return statements;
    });

    Statement body = visitDelimited(stmt.body);
    Expression? cond = stmt.condition;
    List<Statement>? condEffects;
    if (cond != null) {
      condEffects = <Statement>[];
      cond = expressionTransformer.rewrite(stmt.condition!, condEffects);
    }

    if (isSimple) {
      // If the condition contains await, we use a translation like the one for
      // while loops, but leaving the variable declarations and the update
      // expressions in place.
      if (condEffects == null || condEffects.isEmpty) {
        if (cond != null) stmt.condition = cond..parent = stmt;
        stmt.body = body..parent = stmt;
        return stmt;
      } else {
        LabeledStatement labeled = LabeledStatement(stmt);
        // No condition in a for loop is the same as true.
        stmt.condition = null;
        condEffects.add(IfStatement(cond!, body, BreakStatement(labeled)));
        stmt.body = Block(condEffects)..parent = stmt;
        return labeled;
      }
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
    List<VariableDeclaration> temps = <VariableDeclaration>[
      VariableDeclaration.forValue(BoolLiteral(true), isFinal: false)
    ];
    List<Statement> loopBody = <Statement>[];
    List<Statement> initializers = <Statement>[
      ExpressionStatement(VariableSet(temps.first, BoolLiteral(false)))
    ];
    List<Statement> updates = <Statement>[];
    List<Statement> newBody = <Statement>[body];
    for (int i = 0; i < stmt.variables.length; ++i) {
      VariableDeclaration decl = stmt.variables[i];
      temps
          .add(VariableDeclaration(null, type: decl.type, isSynthesized: true));
      loopBody.add(decl);
      if (decl.initializer != null) {
        initializers.addAll(initEffects[i]);
        initializers
            .add(ExpressionStatement(VariableSet(decl, decl.initializer!)));
        decl.initializer = null;
      }
      updates
          .add(ExpressionStatement(VariableSet(decl, VariableGet(temps.last))));
      newBody
          .add(ExpressionStatement(VariableSet(temps.last, VariableGet(decl))));
    }
    // Add the updates to their guarded list of statements.
    for (int i = 0; i < stmt.updates.length; ++i) {
      updates.addAll(updateEffects[i]);
      updates.add(ExpressionStatement(stmt.updates[i]));
    }
    // Initializers or updates could be empty.
    loopBody.add(IfStatement(
        VariableGet(temps.first), Block(initializers), Block(updates)));

    LabeledStatement labeled = LabeledStatement(null);
    if (cond != null) {
      loopBody.addAll(condEffects!);
    } else {
      cond = BoolLiteral(true);
    }
    loopBody.add(IfStatement(cond, Block(newBody), BreakStatement(labeled)));
    labeled.body = WhileStatement(BoolLiteral(true), Block(loopBody))
      ..parent = labeled;
    return Block(<Statement>[]
      ..addAll(temps)
      ..add(labeled));
  }

  @override
  TreeNode visitFunctionDeclaration(FunctionDeclaration stmt) {
    stmt.function = transform(stmt.function)..parent = stmt;
    return stmt;
  }

  @override
  TreeNode visitIfStatement(IfStatement stmt) {
    stmt.condition = expressionTransformer.rewrite(stmt.condition, statements)
      ..parent = stmt;
    stmt.then = visitDelimited(stmt.then)..parent = stmt;
    if (stmt.otherwise != null) {
      stmt.otherwise = visitDelimited(stmt.otherwise!)..parent = stmt;
    }
    return stmt;
  }

  @override
  TreeNode visitLabeledStatement(LabeledStatement stmt) {
    stmt.body = visitDelimited(stmt.body)..parent = stmt;
    return stmt;
  }

  @override
  TreeNode visitReturnStatement(ReturnStatement stmt) {
    if (stmt.expression != null) {
      stmt.expression = expressionTransformer.rewrite(
          stmt.expression!, statements)
        ..parent = stmt;
    }

    return stmt;
  }

  @override
  TreeNode visitSwitchStatement(SwitchStatement stmt) {
    stmt.expression = expressionTransformer.rewrite(stmt.expression, statements)
      ..parent = stmt;
    for (final switchCase in stmt.cases) {
      // Expressions in switch cases cannot contain await so they do not need to
      // be translated.
      switchCase.body = visitDelimited(switchCase.body)..parent = switchCase;
    }
    return stmt;
  }

  @override
  TreeNode visitTryCatch(TryCatch stmt) {
    stmt.body = visitDelimited(stmt.body)..parent = stmt;
    for (final catch_ in stmt.catches) {
      // Create a fresh variable for the exception and stack trace: when a
      // catch block has an `await` we use the catch block variables to restore
      // the current exception after the `await`.
      //
      // TODO (omersa): We could mark [TreeNode]s with `await`s and only do this
      if (catch_.exception == null) {
        catch_.exception = VariableDeclaration(null,
            type: InterfaceType(coreTypes.objectClass, Nullability.nonNullable),
            isSynthesized: true)
          ..parent = catch_;
      }
      if (catch_.stackTrace == null) {
        catch_.stackTrace = VariableDeclaration(null,
            type: InterfaceType(
                coreTypes.stackTraceClass, Nullability.nonNullable),
            isSynthesized: true)
          ..parent = catch_;
      }

      var body = visitDelimited(catch_.body);

      // Add uses to exception and stack trace vars so that they will be added
      // to the context if the catch block has an await.
      if (body is Block) {
        body.statements.add(
            ExpressionStatement(VariableGet(catch_.exception!))..parent = body);
        body.statements.add(ExpressionStatement(VariableGet(catch_.stackTrace!))
          ..parent = body);
      } else {
        body = Block([
          body,
          ExpressionStatement(VariableGet(catch_.exception!)),
          ExpressionStatement(VariableGet(catch_.stackTrace!)),
        ]);
      }

      catch_.body = body..parent = catch_;
    }
    return stmt;
  }

  @override
  TreeNode visitTryFinally(TryFinally stmt) {
    // TODO (omersa): Wrapped in a block to be able to get the variable
    // declarations using `parent.statements[0]` etc. when compiling the node.
    // Ideally we may want to create these variables not in kernel but during
    // code generation.

    // Variable for the finalizer block continuation.
    final continuationVar = VariableDeclaration(null,
        initializer: IntLiteral(asyncCodeGen.continuationFallthrough),
        type: InterfaceType(coreTypes.intClass, Nullability.nonNullable),
        isSynthesized: true);

    // When the finalizer continuation is "rethrow", this stores the exception
    // to rethrow.
    final exceptionVar = VariableDeclaration(null,
        type: InterfaceType(coreTypes.objectClass, Nullability.nonNullable),
        isSynthesized: true);

    // When the finalizer continuation is "rethrow", this stores the stack
    // trace of the exception in [exceptionVar].
    final stackTraceVar = VariableDeclaration(null,
        type: InterfaceType(coreTypes.stackTraceClass, Nullability.nonNullable),
        isSynthesized: true);

    final body = visitDelimited(stmt.body);
    var finalizer = visitDelimited(stmt.finalizer);

    // Add a use of `continuationVar` in finally so that it will be added to
    // the context
    if (finalizer is Block) {
      finalizer.statements.add(ExpressionStatement(VariableGet(continuationVar))
        ..parent = finalizer);
      finalizer.statements.add(
          ExpressionStatement(VariableGet(exceptionVar))..parent = finalizer);
      finalizer.statements.add(
          ExpressionStatement(VariableGet(stackTraceVar))..parent = finalizer);
    } else {
      finalizer = Block([
        finalizer,
        ExpressionStatement(VariableGet(continuationVar)),
        ExpressionStatement(VariableGet(exceptionVar)),
        ExpressionStatement(VariableGet(stackTraceVar)),
      ]);
    }

    return Block([
      continuationVar,
      exceptionVar,
      stackTraceVar,
      TryFinally(body, finalizer)
    ]);
  }

  @override
  TreeNode visitVariableDeclaration(VariableDeclaration stmt) {
    final initializer = stmt.initializer;
    if (initializer != null) {
      stmt.initializer = expressionTransformer.rewrite(initializer, statements)
        ..parent = stmt;
    }
    return stmt;
  }

  @override
  TreeNode visitWhileStatement(WhileStatement stmt) {
    final Statement body = visitDelimited(stmt.body);
    final List<Statement> effects = [];
    final Expression cond =
        expressionTransformer.rewrite(stmt.condition, effects);
    if (effects.isEmpty) {
      stmt.condition = cond..parent = stmt;
      stmt.body = body..parent = stmt;
      return stmt;
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
      final LabeledStatement labeled = LabeledStatement(stmt);
      stmt.condition = BoolLiteral(true)..parent = stmt;
      effects.add(IfStatement(cond, body, BreakStatement(labeled)));
      stmt.body = Block(effects)..parent = stmt;
      return labeled;
    }
  }

  @override
  TreeNode visitYieldStatement(YieldStatement stmt) {
    stmt.expression = expressionTransformer.rewrite(stmt.expression, statements)
      ..parent = stmt;
    return stmt;
  }

  @override
  TreeNode defaultStatement(Statement stmt) =>
      throw 'Unhandled statement: $stmt (${stmt.location})';

  @override
  TreeNode defaultExpression(Expression expr) {
    // This visits initializer expressions, annotations etc.
    final List<Statement> effects = [];
    final Expression transformedExpr =
        expressionTransformer.rewrite(expr, effects);
    if (effects.isEmpty) {
      return transformedExpr;
    } else {
      return BlockExpression(Block(effects), expr);
    }
  }
}

class _ExpressionTransformer extends Transformer {
  /// Whether we have seen an await to the right in the expression tree.
  ///
  /// Subexpressions are visited right-to-left in the reverse of evaluation
  /// order.
  ///
  /// On entry to an expression's visit method, [seenAwait] indicates whether a
  /// sibling to the right contains an await.  If so the expression will be
  /// named in a temporary variable because it is potentially live across an
  /// await.
  ///
  /// On exit from an expression's visit method, [seenAwait] indicates whether
  /// the expression itself or a sibling to the right contains an await.
  bool seenAwait = false;

  /// The (reverse order) sequence of statements that have been emitted.
  ///
  /// Transformation of an expression produces a transformed expression and a
  /// sequence of statements which are assignments to local variables, calls to
  /// helper functions, and yield points.  Only the yield points need to be a
  /// statements, and they are statements so an implementation does not have to
  /// handle unnamed expression intermediate live across yield points.
  ///
  /// The visit methods return the transformed expression and build a sequence
  /// of statements by emitting statements into this list.  This list is built
  /// in reverse because children are visited right-to-left.
  ///
  /// If an expression should be named it is named before visiting its children
  /// so the naming assignment appears in the list before all statements
  /// implementing the translation of the children.
  ///
  /// Children that are conditionally evaluated, such as some parts of logical
  /// and conditional expressions, must be delimited so that they do not emit
  /// unguarded statements into [statements].  This is implemented by setting
  /// [statements] to a fresh empty list before transforming those children.
  List<Statement> statements = <Statement>[];

  /// The number of currently live named intermediate values.
  ///
  /// This index is used to allocate names to temporary values.  Because
  /// children are visited right-to-left, names are assigned in reverse order
  /// of index.
  ///
  /// When an assignment is emitted into [statements] to name an expression
  /// before visiting its children, the index is not immediately reserved
  /// because a child can freely use the same name as its parent.  In practice,
  /// this will be the rightmost named child.
  ///
  /// After visiting the children of a named expression, [nameIndex] is set to
  /// indicate one more live value (the value of the expression) than before
  /// visiting the expression.
  ///
  /// After visiting the children of an expression that is not named,
  /// [nameIndex] may still account for names of subexpressions.
  int nameIndex = 0;

  /// Variables created for temporaries.
  final List<VariableDeclaration> variables = <VariableDeclaration>[];

  final _AwaitTransformer _statementTransformer;

  final StatefulStaticTypeContext staticTypeContext;

  final CoreTypes coreTypes;

  _ExpressionTransformer(
      this._statementTransformer, this.staticTypeContext, this.coreTypes);

  // Helpers

  /// Name an expression by emitting an assignment to a temporary variable.
  Expression name(Expression expr) {
    final DartType type = expr.getStaticType(staticTypeContext);
    final VariableDeclaration temp = allocateTemporary(nameIndex, type);
    statements.add(ExpressionStatement(VariableSet(temp, expr)));
    return castVariableGet(temp, type);
  }

  VariableDeclaration allocateTemporary(int index,
      [DartType type = const DynamicType()]) {
    if (variables.length > index) {
      // Re-using a temporary. Re-type it to dynamic if we detect reuse with
      // different type.
      if (variables[index].type != const DynamicType() &&
          variables[index].type != type) {
        variables[index].type = const DynamicType();
      }
      return variables[index];
    }
    for (var i = variables.length; i <= index; i++) {
      variables.add(VariableDeclaration(":async_temporary_${i}", type: type));
    }
    return variables[index];
  }

  /// Casts a [VariableGet] with `as dynamic` if its type is not `dynamic`.
  Expression castVariableGet(VariableDeclaration variable, DartType type) {
    Expression expr = VariableGet(variable);
    if (type != const DynamicType()) {
      expr = AsExpression(expr, DynamicType());
    }
    return expr;
  }

  // Expressions

  /// Rewrite a top-level expression (top-level wrt. a statement). This is the
  /// entry-point from [_AwaitTransformer].
  ///
  /// Rewriting an expression produces a sequence of statements and an
  /// expression. The sequence of statements are added to the given list. Pass
  /// an empty list if the rewritten expression should be delimited from the
  /// surrounding context.
  //
  // TODO (omersa): We should be able to maintain the state for temporaries
  // (`nameIndex`, `variables`) in a separate class and create a new expression
  // transformer every time we transform a top-level expression. Would that
  // make the code clearer?
  Expression rewrite(Expression expression, List<Statement> outer) {
    assert(statements.isEmpty);
    final saved = seenAwait;
    seenAwait = false;
    final Expression result = transform(expression);
    outer.addAll(statements.reversed);
    statements.clear();
    seenAwait = seenAwait || saved;
    return result;
  }

  @override
  TreeNode defaultExpression(Expression expr) =>
      throw 'Unhandled expression: $expr (${expr.location})';

  @override
  TreeNode visitFunctionExpression(FunctionExpression expr) {
    expr.transformChildren(this);
    return expr;
  }

  // Simple literals. These are pure expressions so they can be evaluated after
  // an await to their right.
  @override
  TreeNode visitSymbolLiteral(SymbolLiteral expr) => expr;

  @override
  TreeNode visitTypeLiteral(TypeLiteral expr) => expr;

  @override
  TreeNode visitThisExpression(ThisExpression expr) => expr;

  @override
  TreeNode visitStringLiteral(StringLiteral expr) => expr;

  @override
  TreeNode visitIntLiteral(IntLiteral expr) => expr;

  @override
  TreeNode visitDoubleLiteral(DoubleLiteral expr) => expr;

  @override
  TreeNode visitBoolLiteral(BoolLiteral expr) => expr;

  @override
  TreeNode visitNullLiteral(NullLiteral expr) => expr;

  @override
  TreeNode visitConstantExpression(ConstantExpression expr) => expr;

  @override
  TreeNode visitCheckLibraryIsLoaded(CheckLibraryIsLoaded expr) => expr;

  @override
  TreeNode visitLoadLibrary(LoadLibrary expr) => expr;

  /// Transform expressions with no child expressions.
  Expression nullary(Expression expr) {
    if (seenAwait) {
      expr = name(expr);
      ++nameIndex;
    }
    return expr;
  }

  @override
  TreeNode visitSuperPropertyGet(SuperPropertyGet expr) => nullary(expr);

  @override
  TreeNode visitStaticGet(StaticGet expr) => nullary(expr);

  @override
  TreeNode visitStaticTearOff(StaticTearOff expr) => nullary(expr);

  @override
  TreeNode visitRethrow(Rethrow expr) => nullary(expr);

  @override
  TreeNode visitVariableGet(VariableGet expr) {
    Expression result = expr;
    // Getting a final or const variable is not an effect so it can be
    // evaluated after an await to its right.
    if (seenAwait && !expr.variable.isFinal && !expr.variable.isConst) {
      result = name(expr);
      ++nameIndex;
    }
    return result;
  }

  /// Transform an expression given an action to transform the children. For
  /// this purposes of the await transformer the children should generally be
  /// translated from right to left, in the reverse of evaluation order.
  Expression transformTreeNode(Expression expr, void action(),
      {bool alwaysName = false}) {
    final bool shouldName = alwaysName || seenAwait;

    // 1. If there is an await in a sibling to the right, emit an assignment to
    // a temporary variable before transforming the children.
    final Expression result = shouldName ? name(expr) : expr;

    // 2. Remember the number of live temporaries before transforming the
    // children.
    final int index = nameIndex;

    // 3. Transform the children. Initially they do not have an await in a
    // sibling to their right.
    seenAwait = false;
    action();

    // 4. If the expression was named then the variables used for children are
    // no longer live but the variable used for the expression is. On the other
    // hand, a sibling to the left (yet to be processed) cannot reuse any of
    // the variables used here, as the assignments in the children (here) would
    // overwrite assignments in the siblings to the left, possibly before the
    // use of the overwritten values.
    if (shouldName) {
      if (index + 1 > nameIndex) {
        nameIndex = index + 1;
      }
      seenAwait = true;
    }

    return result;
  }

  /// Transform expressions with one child expression.
  Expression unary(Expression expr) {
    return transformTreeNode(expr, () {
      expr.transformChildren(this);
    });
  }

  @override
  TreeNode visitInvalidExpression(InvalidExpression expr) => unary(expr);

  @override
  TreeNode visitVariableSet(VariableSet expr) => unary(expr);

  @override
  TreeNode visitInstanceGet(InstanceGet expr) => unary(expr);

  @override
  TreeNode visitDynamicGet(DynamicGet expr) => unary(expr);

  @override
  TreeNode visitInstanceTearOff(InstanceTearOff expr) => unary(expr);

  @override
  TreeNode visitSuperPropertySet(SuperPropertySet expr) => unary(expr);

  @override
  TreeNode visitStaticSet(StaticSet expr) => unary(expr);

  @override
  TreeNode visitNot(Not expr) => unary(expr);

  @override
  TreeNode visitIsExpression(IsExpression expr) => unary(expr);

  @override
  TreeNode visitAsExpression(AsExpression expr) => unary(expr);

  @override
  TreeNode visitThrow(Throw expr) => unary(expr);

  @override
  TreeNode visitEqualsNull(EqualsNull expr) => unary(expr);

  @override
  TreeNode visitRecordIndexGet(RecordIndexGet expr) => unary(expr);

  @override
  TreeNode visitRecordNameGet(RecordNameGet expr) => unary(expr);

  @override
  TreeNode visitNullCheck(NullCheck expr) => unary(expr);

  @override
  TreeNode visitInstantiation(Instantiation expr) => unary(expr);

  @override
  TreeNode visitInstanceSet(InstanceSet expr) {
    return transformTreeNode(expr, () {
      expr.value = transform(expr.value)..parent = expr;
      expr.receiver = transform(expr.receiver)..parent = expr;
    });
  }

  @override
  TreeNode visitDynamicSet(DynamicSet expr) {
    return transformTreeNode(expr, () {
      expr.value = transform(expr.value)..parent = expr;
      expr.receiver = transform(expr.receiver)..parent = expr;
    });
  }

  @override
  TreeNode visitArguments(Arguments args) {
    for (final named in args.named.reversed) {
      named.value = transform(named.value)..parent = named;
    }
    final positional = args.positional;
    for (var i = positional.length - 1; i >= 0; --i) {
      positional[i] = transform(positional[i])..parent = args;
    }
    return args;
  }

  @override
  TreeNode visitInstanceInvocation(InstanceInvocation expr) {
    return transformTreeNode(expr, () {
      visitArguments(expr.arguments);
      expr.receiver = transform(expr.receiver)..parent = expr;
    });
  }

  @override
  TreeNode visitLocalFunctionInvocation(LocalFunctionInvocation expr) {
    return transformTreeNode(expr, () {
      visitArguments(expr.arguments);
    });
  }

  @override
  TreeNode visitDynamicInvocation(DynamicInvocation expr) {
    return transformTreeNode(expr, () {
      visitArguments(expr.arguments);
      expr.receiver = transform(expr.receiver)..parent = expr;
    });
  }

  @override
  TreeNode visitFunctionInvocation(FunctionInvocation expr) {
    return transformTreeNode(expr, () {
      visitArguments(expr.arguments);
      expr.receiver = transform(expr.receiver)..parent = expr;
    });
  }

  @override
  TreeNode visitEqualsCall(EqualsCall expr) {
    return transformTreeNode(expr, () {
      expr.right = transform(expr.right)..parent = expr;
      expr.left = transform(expr.left)..parent = expr;
    });
  }

  @override
  TreeNode visitSuperMethodInvocation(SuperMethodInvocation expr) {
    return transformTreeNode(expr, () {
      visitArguments(expr.arguments);
    });
  }

  @override
  TreeNode visitStaticInvocation(StaticInvocation expr) {
    return transformTreeNode(expr, () {
      visitArguments(expr.arguments);
    });
  }

  @override
  TreeNode visitConstructorInvocation(ConstructorInvocation expr) {
    return transformTreeNode(expr, () {
      visitArguments(expr.arguments);
    });
  }

  @override
  TreeNode visitStringConcatenation(StringConcatenation expr) {
    return transformTreeNode(expr, () {
      final expressions = expr.expressions;
      for (var i = expressions.length - 1; i >= 0; --i) {
        expressions[i] = transform(expressions[i])..parent = expr;
      }
    });
  }

  @override
  TreeNode visitListLiteral(ListLiteral expr) {
    return transformTreeNode(expr, () {
      final expressions = expr.expressions;
      for (var i = expressions.length - 1; i >= 0; --i) {
        expressions[i] = transform(expr.expressions[i])..parent = expr;
      }
    });
  }

  @override
  TreeNode visitMapLiteral(MapLiteral expr) {
    return transformTreeNode(expr, () {
      for (final entry in expr.entries.reversed) {
        entry.value = transform(entry.value)..parent = entry;
        entry.key = transform(entry.key)..parent = entry;
      }
    });
  }

  @override
  TreeNode visitSetLiteral(SetLiteral expr) {
    return transformTreeNode(expr, () {
      final expressions = expr.expressions;
      for (var i = expressions.length - 1; i >= 0; --i) {
        expressions[i] = transform(expr.expressions[i])..parent = expr;
      }
    });
  }

  @override
  TreeNode visitRecordLiteral(RecordLiteral expr) {
    return transformTreeNode(expr, () {
      final named = expr.named;
      for (var i = named.length - 1; i >= 0; --i) {
        named[i] = transform(expr.named[i])..parent = expr;
      }

      final positional = expr.positional;
      for (var i = positional.length - 1; i >= 0; --i) {
        positional[i] = transform(expr.positional[i])..parent = expr;
      }
    });
  }

  // Expressions with control flow

  /// Perform an action with a given list of statements so that it cannot emit
  /// statements into the 'outer' list.
  Expression delimit(Expression action(), List<Statement> inner) {
    final outer = statements;
    statements = inner;
    final result = action();
    statements = outer;
    return result;
  }

  /// Make a [Block] from a reversed list of [Statement]s by reverting the
  /// statements.
  Block blockOf(List<Statement> reversedStatements) {
    return Block(reversedStatements.reversed.toList());
  }

  @override
  TreeNode visitLogicalExpression(LogicalExpression expr) {
    final bool shouldName = seenAwait;

    // Right is delimited because it is conditionally evaluated.
    final List<Statement> rightStatements = [];
    seenAwait = false;
    expr.right = delimit(() => transform(expr.right), rightStatements)
      ..parent = expr;
    final bool rightAwait = seenAwait;

    if (rightStatements.isEmpty) {
      // Easy case: right did not emit any statements.
      seenAwait = shouldName;
      return transformTreeNode(expr, () {
        expr.left = transform(expr.left)..parent = expr;
        seenAwait = seenAwait || rightAwait;
      });
    }

    // If right has emitted statements we will produce a temporary t and emit
    // for && (there is an analogous case for ||):
    //
    // t = [left] == true;
    // if (t) {
    //   t = [right] == true;
    // }

    // Recall that statements are emitted in reverse order, so first emit the
    // if statement, then the assignment of [left] == true, and then translate
    // left so any statements it emits occur after in the accumulated list
    // (that is, so they occur before in the corresponding block).
    final Block rightBody = blockOf(rightStatements);
    final InterfaceType type = staticTypeContext.typeEnvironment.coreTypes
        .boolRawType(staticTypeContext.nonNullable);
    final VariableDeclaration result = allocateTemporary(nameIndex, type);
    final objectEquals = coreTypes.objectEquals;
    rightBody.addStatement(ExpressionStatement(VariableSet(
        result,
        EqualsCall(expr.right, BoolLiteral(true),
            interfaceTarget: objectEquals,
            functionType: objectEquals.getterType as FunctionType))));
    final Statement then;
    final Statement? otherwise;
    if (expr.operatorEnum == LogicalExpressionOperator.AND) {
      then = rightBody;
      otherwise = null;
    } else {
      then = EmptyStatement();
      otherwise = rightBody;
    }
    statements.add(IfStatement(castVariableGet(result, type), then, otherwise));

    final test = EqualsCall(expr.left, BoolLiteral(true),
        interfaceTarget: objectEquals,
        functionType: objectEquals.getterType as FunctionType);
    statements.add(ExpressionStatement(VariableSet(result, test)));

    seenAwait = false;
    test.left = transform(test.left)..parent = test;

    nameIndex += 1;
    seenAwait = seenAwait || rightAwait;
    return castVariableGet(result, type);
  }

  @override
  TreeNode visitConditionalExpression(ConditionalExpression expr) {
    // Then and otherwise are delimited because they are conditionally
    // evaluated.
    final bool shouldName = seenAwait;

    final int savedNameIndex = nameIndex;

    final thenStatements = <Statement>[];
    seenAwait = false;
    expr.then = delimit(() => transform(expr.then), thenStatements)
      ..parent = expr;
    final thenAwait = seenAwait;

    final thenNameIndex = nameIndex;
    nameIndex = savedNameIndex;

    final List<Statement> otherwiseStatements = [];
    seenAwait = false;
    expr.otherwise =
        delimit(() => transform(expr.otherwise), otherwiseStatements)
          ..parent = expr;
    final otherwiseAwait = seenAwait;

    // Only one side of this branch will get executed at a time, so just make
    // sure we have enough temps for either, not both at the same time.
    if (thenNameIndex > nameIndex) {
      nameIndex = thenNameIndex;
    }

    if (thenStatements.isEmpty && otherwiseStatements.isEmpty) {
      // Easy case: neither then nor otherwise emitted any statements.
      seenAwait = shouldName;
      return transformTreeNode(expr, () {
        expr.condition = transform(expr.condition)..parent = expr;
        seenAwait = seenAwait || thenAwait || otherwiseAwait;
      });
    }

    // If `then` or `otherwise` has emitted statements we will produce a
    // temporary t and emit:
    //
    // if ([condition]) {
    //   t = [left];
    // } else {
    //   t = [right];
    // }
    final result = allocateTemporary(nameIndex, expr.staticType);
    final thenBody = blockOf(thenStatements);
    final otherwiseBody = blockOf(otherwiseStatements);
    thenBody.addStatement(ExpressionStatement(VariableSet(result, expr.then)));
    otherwiseBody
        .addStatement(ExpressionStatement(VariableSet(result, expr.otherwise)));
    final branch = IfStatement(expr.condition, thenBody, otherwiseBody);
    statements.add(branch);

    seenAwait = false;
    branch.condition = transform(branch.condition)..parent = branch;

    nameIndex += 1;
    seenAwait = seenAwait || thenAwait || otherwiseAwait;
    return castVariableGet(result, expr.staticType);
  }

  // Await expression

  @override
  TreeNode visitAwaitExpression(AwaitExpression expr) {
    // TODO (omersa): Only name if the await is not already in assignment RHS
    return transformTreeNode(expr, () {
      expr.transformChildren(this);
    }, alwaysName: true);
  }

  // Block expressions

  @override
  TreeNode visitBlockExpression(BlockExpression expr) {
    return transformTreeNode(expr, () {
      expr.value = transform(expr.value)..parent = expr;
      final List<Statement> body = <Statement>[];
      for (final Statement stmt in expr.body.statements.reversed) {
        final Statement? translation = _rewriteStatement(stmt);
        if (translation != null) {
          body.add(translation);
        }
      }
      expr.body = Block(body.reversed.toList())..parent = expr;
    });
  }

  @override
  TreeNode visitLet(Let expr) {
    final body = transform(expr.body);
    final VariableDeclaration variable = expr.variable;
    if (seenAwait) {
      // There is an await in the body of `let var x = initializer in body` or
      // to its right.  We will produce the sequence of statements:
      //
      // <initializer's statements>
      // var x = <initializer's value>
      // <body's statements>
      //
      // and return the body's value.
      statements.add(variable);
      var index = nameIndex;
      seenAwait = false;
      variable.initializer = transform(variable.initializer!)
        ..parent = variable;
      // Temporaries used in the initializer or the body are not live but the
      // temporary used for the body is.
      if (index + 1 > nameIndex) {
        nameIndex = index + 1;
      }
      seenAwait = true;
      return body;
    } else {
      // The body in `let x = initializer in body` did not contain an await.
      // We can leave a let expression.
      return transformTreeNode(expr, () {
        // The body has already been translated.
        expr.body = body..parent = expr;
        variable.initializer = transform(variable.initializer!)
          ..parent = variable;
      });
    }
  }

  @override
  TreeNode visitFunctionNode(FunctionNode node) {
    var nestedRewriter = _AwaitTransformer(staticTypeContext, coreTypes);
    return nestedRewriter.transform(node);
  }

  /// This method translates a statement nested in an expression (e.g., in a
  /// block expression). It produces a translated statement, a list of
  /// statements which are side effects necessary for any await, and a flag
  /// indicating whether there was an await in the statement or to its right.
  /// The translated statement can be null in the case where there was already
  /// an await to the right.
  Statement? _rewriteStatement(Statement stmt) {
    // The translation is accumulating two lists of statements, an inner list
    // which is a reversed list of effects needed for the current expression
    // and an outer list which represents the block containing the current
    // statement. We need to preserve both of those from side effects.
    final List<Statement> savedInner = statements;
    final List<Statement> savedOuter = _statementTransformer.statements;
    statements = <Statement>[];
    _statementTransformer.statements = <Statement>[];
    stmt = _statementTransformer.transform(stmt);

    final List<Statement> results = _statementTransformer.statements;
    results.add(stmt);

    statements = savedInner;
    _statementTransformer.statements = savedOuter;
    if (!seenAwait && results.length == 1) {
      return results.first;
    }
    statements.addAll(results.reversed);
    return null;
  }

  @override
  TreeNode defaultStatement(Statement stmt) {
    throw UnsupportedError(
        "Use _rewriteStatement to transform statement: ${stmt}");
  }
}
