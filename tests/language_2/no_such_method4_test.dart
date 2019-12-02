// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class NoSuchMethodNegativeTest {
  foo() {
    return 1;
  }
}

main() {
  var obj = new NoSuchMethodNegativeTest() as dynamic;
  Expect.throwsNoSuchMethodError(() {
    obj.moo();
  });
}
