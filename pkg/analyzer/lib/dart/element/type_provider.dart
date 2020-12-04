// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// The interface `TypeProvider` defines the behavior of objects that provide
/// access to types defined by the language.
///
/// Clients may not extend, implement or mix-in this class.
abstract class TypeProvider {
  /// Return the element representing the built-in class 'bool'.
  ClassElement get boolElement;

  /// Return the type representing the built-in type 'bool'.
  InterfaceType get boolType;

  /// Return the type representing the type 'bottom'.
  DartType get bottomType;

  /// Return the type representing the built-in type 'Deprecated'.
  InterfaceType get deprecatedType;

  /// Return the element representing the built-in class 'double'.
  ClassElement get doubleElement;

  /// Return the type representing the built-in type 'double'.
  InterfaceType get doubleType;

  /// Return the type representing the built-in type 'dynamic'.
  DartType get dynamicType;

  /// Return the type representing the built-in type 'Function'.
  InterfaceType get functionType;

  /// Return the type representing 'Future<dynamic>'.
  InterfaceType get futureDynamicType;

  /// Return the element representing the built-in class 'Future'.
  ClassElement get futureElement;

  /// Return the type representing 'Future<Null>'.
  InterfaceType get futureNullType;

  /// Return the element representing the built-in class 'FutureOr'.
  ClassElement get futureOrElement;

  /// Return the type representing 'FutureOr<Null>'.
  InterfaceType get futureOrNullType;

  /// Return the element representing the built-in class 'int'.
  ClassElement get intElement;

  /// Return the type representing the built-in type 'int'.
  InterfaceType get intType;

  /// Return the type representing the type 'Iterable<dynamic>'.
  InterfaceType get iterableDynamicType;

  /// Return the element representing the built-in class 'Iterable'.
  ClassElement get iterableElement;

  /// Return the type representing the type 'Iterable<Object>'.
  InterfaceType get iterableObjectType;

  /// Return the element representing the built-in class 'List'.
  ClassElement get listElement;

  /// Return the element representing the built-in class 'Map'.
  ClassElement get mapElement;

  /// Return the type representing 'Map<Object, Object>'.
  InterfaceType get mapObjectObjectType;

  /// Return the type representing the built-in type 'Never'.
  DartType get neverType;

  /// Return a list containing all of the types that cannot be either extended
  /// or implemented.
  Set<ClassElement> get nonSubtypableClasses;

  /// Return the element representing the built-in class 'null'.
  ClassElement get nullElement;

  /// Return the type representing the built-in type 'Null'.
  InterfaceType get nullType;

  /// Return the element representing the built-in class 'num'.
  ClassElement get numElement;

  /// Return the type representing the built-in type 'num'.
  InterfaceType get numType;

  /// Return the type representing the built-in type 'Object'.
  InterfaceType get objectType;

  /// Return the element representing the built-in class 'Set'.
  ClassElement get setElement;

  /// Return the type representing the built-in type 'StackTrace'.
  InterfaceType get stackTraceType;

  /// Return the type representing 'Stream<dynamic>'.
  InterfaceType get streamDynamicType;

  /// Return the element representing the built-in class 'Stream'.
  ClassElement get streamElement;

  /// Return the element representing the built-in class 'String'.
  ClassElement get stringElement;

  /// Return the type representing the built-in type 'String'.
  InterfaceType get stringType;

  /// Return the element representing the built-in class 'Symbol'.
  ClassElement get symbolElement;

  /// Return the type representing the built-in type 'Symbol'.
  InterfaceType get symbolType;

  /// Return the type representing the built-in type 'Type'.
  InterfaceType get typeType;

  /// Return the type representing the built-in type `void`.
  VoidType get voidType;

  /// Return the instantiation of the built-in class 'FutureOr' with the
  /// given [valueType]. The type has the nullability suffix of this provider.
  InterfaceType futureOrType2(DartType valueType);

  /// Return the instantiation of the built-in class 'Future' with the
  /// given [valueType]. The type has the nullability suffix of this provider.
  InterfaceType futureType2(DartType valueType);

  /// Return 'true' if [id] is the name of a getter on
  /// the Object type.
  bool isObjectGetter(String id);

  /// Return 'true' if [id] is the name of a method or getter on
  /// the Object type.
  bool isObjectMember(String id);

  /// Return 'true' if [id] is the name of a method on
  /// the Object type.
  bool isObjectMethod(String id);

  /// Return the instantiation of the built-in class 'Iterable' with the
  /// given [elementType]. The type has the nullability suffix of this provider.
  InterfaceType iterableType2(DartType elementType);

  /// Return the instantiation of the built-in class 'List' with the
  /// given [elementType]. The type has the nullability suffix of this provider.
  InterfaceType listType2(DartType elementType);

  /// Return the instantiation of the built-in class 'List' with the
  /// given [keyType] and [valueType]. The type has the nullability suffix of
  /// this provider.
  InterfaceType mapType2(DartType keyType, DartType valueType);

  /// Return the instantiation of the built-in class 'Set' with the
  /// given [elementType]. The type has the nullability suffix of this provider.
  InterfaceType setType2(DartType elementType);

  /// Return the instantiation of the built-in class 'Stream' with the
  /// given [elementType]. The type has the nullability suffix of this provider.
  InterfaceType streamType2(DartType elementType);
}
