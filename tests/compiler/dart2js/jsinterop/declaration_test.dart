// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library jsinterop.abstract_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/commandline_options.dart';
import '../memory_compiler.dart';

const List<Test> TESTS = const <Test>[
  const Test('Empty js-interop class.', '''
@JS() 
library test;

import 'package:js/js.dart';

@JS()
class A {}

main() => new A();
''', warnings: const []),
  const Test('Js-interop class with external method.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
class A {
  external method();
}

main() => new A();
'''),
  const Test(
      'Js-interop class with external method with required parameters.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
class A {
  external method(a, b);
}

main() => new A();
'''),
  const Test(
      'Js-interop class with external method with optional parameters.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
class A {
  external method([a, b]);
}

main() => new A();
'''),
  const Test(
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

main() => new A();
'''),
  const Test('Js-interop class with external method with named parameters.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
class A {
  external method({a, b});
}

main() => new A();
''', errors: const [MessageKind.JS_INTEROP_METHOD_WITH_NAMED_ARGUMENTS]),
  const Test('Js-interop class with static method.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
class A {
  static method() {}
}

main() => new A();
'''),
  const Test('Js-interop class with instance method.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
class A {
  method() {}
}

main() => new A();
''', errors: const [MessageKind.JS_INTEROP_CLASS_NON_EXTERNAL_MEMBER]),
  const Test(
      'Js-interop class with abstract getter.',
      '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
class A {
  get foo;
}

main() => new A();
''',
      warnings: const [MessageKind.ABSTRACT_GETTER],
      skipForKernel: true),
  const Test('Js-interop class that extends a regular class.', '''
@JS()
library test;

import 'package:js/js.dart';

abstract class A {
  method();
}

@JS()
class B extends A {
  external method();
}

main() => new B();
''', errors: const [MessageKind.JS_INTEROP_CLASS_CANNOT_EXTEND_DART_CLASS]),
  const Test('Js-interop class that extends a js-interop class.', '''
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

main() => new B();
'''),
  const Test(
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

main() => new B();
'''),
  const Test.multi(
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

main() => new B();
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
  const Test('Js-interop class that implements a regular class.', '''
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

main() => new B();
'''),
  const Test('Js-interop class that implements a js-interop class.', '''
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

main() => new B();
'''),
  const Test('Js-interop class with generative constructor.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
class A {
  A();
}

main() => new A();
'''),
  const Test('Js-interop class with factory constructor.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
class A {
  factory A() => null;
}

main() => new A();
'''),
  const Test('Empty anonymous js-interop class.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
@anonymous
class A {}

main() => new A();
'''),
  const Test('Anonymous js-interop class with generative constructor.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
@anonymous
class A {
  A();
}

main() => new A();
'''),
  const Test('Anonymous js-interop class with factory constructor.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
@anonymous
class A {
  factory A() => null;
}

main() => new A();
'''),
  const Test(
      'Anonymous js-interop class with external factory constructor.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
@anonymous
class A {
  external factory A();
}

main() => new A();
'''),
  const Test('External factory constructor with named parameters.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
@anonymous
class A {
  external factory A({a, b});
}

main() => new A(a: 1);
'''),
  const Test(
      'External factory constructor with named parameters '
      'with default parameters.',
      '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
@anonymous
class A {
  external factory A({a: 1, b: 2});
}

main() => new A(a: 1);
'''),
  const Test('External factory constructor with required parameters.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
@anonymous
class A {
  external factory A(a, b);
}

main() => new A(1, 2);
''', errors: const [
    MessageKind.JS_OBJECT_LITERAL_CONSTRUCTOR_WITH_POSITIONAL_ARGUMENTS
  ]),
  const Test('External factory constructor with optional parameters.', '''
@JS()
library test;

import 'package:js/js.dart';

@JS()
@anonymous
class A {
  external factory A([a, b]);
}

main() => new A(1);
''', errors: const [
    MessageKind.JS_OBJECT_LITERAL_CONSTRUCTOR_WITH_POSITIONAL_ARGUMENTS
  ]),
];

void main() {
  asyncTest(() async {
    for (Test test in TESTS) {
      await runTest(test);
    }
  });
}

class Test {
  final String name;
  final String _source;
  final Map<String, String> _sources;
  final List<MessageKind> errors;
  final List<MessageKind> warnings;
  final bool skipForKernel;

  const Test(this.name, this._source,
      {this.errors: const <MessageKind>[],
      this.warnings: const <MessageKind>[],
      this.skipForKernel: false})
      : _sources = null;

  const Test.multi(this.name, this._sources,
      {this.errors: const <MessageKind>[],
      this.warnings: const <MessageKind>[],
      this.skipForKernel: false})
      : _source = null;

  String get source => _source != null ? _source : _sources['main.dart'];

  Map<String, String> get sources =>
      _source != null ? {'main.dart': _source} : _sources;
}

runTest(Test test) async {
  print('==${test.name}======================================================');
  print(test.source);
  await runTestInternal(test, useKernel: false);
  if (!test.skipForKernel) {
    await runTestInternal(test, useKernel: true);
  }
}

runTestInternal(Test test, {bool useKernel}) async {
  DiagnosticCollector collector = new DiagnosticCollector();
  List<String> options = <String>[];
  if (useKernel) {
    options.add(Flags.useKernel);
  }
  print('--useKernel=${useKernel}--------------------------------------------');
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
