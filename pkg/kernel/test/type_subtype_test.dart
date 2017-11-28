// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/src/incremental_class_hierarchy.dart';
import 'package:test/test.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';
import 'type_parser.dart';

/// Description of a small class hierarchy for use in subtype tests.
var classEnvironment = <String, List<String>>{
  'Comparable<T>': ['Object'],
  'num': ['Object', 'Comparable<num>'],
  'int': ['num'],
  'double': ['num'],
  'Iterable<T>': ['Object'],
  'List<T>': ['Iterable<T>'],
  'Future<T>': ['Object'],
  'FutureOr<T>': ['Object'],
};

List<TestCase> testCases = <TestCase>[
  subtype('int', 'num'),
  subtype('int', 'Comparable<num>'),
  subtype('int', 'Comparable<Object>'),
  subtype('int', 'Object'),
  subtype('double', 'num'),

  notSubtype('int', 'double'),
  notSubtype('int', 'Comparable<int>'),
  notSubtype('int', 'Iterable<int>'),
  notSubtype('Comparable<int>', 'Iterable<int>'),

  subtype('List<int>', 'List<int>'),
  subtype('List<int>', 'Iterable<int>'),
  subtype('List<int>', 'List<num>'),
  subtype('List<int>', 'Iterable<num>'),
  subtype('List<int>', 'List<Object>'),
  subtype('List<int>', 'Iterable<Object>'),
  subtype('List<int>', 'Object'),
  subtype('List<int>', 'List<Comparable<Object>>'),
  subtype('List<int>', 'List<Comparable<num>>'),
  subtype('List<int>', 'List<Comparable<Comparable<num>>>'),

  notSubtype('List<int>', 'List<double>'),
  notSubtype('List<int>', 'Iterable<double>'),
  notSubtype('List<int>', 'Comparable<int>'),
  notSubtype('List<int>', 'List<Comparable<int>>'),
  notSubtype('List<int>', 'List<Comparable<Comparable<int>>>'),

  subtype('(num) => num', '(int) => num'),
  subtype('(num) => int', '(num) => num'),
  subtype('(num) => int', '(int) => num'),
  notSubtype('(int) => int', '(num) => num'),

  subtype('(num) => (num) => num', '(num) => (int) => num'),
  notSubtype('(num) => (int) => int', '(num) => (num) => num'),

  subtype('(x:num) => num', '(x:int) => num'), // named parameters
  subtype('(num,x:num) => num', '(int,x:int) => num'),
  subtype('(x:num) => int', '(x:num) => num'),
  notSubtype('(x:int) => int', '(x:num) => num'),

  subtype('<E>(E) => int', '<E>(E) => num'), // type parameters
  subtype('<E>(num) => E', '<E>(int) => E'),
  subtype('<E>(E,num) => E', '<E>(E,int) => E'),
  notSubtype('<E>(E,num) => E', '<E>(E,E) => E'),

  subtype('<E>(E) => (E) => E', '<F>(F) => (F) => F'),
  subtype('<E>(E, (int,E) => E) => E', '<E>(E, (int,E) => E) => E'),
  subtype('<E>(E, (int,E) => E) => E', '<E>(E, (num,E) => E) => E'),
  notSubtype('<E,F>(E) => (F) => E', '<E>(E) => <F>(F) => E'),
  notSubtype('<E,F>(E) => (F) => E', '<F,E>(E) => (F) => E'),

  subtype('<E>(E,num) => E', '<E:num>(E,E) => E'),
  subtype('<E:num>(E) => int', '<E:int>(E) => int'),
  subtype('<E:num>(E) => E', '<E:int>(E) => E'),
  subtype('<E:num>(int) => E', '<E:int>(int) => E'),
  notSubtype('<E>(int) => int', '(int) => int'),
  notSubtype('<E,F>(int) => int', '<E>(int) => int'),

  subtype('<E:List<E>>(E) => E', '<F:List<F>>(F) => F'),
  subtype('<E:Iterable<E>>(E) => E', '<F:List<F>>(F) => F'),
  subtype('<E>(E,List<Object>) => E', '<F:List<F>>(F,F) => F'),
  notSubtype('<E>(E,List<Object>) => List<E>', '<F:List<F>>(F,F) => F'),
  notSubtype('<E>(E,List<Object>) => int', '<F:List<F>>(F,F) => F'),
  subtype('<E>(E,List<Object>) => E', '<F:List<F>>(F,F) => void'),

  subtype('int', 'FutureOr<int>', strongMode: true),
  subtype('int', 'FutureOr<num>', strongMode: true),
  subtype('Future<int>', 'FutureOr<int>', strongMode: true),
  subtype('Future<int>', 'FutureOr<num>', strongMode: true),
  subtype('Future<int>', 'FutureOr<Object>', strongMode: true),
  subtype('FutureOr<int>', 'FutureOr<int>', strongMode: true),
  subtype('FutureOr<int>', 'FutureOr<num>', strongMode: true),
  subtype('FutureOr<int>', 'Object', strongMode: true),
  notSubtype('int', 'FutureOr<double>', strongMode: true),
  notSubtype('FutureOr<double>', 'int', strongMode: true),
  notSubtype('FutureOr<int>', 'Future<num>', strongMode: true),
  notSubtype('FutureOr<int>', 'num', strongMode: true),

  // T & B <: T & A if B <: A
  subtype('T & int', 'T & int'),
  subtype('T & int', 'T & num'),
  subtype('T & num', 'T & num'),
  notSubtype('T & num', 'T & int'),

  // T & B <: T extends A if B <: A
  // (Trivially satisfied since promoted bounds are always a subtype of the
  // original bound)
  subtype('T & int', 'T', typeParameters: 'T: int'),
  subtype('T & int', 'T', typeParameters: 'T: num'),
  subtype('T & num', 'T', typeParameters: 'T: num'),

  // T extends B <: T & A if B <: A
  subtype('T', 'T & int', typeParameters: 'T: int'),
  subtype('T', 'T & num', typeParameters: 'T: int'),
  subtype('T', 'T & num', typeParameters: 'T: num'),
  notSubtype('T', 'T & int', typeParameters: 'T: num'),

  // T extends A <: T extends A
  subtype('T', 'T', typeParameters: 'T: num'),

  // S & B <: A if B <: A, A is not S (or a promotion thereof)
  subtype('S & int', 'int'),
  subtype('S & int', 'num'),
  subtype('S & num', 'num'),
  notSubtype('S & num', 'int'),
  notSubtype('S & num', 'T'),
  notSubtype('S & num', 'T & num'),

  // S extends B <: A if B <: A, A is not S (or a promotion thereof)
  subtype('S', 'int', typeParameters: 'S: int'),
  subtype('S', 'num', typeParameters: 'S: int'),
  subtype('S', 'num', typeParameters: 'S: num'),
  notSubtype('S', 'int', typeParameters: 'S: num'),
  notSubtype('S', 'T', typeParameters: 'S: num'),
  notSubtype('S', 'T & num', typeParameters: 'S: num'),
];

/// Assert that [subtype] is a subtype of [supertype], and that [supertype]
/// is not a subtype of [subtype] (unless the two strings are equal).
TestCase subtype(String subtype_, String supertype,
    {bool strongMode: false, String typeParameters}) {
  return new TestCase(subtype_, supertype,
      isSubtype: true, strongMode: strongMode, typeParameters: typeParameters);
}

/// Assert that neither type is a subtype of the other.
TestCase notSubtype(String subtype_, String supertype,
    {bool strongMode: false, String typeParameters}) {
  return new TestCase(subtype_, supertype,
      isSubtype: false, strongMode: strongMode, typeParameters: typeParameters);
}

class TestCase {
  String subtype;
  String supertype;
  String typeParameters;
  bool isSubtype;
  bool strongMode;

  TestCase(this.subtype, this.supertype,
      {this.isSubtype, this.strongMode: false, this.typeParameters});

  String toString() {
    var description =
        isSubtype ? '$subtype <: $supertype' : '$subtype </: $supertype';
    if (typeParameters != null) {
      description += ' (type parameters: $typeParameters)';
    }
    if (strongMode) {
      description += ' (strong mode)';
    }
    return description;
  }
}

class MockSubtypeTester extends SubtypeTester {
  ClassHierarchy hierarchy;
  InterfaceType objectType;
  InterfaceType nullType;
  InterfaceType rawFunctionType;
  Class futureClass;
  Class futureOrClass;
  LazyTypeEnvironment environment;
  bool strongMode = false;

  InterfaceType futureType(DartType type) =>
      new InterfaceType(futureClass, [type]);

  MockSubtypeTester(
      this.hierarchy,
      this.objectType,
      this.nullType,
      this.rawFunctionType,
      this.futureClass,
      this.futureOrClass,
      this.environment);
}

MockSubtypeTester makeSubtypeTester(Map<String, List<String>> testcase) {
  LazyTypeEnvironment environment = new LazyTypeEnvironment();
  Class objectClass = environment.lookup('Object');
  Class nullClass = environment.lookup('Null');
  Class functionClass = environment.lookup('Function');
  Class futureClass = environment.lookup('Future');
  Class futureOrClass = environment.lookup('FutureOr');
  functionClass.supertype = objectClass.asRawSupertype;
  for (var typeString in testcase.keys) {
    InterfaceType type = environment.parseFresh(typeString);
    Class class_ = type.classNode;
    for (TypeParameterType typeArg in type.typeArguments) {
      class_.typeParameters.add(typeArg.parameter);
    }
    for (var supertypeString in testcase[typeString]) {
      if (class_.supertype == null) {
        class_.supertype = environment.parseSuper(supertypeString);
      } else {
        class_.implementedTypes.add(environment.parseSuper(supertypeString));
      }
    }
  }
  var hierarchy = new IncrementalClassHierarchy();
  return new MockSubtypeTester(
      hierarchy,
      objectClass.rawType,
      nullClass.rawType,
      functionClass.rawType,
      futureClass,
      futureOrClass,
      environment);
}

main() {
  var tester = makeSubtypeTester(classEnvironment);
  for (var testCase in testCases) {
    test('$testCase', () {
      tester.strongMode = testCase.strongMode;
      var environment = tester.environment;
      environment.clearTypeParameters();
      if (testCase.typeParameters != null) {
        environment.setupTypeParameters(testCase.typeParameters);
      }
      var subtype = environment.parse(testCase.subtype);
      var supertype = environment.parse(testCase.supertype);
      if (tester.isSubtypeOf(subtype, supertype) != testCase.isSubtype) {
        fail('isSubtypeOf(${testCase.subtype}, ${testCase.supertype}) returned '
            '${!testCase.isSubtype} but should return ${testCase.isSubtype}');
      }
      if (subtype != supertype && tester.isSubtypeOf(supertype, subtype)) {
        fail('isSubtypeOf(${testCase.supertype}, ${testCase.subtype}) returned '
            'true but should return false');
      }
    });
  }
}
