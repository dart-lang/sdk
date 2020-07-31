// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A<T> {
  @pragma('dart2js:noInline')
  m() {
    return (T t, String s) {};
  }
}

@pragma('dart2js:noInline')
test(o) => o is void Function(int);

main() {
  Expect.isFalse(test(new A<int>().m()));
}
