// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*class: A:*/
class A<T> {
  @NoInline()
  m() {
    return /*needsSignature*/ (int i, String s) {};
  }
}

@NoInline()
test(o) => o is void Function(int);

main() {
  test(new A<int>().m());
}
