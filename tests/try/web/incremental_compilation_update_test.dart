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

import 'package:compiler/src/compiler.dart' show
    Compiler;

import 'package:dart2js_incremental/dart2js_incremental.dart' show
    IncrementalCompilationFailed;

import 'program_result.dart';

const int TIMEOUT = 100;

const List<EncodedResult> tests = const <EncodedResult>[
    // Basic hello-world test.
    const EncodedResult(
        const [
            "main() { print('Hello, ",
            const ["", "Brave New "],
            "World!'); }",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['Hello, World!']),
            const ProgramExpectation(
                const <String>['Hello, Brave New World!']),
        ]),

    // Test that the test framework handles more than one update.
    const EncodedResult(
        const [
            "main() { print('",
            const [
                "Hello darkness, my old friend",
                "I\\'ve come to talk with you again",
                "Because a vision softly creeping",
            ],
            "'); }",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['Hello darkness, my old friend']),
            const ProgramExpectation(
                const <String>['I\'ve come to talk with you again']),
            const ProgramExpectation(
                const <String>['Because a vision softly creeping']),
        ]),

    // Test that that isolate support works.
    const EncodedResult(
        const [
            "main(arguments) { print(",
            const [
                "'Hello, Isolated World!'",
                "arguments"
            ],
            "); }",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['Hello, Isolated World!']),
            const ProgramExpectation(
                const <String>['[]']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that a stored closure changes behavior when updated.

var closure;

foo(a, [b = 'b']) {
""",
            const [
                r"""
  print('$a $b');
""",
                r"""
  print('$b $a');
""",
            ],
            r"""
}

main() {
  if (closure == null) {
    print('[closure] is null.');
    closure = foo;
  }
  closure('a');
  closure('a', 'c');
}
"""],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['[closure] is null.', 'a b', 'a c']),
            const ProgramExpectation(
                const <String>['b a', 'c a']),
        ]),

    const EncodedResult(
        const [
            """
// Test modifying a static method works.

class C {
  static m() {
""",
            const [
                r"""
  print('v1');
""",
                r"""
  print('v2');
""",
            ],
            """
  }
}
main() {
  C.m();
}
""",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['v1']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            """
// Test modifying an instance method works.

class C {
  m() {
""",
            const [
                r"""
  print('v1');
""",
                r"""
  print('v2');
""",
            ],
            """
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

        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['instance is null', 'v1']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            """
// Test that a stored instance tearoff changes behavior when updated.

class C {
  m() {
""",
            const [
                r"""
  print('v1');
""",
                r"""
  print('v2');
""",
            ],
                """
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

        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['closure is null', 'v1']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            """
// Test that deleting an instance method works.

class C {
""",
            const [
                """
  m() {
    print('v1');
  }
""",
                """
""",
            ],
            """
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
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['instance is null', 'v1']),
            const ProgramExpectation(
                const <String>['threw']),
        ]),

    const EncodedResult(
        const [
            """
// Test that deleting an instance method works, even when accessed through
// super.

class A {
  m() {
    print('v2');
  }
}
class B extends A {
""",
            const [
                """
  m() {
    print('v1');
  }
""",
                """
""",
            ],
            """
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

        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['instance is null', 'v1']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            """
// Test that deleting a top-level method works.

""",
            const [
                """
toplevel() {
  print('v1');
}
""",
                """
""",
            ],
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
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['instance is null', 'v1']),
            const ProgramExpectation(
                const <String>['threw']),
        ]),

    const EncodedResult(
        const [
            """
// Test that deleting a static method works.

class B {
""",
            const [
                """
  static staticMethod() {
    print('v1');
  }
""",
                """
""",
            ],
                """
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
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['instance is null', 'v1']),
            const ProgramExpectation(
                const <String>['threw']),
        ]),

    const EncodedResult(
        const [
            """
// Test that a newly instantiated class is handled.

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
""",
            const [
                """
""",
                """
  } else {
    instance = new B();
""",
            ],
            """
  }
  instance.m();
}
""",

        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['instance is null', 'Called A.m']),
            const ProgramExpectation(
                const <String>['Called B.m']),
        ]),

    const EncodedResult(
        const [
            """
// Test that source maps don't throw exceptions.

main() {
  print('a');
""",
            const [
                """
""",
                """
  print('b');
  print('c');
""",
            ],
            """
}
""",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['a']),
            const ProgramExpectation(
                const <String>['a', 'b', 'c']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that a newly instantiated class is handled.

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
""",
            const [
                r"""
""",
                r"""
  } else {
    instance = new B();
""",
            ],
            r"""
  }
  instance.m();
}
""",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['instance is null', 'Called A.m']),
            const ProgramExpectation(
                const <String>['Called B.m']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that fields of a newly instantiated class are handled.

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
""",
            const [
                r"""
""",
                r"""
  instance = new A('v2');
""",
            ],
            r"""
  foo();
}
""",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['v1']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that top-level functions can be added.

""",
            const [
                "",
                r"""
foo() {
  print('v2');
}
""",
            ],
            r"""
main() {
  try {
    foo();
  } catch(e) {
    print('threw');
  }
}
""",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['threw']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that static methods can be added.

class C {
""",
            const [
                "",
                r"""
  static foo() {
    print('v2');
  }
""",
            ],
            r"""
}

main() {
  try {
    C.foo();
  } catch(e) {
    print('threw');
  }
}
""",

        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['threw']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that instance methods can be added.

class C {
""",
            const [
                "",
                r"""
  foo() {
    print('v2');
  }
""",
            ],
            r"""
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
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['instance is null', 'threw']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that top-level functions can have signature changed.

""",
            const [
                r"""
foo() {
  print('v1');
""",
                r"""
void foo() {
  print('v2');
""",
            ],
            r"""
}

main() {
  foo();
}
""",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['v1']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that static methods can have signature changed.

class C {
""",
            const [
                r"""
  static foo() {
    print('v1');
""",
                r"""
  static void foo() {
    print('v2');
""",
            ],
            r"""
  }
}

main() {
  C.foo();
}
""",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['v1']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that instance methods can have signature changed.

class C {
""",
            const [
                r"""
  foo() {
    print('v1');
""",
                r"""
  void foo() {
    print('v2');
""",
            ],
            r"""
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
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['instance is null', 'v1']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that adding a class is supported.

""",
            const [
                "",
                r"""
class C {
  void foo() {
    print('v2');
  }
}
""",
            ],
            r"""
main() {
""",
            const [
                r"""
  print('v1');
""",
                r"""
  new C().foo();
""",
            ],
            r"""
}
""",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['v1']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that removing a class is supported, using constructor.

""",
            const [
                r"""
class C {
}
""",
                ""
            ],
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
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['v1']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that removing a class is supported, using a static method.

""",
            const [
                r"""
class C {
  static m() {
    print('v1');
  }
}
""",
                "",
            ],
            r"""
main() {
  try {
    C.m();
  } catch (e) {
    print('v2');
  }
}
""",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['v1']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that changing the supertype of a class.

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
""",
            const [
                r"""
class C extends B {
""",
                r"""
class C extends A {
""",
            ],
            r"""
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
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['instance is null', 'v1']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test adding a field to a class works.

class A {
""",
            const [
                "",
                r"""
  var x;
""",
            ],
            r"""
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
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['instance is null', 'setter threw', 'getter threw']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test removing a field from a class works.

class A {
""",
            const [
                r"""
  var x;
""",
                "",
            ],
            r"""
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
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['instance is null', 'v1']),
            const ProgramExpectation(
                const <String>['setter threw', 'getter threw']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that named arguments can be called.

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
""",
            const [
                r"""
  instance.foo();
""",
                r"""
  instance.foo(named: 'v2');
""",
            ],
            r"""
}
""",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['instance is null', 'v1']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test than named arguments can be called.

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
""",
            const [
                r"""
  instance.foo(named: 'v1');
""",
                r"""
  instance.foo();
""",
            ],
            r"""
}
""",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['instance is null', 'v1']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that an instance tear-off with named parameters can be called.

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
""",
            const [
                r"""
  closure();
""",
                r"""
  closure(named: 'v2');
""",
            ],
            r"""
}
""",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['closure is null', 'v1']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that a lazy static is supported.

var normal;

""",
            const [
                r"""
foo() {
  print(normal);
}
""",
                r"""
var lazy = bar();

foo() {
  print(lazy);
}

bar() {
  print('v2');
  return 'lazy';
}

""",
            ],
            r"""
main() {
  if (normal == null) {
    normal = 'v1';
  } else {
    normal = '';
  }
  foo();
}
""",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['v1']),
            const ProgramExpectation(
                const <String>['v2', 'lazy']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that superclasses of directly instantiated classes are also emitted.
class A {
}

class B extends A {
}

main() {
""",
            const [
                r"""
  print('v1');
""",
                r"""
  new B();
  print('v2');
""",
            ],
            r"""
}
""",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['v1']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that interceptor classes are handled correctly.

main() {
""",
            const [
                r"""
  print('v1');
""",
                r"""
  ['v2'].forEach(print);
""",
            ],
            r"""
}
""",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['v1']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that newly instantiated superclasses are handled correctly when there
// is more than one change.

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
""",
            const [
                r"""
  new B().foo();
""",
                r"""
  new B().foo();
""",
            r"""
  new A().bar();
""",
            ],
            r"""
}
""",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['Called foo']),
            const ProgramExpectation(
                const <String>['Called foo']),
            const ProgramExpectation(
                const <String>['Called bar']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that newly instantiated subclasses are handled correctly when there is
// more than one change.

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
""",
            const [
                r"""
  new A().foo();
""",
                r"""
  new A().foo();
""",
            r"""
  new B().bar();
""",
            ],
            r"""
}
""",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['Called foo']),
            const ProgramExpectation(
                const <String>['Called foo']),
            const ProgramExpectation(
                const <String>['Called bar']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that constants are handled correctly.

class C {
  final String value;
  const C(this.value);
}

main() {
""",
            const [
                r"""
  print(const C('v1').value);
""",
                r"""
  print(const C('v2').value);
""",
            ],
            r"""
}
""",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['v1']),
            const ProgramExpectation(
                const <String>['v2']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that an instance field can be added to a compound declaration.

class C {
""",
            const [
                r"""
  int x;
""",
                r"""
  int x, y;
""",
            ],
                r"""
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
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>[
                    '[instance] is null', 'v1', '[instance.y] threw']),
            const ProgramExpectation(
                const <String>['v1', 'v2'],
                // TODO(ahe): Shouldn't throw.
                compileUpdatesShouldThrow: true),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that an instance field can be removed from a compound declaration.

class C {
""",
            const [
                r"""
  int x, y;
""",
                r"""
  int x;
""",
            ],
                r"""
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
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['[instance] is null', 'v1', 'v2']),
            const ProgramExpectation(
                const <String>['v1', '[instance.y] threw'],
                // TODO(ahe): Shouldn't throw.
                compileUpdatesShouldThrow: true),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that a static field can be made an instance field.

class C {
""",

            const [
                r"""
  static int x;
""",
                r"""
  int x;
""",
            ],
                r"""
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
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['[instance] is null', 'v1', '[instance.x] threw']),
            const ProgramExpectation(
                const <String>['[C.x] threw', 'v2'],
                // TODO(ahe): Shouldn't throw.
                compileUpdatesShouldThrow: true),
        ]),

    const EncodedResult(
        const [
            r"""
// Test that instance field can be made static.

class C {
""",
            const [
                r"""
  int x;
""",
                r"""
  static int x;
""",
            ],
            r"""
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
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['[instance] is null', '[C.x] threw', 'v1']),
            const ProgramExpectation(
                const <String>['v2', '[instance.x] threw'],
                // TODO(ahe): Shouldn't throw.
                compileUpdatesShouldThrow: true),
        ]),

    const EncodedResult(
        const [
            r"""
// Test compound constants.

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
""",
            const [
                r"""
  print(const A('v1'));
  print(const B('v1'));
""",
                r"""
  print(const B(const A('v2')));
  print(const A(const B('v2')));
""",
            ],
            r"""
}
""",
        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['A(v1)', 'B(v1)']),
            const ProgramExpectation(
                const <String>['B(A(v2))', 'A(B(v2))']),
        ]),

    const EncodedResult(
        const [
            r"""
// Test constants of new classes.

class A {
  final value;
  const A(this.value);

  toString() => 'A($value)';
}
""",
            const [
                "",
                r"""
class B {
  final value;
  const B(this.value);

  toString() => 'B($value)';
}

""",
            ],
            r"""
main() {
""",

            const [
                r"""
  print(const A('v1'));
""",
                r"""
  print(const A('v2'));
  print(const B('v2'));
  print(const B(const A('v2')));
  print(const A(const B('v2')));
""",
            ],
            r"""
}
""",

        ],
        const <ProgramExpectation>[
            const ProgramExpectation(
                const <String>['A(v1)']),
            const ProgramExpectation(
                const <String>['A(v2)', 'B(v2)', 'B(A(v2))', 'A(B(v2))']),
        ]),

    const EncodedResult(
        r"""
==> main.dart <==
// Test that a change in a part is handled.
library test.main;

part 'part.dart';


==> part.dart.patch <==
part of test.main;

main() {
<<<<<<<
  print('Hello, World!');
=======
  print('Hello, Brave New World!');
>>>>>>>
}
""",
        const [
            'Hello, World!',
            'Hello, Brave New World!',
        ]),

    const EncodedResult(
        r"""
==> main.dart.patch <==
// Test that a change in library name is handled.
<<<<<<<
library test.main1;
=======
library test.main2;
>>>>>>>

main() {
  print('Hello, World!');
}
""",
        const [
            'Hello, World!',
            const ProgramExpectation(
                const <String>['Hello, World!'],
                // TODO(ahe): Shouldn't throw.
                compileUpdatesShouldThrow: true),
        ]),

    const EncodedResult(
        r"""
==> main.dart.patch <==
// Test that adding an import is handled.
<<<<<<<
=======
import 'dart:core';
>>>>>>>

main() {
  print('Hello, World!');
}
""",
        const [
            'Hello, World!',
            const ProgramExpectation(
                const <String>['Hello, World!'],
                // TODO(ahe): Shouldn't throw.
                compileUpdatesShouldThrow: true),
        ]),

    const EncodedResult(
        r"""
==> main.dart.patch <==
// Test that adding an export is handled.
<<<<<<<
=======
export 'dart:core';
>>>>>>>

main() {
  print('Hello, World!');
}
""",
        const [
            'Hello, World!',
            const ProgramExpectation(
                const <String>['Hello, World!'],
                // TODO(ahe): Shouldn't throw.
                compileUpdatesShouldThrow: true),
        ]),

    const EncodedResult(
        r"""
==> main.dart.patch <==
// Test that adding a part is handled.
library test.main;

<<<<<<<
=======
part 'part.dart';
>>>>>>>

main() {
  print('Hello, World!');
}


==> part.dart <==
part of test.main
""",
        const [
            'Hello, World!',
            const ProgramExpectation(
                const <String>['Hello, World!'],
                // TODO(ahe): Shouldn't throw.
                compileUpdatesShouldThrow: true),
        ]),

    const EncodedResult(
        r"""
==> main.dart <==
// Test that changes in multiple libraries is handled.
import 'library1.dart' as lib1;
import 'library2.dart' as lib2;

main() {
  lib1.method();
  lib2.method();
}


==> library1.dart.patch <==
library test.library1;

method() {
<<<<<<<
  print('lib1.v1');
=======
  print('lib1.v2');
=======
  print('lib1.v3');
>>>>>>>
}


==> library2.dart.patch <==
library test.library2;

method() {
<<<<<<<
  print('lib2.v1');
=======
  print('lib2.v2');
=======
  print('lib2.v3');
>>>>>>>
}
""",
        const [
            const <String>['lib1.v1', 'lib2.v1'],
            const <String>['lib1.v2', 'lib2.v2'],
            const <String>['lib1.v3', 'lib2.v3'],
        ]),
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
    String skipParameter = Uri.splitQueryString(window.location.search)['skip'];
    if (skipParameter != null) {
      skip = int.parse(skipParameter);
    }
    String verboseParameter =
        Uri.splitQueryString(window.location.search)['verbose'];
    verboseStatus = verboseParameter != null;
  }
  testCount += skip;

  return asyncTest(() => Future.forEach(tests.skip(skip), compileAndRun)
      .then(updateSummary));
}

SpanElement summary;

int testCount = 1;

bool verboseStatus = false;

void updateSummary(_) {
  summary.text = " (${testCount - 1}/${tests.length})";
}

Future compileAndRun(EncodedResult encodedResult) {
  updateSummary(null);
  List<ProgramResult> programs = encodedResult.decode();
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
          Uri base = test.scriptUri;
          Map<String, String> code = program.code is String
              ? { 'main.dart': program.code }
              : program.code;
          Map<Uri, Uri> uriMap = <Uri, Uri>{};
          for (String name in code.keys) {
            Uri uri = base.resolve('$name?v${version++}');
            inputProvider.cachedSources[uri] = new Future.value(code[name]);
            uriMap[base.resolve(name)] = uri;
          }
          Future future = test.incrementalCompiler.compileUpdates(
              uriMap, logVerbose: logger, logTime: logger);
          bool compileUpdatesThrew = false;
          future = future.catchError((error, trace) {
            String statusMessage;
            Future result;
            compileUpdatesThrew = true;
            if (program.compileUpdatesShouldThrow &&
                error is IncrementalCompilationFailed) {
              statusMessage = "Expected error in compileUpdates.";
              result = null;
            } else {
              statusMessage = "Unexpected error in compileUpdates.";
              result = new Future.error(error, trace);
            }
            status.append(new HeadingElement.h3()..appendText(statusMessage));
            return result;
          });
          return future.then((String update) {
            if (program.compileUpdatesShouldThrow) {
              Expect.isTrue(
                  compileUpdatesThrew,
                  "Expected an exception in compileUpdates");
              Expect.isNull( update, "Expected update == null");
              return null;
            }
            print({'update': update});
            iframe.contentWindow.postMessage(['apply-update', update], '*');

            return listener.expect(
                program.messagesWith('iframe-dart-updated-main-done'))
                .then((_) {
                  // TODO(ahe): Enable SerializeScopeTestCase for multiple
                  // parts.
                  if (program.code is! String) return null;
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
    if (!verboseStatus) status.remove();
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

DivElement numberedLines(code) {
  if (code is! Map) {
    code = {'main.dart': code};
  }
  DivElement result = new DivElement();
  code.forEach((String fileName, String code) {
    result.append(new HeadingElement.h4()..appendText(fileName));
    DivElement lines = new DivElement();
    result.append(lines);
    lines.classes.add("output");

    for (String text in splitLines(code)) {
      PreElement line = new PreElement()
          ..appendText(text.trimRight())
          ..classes.add("line");
      lines.append(line);
    }
  });
  return result;
}

StyleElement lineNumberStyle() {
  StyleElement style = new StyleElement()..appendText('''
h2, h3, h4 {
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
