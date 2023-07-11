// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:io';
import 'dart:isolate';

final SPAWN_PACKAGE_ROOT = "file:///no/such/file/";

main([args, port]) async {
  if (port != null) {
    testPackageRoot(port);
    return;
  }
  var p = new RawReceivePort();
  Isolate.spawnUri(Platform.script, [], p.sendPort,
      packageRoot: Uri.parse(SPAWN_PACKAGE_ROOT));
  p.handler = (msg) {
    p.close();
    print("SUCCESS");
  };
}

testPackageRoot(port) async {
  port.send('done');
}
