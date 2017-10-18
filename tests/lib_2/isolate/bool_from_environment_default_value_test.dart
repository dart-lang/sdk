// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";

import "package:expect/expect.dart";

void test(port) {
  Expect.isFalse(const bool.fromEnvironment('NOT_FOUND'));
  Expect.isTrue(const bool.fromEnvironment('NOT_FOUND', defaultValue: true));
  Expect.isFalse(const bool.fromEnvironment('NOT_FOUND', defaultValue: false));
  Expect.isNull(const bool.fromEnvironment('NOT_FOUND', defaultValue: null));
  if (port != null) port.send(null);
}

main() {
  test(null);
  var port = new ReceivePort();
  Isolate.spawn(test, port.sendPort);
  port.listen((_) => port.close());
}
