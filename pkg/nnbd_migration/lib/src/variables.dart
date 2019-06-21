// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:nnbd_migration/src/conditional_discard.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/expression_checks.dart';
import 'package:nnbd_migration/src/node_builder.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/potential_modification.dart';

class Variables implements VariableRecorder, VariableRepository {
  final NullabilityGraph _graph;

  final _decoratedElementTypes = <Element, DecoratedType>{};

  final _decoratedTypeAnnotations =
      <Source, Map<int, DecoratedTypeAnnotation>>{};

  final _potentialModifications = <Source, List<PotentialModification>>{};

  Variables(this._graph);

  @override
  DecoratedType decoratedElementType(Element element, {bool create: false}) =>
      _decoratedElementTypes[element] ??= create
          ? DecoratedType.forElement(element, _graph)
          : throw StateError('No element found');

  @override
  DecoratedType decoratedTypeAnnotation(
      Source source, TypeAnnotation typeAnnotation) {
    var annotationsInSource = _decoratedTypeAnnotations[source];
    if (annotationsInSource == null) {
      throw StateError('No declarated type annotations in ${source.fullName}; '
          'expected one for ${typeAnnotation.toSource()}');
    }
    return annotationsInSource[_uniqueOffsetForTypeAnnotation(typeAnnotation)];
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
      Source source, TypeAnnotation node, DecoratedTypeAnnotation type,
      {bool potentialModification: true}) {
    if (potentialModification) _addPotentialModification(source, type);
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
