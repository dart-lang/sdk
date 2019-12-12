// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that it is not a compile time error for a `final` variable to not have
// an initializer if that variable is declared as `late`.
import 'package:expect/expect.dart';
import 'dart:core';

main() {
  late final a;
  late final b = 0;
}

class C {
  late final a;
  late final b = 0;
}
