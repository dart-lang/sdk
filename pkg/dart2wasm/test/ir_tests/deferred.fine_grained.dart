// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=foo.*Code
// functionFilter=Foo.*doit
// tableFilter=static[0-9]+
// globalFilter=fooGlobal
// globalFilter=FooConst
// typeFilter=NoMatch
// compilerOption=--enable-deferred-loading
// compilerOption=--no-minify

// We import ourselves here \\o//
import 'deferred.fine_grained.dart' deferred as D1;
import 'deferred.fine_grained.dart' deferred as D2;
import 'deferred.fine_grained.dart' deferred as D3;
import 'deferred.fine_grained.dart' deferred as D4;
import 'deferred.fine_grained.dart' deferred as D5;

void main() async {
  await foo0();
}

Future foo0() async {
  foo0Code(0);
  await D1.loadLibrary();
  await D1.foo1();
}

Future foo1() async {
  foo1Code(0);
  await D2.loadLibrary();
  await D2.foo2();
}

Future foo2() async {
  foo2Code(0);
  await D3.loadLibrary();
  await D3.foo3();
}

Future foo3() async {
  foo3Code(0);
  await D4.loadLibrary();
  await D4.foo4();
}

Future foo4() async {
  foo4Code(0);
  await D5.loadLibrary();
  await D5.foo5();
}

Future foo5() async {
  foo5Code(fooGlobal5);
}

@pragma('wasm:never-inline')
void foo0Code(dynamic a) {
  print(const FooConst0());
  print('foo0Code($a)');
  fooGlobal0 = 0;
}

@pragma('wasm:never-inline')
void foo1Code(dynamic a) {
  print(const FooConst1());
  print('foo1Code($a)');
  fooGlobal1 = 1;
}

@pragma('wasm:never-inline')
void foo2Code(dynamic a) {
  print(const FooConst2());
  print('foo2Code($a)');
  fooGlobal2 = 2;
}

@pragma('wasm:never-inline')
void foo3Code(dynamic a) {
  print(const FooConst3());
  print('foo3Code($a)');
  fooGlobal3 = 3;
}

@pragma('wasm:never-inline')
void foo4Code(dynamic a) {
  print(const FooConst4());
  print('foo4Code($a)');
  fooGlobal4 = 4;
}

@pragma('wasm:never-inline')
void foo5Code(dynamic a) {
  print(const FooConst5());
  print('foo5Code($a)');
  fooGlobal5 = 5;

  // Also refer things from other modules, which will make us put them into
  // separate modules.
  foo0Code(fooGlobal0);
  foo1Code(fooGlobal1);
  foo2Code(fooGlobal2);
  foo3Code(fooGlobal3);
  foo4Code(fooGlobal4);
  // We invoke `doit()` here which will cause all modules with const/new
  // instances of the `FooConst*` classes to include `doit()` in it's module
  // even though they don't call `doit()` (only last module does).
  allFooConstants[0].doit(fooGlobal5);
}

final allFooConstants = <FooConstBase>[
  const FooConst0(),
  const FooConst1(),
  const FooConst2(),
  const FooConst3(),
  const FooConst4(),
  const FooConst5(),
];

class FooConstBase {
  const FooConstBase();

  void doit(dynamic a) {
    print('FooConstBase($a)');
  }
}

class FooConst0 extends FooConstBase {
  const FooConst0();

  @override
  void doit(dynamic a) {
    print('FooConst0($a)');
    super.doit(a);
  }
}

class FooConst1 extends FooConstBase {
  const FooConst1();

  @override
  void doit(dynamic a) {
    print('FooConst1($a)');
    super.doit(a);
  }
}

class FooConst2 extends FooConstBase {
  const FooConst2();

  @override
  void doit(dynamic a) {
    print('FooConst2($a)');
    super.doit(a);
  }
}

class FooConst3 extends FooConstBase {
  const FooConst3();

  @override
  void doit(dynamic a) {
    print('FooConst3($a)');
    super.doit(a);
  }
}

class FooConst4 extends FooConstBase {
  const FooConst4();

  @override
  void doit(dynamic a) {
    print('FooConst4($a)');
    super.doit(a);
  }
}

class FooConst5 extends FooConstBase {
  const FooConst5();

  @override
  void doit(dynamic a) {
    print('FooConst5($a)');
    super.doit(a);
  }
}

Object fooGlobal0 = int.parse('0') == 1 ? 1 : '1';
Object fooGlobal1 = int.parse('1') == 1 ? 1 : '1';
Object fooGlobal2 = int.parse('2') == 1 ? 1 : '1';
Object fooGlobal3 = int.parse('3') == 1 ? 1 : '1';
Object fooGlobal4 = int.parse('4') == 1 ? 1 : '1';
Object fooGlobal5 = int.parse('5') == 1 ? 1 : '1';
