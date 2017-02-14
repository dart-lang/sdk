// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:kernel/type_algebra.dart';
import 'package:test/test.dart';
import 'type_parser.dart';
import 'dart:io';

final List<TestCase> testCases = <TestCase>[
  successCase('List<T>', 'List<String>', {'T': 'String'}),
  successCase('List<String>', 'List<T>', {'T': 'String'}),
  successCase('List<T>', 'List<T>', {'T': null}),
  successCase('List<S>', 'List<T>', {'S': 'T'}),
  successCase('List<S>', 'List<T>', {'T': 'S'}),
  successCase(
      'List<S>', 'List<T>', {'S': 'T', 'T': null}), // Require left bias.
  failureCase('List<S>', 'List<T>', []),

  failureCase('List<T>', 'T', ['T']),
  failureCase('List<List<T>>', 'List<T>', ['T']),
  failureCase('Map<S, T>', 'Map<List<T>, List<S>>', ['T', 'S']),

  failureCase('Map<Map<S,String>, Map<int,S>>',
      'Map<Map<int, S>, Map<S, String>>', ['S']),
  successCase('Map<Map<S, int>, Map<int, S>>', 'Map<Map<int, S>, Map<S, int>>',
      {'S': 'int'}),
  successCase('Map<Map<S, String>, Map<int, T>>',
      'Map<Map<int, T>, Map<S, String>>', {'S': 'int', 'T': 'String'}),

  successCase('Map<S, List<T>>', 'Map<T, List<S>>', {'S': 'T'}),
  successCase('Map<S, T>', 'Map<S, List<S>>', {'T': 'List<S>'}),
  successCase('Map<S, T>', 'Map<S, List<S>>', {'T': 'List<S>', 'S': null}),
  successCase('Map<List<S>, T>', 'Map<T, List<S>>', {'T': 'List<S>'}),
  successCase(
      'Map<List<S>, T>', 'Map<T, List<S>>', {'T': 'List<S>', 'S': null}),

  successCase('<E>(E) => E', '<T>(T) => T', {}),
  successCase('<E>(E, S) => E', '<T>(T, int) => T', {'S': 'int'}),
  failureCase('<E>(E, S) => E', '<T>(T, T) => T', ['S']),
  successCase(
      '<E>(E) => <T>(T) => Map<E,T>', '<E>(E) => <T>(T) => Map<E,T>', {}),
  successCase('<E>(E,_) => E', '<T>(T,_) => T', {}),

  successCase('(x:int,y:String) => int', '(y:String,x:int) => int', {}),
  successCase('<S,T>(x:S,y:T) => S', '<S,T>(y:T,x:S) => S', {}),
  successCase('(x:<T>(T)=>T,y:<S>(S)=>S) => int',
      '(y:<S>(S)=>S,x:<T>(T)=>T) => int', {}),
  successCase('(x:<T>(T)=>T,y:<S>(S,S,S)=>S) => int',
      '(y:<S>(S,S,S)=>S,x:<T>(T)=>T) => int', {}),
];

class TestCase {
  String type1;
  String type2;
  Iterable<String> quantifiedVariables;
  Map<String, String> expectedSubstitution; // Null if unification should fail.

  TestCase.success(this.type1, this.type2, this.expectedSubstitution) {
    quantifiedVariables = expectedSubstitution.keys;
  }

  TestCase.fail(this.type1, this.type2, this.quantifiedVariables);

  bool get shouldSucceed => expectedSubstitution != null;

  String toString() => '∃ ${quantifiedVariables.join(',')}. $type1 = $type2';
}

TestCase successCase(String type1, String type2, Map<String, String> expected,
    {bool debug: false}) {
  return new TestCase.success(type1, type2, expected);
}

TestCase failureCase(
    String type1, String type2, List<String> quantifiedVariables,
    {bool debug: false}) {
  return new TestCase.fail(type1, type2, quantifiedVariables);
}

int numFailures = 0;

void reportFailure(TestCase testCase, String message) {
  ++numFailures;
  fail('$message in `$testCase`');
}

main() {
  for (TestCase testCase in testCases) {
    test('$testCase', () {
      var env = new LazyTypeEnvironment();
      var type1 = env.parse(testCase.type1);
      var type2 = env.parse(testCase.type2);
      var quantifiedVariables =
          testCase.quantifiedVariables.map(env.getTypeParameter).toSet();
      var substitution = unifyTypes(type1, type2, quantifiedVariables);
      if (testCase.shouldSucceed) {
        if (substitution == null) {
          reportFailure(testCase, 'Unification failed');
        } else {
          for (var key in testCase.expectedSubstitution.keys) {
            var typeParameter = env.getTypeParameter(key);
            if (testCase.expectedSubstitution[key] == null) {
              if (substitution.containsKey(key)) {
                var actualType = substitution[typeParameter];
                reportFailure(
                    testCase,
                    'Incorrect substitution '
                    '`$key = $actualType` should be unbound');
              }
            } else {
              var expectedType = env.parse(testCase.expectedSubstitution[key]);
              var actualType = substitution[typeParameter];
              if (actualType != expectedType) {
                reportFailure(
                    testCase,
                    'Incorrect substitution '
                    '`$key = $actualType` should be `$key = $expectedType`');
              }
            }
          }
          var boundTypeVariables = testCase.expectedSubstitution.keys
              .where((name) => testCase.expectedSubstitution[name] != null);
          if (substitution.length != boundTypeVariables.length) {
            reportFailure(
                testCase,
                'Substituted `${substitution.keys.join(',')}` '
                'but should only substitute `${boundTypeVariables.join(',')}`');
          }
        }
      } else {
        if (substitution != null) {
          reportFailure(testCase, 'Unification was supposed to fail');
        }
      }
    });
  }
  if (numFailures > 0) {
    exit(1);
  }
}
