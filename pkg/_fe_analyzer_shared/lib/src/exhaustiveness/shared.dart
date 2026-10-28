// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'exhaustive.dart';
import 'key.dart';
import 'path.dart';
import 'space.dart';
import 'shape.dart';
import 'types.dart';

/// Interface implemented by analyze/CFE to support type operations need for the
/// shared [Shape]s.
abstract class TypeOperations<Type extends Object> {
  /// Returns the type for `Object?`.
  Type get nullableObjectType;

  /// Returns the type for the non-nullable `Object`.
  Type get nonNullableObjectType;

  /// Returns `true` if [s] is a subtype of [t].
  bool isSubtypeOf(Type s, Type t);

  /// Returns a type that overapproximates the possible values of [type] by
  /// replacing all type variables with the default types.
  Type overapproximate(Type type);

  /// Returns `true` if [type] is a nullable type.
  bool isNullable(Type type);

  /// Returns `true` if [type] is a potentially nullable type.
  bool isPotentiallyNullable(Type type);

  /// Returns the non-nullable type corresponding to [type]. For instance
  /// `Foo` for `Foo?`. If [type] is already non-nullable, it itself is
  /// returned.
  Type getNonNullable(Type type);

  /// Returns `true` if [type] is the `Null` type.
  bool isNullType(Type type);

  /// Returns `true` if [type] is the `Never` type.
  bool isNeverType(Type type);

  /// Returns `true` if [type] is the `Object?` type.
  bool isNullableObject(Type type);

  /// Returns `true` if [type] is the `Object` type.
  bool isNonNullableObject(Type type);

  /// Returns `true` if [type] is the `dynamic` type.
  bool isDynamic(Type type);

  /// Returns `true` if [type] is the `bool` type.
  bool isBoolType(Type type);

  /// Returns the `bool` type.
  Type get boolType;

  /// Returns `true` if [type] is a record type.
  bool isRecordType(Type type);

  /// Returns `true` if [type] is a generic interface type.
  bool isGeneric(Type type);

  /// Returns the type `T` if [type] is `FutureOr<T>`. Returns `null` otherwise.
  Type? getFutureOrTypeArgument(Type type);

  /// Returns the non-nullable type `Future<T>` for [type] `T`.
  Type instantiateFuture(Type type);

  /// Returns a map of the property names and corresponding types available on
  /// [type]. For an interface type, these are the fields and getters, and for
  /// record types these are the record fields.
  Map<Key, Type> getPropertyTypes(Type type);

  /// Returns the value type `V` if [type] implements `Map<K, V>` or `null`
  /// otherwise.
  Type? getMapValueType(Type type);

  /// Returns the element type `E` if [type] implements `List<E>` or `null`
  /// otherwise.
  Type? getListElementType(Type type);

  /// Returns the list type `List<E>` if [type] implements `List<E>` or `null`
  /// otherwise.
  Type? getListType(Type type);

  /// Returns the extension type erasure of [type].
  ///
  /// This is [type] in which all occurrences of extension types have been
  /// replaced with their representation type.
  Type getExtensionTypeErasure(Type type);

  /// Returns a human-readable representation of the [type].
  String typeToString(Type type);

  /// Returns `true` if [type] has a simple name that can be used as the type
  /// of an object pattern.
  bool hasSimpleName(Type type);

  /// Returns the bound of [type] if is a type variable or a promoted type
  /// variable. Otherwise returns `null`.
  Type? getTypeVariableBound(Type type);

  /// Returns `true` if [type] is an enum type.
  bool isEnum(Type type);

  /// Returns the library URI for [type].
  Uri? libraryUri(Type type);
}

/// Interface for looking up properties and their corresponding [Shape]s of
/// a given type.
abstract class PropertyLookup<Type extends Object> {
  /// Returns a map of the property names and corresponding [Shape]s available
  /// on [type]. For an interface type, these are the fields and getters, and
  /// for record types these are the record fields.
  Map<Key, Shape> getPropertyShapes(Type type);

  Shape? getAdditionalPropertyShape(Type type, Key key);
}

/// Cache used for computing [Shape]s used for exhaustiveness checking.
///
/// This implementation is shared between analyzer and CFE, and implemented
/// using the analyzer/CFE implementations of [TypeOperations],
/// [EnumOperations], and [SealedClassOperations].
class ExhaustivenessCache<
  Type extends Object,
  Class extends Object,
  EnumClass extends Object,
  EnumElement extends Object,
  EnumElementValue extends Object
>
    implements PropertyLookup<Type>, ObjectPropertyLookup {
  final TypeOperations<Type> typeOperations;
  final EnumOperations<Type, EnumClass, EnumElement, EnumElementValue>
  enumOperations;
  final SealedClassOperations<Type, Class> _sealedClassOperations;

  /// Cache for [EnumInfo] for enum classes.
  Map<EnumClass, EnumInfo<Type, EnumClass, EnumElement, EnumElementValue>>
  _enumInfo = {};

  /// Cache for [SealedClassInfo] for sealed classes.
  Map<Class, SealedClassInfo<Type, Class>> _sealedClassInfo = {};

  /// Cache for unique [Shape]s.
  Map<Object, Shape> _uniqueShapeMap = {};

  /// Cache for the [Shape] for `bool`.
  late BoolShape _boolShape = new BoolShape(
    typeOperations,
    this,
    typeOperations.boolType,
  );

  /// Cache for [Shape]s for properties available on a [Type].
  Map<Type, Map<Key, Shape>> _propertyCache = {};

  new(this.typeOperations, this.enumOperations, this._sealedClassOperations);

  /// Returns the [EnumInfo] for [enumClass].
  EnumInfo<Type, EnumClass, EnumElement, EnumElementValue> _getEnumInfo(
    EnumClass enumClass,
  ) {
    return _enumInfo[enumClass] ??= new EnumInfo(
      typeOperations,
      this,
      enumOperations,
      enumClass,
    );
  }

  /// Returns the [SealedClassInfo] for [sealedClass].
  SealedClassInfo<Type, Class> _getSealedClassInfo(Class sealedClass) {
    return _sealedClassInfo[sealedClass] ??= new SealedClassInfo(
      _sealedClassOperations,
      sealedClass,
    );
  }

  /// Returns the [Shape] for the boolean [value].
  Shape getBoolValueShape(bool value) {
    return value ? _boolShape.trueShape : _boolShape.falseShape;
  }

  /// Returns the [Shape] for [type].
  Shape getShapeForType(Type type) {
    type = typeOperations.getExtensionTypeErasure(type);
    if (typeOperations.isNeverType(type)) {
      return Shape.neverShape;
    } else if (typeOperations.isNullType(type)) {
      return Shape.nullShape;
    } else if (typeOperations.isNonNullableObject(type)) {
      return Shape.nonNullableObject;
    } else if (typeOperations.isNullableObject(type) ||
        typeOperations.isDynamic(type)) {
      return Shape.nullableObject;
    }

    Shape shape;
    bool extractNull = typeOperations.isNullable(type);
    Type typeWithoutNull = type;
    if (extractNull) {
      // If [type] is nullable, we model the static type by creating the
      // non-nullable equivalent and then add `Null` afterwards.
      //
      // For instance we model `int?` as `int|Null`.
      typeWithoutNull = typeOperations.getNonNullable(type);
    }
    if (typeOperations.isBoolType(typeWithoutNull)) {
      shape = _boolShape;
    } else if (typeOperations.isRecordType(typeWithoutNull)) {
      shape = new RecordShape(typeOperations, this, typeWithoutNull);
    } else {
      Type? futureOrTypeArgument = typeOperations.getFutureOrTypeArgument(
        typeWithoutNull,
      );
      if (futureOrTypeArgument != null) {
        Shape typeArgument = getShapeForType(futureOrTypeArgument);
        Shape futureType = getShapeForType(
          typeOperations.instantiateFuture(futureOrTypeArgument),
        );
        bool isImplicitlyNullable = typeOperations.isNullable(
          futureOrTypeArgument,
        );
        shape = new FutureOrShape(
          typeOperations,
          this,
          typeWithoutNull,
          typeArgument,
          futureType,
          isImplicitlyNullable: isImplicitlyNullable,
        );
      } else {
        EnumClass? enumClass = enumOperations.getEnumClass(typeWithoutNull);
        if (enumClass != null) {
          shape = new EnumShape(
            typeOperations,
            this,
            typeWithoutNull,
            _getEnumInfo(enumClass),
          );
        } else {
          Class? sealedClass = _sealedClassOperations.getSealedClass(
            typeWithoutNull,
          );
          if (sealedClass != null) {
            shape = new SealedClassShape(
              typeOperations,
              this,
              typeWithoutNull,
              this,
              _sealedClassOperations,
              _getSealedClassInfo(sealedClass),
            );
          } else {
            Type? listType = typeOperations.getListType(typeWithoutNull);
            if (listType != null) {
              shape = new ListShape(typeOperations, this, typeWithoutNull);
            } else {
              bool isImplicitlyNullable = typeOperations.isNullable(
                typeWithoutNull,
              );
              shape = new TypeBasedShape(
                typeOperations,
                this,
                typeWithoutNull,
                isImplicitlyNullable: isImplicitlyNullable,
              );
              Type? bound = typeOperations.getTypeVariableBound(type);
              if (bound != null) {
                shape = new WrappedShape(getShapeForType(bound), shape);
              }
            }
          }
        }
      }
    }
    if (extractNull) {
      // Include the `Null` which was extracted from [type] into
      // [typeWithoutNull].
      shape = shape.nullable;
    }
    return shape;
  }

  /// Returns the [Shape] for the [enumElementValue] declared by
  /// [enumClass].
  Shape getEnumElementShape(
    EnumClass enumClass,
    EnumElementValue enumElementValue,
  ) {
    return _getEnumInfo(enumClass).getEnumElement(enumElementValue);
  }

  /// Creates a new unique [Shape].
  Shape getUnknownShape() {
    // The unknown shape should not be based on the nullable `Object`, since
    // even though it _might_ be `null`, using the nullable `Object` here would
    // mean that it _does_ include `null`, and we need this shape to only cover
    // itself.
    return getUniqueShape<Object>(
      typeOperations.nonNullableObjectType,
      new Object(),
      '?',
    );
  }

  /// Returns a [Shape] of the given [type] with the given
  /// [textualRepresentation] that unique identifies the [uniqueValue].
  ///
  /// This is used for constants that are neither bool nor enum values.
  Shape getUniqueShape<Identity extends Object>(
    Type type,
    Identity uniqueValue,
    String textualRepresentation,
  ) {
    Type nonNullable = typeOperations.getNonNullable(type);
    Shape shape = _uniqueShapeMap[uniqueValue] ??=
        new GeneralValueShape<Type, Identity>(
          typeOperations,
          this,
          nonNullable,
          new IdentityRestriction<Identity>(uniqueValue),
          textualRepresentation,
          uniqueValue,
        );
    if (typeOperations.isNullable(type)) {
      shape = shape.nullable;
    }
    return shape;
  }

  /// Returns a [Shape] of the list [type] with the given [restriction] .
  Shape getListShape(Type type, ListShapeRestriction<Type> restriction) {
    Type nonNullable = typeOperations.getNonNullable(type);
    Shape shape = new ListPatternShape(
      typeOperations,
      this,
      nonNullable,
      restriction,
      restriction.toString(),
    );
    if (typeOperations.isNullable(type)) {
      shape = shape.nullable;
    }
    return shape;
  }

  /// Returns a [Shape] of the map [type] with the given [restriction] .
  Shape getMapShape(Type type, MapShapeRestriction<Type> restriction) {
    Type nonNullable = typeOperations.getNonNullable(type);
    Shape shape = new MapPatternShape(
      typeOperations,
      this,
      nonNullable,
      restriction,
      restriction.toString(),
    );
    if (typeOperations.isNullable(type)) {
      shape = shape.nullable;
    }
    return shape;
  }

  @override
  Map<Key, Shape> getPropertyShapes(Type type) {
    Map<Key, Shape>? properties = _propertyCache[type];
    if (properties == null) {
      _propertyCache[type] = properties = {};
      for (MapEntry<Key, Type> entry
          in typeOperations.getPropertyTypes(type).entries) {
        properties[entry.key] = getShapeForType(entry.value);
      }
    }
    return properties;
  }

  @override
  Shape? getAdditionalPropertyShape(Type type, Key key) {
    if (key is MapKey) {
      Type? valueType = typeOperations.getMapValueType(type);
      if (valueType != null) {
        return getShapeForType(valueType);
      }
    } else if (key is HeadKey || key is TailKey) {
      Type? elementType = typeOperations.getListElementType(type);
      if (elementType != null) {
        return getShapeForType(elementType);
      }
    } else if (key is RestKey) {
      Type? listType = typeOperations.getListType(type);
      if (listType != null) {
        return getShapeForType(listType);
      }
    } else {
      return getObjectPropertyShape(key);
    }
    return null;
  }

  @override
  Shape? getObjectPropertyShape(Key key) {
    return getPropertyShapes(typeOperations.nonNullableObjectType)[key];
  }
}

/// Mixin for creating [Space]s from [Pattern]s.
mixin SpaceCreator<Pattern extends Object, Type extends Object> {
  TypeOperations<Type> get typeOperations;

  ObjectPropertyLookup get objectPropertyLookup;

  /// Returns `true` if the current library has version greater than or equal
  /// to `$major.$minor`.
  bool hasLanguageVersion(int major, int minor);

  /// Creates a [Shape] for an unknown type.
  ///
  /// This is used when the type of the pattern is unknown or can't be
  /// represented as a [Shape]. This shape is unique and ensures that it
  /// neither matches anything nor is matched by anything.
  Shape createUnknownShape();

  /// Creates the [Shape] for [type].
  Shape createShapeForType(Type type);

  /// Creates the [Shape] for [type] restricted by the [contextShape].
  /// If [nonNull] is `true`, the created shape is non-nullable.
  Shape _createShapeForTypeWithContext(
    Shape contextShape,
    Type type, {
    required bool nonNull,
  }) {
    Shape shape = createShapeForType(type);
    if (contextShape.isSubshapeOf(shape)) {
      shape = contextShape;
    }
    if (nonNull) {
      shape = shape.nonNullable;
    }
    return shape;
  }

  /// Creates the [Shape] for the list [type] with the given [restriction].
  Shape createListShape(Type type, ListShapeRestriction<Type> restriction);

  /// Creates the [Shape] for the map [type] with the given [restriction].
  Shape createMapShape(Type type, MapShapeRestriction<Type> restriction);

  /// Creates the [Space] for [pattern] at the given [path].
  ///
  /// The [contextShape] is the [Shape] in which the pattern match is
  /// performed. This is used to restrict the shape of the created [Space] to
  /// the shapes allowed by the context. For instance `Object(:var hashCode)`
  /// is in itself unrestricted and would yield the top space for matching
  /// `var hashCode`. Using the [contextShape] `int`, as given by the type of
  /// the `Object.hashCode`, the created space is all `int` values rather than
  /// all values.
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space dispatchPattern(
    Path path,
    Shape contextShape,
    Pattern pattern, {
    required bool nonNull,
  });

  /// Creates the root space for [pattern].
  Space createRootSpace(Shape contextShape, Pattern pattern) {
    return dispatchPattern(
      const Path.root(),
      contextShape,
      pattern,
      nonNull: false,
    );
  }

  /// Creates the [Space] at [path] for a variable pattern of the declared
  /// [type].
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space createVariableSpace(
    Path path,
    Shape contextShape,
    Type type, {
    required bool nonNull,
  }) {
    Shape shape = _createShapeForTypeWithContext(
      contextShape,
      type,
      nonNull: nonNull,
    );
    return new Space(path, shape);
  }

  /// Creates the [Space] at [path] for an object pattern of the required [type]
  /// and [fieldPatterns].
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space createObjectSpace(
    Path path,
    Shape contextShape,
    Type type,
    Map<String, Pattern> fieldPatterns,
    Map<String, Type> extensionPropertyTypes, {
    required bool nonNull,
  }) {
    Shape shape = _createShapeForTypeWithContext(
      contextShape,
      type,
      nonNull: nonNull,
    );
    Map<Key, Space> properties = <Key, Space>{};
    for (MapEntry<String, Pattern> entry in fieldPatterns.entries) {
      String name = entry.key;
      Shape propertyShape;
      Type? extensionPropertyType = extensionPropertyTypes[name];
      Key key;
      if (extensionPropertyType != null) {
        propertyShape = createShapeForType(extensionPropertyType);
        key = new ExtensionKey(createShapeForType(type), name, propertyShape);
      } else {
        key = new NameKey(name);
        propertyShape =
            shape.getPropertyShape(objectPropertyLookup, key) ??
            Shape.nullableObject;
      }
      properties[key] = dispatchPattern(
        path.add(key),
        propertyShape,
        entry.value,
        nonNull: false,
      );
    }
    return new Space(path, shape, properties: properties);
  }

  /// Creates the [Space] at [path] for a record pattern of the required
  /// [recordType], [positionalFields], and [namedFields].
  Space createRecordSpace(
    Path path,
    Shape contextShape,
    Type recordType,
    List<Pattern> positionalFields,
    Map<String, Pattern> namedFields,
  ) {
    Shape shape = _createShapeForTypeWithContext(
      contextShape,
      recordType,
      nonNull: true,
    );
    Map<Key, Space> properties = <Key, Space>{};
    for (int index = 0; index < positionalFields.length; index++) {
      Key key = new RecordIndexKey(index);
      Shape propertyShape =
          shape.getPropertyShape(objectPropertyLookup, key) ??
          Shape.nullableObject;
      properties[key] = dispatchPattern(
        path.add(key),
        propertyShape,
        positionalFields[index],
        nonNull: false,
      );
    }
    for (MapEntry<String, Pattern> entry in namedFields.entries) {
      Key key = new RecordNameKey(entry.key);
      Shape propertyShape =
          shape.getPropertyShape(objectPropertyLookup, key) ??
          Shape.nullableObject;
      properties[key] = dispatchPattern(
        path.add(key),
        propertyShape,
        entry.value,
        nonNull: false,
      );
    }
    return new Space(path, shape, properties: properties);
  }

  /// Creates the [Space] at [path] for a wildcard pattern with the declared
  /// [type].
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space createWildcardSpace(
    Path path,
    Shape contextShape,
    Type? type, {
    required bool nonNull,
  }) {
    if (type == null) {
      Shape shape = contextShape;
      if (nonNull) {
        shape = shape.nonNullable;
      }
      return new Space(path, shape);
    } else {
      Shape shape = _createShapeForTypeWithContext(
        contextShape,
        type,
        nonNull: nonNull,
      );
      return new Space(path, shape);
    }
  }

  /// Creates the [Space] at [path] for a relational pattern.
  Space createRelationalSpace(Path path) {
    // This pattern do not add to the exhaustiveness coverage.
    return createUnknownSpace(path);
  }

  /// Returns `true` if [singleSpace] does not restrict the spaces of any of its
  /// properties. For instance the pattern `Object(:int hashCode)` is
  /// unrestricted but the pattern `Object(hashCode: 5)` is restricted.
  bool _isUnrestricted(SingleSpace singleSpace) {
    if (singleSpace.properties.isNotEmpty) {
      Map<Key, Shape> propertyShapes = singleSpace.shape.properties;
      for (MapEntry<Key, Space> entry in singleSpace.properties.entries) {
        Key key = entry.key;
        Shape propertyShape = propertyShapes[key] ?? Shape.neverShape;
        if (!_isContainedIn(propertyShape, entry.value)) {
          return false;
        }
      }
    }
    if (singleSpace.additionalProperties.isNotEmpty) {
      for (MapEntry<Key, Space> entry
          in singleSpace.additionalProperties.entries) {
        Key key = entry.key;
        Shape propertyShape =
            singleSpace.shape.getAdditionalPropertyShape(key) ??
            Shape.neverShape;
        if (!_isContainedIn(propertyShape, entry.value)) {
          return false;
        }
      }
    }
    return true;
  }

  /// Returns `true` if the space implied by [shape], i.e. all values of
  /// [shape] regardless of properties, is contained in [space].
  bool _isContainedIn(Shape shape, Space space) {
    Map<SingleSpace, bool> unrestrictedCache = {};
    if (space.singleSpaces.length == 1) {
      // Optimize for simple spaces to avoid unnecessary expansion of subshapes.
      SingleSpace singleSpace = space.singleSpaces.single;
      bool isUnrestricted = unrestrictedCache[singleSpace] ??= _isUnrestricted(
        singleSpace,
      );
      if (isUnrestricted && shape.isSubshapeOf(singleSpace.shape)) {
        return true;
      }
    }
    // To handle case like:
    //
    //    sealed class M {}
    //    class A extends M {}
    //    class B extends M {}
    //    method(o) => switch (o) {
    //        (A() || B()) as M => 0,
    //      };
    //
    // we expand [shape] into subshapes before determining for containment.
    List<Shape> subshapes = expandSealedSubshapes(shape, const {});
    for (Shape subshape in subshapes) {
      bool found = false;
      for (SingleSpace singleSpace in space.singleSpaces) {
        bool isUnrestricted = unrestrictedCache[singleSpace] ??=
            _isUnrestricted(singleSpace);
        if (isUnrestricted && subshape.isSubshapeOf(singleSpace.shape)) {
          found = true;
          break;
        }
      }
      if (!found) {
        return false;
      }
    }
    return true;
  }

  /// Creates the [Space] at [path] for a cast pattern with the given
  /// [subPattern].
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space createCastSpace(
    Path path,
    Shape contextShape,
    Type type,
    Pattern subPattern, {
    required bool nonNull,
  }) {
    Space space = dispatchPattern(
      path,
      contextShape,
      subPattern,
      nonNull: nonNull,
    );
    Shape castShape = createShapeForType(type);
    if (hasLanguageVersion(3, 3)) {
      if (_isContainedIn(castShape, space)) {
        // If all values in [castShape] are also in [space] then the complete
        // [contextShape] is matched. For instance
        //
        //    method(var d) => switch (d) {
        //        final String value => value,
        //        // This covers everything either by matching as int or by
        //        // throwing.
        //        final value as int => value,
        //      };
        space = new Space(path, contextShape);
      }
      if (!typeOperations.isPotentiallyNullable(type)) {
        // If `null` is _not_ included in [castShape], we can include in the
        // generated [space].
        space = space.union(new Space(path, Shape.nullShape));
      }
    } else {
      // The following check assumes that the subpattern space is
      // unrestrictive.
      if (castShape.isSubshapeOf(contextShape) && contextShape.isSealed) {
        for (Shape subshape in expandSealedSubshapes(contextShape, const {})) {
          // If [subshape] is a subshape of [castShape] it will not throw and
          // must be handled by [subPattern]. For instance
          //
          //    sealed class S {}
          //    sealed class X extends S {}
          //    class A extends X {}
          //    method(S s) => switch (s) {
          //      A() as X => 0,
          //    }
          //
          // If [castShape] is a subshape of [subshape] it might not throw but
          // still not handle all values of the [subshape].
          //
          //    sealed class S {}
          //    class A extends S {}
          //    class X extends A {
          //      int field;
          //      X(this.field);
          //    }
          //    method(S s) => switch (s) {
          //      X(field: 42) as X => 0,
          //    }
          //
          if (!castShape.isSubshapeOf(subshape) &&
              !subshape.isSubshapeOf(castShape)) {
            // Otherwise the cast implicitly handles [subshape].
            space = space.union(new Space(path, subshape));
          }
        }
      }
    }
    return space;
  }

  /// Creates the [Space] at [path] for a null check pattern with the given
  /// [subPattern].
  Space createNullCheckSpace(
    Path path,
    Shape contextShape,
    Pattern subPattern,
  ) {
    return dispatchPattern(path, contextShape, subPattern, nonNull: true);
  }

  /// Creates the [Space] at [path] for a null assert pattern with the given
  /// [subPattern].
  Space createNullAssertSpace(
    Path path,
    Shape contextShape,
    Pattern subPattern,
  ) {
    Space space = dispatchPattern(
      path,
      contextShape,
      subPattern,
      nonNull: true,
    );
    return space.union(new Space(path, Shape.nullShape));
  }

  /// Creates the [Space] at [path] for a logical or pattern with the given
  /// [left] and [right] subpatterns.
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space createLogicalOrSpace(
    Path path,
    Shape contextShape,
    Pattern left,
    Pattern right, {
    required bool nonNull,
  }) {
    Space aSpace = dispatchPattern(path, contextShape, left, nonNull: nonNull);
    Space bSpace = dispatchPattern(path, contextShape, right, nonNull: nonNull);
    return aSpace.union(bSpace);
  }

  /// Creates the [Space] at [path] for a logical and pattern with the given
  /// [left] and [right] subpatterns.
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space createLogicalAndSpace(
    Path path,
    Shape contextShape,
    Pattern left,
    Pattern right, {
    required bool nonNull,
  }) {
    Space aSpace = dispatchPattern(path, contextShape, left, nonNull: nonNull);
    Space bSpace = dispatchPattern(path, contextShape, right, nonNull: nonNull);
    return _createSpaceIntersection(path, aSpace, bSpace);
  }

  /// Creates the [Space] at [path] for a list pattern.
  Space createListSpace(
    Path path, {
    required Type type,
    required Type elementType,
    required List<Pattern> headElements,
    required Pattern? restElement,
    required List<Pattern> tailElements,
    required bool hasRest,
    required bool hasExplicitTypeArgument,
  }) {
    int headSize = headElements.length;
    int tailSize = tailElements.length;

    String typeArgumentText;
    if (hasExplicitTypeArgument) {
      StringBuffer sb = new StringBuffer();
      sb.write('<');
      sb.write(typeOperations.typeToString(elementType));
      sb.write('>');
      typeArgumentText = sb.toString();
    } else {
      typeArgumentText = '';
    }

    ListShapeRestriction<Type> identity = new ListShapeRestriction(
      elementType,
      typeArgumentText,
      size: headSize + tailSize,
      hasRest: hasRest,
    );

    Shape shape = createListShape(type, identity);

    Map<Key, Space> additionalProperties = {};
    for (int index = 0; index < headSize; index++) {
      Key key = new HeadKey(index);
      Shape propertyShape =
          shape.getAdditionalPropertyShape(key) ?? Shape.nullableObject;
      additionalProperties[key] = dispatchPattern(
        path.add(key),
        propertyShape,
        headElements[index],
        nonNull: false,
      );
    }
    if (hasRest) {
      Key key = new RestKey(headSize, tailSize);
      Shape propertyShape =
          shape.getAdditionalPropertyShape(key) ?? Shape.nullableObject;
      if (restElement != null) {
        additionalProperties[key] = dispatchPattern(
          path.add(key),
          propertyShape,
          restElement,
          nonNull: false,
        );
      } else {
        additionalProperties[key] = new Space(path.add(key), propertyShape);
      }
    }
    for (int index = 0; index < tailSize; index++) {
      Key key = new TailKey(index);
      Shape propertyShape =
          shape.getAdditionalPropertyShape(key) ?? Shape.nullableObject;
      additionalProperties[key] = dispatchPattern(
        path.add(key),
        propertyShape,
        tailElements[tailElements.length - index - 1],
        nonNull: false,
      );
    }
    return new Space(path, shape, additionalProperties: additionalProperties);
  }

  /// Creates the [Space] at [path] for a map pattern.
  Space createMapSpace(
    Path path, {
    required Type type,
    required Type keyType,
    required Type valueType,
    required Map<MapKey, Pattern> entries,
    required bool hasExplicitTypeArguments,
  }) {
    String typeArgumentsText;
    if (hasExplicitTypeArguments) {
      StringBuffer sb = new StringBuffer();
      sb.write('<');
      sb.write(typeOperations.typeToString(keyType));
      sb.write(', ');
      sb.write(typeOperations.typeToString(valueType));
      sb.write('>');
      typeArgumentsText = sb.toString();
    } else {
      typeArgumentsText = '';
    }

    MapShapeRestriction<Type> identity = new MapShapeRestriction(
      keyType,
      valueType,
      entries.keys.toSet(),
      typeArgumentsText,
    );
    Shape shape = createMapShape(type, identity);

    Map<Key, Space> additionalProperties = {};
    for (MapEntry<Key, Pattern> entry in entries.entries) {
      Key key = entry.key;
      Shape propertyShape =
          shape.getAdditionalPropertyShape(key) ?? Shape.nullableObject;
      additionalProperties[key] = dispatchPattern(
        path.add(key),
        propertyShape,
        entry.value,
        nonNull: false,
      );
    }
    return new Space(path, shape, additionalProperties: additionalProperties);
  }

  /// Creates the [Space] at [path] for a pattern with unknown space.
  ///
  /// This is used when the space of the pattern is unknown or can't be
  /// represented precisely as a union of [SingleSpace]s. This space is unique
  /// and ensures that it neither matches anything nor is matched by anything.
  Space createUnknownSpace(Path path) {
    return new Space(path, createUnknownShape());
  }

  /// Creates an approximation of the intersection of the single spaces [a] and
  /// [b].
  SingleSpace? _createSingleSpaceIntersection(
    Path path,
    SingleSpace a,
    SingleSpace b,
  ) {
    Shape? shape;
    if (a.shape.isSubshapeOf(b.shape)) {
      shape = a.shape;
    } else if (b.shape.isSubshapeOf(a.shape)) {
      shape = b.shape;
    }
    if (shape == null) {
      return null;
    }
    Map<Key, Space> properties = {};
    for (MapEntry<Key, Space> entry in a.properties.entries) {
      Key key = entry.key;
      Space aSpace = entry.value;
      Space? bSpace = b.properties[key];
      if (bSpace != null) {
        properties[key] = _createSpaceIntersection(
          path.add(key),
          aSpace,
          bSpace,
        );
      } else {
        properties[key] = aSpace;
      }
    }
    for (MapEntry<Key, Space> entry in b.properties.entries) {
      Key key = entry.key;
      properties[key] ??= entry.value;
    }
    return new SingleSpace(shape, properties: properties);
  }

  /// Creates an approximation of the intersection of spaces [a] and [b].
  Space _createSpaceIntersection(Path path, Space a, Space b) {
    assert(
      path == a.path,
      "Unexpected path. Expected $path, actual ${a.path}.",
    );
    assert(
      path == b.path,
      "Unexpected path. Expected $path, actual ${b.path}.",
    );
    List<SingleSpace> singleSpaces = [];
    bool hasUnknownSpace = false;
    for (SingleSpace aSingleSpace in a.singleSpaces) {
      for (SingleSpace bSingleSpace in b.singleSpaces) {
        SingleSpace? space = _createSingleSpaceIntersection(
          path,
          aSingleSpace,
          bSingleSpace,
        );
        if (space != null) {
          singleSpaces.add(space);
        } else {
          hasUnknownSpace = true;
        }
      }
    }
    if (hasUnknownSpace) {
      singleSpaces.add(new SingleSpace(createUnknownShape()));
    }
    return new Space.fromSingleSpaces(path, singleSpaces);
  }
}
