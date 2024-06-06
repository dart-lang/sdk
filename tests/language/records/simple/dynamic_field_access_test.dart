// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  @override
  noSuchMethod(Invocation i) {
    Expect.fail('Should not be called.');
  }
}

bool get runtimeTrue => int.parse("1") == 1;

foo1() {
  return 'Hi from foo1';
}

foo2(int arg) {
  Expect.equals(42, arg);
  return 'Hi from foo2';
}

dynamic r1 = runtimeTrue ? (2, 3) as dynamic : A();
dynamic r2 = runtimeTrue ? (foo: 'hey') as dynamic : A();
dynamic r3 = runtimeTrue
    ? const (10, 'a', foo: [1], bar: (50, baz: 60)) as dynamic
    : A();
dynamic r4 = runtimeTrue ? (foo1, foo2: foo2) as dynamic : A();
dynamic r5 =
    runtimeTrue ? (10, $2: 20, $1000000000000000000: 'meow') as dynamic : A();

main() {
  Expect.equals(2, r1.$1);
  Expect.equals(3, r1.$2);
  Expect.throwsNoSuchMethodError(() => r1.$3);
  Expect.throwsNoSuchMethodError(() => r1.$4);
  Expect.throwsNoSuchMethodError(() => r1.$10000000000);
  Expect.throwsNoSuchMethodError(
      () => r1.$99999999999999999999999999999999999999999999999);
  Expect.throwsNoSuchMethodError(() => r1.foo);
  Expect.equals((2, 3).toString(), r1.toString());
  Expect.throwsNoSuchMethodError(() {
    r1.$1 = 4;
  });

  Expect.equals('hey', r2.foo);
  Expect.throwsNoSuchMethodError(() => r2.$1);
  Expect.throwsNoSuchMethodError(() => r2.$2);
  Expect.throwsNoSuchMethodError(() => r2.fo);
  Expect.throwsNoSuchMethodError(() => r2.$foo);
  Expect.throwsNoSuchMethodError(() => r2.bar);
  Expect.throwsNoSuchMethodError(() {
    r2.foo = 'bye';
  });

  Expect.equals(10, r3.$1);
  Expect.equals('a', r3.$2);
  Expect.equals(const [1], r3.foo);
  Expect.equals(const (50, baz: 60), r3.bar);
  Expect.equals(50, r3.bar.$1);
  Expect.equals(60, r3.bar.baz);
  Expect.throwsNoSuchMethodError(() => r3.$3);
  Expect.throwsNoSuchMethodError(() => r3.baz);
  Expect.throwsNoSuchMethodError(() => r3.bar.$2);
  Expect.throwsNoSuchMethodError(() => r3.bar.bar);
  Expect.throwsNoSuchMethodError(() {
    r3.$1 = 10;
  });
  Expect.throwsNoSuchMethodError(() {
    r3.foo = const [1];
  });
  Expect.throwsNoSuchMethodError(() {
    r3.bar.$1 = 50;
  });
  Expect.throwsNoSuchMethodError(() {
    r3.bar.$2 = 50;
  });
  Expect.throwsNoSuchMethodError(() {
    r3.bar.baz = 60;
  });

  Expect.equals('Hi from foo1', r4.$1());
  Expect.equals('Hi from foo2', r4.foo2(42));
  Expect.throwsNoSuchMethodError(() {
    r4.foo2(42, 42);
  });
  Expect.throwsTypeError(() {
    r4.foo2('not int');
  });

  Expect.equals(10, r5.$1);
  Expect.equals(20, r5.$2);
  Expect.equals('meow', r5.$1000000000000000000);
  Expect.throwsNoSuchMethodError(() => r5.$3);
  Expect.throwsNoSuchMethodError(() => r5.$999999999999999999);
}
