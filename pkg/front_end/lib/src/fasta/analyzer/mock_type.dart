// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer.mock_type;

import 'package:analyzer/dart/element/element.dart';

import 'package:analyzer/dart/element/type.dart';

import 'package:analyzer/src/generated/type_system.dart' show TypeSystem;

import '../errors.dart' show
    internalError;

abstract class MockType extends DartType {
  String get displayName => internalError("not supported.");

  Element get element => internalError("not supported.");

  bool get isBottom => internalError("not supported.");

  bool get isDartAsyncFuture => internalError("not supported.");

  bool get isDartAsyncFutureOr => internalError("not supported.");

  bool get isDartCoreFunction => internalError("not supported.");

  bool get isDynamic => internalError("not supported.");

  bool get isObject => internalError("not supported.");

  bool get isUndefined => internalError("not supported.");

  bool get isVoid => internalError("not supported.");

  String get name => internalError("not supported.");

  DartType flattenFutures(TypeSystem typeSystem) => internalError("not supported.");

  bool isAssignableTo(DartType type) => internalError("not supported.");

  bool isMoreSpecificThan(DartType type) => internalError("not supported.");

  bool isSubtypeOf(DartType type) => internalError("not supported.");

  bool isSupertypeOf(DartType type) => internalError("not supported.");

  DartType resolveToBound(DartType objectType) => internalError("not supported.");

  DartType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes) => internalError("not supported.");

  List<DartType> get typeArguments => internalError("not supported.");

  List<TypeParameterElement> get typeParameters => internalError("not supported.");

  ParameterizedType instantiate(List<DartType> argumentTypes) => internalError("not supported.");
}

abstract class MockInterfaceType extends MockType implements InterfaceType {
  List<PropertyAccessorElement> get accessors => internalError("not supported.");

  List<ConstructorElement> get constructors => internalError("not supported.");

  List<InterfaceType> get interfaces => internalError("not supported.");

  List<MethodElement> get methods => internalError("not supported.");

  List<InterfaceType> get mixins => internalError("not supported.");

  InterfaceType get superclass => internalError("not supported.");

  PropertyAccessorElement getGetter(String name) => internalError("not supported.");

  MethodElement getMethod(String name) => internalError("not supported.");

  PropertyAccessorElement getSetter(String name) => internalError("not supported.");

  bool isDirectSupertypeOf(InterfaceType type) => internalError("not supported.");


  ConstructorElement lookUpConstructor(String name, LibraryElement library) => internalError("not supported.");

  PropertyAccessorElement lookUpGetter(String name, LibraryElement library) => internalError("not supported.");

  PropertyAccessorElement lookUpGetterInSuperclass(
      String name, LibraryElement library) => internalError("not supported.");

  PropertyAccessorElement lookUpInheritedGetter(String name,
      {LibraryElement library, bool thisType: true}) => internalError("not supported.");

  ExecutableElement lookUpInheritedGetterOrMethod(String name,
      {LibraryElement library}) => internalError("not supported.");

  MethodElement lookUpInheritedMethod(String name,
      {LibraryElement library, bool thisType: true}) => internalError("not supported.");

  PropertyAccessorElement lookUpInheritedSetter(String name,
      {LibraryElement library, bool thisType: true}) => internalError("not supported.");

  MethodElement lookUpMethod(String name, LibraryElement library) => internalError("not supported.");

  MethodElement lookUpMethodInSuperclass(String name, LibraryElement library) => internalError("not supported.");

  PropertyAccessorElement lookUpSetter(String name, LibraryElement library) => internalError("not supported.");

  PropertyAccessorElement lookUpSetterInSuperclass(
      String name, LibraryElement library) => internalError("not supported.");

  InterfaceType substitute4(List<DartType> argumentTypes) => internalError("not supported.");

  get isDartCoreNull => internalError("not supported.");
}
