// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/handle.dart';
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

  final _decoratedDirectSupertypes =
      <ClassElement, Map<ClassElement, DecoratedType>>{};

  final _decoratedTypeAnnotations =
      <Source, Map<int, DecoratedTypeAnnotation>>{};

  final _potentialModifications = <Source, List<PotentialModification>>{};

  Variables(this._graph);

  @override
  Map<ClassElement, DecoratedType> decoratedDirectSupertypes(
      ClassElement class_) {
    assert(class_ is! ClassElementHandle);
    return _decoratedDirectSupertypes[class_] ??
        _decorateDirectSupertypes(class_);
  }

  @override
  DecoratedType decoratedElementType(Element element) =>
      _decoratedElementTypes[element] ??= _createDecoratedElementType(element);

  @override
  DecoratedType decoratedTypeAnnotation(
      Source source, TypeAnnotation typeAnnotation) {
    var annotationsInSource = _decoratedTypeAnnotations[source];
    if (annotationsInSource == null) {
      throw StateError('No declarated type annotations in ${source.fullName}; '
          'expected one for ${typeAnnotation.toSource()}');
    }
    DecoratedTypeAnnotation decoratedTypeAnnotation =
        annotationsInSource[_uniqueOffsetForTypeAnnotation(typeAnnotation)];
    if (decoratedTypeAnnotation == null) {
      throw StateError('Missing declarated type annotation'
          ' in ${source.fullName}; for ${typeAnnotation.toSource()}');
    }
    return decoratedTypeAnnotation;
  }

  Map<Source, List<PotentialModification>> getPotentialModifications() =>
      _potentialModifications;

  @override
  void recordConditionalDiscard(
      Source source, AstNode node, ConditionalDiscard conditionalDiscard) {
    _addPotentialModification(
        source, ConditionalModification(node, conditionalDiscard));
  }

  @override
  void recordDecoratedDirectSupertypes(ClassElement class_,
      Map<ClassElement, DecoratedType> decoratedDirectSupertypes) {
    assert(() {
      assert(class_ is! ClassElementHandle);
      for (var key in decoratedDirectSupertypes.keys) {
        assert(key is! ClassElementHandle);
      }
      return true;
    }());
    _decoratedDirectSupertypes[class_] = decoratedDirectSupertypes;
  }

  void recordDecoratedElementType(Element element, DecoratedType type) {
    assert(() {
      var library = element.library;
      if (library == null) {
        // No problem; the element is probably a parameter of a function type
        // expressed using new-style Function syntax.
      } else {
        assert(_graph.isBeingMigrated(library.source));
      }
      return true;
    }());
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

  DecoratedType _createDecoratedElementType(Element element) {
    if (_graph.isBeingMigrated(element.library.source)) {
      throw StateError('A decorated type for $element should have been stored '
          'by the NodeBuilder via recordDecoratedElementType');
    }
    return DecoratedType.forElement(element, _graph);
  }

  /// Creates an entry [_decoratedDirectSupertypes] for an already-migrated
  /// class.
  Map<ClassElement, DecoratedType> _decorateDirectSupertypes(
      ClassElement class_) {
    if (class_.type.isObject) {
      // TODO(paulberry): this special case is just to get the basic
      // infrastructure working (necessary since all classes derive from
      // Object).  Once we have the full implementation this case shouldn't be
      // needed.
      return const {};
    }
    throw UnimplementedError('TODO(paulberry)');
  }

  int _uniqueOffsetForTypeAnnotation(TypeAnnotation typeAnnotation) =>
      typeAnnotation is GenericFunctionType
          ? typeAnnotation.functionKeyword.offset
          : typeAnnotation.offset;
}
