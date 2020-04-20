// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

class SuperA1 {}

class SuperA2 {}

class InterfaceA {}

mixin MixinA on SuperA1, SuperA2 implements InterfaceA {}

class SuperB1<T> {}

class SuperB2<T> {}

class SuperB3<T> {}

class InterfaceB<T> {}

mixin MixinB<T> on SuperB1<List<T>>, SuperB2<int>, SuperB3<T>
    implements InterfaceB<Map<int, T>> {}

class C extends SuperA1 with SuperA2 {}

main() {
  var listA = <MixinA>[];
  Expect.isTrue(listA is List<MixinA>);
  Expect.isTrue(listA is List<SuperA1>);
  Expect.isTrue(listA is List<SuperA2>);
  Expect.isTrue(listA is List<InterfaceA>);

  var listB = <MixinB<String>>[];
  Expect.isTrue(listB is List<MixinB<String>>);
  Expect.isTrue(listB is List<SuperB1<List<String>>>);
  Expect.isTrue(listB is List<SuperB2<int>>);
  Expect.isTrue(listB is List<SuperB3<String>>);
  Expect.isTrue(listB is List<InterfaceB<Map<int, String>>>);

} 