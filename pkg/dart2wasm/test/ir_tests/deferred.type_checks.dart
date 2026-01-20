// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=mainMain|takeT
// tableFilter=NoMatch
// globalFilter=NoMatch
// typeFilter=NoMatch
// compilerOption=--enable-deferred-loading
// compilerOption=--minify

// We import ourselves here \\o//
import 'deferred.type_checks.dart' deferred as D;

var mainGlobal = int.parse('1');
var deferredGlobal = int.parse('2');

final fooInt = Foo<int>();
final foos = <Foo<Object>>[Foo<int>(), Foo<String>()];
final alwaysTrue = int.parse('0') == 0;

void main() async {
  await D.loadLibrary();
  D.runMain();
}

@pragma('wasm:never-inline')
void runMain() {
  fooInt.takeT(10);
  foos[alwaysTrue ? 0 : -1].takeT(42);
  foos[alwaysTrue ? 1 : -1].takeT('string');
}

class Foo<T> {
  @pragma('wasm:never-inline')
  void takeT(T value) {
    print('Foo<$T>.takeT($value)');
    print(this as Foo<int>);
  }
}
