// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_native_test_module

import 'package:js/js.dart';
import 'dart:ffi';

@Native<Void Function()>()
external void empty();

@JS()
class Foo {}

extension FooExtension on Foo {
  external get neverCalled;
}

// This test should compile.
void main() {
  print('Hello world');
}
