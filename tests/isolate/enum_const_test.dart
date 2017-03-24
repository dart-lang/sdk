// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
import "package:expect/expect.dart";

enum Foo { BAR, BAZ }

verify(val) {
  Expect.identical(Foo.BAR, val);
}

main() {
  test1(); //# 01: ok
  test2(); //# 02: ok
}

test1() => verify(Foo.BAR);

test2() {
  var rp;
  rp = new RawReceivePort((val) {
    verify(val);
    rp.close();
  });
  rp.sendPort.send(Foo.BAR);
}
