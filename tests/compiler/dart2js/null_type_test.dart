// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("compiler_helper.dart");

const String TEST_ONE = r"""
foo() {
  var c = null;
  while (true) c = 1 + c;
}
""";

main() {
  String generated = compile(TEST_ONE, entry: 'foo');
  Expect.isFalse(generated.contains('typeof (void 0)'));
}
