// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Simple test to ensure that mini_parser keeps working.

import '../../../sdk/lib/_internal/compiler/implementation/tools/mini_parser.dart'
    as tool;

void main() {
  // Parse this script itself.
  tool.toolMain(<String>[ new Options().script ]);
}

/** This class is unused but used to test mini_parser.dart. */
class TestClass {
  foo() {}
  var i;
}
