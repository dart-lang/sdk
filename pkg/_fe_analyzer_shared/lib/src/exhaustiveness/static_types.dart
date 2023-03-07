// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/static_type.dart';

import 'witness.dart';

/// Interface implemented by analyze/CFE to support type operations need for the
/// shared [StaticType]s.
abstract class TypeOperations<Type extends Object> {
  /// Returns the type for `Object`.
  Type get nullableObjectType;

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
  Map<String, Type> getFieldTypes(Type type);

  /// Returns a human-readable representation of the [type].
  String typeToString(Type type);
}

/// Interface implemented by analyzer/CFE to support [StaticType]s for enums.
abstract class EnumOperations<Type extends Object, EnumClass extends Object,
    EnumElement extends Object, EnumElementValue extends Object> {
  /// Returns the enum class declaration for the [type] or `null` if
  /// [type] is not an enum type.
  EnumClass? getEnumClass(Type type);

  /// Returns the enum elements defined by [enumClass].
  Iterable<EnumElement> getEnumElements(EnumClass enumClass);

  /// Returns the value defined by the [enumElement]. The encoding is specific
  /// the implementation of this interface but must ensure constant value
  /// identity.
  EnumElementValue getEnumElementValue(EnumElement enumElement);

  /// Returns the declared name of the [enumElement].
  String getEnumElementName(EnumElement enumElement);

  /// Returns the static type of the [enumElement].
  Type getEnumElementType(EnumElement enumElement);
}

/// Interface implemented by analyzer/CFE to support [StaticType]s for sealed
/// classes.
abstract class SealedClassOperations<Type extends Object,
    Class extends Object> {
  /// Returns the sealed class declaration for [type] or `null` if [type] is not
  /// a sealed class type.
  Class? getSealedClass(Type type);

  /// Returns the direct subclasses of [sealedClass] that either extend,
  /// implement or mix it in.
  List<Class> getDirectSubclasses(Class sealedClass);

  /// Returns the instance of [subClass] that implements [sealedClassType].
  ///
  /// `null` might be returned if [subClass] cannot implement [sealedClassType].
  /// For instance
  ///
  ///     sealed class A<T> {}
  ///     class B<T> extends A<T> {}
  ///     class C extends A<int> {}
  ///
  /// here `C` has no implementation of `A<String>`.
  ///
  /// It is assumed that `TypeOperations.isSealedClass` is `true` for
  /// [sealedClassType] and that [subClass] is in `getDirectSubclasses` for
  /// `getSealedClass` of [sealedClassType].
  Type? getSubclassAsInstanceOf(Class subClass, Type sealedClassType);
}

/// Interface for looking up fields and their corresponding [StaticType]s of
/// a given type.
abstract class FieldLookup<Type extends Object> {
  /// Returns a map of the field names and corresponding [StaticType]s available
  /// on [type]. For an interface type, these are the fields and getters, and
  /// for record types these are the record fields.
  Map<String, StaticType> getFieldTypes(Type type);
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
    EnumElementValue extends Object> implements FieldLookup<Type> {
  final TypeOperations<Type> _typeOperations;
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
      new BoolStaticType(_typeOperations, this, _typeOperations.boolType);

  /// Cache for [StaticType]s for fields available on a [Type].
  Map<Type, Map<String, StaticType>> _fieldCache = {};

  ExhaustivenessCache(
      this._typeOperations, this.enumOperations, this._sealedClassOperations);

  /// Returns the [EnumInfo] for [enumClass].
  EnumInfo<Type, EnumClass, EnumElement, EnumElementValue> _getEnumInfo(
      EnumClass enumClass) {
    return _enumInfo[enumClass] ??=
        new EnumInfo(_typeOperations, this, enumOperations, enumClass);
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
    if (_typeOperations.isNeverType(type)) {
      return StaticType.neverType;
    } else if (_typeOperations.isNullType(type)) {
      return StaticType.nullType;
    } else if (_typeOperations.isNonNullableObject(type)) {
      return StaticType.nonNullableObject;
    } else if (_typeOperations.isNullableObject(type) ||
        _typeOperations.isDynamic(type)) {
      return StaticType.nullableObject;
    }

    StaticType staticType;
    Type nonNullable = _typeOperations.getNonNullable(type);
    if (_typeOperations.isBoolType(nonNullable)) {
      staticType = _boolStaticType;
    } else if (_typeOperations.isRecordType(nonNullable)) {
      staticType = new RecordStaticType(_typeOperations, this, nonNullable);
    } else {
      Type? futureOrTypeArgument =
          _typeOperations.getFutureOrTypeArgument(nonNullable);
      if (futureOrTypeArgument != null) {
        StaticType typeArgument = getStaticType(futureOrTypeArgument);
        StaticType futureType = getStaticType(
            _typeOperations.instantiateFuture(futureOrTypeArgument));
        staticType = new FutureOrStaticType(
            _typeOperations, this, nonNullable, typeArgument, futureType);
      } else {
        EnumClass? enumClass = enumOperations.getEnumClass(nonNullable);
        if (enumClass != null) {
          staticType = new EnumStaticType(
              _typeOperations, this, nonNullable, _getEnumInfo(enumClass));
        } else {
          Class? sealedClass =
              _sealedClassOperations.getSealedClass(nonNullable);
          if (sealedClass != null) {
            staticType = new SealedClassStaticType(
                _typeOperations,
                this,
                nonNullable,
                this,
                _sealedClassOperations,
                _getSealedClassInfo(sealedClass));
          } else {
            staticType =
                new TypeBasedStaticType(_typeOperations, this, nonNullable);
          }
        }
      }
    }
    if (_typeOperations.isNullable(type)) {
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
    return getUniqueStaticType(
        _typeOperations.nullableObjectType, new Object(), '?');
  }

  /// Returns a [StaticType] of the given [type] with the given
  /// [textualRepresentation] that unique identifies the [uniqueValue].
  ///
  /// This is used for constants that are neither bool nor enum values.
  StaticType getUniqueStaticType(
      Type type, Object uniqueValue, String textualRepresentation) {
    Type nonNullable = _typeOperations.getNonNullable(type);
    StaticType staticType = _uniqueTypeMap[uniqueValue] ??=
        new UniqueStaticType(_typeOperations, this, nonNullable, uniqueValue,
            textualRepresentation);
    if (_typeOperations.isNullable(type)) {
      staticType = staticType.nullable;
    }
    return staticType;
  }

  @override
  Map<String, StaticType> getFieldTypes(Type type) {
    Map<String, StaticType>? fields = _fieldCache[type];
    if (fields == null) {
      _fieldCache[type] = fields = {};
      for (MapEntry<String, Type> entry
          in _typeOperations.getFieldTypes(type).entries) {
        fields[entry.key] = getStaticType(entry.value);
      }
    }
    return fields;
  }
}

/// [EnumInfo] stores information to compute the static type for and the type
/// of and enum class and its enum elements.
class EnumInfo<Type extends Object, EnumClass extends Object,
    EnumElement extends Object, EnumElementValue extends Object> {
  final TypeOperations<Type> _typeOperations;
  final FieldLookup<Type> _fieldLookup;
  final EnumOperations<Type, EnumClass, EnumElement, EnumElementValue>
      _enumOperations;
  final EnumClass _enumClass;
  Map<EnumElementValue, EnumElementStaticType<Type, EnumElement>>?
      _enumElements;

  EnumInfo(this._typeOperations, this._fieldLookup, this._enumOperations,
      this._enumClass);

  /// Returns a map of the enum elements and their corresponding [StaticType]s
  /// declared by [_enumClass].
  Map<EnumElementValue, EnumElementStaticType<Type, EnumElement>>
      get enumElements => _enumElements ??= _createEnumElements();

  /// Returns the [StaticType] corresponding to [enumElementValue].
  EnumElementStaticType<Type, EnumElement> getEnumElement(
      EnumElementValue enumElementValue) {
    return enumElements[enumElementValue]!;
  }

  Map<EnumElementValue, EnumElementStaticType<Type, EnumElement>>
      _createEnumElements() {
    Map<EnumElementValue, EnumElementStaticType<Type, EnumElement>> elements =
        {};
    for (EnumElement element in _enumOperations.getEnumElements(_enumClass)) {
      EnumElementValue value = _enumOperations.getEnumElementValue(element);
      elements[value] = new EnumElementStaticType<Type, EnumElement>(
          _typeOperations,
          _fieldLookup,
          _enumOperations.getEnumElementType(element),
          element,
          _enumOperations.getEnumElementName(element));
    }
    return elements;
  }
}

/// [SealedClassInfo] stores information to compute the static type for a
/// sealed class.
class SealedClassInfo<Type extends Object, Class extends Object> {
  final SealedClassOperations<Type, Class> _sealedClassOperations;
  final Class _sealedClass;
  List<Class>? _subClasses;

  SealedClassInfo(this._sealedClassOperations, this._sealedClass);

  /// Returns the classes that directly extends, implements or mix in
  /// [_sealedClass].
  Iterable<Class> get subClasses =>
      _subClasses ??= _sealedClassOperations.getDirectSubclasses(_sealedClass);
}

/// [StaticType] based on a non-nullable [Type].
///
/// All [StaticType] implementation in this library are based on [Type] through
/// this class. Additionally, the `static_type.dart` library has fixed
/// [StaticType] implementations for `Object`, `Null`, `Never` and nullable
/// types.
class TypeBasedStaticType<Type extends Object> extends NonNullableStaticType {
  final TypeOperations<Type> _typeOperations;
  final FieldLookup<Type> _fieldLookup;
  final Type _type;

  TypeBasedStaticType(this._typeOperations, this._fieldLookup, this._type);

  @override
  Map<String, StaticType> get fields => _fieldLookup.getFieldTypes(_type);

  /// Returns a non-null value for static types that are unique subtypes of
  /// the [_type]. For instance individual elements of an enum.
  Object? get identity => null;

  @override
  bool isSubtypeOfInternal(StaticType other) {
    return other is TypeBasedStaticType<Type> &&
        (other.identity == null || identical(identity, other.identity)) &&
        _typeOperations.isSubtypeOf(_type, other._type);
  }

  @override
  bool get isSealed => false;

  @override
  String get name => _typeOperations.typeToString(_type);

  @override
  int get hashCode => Object.hash(_type, identity);

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other is TypeBasedStaticType<Type> &&
        _type == other._type &&
        identity == other.identity;
  }

  Type get typeForTesting => _type;
}

/// [StaticType] for an instantiation of an enum that support access to the
/// enum values that populate its type through the [subtypes] property.
class EnumStaticType<Type extends Object, EnumElement extends Object>
    extends TypeBasedStaticType<Type> {
  final EnumInfo<Type, Object, EnumElement, Object> _enumInfo;
  List<StaticType>? _enumElements;

  EnumStaticType(
      super.typeOperations, super.fieldLookup, super.type, this._enumInfo);

  @override
  bool get isSealed => true;

  @override
  Iterable<StaticType> get subtypes => enumElements;

  List<StaticType> get enumElements => _enumElements ??= _createEnumElements();

  List<StaticType> _createEnumElements() {
    List<StaticType> elements = [];
    for (EnumElementStaticType<Type, EnumElement> enumElement
        in _enumInfo.enumElements.values) {
      // For generic enums, the individual enum elements might not be subtypes
      // of the concrete enum type. For instance
      //
      //    enum E<T> {
      //      a<int>(),
      //      b<String>(),
      //      c<bool>(),
      //    }
      //
      //    method<T extends num>(E<T> e) {
      //      switch (e) { ... }
      //    }
      //
      // Here the enum elements `E.b` and `E.c` cannot be actual values of `e`
      // because of the bound `num` on `T`.
      //
      // We detect this by checking whether the enum element type is a subtype
      // of the overapproximation of [_type], in this case whether the element
      // types are subtypes of `E<num>`.
      //
      // Since all type arguments on enum values are fixed, we don't have to
      // avoid the trivial subtype instantiation `E<Never>`.
      if (_typeOperations.isSubtypeOf(
          enumElement._type, _typeOperations.overapproximate(_type))) {
        // Since the type of the enum element might not itself be a subtype of
        // [_type], for instance in the example above the type of `Enum.a`,
        // `Enum<int>`, is not a subtype of `Enum<T>`, we wrap the static type
        // to establish the subtype relation between the [StaticType] for the
        // enum element and this [StaticType].
        elements.add(new WrappedStaticType(enumElement, this));
      }
    }
    return elements;
  }
}

/// [StaticType] for a single enum element.
///
/// In the [StaticType] model, individual enum elements are represented as
/// unique subtypes of the enum type, modelled using [EnumStaticType].
class EnumElementStaticType<Type extends Object, EnumElement extends Object>
    extends UniqueStaticType<Type> {
  EnumElementStaticType(super.typeOperations, super.fieldLookup, super.type,
      EnumElement super.enumElement, super.name);
}

/// [StaticType] for a sealed class type.
class SealedClassStaticType<Type extends Object, Class extends Object>
    extends TypeBasedStaticType<Type> {
  final ExhaustivenessCache<Type, dynamic, dynamic, dynamic, Class> _cache;
  final SealedClassOperations<Type, Class> _sealedClassOperations;
  final SealedClassInfo<Type, Class> _sealedInfo;
  Iterable<StaticType>? _subtypes;

  SealedClassStaticType(super.typeOperations, super.fieldLookup, super.type,
      this._cache, this._sealedClassOperations, this._sealedInfo);

  @override
  bool get isSealed => true;

  @override
  Iterable<StaticType> get subtypes => _subtypes ??= _createSubtypes();

  List<StaticType> _createSubtypes() {
    List<StaticType> subtypes = [];
    for (Class subClass in _sealedInfo.subClasses) {
      Type? subtype =
          _sealedClassOperations.getSubclassAsInstanceOf(subClass, _type);
      if (subtype != null) {
        if (!_typeOperations.isGeneric(subtype)) {
          // If the subtype is not generic, we can test whether it can be an
          // actual value of [_type] by testing whether it is a subtype of the
          // overapproximation of [_type].
          //
          // For instance
          //
          //     sealed class A<T> {}
          //     class B extends A<num> {}
          //     class C<T extends num> A<T> {}
          //
          //     method<T extends String>(A<T> a) {
          //       switch (a) {
          //         case B: // Not needed, B cannot inhabit A<T>.
          //         case C: // Needed, C<Never> inhabits A<T>.
          //       }
          //     }
          if (!_typeOperations.isSubtypeOf(
              subtype, _typeOperations.overapproximate(_type))) {
            continue;
          }
        }
        StaticType staticType = _cache.getStaticType(subtype);
        // Since the type of the [subtype] might not itself be a subtype of
        // [_type], for instance in the example above the type of `case C:`,
        // `C<num>`, is not a subtype of `A<T>`, we wrap the static type
        // to establish the subtype relation between the [StaticType] for the
        // enum element and this [StaticType].
        subtypes.add(new WrappedStaticType(staticType, this));
      }
    }
    return subtypes;
  }
}

/// [StaticType] for an object uniquely defined by its [identity].
class UniqueStaticType<Type extends Object> extends TypeBasedStaticType<Type> {
  @override
  final Object identity;

  @override
  final String name;

  UniqueStaticType(super.typeOperations, super.fieldLookup, super.type,
      this.identity, this.name);
}

/// [StaticType] for the `bool` type.
class BoolStaticType<Type extends Object> extends TypeBasedStaticType<Type> {
  BoolStaticType(super.typeOperations, super.fieldLookup, super.type);

  @override
  bool get isSealed => true;

  late StaticType trueType =
      new UniqueStaticType(_typeOperations, _fieldLookup, _type, true, 'true');

  late StaticType falseType = new UniqueStaticType(
      _typeOperations, _fieldLookup, _type, false, 'false');

  @override
  Iterable<StaticType> get subtypes => [trueType, falseType];
}

/// [StaticType] for a record type.
///
/// This models that type aspect of the record using only the structure of the
/// record type. This means that the type for `(Object, String)` and
/// `(String, int)` will be subtypes of each other.
///
/// This is necessary to avoid invalid conclusions on the disjointness of
/// spaces base on the their types. For instance in
///
///     method((String, Object) o) {
///       if (o case (Object _, String s)) {}
///     }
///
/// the case is not empty even though `(String, Object)` and `(Object, String)`
/// are not related type-wise.
///
/// Not that the fields of the record types _are_ using the type, so that
/// the `$1` field of `(String, Object)` is known to contain only `String`s.
class RecordStaticType<Type extends Object> extends TypeBasedStaticType<Type> {
  RecordStaticType(super.typeOperations, super.fieldLookup, super.type);

  @override
  bool get isRecord => true;

  @override
  bool isSubtypeOfInternal(StaticType other) {
    if (other is! RecordStaticType<Type>) {
      return false;
    }
    assert(identity == null);
    if (fields.length != other.fields.length) {
      return false;
    }
    for (MapEntry<String, StaticType> field in fields.entries) {
      StaticType? type = other.fields[field.key];
      if (type == null) {
        return false;
      }
    }
    return true;
  }
}

/// [StaticType] for a `FutureOr<T>` type for some type `T`.
///
/// This is a sealed type where the subtypes for are `T` and `Future<T>`.
class FutureOrStaticType<Type extends Object>
    extends TypeBasedStaticType<Type> {
  /// The type for `T`.
  final StaticType _typeArgument;

  /// The type for `Future<T>`.
  final StaticType _futureType;

  FutureOrStaticType(super.typeOperations, super.fieldLookup, super.type,
      this._typeArgument, this._futureType);

  @override
  bool get isSealed => true;

  @override
  Iterable<StaticType> get subtypes => [_typeArgument, _futureType];
}

/// Mixin for creating [Space]s from [Pattern]s.
mixin SpaceCreator<Pattern extends Object, Type extends Object> {
  /// Creates a [StaticType] for an unknown type.
  ///
  /// This is used when the type of the pattern is unknown or can't be
  /// represented as a [StaticType]. This type is unique and ensures that it
  /// is neither matches anything nor is matched by anything.
  StaticType createUnknownStaticType();

  /// Creates the [StaticType] for [type]. If [nonNull] is `true`, the created
  /// type is non-nullable.
  StaticType createStaticType(Type type, {required bool nonNull});

  /// Creates the [Space] for [pattern] at the given [path].
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space dispatchPattern(Path path, Pattern pattern, {required bool nonNull});

  /// Creates the root space for [pattern].
  Space createRootSpace(Pattern pattern, {required bool hasGuard}) {
    if (hasGuard) {
      return createUnknownSpace(const Path.root());
    } else {
      return dispatchPattern(const Path.root(), pattern, nonNull: false);
    }
  }

  /// Creates the [Space] at [path] for a variable pattern of the declared
  /// [type].
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space createVariableSpace(Path path, Type type, {required bool nonNull}) {
    return new Space(path, createStaticType(type, nonNull: nonNull));
  }

  /// Creates the [Space] at [path] for an object pattern of the required [type]
  /// and [fieldPatterns].
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space createObjectSpace(
      Path path, Type type, Map<String, Pattern> fieldPatterns,
      {required bool nonNull}) {
    Map<String, Space> fields = <String, Space>{};
    for (MapEntry<String, Pattern> entry in fieldPatterns.entries) {
      String name = entry.key;
      fields[name] =
          dispatchPattern(path.add(name), entry.value, nonNull: false);
    }
    StaticType staticType = createStaticType(type, nonNull: nonNull);
    return new Space(path, staticType, fields: fields);
  }

  /// Creates the [Space] at [path] for a record pattern of the required [type],
  /// [positionalFields], and [namedFields].
  Space createRecordSpace(Path path, Type recordType,
      List<Pattern> positionalFields, Map<String, Pattern> namedFields) {
    Map<String, Space> fields = <String, Space>{};
    for (int index = 0; index < positionalFields.length; index++) {
      String name = '\$${index + 1}';
      fields[name] = dispatchPattern(path.add(name), positionalFields[index],
          nonNull: false);
    }
    for (MapEntry<String, Pattern> entry in namedFields.entries) {
      String name = entry.key;
      fields[name] =
          dispatchPattern(path.add(name), entry.value, nonNull: false);
    }
    return new Space(path, createStaticType(recordType, nonNull: true),
        fields: fields);
  }

  /// Creates the [Space] at [path] for a wildcard pattern with the declared
  /// [type].
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space createWildcardSpace(Path path, Type? type, {required bool nonNull}) {
    if (type == null) {
      if (nonNull) {
        return new Space(path, StaticType.nonNullableObject);
      } else {
        return new Space(path, StaticType.nullableObject);
      }
    } else {
      StaticType staticType = createStaticType(type, nonNull: nonNull);
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
  Space createCastSpace(Path path, Pattern subPattern,
      {required bool nonNull}) {
    // TODO(johnniwinther): Handle types (sibling sealed types?) implicitly
    // handled by the throw of the invalid cast.
    return dispatchPattern(path, subPattern, nonNull: nonNull);
  }

  /// Creates the [Space] at [path] for a null check pattern with the given
  /// [subPattern].
  Space createNullCheckSpace(Path path, Pattern subPattern) {
    return dispatchPattern(path, subPattern, nonNull: true);
  }

  /// Creates the [Space] at [path] for a null assert pattern with the given
  /// [subPattern].
  Space createNullAssertSpace(Path path, Pattern subPattern) {
    Space space = dispatchPattern(path, subPattern, nonNull: true);
    return space.union(new Space(path, StaticType.nullType));
  }

  /// Creates the [Space] at [path] for a logical or pattern with the given
  /// [left] and [right] subpatterns.
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space createLogicalOrSpace(Path path, Pattern left, Pattern right,
      {required bool nonNull}) {
    Space aSpace = dispatchPattern(path, left, nonNull: nonNull);
    Space bSpace = dispatchPattern(path, right, nonNull: nonNull);
    return aSpace.union(bSpace);
  }

  /// Creates the [Space] at [path] for a logical and pattern with the given
  /// [left] and [right] subpatterns.
  ///
  /// If [nonNull] is `true`, the space is implicitly non-nullable.
  Space createLogicalAndSpace(Path path, Pattern left, Pattern right,
      {required bool nonNull}) {
    Space aSpace = dispatchPattern(path, left, nonNull: nonNull);
    Space bSpace = dispatchPattern(path, right, nonNull: nonNull);
    return _createSpaceIntersection(path, aSpace, bSpace);
  }

  /// Creates the [Space] at [path] for a list pattern.
  Space createListSpace(Path path) {
    // TODO(johnniwinther): Support list patterns. This not only
    //  requires a new interpretation of [Space] fields that handles the
    //  relation between concrete lengths, rest patterns with/without
    //  subpattern, and list of arbitrary size and content, but also for the
    //  runtime to check for lengths < 0.
    return createUnknownSpace(path);
  }

  /// Creates the [Space] at [path] for a map pattern.
  Space createMapSpace(Path path) {
    // TODO(johnniwinther): Support map patterns. This not only
    //  requires a new interpretation of [Space] fields that handles the
    //  relation between concrete lengths, rest patterns with/without
    //  subpattern, and map of arbitrary size and content, but also for the
    //  runtime to check for lengths < 0.
    return createUnknownSpace(path);
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
    Map<String, Space> fields = {};
    for (MapEntry<String, Space> entry in a.fields.entries) {
      String name = entry.key;
      Space aSpace = entry.value;
      Space? bSpace = b.fields[name];
      if (bSpace != null) {
        fields[name] = _createSpaceIntersection(path.add(name), aSpace, bSpace);
      } else {
        fields[name] = aSpace;
      }
    }
    for (MapEntry<String, Space> entry in b.fields.entries) {
      String name = entry.key;
      fields[name] ??= entry.value;
    }
    return new SingleSpace(type, fields: fields);
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
