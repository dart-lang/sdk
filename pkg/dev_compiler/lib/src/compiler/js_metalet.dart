// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): import from its own package
import '../js_ast/js_ast.dart';

import 'js_names.dart' show TemporaryId;

/// A synthetic `let*` node, similar to that found in Scheme.
///
/// For example, postfix increment can be desugared as:
///
///     // psuedocode mix of Scheme and JS:
///     (let* (x1=expr1, x2=expr2, t=x1[x2]) { x1[x2] = t + 1; t })
///
/// [MetaLet] will simplify itself automatically when [toExpression],
/// [toStatement], [toReturn], or [toYieldStatement] is called.
///
/// * variables used once will be inlined.
/// * if used in a statement context they can emit as blocks.
/// * if return value is not used it can be eliminated, see [statelessResult].
/// * if there are no variables, the codegen will be simplified.
///
/// Because this deals with JS AST nodes, it is not aware of any Dart semantics
/// around statelessness (such as `final` variables). [variables] should not
/// be created for these Dart expressions.
///
class MetaLet extends Expression {
  /// Creates a temporary to contain the value of [expr]. The temporary can be
  /// used multiple times in the resulting expression. For example:
  /// `expr ** 2` could be compiled as `expr * expr`. The temporary scope will
  /// ensure `expr` is only evaluated once: `(x => x * x)(expr)`.
  ///
  /// If the expression does not end up using `x` more than once, or if those
  /// expressions can be treated as [stateless] (e.g. they are non-mutated
  /// variables), then the resulting code will be simplified automatically.
  final Map<MetaLetVariable, Expression> variables;

  /// A list of expressions in the body.
  /// The last value should represent the returned value.
  final List<Expression> body;

  /// True if the final expression in [body] can be skipped in [toStatement].
  final bool statelessResult;

  /// We run [toExpression] implicitly when the JS AST is visited, to get the
  /// transformation to happen before the tree is printed.
  /// This happens multiple times, so ensure the expression form is cached.
  Expression _expression;

  MetaLet(this.variables, this.body, {this.statelessResult: false});

  /// Returns an expression that ignores the result. This is a cross between
  /// [toExpression] and [toStatement]. Used for C-style for-loop updaters,
  /// which is an expression syntactically, but functions more like a statement.
  Expression toVoidExpression() {
    var block = toStatement();
    var s = block.statements;
    if (s.length == 1 && s.first is ExpressionStatement) {
      ExpressionStatement es = s.first;
      return es.expression;
    }

    return _toInvokedFunction(block);
  }

  Expression toAssignExpression(Expression left, [String op]) {
    if (left is Identifier) {
      return _simplifyAssignment(left, op: op) ?? _toAssign(left, op);
    } else if (left is PropertyAccess &&
        left.receiver is This &&
        (left.selector is Identifier || left.selector is LiteralString)) {
      return _toAssign(left, op);
    }
    return super.toAssignExpression(left, op);
  }

  Expression _toAssign(Expression left, [String op]) {
    var exprs = body.toList();
    exprs.add(exprs.removeLast().toAssignExpression(left, op));
    return new MetaLet(variables, exprs);
  }

  Statement toVariableDeclaration(Identifier name) {
    var simple = _simplifyAssignment(name, isDeclaration: true);
    if (simple != null) return simple.toStatement();

    // We can still optimize something like:
    //
    //     let x = ((l) => l == null ? null : l.xyz)(some.expr);
    //
    // can be transformed to:
    //
    //     let l = some.expr;
    //     let x = l == null ? null : l.xyz;
    //
    // Because `x` is a declaration, we know it is safe to move.
    // (see also _toAssign)
    var statements = body
        .map((e) =>
            e == body.last ? e.toVariableDeclaration(name) : e.toStatement())
        .toList();
    return _finishStatement(statements);
  }

  Expression toExpression() {
    if (_expression != null) return _expression;
    var block = toReturn();
    var s = block.statements;
    if (s.length == 1 && s.first is Return) {
      Return es = s.first;
      return _expression = es.value;
    }
    // Wrap it in an immediately called function to get in expression context.
    return _expression = _toInvokedFunction(block);
  }

  Block toStatement() {
    // Skip return value if not used.
    var statements = body.map((e) => e.toStatement()).toList();
    if (statelessResult) statements.removeLast();
    return _finishStatement(statements);
  }

  Block toReturn() {
    var statements = body
        .map((e) => e == body.last ? e.toReturn() : e.toStatement())
        .toList();
    return _finishStatement(statements);
  }

  Block toYieldStatement({bool star: false}) {
    var statements = body
        .map((e) =>
            e == body.last ? e.toYieldStatement(star: star) : e.toStatement())
        .toList();
    return _finishStatement(statements);
  }

  accept(NodeVisitor visitor) {
    // TODO(jmesserly): we special case vistors from js_ast.Template, because it
    // doesn't know about MetaLet. Should we integrate directly?
    if (visitor is InstantiatorGeneratorVisitor) {
      return _templateVisitMetaLet(visitor);
    } else if (visitor is InterpolatedNodeAnalysis) {
      return visitor.visitNode(this);
    } else {
      return toExpression().accept(visitor);
    }
  }

  void visitChildren(NodeVisitor visitor) {
    // TODO(jmesserly): we special case vistors from js_ast.Template, because it
    // doesn't know about MetaLet. Should we integrate directly?
    if (visitor is InterpolatedNodeAnalysis ||
        visitor is InstantiatorGeneratorVisitor) {
      variables.values.forEach((v) => v.accept(visitor));
      body.forEach((v) => v.accept(visitor));
    } else {
      toExpression().visitChildren(visitor);
    }
  }

  /// This generates as either a comma expression or a call.
  int get precedenceLevel => toExpression().precedenceLevel;

  /// Patch to pretend [Template] supports visitMetaLet.
  Instantiator _templateVisitMetaLet(InstantiatorGeneratorVisitor visitor) {
    var valueInstantiators = variables.values.map(visitor.visit);
    var bodyInstantiators = body.map(visitor.visit);

    return (args) => new MetaLet(
        new Map.fromIterables(
            variables.keys, valueInstantiators.map((i) => i(args))),
        bodyInstantiators.map((i) => i(args) as Expression).toList(),
        statelessResult: statelessResult);
  }

  Expression _toInvokedFunction(Statement block) {
    var finder = new _YieldFinder();
    block.accept(finder);
    if (!finder.hasYield) {
      return new Call(new ArrowFun([], block), []);
    }
    // If we have a yield, it's more tricky. We'll create a `function*`, which
    // we `yield*` to immediately invoke. We also may need to bind this:
    Expression fn = new Fun([], block, isGenerator: true);
    if (finder.hasThis) fn = js.call('#.bind(this)', fn);
    return new Yield(new Call(fn, []), star: true);
  }

  Block _finishStatement(List<Statement> statements) {
    // Visit the tree and count how many times each temp was used.
    var counter = new _VariableUseCounter();
    var node = new Block(statements);
    node.accept(counter);
    // Also count the init expressions.
    for (var init in variables.values) init.accept(counter);

    var initializers = <VariableInitialization>[];
    var substitutions = <MetaLetVariable, Expression>{};
    variables.forEach((variable, init) {
      // Since this is let*, subsequent variables can refer to previous ones,
      // so we need to substitute here.
      init = _substitute(init, substitutions);
      int n = counter.counts[variable];
      if (n == 1) {
        // Replace interpolated exprs with their value, if it only occurs once.
        substitutions[variable] = init;
      } else {
        // Otherwise replace it with a temp, which will be assigned once.
        var temp = new TemporaryId(variable.displayName);
        substitutions[variable] = temp;
        initializers.add(new VariableInitialization(temp, init));
      }
    });

    // Interpolate the body.
    node = _substitute(node, substitutions);
    if (initializers.isNotEmpty) {
      var first = initializers[0];
      node = new Block([
        initializers.length == 1
            ? first.value.toVariableDeclaration(first.declaration)
            : new VariableDeclarationList('let', initializers).toStatement(),
        node
      ]);
    }
    return node;
  }

  /// If we finish with an assignment to an identifier, try to simplify the
  /// block. For example:
  ///
  ///     result = ((_) => _.add(1), _.add(2), _)([])
  ///
  /// Can be transformed to:
  ///
  ///     (result = [], result.add(1), result.add(2), result)
  ///
  /// However we should not simplify in this case because `result` is read:
  ///
  ///     result = ((_) => _.addAll(result), _.add(2), _)([])
  ///
  MetaLet _simplifyAssignment(Identifier left,
      {String op, bool isDeclaration: false}) {
    // See if the result value is a let* temporary variable.
    var result = body.last;
    if (result is MetaLetVariable && variables.containsKey(result)) {
      // For assignments, make sure the identifier isn't used in body, as that
      // would change the assignment order and be an invalid optimization.
      if (!isDeclaration && _IdentFinder.foundIn(left.name, body)) return null;

      var vars = new Map<MetaLetVariable, Expression>.from(variables);
      var value = vars.remove(result);
      Expression assign;
      if (isDeclaration) {
        // Technically, putting one of these in a comma expression is not
        // legal. However when isDeclaration is true, toStatement will be
        // called immediately on the MetaLet, which results in legal JS.
        assign = new VariableDeclarationList(
            'let', [new VariableInitialization(left, value)]);
      } else {
        assign = value.toAssignExpression(left, op);
      }

      assert(body.isNotEmpty);
      Binary newBody = new Expression.binary([assign]..addAll(body), ',');
      newBody = _substitute(newBody, {result: left});
      return new MetaLet(vars, newBody.commaToExpressionList(),
          statelessResult: statelessResult);
    }
    return null;
  }
}

/// Similar to [Template.instantiate] but works with free variables.
Node _substitute(Node tree, Map<MetaLetVariable, Expression> substitutions) {
  var generator = new InstantiatorGeneratorVisitor(/*forceCopy:*/ false);
  var instantiator = generator.compile(tree);
  var nodes = new List<MetaLetVariable>.from(generator
      .analysis.containsInterpolatedNode
      .where((n) => n is MetaLetVariable));
  if (nodes.isEmpty) return tree;

  return instantiator(new Map.fromIterable(nodes,
      key: (v) => (v as MetaLetVariable).nameOrPosition,
      value: (v) => substitutions[v] ?? v));
}

/// A temporary variable used in a [MetaLet].
///
/// Each instance of this class represents a fresh variable. The same object
/// should be used everywhere to refer to the same variable. Different variables
/// with the same name are different, and will be renamed later on, if needed.
///
/// These variables will be replaced when the `let*` is complete, depending on
/// how often they occur and whether they can be optimized away. See [MetaLet]
/// for more information.
///
/// This class should never reach our final JS code.
class MetaLetVariable extends InterpolatedExpression {
  /// The suggested display name of this variable.
  ///
  /// This name should not be used
  final String displayName;

  /// Compute fresh IDs to avoid
  static int _uniqueId = 0;

  MetaLetVariable(String displayName)
      : displayName = displayName,
        super(displayName + '@${++_uniqueId}');
}

class _VariableUseCounter extends BaseVisitor {
  final counts = <MetaLetVariable, int>{};
  @override
  visitInterpolatedExpression(InterpolatedExpression node) {
    if (node is MetaLetVariable) {
      int n = counts[node];
      counts[node] = n == null ? 1 : n + 1;
    }
  }
}

class _IdentFinder extends BaseVisitor {
  final String name;
  bool found = false;
  _IdentFinder(this.name);

  static bool foundIn(String name, List<Node> body) {
    var finder = new _IdentFinder(name);
    for (var expr in body) {
      expr.accept(finder);
      if (finder.found) return true;
    }
    return false;
  }

  @override
  visitIdentifier(Identifier node) {
    if (node.name == name) found = true;
  }

  @override
  visitNode(Node node) {
    if (!found) super.visitNode(node);
  }
}

class _YieldFinder extends BaseVisitor {
  bool hasYield = false;
  bool hasThis = false;
  bool _nestedFunction = false;

  @override
  visitThis(This node) {
    hasThis = true;
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    var savedNested = _nestedFunction;
    _nestedFunction = true;
    super.visitFunctionExpression(node);
    _nestedFunction = savedNested;
  }

  @override
  visitYield(Yield node) {
    if (!_nestedFunction) hasYield = true;
    super.visitYield(node);
  }

  @override
  visitNode(Node node) {
    if (hasYield && hasThis) return; // found both, nothing more to do.
    super.visitNode(node);
  }
}
