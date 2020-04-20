// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

class H {
  call() {}
}

main() {
  print(new H());
  method();
}

method() {
  local1() {}

  local1(); // This call wrongfully triggers enqueueing of H.call in codegen.
}
