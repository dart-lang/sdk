// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

const SPAWN_PACKAGE_ROOT = "otherPackageRoot";

void main([args, port]) {
  if (port != null) {
    testPackageRoot(args);
    return;
  }
  var p = new ReceivePort();
  Isolate.spawnUri(Platform.script,
                   [p.sendPort, Platform.packageRoot],
                   {},
                   packageRoot: SPAWN_PACKAGE_ROOT);
  p.listen((msg) {
    p.close();
  });
}


void testPackageRoot(args) {
  var parentPackageRoot = args[1];
  if (parentPackageRoot == Platform.packageRoot) {
    throw "Got parent package root";
  }
  if (Platform.packageRoot != SPAWN_PACKAGE_ROOT) {
    throw "Wrong package root";
  }
  args[0].send(null);
}

