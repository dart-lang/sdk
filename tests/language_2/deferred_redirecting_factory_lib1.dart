// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib1;

import "deferred_redirecting_factory_lib2.dart" deferred as lib2;
import "deferred_redirecting_factory_test.dart" as main;

loadLib2() {
  return lib2.loadLibrary();
}

class C extends main.C {
  String get foo => "lib1";
  C();
  factory C.a() = lib2.C;
}
