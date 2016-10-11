// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'helper.dart' show check;

main() {
  group('compile getters with kernel', () {
    test('top-level', () {
      String code = '''
int get foo => 1;
main() => foo;
''';
      return check(code);
    });

    test('static', () {
      String code = '''
class A {
  static int get foo => 1;
}
main() => A.foo;
''';
      return check(code);
    });
  });

  group('compile setters with kernel', () {
    test('top-level', () {
      String code = '''
set foo(int newFoo) {
  // do nothing
}
main() {
  foo = 1;
}''';
      return check(code);
    });

    test('static', () {
      String code = '''
class A {
  static set foo(int newFoo) {
    // do nothing
  }
}
main() {
  A.foo = 1;
}
''';
      return check(code);
    });
  });
}
