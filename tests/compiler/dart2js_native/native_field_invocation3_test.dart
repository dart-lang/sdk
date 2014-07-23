// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper";
import "package:expect/expect.dart";

makeCC() native;

void setup() native """
function CC() {}
makeCC = function() { return new CC; }
""";


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
  // `foo` contains a closure. Make sure that invoking foo through an
  // interceptor works.
  Expect.equals("### !!! 499 !!! ###", c.foo(499));
}
