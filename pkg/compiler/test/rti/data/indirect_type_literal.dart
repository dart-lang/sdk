// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/util/testing.dart';

class A<T> {}

class B<T extends num> {}

/*class: Indirect:exp,needsArgs*/
class Indirect<T> {
  Type get type => T;
}

void main() {
  makeLive(A == Indirect<A>().type);
  makeLive(A == Indirect<A<dynamic>>().type);
  makeLive(A == Indirect<A<num>>().type);
  makeLive(B == Indirect<B>().type);
  makeLive(B == Indirect<B<num>>().type);
  makeLive(B == Indirect<B<int>>().type);
}
