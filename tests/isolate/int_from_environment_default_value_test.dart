// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";

import "package:expect/expect.dart";

void test(port) {
  Expect.isNull(const int.fromEnvironment('NOT_FOUND'));
  Expect.equals(
      12345, const int.fromEnvironment('NOT_FOUND', defaultValue: 12345));
  if (port != null) port.send(null);
}

main() {
  test(null);
  var port = new ReceivePort();
  Isolate.spawn(test, port.sendPort);
  port.listen((_) => port.close());
}
