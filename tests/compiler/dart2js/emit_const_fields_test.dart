// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that unused static consts are not emitted.

import "package:expect/expect.dart";
import 'compiler_helper.dart';

const String TEST_GUIDE = r"""
class Guide {
  static const LTUAE = 42;
  static const TITLE = 'Life, the Universe and Everything';
}

main() {
  return "${Guide.LTUAE}, ${Guide.TITLE}";
}
""";

main() {
  String generated = compileAll(TEST_GUIDE);
  Expect.isTrue(generated.contains("42"));
  Expect.isFalse(generated.contains("TITLE"));
}

