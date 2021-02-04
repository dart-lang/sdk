// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

abstract class Foo<A, B> {
  bool pip(o);
}

class Bar<X, Y> implements Foo<X, Y> {
  bool pip(o) => o is Y;
}

class Baz<U, V> implements Foo<U, V> {
  bool pip(o) => true;
}

void main() {
  Expect.listEquals([], test(1));
  Expect.listEquals([true, false], test(Bar<String, int>()));
  Expect.listEquals([true, true], test(Baz<String, int>()));
}

@pragma('dart2js:noInline')
List<bool> test(dynamic p) {
  List<bool> result = [];
  if (p is Foo) {
    for (var o in [1, 'x']) {
      result.add(p.pip(o));
    }
  }
  return result;
}
