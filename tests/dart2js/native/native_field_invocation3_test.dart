// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

makeCC() native;

void setup() {
  JS('', r"""
(function(){
  function CC() {}
  makeCC = function() { return new CC() };
  self.nativeConstructor(CC);
})()""");
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
  nativeTesting();
  setup();
  var c = makeCC();
  c.init();
  // `foo` contains a closure. Make sure that invoking foo through an
  // interceptor works.
  Expect.equals("### !!! 499 !!! ###", c.foo(499));
}
