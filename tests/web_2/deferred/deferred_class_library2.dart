// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Imported by deferred_class_test.dart.

library deferred_class_library2;

class MyClass {
  const MyClass();

  foo(x) {
    print('MyClass.foo($x)');
    return (x - 3) ~/ 2;
  }
}

class Constant {
  final value;
  const Constant(this.value);

  operator ==(other) => other is Constant && value == other.value;
  get hashCode => 0;
}

const C1 = const Constant(499);
const C2 = const [const Constant(99)];

foo([x = const Constant(42)]) => x;
bar() => const Constant(777);

class Gee {
  get value => c.value;
  final c;

  Gee([this.c = const Constant(111)]);
  const Gee.n321([this.c = const Constant(321)]);
  Gee.n135({arg: const Constant(135)}) : this.c = arg;
  const Gee.n246({arg: const Constant(246)}) : this.c = arg;
  const Gee.n888() : this.c = const Constant(888);
  const Gee.constant(this.c);
}

class Gee2 extends Gee {
  Gee2() : super(const Constant(979));
  const Gee2.n321() : super.n321();
  const Gee2.n151() : super.constant(const Constant(151));
  const Gee2.n888() : super.n888();
}
