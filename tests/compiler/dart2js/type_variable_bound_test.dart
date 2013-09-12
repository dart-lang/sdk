// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';
import "package:expect/expect.dart";

Future compile(String source) {
  Uri uri = Uri.parse('test:code');
  var compiler = compilerFor(source, uri, analyzeOnly: true);
  compiler.diagnosticHandler = createHandler(compiler, source);
  return compiler.runCompiler(uri).then((_) {
    return compiler;
  });
}

test(String source, {var errors, var warnings}) {
  if (errors == null) errors = [];
  if (errors is! List) errors = [errors];
  if (warnings == null) warnings = [];
  if (warnings is! List) warnings = [warnings];
  asyncTest(() => compile(source).then((compiler) {
    Expect.equals(!errors.isEmpty, compiler.compilationFailed);
    Expect.equals(errors.length, compiler.errors.length,
                  'unexpected error count: ${compiler.errors.length} '
                  'expected ${errors.length}');
    Expect.equals(warnings.length, compiler.warnings.length,
                  'unexpected warning count: ${compiler.warnings.length} '
                  'expected ${warnings.length}');

    for (int i = 0 ; i < errors.length ; i++) {
      Expect.equals(errors[i], compiler.errors[i].message.kind);
    }
    for (int i = 0 ; i < warnings.length ; i++) {
      Expect.equals(warnings[i], compiler.warnings[i].message.kind);
    }
  }));
}

test1() {
  asyncTest(() => compile(r"""
class A<T extends T> {}

void main() {
  new A();
}
""").then((compiler) {
    Expect.isFalse(compiler.compilationFailed);
    Expect.isTrue(compiler.errors.isEmpty,
                  'unexpected errors: ${compiler.errors}');
    Expect.equals(1, compiler.warnings.length,
                  'expected exactly one warning, but got ${compiler.warnings}');

    Expect.equals(MessageKind.CYCLIC_TYPE_VARIABLE,
                  compiler.warnings[0].message.kind);
    Expect.equals("T", compiler.warnings[0].node.toString());
  }));
}

test2() {
  asyncTest(() => compile(r"""
class B<T extends S, S extends T> {}

void main() {
  new B();
}
""").then((compiler) {
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
  }));
}

test3() {
  asyncTest(() => compile(r"""
class C<T extends S, S extends U, U extends T> {}

void main() {
  new C();
}
""").then((compiler) {
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
  }));
}

test4() {
  asyncTest(() => compile(r"""
class D<T extends S, S extends U, U extends S> {}

void main() {
  new D();
}
""").then((compiler) {
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
  }));
}

test5() {
  test(r"""
class A<T extends num> {}

void main() {
  new A();
  new A<num>();
  new A<dynamic>();
  new A<int>();
  new A<double>();
}
""");
}

test6() {
  test(r"""
class A<T extends num> {}

void main() {
  new A<String>();
}
""", warnings: MessageKind.INVALID_TYPE_VARIABLE_BOUND);
}

test7() {
  test(r"""
class A<T extends num> {}
class B<T> extends A<T> {} // Warning produced here.

void main() {
  new B(); // No warning produced here.
  new B<String>(); // No warning produced here.
}
""", warnings: MessageKind.INVALID_TYPE_VARIABLE_BOUND);
}

test8() {
  test(r"""
class B<T extends B<T>> {}
class C<T extends B<T>> extends B<T> {}
class D<T extends C<T>> extends C<T> {}
class E<T extends E<T>> extends D<T> {}
class F extends E<F> {}

void main() {
  new B();
  new B<dynamic>();
  new B<F>();
  new B<B<F>>();
  new C();
  new C<dynamic>();
  new C<B<F>>();
  new D();
  new D<dynamic>();
  new D<C<F>>();
  new E();
  new E<dynamic>();
  new E<E<F>>();
  new F();
}
""");
}

test9() {
  test(r"""
class B<T extends B<T>> {}
class C<T extends B<T>> extends B<T> {}
class D<T extends C<T>> extends C<T> {}
class E<T extends E<T>> extends D<T> {}
class F extends E<F> {}

void main() {
  new D<B<F>>(); // Warning: B<F> is not a subtype of C<T>.
  new E<D<F>>(); // Warning: E<F> is not a subtype of E<T>.
}
""", warnings: [MessageKind.INVALID_TYPE_VARIABLE_BOUND,
                MessageKind.INVALID_TYPE_VARIABLE_BOUND]);
}

main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
  test7();
  test8();
  test9();
}
