// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test case for bytecode_with_ast_in_aot_test.dart.
// Contains 1 entry point.

import 'package:expect/expect.dart';

class A {
  // Make sure obfuscation prohibitions metadata is generated.
  @pragma('vm:entry-point')
  void foofoo1() {}
}

main() {
  new A();
  print('OK');
}
