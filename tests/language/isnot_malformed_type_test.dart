// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

f(obj) {
  // 'Baz' is not loaded, mapped to dynamic.
  return (obj is !Baz);
}

main () {
  Expect.isFalse(f(null));
}
