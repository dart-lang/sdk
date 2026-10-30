// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--cfg

import 'package:expect/expect.dart';

class Counter {
  @pragma('wasm:cfg')
  int count;

  @pragma('wasm:cfg')
  String label;

  @pragma('wasm:cfg')
  Object? tag;

  Counter(this.count, this.label, [this.tag]);
}

class CustomCounter extends Counter {
  CustomCounter(int count, String label) : super(count, label);

  @override
  int get count => super.count + 100;

  @override
  set count(int value) {
    super.count = value * 2;
  }

  @override
  String get label => '[${super.label}]';
}

abstract class NumberHolder {
  num get readOnlyCovariant;
  num get mutableCovariant;
  set mutableCovariant(num value);
}

class IntHolder implements NumberHolder {
  // Even though this field is marked `covariant`, its implicit getter does not
  // perform type checks and can be compiled with CFG.
  @pragma('wasm:cfg')
  @override
  covariant int readOnlyCovariant;

  // Its implicit getter is compiled with CFG, while its covariant setter
  // falls back to the AST compiler to perform the runtime parameter check.
  @override
  covariant int mutableCovariant;

  IntHolder(this.readOnlyCovariant, this.mutableCovariant);
}

class NumHolder implements NumberHolder {
  @override
  num readOnlyCovariant;

  @override
  num mutableCovariant;

  NumHolder(this.readOnlyCovariant, this.mutableCovariant);
}

void main() {
  // Direct field setter and getter on Counter.
  final c = Counter(int.parse('5'), 'init');
  Expect.equals(5, c.count);
  Expect.equals('init', c.label);
  Expect.isNull(c.tag);

  c.count = int.parse('42');
  c.label = 'updated';
  c.tag = int.parse('99');
  Expect.equals(42, c.count);
  Expect.equals('updated', c.label);
  Expect.equals(99, c.tag);

  // Polymorphic dispatch on `count` and `label` forces `Counter`'s implicit
  // field getter and setter functions to be generated and compiled via CFG
  // (`LoadInstanceField` and `StoreInstanceField`).
  final items = <Counter>[c, CustomCounter(int.parse('10'), 'sub')];
  Expect.equals(42, items[0].count);
  Expect.equals(110, items[1].count);
  Expect.equals('updated', items[0].label);
  Expect.equals('[sub]', items[1].label);

  items[0].count = int.parse('7');
  items[1].count = int.parse('7');
  Expect.equals(7, items[0].count);
  Expect.equals(114, items[1].count);

  // Covariant field getter compiled with CFG (`@pragma('wasm:cfg')`), and
  // covariant field setter safely enforcing runtime type checks.
  final holders = <NumberHolder>[
    IntHolder(int.parse('11'), int.parse('22')),
    NumHolder(1.5, 2.5),
  ];
  Expect.equals(11, holders[0].readOnlyCovariant);
  Expect.equals(1.5, holders[1].readOnlyCovariant);
  Expect.equals(22, holders[0].mutableCovariant);
  Expect.equals(2.5, holders[1].mutableCovariant);

  holders[0].mutableCovariant = int.parse('33');
  Expect.equals(33, holders[0].mutableCovariant);
  Expect.throwsTypeError(() {
    holders[0].mutableCovariant = 3.14;
  });
  Expect.equals(33, holders[0].mutableCovariant);
}
