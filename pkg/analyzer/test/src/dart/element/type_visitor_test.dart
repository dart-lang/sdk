// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';
import 'string_types.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveTypeVisitorTest);
  });
}

@reflectiveTest
class RecursiveTypeVisitorTest extends AbstractTypeSystemTest with StringTypes {
  late final _MockRecursiveVisitor visitor;

  @override
  void setUp() {
    super.setUp();
    visitor = _MockRecursiveVisitor();
    defineStringTypes();
  }

  void test_callsDefaultBehavior() {
    expect(parseType('int').accept(visitor), true);
    visitor.assertVisitedType(parseType('int'));
  }

  void test_functionType_complex() {
    var type = parseFunctionType(
      'dynamic Function<T extends int, K extends String>('
      'num, double, {void c, Object d})',
    );
    expect(type.accept(visitor), true);
    visitor.assertVisitedTypes([
      parseType('dynamic'),
      parseType('int'),
      parseType('String'),
      parseType('num'),
      parseType('double'),
      parseType('void'),
      parseType('Object'),
    ]);
  }

  void test_functionType_positionalParameter() {
    var type = parseFunctionType('dynamic Function([int])');
    expect(type.accept(visitor), true);
    visitor.assertVisitedType(parseType('int'));
  }

  void test_functionType_returnType() {
    var type = parseFunctionType('int Function()');
    expect(type.accept(visitor), true);
    visitor.assertVisitedType(parseType('int'));
  }

  void test_functionType_typeFormal_bound() {
    var type = parseFunctionType('dynamic Function<T extends int>()');
    expect(type.accept(visitor), true);
    visitor.assertVisitedTypes([parseType('dynamic'), parseType('int')]);
  }

  void test_functionType_typeFormal_noBound() {
    var type = parseFunctionType('dynamic Function<T>()');
    expect(type.accept(visitor), true);
    visitor.assertVisitedType(parseType('dynamic'));
  }

  void test_interfaceType_typeParameter() {
    var type = typeProvider.listType(parseType('int'));
    expect(type.accept(visitor), true);
    visitor.assertVisitedType(parseType('int'));
  }

  void test_interfaceType_typeParameters() {
    var type = typeProvider.mapType(parseType('int'), parseType('String'));
    expect(type.accept(visitor), true);
    visitor.assertVisitedTypes([parseType('int'), parseType('String')]);
  }

  void test_interfaceType_typeParameters_nested() {
    var innerList = typeProvider.listType(parseType('int'));
    var outerList = typeProvider.listType(innerList);
    expect(outerList.accept(visitor), true);
    visitor.assertVisitedType(parseType('int'));
  }

  void test_recordType_named() {
    var type = typeOfString('({int f1, double f2})');
    expect(type.accept(visitor), true);
    visitor.assertVisitedType(parseType('int'));
    visitor.assertVisitedType(parseType('double'));
  }

  void test_recordType_named_dollarIdentifier() {
    var type = typeOfString(r'({int $1})');
    expect(type.accept(visitor), true);
    visitor.assertVisitedType(parseType('int'));
  }

  void test_recordType_positional() {
    var type = typeOfString('(int, double)');
    expect(type.accept(visitor), true);
    visitor.assertVisitedType(parseType('int'));
    visitor.assertVisitedType(parseType('double'));
  }

  void test_stopVisiting_first() {
    var type = parseFunctionType(
      'dynamic Function<T extends int, K extends String>('
      'num, double, {void c, Object d})',
    );
    visitor.stopOnType = parseType('dynamic');
    expect(type.accept(visitor), false);
    visitor.assertNotVisitedTypes([
      parseType('int'),
      parseType('String'),
      parseType('num'),
      parseType('double'),
      parseType('void'),
      parseType('Object'),
    ]);
  }

  void test_stopVisiting_halfway() {
    var type = parseFunctionType(
      'dynamic Function<T extends int, K extends String>('
      'num, double, {void c, Object d})',
    );
    visitor.stopOnType = parseType('int');
    expect(type.accept(visitor), false);
    visitor.assertNotVisitedTypes([
      parseType('String'),
      parseType('void'),
      parseType('Object'),
    ]);
  }

  void test_stopVisiting_nested() {
    var innerType = typeProvider.mapType(parseType('int'), parseType('String'));
    var outerList = typeProvider.listType(innerType);
    visitor.stopOnType = parseType('int');
    expect(outerList.accept(visitor), false);
    visitor.assertNotVisitedType(parseType('String'));
  }

  void test_stopVisiting_nested_parent() {
    var innerTypeStop = typeProvider.listType(parseType('int'));
    var innerTypeSkipped = typeProvider.listType(parseType('String'));
    var outerType = typeProvider.mapType(innerTypeStop, innerTypeSkipped);
    visitor.stopOnType = parseType('int');
    expect(outerType.accept(visitor), false);
    visitor.assertNotVisitedType(parseType('String'));
  }

  void test_stopVisiting_typeParameters() {
    var type = typeProvider.mapType(parseType('int'), parseType('String'));
    visitor.stopOnType = parseType('int');
    expect(type.accept(visitor), false);
    visitor.assertVisitedType(parseType('int'));
    visitor.assertNotVisitedType(parseType('String'));
  }
}

class _MockRecursiveVisitor extends RecursiveTypeVisitor {
  final Set<DartType> visitedTypes = {};
  DartType? stopOnType;

  _MockRecursiveVisitor() : super(includeTypeAliasArguments: false);

  void assertNotVisitedType(DartType type) {
    expect(visitedTypes, isNot(contains(type)));
  }

  void assertNotVisitedTypes(Iterable<DartType> types) =>
      types.forEach(assertNotVisitedType);

  void assertVisitedType(DartType type) {
    expect(visitedTypes, contains(type));
  }

  void assertVisitedTypes(Iterable<DartType> types) =>
      types.forEach(assertVisitedType);

  @override
  bool visitDartType(DartType type) {
    expect(type, isNotNull);
    visitedTypes.add(type);
    return type != stopOnType;
  }

  @override
  bool visitInterfaceType(InterfaceType type) {
    visitedTypes.add(type);
    if (type == stopOnType) {
      return false;
    }
    return super.visitInterfaceType(type);
  }
}
