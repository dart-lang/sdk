// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=foo
// functionFilter=doit
// tableFilter=static[0-9]+
// globalFilter=fooGlobal
// globalFilter=Foo
// typeFilter=NoMatch
// compilerOption=--enable-deferred-loading
// compilerOption=--no-minify

// We import ourselves here \\o//
import 'deferred.fine_grained.devirtualized.dart' deferred as D;

FooBase? baseObj;
Foo1? foo1Obj;

void main() async {
  await D.loadLibrary();
  print(runtimeTrue); // to prevent inlining into foo0
  D.foo1(); // to prevent deferred loading check inlining into f1

  foo0();
}

final runtimeTrue = int.parse('1') == 1;

@pragma('wasm:never-inline')
void foo0() {
  baseObj = runtimeTrue ? Foo0() : Foo1();
  foo1Obj = runtimeTrue ? Foo1() : Foo1();
  D.foo1();
}

@pragma('wasm:never-inline')
void foo1() {
  baseObj!.doitDispatch(1);
  foo1Obj!.doitDispatch(2);

  foo1Obj!.doitDevirt(1);
  foo1Obj!.doitDevirt(1);
}

class FooBase {
  FooBase();

  void doitDispatch(dynamic a) {
    print('FooBase($a)');
  }

  void doitDevirt(dynamic a) {
    print('FooBase($a)');
  }
}

class Foo0 extends FooBase {
  Foo0();

  @override
  void doitDispatch(dynamic a) {
    print('Foo0.doitDispatch($a)');
    super.doitDispatch(a);
  }

  @override
  void doitDevirt(dynamic a) {
    print('Fooi0.doitDevirt($a)');
    super.doitDevirt(a);
  }
}

class Foo1 extends FooBase {
  Foo1();

  @override
  void doitDispatch(dynamic a) {
    print('Foo1.doitDispatch($a)');
    super.doitDispatch(a);
  }

  @override
  void doitDevirt(dynamic a) {
    print('Foo1.doitDevirt($a)');
    super.doitDevirt(a);
  }
}
