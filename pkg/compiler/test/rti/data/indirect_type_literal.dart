// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:compiler/src/util/testing.dart';

class A<T> {}

class B<T extends num> {}

/*class: Indirect:exp,needsArgs*/
class Indirect<T> {
  Type get type => T;
}

void main() {
  makeLive(A == new Indirect<A>().type);
  makeLive(A == new Indirect<A<dynamic>>().type);
  makeLive(A == new Indirect<A<num>>().type);
  makeLive(B == new Indirect<B>().type);
  makeLive(B == new Indirect<B<num>>().type);
  makeLive(B == new Indirect<B<int>>().type);
}
