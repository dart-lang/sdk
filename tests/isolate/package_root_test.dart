// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

final SPAWN_PACKAGE_ROOT = "file:///no/such/file/";

void main([args, port]) {
  if (port != null) {
    testPackageRoot(port);
    return;
  }
  var p = new RawReceivePort();
  Isolate.spawnUri(Platform.script,
                   [],
                   p.sendPort,
                   packageRoot: Uri.parse(SPAWN_PACKAGE_ROOT));
  p.handler = (msg) {
    p.close();
    if (msg != SPAWN_PACKAGE_ROOT) {
      throw "Bad package root in child isolate: $msg";
    }
  };
}

testPackageRoot(port) async {
  var packageRoot = await Isolate.packageRoot;
  port.send(packageRoot.toString());
}
