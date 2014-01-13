// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.isolate_legacy;

import 'dart:isolate';
import 'dart:async';

ReceivePort spawnFunction(void function(SendPort port)) {
  ReceivePort port = new ReceivePort();
  Isolate.spawn(function, port.sendPort);
  return port;
}

ReceivePort spawnDomFunction(void function(SendPort port)) {
  throw 'spawnDomFunction is no more';
}
