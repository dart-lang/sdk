// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test dart2wasm's `int` passing to `js_interop` functions.
//
// To avoid allocations when passing an `int` to JS in V8, dart2wasm passes
// `int`s as externalized `i31ref`s. Test the `i31ref` edge cases:
//
// - Min i31 (should be passed as externalized `i31ref`)
// - Max i31 (should be passed as externalized `i31ref`)
// - Min i31 - 1 (should be passed as externalized `f64`)
// - Max i31 + 1 (should be passed as externalized `f64`)

// The option below allows importing `dart:_wasm`.
// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

import 'dart:_wasm';
import 'dart:js_interop';

import 'package:expect/expect.dart';

@JS('test')
external int intTest(int i);

@JS('test')
external num numTest(num i);

void main() {
  const int maxI31 = (1 << 30) - 1;
  const int minI31 = -(1 << 30);

  int i31refs = 0;
  int others = 0;

  setReturnIdentity = ((JSAny js) {
    final isI31Ref = externRefForJSAny(js).internalize()!.isI31;

    if (isI31Ref) {
      i31refs += 1;
    } else {
      others += 1;
    }

    final dartValue = (js.dartify() as double).toInt();
    Expect.equals(isI31Ref, dartValue >= minI31 && dartValue <= maxI31);
    return js;
  }).toJS;

  for (int i in <int>[maxI31, maxI31 + 1, minI31, minI31 - 1]) {
    returnIdentity(i);
  }

  Expect.equals(2, i31refs);
  Expect.equals(2, others);
}

@JS('globalThis.returnIdentity')
external void set setReturnIdentity(JSFunction fun);

@JS('globalThis.returnIdentity')
external JSAny returnIdentity(int i);
