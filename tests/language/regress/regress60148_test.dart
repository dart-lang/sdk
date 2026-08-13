// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/expect.dart';

main() async {
  final l = <A<int>>[B<int>(), C<int>()];
  Expect.equals('B.foo(1, first=1)', l[0].foo(1));
  Expect.equals('C.foo(2, second=true)', l[1].foo(2));
  Expect.equals('B.foo(3, first=2)', B<int>().foo(3, first: 2));
  Expect.equals('C.foo(4, second=false)', C<int>().foo(4, second: false));
}

abstract class A<T> {
  String foo(T a);
}

class B<T> extends A<T> {
  String foo(T a, {int first = 1}) => 'B.foo($a, first=$first)';
}

class C<T> extends A<T> {
  String foo(T a, {bool second = true}) => 'C.foo($a, second=$second)';
}
