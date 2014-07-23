// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper";
import "package:expect/expect.dart";

makeCC() native;
nativeFirst(x, y) native;

void setup() native """
function CC() {}
makeCC = function() { return new CC; }
nativeFirst = function(x, y) { return x; }
""";

class C {
  foo(x) => x;
}

@Native("CC")
class ClickCounter {
  var status;

  var foo;

  init() {
    foo = wrap(g);
  }

  g(val) => "### $val ###";
}

wrap(cb) {
  return (val) {
    return cb("!!! $val !!!");
  };
}

main() {
  setup();
  var c = makeCC();
  c.init();
  var c2 = new C();
  c = nativeFirst(c, c2);
  // After the `nativeFirst` invocation dart2js doesn't know if c is a
  // ClickCounter or C. It must go through the interceptor and call the foo$1
  // invocation.
  Expect.equals("### !!! 499 !!! ###", c.foo(499));
}
