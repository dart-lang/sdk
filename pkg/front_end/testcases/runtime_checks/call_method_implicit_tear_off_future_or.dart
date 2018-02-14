// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

import 'dart:async';

class C {
  void call() {}
}

main() {
  FutureOr<void Function()> x = new C();
}
