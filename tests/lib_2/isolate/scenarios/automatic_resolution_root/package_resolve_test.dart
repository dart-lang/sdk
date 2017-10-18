// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

final PACKAGE_URI = "package:foo/bar.dart";

main([args, port]) async {
  if (port != null) {
    testPackageResolution(port);
    return;
  }
  var p = new RawReceivePort();
  Isolate.spawnUri(Platform.script, [], p.sendPort,
      automaticPackageResolution: true);
  p.handler = (msg) {
    p.close();
    if (msg is! List) {
      print(msg.runtimeType);
      throw "Failure return from spawned isolate:\n\n$msg";
    }
    var child_pkg_root = Platform.script.resolve("packages/");
    if (msg[0] != child_pkg_root.toString()) {
      throw "Bad package root in child isolate: ${msg[0]}.\n"
          "Expected: $child_pkg_root";
    }
    var child_pkg_path = child_pkg_root.resolve("foo/bar.dart");
    if (msg[1] != child_pkg_path.toString()) {
      throw "Package path not matching: ${msg[1]}\n"
          "Expected $child_pkg_path";
    }
    print("SUCCESS");
  };
  print("Spawning isolate's package root: ${await Isolate.packageRoot}");
}

testPackageResolution(port) async {
  try {
    var packageRootStr = Platform.packageRoot;
    var packageConfigStr = Platform.packageConfig;
    var packageRoot = await Isolate.packageRoot;
    var resolvedPkg = await Isolate.resolvePackageUri(Uri.parse(PACKAGE_URI));
    print("Spawned isolate's package root flag: $packageRootStr");
    print("Spawned isolate's package config flag: $packageConfigStr");
    print("Spawned isolate's loaded package root: $packageRoot");
    print("Spawned isolate's resolved package path: $resolvedPkg");
    port.send([packageRoot?.toString(), resolvedPkg?.toString()]);
  } catch (e, s) {
    port.send("$e\n$s\n");
  }
}
