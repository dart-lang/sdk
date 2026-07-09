// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class C {
  int get one => 1;
}

extension E on C {
  int get two => 2;
}

main() {
  C c = C();
  var result = c.one + c.two;
  Expect.equals(result, 3);
}
