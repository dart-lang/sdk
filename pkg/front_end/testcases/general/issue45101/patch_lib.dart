// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart=2.9
// ignore: import_internal_library
import 'dart:_internal';

@patch
@pragma("vm:entry-point")
class Array<T> {
  // ...

  @patch
  const factory Array(int foo) = _ArraySize<T>;
}

class _ArraySize<T> implements Array<T> {
  final int foo;

  const _ArraySize(this.foo);
}
