// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library d;

import 'b.dart';

void foo() {
  var x = f3(f4("""hello"""));
  var y = f1(f4);
  var z = f2(f3);
}
