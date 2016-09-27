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
  /// [statements] to a fresh empty list before transforming those children and
  /// wrapping any emitted statements in a [BlockExpression].
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

  final VariableDeclaration asyncResult =
      new VariableDeclaration(':result');
  final List<VariableDeclaration> variables = <VariableDeclaration>[];

  ExpressionLifter(this.continuationRewriter);

  /// Rewrite a toplevel expression (toplevel wrt. a statement).
  Expression rewrite(Expression expression) {
    var hadSeenAwait = seenAwait;
    seenAwait = false;
    var result = delimit(() => expression.accept(this));
    seenAwait = seenAwait || hadSeenAwait;
    return result;
  }

  // Perform an action with a fresh list of statements so that it cannot emit
  // statements into the 'outer' list, and wrap any emitted statements in a
  // block expression.
  Expression delimit(Expression action()) {
    var saved = statements;
    statements = <Statement>[];
    Expression result = action();
    if (statements.isNotEmpty) {
      result =
          new BlockExpression(new Block(statements.reversed.toList()), result);
    }
    statements = saved;
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
    return transform(expr, () { expr.transformChildren(this); });
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
    return transform(expr, () { visitArguments(expr.arguments); });
  }

  TreeNode visitStaticInvocation(StaticInvocation expr) {
    return transform(expr, () { visitArguments(expr.arguments); });
  }

  TreeNode visitConstructorInvocation(ConstructorInvocation expr) {
    return transform(expr, () { visitArguments(expr.arguments); });
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
        entry.value = entry.value.accept(this)..parent = expr;
        entry.key = entry.key.accept(this)..parent = expr;
      }
    });
  }

  // Control flow.
  TreeNode visitLogicalExpression(LogicalExpression expr) {
    return transform(expr, () {
      expr.right = delimit(() => expr.right.accept(this))..parent = expr;
      var rightAwait = seenAwait;

      seenAwait = false;
      expr.left = expr.left.accept(this)..parent = expr;
      seenAwait = seenAwait || rightAwait;
    });
  }

  TreeNode visitConditionalExpression(ConditionalExpression expr) {
    return transform(expr, () {
      expr.then = delimit(() => expr.then.accept(this))..parent = expr;
      var leftAwait = seenAwait;

      seenAwait = false;
      expr.otherwise =
          delimit(() => expr.otherwise.accept(this))..parent = expr;
      var rightAwait = seenAwait;

      seenAwait = false;
      expr.condition = expr.condition.accept(this)..parent = expr;
      seenAwait = seenAwait || leftAwait || rightAwait;
    });
  }

  // Others.
  TreeNode visitAwaitExpression(AwaitExpression expr) {
    final R = continuationRewriter;
    var shouldName = seenAwait;
    var result = new VariableGet(asyncResult);
    if (shouldName) result = name(result);
    seenAwait = false;
    var index = nameIndex;
    var operand = expr.operand.accept(this);

    // The statements are in reverse order, so name the result first if
    // necessary and then add these two in reverse.
    statements.add(R.createContinuationPoint());
    statements.add(new ExpressionStatement(
        new StaticInvocation(R.helper.awaitHelper,
            new Arguments(<Expression>[
                operand,
                new VariableGet(R.thenContinuationVariable),
                new VariableGet(R.catchErrorContinuationVariable)]))));

    if (shouldName) nameIndex = index + 1;
    seenAwait = true;
    return result;
  }

  TreeNode visitFunctionExpression(FunctionExpression expr) {
    expr.transformChildren(this);
    return expr;
  }

  TreeNode visitLet(Let expr) {
    expr.body = expr.body.accept(this)..parent = expr;
    VariableDeclaration variable = expr.variable;
    variable.initializer =
        variable.initializer.accept(this)..parent = variable;
    return expr;
  }

  TreeNode visitBlockExpression(BlockExpression expr) {
    var length = statements.length;
    expr.value.accept(this)..parent = expr;
    if (statements.length == length) {
      // The statements in the body do not need be translated right-to-left
      // because all subexpressions will be treated as delimited and so
      // prevented from emitting statements into the list of statements.
      expr.body = expr.body.accept(continuationRewriter)..parent = expr;
      return expr;
    } else {
      // Statements were emitted from the translation of the value.  The
      // statements in the body must be executed before them.  Copy the body's
      // statements to the accumulated statement list in reverse order.
      for (var statement in expr.body.statements.reversed) {
        statements.add(statement.accept(continuationRewriter));
      }
      return expr.value;
    }
  }

  visitFunctionNode(FunctionNode node) {
    var nestedRewriter = new RecursiveContinuationRewriter(
        continuationRewriter.helper);
    return node.accept(nestedRewriter);
  }
}
