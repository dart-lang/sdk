// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'compiler_helper.dart';
import "package:expect/expect.dart";

compile(String source) {
  Uri uri = new Uri('test:code');
  var compiler = compilerFor(source, uri);
  compiler.runCompiler(uri);
  return compiler;
}

test1() {
  var compiler = compile(r"""
class A<T extends T> {}

void main() {
  new A();
}
""");

  Expect.isFalse(compiler.compilationFailed);
  Expect.isTrue(compiler.errors.isEmpty,
                'unexpected errors: ${compiler.errors}');
  Expect.equals(1, compiler.warnings.length,
                'expected exactly one warning, but got ${compiler.warnings}');

  Expect.equals(MessageKind.CYCLIC_TYPE_VARIABLE,
                compiler.warnings[0].message.kind);
  Expect.equals("T", compiler.warnings[0].node.toString());
}

test2() {
  var compiler = compile(r"""
class B<T extends S, S extends T> {}

void main() {
  new B();
}
""");

  Expect.isFalse(compiler.compilationFailed);
  print(compiler.errors);
  Expect.isTrue(compiler.errors.isEmpty, 'unexpected errors');
  Expect.equals(2, compiler.warnings.length,
                'expected exactly one error, but got ${compiler.warnings}');

  Expect.equals(MessageKind.CYCLIC_TYPE_VARIABLE,
                compiler.warnings[0].message.kind);
  Expect.equals("T", compiler.warnings[0].node.toString());

  Expect.equals(MessageKind.CYCLIC_TYPE_VARIABLE,
                compiler.warnings[1].message.kind);
  Expect.equals("S", compiler.warnings[1].node.toString());
}

test3() {
  var compiler = compile(r"""
class C<T extends S, S extends U, U extends T> {}

void main() {
  new C();
}
""");

  Expect.isFalse(compiler.compilationFailed);
  print(compiler.errors);
  Expect.isTrue(compiler.errors.isEmpty, 'unexpected errors');
  Expect.equals(3, compiler.warnings.length,
                'expected exactly one error, but got ${compiler.warnings}');

  Expect.equals(MessageKind.CYCLIC_TYPE_VARIABLE,
                compiler.warnings[0].message.kind);
  Expect.equals("T", compiler.warnings[0].node.toString());

  Expect.equals(MessageKind.CYCLIC_TYPE_VARIABLE,
                compiler.warnings[1].message.kind);
  Expect.equals("S", compiler.warnings[1].node.toString());

  Expect.equals(MessageKind.CYCLIC_TYPE_VARIABLE,
                compiler.warnings[2].message.kind);
  Expect.equals("U", compiler.warnings[2].node.toString());
}

test4() {
  var compiler = compile(r"""
class D<T extends S, S extends U, U extends S> {}

void main() {
  new D();
}
""");

  Expect.isFalse(compiler.compilationFailed);
  print(compiler.errors);
  Expect.isTrue(compiler.errors.isEmpty, 'unexpected errors');
  Expect.equals(2, compiler.warnings.length,
                'expected exactly one error, but got ${compiler.warnings}');

  Expect.equals(MessageKind.CYCLIC_TYPE_VARIABLE,
                compiler.warnings[0].message.kind);
  Expect.equals("S", compiler.warnings[0].node.toString());

  Expect.equals(MessageKind.CYCLIC_TYPE_VARIABLE,
                compiler.warnings[1].message.kind);
  Expect.equals("U", compiler.warnings[1].node.toString());
}

main() {
  test1();
  test2();
  test3();
  test4();
}
