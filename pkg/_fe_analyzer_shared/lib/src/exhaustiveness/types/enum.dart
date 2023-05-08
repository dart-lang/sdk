// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../types.dart';

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
  EnumElementValue? getEnumElementValue(EnumElement enumElement);

  /// Returns the declared name of the [enumElement].
  String getEnumElementName(EnumElement enumElement);

  /// Returns the static type of the [enumElement].
  Type getEnumElementType(EnumElement enumElement);
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
      EnumElementValue? value = _enumOperations.getEnumElementValue(element);
      if (value != null) {
        elements[value] = new EnumElementStaticType<Type, EnumElement>(
            _typeOperations,
            _fieldLookup,
            _enumOperations.getEnumElementType(element),
            new IdentityRestriction<EnumElement>(element),
            _enumOperations.getEnumElementName(element),
            element);
      }
    }
    return elements;
  }
}

/// [StaticType] for an instantiation of an enum that support access to the
/// enum values that populate its type through the [subtypes] property.
class EnumStaticType<Type extends Object, EnumElement extends Object>
    extends TypeBasedStaticType<Type> {
  final EnumInfo<Type, Object, EnumElement, Object> _enumInfo;
  List<StaticType>? _enumElements;

  EnumStaticType(
      super.typeOperations, super.fieldLookup, super.type, this._enumInfo)
      : super(isImplicitlyNullable: false);

  @override
  bool get isSealed => true;

  @override
  Iterable<StaticType> getSubtypes(Set<Key> keysOfInterest) => enumElements;

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
    extends ValueStaticType<Type, EnumElement> {
  final EnumElement _value;

  EnumElementStaticType(super.typeOperations, super.fieldLookup, super.type,
      super.restriction, super.name, this._value);

  @override
  void valueToDart(DartTemplateBuffer buffer) {
    buffer.writeEnumValue(_value, name);
  }
}
