// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-deferred-loading

import 'package:expect/expect.dart';

import '' deferred as D1;
import '' deferred as D2;

main() async {
  // Create a call to `Object.toString()` which will populate any
  // always-same-constant optional parameters as well.
  print(1);

  String result = '';
  if (opaqueTrue) {
    await D1.loadLibrary();
    result = D1.foo();
  }
  Expect.equals('Foo(Bar)', result);
}

String foo() => Foo().toString();

class Foo {
  @override
  String toString({Bar bar = const Bar()}) {
    return 'Foo($bar)';
  }
}

class Bar {
  const Bar();

  @override
  String toString() => 'Bar';
}

bool get opaqueTrue => int.parse('1') == 1;
