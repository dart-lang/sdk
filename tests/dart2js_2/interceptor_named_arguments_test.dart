// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that the proper one-shot interceptor is used for different
// combinations of named arguments.
import "package:expect/expect.dart";

// Use dart:html to get interceptors into play.
import "dart:html";

// [createFragment] has the same signature as in [Element].
class Other {
  createFragment(html, {validator, treeSanitizer}) {
    int result = 0;
    result += validator == null ? 0 : 2;
    result += treeSanitizer == null ? 0 : 1;
    return result;
  }
}

@pragma('dart2js:noInline')
bool wontTell(bool x) => x;

// Ensure that we use the interceptor only once per context so that we
// actually get a one-shot interceptor. This is a little brittle...
@pragma('dart2js:noInline')
testA(thing) {
  Expect.equals(0, thing.createFragment(null));
}

@pragma('dart2js:noInline')
testB(thing) {
  Expect.equals(2, thing.createFragment(null, validator: 1));
}

@pragma('dart2js:noInline')
testC(thing) {
  Expect.equals(1, thing.createFragment(null, treeSanitizer: 1));
}

@pragma('dart2js:noInline')
testD(thing) {
  Expect.equals(3, thing.createFragment(null, validator: 1, treeSanitizer: 1));
}

main() {
  // Ensure we get interceptors into play.
  var thing = wontTell(true) ? new Other() : new DivElement();
  testA(thing);
  testB(thing);
  testC(thing);
  testD(thing);
}
