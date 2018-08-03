// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks

library Issue1363Test.dart;

import 'issue1363_lib.dart' as lib;

main() {
  new C().test();
}

class C {
  lib.Cup<lib.C> libCup;
  lib.Cup<C> myCup;

  C();

  test() {
    myCup = new lib.Cup<C>(new C());
    libCup = new lib.Cup<lib.C>(new lib.C());

    C contents = myCup.getContents(); // expect no warning or error
    contents = libCup.getContents(); //# 01: compile-time error
  }
}
