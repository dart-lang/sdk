// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper";
import "package:expect/expect.dart";

@Native("NNative")
class NNative {
  var status;

  var f;

  ClickCounter() {
    f = wrap(g);
  }

  g(val) => "### $val ###";
}

nativeId(x) native;

void setup() native """
nativeId = function(x) { return x; }
""";


class ClickCounter {
  var status;

  var f;

  ClickCounter() {
    f = wrap(g);
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
  // Make sure the ClickCounter class goes through interceptors.
  Expect.equals("### !!! 42 !!! ###", nativeId(new ClickCounter()).f(42));
  // We are interested in the direct call, where the type is known.
  Expect.equals("### !!! 499 !!! ###", new ClickCounter().f(499));
}
