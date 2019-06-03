// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/nullability/conditional_discard.dart';
import 'package:analysis_server/src/nullability/constraint_gatherer.dart';
import 'package:analysis_server/src/nullability/constraint_variable_gatherer.dart';
import 'package:analysis_server/src/nullability/decorated_type.dart';
import 'package:analysis_server/src/nullability/expression_checks.dart';
import 'package:analysis_server/src/nullability/nullability_node.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' show SourceEdit;

/// Records information about how a conditional expression or statement might
/// need to be modified.
class ConditionalModification extends PotentialModification {
  final int offset;

  final int end;

  final bool isStatement;

  final ConditionalDiscard discard;

  final _KeepNode condition;

  final _KeepNode thenStatement;

  final _KeepNode elseStatement;

  factory ConditionalModification(AstNode node, ConditionalDiscard discard) {
    if (node is IfStatement) {
      return ConditionalModification._(
          node.offset,
          node.end,
          node is Statement,
          discard,
          _KeepNode(node.condition),
          _KeepNode(node.thenStatement),
          _KeepNode(node.elseStatement));
    } else {
      throw new UnimplementedError('TODO(paulberry)');
    }
  }

  ConditionalModification._(this.offset, this.end, this.isStatement,
      this.discard, this.condition, this.thenStatement, this.elseStatement);

  @override
  bool get isEmpty => discard.keepTrue && discard.keepFalse;

  @override
  Iterable<SourceEdit> get modifications {
    if (isEmpty) return const [];
    // TODO(paulberry): move the following logic into DartEditBuilder (see
    // dartbug.com/35872).
    var result = <SourceEdit>[];
    var keepNodes = <_KeepNode>[];
    if (!discard.pureCondition) {
      keepNodes.add(condition); // TODO(paulberry): test
    }
    if (discard.keepTrue) {
      keepNodes.add(thenStatement); // TODO(paulberry): test
    }
    if (discard.keepFalse) {
      keepNodes.add(elseStatement); // TODO(paulberry): test
    }
    // TODO(paulberry): test thoroughly
    for (int i = 0; i < keepNodes.length; i++) {
      var keepNode = keepNodes[i];
      if (i == 0 && keepNode.offset != offset) {
        result.add(SourceEdit(offset, 0, '/* '));
      }
      if (i != 0 || keepNode.offset != offset) {
        result.add(SourceEdit(keepNode.offset, 0, '*/ '));
      }
      if (i != keepNodes.length - 1 || keepNode.end != end) {
        result.add(SourceEdit(keepNode.end, 0,
            keepNode.isExpression && isStatement ? '; /*' : ' /*'));
      }
      if (i == keepNodes.length - 1 && keepNode.end != end) {
        result.add(SourceEdit(end, 0, ' */'));
      }
    }
    return result;
  }
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
  final bool _permissive;

  final Variables _variables;

  final NullabilityGraph _graph;

  /// Prepares to perform nullability migration.
  ///
  /// If [permissive] is `true`, exception handling logic will try to proceed
  /// as far as possible even though the migration algorithm is not yet
  /// complete.  TODO(paulberry): remove this mode once the migration algorithm
  /// is fully implemented.
  NullabilityMigration({bool permissive: false})
      : this._(permissive, NullabilityGraph());

  NullabilityMigration._(this._permissive, this._graph)
      : _variables = Variables(_graph);

  Map<Source, List<PotentialModification>> finish() {
    _graph.propagate();
    return _variables.getPotentialModifications();
  }

  void prepareInput(CompilationUnit unit, TypeProvider typeProvider) {
    unit.accept(ConstraintVariableGatherer(_variables,
        unit.declaredElement.source, _permissive, _graph, typeProvider));
  }

  void processInput(CompilationUnit unit, TypeProvider typeProvider) {
    unit.accept(ConstraintGatherer(typeProvider, _variables, _graph,
        unit.declaredElement.source, _permissive));
  }
}

/// Records information about the possible addition of an import
/// to the source code.
class PotentiallyAddImport extends PotentialModification {
  final _usages = <PotentialModification>[];

  final int _offset;
  final String _importPath;

  PotentiallyAddImport(
      AstNode beforeNode, this._importPath, PotentialModification usage)
      : _offset = beforeNode.offset {
    _usages.add(usage);
  }

  get importPath => _importPath;

  @override
  bool get isEmpty {
    for (PotentialModification usage in _usages) {
      if (!usage.isEmpty) {
        return false;
      }
    }
    return true;
  }

  // TODO(danrubel): change all of dartfix NNBD to use DartChangeBuilder
  @override
  Iterable<SourceEdit> get modifications =>
      isEmpty ? const [] : [SourceEdit(_offset, 0, "import '$_importPath';\n")];

  void addUsage(PotentialModification usage) {
    _usages.add(usage);
  }
}

/// Records information about the possible addition of a `@required` annotation
/// to the source code.
class PotentiallyAddRequired extends PotentialModification {
  final NullabilityNode _node;

  final int _offset;

  PotentiallyAddRequired(DefaultFormalParameter parameter, this._node)
      : _offset = parameter.offset;

  @override
  bool get isEmpty => _node.isNullable;

  @override
  Iterable<SourceEdit> get modifications =>
      isEmpty ? const [] : [SourceEdit(_offset, 0, '@required ')];
}

/// Interface used by data structures representing potential modifications to
/// the code being migrated.
abstract class PotentialModification {
  bool get isEmpty;

  /// Gets the individual migrations that need to be done, considering the
  /// solution to the constraint equations.
  Iterable<SourceEdit> get modifications;
}

class Variables implements VariableRecorder, VariableRepository {
  final _decoratedElementTypes = <Element, DecoratedType>{};

  final _decoratedTypeAnnotations =
      <Source, Map<int, DecoratedTypeAnnotation>>{};

  final _potentialModifications = <Source, List<PotentialModification>>{};

  final NullabilityGraph _graph;

  Variables(this._graph);

  @override
  DecoratedType decoratedElementType(Element element, {bool create: false}) =>
      _decoratedElementTypes[element] ??= create
          ? DecoratedType.forElement(element)
          : throw StateError('No element found');

  @override
  DecoratedType decoratedTypeAnnotation(
      Source source, TypeAnnotation typeAnnotation) {
    return _decoratedTypeAnnotations[source]
        [_uniqueOffsetForTypeAnnotation(typeAnnotation)];
  }

  Map<Source, List<PotentialModification>> getPotentialModifications() =>
      _potentialModifications;

  @override
  void recordConditionalDiscard(
      Source source, AstNode node, ConditionalDiscard conditionalDiscard) {
    _addPotentialModification(
        source, ConditionalModification(node, conditionalDiscard));
  }

  void recordDecoratedElementType(Element element, DecoratedType type) {
    _decoratedElementTypes[element] = type;
  }

  void recordDecoratedExpressionType(Expression node, DecoratedType type) {}

  void recordDecoratedTypeAnnotation(
      Source source, TypeAnnotation node, DecoratedTypeAnnotation type) {
    _addPotentialModification(source, type);
    (_decoratedTypeAnnotations[source] ??=
        {})[_uniqueOffsetForTypeAnnotation(node)] = type;
  }

  @override
  void recordExpressionChecks(
      Source source, Expression expression, ExpressionChecks checks) {
    _addPotentialModification(source, checks);
  }

  @override
  void recordPossiblyOptional(
      Source source, DefaultFormalParameter parameter, NullabilityNode node) {
    var modification = PotentiallyAddRequired(parameter, node);
    _addPotentialModification(source, modification);
    _addPotentialImport(
        source, parameter, modification, 'package:meta/meta.dart');
  }

  void _addPotentialImport(Source source, AstNode node,
      PotentialModification usage, String importPath) {
    // Get the compilation unit - assume not null
    while (node is! CompilationUnit) {
      node = node.parent;
    }
    var unit = node as CompilationUnit;

    // Find an existing import
    for (var directive in unit.directives) {
      if (directive is ImportDirective) {
        if (directive.uri.stringValue == importPath) {
          return;
        }
      }
    }

    // Add the usage to an existing modification if possible
    for (var modification in (_potentialModifications[source] ??= [])) {
      if (modification is PotentiallyAddImport) {
        if (modification.importPath == importPath) {
          modification.addUsage(usage);
          return;
        }
      }
    }

    // Create a new import modification
    AstNode beforeNode;
    for (var directive in unit.directives) {
      if (directive is ImportDirective || directive is ExportDirective) {
        beforeNode = directive;
        break;
      }
    }
    if (beforeNode == null) {
      for (var declaration in unit.declarations) {
        beforeNode = declaration;
        break;
      }
    }
    _addPotentialModification(
        source, PotentiallyAddImport(beforeNode, importPath, usage));
  }

  void _addPotentialModification(
      Source source, PotentialModification potentialModification) {
    (_potentialModifications[source] ??= []).add(potentialModification);
  }

  int _uniqueOffsetForTypeAnnotation(TypeAnnotation typeAnnotation) =>
      typeAnnotation is GenericFunctionType
          ? typeAnnotation.functionKeyword.offset
          : typeAnnotation.offset;
}

/// Helper object used by [ConditionalModification] to keep track of AST nodes
/// within the conditional expression.
class _KeepNode {
  final int offset;

  final int end;

  final bool isExpression;

  factory _KeepNode(AstNode node) {
    int offset = node.offset;
    int end = node.end;
    if (node is Block && node.statements.isNotEmpty) {
      offset = node.statements.beginToken.offset;
      end = node.statements.endToken.end;
    }
    return _KeepNode._(offset, end, node is Expression);
  }

  _KeepNode._(this.offset, this.end, this.isExpression);
}
