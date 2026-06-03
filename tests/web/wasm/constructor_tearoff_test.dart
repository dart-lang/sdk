// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  final arg = int.parse('1');

  // Call constructors
  final foos = [
    Foo(arg),
    Foo.redirect(arg),
    Foo.factory(arg),
    Foo.redirectingFactory(arg),
  ];
  Expect.equals('Foo<$int>(1, named: Foo named)', foos[0].toString());
  Expect.equals('Foo<$int>(1, named: Foo.redirect named)', foos[1].toString());
  Expect.equals('Foo<$int>(1, named: Foo.factory named)', foos[2].toString());
  Expect.equals('Foo<$int>(1, named: Foo named)', foos[3].toString());

  // Call constructor tear-offs via typed closure call.
  final tearoffs = <Foo<T> Function<T>(T, {String named})>[
    Foo.new,
    Foo.redirect,
    Foo.factory,
    Foo.redirectingFactory,
  ];
  Expect.equals(
    'Foo<$double>(1.1, named: Foo named)',
    tearoffs[0]<double>(1.1).toString(),
  );
  Expect.equals(
    'Foo<$double>(1.2, named: 2)',
    tearoffs[1]<double>(1.2, named: '2').toString(),
  );
  Expect.equals(
    'Foo<$double>(1.3, named: Foo.factory named)',
    tearoffs[2]<double>(1.3).toString(),
  );
  Expect.equals(
    'Foo<$double>(1.4, named: 4)',
    tearoffs[3]<double>(1.4, named: '4').toString(),
  );

  // Call constructor tear-offs via typed dynamic call.
  final dtearoffs = <dynamic>[
    Foo.new,
    Foo.redirect,
    Foo.factory,
    Foo.redirectingFactory,
  ];
  Expect.equals(
    'Foo<$double>(1.1, named: 1)',
    dtearoffs[0]<double>(1.1, named: '1').toString(),
  );
  Expect.equals(
    'Foo<$double>(1.2, named: Foo.redirect named)',
    dtearoffs[1]<double>(1.2).toString(),
  );
  Expect.equals(
    'Foo<$double>(1.3, named: 3)',
    dtearoffs[2]<double>(1.3, named: '3').toString(),
  );
  Expect.equals(
    'Foo<$double>(1.4, named: Foo named)',
    dtearoffs[3]<double>(1.4).toString(),
  );
}

class Foo<T> {
  final T pos;
  final String named;

  Foo(this.pos, {this.named = 'Foo named'});
  Foo.redirect(T pos, {String named = 'Foo.redirect named'})
    : this(pos, named: named);
  factory Foo.factory(T pos, {String named = 'Foo.factory named'}) =>
      Foo(pos, named: named);
  factory Foo.redirectingFactory(T pos, {String named}) = Foo;

  String toString() => 'Foo<$T>($pos, named: $named)';
}
