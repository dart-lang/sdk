// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// PackageRoot=none

import 'dart:io';
import 'dart:isolate';

main([args, port]) async {
  if (port != null) {
    testBadResolvePackage(port);
    return;
  }
  var p = new RawReceivePort();
  Isolate.spawnUri(Platform.script, [], p.sendPort);
  p.handler = (msg) {
    p.close();
    if (msg is! List) {
      print(msg.runtimeType);
      throw "Failure return from spawned isolate:\n\n$msg";
    }
    // Expecting a null resolution for inexistent package mapping.
    if (msg[0] != null) {
      throw "Bad package config in child isolate: ${msg[0]}\n"
          "Expected: 'Foo'";
    }
    print("SUCCESS");
  };
}

testBadResolvePackage(port) async {
  try {
    var packageRootStr = Platform.packageRoot;
    var packageConfigStr = Platform.packageConfig;
    var packageConfig = await Isolate.packageConfig;
    var badPackageUri = Uri.parse("package:asdf/qwerty.dart");
    var resolvedPkg = await Isolate.resolvePackageUri(badPackageUri);
    print("Spawned isolate's package root flag: $packageRootStr");
    print("Spawned isolate's package config flag: $packageConfigStr");
    print("Spawned isolate's loaded package config: $packageConfig");
    print("Spawned isolate's resolved package path: $resolvedPkg");
    port.send([resolvedPkg]);
  } catch (e, s) {
    port.send("$e\n$s\n");
  }
}
