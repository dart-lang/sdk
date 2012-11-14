// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:uri';

import 'compiler_helper.dart';

import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
       show MessageKind;

const String SOURCE = """
class Foo {
  // Deliberately not const to ensure compile error.
  Foo(_);
}

@Bar()
class Bar {
  const Bar();
}

@Foo('x')
typedef void VoidFunction();

@Foo('y')
class MyClass {}

main() {
}
""";

main() {
  Uri uri = new Uri('test:code');
  var compiler = compilerFor(SOURCE, uri, analyzeAll: false);
  compiler.runCompiler(uri);
  Expect.isFalse(compiler.compilationFailed);
  print(compiler.warnings);
  Expect.isTrue(compiler.warnings.isEmpty, 'unexpected warnings');
  Expect.isTrue(compiler.errors.isEmpty, 'unexpected errors');
  compiler = compilerFor(SOURCE, uri, analyzeAll: true);
  compiler.runCompiler(uri);
  Expect.isTrue(compiler.compilationFailed);
  Expect.isTrue(compiler.warnings.isEmpty, 'unexpected warnings');
  Expect.equals(2, compiler.errors.length,
                'expected exactly two errors, but got ${compiler.errors}');

  Expect.equals(MessageKind.CONSTRUCTOR_IS_NOT_CONST,
                compiler.errors[0].message.kind);
  Expect.equals("Foo", compiler.errors[0].node.toString());

  Expect.equals(MessageKind.CONSTRUCTOR_IS_NOT_CONST,
                compiler.errors[1].message.kind);
  Expect.equals("Foo", compiler.errors[1].node.toString());
}
