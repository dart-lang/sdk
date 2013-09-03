// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';
import 'parser_helper.dart';

const String TEST_NULL0 = r"""
class A { static var x; }

main() { return A.x; }
""";

const String TEST_NULL1 = r"""
var x;

main() { return x; }
""";

main() {
  asyncTest(() => compileAll(TEST_NULL0).then((generated) {
    Expect.isTrue(generated.contains("null"));
  }));

  asyncTest(() => compileAll(TEST_NULL1).then((generated) {
    Expect.isTrue(generated.contains("null"));
  }));
}
