// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: import_internal_library
import 'dart:_internal';

@patch
@pragma('patch-class')
class Class<@pragma('patch-class-type-variable') T> {
  @patch
  @pragma('patch-constructor')
  external Class();

  @patch
  @pragma('patch-procedure')
  external void method<@pragma('patch-method-type-variable') S>();
}

@patch
@pragma('patch-extension')
extension Extension<@pragma('patch-extension-type-variable') T> on int {
  @patch
  @pragma('patch-extension-method')
  external void method<@pragma('patch-extension-method-type-variable') S>();
}
