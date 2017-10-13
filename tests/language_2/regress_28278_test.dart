// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--load-deferred-eagerly
// VMOptions=

import "package:expect/expect.dart";

import "regress_28278_lib.dart" deferred as def;

var result = "";

class D {
  m() async {
    await def.loadLibrary();
    result = def.foo(result += "Here");
  }
}

main() async {
  var d = new D();
  await d.m();
  await d.m();
  Expect.equals("HereHelloHereHello", result);
}
