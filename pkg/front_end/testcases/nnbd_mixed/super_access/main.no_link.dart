// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'main_lib1.dart';
import 'main_lib2.dart';

class Class<T> with Mixin1<T>, Mixin2<T> {
  set field(Typedef value) {
    super.field;
    super.field = value;
    super.method1();
    super.method2(null);
  }
}

main() {}
