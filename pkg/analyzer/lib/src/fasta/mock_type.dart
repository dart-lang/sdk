// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer.mock_type;

import 'package:analyzer/dart/element/element.dart';

import 'package:analyzer/dart/element/type.dart';

import 'package:analyzer/src/generated/type_system.dart' show TypeSystem;

import 'package:front_end/src/fasta/problems.dart' show unsupported;

abstract class MockType extends DartType {
  String get displayName => unsupported("displayName", -1, null);

  Element get element => unsupported("element", -1, null);

  bool get isBottom => unsupported("isBottom", -1, null);

  bool get isDartAsyncFuture => unsupported("isDartAsyncFuture", -1, null);

  bool get isDartAsyncFutureOr => unsupported("isDartAsyncFutureOr", -1, null);

  bool get isDartCoreFunction => unsupported("isDartCoreFunction", -1, null);

  bool get isDynamic => unsupported("isDynamic", -1, null);

  bool get isObject => unsupported("isObject", -1, null);

  bool get isUndefined => unsupported("isUndefined", -1, null);

  bool get isVoid => unsupported("isVoid", -1, null);

  String get name => unsupported("name", -1, null);

  DartType flattenFutures(TypeSystem typeSystem) {
    return unsupported("flattenFutures", -1, null);
  }

  bool isAssignableTo(DartType type) => unsupported("isAssignableTo", -1, null);

  bool isMoreSpecificThan(DartType type) =>
      unsupported("isMoreSpecificThan", -1, null);

  bool isSubtypeOf(DartType type) => unsupported("isSubtypeOf", -1, null);

  bool isSupertypeOf(DartType type) => unsupported("isSupertypeOf", -1, null);

  DartType resolveToBound(DartType objectType) {
    return unsupported("resolveToBound", -1, null);
  }

  DartType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes) {
    return unsupported("substitute2", -1, null);
  }

  List<DartType> get typeArguments {
    return unsupported("typeArguments", -1, null);
  }

  List<TypeParameterElement> get typeParameters {
    return unsupported("typeParameters", -1, null);
  }

  ParameterizedType instantiate(List<DartType> argumentTypes) {
    return unsupported("instantiate", -1, null);
  }
}

abstract class MockInterfaceType extends MockType implements InterfaceType {
  ClassElement get element => unsupported("element", -1, null);

  List<PropertyAccessorElement> get accessors {
    return unsupported("accessors", -1, null);
  }

  List<ConstructorElement> get constructors {
    return unsupported("constructors", -1, null);
  }

  List<InterfaceType> get interfaces {
    return unsupported("interfaces", -1, null);
  }

  List<MethodElement> get methods {
    return unsupported("methods", -1, null);
  }

  List<InterfaceType> get mixins {
    return unsupported("mixins", -1, null);
  }

  InterfaceType get superclass => unsupported("superclass", -1, null);

  PropertyAccessorElement getGetter(String name) {
    return unsupported(" PropertyAccessorElement getGetter", -1, null);
  }

  MethodElement getMethod(String name) {
    return unsupported("getMethod", -1, null);
  }

  PropertyAccessorElement getSetter(String name) {
    return unsupported(" PropertyAccessorElement getSetter", -1, null);
  }

  bool isDirectSupertypeOf(InterfaceType type) {
    return unsupported("isDirectSupertypeOf", -1, null);
  }

  ConstructorElement lookUpConstructor(String name, LibraryElement library) {
    return unsupported(" ConstructorElement lookUpConstructor", -1, null);
  }

  PropertyAccessorElement lookUpGetter(String name, LibraryElement library) {
    return unsupported(" PropertyAccessorElement lookUpGetter", -1, null);
  }

  PropertyAccessorElement lookUpGetterInSuperclass(
      String name, LibraryElement library) {
    return unsupported("lookUpGetterInSuperclass", -1, null);
  }

  PropertyAccessorElement lookUpInheritedGetter(String name,
      {LibraryElement library, bool thisType: true}) {
    return unsupported(
        " PropertyAccessorElement lookUpInheritedGetter", -1, null);
  }

  ExecutableElement lookUpInheritedGetterOrMethod(String name,
      {LibraryElement library}) {
    return unsupported("lookUpInheritedGetterOrMethod", -1, null);
  }

  MethodElement lookUpInheritedMethod(String name,
      {LibraryElement library, bool thisType: true}) {
    return unsupported(" MethodElement lookUpInheritedMethod", -1, null);
  }

  PropertyAccessorElement lookUpInheritedSetter(String name,
      {LibraryElement library, bool thisType: true}) {
    return unsupported(
        " PropertyAccessorElement lookUpInheritedSetter", -1, null);
  }

  MethodElement lookUpMethod(String name, LibraryElement library) {
    return unsupported("lookUpMethod", -1, null);
  }

  MethodElement lookUpMethodInSuperclass(String name, LibraryElement library) {
    return unsupported(" MethodElement lookUpMethodInSuperclass", -1, null);
  }

  PropertyAccessorElement lookUpSetter(String name, LibraryElement library) {
    return unsupported(" PropertyAccessorElement lookUpSetter", -1, null);
  }

  PropertyAccessorElement lookUpSetterInSuperclass(
      String name, LibraryElement library) {
    return unsupported("lookUpSetterInSuperclass", -1, null);
  }

  InterfaceType instantiate(List<DartType> argumentTypes) {
    return unsupported("instantiate", -1, null);
  }

  InterfaceType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes) {
    return unsupported("substitute2", -1, null);
  }

  InterfaceType substitute4(List<DartType> argumentTypes) {
    return unsupported("substitute4", -1, null);
  }

  get isDartCoreNull => unsupported("isDartCoreNull", -1, null);
}
