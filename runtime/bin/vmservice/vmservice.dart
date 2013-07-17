// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vmservice;

import 'dart:async';
import 'dart:json' as JSON;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:utf' as UTF;


void messageHandler(message, SendPort replyTo) {
}


main() {
  port.receive(messageHandler);
}
