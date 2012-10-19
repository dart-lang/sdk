// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

class Bar {}

main() {
  final port = new ReceivePort();
  port.receive((msg, reply) {
    Expect.equals(new Bar().runtimeType.toString(), 'Bar');
  });
  port.toSendPort().send(null, null);
}
