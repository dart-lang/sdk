// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that it is a compile time error for a `late` variable initializer
// to use the `await` expression.
import 'package:expect/expect.dart';
import 'dart:core';

main() async {
  late final a = 0; //# 01: ok
  late var b = await 0; //# 02: compile-time error
  late Function c = () async => await 42; //# 03: ok
  late var d = () async { await 42; }; //# 04: ok
  var e = () async { late final e2 = await 42; }; //# 05: compile-time error
}
