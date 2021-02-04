// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


import 'package:expect/expect.dart';
import 'dart:_internal' show extractTypeArguments;

class C<T> {}

main() {
  test(new C<int>(), int);
  test(new C<String>(), String);
}

test(dynamic a, T) {
  Expect.equals(T, extractTypeArguments<C>(a, <T>() => T));
}
