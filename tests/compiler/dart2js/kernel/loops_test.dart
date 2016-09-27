// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'helper.dart' show check;

main() {
  test('for-loop', () {
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

  test('while-loop', () {
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
}
