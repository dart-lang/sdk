// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:isolate";
import "package:expect/expect.dart";

main() async {
  var pkgRoot = Uri.parse("file:///no/such/directory/");
  var pkgConfig = Uri.parse("file:///no/such/.packages");
  try {
    var i = await Isolate.spawnUri(Platform.script, [], null,
        packageRoot: pkgRoot, packageConfig: pkgConfig);
  } catch (e) {
    print(e);
    Expect.isTrue(e is ArgumentError);
  }
  try {
    var i = await Isolate.spawnUri(Platform.script, [], null,
        packageRoot: pkgRoot, automaticPackageResolution: true);
  } catch (e) {
    print(e);
    Expect.isTrue(e is ArgumentError);
  }
  try {
    var i = await Isolate.spawnUri(Platform.script, [], null,
        packageConfig: pkgConfig, automaticPackageResolution: true);
  } catch (e) {
    print(e);
    Expect.isTrue(e is ArgumentError);
  }
  try {
    var i = await Isolate.spawnUri(Platform.script, [], null,
        packageRoot: pkgRoot,
        packageConfig: pkgConfig,
        automaticPackageResolution: true);
  } catch (e) {
    print(e);
    Expect.isTrue(e is ArgumentError);
  }
}
