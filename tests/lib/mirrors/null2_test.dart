// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.null_test;

@MirrorsUsed(targets: const ["test.null_test", Null])
import 'dart:mirrors';

import 'package:expect/expect.dart';

main() {
  InstanceMirror nullMirror = reflect(null);
  for (int i = 0; i < 10; i++) {
    Expect.isTrue(nullMirror.getField(#hashCode).reflectee is int);
  }
}
