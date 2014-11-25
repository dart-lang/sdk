// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.incremental_compilation_update_test;

import 'dart:html';

import 'dart:async' show
    Future;

import 'package:async_helper/async_helper.dart' show
    asyncTest;

import 'package:try/src/interaction_manager.dart' show
    splitLines;

import 'sandbox.dart' show
    appendIFrame,
    listener;

import 'web_compiler_test_case.dart' show
    WebCompilerTestCase,
    WebInputProvider;

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
    instance = new C();
  }
  instance.m();
}
""",
            const <String> ['v1']),
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
    closure = new C().m;
  }
  closure();
}
""",
            const <String> ['v1']),
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
    instance = new C();
  }
  try {
    instance.m();
  } catch (e) {
    print('v2');
  }
}
""",
            const <String> ['v1']),
        const ProgramResult(
            """
class C {
}
var instance;
main() {
  if (instance == null) {
    instance = new C();
  }
  try {
    instance.m();
  } catch (e) {
    print('v2');
  }
}
""",
            const <String> ['v2']),
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
    instance = new C();
  }
  instance.m();
}
""",
            const <String> ['v1']),
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
      print('v2');
    }
  }
}
var instance;
main() {
  if (instance == null) {
    instance = new C();
  }
  instance.m();
}
""",
            const <String> ['v1']),
        const ProgramResult(
            """
class C {
  m() {
    try {
      toplevel();
    } catch (e) {
      print('v2');
    }
  }
}
var instance;
main() {
  if (instance == null) {
    instance = new C();
  }
  instance.m();
}
""",
            const <String> ['v2']),
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
      print('v2');
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
    instance = new C();
  }
  instance.m();
}
""",
            const <String> ['v1']),
        const ProgramResult(
            """
class B {
}
class C {
  m() {
    try {
      B.staticMethod();
    } catch (e) {
      print('v2');
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
    instance = new C();
  }
  instance.m();
}
""",
            const <String> ['v2']),
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
    instance = new A();
//   } else {
//     instance = new B();
  }
  instance.m();
}
""",
            const <String>['Called A.m']),
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
    instance = new A();
//   } else {
//     instance = new B();
  }
  instance.m();
}
""",
            const <String>['Called A.m']),
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
    print('v1');
  }
}
""",
            const <String>['v1']),
        const ProgramResult(
            r"""
foo() {
  print('v2');
}

main() {
  try {
    foo();
  } catch(e) {
    print('v1');
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
    print('v1');
  }
}
""",
            const <String>['v1']),
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
    print('v1');
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
    instance = new C();
  }

  try {
    instance.foo();
  } catch(e) {
    print('v1');
  }
}
""",
            const <String>['v1']),
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
    instance = new C();
  }

  try {
    instance.foo();
  } catch(e) {
    print('v1');
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
    instance = new C();
  }

  instance.foo();
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

var instance;

main() {
  if (instance == null) {
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
    // TODO(ahe): Incremental compiler can't handle new noSuchMethod
    // situations, crashes when compiling a constructor which uses type
    // arguments.
    C.missing();
  } catch (e) {
  }
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
    instance = new C();
  }
  instance.m();
}
""",
            const <String>['v1']),
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
            const <String>['setter threw', 'getter threw']),
        const ProgramResult(
            r"""
class A {
  var x;
}

var instance;

main() {
  if (instance == null) {
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
    // TODO(ahe): The emitter still see the field, and we need to ensure that
    // old names aren't used again.
    const <ProgramResult>[
        const ProgramResult(
            r"""
class A {
  var x;
}

var instance;

main() {
  if (instance == null) {
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
            const <String>['v1']),
        const ProgramResult(
            r"""
class A {
}

var instance;

main() {
  if (instance == null) {
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
];

void main() {
  listener.start();

  document.head.append(lineNumberStyle());

  return asyncTest(() => Future.forEach(tests, compileAndRun));
}

int testCount = 1;

Future compileAndRun(List<ProgramResult> programs) {
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
                program.messagesWith('iframe-dart-updated-main-done'));
          });
        });
      });
    });
  }).then((_) {
    status.style.color = 'limegreen';

    // Remove the iframe to work around a bug in test.dart.
    iframe.remove();
  });
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

Element numberedLines(String code) {
  DivElement result = new DivElement();
  result.classes.add("output");

  for (String text in splitLines(code)) {
    Element line = new PreElement()
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
