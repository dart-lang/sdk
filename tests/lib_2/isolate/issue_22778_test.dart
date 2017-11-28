// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
import "package:expect/expect.dart";

func() {}

main() {
  var r = new RawReceivePort();
  r.handler = (v) {
    Expect.isTrue(v[0] == v[1]);
    r.close();
  };
  r.sendPort.send([func, func]);
}
