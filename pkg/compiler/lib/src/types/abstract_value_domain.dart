// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.abstract_value_domain;

import '../constants/values.dart';
import '../dart_types.dart';
import '../elements/elements.dart';
import '../universe/selector.dart' show Selector;

enum AbstractBool { True, False, Maybe, Nothing }

/// A value in an abstraction of runtime values.
abstract class AbstractValue {}

/// A system that implements an abstraction over runtime values and provides
/// access to interprocedural analysis results.
// TODO(johnniwinther): Consider extracting the inference result access from
// this interface.
abstract class AbstractValueDomain {
  AbstractValue get dynamicType;
  AbstractValue get typeType;
  AbstractValue get functionType;
  AbstractValue get boolType;
  AbstractValue get intType;
  AbstractValue get doubleType;
  AbstractValue get numType;
  AbstractValue get stringType;
  AbstractValue get listType;
  AbstractValue get mapType;
  AbstractValue get nonNullType;
  AbstractValue get nullType;
  AbstractValue get extendableArrayType;
  AbstractValue get fixedArrayType;
  AbstractValue get arrayType;
  AbstractValue get uint31Type;
  AbstractValue get uint32Type;
  AbstractValue get uintType;

  AbstractValue get numStringBoolType;

  AbstractValue get fixedLengthType;

  AbstractValue get interceptorType;

  AbstractValue get interceptedTypes;

  /// If true, [function] ignores its explicit receiver argument and will use
  /// its `this` value instead.
  bool methodIgnoresReceiverArgument(FunctionElement function);

  /// If true, the explicit receiver argument can be ignored when invoking
  /// [selector] on a value of [type].
  bool targetIgnoresReceiverArgument(AbstractValue type, Selector selector);

  Element locateSingleElement(AbstractValue mask, Selector selector);

  ClassElement singleClass(AbstractValue mask);

  bool needsNoSuchMethodHandling(AbstractValue mask, Selector selector);

  AbstractValue getReceiverType(MethodElement method);

  AbstractValue getParameterType(ParameterElement parameter);

  AbstractValue getReturnType(FunctionElement function);

  AbstractValue getInvokeReturnType(Selector selector, AbstractValue mask);

  AbstractValue getFieldType(FieldElement field);

  AbstractValue join(AbstractValue a, AbstractValue b);

  AbstractValue intersection(AbstractValue a, AbstractValue b);

  AbstractValue getTypeOf(ConstantValue constant);

  /// Returns the constant value if the [AbstractValue] represents a single
  /// constant value. Returns `null` if [value] is not a constant.
  ConstantValue getConstantOf(AbstractValue value);

  AbstractValue nonNullExact(ClassElement element);

  AbstractValue nonNullSubclass(ClassElement element);

  AbstractValue nonNullSubtype(ClassElement element);

  bool isDefinitelyBool(AbstractValue t, {bool allowNull: false});

  bool isDefinitelyNum(AbstractValue t, {bool allowNull: false});

  bool isDefinitelyString(AbstractValue t, {bool allowNull: false});

  bool isDefinitelyNumStringBool(AbstractValue t, {bool allowNull: false});

  bool isDefinitelyNotNumStringBool(AbstractValue t);

  /// True if all values of [t] are either integers or not numbers at all.
  ///
  /// This does not imply that the value is an integer, since most other values
  /// such as null are also not a non-integer double.
  bool isDefinitelyNotNonIntegerDouble(AbstractValue t);

  bool isDefinitelyNonNegativeInt(AbstractValue t, {bool allowNull: false});

  bool isDefinitelyInt(AbstractValue t, {bool allowNull: false});

  bool isDefinitelyUint31(AbstractValue t, {bool allowNull: false});

  bool isDefinitelyUint32(AbstractValue t, {bool allowNull: false});

  bool isDefinitelyUint(AbstractValue t, {bool allowNull: false});

  bool isDefinitelyArray(AbstractValue t, {bool allowNull: false});

  bool isDefinitelyMutableArray(AbstractValue t, {bool allowNull: false});

  bool isDefinitelyFixedArray(AbstractValue t, {bool allowNull: false});

  bool isDefinitelyExtendableArray(AbstractValue t, {bool allowNull: false});

  bool isDefinitelyIndexable(AbstractValue t, {bool allowNull: false});

  bool isDefinitelyMutableIndexable(AbstractValue t, {bool allowNull: false});

  bool isDefinitelyFixedLengthIndexable(AbstractValue t,
      {bool allowNull: false});

  bool isDefinitelyIntercepted(AbstractValue t, {bool allowNull});

  bool isDefinitelySelfInterceptor(AbstractValue t, {bool allowNull: false});

  /// Given a class from the interceptor hierarchy, returns an [AbstractValue]
  /// matching all values with that interceptor (or a subtype thereof).
  AbstractValue getInterceptorSubtypes(ClassElement class_);

  bool areDisjoint(AbstractValue leftType, AbstractValue rightType);

  bool isMorePreciseOrEqual(AbstractValue t1, AbstractValue t2);

  AbstractBool isSubtypeOf(AbstractValue value, DartType type,
      {bool allowNull});

  /// Returns whether [value] is one of the falsy values: false, 0, -0, NaN,
  /// the empty string, or null.
  AbstractBool boolify(AbstractValue value);

  AbstractBool strictBoolify(AbstractValue type);

  /// Create a type mask containing at least all subtypes of [type].
  AbstractValue subtypesOf(DartType type);

  /// Returns a subset of [receiver] containing at least the types
  /// that can respond to [selector] without throwing.
  AbstractValue receiverTypeFor(Selector selector, AbstractValue receiver);

  /// The result of an index operation on [value], or the dynamic type if
  /// unknown.
  AbstractValue elementTypeOfIndexable(AbstractValue value);

  /// The length property of [value], or `null` if unknown.
  int getContainerLength(AbstractValue value);

  /// Returns the type of the entry of [container] at a given index.
  /// Returns `null` if unknown.
  AbstractValue indexWithConstant(
      AbstractValue container, ConstantValue indexValue);
}
