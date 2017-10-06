// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// PackageRoot=none

import 'dart:io';
import 'dart:isolate';

import "package:foo/foo.dart";
import "package:bar/bar.dart";

var CONFIG_URI = "package:bar/spawned_packages/";

main([args, port]) async {
  if (port != null) {
    testCorrectBarPackage(port);
    return;
  }
  var p = new RawReceivePort();
  Isolate.spawnUri(Platform.script, [], p.sendPort,
      packageRoot: Uri.parse(CONFIG_URI));
  p.handler = (msg) {
    p.close();
    if (msg is! List) {
      print(msg.runtimeType);
      throw "Failure return from spawned isolate:\n\n$msg";
    }
    if (msg[0] != "Foo") {
      throw "Bad package config in child isolate: ${msg[0]}\n"
          "Expected: 'Foo'";
    }
    if (msg[1] != "Bar2") {
      throw "Package path not matching: ${msg[1]}\n"
          "Expected: 'Bar2'";
    }
    print("SUCCESS");
  };
  if (Bar.value != "Bar1") {
    throw "Spawning isolate package:bar invalid.";
  }
  print("Spawned isolate resolved $CONFIG_URI to: "
      "${await Isolate.resolvePackageUri(Uri.parse(CONFIG_URI))}");
}

testCorrectBarPackage(port) async {
  try {
    var packageRootStr = Platform.packageRoot;
    var packageConfigStr = Platform.packageConfig;
    var packageConfig = await Isolate.packageConfig;
    var resolvedPkg = await Isolate.resolvePackageUri(Uri.parse(CONFIG_URI));
    print("Spawned isolate's package root flag: $packageRootStr");
    print("Spawned isolate's package config flag: $packageConfigStr");
    print("Spawned isolate's loaded package config: $packageConfig");
    print("Spawned isolate's resolved package path: $resolvedPkg");
    port.send([Foo.value, Bar.value]);
  } catch (e, s) {
    port.send("$e\n$s\n");
  }
}
