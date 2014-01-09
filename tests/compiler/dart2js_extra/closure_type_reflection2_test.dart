// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that classes referenced from a signature of a tear-off closure
// are emitted.

@MirrorsUsed(targets: 'C')
import 'dart:mirrors';

import 'package:expect/expect.dart';

class A {}

class C {
  A foo() {}
}

main() {
  Expect.isFalse(reflect(new C().foo).function.returnType.toString()
      .contains('dynamic'));
}
