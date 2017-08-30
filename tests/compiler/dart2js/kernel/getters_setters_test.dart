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

    test('super get', () {
      String code = '''
class A {
  int get foo => 1;
}

class B extends A {

  int get rotations => super.foo * 3;
}

main() => new B().foo;
''';
      return check(code);
    });

    test('super get no such method', () {
      String code = '''
class A {
  static int get foo => 1;
}

class B extends A {

  int get rotations => super.nothing * 3;
}

main() => new B().foo;
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

  test('super set', () {
    String code = '''
class A {
  set ferocious(int newFerocious) {}
}

class B extends A {
  bar() {
    super.ferocious = 87;
  }
}
main() {
  new B().bar();
}''';
    return check(code);
  });

  test('super set no such method', () {
    String code = '''
class A {
  final ferocious = 0;
  noSuchMethod(_) => 42;
}

class B extends A {
  bar() {
    super.ferocious = 87;
  }
}
main() {
  new B().bar();
}''';
    return check(code,
        // TODO(johnniwinther): Remove this when
        // `KernelClosureConversionTask.getClosureInfoForMember` doesn't fail
        // on the closure in `Maps.mapToString`.
        useKernelInSsa: true);
  });
}
