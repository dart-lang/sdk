// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int zero;
  int? zeroOrNull;

  A(this.zero, [this.zeroOrNull]);
}

int? test1(A? a) => a?.zero!;
int? test2(A? a) => a?.zeroOrNull!;
bool? test3(A? a) => a?.zero!.isEven;
bool? test4(A? a) => a?.zeroOrNull!.isEven;

class Foo {
  Bar? bar;

  Foo(this.bar);

  Bar? operator [](int? index) => index != null ? new Bar(index) : null;
}

class Bar {
  int baz;

  Bar(this.baz);

  int operator [](int index) => index;

  bool operator ==(Object other) => other is Bar && baz == other.baz;
}

Bar? test5(Foo? foo) => foo?.bar!;
int? test6(Foo? foo) => foo?.bar!.baz;
int? test7(Foo? foo, int baz) => foo?.bar![baz];
Bar? test8(Foo? foo, int? bar) => foo?[bar]!;
int? test9(Foo? foo, int? bar) => foo?[bar]!.baz;
test10(Foo? foo, int? bar, int baz) => foo?[bar]![baz];

main() {
  expect(0, test1(new A(0)));
  expect(null, test1(null));

  expect(0, test2(new A(0, 0)));
  expect(null, test2(null));
  throws(() => test2(new A(0, null)));

  expect(true, test3(new A(0)));
  expect(null, test3(null));

  expect(true, test4(new A(0, 0)));
  expect(null, test4(null));
  throws(() => test4(new A(0, null)));

  expect(new Bar(0), test5(new Foo(new Bar(0))));
  expect(null, test5(null));
  throws(() => test5(new Foo(null)));

  expect(0, test6(new Foo(new Bar(0))));
  expect(null, test6(null));
  throws(() => test6(new Foo(null)));

  expect(42, test7(new Foo(new Bar(0)), 42));
  expect(null, test7(null, 42));
  throws(() => test7(new Foo(null), 42));

  expect(new Bar(42), test8(new Foo(new Bar(0)), 42));
  expect(null, test8(null, 42));
  throws(() => test8(new Foo(new Bar(0)), null));

  expect(42, test9(new Foo(new Bar(0)), 42));
  expect(null, test9(null, 42));
  throws(() => test9(new Foo(new Bar(0)), null));

  expect(87, test10(new Foo(new Bar(0)), 42, 87));
  expect(null, test10(null, 42, 87));
  throws(() => test10(new Foo(new Bar(0)), null, 87));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

throws(void Function() f) {
  try {
    f();
  } catch (_) {
    return;
  }
  throw 'Missing exception';
}
