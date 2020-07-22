// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A<T> {}

class A1 implements A<C1> {}

class B<T> {
  @pragma('dart2js:noInline')
  method(var t) => t is T;
}

class C {}

class C1 implements C {}

class C2 implements C {}

main() {
  Expect.isTrue(B<List<A<C>>>().method(List<A1>.empty()));
  Expect.isFalse(B<List<A<C2>>>().method(List<A1>.empty()));
}
