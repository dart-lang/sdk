// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

#import("compiler_helper.dart");
#import("parser_helper.dart");

const String TEST_NULL0 = @"""
class A { static var x; }

main() { return A.x; }
""";

const String TEST_NULL1 = @"""
var x;

main() { return x; }
""";

main() {
  String generated = compileAll(TEST_NULL0);
  Expect.isTrue(generated.contains("null"));
  generated = compileAll(TEST_NULL1);
  Expect.isTrue(generated.contains("null"));
}
