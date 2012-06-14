// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("compiler_helper.dart");

final String FIB = @"""
fib(n) {
  if (n <= 1) return 1;
  return fib(n - 1) + fib(n - 2);
}
""";

main() {
  // Make sure we don't introduce a new variable.
  RegExp regexp = new RegExp("var $anyIdentifier =");
  compileAndDoNotMatch(FIB, 'fib', regexp);
}
