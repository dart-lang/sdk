// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:meta/meta.dart';

/// The interface `TypeProvider` defines the behavior of objects that provide
/// access to types defined by the language.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeProvider {
  /// Return the element representing the built-in class `bool`.
  ClassElement get boolElement;

  /// Return the element representing the built-in class `bool`.
  @experimental
  ClassElement2 get boolElement2;

  /// Return the type representing the built-in type `bool`.
  InterfaceType get boolType;

  /// Return the type representing the type `bottom`.
  DartType get bottomType;

  /// Return the type representing the built-in type `Deprecated`.
  InterfaceType get deprecatedType;

  /// Return the element representing the built-in class `double`.
  ClassElement get doubleElement;

  /// Return the element representing the built-in class `double`.
  @experimental
  ClassElement2 get doubleElement2;

  /// Return the type representing the built-in type `double`.
  InterfaceType get doubleType;

  /// Return the type representing the built-in type `dynamic`.
  DartType get dynamicType;

  /// Return the element representing the built-in type `Enum`, or `null` if
  /// the SDK does not have definition of `Enum`.
  ClassElement? get enumElement;

  /// Return the element representing the built-in type `Enum`, or `null` if
  /// the SDK does not have definition of `Enum`.
  @experimental
  ClassElement2? get enumElement2;

  /// Return the type representing the built-in type `Enum`, or `null` if
  /// the SDK does not have definition of `Enum`.
  InterfaceType? get enumType;

  /// Return the type representing the built-in type `Function`.
  InterfaceType get functionType;

  /// Return the type representing `Future<dynamic>`.
  InterfaceType get futureDynamicType;

  /// Return the element representing the built-in class `Future`.
  ClassElement get futureElement;

  /// Return the element representing the built-in class `Future`.
  @experimental
  ClassElement2 get futureElement2;

  /// Return the type representing `Future<Null>`.
  InterfaceType get futureNullType;

  /// Return the element representing the built-in class `FutureOr`.
  ClassElement get futureOrElement;

  /// Return the element representing the built-in class `FutureOr`.
  @experimental
  ClassElement2 get futureOrElement2;

  /// Return the type representing `FutureOr<Null>`.
  InterfaceType get futureOrNullType;

  /// Return the element representing the built-in class `int`.
  ClassElement get intElement;

  /// Return the element representing the built-in class `int`.
  @experimental
  ClassElement2 get intElement2;

  /// Return the type representing the built-in type `int`.
  InterfaceType get intType;

  /// Return the type representing the type `Iterable<dynamic>`.
  InterfaceType get iterableDynamicType;

  /// Return the element representing the built-in class `Iterable`.
  ClassElement get iterableElement;

  /// Return the element representing the built-in class `Iterable`.
  @experimental
  ClassElement2 get iterableElement2;

  /// Return the type representing the type `Iterable<Object>`.
  InterfaceType get iterableObjectType;

  /// Return the element representing the built-in class `List`.
  ClassElement get listElement;

  /// Return the element representing the built-in class `List`.
  @experimental
  ClassElement2 get listElement2;

  /// Return the element representing the built-in class `Map`.
  ClassElement get mapElement;

  /// Return the element representing the built-in class `Map`.
  @experimental
  ClassElement2 get mapElement2;

  /// Return the type representing `Map<Object, Object>`.
  InterfaceType get mapObjectObjectType;

  /// Return the type representing the built-in type `Never`.
  NeverType get neverType;

  /// Return the element representing the built-in class `Null`.
  ClassElement get nullElement;

  /// Return the element representing the built-in class `Null`.
  @experimental
  ClassElement2 get nullElement2;

  /// Return the type representing the built-in type `Null`.
  InterfaceType get nullType;

  /// Return the element representing the built-in class `num`.
  ClassElement get numElement;

  /// Return the element representing the built-in class `num`.
  @experimental
  ClassElement2 get numElement2;

  /// Return the type representing the built-in type `num`.
  InterfaceType get numType;

  /// Return the element representing the built-in class `Object`.
  ClassElement get objectElement;

  /// Return the element representing the built-in class `Object`.
  @experimental
  ClassElement2 get objectElement2;

  /// Return the type representing the built-in type `Object?`.
  InterfaceType get objectQuestionType;

  /// Return the type representing the built-in type `Object`.
  InterfaceType get objectType;

  /// Return the element representing the built-in class `Record`.
  ClassElement get recordElement;

  /// Return the element representing the built-in class `Record`.
  @experimental
  ClassElement2 get recordElement2;

  /// Return the type representing the built-in type `Record`.
  InterfaceType get recordType;

  /// Return the element representing the built-in class `Set`.
  ClassElement get setElement;

  /// Return the element representing the built-in class `Set`.
  @experimental
  ClassElement2 get setElement2;

  /// Return the type representing the built-in type `StackTrace`.
  InterfaceType get stackTraceType;

  /// Return the type representing `Stream<dynamic>`.
  InterfaceType get streamDynamicType;

  /// Return the element representing the built-in class `Stream`.
  ClassElement get streamElement;

  /// Return the element representing the built-in class `Stream`.
  @experimental
  ClassElement2 get streamElement2;

  /// Return the element representing the built-in class `String`.
  ClassElement get stringElement;

  /// Return the element representing the built-in class `String`.
  @experimental
  ClassElement2 get stringElement2;

  /// Return the type representing the built-in type `String`.
  InterfaceType get stringType;

  /// Return the element representing the built-in class `Symbol`.
  ClassElement get symbolElement;

  /// Return the element representing the built-in class `Symbol`.
  @experimental
  ClassElement2 get symbolElement2;

  /// Return the type representing the built-in type `Symbol`.
  InterfaceType get symbolType;

  /// Return the type representing the built-in type `Type`.
  InterfaceType get typeType;

  /// Return the type representing the built-in type `void`.
  VoidType get voidType;

  /// Return the instantiation of the built-in class `FutureOr` with the
  /// given [valueType]. The type has the nullability suffix of this provider.
  InterfaceType futureOrType(DartType valueType);

  /// Return the instantiation of the built-in class `Future` with the
  /// given [valueType]. The type has the nullability suffix of this provider.
  InterfaceType futureType(DartType valueType);

  /// Return `true` if [element] cannot be extended, implemented, or mixed in.
  bool isNonSubtypableClass(InterfaceElement element);

  /// Return 'true' if [id] is the name of a getter on the `Object` type.
  bool isObjectGetter(String id);

  /// Return 'true' if [id] is the name of a method or getter on the `Object`
  /// type.
  bool isObjectMember(String id);

  /// Return 'true' if [id] is the name of a method on the `Object` type.
  bool isObjectMethod(String id);

  /// Return the instantiation of the built-in class `Iterable` with the
  /// given [elementType]. The type has the nullability suffix of this provider.
  InterfaceType iterableType(DartType elementType);

  /// Return the instantiation of the built-in class `List` with the
  /// given [elementType]. The type has the nullability suffix of this provider.
  InterfaceType listType(DartType elementType);

  /// Return the instantiation of the built-in class `List` with the
  /// given [keyType] and [valueType]. The type has the nullability suffix of
  /// this provider.
  InterfaceType mapType(DartType keyType, DartType valueType);

  /// Return the instantiation of the built-in class `Set` with the
  /// given [elementType]. The type has the nullability suffix of this provider.
  InterfaceType setType(DartType elementType);

  /// Return the instantiation of the built-in class `Stream` with the
  /// given [elementType]. The type has the nullability suffix of this provider.
  InterfaceType streamType(DartType elementType);
}
