// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:expect/expect.dart';
import 'package:expect/variations.dart';

@JS('Array.prototype')
external JSObject get arrayProto;

@JS('Object.getPrototypeOf')
external JSObject? getPrototypeOf(JSObject o);

@JSExport()
class Foo {
  int _unused = 0;
}

void main() {
  Expect.isTrue(
    createJSInteropWrapper(Foo(), arrayProto).instanceOfString('Array'),
  );

  // Check that `undefined` is also an invalid proto.
  final undefined = globalContext['foo'] as JSObject?;
  if (jsNumbers) {
    // On JS backends, `undefined` is a value that can flow across the interop
    // boundary and causes `Object.create` to throw.
    Expect.throws(() => createJSInteropWrapper(Foo(), undefined));
  } else {
    // On dart2wasm, `undefined` gets turned into `null` when crossing the
    // interop boundary, so `createJSInteropWrapper` behaves identically to
    // passing a `null` proto (or nothing at all).
    final wrapper = createJSInteropWrapper(Foo(), undefined);
    Expect.equals(null, getPrototypeOf(wrapper));
  }
}
