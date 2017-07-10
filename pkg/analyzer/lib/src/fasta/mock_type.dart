// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer.mock_type;

import 'package:analyzer/dart/element/element.dart';

import 'package:analyzer/dart/element/type.dart';

import 'package:analyzer/src/generated/type_system.dart' show TypeSystem;

import 'package:front_end/src/fasta/deprecated_problems.dart'
    show deprecated_internalProblem;

abstract class MockType extends DartType {
  String get displayName => deprecated_internalProblem("not supported.");

  Element get element => deprecated_internalProblem("not supported.");

  bool get isBottom => deprecated_internalProblem("not supported.");

  bool get isDartAsyncFuture => deprecated_internalProblem("not supported.");

  bool get isDartAsyncFutureOr => deprecated_internalProblem("not supported.");

  bool get isDartCoreFunction => deprecated_internalProblem("not supported.");

  bool get isDynamic => deprecated_internalProblem("not supported.");

  bool get isObject => deprecated_internalProblem("not supported.");

  bool get isUndefined => deprecated_internalProblem("not supported.");

  bool get isVoid => deprecated_internalProblem("not supported.");

  String get name => deprecated_internalProblem("not supported.");

  DartType flattenFutures(TypeSystem typeSystem) {
    return deprecated_internalProblem("not supported.");
  }

  bool isAssignableTo(DartType type) =>
      deprecated_internalProblem("not supported.");

  bool isMoreSpecificThan(DartType type) =>
      deprecated_internalProblem("not supported.");

  bool isSubtypeOf(DartType type) =>
      deprecated_internalProblem("not supported.");

  bool isSupertypeOf(DartType type) =>
      deprecated_internalProblem("not supported.");

  DartType resolveToBound(DartType objectType) {
    return deprecated_internalProblem("not supported.");
  }

  DartType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes) {
    return deprecated_internalProblem("not supported.");
  }

  List<DartType> get typeArguments =>
      deprecated_internalProblem("not supported.");

  List<TypeParameterElement> get typeParameters {
    return deprecated_internalProblem("not supported.");
  }

  ParameterizedType instantiate(List<DartType> argumentTypes) {
    return deprecated_internalProblem("not supported.");
  }
}

abstract class MockInterfaceType extends MockType implements InterfaceType {
  ClassElement get element => deprecated_internalProblem("not supported.");

  List<PropertyAccessorElement> get accessors {
    return deprecated_internalProblem("not supported.");
  }

  List<ConstructorElement> get constructors =>
      deprecated_internalProblem("not supported.");

  List<InterfaceType> get interfaces =>
      deprecated_internalProblem("not supported.");

  List<MethodElement> get methods =>
      deprecated_internalProblem("not supported.");

  List<InterfaceType> get mixins =>
      deprecated_internalProblem("not supported.");

  InterfaceType get superclass => deprecated_internalProblem("not supported.");

  PropertyAccessorElement getGetter(String name) {
    return deprecated_internalProblem("not supported.");
  }

  MethodElement getMethod(String name) =>
      deprecated_internalProblem("not supported.");

  PropertyAccessorElement getSetter(String name) {
    return deprecated_internalProblem("not supported.");
  }

  bool isDirectSupertypeOf(InterfaceType type) {
    return deprecated_internalProblem("not supported.");
  }

  ConstructorElement lookUpConstructor(String name, LibraryElement library) {
    return deprecated_internalProblem("not supported.");
  }

  PropertyAccessorElement lookUpGetter(String name, LibraryElement library) {
    return deprecated_internalProblem("not supported.");
  }

  PropertyAccessorElement lookUpGetterInSuperclass(
          String name, LibraryElement library) =>
      deprecated_internalProblem("not supported.");

  PropertyAccessorElement lookUpInheritedGetter(String name,
      {LibraryElement library, bool thisType: true}) {
    return deprecated_internalProblem("not supported.");
  }

  ExecutableElement lookUpInheritedGetterOrMethod(String name,
          {LibraryElement library}) =>
      deprecated_internalProblem("not supported.");

  MethodElement lookUpInheritedMethod(String name,
      {LibraryElement library, bool thisType: true}) {
    return deprecated_internalProblem("not supported.");
  }

  PropertyAccessorElement lookUpInheritedSetter(String name,
      {LibraryElement library, bool thisType: true}) {
    return deprecated_internalProblem("not supported.");
  }

  MethodElement lookUpMethod(String name, LibraryElement library) {
    return deprecated_internalProblem("not supported.");
  }

  MethodElement lookUpMethodInSuperclass(String name, LibraryElement library) {
    return deprecated_internalProblem("not supported.");
  }

  PropertyAccessorElement lookUpSetter(String name, LibraryElement library) {
    return deprecated_internalProblem("not supported.");
  }

  PropertyAccessorElement lookUpSetterInSuperclass(
          String name, LibraryElement library) =>
      deprecated_internalProblem("not supported.");

  InterfaceType instantiate(List<DartType> argumentTypes) {
    return deprecated_internalProblem("not supported.");
  }

  InterfaceType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes) {
    return deprecated_internalProblem("not supported.");
  }

  InterfaceType substitute4(List<DartType> argumentTypes) {
    return deprecated_internalProblem("not supported.");
  }

  get isDartCoreNull => deprecated_internalProblem("not supported.");
}
