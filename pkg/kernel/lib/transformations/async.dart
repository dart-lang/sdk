// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.async;

import '../kernel.dart';
import 'continuation.dart';

/// A transformer that introduces temporary variables for all subexpressions
/// that are alive across yield points (AwaitExpression).
///
/// The transformer is invoked by passing [rewrite] a top-level expression.
///
/// All intermediate values that are possible live across an await are named in
/// local variables.
///
/// Await expressions are translated into a call to a helper function and a
/// native yield.
class ExpressionLifter extends Transformer {
  final AsyncRewriterBase continuationRewriter;

  /// Have we seen an await to the right in the expression tree.
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
  /// implementating the translation of the children.
  ///
  /// Children that are conditionally evaluated, such as some parts of logical
  /// and conditional expressions, must be delimited so that they do not emit
  /// unguarded statements into [statements].  This is implemented by setting
  /// [statements] to a fresh empty list before transforming those children.
  List<Statement> statements = <Statement>[];

  /// The number of currently live named intermediate values.
  ///
  /// This index is used to allocate names to temporary values.  Because
  /// children are visited right-to-left, names are assigned in reverse order of
  /// index.
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

  final VariableDeclaration asyncResult = new VariableDeclaration(':result');
  final List<VariableDeclaration> variables = <VariableDeclaration>[];

  ExpressionLifter(this.continuationRewriter);

  Block blockOf(List<Statement> stmts) => new Block(stmts.reversed.toList());

  /// Rewrite a toplevel expression (toplevel wrt. a statement).
  ///
  /// Rewriting an expression produces a sequence of statements and an
  /// expression.  The sequence of statements are added to the given list.  Pass
  /// an empty list if the rewritten expression should be delimited from the
  /// surrounding context.
  Expression rewrite(Expression expression, List<Statement> outer) {
    assert(statements.isEmpty);
    assert(nameIndex == 0);
    seenAwait = false;
    Expression result = expression.accept(this);
    outer.addAll(statements.reversed);
    statements.clear();
    nameIndex = 0;
    return result;
  }

  // Perform an action with a given list of statements so that it cannot emit
  // statements into the 'outer' list.
  Expression delimit(Expression action(), List<Statement> inner) {
    var index = nameIndex;
    var outer = statements;
    statements = inner;
    Expression result = action();
    nameIndex = index;
    statements = outer;
    return result;
  }

  // Name an expression by emitting an assignment to a temporary variable.
  VariableGet name(Expression expr) {
    VariableDeclaration temp = allocateTemporary(nameIndex);
    statements.add(new ExpressionStatement(new VariableSet(temp, expr)));
    return new VariableGet(temp);
  }

  VariableDeclaration allocateTemporary(int index) {
    for (var i = variables.length; i <= index; i++) {
      variables.add(new VariableDeclaration(":async_temporary_${i}"));
    }
    return variables[index];
  }

  // Simple literals.  These are pure expressions so they can be evaluated after
  // an await to their right.
  TreeNode visitSymbolLiteral(SymbolLiteral expr) => expr;
  TreeNode visitTypeLiteral(TypeLiteral expr) => expr;
  TreeNode visitThisExpression(ThisExpression expr) => expr;
  TreeNode visitStringLiteral(StringLiteral expr) => expr;
  TreeNode visitIntLiteral(IntLiteral expr) => expr;
  TreeNode visitDoubleLiteral(DoubleLiteral expr) => expr;
  TreeNode visitBoolLiteral(BoolLiteral expr) => expr;
  TreeNode visitNullLiteral(NullLiteral expr) => expr;

  // Nullary expressions with effects.
  Expression nullary(Expression expr) {
    if (seenAwait) {
      expr = name(expr);
      ++nameIndex;
    }
    return expr;
  }

  TreeNode visitInvalidExpression(InvalidExpression expr) => nullary(expr);
  TreeNode visitSuperPropertyGet(SuperPropertyGet expr) => nullary(expr);
  TreeNode visitStaticGet(StaticGet expr) => nullary(expr);
  TreeNode visitRethrow(Rethrow expr) => nullary(expr);

  // Getting a final or const variable is not an effect so it can be evaluated
  // after an await to its right.
  TreeNode visitVariableGet(VariableGet expr) {
    if (seenAwait && !expr.variable.isFinal && !expr.variable.isConst) {
      expr = name(expr);
      ++nameIndex;
    }
    return expr;
  }

  // Transform an expression given an action to transform the children.  For
  // this purposes of the await transformer the children should generally be
  // translated from right to left, in the reverse of evaluation order.
  Expression transform(Expression expr, void action()) {
    var shouldName = seenAwait;

    // 1. If there is an await in a sibling to the right, emit an assignment to
    // a temporary variable before transforming the children.
    var result = shouldName ? name(expr) : expr;

    // 2. Remember the number of live temporaries before transforming the
    // children.
    var index = nameIndex;

    // 3. Transform the children.  Initially they do not have an await in a
    // sibling to their right.
    seenAwait = false;
    action();

    // 4. If the expression was named then the variables used for children are
    // no longer live but the variable used for the expression is.
    if (shouldName) {
      nameIndex = index + 1;
      seenAwait = true;
    }
    return result;
  }

  // Unary expressions.
  Expression unary(Expression expr) {
    return transform(expr, () {
      expr.transformChildren(this);
    });
  }

  TreeNode visitVariableSet(VariableSet expr) => unary(expr);
  TreeNode visitPropertyGet(PropertyGet expr) => unary(expr);
  TreeNode visitDirectPropertyGet(DirectPropertyGet expr) => unary(expr);
  TreeNode visitSuperPropertySet(SuperPropertySet expr) => unary(expr);
  TreeNode visitStaticSet(StaticSet expr) => unary(expr);
  TreeNode visitNot(Not expr) => unary(expr);
  TreeNode visitIsExpression(IsExpression expr) => unary(expr);
  TreeNode visitAsExpression(AsExpression expr) => unary(expr);
  TreeNode visitThrow(Throw expr) => unary(expr);

  TreeNode visitPropertySet(PropertySet expr) {
    return transform(expr, () {
      expr.value = expr.value.accept(this)..parent = expr;
      expr.receiver = expr.receiver.accept(this)..parent = expr;
    });
  }

  TreeNode visitDirectPropertySet(DirectPropertySet expr) {
    return transform(expr, () {
      expr.value = expr.value.accept(this)..parent = expr;
      expr.receiver = expr.receiver.accept(this)..parent = expr;
    });
  }

  TreeNode visitArguments(Arguments args) {
    for (var named in args.named.reversed) {
      named.value = named.value.accept(this)..parent = named;
    }
    var positional = args.positional;
    for (var i = positional.length - 1; i >= 0; --i) {
      positional[i] = positional[i].accept(this)..parent = args;
    }
    // Returns the arguments, which is assumed at the call sites because they do
    // not replace the arguments or set parent pointers.
    return args;
  }

  TreeNode visitMethodInvocation(MethodInvocation expr) {
    return transform(expr, () {
      visitArguments(expr.arguments);
      expr.receiver = expr.receiver.accept(this)..parent = expr;
    });
  }

  TreeNode visitDirectMethodInvocation(DirectMethodInvocation expr) {
    return transform(expr, () {
      visitArguments(expr.arguments);
      expr.receiver = expr.receiver.accept(this)..parent = expr;
    });
  }

  TreeNode visitSuperMethodInvocation(SuperMethodInvocation expr) {
    return transform(expr, () {
      visitArguments(expr.arguments);
    });
  }

  TreeNode visitStaticInvocation(StaticInvocation expr) {
    return transform(expr, () {
      visitArguments(expr.arguments);
    });
  }

  TreeNode visitConstructorInvocation(ConstructorInvocation expr) {
    return transform(expr, () {
      visitArguments(expr.arguments);
    });
  }

  TreeNode visitStringConcatenation(StringConcatenation expr) {
    return transform(expr, () {
      var expressions = expr.expressions;
      for (var i = expressions.length - 1; i >= 0; --i) {
        expressions[i] = expressions[i].accept(this)..parent = expr;
      }
    });
  }

  TreeNode visitListLiteral(ListLiteral expr) {
    return transform(expr, () {
      var expressions = expr.expressions;
      for (var i = expressions.length - 1; i >= 0; --i) {
        expressions[i] = expr.expressions[i].accept(this)..parent = expr;
      }
    });
  }

  TreeNode visitMapLiteral(MapLiteral expr) {
    return transform(expr, () {
      for (var entry in expr.entries.reversed) {
        entry.value = entry.value.accept(this)..parent = entry;
        entry.key = entry.key.accept(this)..parent = entry;
      }
    });
  }

  // Control flow.
  TreeNode visitLogicalExpression(LogicalExpression expr) {
    var shouldName = seenAwait;

    // Right is delimited because it is conditionally evaluated.
    var rightStatements = <Statement>[];
    seenAwait = false;
    expr.right = delimit(() => expr.right.accept(this), rightStatements)
      ..parent = expr;
    var rightAwait = seenAwait;

    if (rightStatements.isEmpty) {
      // Easy case: right did not emit any statements.
      seenAwait = shouldName;
      return transform(expr, () {
        expr.left = expr.left.accept(this)..parent = expr;
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

    // Recall that statements are emitted in reverse order, so first emit the if
    // statement, then the assignment of [left] == true, and then translate left
    // so any statements it emits occur after in the accumulated list (that is,
    // so they occur before in the corresponding block).
    var rightBody = blockOf(rightStatements);
    var result = allocateTemporary(nameIndex);
    rightBody.addStatement(new ExpressionStatement(new VariableSet(
        result,
        new MethodInvocation(expr.right, new Name('=='),
            new Arguments(<Expression>[new BoolLiteral(true)])))));
    var then, otherwise;
    if (expr.operator == '&&') {
      then = rightBody;
      otherwise = null;
    } else {
      then = new EmptyStatement();
      otherwise = rightBody;
    }
    statements.add(new IfStatement(new VariableGet(result), then, otherwise));

    var test = new MethodInvocation(expr.left, new Name('=='),
        new Arguments(<Expression>[new BoolLiteral(true)]));
    statements.add(new ExpressionStatement(new VariableSet(result, test)));

    seenAwait = false;
    test.receiver = test.receiver.accept(this)..parent = test;

    ++nameIndex;
    seenAwait = seenAwait || rightAwait;
    return new VariableGet(result);
  }

  TreeNode visitConditionalExpression(ConditionalExpression expr) {
    // Then and otherwise are delimited because they are conditionally
    // evaluated.
    var shouldName = seenAwait;

    var thenStatements = <Statement>[];
    seenAwait = false;
    expr.then = delimit(() => expr.then.accept(this), thenStatements)
      ..parent = expr;
    var thenAwait = seenAwait;

    var otherwiseStatements = <Statement>[];
    seenAwait = false;
    expr.otherwise =
        delimit(() => expr.otherwise.accept(this), otherwiseStatements)
          ..parent = expr;
    var otherwiseAwait = seenAwait;

    if (thenStatements.isEmpty && otherwiseStatements.isEmpty) {
      // Easy case: neither then nor otherwise emitted any statements.
      seenAwait = shouldName;
      return transform(expr, () {
        expr.condition = expr.condition.accept(this)..parent = expr;
        seenAwait = seenAwait || thenAwait || otherwiseAwait;
      });
    }

    // If then or otherwise has emitted statements we will produce a temporary t
    // and emit:
    //
    // if ([condition]) {
    //   t = [left];
    // } else {
    //   t = [right];
    // }
    var result = allocateTemporary(nameIndex);
    var thenBody = blockOf(thenStatements);
    var otherwiseBody = blockOf(otherwiseStatements);
    thenBody.addStatement(
        new ExpressionStatement(new VariableSet(result, expr.then)));
    otherwiseBody.addStatement(
        new ExpressionStatement(new VariableSet(result, expr.otherwise)));
    var branch = new IfStatement(expr.condition, thenBody, otherwiseBody);
    statements.add(branch);

    seenAwait = false;
    branch.condition = branch.condition.accept(this)..parent = branch;

    ++nameIndex;
    seenAwait = seenAwait || thenAwait || otherwiseAwait;
    return new VariableGet(result);
  }

  // Others.
  TreeNode visitAwaitExpression(AwaitExpression expr) {
    final R = continuationRewriter;
    var shouldName = seenAwait;
    var result = new VariableGet(asyncResult);

    // The statements are in reverse order, so name the result first if
    // necessary and then add the two other statements in reverse.
    if (shouldName) result = name(result);
    statements.add(R.createContinuationPoint()..fileOffset = expr.fileOffset);
    Arguments arguments = new Arguments(<Expression>[
      expr.operand,
      new VariableGet(R.thenContinuationVariable),
      new VariableGet(R.catchErrorContinuationVariable),
      new VariableGet(R.nestedClosureVariable),
    ]);
    statements.add(new ExpressionStatement(
        new StaticInvocation(R.helper.awaitHelper, arguments)
          ..fileOffset = expr.fileOffset));

    seenAwait = false;
    var index = nameIndex;
    arguments.positional[0] = expr.operand.accept(this)..parent = arguments;

    if (shouldName) nameIndex = index + 1;
    seenAwait = true;
    return result;
  }

  TreeNode visitFunctionExpression(FunctionExpression expr) {
    expr.transformChildren(this);
    return expr;
  }

  TreeNode visitLet(Let expr) {
    var shouldName = seenAwait;

    seenAwait = false;
    var body = expr.body.accept(this);

    VariableDeclaration variable = expr.variable;
    if (seenAwait) {
      // The body in `let var x = initializer in body` contained an await.  We
      // will produce the sequence of statements:
      //
      // <initializer's statements>
      // var x = <initializer's value>
      // <body's statements>
      //
      // and return the body's value.
      //
      // So x is in scope for all the body's statements and the body's value.
      // This has the unpleasant consequence that all let-bound variables with
      // await in the let's body will end up hoisted out the the expression and
      // allocated to the context in the VM, even if they have no uses
      // (`let _ = e0 in e1` can be used for sequencing of `e0` and `e1`).
      statements.add(variable);
      var index = nameIndex;
      seenAwait = false;
      variable.initializer = variable.initializer.accept(this)
        ..parent = variable;
      // Temporaries used in the initializer or the body are not live but the
      // temporary used for the body is.
      nameIndex = index + 1;
      seenAwait = true;
      return body;
    } else {
      // The body in `let x = initializer in body` did not contain an await.  We
      // can leave a let expression.
      seenAwait = shouldName;
      return transform(expr, () {
        // The body has already been translated.
        expr.body = body..parent = expr;
        variable.initializer = variable.initializer.accept(this)
          ..parent = variable;
      });
    }
  }

  visitFunctionNode(FunctionNode node) {
    var nestedRewriter =
        new RecursiveContinuationRewriter(continuationRewriter.helper);
    return node.accept(nestedRewriter);
  }
}
