// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--omit-implicit-checks

import 'package:expect/expect.dart';

main() {
  final l = [X<int>().foo, X<double>().foo];
  final c = l[int.parse('0')];
  Expect.isTrue(c is int Function(int));
  Expect.isTrue(c is int Function(Object));
}

class X<T> {
  T foo(T value) {
    print(value);
    return value;
  }
}
