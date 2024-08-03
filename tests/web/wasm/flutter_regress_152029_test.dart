// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--omit-implicit-checks

import 'package:expect/expect.dart';

class A<T> {
  T? value = null;
}

main() {
  final list = [A<String>(), 1];
  final dynamic a = list[int.parse('0')];
  if (int.parse('0') == 0) {
    a.value = '42';
  }
  Expect.equals('42', a.value);
}
