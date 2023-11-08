// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

final packageUriToResolve = Uri.parse("package:foo/bar.dart");
final packageResolvedUri = "file:///no/such/directory/lib/bar.dart";

final packageConfigJson = """
{
  "configVersion": 2,
  "packages": [
    {
      "name": "foo",
      "rootUri": "file:///no/such/directory",
      "packageUri": "lib/",
      "languageVersion": "2.7"
    }
  ]
}
""";

main([args, port]) async {
  if (port != null) {
    testPackageResolution(port);
    return;
  }
  await runTest(packageConfigJson);
}

Future runTest(String packageConfig) async {
  final data = Uri.dataFromString(packageConfig);
  final port = ReceivePort();
  await Isolate.spawnUri(Platform.script, [], port.sendPort,
      packageConfig: data);
  final msg = await port.first;
  if (msg is! List) {
    print(msg.runtimeType);
    throw "Failure return from spawned isolate:\n\n$msg";
  }
  if (msg[0] != data.toString()) {
    throw "Bad package config in child isolate: ${msg[0]}\n"
        "Expected: $data";
  }
  if (msg[1] != packageResolvedUri) {
    throw "Package path not matching: ${msg[1]}";
  }
  print("SUCCESS");
}

testPackageResolution(port) async {
  try {
    var packageConfigStr = Platform.packageConfig;
    var packageConfig = await Isolate.packageConfig;
    if (packageConfig != Isolate.packageConfigSync) {
      throw "Isolate.packageConfig != Isolate.packageConfigSync";
    }
    var resolvedPkg = await Isolate.resolvePackageUri(packageUriToResolve);
    if (resolvedPkg != Isolate.resolvePackageUriSync(packageUriToResolve)) {
      throw "Isolate.resolvePackageUri != Isolate.resolvePackageUriSync";
    }
    print("Spawned isolate's package config flag: $packageConfigStr");
    print("Spawned isolate's loaded package config: $packageConfig");
    print("Spawned isolate's resolved package path: $resolvedPkg");
    port.send([packageConfig?.toString(), resolvedPkg?.toString()]);
  } catch (e, s) {
    port.send("$e\n$s\n");
  }
}
