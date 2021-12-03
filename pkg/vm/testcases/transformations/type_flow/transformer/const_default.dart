// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'const_default.lib.dart';

test(Class c) {
  c.method2();
}

main() {
  dynamic dyn = null;
  //test(dyn);
}
