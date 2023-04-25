// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'exhaustive.dart';
import 'key.dart';
import 'path.dart';
import 'space.dart';
import 'static_type.dart';
import 'types.dart';

/// Interface implemented by analyze/CFE to support type operations need for the
/// shared [StaticType]s.
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

  /// Returns `true` if [type] is a potentially nullable type.
  bool isNullable(Type type);

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

  /// Returns a map of the field names and corresponding types available on
  /// [type]. For an interface type, these are the fields and getters, and for
  /// record types these are the record fields.
  Map<Key, Type> getFieldTypes(Type type);

  /// Returns the value type `V` if [type] implements `Map<K, V>` or `null`
  /// otherwise.
  Type? getMapValueType(Type type);

  /// Returns the element type `E` if [type] implements `List<E>` or `null`
  /// otherwise.
  Type? getListElementType(Type type);

  /// Returns the list type `List<E>` if [type] implements `List<E>` or `null`
  /// otherwise.
  Type? getListType(Type type);

  /// Returns a human-readable representation of the [type].
  String typeToString(Type type);

  /// Returns `true` if [type] has a simple name that can be used as the type
  /// of an object pattern.
  bool hasSimpleName(Type type);

  /// Returns the bound of [type] if is a type variable or a promoted type
  /// variable. Otherwise returns `null`.
  Type? getTypeVariableBound(Type type);
}

/// Interface for looking up fields and their corresponding [StaticType]s of
/// a given type.
abstract class FieldLookup<Type extends Object> {
  /// Returns a map of the field names and corresponding [StaticType]s available
  /// on [type]. For an interface type, these are the fields and getters, and
  /// for record types these are the record fields.
  Map<Key, StaticType> getFieldTypes(Type type);

  StaticType? getAdditionalFieldType(Type type, Key key);
}

/// Cache used for computing [StaticType]s used for exhaustiveness checking.
///
/// This implementation is shared between analyzer and CFE, and implemented
/// using the analyzer/CFE implementations of [TypeOperations],
/// [EnumOperations], and [SealedClassOperations].
class ExhaustivenessCache<
        Type extends Object,
        Class extends Object,
        EnumClass extends Object,
        EnumElement extends Object,
        EnumElementValue extends Object>
    implements FieldLookup<Type>, ObjectPropertyLookup {
  final TypeOperations<Type> typeOperations;
  final EnumOperations<Type, EnumClass, EnumElement, EnumElementValue>
      enumOperations;
  final SealedClassOperations<Type, Class> _sealedClassOperations;

  /// Cache for [EnumInfo] for enum classes.
  Map<EnumClass, EnumInfo<Type, EnumClass, EnumElement, EnumElementValue>>
      _enumInfo = {};

  /// Cache for [SealedClassInfo] for sealed classes.
  Map<Class, SealedClassInfo<Type, Class>> _sealedClassInfo = {};

  /// Cache for [UniqueStaticType]s.
  Map<Object, StaticType> _uniqueTypeMap = {};

  /// Cache for the [StaticType] for `bool`.
  late BoolStaticType _boolStaticType =
      new BoolStaticType(typeOperations, this, typeOperations.boolType);

  /// Cache for [StaticType]s for fields available on a [Type].
  Map<Type, Map<Key, StaticType>> _fieldCache = {};

  ExhaustivenessCache(
      this.typeOperations, this.enumOperations, this._sealedClassOperations);

  /// Returns the [EnumInfo] for [enumClass].
  EnumInfo<Type, EnumClass, EnumElement, EnumElementValue> _getEnumInfo(
      EnumClass enumClass) {
    return _enumInfo[enumClass] ??=
        new EnumInfo(typeOperations, this, enumOperations, enumClass);
  }

  /// Returns the [SealedClassInfo] for [sealedClass].
  SealedClassInfo<Type, Class> _getSealedClassInfo(Class sealedClass) {
    return _sealedClassInfo[sealedClass] ??=
        new SealedClassInfo(_sealedClassOperations, sealedClass);
  }

  /// Returns the [StaticType] for the boolean [value].
  StaticType getBoolValueStaticType(bool value) {
    return value ? _boolStaticType.trueType : _boolStaticType.falseType;
  }

  /// Returns the [StaticType] for [type].
  StaticType getStaticType(Type type) {
    if (typeOperations.isNeverType(type)) {
      return StaticType.neverType;
    } else if (typeOperations.isNullType(type)) {
      return StaticType.nullType;
    } else if (typeOperations.isNonNullableObject(type)) {
      return StaticType.nonNullableObject;
    } else if (typeOperations.isNullableObject(type) ||
        typeOperations.isDynamic(type)) {
      return StaticType.nullableObject;
    }

    StaticType staticType;
    Type nonNullable = typeOperations.getNonNullable(type);
    if (typeOperations.isBoolType(nonNullable)) {
      staticType = _boolStaticType;
    } else if (typeOperations.isRecordType(nonNullable)) {
      staticType = new RecordStaticType(typeOperations, this, nonNullable);
    } else {
      Type? futureOrTypeArgument =
          typeOperations.getFutureOrTypeArgument(nonNullable);
      if (futureOrTypeArgument != null) {
        StaticType typeArgument = getStaticType(futureOrTypeArgument);
        StaticType futureType = getStaticType(
            typeOperations.instantiateFuture(futureOrTypeArgument));
        bool isImplicitlyNullable =
            typeOperations.isNullable(futureOrTypeArgument);
        staticType = new FutureOrStaticType(
            typeOperations, this, nonNullable, typeArgument, futureType,
            isImplicitlyNullable: isImplicitlyNullable);
      } else {
        EnumClass? enumClass = enumOperations.getEnumClass(nonNullable);
        if (enumClass != null) {
          staticType = new EnumStaticType(
              typeOperations, this, nonNullable, _getEnumInfo(enumClass));
        } else {
          Class? sealedClass =
              _sealedClassOperations.getSealedClass(nonNullable);
          if (sealedClass != null) {
            staticType = new SealedClassStaticType(
                typeOperations,
                this,
                nonNullable,
                this,
                _sealedClassOperations,
                _getSealedClassInfo(sealedClass));
          } else {
            Type? listType = typeOperations.getListType(nonNullable);
            if (listType != null) {
              staticType =
                  new ListTypeStaticType(typeOperations, this, nonNullable);
            } else {
              bool isImplicitlyNullable =
                  typeOperations.isNullable(nonNullable);
              staticType = new TypeBasedStaticType(
                  typeOperations, this, nonNullable,
                  isImplicitlyNullable: isImplicitlyNullable);
              Type? bound = typeOperations.getTypeVariableBound(type);
              if (bound != null) {
                staticType =
                    new WrappedStaticType(getStaticType(bound), staticType);
              }
            }
          }
        }
      }
    }
    if (typeOperations.isNullable(type)) {
      staticType = staticType.nullable;
    }
    return staticType;
  }

  /// Returns the [StaticType] for the [enumElementValue] declared by
  /// [enumClass].
  StaticType getEnumElementStaticType(
      EnumClass enumClass, EnumElementValue enumElementValue) {
    return _getEnumInfo(enumClass).getEnumElement(enumElementValue);
  }

  /// Creates a new unique [StaticType].
  StaticType getUnknownStaticType() {
    // The unknown static type should be based on the nullable `Object`, since
    // even though it _might_ be `null`, using the nullable `Object` here would
    // mean that it _does_ include `null`, and we need this type to only cover
    // itself.
    return getUniqueStaticType<Object>(
        typeOperations.nonNullableObjectType, new Object(), '?');
  }

  /// Returns a [StaticType] of the given [type] with the given
  /// [textualRepresentation] that unique identifies the [uniqueValue].
  ///
  /// This is used for constants that are neither bool nor enum values.
  StaticType getUniqueStaticType<Identity extends Object>(
      Type type, Identity uniqueValue, String textualRepresentation) {
    Type nonNullable = typeOperations.getNonNullable(type);
    StaticType staticType = _uniqueTypeMap[uniqueValue] ??=
        new GeneralValueStaticType<Type, Identity>(
            typeOperations,
            this,
            nonNullable,
            new IdentityRestriction<Identity>(uniqueValue),
            textualRepresentation,
            uniqueValue);
    if (typeOperations.isNullable(type)) {
      staticType = staticType.nullable;
    }
    return staticType;
  }

  /// Returns a [StaticType] of the list [type] with the given [restriction] .
  StaticType getListStaticType(
      Type type, ListTypeRestriction<Type> restriction) {
    Type nonNullable = typeOperations.getNonNullable(type);
    StaticType staticType = new ListPatternStaticType(
        typeOperations, this, nonNullable, restriction, restriction.toString());
    if (typeOperations.isNullable(type)) {
      staticType = staticType.nullable;
    }
    return staticType;
  }

  /// Returns a [StaticType] of the map [type] with the given [restriction] .
  StaticType getMapStaticType(Type type, MapTypeRestriction<Type> restriction) {
    Type nonNullable = typeOperations.getNonNullable(type);
    StaticType staticType = new MapPatternStaticType(
        typeOperations, this, nonNullable, restriction, restriction.toString());
    if (typeOperations.isNullable(type)) {
      staticType = staticType.nullable;
    }
    return staticType;
  }

  @override
  Map<Key, StaticType> getFieldTypes(Type type) {
    Map<Key, StaticType>? fields = _fieldCache[type];
    if (fields == null) {
      _fieldCache[type] = fields = {};
      for (MapEntry<Key, Type> entry
          in typeOperations.getFieldTypes(type).entries) {
        fields[entry.key] = getStaticType(entry.value);
      }
    }
    return fields;
  }

  @override
  StaticType? getAdditionalFieldType(Type type, Key key) {
    if (key is MapKey) {
      Type? valueType = typeOperations.getMapValueType(type);
      if (valueType != null) {
        return getStaticType(valueType);
      }
    } else if (key is HeadKey || key is TailKey) {
      Type? elementType = typeOperations.getListElementType(type);
      if (elementType != null) {
        return getStaticType(elementType);
      }
    } else if (key is RestKey) {
      Type? listType = typeOperations.getListType(type);
      if (listType != null) {
        return getStaticType(listType);
      }
    } else {
      return getObjectFieldType(key);
    }
    return null;
  }

  @override
  StaticType? getObjectFieldType(Key key) {
    return getFieldTypes(typeOperations.nonNullableObjectType)[key];
  }
}

/// Mixin for creating [Space]s from [Pattern]s.
mixin SpaceCreator<Pattern extends Object, Type extends Object> {
  TypeOperations<Type> get typeOperations;

  ObjectPropertyLookup get objectFieldLookup;

  /// Creates a [StaticType] for an unknown type.
  ///
  /// This is used when the type of the pattern is unknown or can't be
  /// represented as a [StaticType]. This type is unique and ensures that it
  /// is neither matches anything nor is matched by anything.
  StaticType createUnknownStaticType();

  /// Creates the [StaticType] for [type].
  StaticType createStaticType(Type type);

  /// Creates the [StaticType] for [type] restricted by the [contextType].
  /// If [nonNull] is `true`, the created type is non-nullable.
  StaticType _createStaticTypeWithContext(StaticType contextType, Type type,
      {required bool nonNull}) {
    StaticType staticType = createStaticType(type);
    if (contextType.isSubtypeOf(staticType)) {
      staticType = contextType;
    }
    if (nonNull) {
      staticType = staticType.nonNullable;
    }
    return staticType;
  }

  /// Creates the [StaticType] for the list [type] with the given [restriction].
  StaticType createListType(Type type, ListTypeRestriction<Type> restriction);

  /// Creates the [StaticType] for the map [type] with the given [restriction].
  StaticType createMapType(Type type, MapTypeRestriction<Type> restriction);

  /// Creates the [Space] for [pattern] at the given [path].
  ///
  /// The [contextType] is the [StaticType] in which the pattern match is
  /// performed. This is used to the restrict type of the created [Space] to
  /// the types allowed by the context. For instance `Object(:var hashCode)` is
  /// in itself unrestricted and would yield the top space for matching
  /// `var hashCode`. Using the [contextType] `int`, as given by the type of
  /// the `Object.hashCode`, the created space is all `int` values rather than
  /// all values.
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space dispatchPattern(Path path, StaticType contextType, Pattern pattern,
      {required bool nonNull});

  /// Creates the root space for [pattern].
  Space createRootSpace(StaticType contextType, Pattern pattern,
      {required bool hasGuard}) {
    if (hasGuard) {
      return createUnknownSpace(const Path.root());
    } else {
      return dispatchPattern(const Path.root(), contextType, pattern,
          nonNull: false);
    }
  }

  /// Creates the [Space] at [path] for a variable pattern of the declared
  /// [type].
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space createVariableSpace(Path path, StaticType contextType, Type type,
      {required bool nonNull}) {
    StaticType staticType =
        _createStaticTypeWithContext(contextType, type, nonNull: nonNull);
    return new Space(path, staticType);
  }

  /// Creates the [Space] at [path] for an object pattern of the required [type]
  /// and [fieldPatterns].
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space createObjectSpace(
      Path path,
      StaticType contextType,
      Type type,
      Map<String, Pattern> fieldPatterns,
      Map<String, Type> extensionPropertyTypes,
      {required bool nonNull}) {
    StaticType staticType =
        _createStaticTypeWithContext(contextType, type, nonNull: nonNull);
    Map<Key, Space> properties = <Key, Space>{};
    for (MapEntry<String, Pattern> entry in fieldPatterns.entries) {
      String name = entry.key;
      StaticType propertyType;
      Type? extensionPropertyType = extensionPropertyTypes[name];
      Key key;
      if (extensionPropertyType != null) {
        propertyType = createStaticType(extensionPropertyType);
        key = new ExtensionKey(createStaticType(type), name, propertyType);
      } else {
        key = new NameKey(name);
        propertyType = staticType.getPropertyType(objectFieldLookup, key) ??
            StaticType.nullableObject;
      }
      properties[key] = dispatchPattern(
          path.add(key), propertyType, entry.value,
          nonNull: false);
    }
    return new Space(path, staticType, properties: properties);
  }

  /// Creates the [Space] at [path] for a record pattern of the required [type],
  /// [positionalFields], and [namedFields].
  Space createRecordSpace(Path path, StaticType contextType, Type recordType,
      List<Pattern> positionalFields, Map<String, Pattern> namedFields) {
    StaticType staticType =
        _createStaticTypeWithContext(contextType, recordType, nonNull: true);
    Map<Key, Space> properties = <Key, Space>{};
    for (int index = 0; index < positionalFields.length; index++) {
      Key key = new RecordIndexKey(index);
      StaticType propertyType =
          staticType.getPropertyType(objectFieldLookup, key) ??
              StaticType.nullableObject;
      properties[key] = dispatchPattern(
          path.add(key), propertyType, positionalFields[index],
          nonNull: false);
    }
    for (MapEntry<String, Pattern> entry in namedFields.entries) {
      Key key = new RecordNameKey(entry.key);
      StaticType propertyType =
          staticType.getPropertyType(objectFieldLookup, key) ??
              StaticType.nullableObject;
      properties[key] = dispatchPattern(
          path.add(key), propertyType, entry.value,
          nonNull: false);
    }
    return new Space(path, staticType, properties: properties);
  }

  /// Creates the [Space] at [path] for a wildcard pattern with the declared
  /// [type].
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space createWildcardSpace(Path path, StaticType contextType, Type? type,
      {required bool nonNull}) {
    if (type == null) {
      StaticType staticType = contextType;
      if (nonNull) {
        staticType = staticType.nonNullable;
      }
      return new Space(path, staticType);
    } else {
      StaticType staticType =
          _createStaticTypeWithContext(contextType, type, nonNull: nonNull);
      return new Space(path, staticType);
    }
  }

  /// Creates the [Space] at [path] for a relational pattern.
  Space createRelationalSpace(Path path) {
    // This pattern do not add to the exhaustiveness coverage.
    return createUnknownSpace(path);
  }

  /// Creates the [Space] at [path] for a cast pattern with the given
  /// [subPattern].
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space createCastSpace(
      Path path, StaticType contextType, Type type, Pattern subPattern,
      {required bool nonNull}) {
    Space space =
        dispatchPattern(path, contextType, subPattern, nonNull: nonNull);
    StaticType castType = createStaticType(type);
    if (castType.isSubtypeOf(contextType) && contextType.isSealed) {
      for (StaticType subtype in expandSealedSubtypes(contextType, const {})) {
        // If [subtype] is a subtype of [castType] it will not throw and must
        // be handled by [subPattern]. For instance
        //
        //    sealed class S {}
        //    sealed class X extends S {}
        //    class A extends X {}
        //    method(S s) => switch (s) {
        //      A() as X => 0,
        //    }
        //
        // If [castType] is a subtype of [subtype] it might not throw but still
        // not handle all values of the [subtype].
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
        if (!castType.isSubtypeOf(subtype) && !subtype.isSubtypeOf(castType)) {
          // Otherwise the cast implicitly handles [subtype].
          space = space.union(new Space(path, subtype));
        }
      }
    }
    return space;
  }

  /// Creates the [Space] at [path] for a null check pattern with the given
  /// [subPattern].
  Space createNullCheckSpace(
      Path path, StaticType contextType, Pattern subPattern) {
    return dispatchPattern(path, contextType, subPattern, nonNull: true);
  }

  /// Creates the [Space] at [path] for a null assert pattern with the given
  /// [subPattern].
  Space createNullAssertSpace(
      Path path, StaticType contextType, Pattern subPattern) {
    Space space = dispatchPattern(path, contextType, subPattern, nonNull: true);
    return space.union(new Space(path, StaticType.nullType));
  }

  /// Creates the [Space] at [path] for a logical or pattern with the given
  /// [left] and [right] subpatterns.
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space createLogicalOrSpace(
      Path path, StaticType contextType, Pattern left, Pattern right,
      {required bool nonNull}) {
    Space aSpace = dispatchPattern(path, contextType, left, nonNull: nonNull);
    Space bSpace = dispatchPattern(path, contextType, right, nonNull: nonNull);
    return aSpace.union(bSpace);
  }

  /// Creates the [Space] at [path] for a logical and pattern with the given
  /// [left] and [right] subpatterns.
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space createLogicalAndSpace(
      Path path, StaticType contextType, Pattern left, Pattern right,
      {required bool nonNull}) {
    Space aSpace = dispatchPattern(path, contextType, left, nonNull: nonNull);
    Space bSpace = dispatchPattern(path, contextType, right, nonNull: nonNull);
    return _createSpaceIntersection(path, aSpace, bSpace);
  }

  /// Creates the [Space] at [path] for a list pattern.
  Space createListSpace(Path path,
      {required Type type,
      required Type elementType,
      required List<Pattern> headElements,
      required Pattern? restElement,
      required List<Pattern> tailElements,
      required bool hasRest,
      required bool hasExplicitTypeArgument}) {
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

    ListTypeRestriction<Type> identity = new ListTypeRestriction(
        elementType, typeArgumentText,
        size: headSize + tailSize, hasRest: hasRest);

    StaticType staticType = createListType(type, identity);

    Map<Key, Space> additionalProperties = {};
    for (int index = 0; index < headSize; index++) {
      Key key = new HeadKey(index);
      StaticType propertyType = staticType.getAdditionalPropertyType(key) ??
          StaticType.nullableObject;
      additionalProperties[key] = dispatchPattern(
          path.add(key), propertyType, headElements[index],
          nonNull: false);
    }
    if (hasRest) {
      Key key = new RestKey(headSize, tailSize);
      StaticType propertyType = staticType.getAdditionalPropertyType(key) ??
          StaticType.nullableObject;
      if (restElement != null) {
        additionalProperties[key] = dispatchPattern(
            path.add(key), propertyType, restElement,
            nonNull: false);
      } else {
        additionalProperties[key] = new Space(path.add(key), propertyType);
      }
    }
    for (int index = 0; index < tailSize; index++) {
      Key key = new TailKey(index);
      StaticType propertyType = staticType.getAdditionalPropertyType(key) ??
          StaticType.nullableObject;
      additionalProperties[key] = dispatchPattern(path.add(key), propertyType,
          tailElements[tailElements.length - index - 1],
          nonNull: false);
    }
    return new Space(path, staticType,
        additionalProperties: additionalProperties);
  }

  /// Creates the [Space] at [path] for a map pattern.
  Space createMapSpace(Path path,
      {required Type type,
      required Type keyType,
      required Type valueType,
      required Map<MapKey, Pattern> entries,
      required bool hasExplicitTypeArguments}) {
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

    MapTypeRestriction<Type> identity = new MapTypeRestriction(
        keyType, valueType, entries.keys.toSet(), typeArgumentsText);
    StaticType staticType = createMapType(type, identity);

    Map<Key, Space> additionalProperties = {};
    for (MapEntry<Key, Pattern> entry in entries.entries) {
      Key key = entry.key;
      StaticType propertyType = staticType.getAdditionalPropertyType(key) ??
          StaticType.nullableObject;
      additionalProperties[key] = dispatchPattern(
          path.add(key), propertyType, entry.value,
          nonNull: false);
    }
    return new Space(path, staticType,
        additionalProperties: additionalProperties);
  }

  /// Creates the [Space] at [path] for a pattern with unknown space.
  ///
  /// This is used when the space of the pattern is unknown or can't be
  /// represented precisely as a union of [SingleSpace]s. This space is unique
  /// and ensures that it is neither matches anything nor is matched by
  /// anything.
  Space createUnknownSpace(Path path) {
    return new Space(path, createUnknownStaticType());
  }

  /// Creates an approximation of the intersection of the single spaces [a] and
  /// [b].
  SingleSpace? _createSingleSpaceIntersection(
      Path path, SingleSpace a, SingleSpace b) {
    StaticType? type;
    if (a.type.isSubtypeOf(b.type)) {
      type = a.type;
    } else if (b.type.isSubtypeOf(a.type)) {
      type = b.type;
    }
    if (type == null) {
      return null;
    }
    Map<Key, Space> properties = {};
    for (MapEntry<Key, Space> entry in a.properties.entries) {
      Key key = entry.key;
      Space aSpace = entry.value;
      Space? bSpace = b.properties[key];
      if (bSpace != null) {
        properties[key] =
            _createSpaceIntersection(path.add(key), aSpace, bSpace);
      } else {
        properties[key] = aSpace;
      }
    }
    for (MapEntry<Key, Space> entry in b.properties.entries) {
      Key key = entry.key;
      properties[key] ??= entry.value;
    }
    return new SingleSpace(type, properties: properties);
  }

  /// Creates an approximation of the intersection of spaces [a] and [b].
  Space _createSpaceIntersection(Path path, Space a, Space b) {
    assert(
        path == a.path, "Unexpected path. Expected $path, actual ${a.path}.");
    assert(
        path == b.path, "Unexpected path. Expected $path, actual ${b.path}.");
    List<SingleSpace> singleSpaces = [];
    bool hasUnknownSpace = false;
    for (SingleSpace aSingleSpace in a.singleSpaces) {
      for (SingleSpace bSingleSpace in b.singleSpaces) {
        SingleSpace? space =
            _createSingleSpaceIntersection(path, aSingleSpace, bSingleSpace);
        if (space != null) {
          singleSpaces.add(space);
        } else {
          hasUnknownSpace = true;
        }
      }
    }
    if (hasUnknownSpace) {
      singleSpaces.add(new SingleSpace(createUnknownStaticType()));
    }
    return new Space.fromSingleSpaces(path, singleSpaces);
  }
}
