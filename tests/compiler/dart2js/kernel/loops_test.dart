// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'helper.dart' show check;

main() {
  test('for loop', () {
    String code = '''
main() {
  var a = 0;
  for (var i = 0; i < 10; i++) {
    a += i;
  }
  return a;
}''';
    return check(code);
  });

  test('while loop', () {
    String code = '''
main() {
  var a = 0;
  while (a < 100) {
    a *= 2;
  }
  return a;
}''';
    return check(code);
  });

  test('for-in loop', () {
    String code = '''
main() {
  var sum = 0;
  for (var a in [1, 2, 3]) {
    sum += a;
  }
  return sum;
}''';
    // TODO(het): Check that the code is alpha-equivalent. That is,
    // the same except for variable names.
    return check(code);
  }, skip: "The output is the same, with one variable renamed");

  test('for-in loop optimized', () {
    String code = '''
main() {
  var sum = 0;
  for (var a in [1, 2, 3]) {
    sum += a;
  }
  return sum;
}''';
    // This is the same test as above, but by enabling type inference
    // we allow the compiler to detect that it can iterate over the
    // array using indexing.
    return check(code, disableTypeInference: false);
  });

  test('for-in loop top-level variable', () {
    String code = '''
var a = 0;
main() {
  var sum = 0;
  for (a in [1, 2, 3]) {
    sum += a;
  }
  return sum;
}''';
    return check(code, disableTypeInference: false);
  });
}
