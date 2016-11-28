// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.type_substitute_bounds_test;

import 'package:kernel/kernel.dart';
import 'package:kernel/type_algebra.dart';
import 'package:test/test.dart';
import 'type_parser.dart';

final List<TestCase> testCases = <TestCase>[
  testCase('T', {'T': bound('_', 'String')}, 'String'),
  testCase('List<T>', {'T': bound('_', 'String')}, 'List<String>'),
  testCase('List<List<T>>', {'T': bound('_', 'String')}, 'List<List<String>>'),
  testCase('(T) => T', {'T': bound('_', 'String')}, '(_) => String'),
  testCase('<G>(G,T) => T', {'T': bound('_', 'String')}, '<G>(G,_) => String'),
  testCase(
      '<G>(G,x:T) => T', {'T': bound('_', 'String')}, '<G>(G,x:_) => String'),
  testCase('<G:T>(G) => G', {'T': bound('_', 'String')}, '<G:_>(G) => G'),
  testCase('<G:T>(G) => G', {'T': bound('int', 'num')}, '<G:int>(G) => G'),
  testCase('<G>(T,G) => void', {'T': bound('_', 'String')}, '<G>(_,G) => void'),
  testCase('(T) => void', {'T': bound('_', 'String')}, '(_) => void'),
  testCase('(int) => T', {'T': bound('_', 'String')}, '(int) => String'),
  testCase('(int) => int', {'T': bound('_', 'String')}, '(int) => int'),
  testCase('((T) => int) => int', {'T': bound('_', 'String')},
      '((String) => int) => int'),
  testCase('<E>(<F>(T) => int) => int', {'T': bound('_', 'String')},
      '<E>(<F>(String) => int) => int'),
  testCase('(<F>(T) => int) => int', {'T': bound('_', 'String')},
      '(<F>(String) => int) => int'),
  testCase('<E>((T) => int) => int', {'T': bound('_', 'String')},
      '<E>((String) => int) => int'),
];

class TestCase {
  final String type;
  final Map<String, TypeBound> bounds;
  final String expected;

  TestCase(this.type, this.bounds, this.expected);

  String toString() {
    var substitution = bounds.keys.map((key) {
      var bound = bounds[key];
      return '${bound.lower} <: $key <: ${bound.upper}';
    }).join(',');
    return '$type [$substitution] <: $expected';
  }
}

class TypeBound {
  final String lower, upper;

  TypeBound(this.lower, this.upper);
}

TypeBound bound(String lower, String upper) => new TypeBound(lower, upper);

TestCase testCase(String type, Map<String, TypeBound> bounds, String expected) {
  return new TestCase(type, bounds, expected);
}

main() {
  for (var testCase in testCases) {
    test('$testCase', () {
      var environment = new LazyTypeEnvironment();
      var type = environment.parse(testCase.type);
      var upperBounds = <TypeParameter, DartType>{};
      var lowerBounds = <TypeParameter, DartType>{};
      testCase.bounds.forEach((String name, TypeBound bounds) {
        var parameter = environment.getTypeParameter(name);
        upperBounds[parameter] = environment.parse(bounds.upper);
        lowerBounds[parameter] = environment.parse(bounds.lower);
      });
      var substituted = Substitution
          .fromUpperAndLowerBounds(upperBounds, lowerBounds)
          .substituteType(type);
      var expected = environment.parse(testCase.expected);
      if (substituted != expected) {
        fail('Expected `$expected` but got `$substituted`');
      }
    });
  }
}
