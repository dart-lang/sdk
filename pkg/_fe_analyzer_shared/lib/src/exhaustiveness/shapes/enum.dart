// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../types.dart';

/// Interface implemented by analyzer/CFE to support [Shape]s for enums.
abstract class EnumOperations<
  Type extends Object,
  EnumClass extends Object,
  EnumElement extends Object,
  EnumElementValue extends Object
> {
  /// Returns the enum class declaration for the [type] or `null` if
  /// [type] is not an enum type.
  EnumClass? getEnumClass(Type type);

  /// Returns the enum elements defined by [enumClass].
  Iterable<EnumElement> getEnumElements(EnumClass enumClass);

  /// Returns the value defined by the [enumElement]. The encoding is specific
  /// the implementation of this interface but must ensure constant value
  /// identity.
  EnumElementValue? getEnumElementValue(EnumElement enumElement);

  /// Returns the declared name of the [enumElement] including the enum prefix,
  /// i.e. `E.a`.
  String getEnumElementName(EnumElement enumElement);

  /// Returns the declared name of the [enumElement] excluding the enum prefix,
  /// i.e. `a` instead of `E.a`.
  String getEnumElementSimpleName(EnumElement enumElement);

  /// Returns the static type of the [enumElement].
  Type getEnumElementType(EnumElement enumElement);
}

/// [EnumInfo] stores information to compute the shapes for an enum class and
/// its enum elements.
class EnumInfo<
  Type extends Object,
  EnumClass extends Object,
  EnumElement extends Object,
  EnumElementValue extends Object
> {
  final TypeOperations<Type> _typeOperations;
  final PropertyLookup<Type> _propertyLookup;
  final EnumOperations<Type, EnumClass, EnumElement, EnumElementValue>
  _enumOperations;
  final EnumClass _enumClass;
  Map<EnumElementValue, EnumElementShape<Type, EnumElement>>? _enumElements;

  new(
    this._typeOperations,
    this._propertyLookup,
    this._enumOperations,
    this._enumClass,
  );

  /// Returns a map of the enum elements and their corresponding [Shape]s
  /// declared by [_enumClass].
  Map<EnumElementValue, EnumElementShape<Type, EnumElement>> get enumElements =>
      _enumElements ??= _createEnumElements();

  /// Returns the [Shape] corresponding to [enumElementValue].
  EnumElementShape<Type, EnumElement> getEnumElement(
    EnumElementValue enumElementValue,
  ) {
    return enumElements[enumElementValue]!;
  }

  Map<EnumElementValue, EnumElementShape<Type, EnumElement>>
  _createEnumElements() {
    Map<EnumElementValue, EnumElementShape<Type, EnumElement>> elements = {};
    for (EnumElement element in _enumOperations.getEnumElements(_enumClass)) {
      EnumElementValue? value = _enumOperations.getEnumElementValue(element);
      if (value != null) {
        elements[value] = new EnumElementShape<Type, EnumElement>(
          _typeOperations,
          _propertyLookup,
          _enumOperations.getEnumElementType(element),
          new IdentityRestriction<EnumElement>(element),
          _enumOperations.getEnumElementName(element),
          element,
          _enumOperations.getEnumElementSimpleName(element),
        );
      }
    }
    return elements;
  }
}

/// [Shape] for an instantiation of an enum that supports access to the
/// enum values that populate its shape through the [getSubshapes] method.
class EnumShape<Type extends Object, EnumElement extends Object>
    extends TypeBasedShape<Type> {
  final EnumInfo<Type, Object, EnumElement, Object> _enumInfo;
  List<Shape>? _enumElements;

  new(super.typeOperations, super.propertyLookup, super.type, this._enumInfo)
    : super(isImplicitlyNullable: false);

  @override
  bool get isSealed => true;

  @override
  Iterable<Shape> getSubshapes(Set<Key> keysOfInterest) => enumElements;

  List<Shape> get enumElements => _enumElements ??= _createEnumElements();

  List<Shape> _createEnumElements() {
    List<Shape> elements = [];
    for (EnumElementShape<Type, EnumElement> enumElement
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
        enumElement._type,
        _typeOperations.overapproximate(_type),
      )) {
        // Since the type of the enum element might not itself be a subtype of
        // [_type], for instance in the example above the type of `Enum.a`,
        // `Enum<int>`, is not a subtype of `Enum<T>`, we wrap the shape to
        // establish the subshape relation between the [Shape] for the enum
        // element and this [Shape].
        elements.add(new WrappedShape(enumElement, this));
      }
    }
    return elements;
  }
}

/// [Shape] for a single enum element.
///
/// In the [Shape] model, individual enum elements are represented as
/// unique subshapes of the enum shape, modelled using [EnumShape].
class EnumElementShape<Type extends Object, EnumElement extends Object>
    extends ValueShape<Type, EnumElement> {
  final EnumElement _value;

  /// The simple name of the enum element without the enum prefix, i.e. `a`
  /// instead of `E.a` (which is what [name] is).
  final String _simpleName;

  new(
    super.typeOperations,
    super.propertyLookup,
    super.type,
    super.restriction,
    super.name,
    this._value,
    this._simpleName,
  );

  @override
  void valueToDart(DartTemplateBuffer buffer) {
    buffer.writeEnumValue(_value, name);
  }

  @override
  Future<bool> isAccessible(DartAccessibility accessibility) async {
    return accessibility.isEnumValueAccessible(_value, _simpleName);
  }
}
