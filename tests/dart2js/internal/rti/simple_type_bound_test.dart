// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--experiment-new-rti

import "package:expect/expect.dart";

@pragma('dart2js:noInline')
dynamic makeFunction(x) {
  // Return a local function since that does not require any tear-off code.
  dynamic foo<U extends V, V extends num>() {
    // Returning x ensures this is a local function and will not be optimized to
    // a static tear-off.
    return x;
  }

  return foo;
}

@pragma('dart2js:noInline')
void test(dynamic action, bool expectThrows) {
  // Don't use Expect.throws because it is hard to call without implicit type
  // checks.
  try {
    // There is no type check here, just a dynamic 'call' selector.
    action();
  } catch (e, st) {
    if (expectThrows) return;
    Expect.fail('Should throw');
    return;
  }
  if (expectThrows) {
    Expect.fail('Did not throw');
  }
}

main() {
  dynamic f = makeFunction(123);

  test(() => f<String, int>(), true);
  test(() => f<num, num>(), false);
}
