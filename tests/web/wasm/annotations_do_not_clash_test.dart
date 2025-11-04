// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_native_test_module
// dart2wasmOptions=--extra-compiler-option=--enable-experimental-ffi

import 'dart:ffi';
import 'dart:js_interop';

@Native<Void Function()>()
external void empty();

@JS()
@staticInterop
class Foo {}

extension FooExtension on Foo {
  external JSObject get neverCalled;
}

// This test should compile.
void main() {
  print('Hello world');
}
