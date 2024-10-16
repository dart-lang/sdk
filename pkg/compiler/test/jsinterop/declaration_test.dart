// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library jsinterop.abstract_test;

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/util/memory_compiler.dart';

const List<Test> TESTS = const <Test>[
  const SingleTest('Empty js-interop class.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
class A {}

main() => A();
''', warnings: const []),
  const SingleTest('Js-interop class with external method.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
class A {
  external method();
}

main() => A();
'''),
  const SingleTest(
      'Js-interop class with external method with required parameters.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
class A {
  external method(a, b);
}

main() => A();
'''),
  const SingleTest(
      'Js-interop class with external method with optional parameters.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
class A {
  external method([a, b]);
}

main() => A();
'''),
  const SingleTest(
      'Js-interop class with external method with optional parameters '
          'with default values.',
      '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
class A {
  external method([a = 1, b = 2]);
}

main() => A();
'''),
  const SingleTest('Js-interop class with static method.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
class A {
  static method() {}
}

main() => A();
'''),
  const SingleTest('Js-interop class that extends a js-interop class.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
abstract class A {
  method();
}

@JS()
class B extends A {
  external method();
}

main() => B();
'''),
  const SingleTest(
      'Js-interop class that extends a js-interop class, '
          'reversed declaration order.',
      '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
class B extends A {
  external method();
}

@JS()
abstract class A {
  method();
}

main() => B();
'''),
  const MultiTest(
      'Js-interop class that extends a js-interop class from a different '
      'library.',
      const {
        'main.dart': '''
@JS()
library test;

import 'package:js/js.dart';
import 'other.dart';

@JS()
class B extends A {
  external method();
}

main() => B();
''',
        'other.dart': '''
@JS()
library other;

import 'package:js/js.dart';

@JS()
abstract class A {
  method();
}
'''
      }),
  const SingleTest('Js-interop class that implements a regular class.', '''
@JS()
library test;

import 'package:js/js.dart';

abstract class A {
  method();
}

@JS()
class B implements A {
  external method();
}

main() => B();
'''),
  const SingleTest('Js-interop class that implements a js-interop class.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
abstract class A {
  method();
}

@JS()
class B implements A {
  external method();
}

main() => B();
'''),
  const SingleTest('Js-interop class with generative constructor.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
class A {
  external A();
}

main() => A();
'''),
  const SingleTest('Js-interop class with factory constructor.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
class A {
  external A._();

  factory A() => A._();
}

main() => A();
'''),
  const SingleTest('Empty anonymous js-interop class.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
@anonymous
class A {}

main() => A();
'''),
  const SingleTest(
      'Anonymous js-interop class with generative constructor.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
@anonymous
class A {
  external A();
}

main() => A();
'''),
  const SingleTest('Anonymous js-interop class with factory constructor.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
@anonymous
class A {
  external A._();

  factory A() => A._();
}

main() => A();
'''),
  const SingleTest(
      'Anonymous js-interop class with external factory constructor.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
@anonymous
class A {
  external factory A();
}

main() => A();
'''),
  const SingleTest('External factory constructor with named parameters.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
@anonymous
class A {
  external factory A({a, b});
}

main() => A(a: 1);
'''),
  const SingleTest(
      'External factory constructor with named parameters '
          'with default parameters.',
      '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
@anonymous
class A {
  external factory A({a = 1, b = 2});
}

main() => A(a: 1);
'''),
  const SingleTest('Function-typed return type', '''
@JS()
library lib;

import 'package:js/js.dart';

@JS('func')
external int Function() func();

main() {
  func();
}
'''),
  const SingleTest(
    'Non-external field.',
    '''
@JS()
library lib;

import 'package:js/js.dart';

@JS()
@anonymous
class B {
  int Function()? callback;
}

@JS('makeB')
external B makeB();

main() {
  makeB().callback!();
}
''',
    // TODO(34174): Disallow js-interop fields.
    /*errors: const [MessageKind.IMPLICIT_JS_INTEROP_FIELD_NOT_SUPPORTED]*/
  ),
];

void main(List<String> args) {
  asyncTest(() async {
    for (Test test in TESTS) {
      bool run = true;
      if (args.isNotEmpty) {
        run = false;
        for (String arg in args) {
          if (test.name.contains(arg)) {
            run = true;
            break;
          }
        }
      }
      if (run) {
        await runTest(test);
      }
    }
  });
}

abstract class Test {
  final String name;
  final List<MessageKind> errors;
  final List<MessageKind> warnings;

  const Test(this.name, {required this.errors, required this.warnings});
  String get source;
  Map<String, String> get sources;
}

class SingleTest extends Test {
  @override
  final String source;

  const SingleTest(super.name, this.source,
      {super.errors = const <MessageKind>[],
      super.warnings = const <MessageKind>[]});

  @override
  Map<String, String> get sources => {'main.dart': source};
}

class MultiTest extends Test {
  @override
  final Map<String, String> sources;

  const MultiTest(super.name, this.sources,
      {super.errors = const <MessageKind>[],
      super.warnings = const <MessageKind>[]});

  @override
  String get source => sources['main.dart']!;
}

runTest(Test test) async {
  print('==${test.name}======================================================');
  print(test.source);
  await runTestInternal(test);
}

runTestInternal(Test test) async {
  DiagnosticCollector collector = DiagnosticCollector();
  List<String> options = <String>[];
  // TODO(redemption): Enable inlining.
  options.add(Flags.disableInlining);
  await runCompiler(
      diagnosticHandler: collector,
      options: options,
      memorySourceFiles: test.sources);
  Expect.equals(
      test.errors.length, collector.errors.length, 'Unexpected error count.');
  Expect.equals(test.warnings.length, collector.warnings.length,
      'Unexpected warning count.');
  for (int index = 0; index < test.errors.length; index++) {
    Expect.equals(test.errors[index],
        collector.errors.elementAt(index).messageKind, 'Unexpected error.');
  }
  for (int index = 0; index < test.warnings.length; index++) {
    Expect.equals(test.warnings[index],
        collector.warnings.elementAt(index).messageKind, 'Unexpected warning.');
  }
}
