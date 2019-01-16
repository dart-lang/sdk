// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  'Null': ['Object'],
};

List<TestCase> testCases = <TestCase>[
  subtype('int', 'num', legacyMode: true),
  subtype('int', 'Comparable<num>', legacyMode: true),
  subtype('int', 'Comparable<Object>', legacyMode: true),
  subtype('int', 'Object', legacyMode: true),
  subtype('double', 'num', legacyMode: true),

  notSubtype('int', 'double', legacyMode: true),
  notSubtype('int', 'Comparable<int>', legacyMode: true),
  notSubtype('int', 'Iterable<int>', legacyMode: true),
  notSubtype('Comparable<int>', 'Iterable<int>', legacyMode: true),

  subtype('List<int>', 'List<int>', legacyMode: true),
  subtype('List<int>', 'Iterable<int>', legacyMode: true),
  subtype('List<int>', 'List<num>', legacyMode: true),
  subtype('List<int>', 'Iterable<num>', legacyMode: true),
  subtype('List<int>', 'List<Object>', legacyMode: true),
  subtype('List<int>', 'Iterable<Object>', legacyMode: true),
  subtype('List<int>', 'Object', legacyMode: true),
  subtype('List<int>', 'List<Comparable<Object>>', legacyMode: true),
  subtype('List<int>', 'List<Comparable<num>>', legacyMode: true),
  subtype('List<int>', 'List<Comparable<Comparable<num>>>', legacyMode: true),

  notSubtype('List<int>', 'List<double>', legacyMode: true),
  notSubtype('List<int>', 'Iterable<double>', legacyMode: true),
  notSubtype('List<int>', 'Comparable<int>', legacyMode: true),
  notSubtype('List<int>', 'List<Comparable<int>>', legacyMode: true),
  notSubtype('List<int>', 'List<Comparable<Comparable<int>>>',
      legacyMode: true),

  subtype('(num) => num', '(int) => num', legacyMode: true),
  subtype('(num) => int', '(num) => num', legacyMode: true),
  subtype('(num) => int', '(int) => num', legacyMode: true),
  notSubtype('(int) => int', '(num) => num', legacyMode: true),

  subtype('(num) => (num) => num', '(num) => (int) => num', legacyMode: true),
  notSubtype('(num) => (int) => int', '(num) => (num) => num',
      legacyMode: true),

  subtype('(x:num) => num', '(x:int) => num',
      legacyMode: true), // named parameters
  subtype('(num,x:num) => num', '(int,x:int) => num', legacyMode: true),
  subtype('(x:num) => int', '(x:num) => num', legacyMode: true),
  notSubtype('(x:int) => int', '(x:num) => num', legacyMode: true),

  subtype('<E>(E) => int', '<E>(E) => num',
      legacyMode: true), // type parameters
  subtype('<E>(num) => E', '<E>(int) => E', legacyMode: true),
  subtype('<E>(E,num) => E', '<E>(E,int) => E', legacyMode: true),
  notSubtype('<E>(E,num) => E', '<E>(E,E) => E', legacyMode: true),

  subtype('<E>(E) => (E) => E', '<F>(F) => (F) => F', legacyMode: true),
  subtype('<E>(E, (int,E) => E) => E', '<E>(E, (int,E) => E) => E',
      legacyMode: true),
  subtype('<E>(E, (int,E) => E) => E', '<E>(E, (num,E) => E) => E',
      legacyMode: true),
  notSubtype('<E,F>(E) => (F) => E', '<E>(E) => <F>(F) => E', legacyMode: true),
  notSubtype('<E,F>(E) => (F) => E', '<F,E>(E) => (F) => E', legacyMode: true),

  notSubtype('<E>(E,num) => E', '<E:num>(E,E) => E', legacyMode: true),
  notSubtype('<E:num>(E) => int', '<E:int>(E) => int', legacyMode: true),
  notSubtype('<E:num>(E) => E', '<E:int>(E) => E', legacyMode: true),
  notSubtype('<E:num>(int) => E', '<E:int>(int) => E', legacyMode: true),
  subtype('<E:num>(E) => E', '<F:num>(F) => num', legacyMode: true),
  subtype('<E:int>(E) => E', '<F:int>(F) => num', legacyMode: true),
  subtype('<E:int>(E) => E', '<F:int>(F) => int', legacyMode: true),
  notSubtype('<E>(int) => int', '(int) => int', legacyMode: true),
  notSubtype('<E,F>(int) => int', '<E>(int) => int', legacyMode: true),

  subtype('<E:List<E>>(E) => E', '<F:List<F>>(F) => F', legacyMode: true),
  notSubtype('<E:Iterable<E>>(E) => E', '<F:List<F>>(F) => F',
      legacyMode: true),
  notSubtype('<E>(E,List<Object>) => E', '<F:List<F>>(F,F) => F',
      legacyMode: true),
  notSubtype('<E>(E,List<Object>) => List<E>', '<F:List<F>>(F,F) => F',
      legacyMode: true),
  notSubtype('<E>(E,List<Object>) => int', '<F:List<F>>(F,F) => F',
      legacyMode: true),
  notSubtype('<E>(E,List<Object>) => E', '<F:List<F>>(F,F) => void',
      legacyMode: true),

  subtype('int', 'FutureOr<int>'),
  subtype('int', 'FutureOr<num>'),
  subtype('Future<int>', 'FutureOr<int>'),
  subtype('Future<int>', 'FutureOr<num>'),
  subtype('Future<int>', 'FutureOr<Object>'),
  subtype('FutureOr<int>', 'FutureOr<int>'),
  subtype('FutureOr<int>', 'FutureOr<num>'),
  subtype('FutureOr<int>', 'Object'),
  notSubtype('int', 'FutureOr<double>'),
  notSubtype('FutureOr<double>', 'int'),
  notSubtype('FutureOr<int>', 'Future<num>'),
  notSubtype('FutureOr<int>', 'num'),

  // T & B <: T & A if B <: A
  subtype('T & int', 'T & int', legacyMode: true),
  subtype('T & int', 'T & num', legacyMode: true),
  subtype('T & num', 'T & num', legacyMode: true),
  notSubtype('T & num', 'T & int', legacyMode: true),

  // T & B <: T extends A if B <: A
  // (Trivially satisfied since promoted bounds are always a subtype of the
  // original bound)
  subtype('T & int', 'T', legacyMode: true, typeParameters: 'T: int'),
  subtype('T & int', 'T', legacyMode: true, typeParameters: 'T: num'),
  subtype('T & num', 'T', legacyMode: true, typeParameters: 'T: num'),

  // T extends B <: T & A if B <: A
  subtype('T', 'T & int', legacyMode: true, typeParameters: 'T: int'),
  subtype('T', 'T & num', legacyMode: true, typeParameters: 'T: int'),
  subtype('T', 'T & num', legacyMode: true, typeParameters: 'T: num'),
  notSubtype('T', 'T & int', legacyMode: true, typeParameters: 'T: num'),

  // T extends A <: T extends A
  subtype('T', 'T', legacyMode: true, typeParameters: 'T: num'),

  // S & B <: A if B <: A, A is not S (or a promotion thereof)
  subtype('S & int', 'int', legacyMode: true),
  subtype('S & int', 'num', legacyMode: true),
  subtype('S & num', 'num', legacyMode: true),
  notSubtype('S & num', 'int', legacyMode: true),
  notSubtype('S & num', 'T', legacyMode: true),
  notSubtype('S & num', 'T & num', legacyMode: true),

  // S extends B <: A if B <: A, A is not S (or a promotion thereof)
  subtype('S', 'int', legacyMode: true, typeParameters: 'S: int'),
  subtype('S', 'num', legacyMode: true, typeParameters: 'S: int'),
  subtype('S', 'num', legacyMode: true, typeParameters: 'S: num'),
  notSubtype('S', 'int', legacyMode: true, typeParameters: 'S: num'),
  notSubtype('S', 'T', legacyMode: true, typeParameters: 'S: num'),
  notSubtype('S', 'T & num', legacyMode: true, typeParameters: 'S: num'),
];

/// Assert that [subtype] is a subtype of [supertype], and that [supertype]
/// is not a subtype of [subtype] (unless the two strings are equal).
TestCase subtype(String subtype_, String supertype,
    {bool legacyMode: false, String typeParameters}) {
  return new TestCase(subtype_, supertype,
      isSubtype: true, legacyMode: legacyMode, typeParameters: typeParameters);
}

/// Assert that neither type is a subtype of the other.
TestCase notSubtype(String subtype_, String supertype,
    {bool legacyMode: false, String typeParameters}) {
  return new TestCase(subtype_, supertype,
      isSubtype: false, legacyMode: legacyMode, typeParameters: typeParameters);
}

class TestCase {
  String subtype;
  String supertype;
  String typeParameters;
  bool isSubtype;
  bool legacyMode;

  TestCase(this.subtype, this.supertype,
      {this.isSubtype, this.legacyMode: false, this.typeParameters});

  String toString() {
    var description =
        isSubtype ? '$subtype <: $supertype' : '$subtype </: $supertype';
    if (typeParameters != null) {
      description += ' (type parameters: $typeParameters)';
    }
    if (legacyMode) {
      description += ' (legacy mode)';
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
  bool legacyMode = false;

  InterfaceType futureType(DartType type) =>
      new InterfaceType(futureClass, [type]);

  @override
  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superclass) {
    return hierarchy.getTypeAsInstanceOf(type, superclass);
  }

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
  var component = new Component(libraries: [environment.dummyLibrary]);
  var hierarchy = new ClassHierarchy(component);
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
      tester.legacyMode = testCase.legacyMode;
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
