// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

final SPAWN_PACKAGE_ROOT = "file:///no/such/package/root/";
final PACKAGE_URI = "package:foo/bar.dart";
final PACKAGE_PATH = "file:///no/such/package/root/foo/bar.dart";

main([args, port]) async {
  if (port != null) {
    testPackageResolution(port);
    return;
  }
  var p = new RawReceivePort();
  Isolate.spawnUri(Platform.script, [], p.sendPort,
      packageRoot: Uri.parse(SPAWN_PACKAGE_ROOT));
  p.handler = (msg) {
    p.close();
    if (msg is! List) {
      print(msg.runtimeType);
      throw "Failure return from spawned isolate:\n\n$msg";
    }
    if (msg[0] != SPAWN_PACKAGE_ROOT) {
      throw "Bad package root in child isolate: ${msg[0]}";
    }
    if (msg[1] != PACKAGE_PATH) {
      throw "Package path not matching: ${msg[1]}";
    }
    print("SUCCESS");
  };
  print("Spawning isolate's package root: ${await Isolate.packageRoot}");
}

testPackageResolution(port) async {
  try {
    var packageRootStr = Platform.packageRoot;
    var packageRoot = await Isolate.packageRoot;
    var resolvedPkg = await Isolate.resolvePackageUri(Uri.parse(PACKAGE_URI));
    print("Spawned isolate's package root flag: $packageRootStr");
    print("Spawned isolate's loaded package root: $packageRoot");
    print("Spawned isolate's resolved package path: $resolvedPkg");
    port.send([packageRoot?.toString(), resolvedPkg?.toString()]);
  } catch (e, s) {
    port.send("$e\n$s\n");
  }
}
