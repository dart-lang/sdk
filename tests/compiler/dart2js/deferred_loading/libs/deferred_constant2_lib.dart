// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library deferred_constants2_lib;

class MyClass {
  const MyClass();

  foo(x) {
    print('MyClass.foo($x)');
    return (x - 3) ~/ 2;
  }
}

class Constant {
  /*element: Constant.value:OutputUnit(1, {lib})*/
  final value;
  /*element: Constant.:OutputUnit(1, {lib})*/
  const Constant(this.value);

  /*element: Constant.==:OutputUnit(1, {lib})*/
  operator ==(other) => other is Constant && value == other.value;
  /*element: Constant.hashCode:OutputUnit(1, {lib})*/
  get hashCode => 0;
}

/*element: C1:OutputUnit(1, {lib})*/
const C1 = /*OutputUnit(1, {lib})*/ const Constant(499);

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
