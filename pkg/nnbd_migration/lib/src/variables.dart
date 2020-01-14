// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/src/already_migrated_code_decorator.dart';
import 'package:nnbd_migration/src/conditional_discard.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/expression_checks.dart';
import 'package:nnbd_migration/src/node_builder.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/potential_modification.dart';

class Variables implements VariableRecorder, VariableRepository {
  final NullabilityGraph _graph;

  final _conditionalDiscards = <Source, Map<int, ConditionalDiscard>>{};

  final _decoratedElementTypes = <Element, DecoratedType>{};

  final _decoratedTypeParameterBounds = <Element, DecoratedType>{};

  final _decoratedDirectSupertypes =
      <ClassElement, Map<ClassElement, DecoratedType>>{};

  final _decoratedTypeAnnotations = <Source, Map<int, DecoratedType>>{};

  final _potentialModifications = <Source, List<PotentialModification>>{};

  final AlreadyMigratedCodeDecorator _alreadyMigratedCodeDecorator;

  final NullabilityMigrationInstrumentation /*?*/ instrumentation;

  Variables(this._graph, TypeProvider typeProvider, {this.instrumentation})
      : _alreadyMigratedCodeDecorator =
            AlreadyMigratedCodeDecorator(_graph, typeProvider);

  @override
  Map<ClassElement, DecoratedType> decoratedDirectSupertypes(
      ClassElement class_) {
    return _decoratedDirectSupertypes[class_] ??=
        _decorateDirectSupertypes(class_);
  }

  @override
  DecoratedType decoratedElementType(Element element) {
    assert(element is! TypeParameterElement,
        'Use decoratedTypeParameterBound instead');
    return _decoratedElementTypes[element] ??=
        _createDecoratedElementType(element);
  }

  @override
  DecoratedType decoratedTypeAnnotation(
      Source source, TypeAnnotation typeAnnotation) {
    var annotationsInSource = _decoratedTypeAnnotations[source];
    if (annotationsInSource == null) {
      throw StateError('No declarated type annotations in ${source.fullName}; '
          'expected one for ${typeAnnotation.toSource()}');
    }
    DecoratedType decoratedTypeAnnotation =
        annotationsInSource[_uniqueOffsetForTypeAnnotation(typeAnnotation)];
    if (decoratedTypeAnnotation == null) {
      throw StateError('Missing declarated type annotation'
          ' in ${source.fullName}; for ${typeAnnotation.toSource()}');
    }
    return decoratedTypeAnnotation;
  }

  @override
  DecoratedType decoratedTypeParameterBound(
      TypeParameterElement typeParameter) {
    if (typeParameter.enclosingElement == null) {
      var decoratedType =
          DecoratedType.decoratedTypeParameterBound(typeParameter);
      if (decoratedType == null) {
        throw StateError(
            'A decorated type for the bound of $typeParameter should '
            'have been stored by the NodeBuilder via recordTypeParameterBound');
      }
      return decoratedType;
    } else {
      var decoratedType = _decoratedTypeParameterBounds[typeParameter];
      if (decoratedType == null) {
        if (_graph.isBeingMigrated(typeParameter.library.source)) {
          throw StateError(
              'A decorated type for the bound of $typeParameter should '
              'have been stored by the NodeBuilder via '
              'recordTypeParameterBound');
        }
        decoratedType = _alreadyMigratedCodeDecorator.decorate(
            typeParameter.bound ?? DynamicTypeImpl.instance, typeParameter);
        instrumentation?.externalDecoratedTypeParameterBound(
            typeParameter, decoratedType);
        _decoratedTypeParameterBounds[typeParameter] = decoratedType;
      }
      return decoratedType;
    }
  }

  ConditionalDiscard getConditionalDiscard(Source source, AstNode node) =>
      (_conditionalDiscards[source] ?? {})[node.offset];

  Map<Source, List<PotentialModification>> getPotentialModifications() =>
      _potentialModifications;

  @override
  void recordConditionalDiscard(
      Source source, AstNode node, ConditionalDiscard conditionalDiscard) {
    (_conditionalDiscards[source] ??= {})[node.offset] = conditionalDiscard;
    _addPotentialModification(
        source, ConditionalModification(node, conditionalDiscard));
  }

  @override
  void recordDecoratedDirectSupertypes(ClassElement class_,
      Map<ClassElement, DecoratedType> decoratedDirectSupertypes) {
    _decoratedDirectSupertypes[class_] = decoratedDirectSupertypes;
  }

  void recordDecoratedElementType(Element element, DecoratedType type) {
    assert(() {
      assert(element is! TypeParameterElement,
          'Use recordDecoratedTypeParameterBound instead');
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

  void recordDecoratedTypeAnnotation(Source source, TypeAnnotation node,
      DecoratedType type, PotentiallyAddQuestionSuffix potentialModification) {
    instrumentation?.explicitTypeNullability(source, node, type.node);
    if (potentialModification != null)
      _addPotentialModification(source, potentialModification);
    (_decoratedTypeAnnotations[source] ??=
        {})[_uniqueOffsetForTypeAnnotation(node)] = type;
  }

  @override
  void recordDecoratedTypeParameterBound(
      TypeParameterElement typeParameter, DecoratedType bound) {
    if (typeParameter.enclosingElement == null) {
      DecoratedType.recordTypeParameterBound(typeParameter, bound);
    } else {
      _decoratedTypeParameterBounds[typeParameter] = bound;
    }
  }

  @override
  void recordExpressionChecks(
      Source source, Expression expression, ExpressionChecksOrigin origin) {
    _addPotentialModification(source, origin.checks);
  }

  @override
  void recordPossiblyOptional(
      Source source, DefaultFormalParameter parameter, NullabilityNode node) {
    var modification = PotentiallyAddRequired(parameter, node);
    _addPotentialModification(source, modification);
  }

  void _addPotentialModification(
      Source source, PotentialModification potentialModification) {
    (_potentialModifications[source] ??= []).add(potentialModification);
  }

  /// Creates a decorated type for the given [element], which should come from
  /// an already-migrated library (or the SDK).
  DecoratedType _createDecoratedElementType(Element element) {
    if (_graph.isBeingMigrated(element.library.source)) {
      throw StateError('A decorated type for $element should have been stored '
          'by the NodeBuilder via recordDecoratedElementType');
    }

    DecoratedType decoratedType;
    if (element is Member) {
      assert((element as Member).isLegacy);
      element = element.declaration;
    }

    if (element is FunctionTypedElement) {
      decoratedType =
          _alreadyMigratedCodeDecorator.decorate(element.type, element);
    } else if (element is VariableElement) {
      decoratedType =
          _alreadyMigratedCodeDecorator.decorate(element.type, element);
    } else {
      // TODO(paulberry)
      throw UnimplementedError('Decorating ${element.runtimeType}');
    }
    instrumentation?.externalDecoratedType(element, decoratedType);
    return decoratedType;
  }

  /// Creates an entry [_decoratedDirectSupertypes] for an already-migrated
  /// class.
  Map<ClassElement, DecoratedType> _decorateDirectSupertypes(
      ClassElement class_) {
    var result = <ClassElement, DecoratedType>{};
    for (var decoratedSupertype
        in _alreadyMigratedCodeDecorator.getImmediateSupertypes(class_)) {
      var class_ = (decoratedSupertype.type as InterfaceType).element;
      result[class_] = decoratedSupertype;
    }
    return result;
  }

  int _uniqueOffsetForTypeAnnotation(TypeAnnotation typeAnnotation) =>
      typeAnnotation is GenericFunctionType
          ? typeAnnotation.functionKeyword.offset
          : typeAnnotation.offset;
}
