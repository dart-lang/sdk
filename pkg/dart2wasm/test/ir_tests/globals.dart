// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=DartGlobals
// tableFilter=cross-module-funcs|global-table
// globalFilter=NoMatch
// typeFilter=NoMatch
// compilerOption=--no-minify
// compilerOption=-O0

void main() {
  // Ensure we read and write the globals.
  print(DartGlobals.foo0_constInit);
  print(DartGlobals.foo1_newInit);
  print(DartGlobals.foo2_newInit_final);
  print(DartGlobals.foo3_newInit);
  print(DartGlobals.foo4_newInit);
  print(DartGlobals.foo5_newInit);
  print(DartGlobals.foo6_newInit);
  print(DartGlobals.foo7_newInit);
  print(DartGlobals.foo8_newInit);
  print(DartGlobals.foo9_newInit);

  print(DartGlobals.bar0_constInit);
  print(DartGlobals.bar1_newInit);
  print(DartGlobals.bar2_newInit_final);
  print(DartGlobals.bar3_noInit);
  print(DartGlobals.bar4_noInit);
  print(DartGlobals.bar5_noInit);
  print(DartGlobals.bar6_noInit);
  print(DartGlobals.bar7_noInit);
  print(DartGlobals.bar8_noInit);
  print(DartGlobals.bar9_noInit);

  print(DartGlobals.baz0_constInit);
  print(DartGlobals.baz1_newInit);
  print(DartGlobals.baz2_newInit_final);
  print(DartGlobals.baz3_noInit);

  DartGlobals.foo0_constInit = Foo('');
  DartGlobals.foo1_newInit = Foo('');
  DartGlobals.foo3_newInit = Foo('');
  DartGlobals.foo4_newInit = Foo('');
  DartGlobals.foo5_newInit = Foo('');
  DartGlobals.foo6_newInit = Foo('');
  DartGlobals.foo7_newInit = Foo('');
  DartGlobals.foo8_newInit = Foo('');
  DartGlobals.foo9_newInit = Foo('');

  DartGlobals.bar0_constInit = null;
  DartGlobals.bar1_newInit = null;
  DartGlobals.bar3_noInit = Bar('');
  DartGlobals.bar4_noInit = Bar('');
  DartGlobals.bar5_noInit = Bar('');
  DartGlobals.bar6_noInit = Bar('');
  DartGlobals.bar7_noInit = Bar('');
  DartGlobals.bar8_noInit = Bar('');
  DartGlobals.bar9_noInit = Bar('');

  DartGlobals.baz0_constInit = null;
  DartGlobals.baz1_newInit = null;
  DartGlobals.baz3_noInit = Baz('');
}

class DartGlobals {
  // Field type has more than 10 such fields, so it qualifies for table based
  // slot. Though depending on which case we may still prefer global.
  static Foo foo0_constInit = const Foo('foo0');
  static Foo foo1_newInit = Foo('foo1');
  static final Foo foo2_newInit_final = Foo('foo2');
  static Foo foo3_newInit = Foo('foo3');
  static Foo foo4_newInit = Foo('foo4');
  static Foo foo5_newInit = Foo('foo5');
  static Foo foo6_newInit = Foo('foo6');
  static Foo foo7_newInit = Foo('foo7');
  static Foo foo8_newInit = Foo('foo8');
  static Foo foo9_newInit = Foo('foo9');

  // Field type has more than 10 such fields, so it qualifies for table based
  // slot. Though depending on which case we may still prefer global.
  static Bar? bar0_constInit = const Bar('bar0');
  static Bar? bar1_newInit = Bar('bar1');
  static final Bar? bar2_newInit_final = Bar('bar2');
  static Bar? bar3_noInit;
  static Bar? bar4_noInit;
  static Bar? bar5_noInit;
  static Bar? bar6_noInit;
  static Bar? bar7_noInit;
  static Bar? bar8_noInit;
  static Bar? bar9_noInit;

  // Field type has less than 10 such fields, so it doesn't qualify for a table
  // based slot, we use global fields.
  static Baz? baz0_constInit = const Baz('baz0');
  static Baz? baz1_newInit = Baz('baz1');
  static final Baz? baz2_newInit_final = Baz('baz2');
  static Baz? baz3_noInit;
}

class Foo {
  final String value;
  const Foo(this.value);

  String toString() => 'Foo($value)';
}

class Bar {
  final String value;
  const Bar(this.value);

  String toString() => 'Bar($value)';
}

class Baz {
  final String value;
  const Baz(this.value);

  String toString() => 'Baz($value)';
}
