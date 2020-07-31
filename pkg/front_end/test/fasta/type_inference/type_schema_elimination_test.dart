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

  DartType get nullType => coreTypes.nullType;

  DartType get objectType => coreTypes.objectLegacyRawType;

  DartType greatestClosure(DartType schema) {
    return typeSchemaElimination.greatestClosure(schema, dynamicType, nullType);
  }

  DartType leastClosure(DartType schema) {
    return typeSchemaElimination.leastClosure(schema, dynamicType, nullType);
  }

  void test_greatestClosure_contravariant() {
    expect(
        greatestClosure(new FunctionType(
                [unknownType], dynamicType, Nullability.legacy))
            .leakingDebugToString(),
        '(dart.core::Null?) →* dynamic');
    expect(
        greatestClosure(new FunctionType([], dynamicType, Nullability.legacy,
                namedParameters: [new NamedType('foo', unknownType)]))
            .leakingDebugToString(),
        '({foo: dart.core::Null?}) →* dynamic');
  }

  void test_greatestClosure_contravariant_contravariant() {
    expect(
        greatestClosure(new FunctionType([
          new FunctionType([unknownType], dynamicType, Nullability.legacy)
        ], dynamicType, Nullability.legacy))
            .leakingDebugToString(),
        '((dynamic) →* dynamic) →* dynamic');
  }

  void test_greatestClosure_covariant() {
    expect(
        greatestClosure(new FunctionType([], unknownType, Nullability.legacy))
            .leakingDebugToString(),
        '() →* dynamic');
    expect(
        greatestClosure(new InterfaceType(
                coreTypes.listClass, Nullability.legacy, [unknownType]))
            .leakingDebugToString(),
        'dart.core::List<dynamic>*');
  }

  void test_greatestClosure_function_multipleUnknown() {
    expect(
        greatestClosure(new FunctionType(
            [unknownType, unknownType], unknownType, Nullability.legacy,
            namedParameters: [
              new NamedType('a', unknownType),
              new NamedType('b', unknownType)
            ])).leakingDebugToString(),
        '(dart.core::Null?, dart.core::Null?, {a: dart.core::Null?, '
        'b: dart.core::Null?}) →* dynamic');
  }

  void test_greatestClosure_simple() {
    expect(greatestClosure(unknownType).leakingDebugToString(), 'dynamic');
  }

  void test_leastClosure_contravariant() {
    expect(
        leastClosure(new FunctionType(
                [unknownType], dynamicType, Nullability.legacy))
            .leakingDebugToString(),
        '(dynamic) →* dynamic');
    expect(
        leastClosure(new FunctionType([], dynamicType, Nullability.legacy,
                namedParameters: [new NamedType('foo', unknownType)]))
            .leakingDebugToString(),
        '({foo: dynamic}) →* dynamic');
  }

  void test_leastClosure_contravariant_contravariant() {
    expect(
        leastClosure(new FunctionType([
          new FunctionType([unknownType], dynamicType, Nullability.legacy)
        ], dynamicType, Nullability.legacy))
            .leakingDebugToString(),
        '((dart.core::Null?) →* dynamic) →* dynamic');
  }

  void test_leastClosure_covariant() {
    expect(
        leastClosure(new FunctionType([], unknownType, Nullability.legacy))
            .leakingDebugToString(),
        '() →* dart.core::Null?');
    expect(
        leastClosure(new InterfaceType(
                coreTypes.listClass, Nullability.legacy, [unknownType]))
            .leakingDebugToString(),
        'dart.core::List<dart.core::Null?>*');
  }

  void test_leastClosure_function_multipleUnknown() {
    expect(
        leastClosure(new FunctionType(
            [unknownType, unknownType], unknownType, Nullability.legacy,
            namedParameters: [
              new NamedType('a', unknownType),
              new NamedType('b', unknownType)
            ])).leakingDebugToString(),
        '(dynamic, dynamic, {a: dynamic, b: dynamic}) →* dart.core::Null?');
  }

  void test_leastClosure_simple() {
    expect(
        leastClosure(unknownType).leakingDebugToString(), 'dart.core::Null?');
  }
}

class _MockCoreTypes implements CoreTypes {
  @override
  final Class listClass = new Class(name: 'List');

  @override
  final Class nullClass = new Class(name: 'Null');

  @override
  final Class objectClass = new Class(name: 'Object');

  @override
  InterfaceType nullType;

  _MockCoreTypes() {
    nullType = new InterfaceType(
        nullClass, Nullability.nullable, const <DynamicType>[]);
    new Library(Uri.parse('dart:core'),
        name: 'dart.core', classes: [listClass, nullClass, objectClass]);
  }

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
