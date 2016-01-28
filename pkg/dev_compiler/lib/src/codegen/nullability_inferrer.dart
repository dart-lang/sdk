// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.codegen.nullability_inferrer;

import 'package:analyzer/analyzer.dart' hide ConstantEvaluator;
import 'package:analyzer/src/generated/ast.dart' hide ConstantEvaluator;
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/scanner.dart'
    show StringToken, Token, TokenType;

import 'assignments_index.dart';
import 'js_codegen.dart' show TemporaryVariableElement;
import '../utils.dart' show isInlineJS, DirectedGraph;

typedef bool NullableExpressionPredicate(Expression expr);

typedef DartType _StaticTypeGetter(Expression e);
typedef bool _JSBuiltinTypePredicate(DartType t);

/// Infers flow-insensitive nullability for local variables.
// TODO(ochafik): Use flow-sensitive inference.
class NullabilityInferrer {
  /// Index of assignments of [LocalVariableElement]s defined in this inferer's
  /// context.
  final Map<LocalVariableElement, List<Expression>> _assignments;
  final _StaticTypeGetter getStaticType;
  final _JSBuiltinTypePredicate isJSBuiltinType;

  NullabilityInferrer(Iterable<AstNode> context,
      {this.getStaticType, this.isJSBuiltinType})
      : _assignments = indexLocalAssignments(context);

  /// Tests whether [expr] is nullable, with assumptions on local variable
  /// nullability provided by [isNullableLocal].
  ///
  /// If [assignmentsTarget] and [assignments] are not null, this also builds an
  /// assignments graph (records assignments from each variable to other
  /// variables it can be assigned to). For example, given an assignment:
  ///
  ///     y = x;
  ///
  /// This will lead us to conclude that `y` can be any value that `x` could
  /// hold at that location. For example, if we are not considering control
  /// flow, this means `y` could contain any value that can ever be assigned to
  /// `x`.
  bool _isNullableExpression(Expression expr,
      [bool isNullableLocal(LocalVariableElement e),
      LocalVariableElement assignmentsTarget,
      DirectedGraph<LocalVariableElement> assignments]) {
    // TODO(vsm): Revisit whether we really need this when we get
    // better non-nullability in the type system.
    // TODO(jmesserly): we do recursive calls in a few places. This could
    // leads to O(depth) cost for calling this function. We could store the
    // resulting value if that becomes an issue, so we maintain the invariant
    // that each node is visited once.

    if (expr is SimpleIdentifier) {
      // Type literals are not null.
      var e = expr.staticElement;
      if (e is ClassElement || e is FunctionTypeAliasElement) {
        return false;
      }

      if (e is LocalVariableElement && isNullableLocal != null) {
        assignments?.addEdge(e, assignmentsTarget);
        return isNullableLocal(e);
      }
      return true;
    }
    bool recurse(Expression x) => _isNullableExpression(
        x, isNullableLocal, assignmentsTarget, assignments);

    if (expr is Literal) return expr is NullLiteral;
    if (expr is IsExpression) return false;
    if (expr is FunctionExpression) return false;
    if (expr is ThisExpression) return false;
    if (expr is SuperExpression) return false;
    if (expr is CascadeExpression) return recurse(expr.target);
    if (expr is ConditionalExpression) {
      return recurse(expr.thenExpression) || recurse(expr.elseExpression);
    }
    if (expr is ParenthesizedExpression) {
      return recurse(expr.expression);
    }

    DartType type = null;
    if (expr is BinaryExpression) {
      switch (expr.operator.type) {
        case TokenType.EQ_EQ:
        case TokenType.BANG_EQ:
        case TokenType.AMPERSAND_AMPERSAND:
        case TokenType.BAR_BAR:
          return false;
        case TokenType.QUESTION_QUESTION:
          return recurse(expr.leftOperand) && recurse(expr.rightOperand);
      }
      type = getStaticType(expr.leftOperand);
    } else if (expr is PrefixExpression) {
      if (expr.operator.type == TokenType.BANG) return false;
      type = getStaticType(expr.operand);
    } else if (expr is PostfixExpression) {
      type = getStaticType(expr.operand);
    }
    if (type != null && isJSBuiltinType(type)) {
      return false;
    }
    if (expr is MethodInvocation) {
      // TODO(vsm): This logic overlaps with the resolver.
      // Where is the best place to put this?
      var e = expr.methodName.staticElement;
      if (isInlineJS(e)) {
        // Fix types for JS builtin calls.
        //
        // This code was taken from analyzer. It's not super sophisticated:
        // only looks for the type name in dart:core, so we just copy it here.
        //
        // TODO(jmesserly): we'll likely need something that can handle a wider
        // variety of types, especially when we get to JS interop.
        var args = expr.argumentList.arguments;
        var first = args.isNotEmpty ? args.first : null;
        if (first is SimpleStringLiteral) {
          var types = first.stringValue;
          if (!types.split('|').contains('Null')) {
            return false;
          }
        }
      }
      // TODO(ochafik): Handle `identical` invocations.
    }

    // TODO(ochafik): Handle PrefixedIdentifier, refs to top-level finals
    // that have been assigned non-nullable values, non-generative constructor
    // calls, refs to local functions...

    // Failed to recognize a non-nullable case: assume it's trivially nullable.
    return true;
  }

  NullableExpressionPredicate buildNullabilityPredicate() {
    // Collect the transitive closure of every variable that can be assigned
    // trivially nullable values.
    var assignmentsGraph = new DirectedGraph<LocalVariableElement>();

    /// Detect vars that are "trivially nullable" (i.e. provably nullable
    /// if we assume all known variables are non-nullable).
    var trivialNullables = new Set<LocalVariableElement>();
    _assignments.forEach((local, expressions) {
      for (var expr in expressions) {
        // In the unlikely event of an unknown var, assume it's nullable.
        var isTriviallyNullable = _isNullableExpression(expr,
            (e) => e is TemporaryVariableElement, local, assignmentsGraph);
        if (isTriviallyNullable) trivialNullables.add(local);
      }
    });
    var nullables = assignmentsGraph.getTransitiveClosure(trivialNullables);

    bool isNullableLocal(LocalVariableElement e) {
      // TODO(jmesserly): we should be able to make this work for temps too.
      return e is TemporaryVariableElement || nullables.contains(e);
    }
    return (Expression expr) => _isNullableExpression(expr, isNullableLocal);
  }
}
