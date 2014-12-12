// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.incremental_compilation_update_test;

import 'dart:html' hide
    Element;

import 'dart:async' show
    Future;

import 'package:async_helper/async_helper.dart' show
    asyncTest;

import 'package:expect/expect.dart' show
    Expect;

import 'package:try/src/interaction_manager.dart' show
    splitLines;

import 'package:try/poi/scope_information_visitor.dart' show
    ScopeInformationVisitor;

import 'sandbox.dart' show
    appendIFrame,
    listener;

import 'web_compiler_test_case.dart' show
    WebCompilerTestCase,
    WebInputProvider;

import '../poi/compiler_test_case.dart' show
    CompilerTestCase;

import 'package:compiler/src/elements/elements.dart' show
    Element,
    LibraryElement;

import 'package:compiler/src/dart2jslib.dart' show
    Compiler;

import 'program_result.dart';

const int TIMEOUT = 100;

const List<List<ProgramResult>> tests = const <List<ProgramResult>>[
    // Basic hello-world test.
    const <ProgramResult>[
        const ProgramResult(
            "main() { print('Hello, World!'); }",
            const <String> ['Hello, World!']),
        const ProgramResult(
            "main() { print('Hello, Brave New World!'); }",
            const <String> ['Hello, Brave New World!']),
    ],

    // Test that the test framework handles more than one update.
    const <ProgramResult>[
        const ProgramResult(
            "main() { print('Hello darkness, my old friend'); }",
            const <String> ['Hello darkness, my old friend']),
        const ProgramResult(
            "main() { print('I\\'ve come to talk with you again'); }",
            const <String> ['I\'ve come to talk with you again']),
        const ProgramResult(
            "main() { print('Because a vision softly creeping'); }",
            const <String> ['Because a vision softly creeping']),
    ],

    // Test that that isolate support works.
    const <ProgramResult>[
        const ProgramResult(
            "main(arguments) { print('Hello, Isolated World!'); }",
            const <String> ['Hello, Isolated World!']),
        const ProgramResult(
            "main(arguments) { print(arguments); }",
            const <String> ['[]']),
    ],

    // Test that a stored closure changes behavior when updated.
    const <ProgramResult>[
        const ProgramResult(
            r"""
var closure;

foo(a, [b = 'b']) {
  print('$a $b');
}

main() {
  if (closure == null) {
    print('[closure] is null.');
    closure = foo;
  }
  closure('a');
  closure('a', 'c');
}
""",
            const <String> ['[closure] is null.', 'a b', 'a c']),
        const ProgramResult(
            r"""
var closure;

foo(a, [b = 'b']) {
  print('$b $a');
}

main() {
  if (closure == null) {
    print('[closure] is null.');
    closure = foo;
  }
  closure('a');
  closure('a', 'c');
}
""",
            const <String> ['b a', 'c a']),
    ],

    // Test modifying a static method works.
    const <ProgramResult>[
        const ProgramResult(
            """
class C {
  static m() {
    print('v1');
  }
}
main() {
  C.m();
}
""",
            const <String> ['v1']),
        const ProgramResult(
            """
class C {
  static m() {
    print('v2');
  }
}
main() {
  C.m();
}
""",
            const <String> ['v2']),
    ],

    // Test modifying an instance method works.
    const <ProgramResult>[
        const ProgramResult(
            """
class C {
  m() {
    print('v1');
  }
}
var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.m();
}
""",
            const <String> ['instance is null', 'v1']),
        const ProgramResult(
            """
class C {
  m() {
    print('v2');
  }
}
var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.m();
}
""",
            const <String> ['v2']),
    ],

    // Test that a stored instance tearoff changes behavior when updated.
    const <ProgramResult>[
        const ProgramResult(
            """
class C {
  m() {
    print('v1');
  }
}
var closure;
main() {
  if (closure == null) {
    print('closure is null');
    closure = new C().m;
  }
  closure();
}
""",
            const <String> ['closure is null', 'v1']),
        const ProgramResult(
            """
class C {
  m() {
    print('v2');
  }
}
var closure;
main() {
  if (closure == null) {
    print('closure is null');
    closure = new C().m;
  }
  closure();
}
""",
            const <String> ['v2']),
    ],

    // Test that deleting an instance method works.
    const <ProgramResult>[
        const ProgramResult(
            """
class C {
  m() {
    print('v1');
  }
}
var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  try {
    instance.m();
  } catch (e) {
    print('threw');
  }
}
""",
            const <String> ['instance is null', 'v1']),
        const ProgramResult(
            """
class C {
}
var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  try {
    instance.m();
  } catch (e) {
    print('threw');
  }
}
""",
            const <String> ['threw']),
    ],

    // Test that deleting an instance method works, even when accessed through
    // super.
    const <ProgramResult>[
        const ProgramResult(
            """
class A {
  m() {
    print('v2');
  }
}
class B extends A {
  m() {
    print('v1');
  }
}
class C extends B {
  m() {
    super.m();
  }
}
var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.m();
}
""",
            const <String> ['instance is null', 'v1']),
        const ProgramResult(
            """
class A {
  m() {
    print('v2');
  }
}
class B extends A {
}
class C extends B {
  m() {
    super.m();
  }
}
var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.m();
}
""",
            const <String> ['v2']),
    ],

    // Test that deleting a top-level method works.
    const <ProgramResult>[
        const ProgramResult(
            """
toplevel() {
  print('v1');
}
class C {
  m() {
    try {
      toplevel();
    } catch (e) {
      print('threw');
    }
  }
}
var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.m();
}
""",
            const <String> ['instance is null', 'v1']),
        const ProgramResult(
            """
class C {
  m() {
    try {
      toplevel();
    } catch (e) {
      print('threw');
    }
  }
}
var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.m();
}
""",
            const <String> ['threw']),
    ],

    // Test that deleting a static method works.
    const <ProgramResult>[
        const ProgramResult(
            """
class B {
  static staticMethod() {
    print('v1');
  }
}
class C {
  m() {
    try {
      B.staticMethod();
    } catch (e) {
      print('threw');
    }
    try {
      // Ensure that noSuchMethod support is compiled. This test is not about
      // adding new classes.
      B.missingMethod();
      print('bad');
    } catch (e) {
    }
  }
}
var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.m();
}
""",
            const <String> ['instance is null', 'v1']),
        const ProgramResult(
            """
class B {
}
class C {
  m() {
    try {
      B.staticMethod();
    } catch (e) {
      print('threw');
    }
    try {
      // Ensure that noSuchMethod support is compiled. This test is not about
      // adding new classes.
      B.missingMethod();
      print('bad');
    } catch (e) {
    }
  }
}
var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.m();
}
""",
            const <String> ['threw']),
    ],

    // Test that a newly instantiated class is handled.
    const <ProgramResult>[
        const ProgramResult(
            """
class A {
  m() {
    print('Called A.m');
  }
}

class B {
  m() {
    print('Called B.m');
  }
}

var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new A();
  }
  instance.m();
}
""",
            const <String>['instance is null', 'Called A.m']),
        const ProgramResult(
            """
class A {
  m() {
    print('Called A.m');
  }
}

class B {
  m() {
    print('Called B.m');
  }
}

var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new A();
  } else {
    instance = new B();
  }
  instance.m();
}
""",
            const <String>['Called B.m']),
    ],

    // Test that source maps don't throw exceptions.
    const <ProgramResult>[
        const ProgramResult(
            """
main() {
  print('a');
}
""",
            const <String>['a']),

        const ProgramResult(
            """
main() {
  print('a');
  print('b');
  print('c');
}
""",
            const <String>['a', 'b', 'c']),
    ],

    // Test that a newly instantiated class is handled.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class A {
  get name => 'A.m';

  m() {
    print('Called $name');
  }
}

class B extends A {
  get name => 'B.m';
}

var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new A();
  }
  instance.m();
}
""",
            const <String>['instance is null', 'Called A.m']),
        const ProgramResult(
            r"""
class A {
  get name => 'A.m';

  m() {
    print('Called $name');
  }
}

class B extends A {
  get name => 'B.m';
}

var instance;
main() {
  if (instance == null) {
    print('instance is null');
    instance = new A();
  } else {
    instance = new B();
  }
  instance.m();
}
""",
            const <String>['Called B.m']),
    ],

    // Test that fields of a newly instantiated class are handled.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class A {
  var x;
  A(this.x);
}
var instance;
foo() {
  if (instance != null) {
    print(instance.x);
  } else {
    print('v1');
  }
}
main() {
  foo();
}
""",
            const <String>['v1']),
        const ProgramResult(
            r"""
class A {
  var x;
  A(this.x);
}
var instance;
foo() {
  if (instance != null) {
    print(instance.x);
  } else {
    print('v1');
  }
}
main() {
  instance = new A('v2');
  foo();
}
""",
            const <String>['v2']),
    ],

    // Test that top-level functions can be added.
    const <ProgramResult>[
        const ProgramResult(
            r"""
main() {
  try {
    foo();
  } catch(e) {
    print('threw');
  }
}
""",
            const <String>['threw']),
        const ProgramResult(
            r"""
foo() {
  print('v2');
}

main() {
  try {
    foo();
  } catch(e) {
    print('threw');
  }
}
""",
            const <String>['v2']),
    ],

    // Test that static methods can be added.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class C {
}

main() {
  try {
    C.foo();
  } catch(e) {
    print('threw');
  }
}
""",
            const <String>['threw']),
        const ProgramResult(
            r"""
class C {
  static foo() {
    print('v2');
  }
}

main() {
  try {
    C.foo();
  } catch(e) {
    print('threw');
  }
}
""",
            const <String>['v2']),
    ],

    // Test that instance methods can be added.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class C {
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }

  try {
    instance.foo();
  } catch(e) {
    print('threw');
  }
}
""",
            const <String>['instance is null', 'threw']),
        const ProgramResult(
            r"""
class C {
  foo() {
    print('v2');
  }
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }

  try {
    instance.foo();
  } catch(e) {
    print('threw');
  }
}
""",
            const <String>['v2']),
    ],

    // Test that top-level functions can have signature changed.
    const <ProgramResult>[
        const ProgramResult(
            r"""
foo() {
  print('v1');
}

main() {
  foo();
}
""",
            const <String>['v1']),
        const ProgramResult(
            r"""
void foo() {
  print('v2');
}

main() {
  foo();
}
""",
            const <String>['v2']),
    ],

    // Test that static methods can have signature changed.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class C {
  static foo() {
    print('v1');
  }
}

main() {
  C.foo();
}
""",
            const <String>['v1']),
        const ProgramResult(
            r"""
class C {
  static void foo() {
    print('v2');
  }
}

main() {
  C.foo();
}
""",
            const <String>['v2']),
    ],

    // Test that instance methods can have signature changed.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class C {
  foo() {
    print('v1');
  }
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }

  instance.foo();
}
""",
            const <String>['instance is null', 'v1']),
        const ProgramResult(
            r"""
class C {
  void foo() {
    print('v2');
  }
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }

  instance.foo();
}
""",
            const <String>['v2']),
    ],

    // Test that adding a class is supported.
    const <ProgramResult>[
        const ProgramResult(
            r"""
main() {
  print('v1');
}
""",
            const <String>['v1']),
        const ProgramResult(
            r"""
class C {
  void foo() {
    print('v2');
  }
}

main() {
  new C().foo();
}
""",
            const <String>['v2']),
    ],

    // Test that removing a class is supported, using constructor.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class C {
}

main() {
  try {
    new C();
    print('v1');
  } catch (e) {
    print('v2');
  }
}
""",
            const <String>['v1']),
        const ProgramResult(
            r"""
main() {
  try {
    new C();
    print('v1');
  } catch (e) {
    print('v2');
  }
}
""",
            const <String>['v2']),
    ],

    // Test that removing a class is supported, using a static method.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class C {
  static m() {
    print('v1');
  }
}

main() {
  try {
    C.m();
  } catch (e) {
    print('v2');
  }
}
""",
            const <String>['v1']),
        const ProgramResult(
            r"""
main() {
  try {
    C.m();
  } catch (e) {
    print('v2');
  }
}
""",
            const <String>['v2']),
    ],

    // Test that changing the supertype of a class.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class A {
  m() {
    print('v2');
  }
}
class B extends A {
  m() {
    print('v1');
  }
}
class C extends B {
  m() {
    super.m();
  }
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.m();
}
""",
            const <String>['instance is null', 'v1']),
        const ProgramResult(
            r"""
class A {
  m() {
    print('v2');
  }
}
class B extends A {
  m() {
    print('v1');
  }
}
class C extends A {
  m() {
    super.m();
  }
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.m();
}
""",
            const <String>['v2']),
    ],

    // Test adding a field to a class works.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class A {
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new A();
  }
  try {
    instance.x = 'v2';
  } catch(e) {
    print('setter threw');
  }
  try {
    print(instance.x);
  } catch (e) {
    print('getter threw');
  }
}
""",
            const <String>['instance is null', 'setter threw', 'getter threw']),
        const ProgramResult(
            r"""
class A {
  var x;
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new A();
  }
  try {
    instance.x = 'v2';
  } catch(e) {
    print('setter threw');
  }
  try {
    print(instance.x);
  } catch (e) {
    print('getter threw');
  }
}
""",
            const <String>['v2']),
    ],

    // Test removing a field from a class works.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class A {
  var x;
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new A();
  }
  try {
    instance.x = 'v1';
  } catch(e) {
    print('setter threw');
  }
  try {
    print(instance.x);
  } catch (e) {
    print('getter threw');
  }
}
""",
            const <String>['instance is null', 'v1']),
        const ProgramResult(
            r"""
class A {
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new A();
  }
  try {
    instance.x = 'v1';
  } catch(e) {
    print('setter threw');
  }
  try {
    print(instance.x);
  } catch (e) {
    print('getter threw');
  }
}
""",
            const <String>['setter threw', 'getter threw']),
    ],

    // Test that named arguments can be called.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class C {
  foo({a, named: 'v1', x}) {
    print(named);
  }
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.foo();
}
""",
            const <String>['instance is null', 'v1']),
        const ProgramResult(
            r"""
class C {
  foo({a, named: 'v1', x}) {
    print(named);
  }
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.foo(named: 'v2');
}
""",
            const <String>['v2']),
    ],

    // Test than named arguments can be called.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class C {
  foo({a, named: 'v2', x}) {
    print(named);
  }
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.foo(named: 'v1');
}
""",
            const <String>['instance is null', 'v1']),
        const ProgramResult(
            r"""
class C {
  foo({a, named: 'v2', x}) {
    print(named);
  }
}

var instance;

main() {
  if (instance == null) {
    print('instance is null');
    instance = new C();
  }
  instance.foo();
}
""",
            const <String>['v2']),
    ],

    // Test that an instance tear-off with named parameters can be called.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class C {
  foo({a, named: 'v1', x}) {
    print(named);
  }
}

var closure;

main() {
  if (closure == null) {
    print('closure is null');
    closure = new C().foo;
  }
  closure();
}
""",
            const <String>['closure is null', 'v1']),
        const ProgramResult(
            r"""
class C {
  foo({a, named: 'v1', x}) {
    print(named);
  }
}

var closure;

main() {
  if (closure == null) {
    print('closure is null');
    closure = new C().foo;
  }
  closure(named: 'v2');
}
""",
            const <String>['v2']),
    ],

    // Test that a lazy static is supported.
    const <ProgramResult>[
        const ProgramResult(
            r"""
var normal;

foo() {
  print(normal);
}

main() {
  if (normal == null) {
    normal = 'v1';
  } else {
    normal = '';
  }
  foo();
}
""",
            const <String>['v1']),
        const ProgramResult(
            r"""
var normal;

var lazy = bar();

foo() {
  print(lazy);
}

bar() {
  print('v2');
  return 'lazy';
}

main() {
  if (normal == null) {
    normal = 'v1';
  } else {
    normal = '';
  }
  foo();
}
""",
            const <String>['v2', 'lazy']),
    ],

    // Test that superclasses of directly instantiated classes are also
    // emitted.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class A {
}

class B extends A {
}

main() {
  print('v1');
}
""",
            const <String>['v1']),
        const ProgramResult(
            r"""
class A {
}

class B extends A {
}

main() {
  new B();
  print('v2');
}
""",
            const <String>['v2']),
    ],

    // Test that interceptor classes are handled correctly.
    const <ProgramResult>[
        const ProgramResult(
            r"""
main() {
  print('v1');
}
""",
            const <String>['v1']),
        const ProgramResult(
            r"""
main() {
  ['v2'].forEach(print);
}
""",
            const <String>['v2']),
    ],

    // Test that newly instantiated classes are handled correctly when there is
    // more than one change.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class A {
  foo() {
    print('Called foo');
  }

  bar() {
    print('Called bar');
  }
}

class B extends A {
}

main() {
  new B().foo();
}
""",
            const <String>['Called foo']),
        const ProgramResult(
            r"""
class A {
  foo() {
    print('Called foo');
  }

  bar() {
    print('Called bar');
  }
}

class B extends A {
}

main() {
  new B().foo();
}
""",
            const <String>['Called foo']),
        const ProgramResult(
            r"""
class A {
  foo() {
    print('Called foo');
  }

  bar() {
    print('Called bar');
  }
}

class B extends A {
}

main() {
  new A().bar();
}
""",
            const <String>['Called bar']),
    ],

    // Test that constants are handled correctly.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class C {
  final String value;
  const C(this.value);
}

main() {
  print(const C('v1').value);
}
""",
            const <String>['v1']),
        const ProgramResult(
            r"""
class C {
  final String value;
  const C(this.value);
}

main() {
  print(const C('v2').value);
}
""",
            const <String>['v2']),
    ],

    // Test that an instance field can be added to a compound declaration.
    // TODO(ahe): Test doesn't pass.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class C {
  int x;
}

var instance;

main() {
  if (instance == null) {
    print('[instance] is null');
    instance = new C();
    instance.x = 'v1';
  } else {
    instance.y = 'v2';
  }
  try {
    print(instance.x);
  } catch (e) {
    print('[instance.x] threw');
  }
  try {
    print(instance.y);
  } catch (e) {
    print('[instance.y] threw');
  }
}
""",
            const <String>['[instance] is null', 'v1', '[instance.y] threw']),
/*
        const ProgramResult(
            r"""
class C {
  int x, y;
}

var instance;

main() {
  if (instance == null) {
    print('[instance] is null');
    instance = new C();
    instance.x = 'v1';
  } else {
    instance.y = 'v2';
  }
  try {
    print(instance.x);
  } catch (e) {
    print('[instance.x] threw');
  }
  try {
    print(instance.y);
  } catch (e) {
    print('[instance.y] threw');
  }
}
""",
            const <String>['v1', 'v2']),
*/
    ],

    // Test that an instance field can be removed from a compound declaration.
    // TODO(ahe): Test doesn't pass.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class C {
  int x, y;
}

var instance;

main() {
  if (instance == null) {
    print('[instance] is null');
    instance = new C();
    instance.x = 'v1';
    instance.y = 'v2';
  }
  try {
    print(instance.x);
  } catch (e) {
    print('[instance.x] threw');
  }
  try {
    print(instance.y);
  } catch (e) {
    print('[instance.y] threw');
  }
}
""",
            const <String>['[instance] is null', 'v1', 'v2']),
/*
        const ProgramResult(
            r"""
class C {
  int x;
}

var instance;

main() {
  if (instance == null) {
    print('[instance] is null');
    instance = new C();
    instance.x = 'v1';
    instance.y = 'v2';
  }
  try {
    print(instance.x);
  } catch (e) {
    print('[instance.x] threw');
  }
  try {
    print(instance.y);
  } catch (e) {
    print('[instance.y] threw');
  }
}
""",
            const <String>['v1', '[instance.y] threw']),
*/
    ],

    // Test that a static field can be made an instance field.
    // TODO(ahe): Test doesn't pass.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class C {
  static int x;
}

var instance;

main() {
  if (instance == null) {
    print('[instance] is null');
    instance = new C();
    C.x = 'v1';
  } else {
    instance.x = 'v2';
  }
  try {
    print(C.x);
  } catch (e) {
    print('[C.x] threw');
  }
  try {
    print(instance.x);
  } catch (e) {
    print('[instance.x] threw');
  }
}
""",
            const <String>['[instance] is null', 'v1', '[instance.x] threw']),
/*
        const ProgramResult(
            r"""
class C {
  int x;
}

var instance;

main() {
  if (instance == null) {
    print('[instance] is null');
    instance = new C();
    C.x = 'v1';
  } else {
    instance.x = 'v2';
  }
  try {
    print(C.x);
  } catch (e) {
    print('[C.x] threw');
  }
  try {
    print(instance.x);
  } catch (e) {
    print('[instance.x] threw');
  }
}
""",
            const <String>['[C.x] threw', 'v2']),
*/
    ],

    // Test that instance field can be made static.
    // TODO(ahe): Test doesn't pass.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class C {
  int x;
}

var instance;

main() {
  if (instance == null) {
    print('[instance] is null');
    instance = new C();
    instance.x = 'v1';
  } else {
    C.x = 'v2';
  }
  try {
    print(C.x);
  } catch (e) {
    print('[C.x] threw');
  }
  try {
    print(instance.x);
  } catch (e) {
    print('[instance.x] threw');
  }
}
""",
            const <String>['[instance] is null', '[C.x] threw', 'v1']),
/*
        const ProgramResult(
            r"""
class C {
  static int x;
}

var instance;

main() {
  if (instance == null) {
    print('[instance] is null');
    instance = new C();
    instance.x = 'v1';
  } else {
    C.x = 'v2';
  }
  try {
    print(C.x);
  } catch (e) {
    print('[C.x] threw');
  }
  try {
    print(instance.x);
  } catch (e) {
    print('[instance.x] threw');
  }
}
""",
            const <String>['v2', '[instance.x] threw']),
*/
    ],

    // Test compound constants.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class A {
  final value;
  const A(this.value);

  toString() => 'A($value)';
}

class B {
  final value;
  const B(this.value);

  toString() => 'B($value)';
}

main() {
  print(const A('v1'));
  print(const B('v1'));
}
""",
            const <String>['A(v1)', 'B(v1)']),

        const ProgramResult(
            r"""
class A {
  final value;
  const A(this.value);

  toString() => 'A($value)';
}

class B {
  final value;
  const B(this.value);

  toString() => 'B($value)';
}

main() {
  print(const B(const A('v2')));
  print(const A(const B('v2')));
}
""",
            const <String>['B(A(v2))', 'A(B(v2))']),
    ],

    // Test constants of new classes.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class A {
  final value;
  const A(this.value);

  toString() => 'A($value)';
}

main() {
  print(const A('v1'));
}
""",
            const <String>['A(v1)']),

        const ProgramResult(
            r"""
class A {
  final value;
  const A(this.value);

  toString() => 'A($value)';
}

class B {
  final value;
  const B(this.value);

  toString() => 'B($value)';
}

main() {
  print(const A('v2'));
  print(const B('v2'));
  print(const B(const A('v2')));
  print(const A(const B('v2')));
}
""",
            const <String>['A(v2)', 'B(v2)', 'B(A(v2))', 'A(B(v2))']),
    ],
];

void main() {
  listener.start();

  document.head.append(lineNumberStyle());

  summary = new SpanElement();
  document.body.append(new HeadingElement.h1()
      ..appendText("Incremental compiler tests")
      ..append(summary));

  String query = window.location.search;
  int skip = 0;
  if (query != null && query.length > 1) {
    query = query.substring(1);
    String skipParam = Uri.splitQueryString(window.location.search)['skip'];
    if (skipParam != null) {
      skip = int.parse(skipParam);
    }
  }
  testCount += skip;

  return asyncTest(() => Future.forEach(tests.skip(skip), compileAndRun)
      .then(updateSummary));
}

SpanElement summary;

int testCount = 1;

void updateSummary(_) {
  summary.text = " (${testCount - 1}/${tests.length})";
}

Future compileAndRun(List<ProgramResult> programs) {
  updateSummary(null);
  var status = new DivElement();
  document.body.append(status);

  IFrameElement iframe =
      appendIFrame(
          '/root_dart/tests/try/web/incremental_compilation_update.html',
          document.body)
          ..style.width = '100%'
          ..style.height = '600px';

  return listener.expect('iframe-ready').then((_) {
    ProgramResult program = programs.first;

    status.append(
        new HeadingElement.h2()
            ..appendText("Full program #${testCount++}:"));
    status.append(numberedLines(program.code));

    status.style.color = 'orange';
    WebCompilerTestCase test = new WebCompilerTestCase(program.code);
    return test.run().then((String jsCode) {
      status.style.color = 'red';
      var objectUrl =
          Url.createObjectUrl(new Blob([jsCode], 'application/javascript'));

      iframe.contentWindow.postMessage(['add-script', objectUrl], '*');
      Future future =
          listener.expect(program.messagesWith('iframe-dart-main-done'));
      return future.then((_) {
        int version = 2;
        return Future.forEach(programs.skip(1), (ProgramResult program) {

          status.append(new HeadingElement.h2()..appendText("Update:"));
          status.append(numberedLines(program.code));

          WebInputProvider inputProvider =
              test.incrementalCompiler.inputProvider;
          Uri uri = test.scriptUri.resolve('?v${version++}');
          inputProvider.cachedSources[uri] = new Future.value(program.code);
          Future future = test.incrementalCompiler.compileUpdates(
              {test.scriptUri: uri}, logVerbose: logger, logTime: logger);
          return future.then((String update) {
            print({'update': update});
            iframe.contentWindow.postMessage(['apply-update', update], '*');

            return listener.expect(
                program.messagesWith('iframe-dart-updated-main-done'))
                .then((_) {
                  return new SerializeScopeTestCase(
                      program.code, test.incrementalCompiler.mainApp,
                      test.incrementalCompiler.compiler).run();
                });
          });
        });
      });
    });
  }).then((_) {
    status.style.color = 'limegreen';

    // Remove the iframe and status to work around a bug in test.dart
    // (https://code.google.com/p/dart/issues/detail?id=21691).
    status.remove();
    iframe.remove();
  });
}

class SerializeScopeTestCase extends CompilerTestCase {
  final String scopeInfo;

  SerializeScopeTestCase(
      String source,
      LibraryElement library,
      Compiler compiler)
      : scopeInfo = computeScopeInfo(compiler, library),
        super(source, '${library.canonicalUri}');

  Future run() => loadMainApp().then(checkScopes);

  void checkScopes(LibraryElement library) {
    Expect.stringEquals(computeScopeInfo(compiler, library), scopeInfo);
  }

  static String computeScopeInfo(Compiler compiler, LibraryElement library) {
    ScopeInformationVisitor visitor =
        new ScopeInformationVisitor(compiler, library, 0);

    visitor.ignoreImports = true;
    visitor.sortMembers = true;
    visitor.indented.write('[\n');
    visitor.indentationLevel++;
    visitor.indented;
    library.accept(visitor);
    library.forEachLocalMember((Element member) {
      if (member.isClass) {
        visitor.buffer.write(',\n');
        visitor.indented;
        member.accept(visitor);
      }
    });
    visitor.buffer.write('\n');
    visitor.indentationLevel--;
    visitor.indented.write(']');
    return '${visitor.buffer}';
  }
}

void logger(x) {
  print(x);
  bool isCheckedMode = false;
  assert(isCheckedMode = true);
  int timeout = isCheckedMode ? TIMEOUT * 2 : TIMEOUT;
  if (listener.elapsed > timeout) {
    throw 'Test timed out.';
  }
}

DivElement numberedLines(String code) {
  DivElement result = new DivElement();
  result.classes.add("output");

  for (String text in splitLines(code)) {
    PreElement line = new PreElement()
        ..appendText(text.trimRight())
        ..classes.add("line");
    result.append(line);
  }

  return result;
}


StyleElement lineNumberStyle() {
  StyleElement style = new StyleElement()..appendText('''
h2 {
  color: black;
}

.output {
  padding: 0px;
  counter-reset: line-number;
  padding-bottom: 1em;
}

.line {
  white-space: pre-wrap;
  padding-left: 3.5em;
  margin-top: 0;
  margin-bottom: 0;
}

.line::before {
  counter-increment: line-number;
  content: counter(line-number) " ";
  position: absolute;
  left: 0px;
  width: 3em;
  text-align: right;
  background-color: lightgoldenrodyellow;
}
''');
  style.type = 'text/css';
  return style;
}
