// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/nullability/conditional_discard.dart';
import 'package:analyzer/src/dart/nullability/constraint_gatherer.dart';
import 'package:analyzer/src/dart/nullability/constraint_variable_gatherer.dart';
import 'package:analyzer/src/dart/nullability/decorated_type.dart';
import 'package:analyzer/src/dart/nullability/expression_checks.dart';
import 'package:analyzer/src/dart/nullability/unit_propagation.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Representation of a single location in the code that needs to be modified
/// by the migration tool.
///
/// TODO(paulberry): unify with SourceEdit.
class Modification {
  final int location;

  final String insert;

  Modification(this.location, this.insert);
}

/// Transitional migration API.
///
/// Usage: pass each input source file to [prepareInput].  Then pass each input
/// source file to [processInput].  Then call [finish] to obtain the
/// modifications that need to be made to each source file.
///
/// TODO(paulberry): this implementation keeps a lot of CompilationUnit objects
/// around.  Can we do better?
class NullabilityMigration {
  final _variables = Variables();

  final _constraints = Solver();

  CompilationUnit _unit;

  String _path;

  Map<String, List<Modification>> finish() {
    var results = <String, List<Modification>>{};
    _constraints.applyHeuristics();
    // TODO(paulberry): loop over units
    var path = _path;
    results[path] = _variables.getModifications();
    return results;
  }

  void prepareInput(String path, CompilationUnit unit) {
    // TODO(paulberry): allow processing of multiple files
    assert(_unit == null && _path == null);
    _unit = unit;
    _path = path;
    unit.accept(ConstraintVariableGatherer(_variables));
  }

  void processInput(CompilationUnit unit, TypeProvider typeProvider) {
    // TODO(paulberry): tolerate the caller giving us a recreated unit.
    assert(identical(unit, _unit));
    unit.accept(ConstraintGatherer(typeProvider, _variables, _constraints));
  }

  static String applyModifications(
      String code, List<Modification> modifications) {
    var migrated = code;
    for (var modification in modifications) {
      migrated = migrated.substring(0, modification.location) +
          modification.insert +
          migrated.substring(modification.location);
    }
    return migrated;
  }
}

/// Mock representation of constraint variables.
class Variables implements VariableRecorder, VariableRepository {
  final _decoratedElementTypes = <Element, DecoratedType>{};

  final _decoratedExpressionTypes = <Expression, DecoratedType>{};

  final _decoratedTypeAnnotations = <TypeAnnotation, DecoratedType>{};

  final _expressionChecks = <Expression, ExpressionChecks>{};

  final _potentialModifications = <_PotentialModification>[];

  final _conditionalDiscard = <AstNode, ConditionalDiscard>{};

  /// Gets the [ExpressionChecks] associated with the given [expression].
  ExpressionChecks checkExpression(Expression expression) =>
      _expressionChecks[_normalizeExpression(expression)];

  @override
  ConstraintVariable checkNotNullForExpression(Expression expression) {
    var variable = _CheckExpression(expression);
    _potentialModifications.add(variable);
    return variable;
  }

  /// Gets the [conditionalDiscard] associated with the given [expression].
  ConditionalDiscard conditionalDiscard(AstNode node) =>
      _conditionalDiscard[node];

  @override
  DecoratedType decoratedElementType(Element element, {bool create: false}) =>
      _decoratedElementTypes[element] ??= create
          ? DecoratedType.forElement(element)
          : throw StateError('No element found');

  /// Gets the [DecoratedType] associated with the given [expression].
  DecoratedType decoratedExpressionType(Expression expression) =>
      _decoratedExpressionTypes[_normalizeExpression(expression)];

  /// Gets the [DecoratedType] associated with the given [typeAnnotation].
  DecoratedType decoratedTypeAnnotation(TypeAnnotation typeAnnotation) =>
      _decoratedTypeAnnotations[typeAnnotation];

  List<Modification> getModifications() {
    var modifications = <Modification>[];
    for (var variable in _potentialModifications) {
      modifications.addAll(variable._modifications);
    }
    modifications.sort((a, b) => b.location.compareTo(a.location));
    return modifications;
  }

  @override
  ConstraintVariable nullableForExpression(Expression expression) =>
      _NullableExpression(expression);

  @override
  ConstraintVariable nullableForTypeAnnotation(TypeAnnotation node) {
    var variable = _NullableTypeAnnotation(node);
    _potentialModifications.add(variable);
    return variable;
  }

  @override
  void recordConditionalDiscard(
      AstNode node, ConditionalDiscard conditionalDiscard) {
    _conditionalDiscard[node] = conditionalDiscard;
    _potentialModifications
        .add(_ConditionalModification(node, conditionalDiscard));
  }

  void recordDecoratedElementType(Element element, DecoratedType type) {
    _decoratedElementTypes[element] = type;
  }

  void recordDecoratedExpressionType(Expression node, DecoratedType type) {
    _decoratedExpressionTypes[_normalizeExpression(node)] = type;
  }

  void recordDecoratedTypeAnnotation(TypeAnnotation node, DecoratedType type) {
    _decoratedTypeAnnotations[node] = type;
  }

  @override
  void recordExpressionChecks(Expression expression, ExpressionChecks checks) {
    _expressionChecks[_normalizeExpression(expression)] = checks;
  }

  /// Unwraps any parentheses surrounding [expression].
  Expression _normalizeExpression(Expression expression) {
    while (expression is ParenthesizedExpression) {
      expression = (expression as ParenthesizedExpression).expression;
    }
    return expression;
  }
}

/// Type of a [ConstraintVariable] representing the addition of a null check.
class _CheckExpression extends ConstraintVariable
    implements _PotentialModification {
  final Expression _node;

  _CheckExpression(this._node);

  @override
  Iterable<Modification> get _modifications =>
      value ? [Modification(_node.end, '!')] : [];

  @override
  toString() => 'checkNotNull($_node@${_node.offset})';
}

/// Records information about how a conditional expression or statement might
/// need to be modified.
class _ConditionalModification extends _PotentialModification {
  final AstNode node;

  final ConditionalDiscard discard;

  _ConditionalModification(this.node, this.discard);

  @override
  Iterable<Modification> get _modifications {
    if (discard.keepTrue.value && discard.keepFalse.value) return const [];
    var result = <Modification>[];
    var keepNodes = <AstNode>[];
    var node = this.node;
    if (node is IfStatement) {
      if (!discard.pureCondition) {
        keepNodes.add(node.condition); // TODO(paulberry): test
      }
      if (discard.keepTrue.value) {
        keepNodes.add(node.thenStatement); // TODO(paulberry): test
      }
      if (discard.keepFalse.value) {
        keepNodes.add(node.elseStatement); // TODO(paulberry): test
      }
    } else {
      assert(false); // TODO(paulberry)
    }
    // TODO(paulberry): test thoroughly
    for (int i = 0; i < keepNodes.length; i++) {
      var keepNode = keepNodes[i];
      int start = keepNode.offset;
      int end = keepNode.end;
      if (keepNode is Block && keepNode.statements.isNotEmpty) {
        start = keepNode.statements[0].offset;
        end = keepNode.statements.last.end;
      }
      if (i == 0 && start != node.offset) {
        result.add(Modification(node.offset, '/* '));
      }
      if (i != 0 || start != node.offset) {
        result.add(Modification(start, '*/ '));
      }
      if (i != keepNodes.length - 1 || end != node.end) {
        result.add(Modification(
            end, keepNode is Expression && node is Statement ? '; /*' : ' /*'));
      }
      if (i == keepNodes.length - 1 && end != node.end) {
        result.add(Modification(node.end, ' */'));
      }
    }
    return result;
  }
}

/// Type of a [ConstraintVariable] representing the fact that a subexpression's
/// type is nullable.
class _NullableExpression extends ConstraintVariable {
  final Expression _node;

  _NullableExpression(this._node);

  @override
  toString() => 'nullable($_node@${_node.offset})';
}

/// Type of a [ConstraintVariable] representing the addition of `?` to a type.
class _NullableTypeAnnotation extends ConstraintVariable
    implements _PotentialModification {
  final TypeAnnotation _node;

  _NullableTypeAnnotation(this._node);

  @override
  Iterable<Modification> get _modifications =>
      value ? [Modification(_node.end, '?')] : [];

  @override
  toString() => 'nullable($_node@${_node.offset})';
}

/// Interface used by data structures representing potential modifications to
/// the code being migrated.
abstract class _PotentialModification {
  /// Gets the individual migrations that need to be done, considering the
  /// solution to the constraint equations.
  Iterable<Modification> get _modifications;
}
