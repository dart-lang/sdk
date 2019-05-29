// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

final SPAWN_PACKAGE_ROOT = Uri.parse(".");

void main([args, port]) {
  var p = new ReceivePort();
  Isolate.spawnUri(
      Uri.parse("issue_12474_child.dart"), [p.sendPort as dynamic], {},
      packageRoot: SPAWN_PACKAGE_ROOT);
  p.listen((msg) {
    print("Received message");
    p.close();
  });
}
