// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/type_inference/type_schema.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_elimination.dart'
    as typeSchemaElimination;
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeSchemaEliminationTest);
  });
}

@reflectiveTest
class TypeSchemaEliminationTest {
  static const DartType unknownType = const UnknownType();

  CoreTypes coreTypes = new _MockCoreTypes();

  DartType get dynamicType => const DynamicType();

  DartType get nullType => coreTypes.nullClass.rawType;

  DartType get objectType => coreTypes.objectClass.rawType;

  DartType greatestClosure(DartType schema) =>
      typeSchemaElimination.greatestClosure(coreTypes, schema);

  DartType leastClosure(DartType schema) =>
      typeSchemaElimination.leastClosure(coreTypes, schema);

  void test_greatestClosure_contravariant() {
    expect(
        greatestClosure(new FunctionType([unknownType], dynamicType))
            .toString(),
        '(dart.core::Null) → dynamic');
    expect(
        greatestClosure(new FunctionType([], dynamicType,
            namedParameters: [new NamedType('foo', unknownType)])).toString(),
        '({foo: dart.core::Null}) → dynamic');
  }

  void test_greatestClosure_contravariant_contravariant() {
    expect(
        greatestClosure(new FunctionType([
          new FunctionType([unknownType], dynamicType)
        ], dynamicType))
            .toString(),
        '((dynamic) → dynamic) → dynamic');
  }

  void test_greatestClosure_covariant() {
    expect(greatestClosure(new FunctionType([], unknownType)).toString(),
        '() → dynamic');
    expect(
        greatestClosure(new InterfaceType(coreTypes.listClass, [unknownType]))
            .toString(),
        'dart.core::List<dynamic>');
  }

  void test_greatestClosure_function_multipleUnknown() {
    expect(
        greatestClosure(new FunctionType(
            [unknownType, unknownType], unknownType,
            namedParameters: [
              new NamedType('a', unknownType),
              new NamedType('b', unknownType)
            ])).toString(),
        '(dart.core::Null, dart.core::Null, {a: dart.core::Null, '
        'b: dart.core::Null}) → dynamic');
  }

  void test_greatestClosure_simple() {
    expect(greatestClosure(unknownType).toString(), 'dynamic');
  }

  void test_leastClosure_contravariant() {
    expect(
        leastClosure(new FunctionType([unknownType], dynamicType)).toString(),
        '(dynamic) → dynamic');
    expect(
        leastClosure(new FunctionType([], dynamicType,
            namedParameters: [new NamedType('foo', unknownType)])).toString(),
        '({foo: dynamic}) → dynamic');
  }

  void test_leastClosure_contravariant_contravariant() {
    expect(
        leastClosure(new FunctionType([
          new FunctionType([unknownType], dynamicType)
        ], dynamicType))
            .toString(),
        '((dart.core::Null) → dynamic) → dynamic');
  }

  void test_leastClosure_covariant() {
    expect(leastClosure(new FunctionType([], unknownType)).toString(),
        '() → dart.core::Null');
    expect(
        leastClosure(new InterfaceType(coreTypes.listClass, [unknownType]))
            .toString(),
        'dart.core::List<dart.core::Null>');
  }

  void test_leastClosure_function_multipleUnknown() {
    expect(
        leastClosure(new FunctionType([unknownType, unknownType], unknownType,
            namedParameters: [
              new NamedType('a', unknownType),
              new NamedType('b', unknownType)
            ])).toString(),
        '(dynamic, dynamic, {a: dynamic, b: dynamic}) → dart.core::Null');
  }

  void test_leastClosure_simple() {
    expect(leastClosure(unknownType).toString(), 'dart.core::Null');
  }
}

class _MockCoreTypes implements CoreTypes {
  @override
  final Class listClass = new Class(name: 'List');

  @override
  final Class nullClass = new Class(name: 'Null');

  @override
  final Class objectClass = new Class(name: 'Object');

  _MockCoreTypes() {
    new Library(Uri.parse('dart:core'),
        name: 'dart.core', classes: [listClass, nullClass, objectClass]);
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
