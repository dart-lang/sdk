// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Class {
  static set o(_) {}
  m() => o; //# 01: compile-time error

  noSuchMethod(_) => 42;
}

main() {
  Expect.throws(() => new Class().m()); //# 01: continued
}
