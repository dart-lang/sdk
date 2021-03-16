// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

@pragma('dart2js:noInline')
test1(o) => o is Function(int);

@pragma('dart2js:noInline')
test2(o) => o is Function<T>(T);

class C<S> {
  @pragma('dart2js:noInline')
  test(bool expected) {
    local1(int i) {}
    local2<T>(T t) {}
    local3(S s) {}

    Expect.isTrue(test1(local1));
    Expect.isFalse(test2(local1));

    Expect.isFalse(test1(local2));
    Expect.isTrue(test2(local2));

    Expect.equals(expected, test1(local3));
    Expect.isFalse(test2(local3));
  }
}

main() {
  new C<int>().test(true);
  new C<double>().test(false);
}
