// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_algebra.dart';

import '../kernel/internal_ast.dart';
import 'inference_visitor_base.dart';
import 'type_constraint_gatherer.dart';
import 'type_schema.dart';
import 'type_schema_environment.dart';

/// Helper class use to disambiguate a map/set literal.
class const ElementInferenceKind({
  /// Whether the literal can be an iterable.
  ///
  /// This is true if the literal didn't contains type arguments or elements
  /// that prevent it from being a set literal.
  required final bool canBeIterable,

  /// Whether the literal can be a map.
  ///
  /// This is true if the literal didn't contains type arguments or elements
  /// that prevent it from being a map literal.
  required final bool canBeMap,
}) {
  @override
  String toString() =>
      'ElementInferenceKind(canBeIterable=$canBeIterable,canBeMap=$canBeMap)';
}

/// Inference context object used to provide type context information for the
/// inference of elements and to collect information needed to infer the
/// enclosing list, set, or map literal.
sealed class ElementInferenceContext {
  /// The type of literal elements as known before inferring the elements.
  ElementType get elementTypeContext;

  /// The type context used for inference of spread elements.
  SpreadContext get spreadContext;

  /// Called to register the inferred type of an element.
  void registerElementType(ElementType elementType);

  /// Computes the element kind of the literal based on the information
  /// collected in this context object.
  ElementInferenceKind determineElementKind();

  /// Infers the element type of the literal.
  ///
  /// If [asMap] is `true`, the literal is inferred as a map literal. Otherwise
  /// it is inferred as a list or set literal.
  ElementType inferElementType({required bool asMap});

  /// Registers that a map entry element occurred at the given [fileOffset]
  /// within the literal.
  ///
  /// This is used to disambiguate map/set literals.
  void registerMapEntry({required int fileOffset});

  /// Registers that a spread element of a map type occurred at the given
  /// [fileOffset] within the literal.
  ///
  /// This is used to disambiguate map/set literals.
  void registerMapSpread({required int fileOffset});

  /// Registers that a spread element of an iterable type occurred at the given
  /// [fileOffset] within the literal.
  ///
  /// This is used to disambiguate map/set literals.
  void registerIterableSpread({
    required DartType type,
    required int fileOffset,
  });

  /// Registers that an expression element occurred at the given [fileOffset]
  /// within the literal.
  ///
  /// This is used to disambiguate map/set literals.
  void registerExpression({required int fileOffset});
}

/// Context object used for the inference of list and set literals of a known
/// element type.
class ListSetElementInferenceContext({
  @override required final ElementType elementTypeContext,
  @override required final SpreadContext spreadContext,
}) extends ElementInferenceContext {
  @override
  void registerElementType(ElementType elementType) {}

  @override
  ElementInferenceKind determineElementKind() {
    return const ElementInferenceKind(canBeMap: false, canBeIterable: true);
  }

  @override
  ElementType inferElementType({required bool asMap}) {
    assert(!asMap, "Unexpected element kind: map");
    return elementTypeContext;
  }

  @override
  void registerMapEntry({required int fileOffset}) {}

  @override
  void registerIterableSpread({
    required DartType type,
    required int fileOffset,
  }) {}

  @override
  void registerMapSpread({required int fileOffset}) {}

  @override
  void registerExpression({required int fileOffset}) {}
}

/// Context object used for inference of a list literal with an unknown element
/// type.
class InferredListElementInferenceContext extends ElementInferenceContext {
  @override
  final ElementType elementTypeContext;
  @override
  final SpreadContext spreadContext;
  final DartType _formalType;
  final InferenceVisitorBase _visitor;
  final TypeConstraintGatherer _gatherer;
  final List<StructuralParameter> _typeParametersToInfer;
  final List<DartType> _initiallyInferredTypes;
  final InternalNode _node;
  final List<DartType> _expressionTypes = [];

  new _({
    required this.elementTypeContext,
    required this.spreadContext,
    required this._formalType,
    required this._visitor,
    required this._gatherer,
    required this._typeParametersToInfer,
    required this._initiallyInferredTypes,
    required this._node,
  });

  factory({
    required InferenceVisitorBase visitor,
    required DartType typeContext,
    required bool forConst,
    required InternalNode node,
  }) {
    // The type context is an iterable so we set up the inference as if we
    // call a method that returns the corresponding `List` type:
    //
    //    List<E> method<E>(E e1, E e2, E e3, ...)
    FreshStructuralParametersFromTypeParameters freshTypeParameters =
        getFreshStructuralParametersFromTypeParameters(
          visitor.coreTypes.listClass.typeParameters,
        );
    InterfaceType listType = visitor.coreTypes.thisInterfaceType(
      visitor.coreTypes.listClass,
      Nullability.nonNullable,
    );
    List<StructuralParameter> typeParametersToInfer =
        freshTypeParameters.freshTypeParameters;
    listType = freshTypeParameters.substitute(listType) as InterfaceType;
    // We pretend that all parameter types are the type argument of the list
    // type.
    DartType formalType = listType.typeArguments[0];

    TypeConstraintGatherer gatherer = visitor.typeSchemaEnvironment
        .setupGenericTypeInference(
          listType,
          typeParametersToInfer,
          typeContext,
          isConst: forConst,
          inferenceUsingBoundsIsEnabled:
              visitor.libraryFeatures.inferenceUsingBounds.isEnabled,
          typeOperations: visitor.cfeOperations,
          inferenceResultForTesting: visitor
              .dataForTesting
              // Coverage-ignore(suite): Not run.
              ?.typeInferenceResult,
          internalNodeForTesting: node,
        );
    List<DartType> inferredTypes = visitor.typeSchemaEnvironment
        .choosePreliminaryTypes(
          gatherer.computeConstraints(),
          typeParametersToInfer,
          /* previouslyInferredTypes= */ null,
          inferenceUsingBoundsIsEnabled:
              visitor.libraryFeatures.inferenceUsingBounds.isEnabled,
          dataForTesting: visitor.dataForTesting,
          internalNodeForTesting: node,
          typeOperations: visitor.cfeOperations,
        );
    DartType typeArgument = inferredTypes[0];
    SpreadContext spreadContext = new IterableSpreadContext(
      typeArgument: typeArgument,
    );

    return new InferredListElementInferenceContext._(
      elementTypeContext: new IterableElementType(typeArgument),
      spreadContext: spreadContext,
      formalType: formalType,
      visitor: visitor,
      gatherer: gatherer,
      typeParametersToInfer: typeParametersToInfer,
      initiallyInferredTypes: inferredTypes,
      node: node,
    );
  }

  @override
  void registerElementType(ElementType elementType) {
    _expressionTypes.add(elementType.expressionType);
  }

  @override
  ElementInferenceKind determineElementKind() {
    return const ElementInferenceKind(canBeMap: false, canBeIterable: true);
  }

  @override
  ElementType inferElementType({required bool asMap}) {
    assert(!asMap, "Unexpected element kind: map");

    // We pretend that the called method has as many parameters as the seen
    // [_expressionTypes]. All use the [_formalType] as parameter type.
    List<DartType> formalTypes = new List.filled(
      _expressionTypes.length,
      _formalType,
    );
    _gatherer.constrainArguments(
      formalTypes,
      _expressionTypes,
      internalNodeForTesting: _node,
    );
    List<DartType> inferredTypes = _visitor.typeSchemaEnvironment
        .chooseFinalTypes(
          _gatherer.computeConstraints(),
          _typeParametersToInfer,
          _initiallyInferredTypes,
          inferenceUsingBoundsIsEnabled:
              _visitor.libraryFeatures.inferenceUsingBounds.isEnabled,
          dataForTesting: _visitor.dataForTesting,
          internalNodeForTesting: _node,
          typeOperations: _visitor.cfeOperations,
        );
    if (_visitor.dataForTesting != null) {
      // Coverage-ignore-block(suite): Not run.
      _visitor
              .dataForTesting!
              .typeInferenceResult
              .inferredTypeArguments[_node] =
          inferredTypes;
    }
    DartType typeArgument = inferredTypes[0];

    if (!_visitor.libraryFeatures.genericMetadata.isEnabled) {
      _visitor.checkGenericFunctionTypeArgument(typeArgument, _node.fileOffset);
    }

    return new IterableElementType(typeArgument);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void registerMapEntry({required int fileOffset}) {}

  @override
  void registerIterableSpread({
    required DartType type,
    required int fileOffset,
  }) {}

  @override
  void registerMapSpread({required int fileOffset}) {}

  @override
  void registerExpression({required int fileOffset}) {}
}

/// Context object used for the inference of map literals of known key/value
/// types.
class MapElementInferenceContext({
  @override required final ElementType elementTypeContext,
  @override required final SpreadContext spreadContext,
}) extends ElementInferenceContext {
  @override
  void registerElementType(ElementType elementType) {}

  @override
  ElementInferenceKind determineElementKind() {
    return const ElementInferenceKind(canBeMap: true, canBeIterable: false);
  }

  @override
  ElementType inferElementType({required bool asMap}) {
    assert(asMap, "Unexpected element kind: set");
    return elementTypeContext;
  }

  @override
  void registerMapEntry({required int fileOffset}) {}

  @override
  void registerIterableSpread({
    required DartType type,
    required int fileOffset,
  }) {}

  @override
  void registerMapSpread({required int fileOffset}) {}

  @override
  void registerExpression({required int fileOffset}) {}
}

/// Context object used for inference of a map or set literal. The literal can
/// be an ambiguous map/set literal, or it can be known map or set literal but
/// with unknown type argument(s).
class InferredMapOrSetElementInferenceContext extends ElementInferenceContext {
  @override
  final ElementType elementTypeContext;
  @override
  final SpreadContext spreadContext;
  final DartType _formalKeyType;
  final DartType _formalValueType;
  final InferenceVisitorBase _visitor;
  final TypeConstraintGatherer _gatherer;
  final List<StructuralParameter> _typeParametersToInfer;
  final List<DartType> _initiallyInferredTypes;
  final bool _typeContextIsMap;
  final bool _typeContextIsIterable;
  final InternalNode _node;
  final List<ElementType> _elementTypes = [];

  /// Stores the offset of the expression found by inferMapEntry.
  int? _expressionOffset;

  /// Stores the offset of the map entry found by inferMapEntry.
  int? _mapEntryOffset;

  /// Stores the offset of the map spread found by inferMapEntry.
  int? _mapSpreadOffset;

  /// Stores the offset of the iterable spread found by inferMapEntry.
  int? _iterableSpreadOffset;

  /// Stores the type of the iterable spread found by inferMapEntry.
  DartType? _iterableSpreadType;

  new _({
    required this.elementTypeContext,
    required this.spreadContext,
    required this._formalKeyType,
    required this._formalValueType,
    required this._visitor,
    required this._gatherer,
    required this._typeParametersToInfer,
    required this._initiallyInferredTypes,
    required this._node,
    required this._typeContextIsMap,
    required this._typeContextIsIterable,
  });

  factory({
    required InferenceVisitorBase visitor,
    required DartType typeContext,
    required bool forConst,
    required InternalNode node,
  }) {
    Class mapClass = visitor.coreTypes.mapClass;
    Class setClass = visitor.coreTypes.setClass;

    SpreadContext spreadContext;

    DartType? unfuturedTypeContext = visitor.typeSchemaEnvironment.flatten(
      typeContext,
    );

    // Ambiguous set/map literal
    List<DartType>? typeArgumentsAsMap;
    List<DartType>? typeArgumentsAsIterable;
    bool typeContextIsMap = false;
    bool typeContextIsIterable = false;

    if (unfuturedTypeContext is TypeDeclarationType) {
      typeArgumentsAsMap = visitor.hierarchyBuilder
          .getTypeArgumentsAsInstanceOf(unfuturedTypeContext, mapClass);
      typeArgumentsAsIterable = visitor.hierarchyBuilder
          .getTypeArgumentsAsInstanceOf(
            unfuturedTypeContext,
            visitor.coreTypes.iterableClass,
          );
    }
    if (typeArgumentsAsMap != null) {
      DartType keyType = typeArgumentsAsMap[0];
      DartType valueType = typeArgumentsAsMap[1];
      spreadContext = new MapSpreadContext(
        keyType: keyType,
        valueType: valueType,
      );
      typeContextIsMap = true;
    } else if (typeArgumentsAsIterable != null) {
      DartType typeArgument = typeArgumentsAsIterable[0];
      spreadContext = new IterableSpreadContext(typeArgument: typeArgument);
      typeContextIsIterable = true;
    } else {
      spreadContext = const UnknownSpreadContext();
    }

    List<StructuralParameter> typeParametersToInfer;
    DartType returnType;
    ElementType elementType;
    DartType formalKeyType;
    DartType formalValueType;
    if (typeContextIsIterable) {
      // The type context is an iterable so we set up the inference as if we
      // call a method that returns the corresponding `Set` type:
      //
      //    Set<E> method<E>(E e1, E e2, E e3, ...)
      InterfaceType setType = visitor.coreTypes.thisInterfaceType(
        setClass,
        Nullability.nonNullable,
      );
      FreshStructuralParametersFromTypeParameters freshTypeParameters =
          getFreshStructuralParametersFromTypeParameters(
            setClass.typeParameters,
          );
      typeParametersToInfer = freshTypeParameters.freshTypeParameters;
      returnType = setType =
          freshTypeParameters.substitute(setType) as InterfaceType;
      // We pretend that all parameter types are the type argument of the return
      // type.
      formalKeyType = formalValueType = setType.typeArguments[0];
    } else {
      // The type context is a map so we set up the inference as if we call a
      // method that returns the corresponding `Map` type:
      //
      //    Map<K, V> method<K, V>(K k1, V v1, K k2, V v2, ...)
      InterfaceType mapType = visitor.coreTypes.thisInterfaceType(
        mapClass,
        Nullability.nonNullable,
      );
      FreshStructuralParametersFromTypeParameters freshTypeParameters =
          getFreshStructuralParametersFromTypeParameters(
            mapClass.typeParameters,
          );
      typeParametersToInfer = freshTypeParameters.freshTypeParameters;
      returnType = mapType =
          freshTypeParameters.substitute(mapType) as InterfaceType;
      // We pretend that all parameter types alternating between the type
      // arguments of the return type.
      formalKeyType = mapType.typeArguments[0];
      formalValueType = mapType.typeArguments[1];
    }

    TypeConstraintGatherer gatherer = visitor.typeSchemaEnvironment
        .setupGenericTypeInference(
          returnType,
          typeParametersToInfer,
          typeContext,
          isConst: forConst,
          inferenceUsingBoundsIsEnabled:
              visitor.libraryFeatures.inferenceUsingBounds.isEnabled,
          typeOperations: visitor.cfeOperations,
          inferenceResultForTesting: visitor
              .dataForTesting
              // Coverage-ignore(suite): Not run.
              ?.typeInferenceResult,
          internalNodeForTesting: node,
        );
    List<DartType> inferredTypes = visitor.typeSchemaEnvironment
        .choosePreliminaryTypes(
          gatherer.computeConstraints(),
          typeParametersToInfer,
          /* previouslyInferredTypes= */ null,
          inferenceUsingBoundsIsEnabled:
              visitor.libraryFeatures.inferenceUsingBounds.isEnabled,
          dataForTesting: visitor.dataForTesting,
          internalNodeForTesting: node,
          typeOperations: visitor.cfeOperations,
        );

    if (typeContextIsIterable) {
      DartType typeArgument = inferredTypes[0];
      elementType = new IterableElementType(typeArgument);
    } else if (typeContextIsMap) {
      DartType keyType = inferredTypes[0];
      DartType valueType = inferredTypes[1];
      elementType = new MapElementType(keyType: keyType, valueType: valueType);
    } else {
      elementType = const UnknownElementTypeSchema();
    }

    return new InferredMapOrSetElementInferenceContext._(
      elementTypeContext: elementType,
      spreadContext: spreadContext,
      formalKeyType: formalKeyType,
      formalValueType: formalValueType,
      visitor: visitor,
      gatherer: gatherer,
      typeParametersToInfer: typeParametersToInfer,
      initiallyInferredTypes: inferredTypes,
      node: node,
      typeContextIsMap: typeContextIsMap,
      typeContextIsIterable: typeContextIsIterable,
    );
  }

  @override
  ElementInferenceKind determineElementKind() {
    bool hasExpression = _expressionOffset != null;
    bool hasMapEntry = _mapEntryOffset != null;
    bool hasMapSpread = _mapSpreadOffset != null;
    bool hasIterableSpread = _iterableSpreadOffset != null;
    bool canBeIterable = !hasMapSpread && !hasMapEntry && !_typeContextIsMap;
    bool canBeMap =
        !hasExpression && !hasIterableSpread && !_typeContextIsIterable;
    return new ElementInferenceKind(
      canBeMap: canBeMap,
      canBeIterable: canBeIterable,
    );
  }

  @override
  ElementType inferElementType({required bool asMap}) {
    if (asMap) {
      // We pretend that the called method has twice as many parameters as the
      // seen [_elementTypes] which alternate between the [_formalKeyType] and
      // [_formalValueType] as their parameter type. And similarly we pretend
      // that the actual argument types are alternating between the key types
      // and the value types of the [_elementTypes].
      List<DartType> formalTypes = [];
      List<DartType> actualTypes = [];
      for (ElementType elementType in _elementTypes) {
        formalTypes.add(_formalKeyType);
        actualTypes.add(elementType.keyType);
        formalTypes.add(_formalValueType);
        actualTypes.add(elementType.valueType);
      }
      _gatherer.constrainArguments(
        formalTypes,
        actualTypes,
        internalNodeForTesting: _node,
      );
    } else {
      // We pretend that the called method has as many parameters as the seen
      // [_elementTypes]. All use the [_formalKeyType] as parameter type. And
      // similarly we pretend that the actual argument types are the expression
      // types of the [_elementTypes].
      List<DartType> formalTypes = [];
      List<DartType> actualTypes = [];
      for (ElementType elementType in _elementTypes) {
        formalTypes.add(_formalKeyType);
        actualTypes.add(elementType.expressionType);
      }
      _gatherer.constrainArguments(
        formalTypes,
        actualTypes,
        internalNodeForTesting: _node,
      );
    }
    List<DartType> inferredTypes = _visitor.typeSchemaEnvironment
        .chooseFinalTypes(
          _gatherer.computeConstraints(),
          _typeParametersToInfer,
          _initiallyInferredTypes,
          inferenceUsingBoundsIsEnabled:
              _visitor.libraryFeatures.inferenceUsingBounds.isEnabled,
          dataForTesting: _visitor.dataForTesting,
          internalNodeForTesting: _node,
          typeOperations: _visitor.cfeOperations,
        );
    if (asMap) {
      DartType keyType = inferredTypes[0];
      DartType valueType = inferredTypes[1];

      if (_visitor.dataForTesting != null) {
        // Coverage-ignore-block(suite): Not run.
        _visitor
            .dataForTesting!
            .typeInferenceResult
            .inferredTypeArguments[_node] = [
          keyType,
          valueType,
        ];
      }

      if (!_visitor.libraryFeatures.genericMetadata.isEnabled) {
        _visitor.checkGenericFunctionTypeArgument(keyType, _node.fileOffset);
        _visitor.checkGenericFunctionTypeArgument(valueType, _node.fileOffset);
      }

      return new MapElementType(keyType: keyType, valueType: valueType);
    } else {
      DartType typeArgument = inferredTypes[0];

      if (_visitor.dataForTesting != null) {
        // Coverage-ignore-block(suite): Not run.
        _visitor
            .dataForTesting!
            .typeInferenceResult
            .inferredTypeArguments[_node] = [
          typeArgument,
        ];
      }

      if (!_visitor.libraryFeatures.genericMetadata.isEnabled) {
        _visitor.checkGenericFunctionTypeArgument(
          typeArgument,
          _node.fileOffset,
        );
      }

      return new IterableElementType(typeArgument);
    }
  }

  @override
  void registerElementType(ElementType elementType) {
    _elementTypes.add(elementType);
  }

  @override
  void registerMapEntry({required int fileOffset}) {
    _mapEntryOffset ??= fileOffset;
  }

  @override
  void registerIterableSpread({
    required DartType type,
    required int fileOffset,
  }) {
    _iterableSpreadOffset ??= fileOffset;
    _iterableSpreadType ??= type;
  }

  @override
  void registerMapSpread({required int fileOffset}) {
    _mapSpreadOffset ??= fileOffset;
  }

  @override
  void registerExpression({required int fileOffset}) {
    _expressionOffset ??= fileOffset;
  }
}

/// The type or type schema of an element in a list, set, or map literal.
sealed class const ElementType() {
  /// Returns the type as expression in a list or set literal.
  DartType get expressionType;

  /// Returns the key type as map entry in a map literal.
  DartType get keyType;

  /// Returns the value type as map entry in a map literal.
  DartType get valueType;

  /// Computes the standard upper bound between this element type and [other].
  ElementType getStandardUpperBound(
    TypeSchemaEnvironment typeSchemaEnvironment,
    ElementType other,
  );
}

/// The element type of an expression.
///
/// This is used for type schema when the literal is known to be a list or
/// set literal, and for the type of expressions occurring within a literal.
class IterableElementType(@override final DartType expressionType)
    extends ElementType {
  @override
  ElementType getStandardUpperBound(
    TypeSchemaEnvironment typeSchemaEnvironment,
    ElementType other,
  ) {
    switch (other) {
      case IterableElementType():
        return new IterableElementType(
          typeSchemaEnvironment.getStandardUpperBound(
            expressionType,
            other.expressionType,
          ),
        );
      case MapElementType():
        // Error case. reported elsewhere.
        return const InvalidElementType();
      case InvalidElementType():
        return other;
      case NeverElementType():
        return this;
      case DynamicElementType():
        return other;
      // Coverage-ignore(suite): Not run.
      case UnknownElementTypeSchema():
        throw new UnsupportedError('Unexpected element type $other');
    }
  }

  @override
  DartType get keyType => const InvalidType();

  @override
  DartType get valueType => const InvalidType();
}

/// The element type of an map entry.
///
/// This is used for type schema when the literal is known to be a map literal,
/// and for the type of map entries occurring within a literal.
class MapElementType({
  @override required final DartType keyType,
  @override required final DartType valueType,
}) extends ElementType {
  @override
  ElementType getStandardUpperBound(
    TypeSchemaEnvironment typeSchemaEnvironment,
    ElementType other,
  ) {
    switch (other) {
      case MapElementType():
        return new MapElementType(
          keyType: typeSchemaEnvironment.getStandardUpperBound(
            keyType,
            other.keyType,
          ),
          valueType: typeSchemaEnvironment.getStandardUpperBound(
            valueType,
            other.valueType,
          ),
        );
      case IterableElementType():
        // Error case. reported elsewhere.
        return const InvalidElementType();
      case InvalidElementType():
        return other;
      case NeverElementType():
        return this;
      case DynamicElementType():
        return other;
      // Coverage-ignore(suite): Not run.
      case UnknownElementTypeSchema():
        throw new UnsupportedError('Unexpected element type $other');
    }
  }

  @override
  DartType get expressionType => const InvalidType();
}

/// The element type for an invalid element.
class const InvalidElementType() extends ElementType {
  @override
  DartType get expressionType => const InvalidType();

  @override
  // Coverage-ignore(suite): Not run.
  ElementType getStandardUpperBound(
    TypeSchemaEnvironment typeSchemaEnvironment,
    ElementType other,
  ) {
    return this;
  }

  @override
  DartType get keyType => const InvalidType();

  @override
  DartType get valueType => const InvalidType();
}

/// The element type for an element of type `Never`.
class const NeverElementType() extends ElementType {
  @override
  DartType get expressionType => const NeverType.nonNullable();

  @override
  // Coverage-ignore(suite): Not run.
  ElementType getStandardUpperBound(
    TypeSchemaEnvironment typeSchemaEnvironment,
    ElementType other,
  ) {
    return this;
  }

  @override
  DartType get keyType => const NeverType.nonNullable();

  @override
  DartType get valueType => const NeverType.nonNullable();
}

/// The element type for an element of type `dynamic`.
class const DynamicElementType() extends ElementType {
  @override
  DartType get expressionType => const DynamicType();

  @override
  ElementType getStandardUpperBound(
    TypeSchemaEnvironment typeSchemaEnvironment,
    ElementType other,
  ) {
    switch (other) {
      case IterableElementType():
      case MapElementType():
      case DynamicElementType():
        return this;
      // Coverage-ignore(suite): Not run.
      case NeverElementType():
      case InvalidElementType():
        return other;
      // Coverage-ignore(suite): Not run.
      case UnknownElementTypeSchema():
        throw new UnsupportedError('Unexpected element type $other');
    }
  }

  @override
  DartType get keyType => const DynamicType();

  @override
  DartType get valueType => const DynamicType();
}

/// The element type for the type context of an ambiguous map/set literal.
class const UnknownElementTypeSchema() extends ElementType {
  @override
  DartType get expressionType => const UnknownType();

  @override
  ElementType getStandardUpperBound(
    TypeSchemaEnvironment typeSchemaEnvironment,
    ElementType other,
  ) {
    throw new UnsupportedError('Unexpected element type $this');
  }

  @override
  DartType get keyType => const UnknownType();

  @override
  DartType get valueType => const UnknownType();
}

/// Context type information used for inferring spread elements in a literal.
sealed class const SpreadContext() {
  /// Returns the type context used for inference of a spread element.
  DartType getSpreadTypeContext(CoreTypes coreTypes);
}

/// Spread context for when the literal is an ambiguous map/set literal.
class const UnknownSpreadContext() extends SpreadContext {
  @override
  DartType getSpreadTypeContext(CoreTypes coreTypes) => const UnknownType();
}

/// Spread context for when the literal is known to be a list or set literal.
class const IterableSpreadContext({required final DartType typeArgument})
    extends SpreadContext {
  @override
  DartType getSpreadTypeContext(CoreTypes coreTypes) => new InterfaceType(
    coreTypes.iterableClass,
    Nullability.nonNullable,
    [typeArgument],
  );
}

/// Spread context for when the literal is known to be a map literal.
class const MapSpreadContext({
  required final DartType keyType,
  required final DartType valueType,
}) extends SpreadContext {
  @override
  DartType getSpreadTypeContext(CoreTypes coreTypes) => new InterfaceType(
    coreTypes.mapClass,
    Nullability.nonNullable,
    [keyType, valueType],
  );
}
