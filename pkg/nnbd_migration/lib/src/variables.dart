// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart' as type_algebra;
import 'package:analyzer/src/generated/element_type_provider.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/src/already_migrated_code_decorator.dart';
import 'package:nnbd_migration/src/conditional_discard.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/expression_checks.dart';
import 'package:nnbd_migration/src/node_builder.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/potential_modification.dart';

/// Data structure used by [Variables.spanForUniqueIdentifier] to return an
/// offset/end pair.
class OffsetEndPair {
  final int offset;

  final int end;

  OffsetEndPair(this.offset, this.end);
}

class Variables implements VariableRecorder, VariableRepository {
  final NullabilityGraph _graph;

  final TypeProvider _typeProvider;

  final _conditionalDiscards = <Source, Map<int, ConditionalDiscard>>{};

  final _decoratedElementTypes = <Element, DecoratedType>{};

  final _decoratedTypeParameterBounds = <Element, DecoratedType>{};

  final _decoratedDirectSupertypes =
      <ClassElement, Map<ClassElement, DecoratedType>>{};

  final _decoratedTypeAnnotations = <Source, Map<int, DecoratedType>>{};

  final _expressionChecks = <Source, Map<int, ExpressionChecks>>{};

  final _potentialModifications = <Source, List<PotentialModification>>{};

  final _unnecessaryCasts = <Source, Set<int>>{};

  final AlreadyMigratedCodeDecorator _alreadyMigratedCodeDecorator;

  final NullabilityMigrationInstrumentation /*?*/ instrumentation;

  Variables(this._graph, this._typeProvider, {this.instrumentation})
      : _alreadyMigratedCodeDecorator =
            AlreadyMigratedCodeDecorator(_graph, _typeProvider);

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
          'expected one for ${typeAnnotation.toSource()} '
          '(offset ${typeAnnotation.offset})');
    }
    DecoratedType decoratedTypeAnnotation = annotationsInSource[
        uniqueIdentifierForSpan(typeAnnotation.offset, typeAnnotation.end)];
    if (decoratedTypeAnnotation == null) {
      throw StateError('Missing declarated type annotation'
          ' in ${source.fullName}; for ${typeAnnotation.toSource()}');
    }
    return decoratedTypeAnnotation;
  }

  /// Note: the optional argument [allowNullUnparentedBounds] is intended for
  /// the FixBuilder stage only, to allow it to cope with the situation where
  /// a type parameter element with a null parent doesn't have a decorated type
  /// associated with it.  This can arise because synthetic type parameter
  /// elements get created as a result of type system operations during
  /// resolution, and fortunately it isn't a problem during the FixBuilder stage
  /// because at that point the types we are dealing with are all
  /// post-migration types, so their bounds already reflect the correct
  /// nullabilities.
  @override
  DecoratedType decoratedTypeParameterBound(TypeParameterElement typeParameter,
      {bool allowNullUnparentedBounds = false}) {
    var enclosingElement = typeParameter.enclosingElement;
    if (enclosingElement == null) {
      var decoratedType =
          DecoratedType.decoratedTypeParameterBound(typeParameter);
      if (decoratedType == null && !allowNullUnparentedBounds) {
        throw StateError(
            'A decorated type for the bound of $typeParameter should '
            'have been stored by the NodeBuilder via recordTypeParameterBound');
      }
      return decoratedType;
    } else {
      var decoratedType = _decoratedTypeParameterBounds[typeParameter];
      if (decoratedType == null) {
        if (enclosingElement is GenericFunctionTypeElement) {
          // Each time code containing a typedef is re-analyzed, fresh elements
          // are created for type parameters.  So it's possible that we may not
          // be able to find the decorated type for the type parameter, but we
          // can find the decorated type for the enclosing generic function type
          // and use its decorated type parameter bounds.
          int i = enclosingElement.typeParameters.indexOf(typeParameter);
          decoratedType =
              decoratedElementType(enclosingElement).typeFormalBounds[i];
        } else {
          if (_graph.isBeingMigrated(typeParameter.library.source)) {
            throw StateError(
                'A decorated type for the bound of $typeParameter should '
                'have been stored by the NodeBuilder via '
                'recordTypeParameterBound');
          }
          decoratedType = _alreadyMigratedCodeDecorator.decorate(
              typeParameter.bound ?? DynamicTypeImpl.instance, typeParameter);
        }
        instrumentation?.externalDecoratedTypeParameterBound(
            typeParameter, decoratedType);
        _decoratedTypeParameterBounds[typeParameter] = decoratedType;
      }
      return decoratedType;
    }
  }

  /// Retrieves the [ExpressionChecks] object corresponding to the given
  /// [expression], if one exists; otherwise null.
  ExpressionChecks expressionChecks(Source source, Expression expression) {
    return (_expressionChecks[source] ??
        {})[uniqueIdentifierForSpan(expression.offset, expression.end)];
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
        {})[uniqueIdentifierForSpan(node.offset, node.end)] = type;
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
    (_expressionChecks[source] ??=
            {})[uniqueIdentifierForSpan(expression.offset, expression.end)] =
        origin.checks;
  }

  @override
  void recordPossiblyOptional(
      Source source, DefaultFormalParameter parameter, NullabilityNode node) {
    var modification = PotentiallyAddRequired(parameter, node);
    _addPotentialModification(source, modification);
  }

  @override
  void recordUnnecessaryCast(Source source, AsExpression node) {
    bool newlyAdded = (_unnecessaryCasts[source] ??= {})
        .add(uniqueIdentifierForSpan(node.offset, node.end));
    assert(newlyAdded);
  }

  /// Convert this decorated type into the [DartType] that it will represent
  /// after the code has been migrated.
  ///
  /// This method should be used after nullability propagation; it makes use of
  /// the nullabilities associated with nullability nodes to determine which
  /// types should be nullable and which types should not.
  DartType toFinalType(DecoratedType decoratedType) {
    var type = decoratedType.type;
    if (type.isVoid || type.isDynamic) return type;
    if (type.isBottom || type.isDartCoreNull) {
      if (decoratedType.node.isNullable) {
        return (_typeProvider.nullType as TypeImpl)
            .withNullability(NullabilitySuffix.none);
      } else {
        return NeverTypeImpl.instance;
      }
    }
    var nullabilitySuffix = decoratedType.node.isNullable
        ? NullabilitySuffix.question
        : NullabilitySuffix.none;
    if (type is FunctionType) {
      var newTypeFormals = <TypeParameterElementImpl>[];
      var typeFormalSubstitution = <TypeParameterElement, DartType>{};
      for (var typeFormal in decoratedType.typeFormals) {
        var newTypeFormal = TypeParameterElementImpl.synthetic(typeFormal.name);
        newTypeFormals.add(newTypeFormal);
        typeFormalSubstitution[typeFormal] = TypeParameterTypeImpl(
            newTypeFormal,
            nullabilitySuffix: NullabilitySuffix.none);
      }
      for (int i = 0; i < newTypeFormals.length; i++) {
        var bound = type_algebra.substitute(
            toFinalType(decoratedType.typeFormalBounds[i]),
            typeFormalSubstitution);
        if (!bound.isDynamic &&
            !(bound.isDartCoreObject &&
                bound.nullabilitySuffix == NullabilitySuffix.question)) {
          newTypeFormals[i].bound = bound;
        }
      }
      var parameters = <ParameterElement>[];
      for (int i = 0; i < type.parameters.length; i++) {
        var origParameter = type.parameters[i];
        ParameterKind parameterKind;
        DecoratedType parameterType;
        var name = origParameter.name;
        if (origParameter.isNamed) {
          // TODO(paulberry): infer ParameterKind.NAMED_REQUIRED when
          // appropriate. See https://github.com/dart-lang/sdk/issues/38596.
          parameterKind = ParameterKind.NAMED;
          parameterType = decoratedType.namedParameters[name];
        } else {
          parameterKind = origParameter.isOptional
              ? ParameterKind.POSITIONAL
              : ParameterKind.REQUIRED;
          parameterType = decoratedType.positionalParameters[i];
        }
        parameters.add(ParameterElementImpl.synthetic(
            name,
            type_algebra.substitute(
                toFinalType(parameterType), typeFormalSubstitution),
            parameterKind));
      }
      return FunctionTypeImpl(
        typeFormals: newTypeFormals,
        parameters: parameters,
        returnType: type_algebra.substitute(
          toFinalType(decoratedType.returnType),
          typeFormalSubstitution,
        ),
        nullabilitySuffix: nullabilitySuffix,
      );
    } else if (type is InterfaceType) {
      return InterfaceTypeImpl(
        element: type.element,
        typeArguments: [
          for (var arg in decoratedType.typeArguments) toFinalType(arg)
        ],
        nullabilitySuffix: nullabilitySuffix,
      );
    } else if (type is TypeParameterType) {
      var element = type.element;
      var decoratedBound =
          decoratedTypeParameterBound(element, allowNullUnparentedBounds: true);
      // Note: it's possible that we won't have a decorated type parameter bound
      // for the type parameter.  If that happens, it's because it was a type
      // parameter that was synthetically generated from other type parameters
      // during resolution (e.g. because of a LUB computation or a
      // substitution).  If this occurs, then the type parameters it was based
      // on should have had bounds reflecting their final types, so we can just
      // use the element's bound.
      var finalBound =
          decoratedBound == null ? element.bound : toFinalType(decoratedBound);
      // The easiest way to override the bound is to create a
      // TypeParameterMember and supply the new bound.
      var member = TypeParameterMember(
          element.declaration, type_algebra.Substitution.empty, finalBound);
      return TypeParameterTypeImpl(member,
          nullabilitySuffix: nullabilitySuffix);
    } else {
      // The above cases should cover all possible types.  On the off chance
      // they don't, fall back on returning DecoratedType.type.
      assert(false, 'Unexpected type (${type.runtimeType})');
      return type;
    }
  }

  /// Queries whether, prior to migration, an unnecessary cast existed at
  /// [node].
  bool wasUnnecessaryCast(Source source, AsExpression node) =>
      (_unnecessaryCasts[source] ?? const {})
          .contains(uniqueIdentifierForSpan(node.offset, node.end));

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

    if (element is FunctionTypeAliasElement) {
      // For `typedef F<T> = Function(T)`, get the `function` which is (in this
      // case) `Function(T)`. Without this we would get `Function<T>(T)` which
      // is incorrect. This is a known issue with `.type` on typedefs in the
      // analyzer.
      element = (element as FunctionTypeAliasElement).function;
    }

    if (element is FunctionTypedElement) {
      decoratedType = _alreadyMigratedCodeDecorator.decorate(
          element.preMigrationType, element);
    } else if (element is VariableElement) {
      decoratedType = _alreadyMigratedCodeDecorator.decorate(
          element.preMigrationType, element);
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

  /// Inverts the logic of [uniqueIdentifierForSpan], producing an (offset, end)
  /// pair.
  @visibleForTesting
  static OffsetEndPair spanForUniqueIdentifier(int span) {
    // The formula for uniqueIdentifierForSpan was:
    //   span = end*(end + 1) / 2 + offset
    // In other words, all encodings with the same `end` value are consecutive.
    // So we just have to figure out the `end` value for this `span`, then
    // use [uniqueIdentifierForSpan] to find the first encoding with this `end`
    // value, and subtract to find the offset.
    //
    // To find the `end` value, we assume offset = 0 and solve for `end` using
    // the quadratic formula:
    //   span = end*(end + 1) / 2
    //   end^2 + end - 2*span = 0
    //   end = -1 +/- sqrt(1 + 8*span)
    // We can reslove the `+/-` to `+` (since the result we seek can't be
    // negative), so that yields:
    //   end = sqrt(1 + 8*span) - 1
    int end = (math.sqrt(1 + 8.0 * span) - 1).floor();
    assert(end >= 0);

    // There's a slight chance of numerical instabilities in `sqrt` leading to
    // a result for `end` that's off by 1, so we loop to find the correct
    // result:
    while (true) {
      // Compute the first `span` value corresponding to this `end` value.
      int firstSpanForThisEnd = uniqueIdentifierForSpan(0, end);

      // Offsets are encoded consecutively so we can find the offset by
      // subtracting:
      int offset = span - firstSpanForThisEnd;

      if (offset < 0) {
        // Oops, `end` must have been too large.  Decrement and try again.
        assert(end > 0);
        --end;
      } else if (offset > end) {
        // Oops, `end` must have been too small.  Increment and try again.
        ++end;
      } else {
        return OffsetEndPair(offset, end);
      }
    }
  }

  /// Combine the given [offset] and [end] into a unique integer that depends
  /// on both of them, taking advantage of the fact that `0 <= offset <= end`.
  @visibleForTesting
  static int uniqueIdentifierForSpan(int offset, int end) {
    assert(0 <= offset && offset <= end);
    // Our encoding is based on the observation that if you make a graph of the
    // set of all possible (offset, end) pairs, marking those that satisfy
    // `0 <= offset <= end` with an `x`, you get a triangle shape:
    //
    //       offset
    //     +-------->
    //     |x
    //     |xx
    // end |xxx
    //     |xxxx
    //     V
    //
    // If we assign integers to the `x`s in the order they appear in this graph,
    // then the rows start with numbers 0, 1, 3, 6, 10, etc.  This can be
    // computed from `end` as `end*(end + 1)/2`.  We use `~/` for integer
    // division.
    return end * (end + 1) ~/ 2 + offset;
  }
}

extension on FunctionTypedElement {
  FunctionType get preMigrationType {
    var previousElementTypeProvider = ElementTypeProvider.current;
    try {
      ElementTypeProvider.current = const ElementTypeProvider();
      return type;
    } finally {
      ElementTypeProvider.current = previousElementTypeProvider;
    }
  }
}

extension on VariableElement {
  DartType get preMigrationType {
    var previousElementTypeProvider = ElementTypeProvider.current;
    try {
      ElementTypeProvider.current = const ElementTypeProvider();
      return type;
    } finally {
      ElementTypeProvider.current = previousElementTypeProvider;
    }
  }
}
