// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.top_level_accessors_test;

@MirrorsUsed(targets: "test.top_level_accessors_test")
import 'dart:mirrors';

import 'package:expect/expect.dart';

var field;

get accessor => field;

set accessor(value) {
  field = value;
  return 'fisk'; //# 01: compile-time error
}

main() {
  LibraryMirror library =
      currentMirrorSystem().findLibrary(#test.top_level_accessors_test);
  field = 42;
  Expect.equals(42, library.getField(#accessor).reflectee);
  Expect.equals(87, library.setField(#accessor, 87).reflectee);
  Expect.equals(87, field);
  Expect.equals(87, library.getField(#accessor).reflectee);
}
