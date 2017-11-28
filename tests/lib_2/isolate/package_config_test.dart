// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--trace_shutdown
import 'dart:io';
import 'dart:isolate';

final SPAWN_PACKAGE_CONFIG = "foobar:///no/such/file/";

main([args, port]) async {
  if (port != null) {
    testPackageConfig(port);
    return;
  }
  var p = new RawReceivePort();
  Isolate.spawnUri(Platform.script, [], p.sendPort,
      packageConfig: Uri.parse(SPAWN_PACKAGE_CONFIG));
  p.handler = (msg) {
    p.close();
    if (msg[0] != SPAWN_PACKAGE_CONFIG) {
      throw "Bad package config in child isolate: ${msg[0]}";
    }
    if (msg[1] != null) {
      throw "Non-null loaded package config in isolate: ${msg[1]}";
    }
    print("SUCCESS");
  };
  print("Spawning isolate's package config: ${await Isolate.packageConfig}");
}

testPackageConfig(port) async {
  var packageConfigStr = Platform.packageConfig;
  var packageConfig = await Isolate.packageConfig;
  print("Spawned isolate's package config flag: $packageConfigStr");
  print("Spawned isolate's loaded package config: $packageConfig");
  port.send([packageConfigStr, packageConfig?.toString()]);
}
