// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';
import "package:expect/expect.dart";

Future compile(String source) {
  Uri uri = Uri.parse('test:code');
  var compiler =
      compilerFor(source, uri, analyzeOnly: true, enableTypeAssertions: true);
  compiler.diagnosticHandler = createHandler(compiler, source);
  return compiler.run(uri).then((_) {
    return compiler;
  });
}

test(String source, {var errors, var warnings}) {
  if (errors == null) errors = [];
  if (errors is! List) errors = [errors];
  if (warnings == null) warnings = [];
  if (warnings is! List) warnings = [warnings];
  asyncTest(() => compile(source).then((compiler) {
    DiagnosticCollector collector = compiler.diagnosticCollector;
    Expect.equals(!errors.isEmpty, compiler.compilationFailed);
    Expect.equals(errors.length, collector.errors.length,
                  'unexpected error count: ${collector.errors.length} '
                  'expected ${errors.length}');
    Expect.equals(warnings.length, collector.warnings.length,
                  'unexpected warning count: ${collector.warnings.length} '
                  'expected ${warnings.length}');

    for (int i = 0 ; i < errors.length ; i++) {
      Expect.equals(errors[i], collector.errors.elementAt(i).message.kind);
    }
    for (int i = 0 ; i < warnings.length ; i++) {
      Expect.equals(warnings[i], collector.warnings.elementAt(i).message.kind);
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
    DiagnosticCollector collector = compiler.diagnosticCollector;
    Expect.isFalse(compiler.compilationFailed);
    Expect.isTrue(collector.errors.isEmpty,
                  'unexpected errors: ${collector.errors}');
    Expect.equals(1, collector.warnings.length,
                  'expected exactly one warning, but got ${collector.warnings}');

    print(collector.warnings.elementAt(0));
    Expect.equals(MessageKind.CYCLIC_TYPE_VARIABLE,
                  collector.warnings.elementAt(0).message.kind);
    Expect.equals("T",
        collector.warnings.elementAt(0).message.arguments['typeVariableName']);
  }));
}

test2() {
  asyncTest(() => compile(r"""
class B<T extends S, S extends T> {}

void main() {
  new B();
}
""").then((compiler) {
    DiagnosticCollector collector = compiler.diagnosticCollector;
    Expect.isFalse(compiler.compilationFailed);
    print(collector.errors);
    Expect.isTrue(collector.errors.isEmpty, 'unexpected errors');
    Expect.equals(2, collector.warnings.length,
                  'expected exactly two errors, but got ${collector.warnings}');

    Expect.equals(MessageKind.CYCLIC_TYPE_VARIABLE,
                  collector.warnings.elementAt(0).message.kind);
    Expect.equals("T",
        collector.warnings.elementAt(0).message.arguments['typeVariableName']);

    Expect.equals(MessageKind.CYCLIC_TYPE_VARIABLE,
                  collector.warnings.elementAt(1).message.kind);
    Expect.equals("S",
        collector.warnings.elementAt(1).message.arguments['typeVariableName']);
  }));
}

test3() {
  asyncTest(() => compile(r"""
class C<T extends S, S extends U, U extends T> {}

void main() {
  new C();
}
""").then((compiler) {
    DiagnosticCollector collector = compiler.diagnosticCollector;
    Expect.isFalse(compiler.compilationFailed);
    print(collector.errors);
    Expect.isTrue(collector.errors.isEmpty, 'unexpected errors');
    Expect.equals(3, collector.warnings.length,
                  'expected exactly one error, but got ${collector.warnings}');

    Expect.equals(MessageKind.CYCLIC_TYPE_VARIABLE,
                  collector.warnings.elementAt(0).message.kind);
    Expect.equals("T",
        collector.warnings.elementAt(0).message.arguments['typeVariableName']);

    Expect.equals(MessageKind.CYCLIC_TYPE_VARIABLE,
                  collector.warnings.elementAt(1).message.kind);
    Expect.equals("S",
        collector.warnings.elementAt(1).message.arguments['typeVariableName']);

    Expect.equals(MessageKind.CYCLIC_TYPE_VARIABLE,
                  collector.warnings.elementAt(2).message.kind);
    Expect.equals("U",
        collector.warnings.elementAt(2).message.arguments['typeVariableName']);
  }));
}

test4() {
  asyncTest(() => compile(r"""
class D<T extends S, S extends U, U extends S> {}

void main() {
  new D();
}
""").then((compiler) {
    DiagnosticCollector collector = compiler.diagnosticCollector;
    Expect.isFalse(compiler.compilationFailed);
    print(collector.errors);
    Expect.isTrue(collector.errors.isEmpty, 'unexpected errors');
    Expect.equals(2, collector.warnings.length,
                  'expected exactly one error, but got ${collector.warnings}');

    Expect.equals(MessageKind.CYCLIC_TYPE_VARIABLE,
                  collector.warnings.elementAt(0).message.kind);
    Expect.equals("S",
        collector.warnings.elementAt(0).message.arguments['typeVariableName']);

    Expect.equals(MessageKind.CYCLIC_TYPE_VARIABLE,
                  collector.warnings.elementAt(1).message.kind);
    Expect.equals("U",
        collector.warnings.elementAt(1).message.arguments['typeVariableName']);
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

test10() {
  test(r"""
class A {
  const A();
}
class Test<T extends A> {
  final T x = const A();
  const Test();
}
main() {
  print(const Test<A>());
}
""");
}

// TODO(het): The error is reported twice because both the Dart and JS constant
// compilers are run on the const constructor, investigate why.
test11() {
  test(r"""
class A {
  const A();
}
class B extends A {
  const B();
}
class Test<T extends A> {
  final T x = const A();
  const Test();
}
main() {
  print(const Test<B>());
}
""", errors: [MessageKind.NOT_ASSIGNABLE, MessageKind.NOT_ASSIGNABLE]);
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
  test10();
  test11();
}
