// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

main() {
  // The SendPorts should not be serialized.
  var port = new RawReceivePort();
  Isolate.current.addErrorListener(port.sendPort);
  Isolate.current.addOnExitListener(port.sendPort);
  port.close();
}
