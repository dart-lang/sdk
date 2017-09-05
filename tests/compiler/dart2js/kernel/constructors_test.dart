// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart' show Compiler;
import 'package:compiler/src/elements/entities.dart';
import 'package:test/test.dart';

import 'helper.dart' show check;

main() {
  test('simple default constructor', () {
    String code = '''
class A {
}

main() {
  var a = new A();
  return a;
}''';
    return check(code, lookup: defaultConstructorFor('A'));
  });

  test('simple default constructor with field', () {
    String code = '''
class A {
  int x = 1;
}

main() {
  var a = new A();
  return a;
}''';
    return check(code, lookup: defaultConstructorFor('A'));
  });

  test('redirecting constructor with field', () {
    String code = '''
class Foo {
  final int value;
  const Foo({int number: 0}) : this.poodle(number * 2);
  const Foo.poodle(this.value);
}

main() => new Foo(number: 3);
''';
    return check(code, lookup: defaultConstructorFor('Foo'));
  });

  // TODO(efortuna): Kernel needs to have some additional constructor
  // implementation work before this is legitimately equivalent code to the
  // original AST.
/*  test('initialized field and constructor', () {
    String code = '''
import 'dart:_foreign_helper' show JS, JS_EMBEDDED_GLOBAL;
import 'package:expect/expect.dart';


class Foo {
  final value = JS('bool', '#()', JS_EMBEDDED_GLOBAL('', 'foo'));
  Foo() {
    print('hello world');
  }
}

main() => new Foo();
''';
    return check(code, lookup: defaultConstructorFor('Foo'));
  });*/
}

defaultConstructorFor(String className) => (Compiler compiler) {
      ElementEnvironment elementEnvironment =
          compiler.backendClosedWorldForTesting.elementEnvironment;
      LibraryEntity mainLibrary = elementEnvironment.mainLibrary;
      ClassEntity clazz =
          elementEnvironment.lookupClass(mainLibrary, className);
      return elementEnvironment.lookupConstructor(clazz, '');
    };
