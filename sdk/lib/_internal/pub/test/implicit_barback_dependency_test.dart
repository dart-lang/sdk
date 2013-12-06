// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'descriptor.dart' as d;
import 'test_pub.dart';
import '../lib/src/barback.dart' as barback;
import '../lib/src/version.dart';

main() {
  initConfig();

  var previousVersion = new Version(
      barback.supportedVersion.major, barback.supportedVersion.minor - 1, 0);

  forBothPubGetAndUpgrade((command) {
    integration("implicitly constrains barback to versions pub supports", () {
      servePackages([
        packageMap("barback", previousVersion.toString()),
        packageMap("barback", barback.supportedVersion.toString()),
        packageMap("barback", barback.supportedVersion.nextPatch.toString()),
        packageMap("barback", barback.supportedVersion.nextMinor.toString())
      ]);

      d.appDir({
        "barback": "any"
      }).create();

      pubCommand(command);

      d.packagesDir({
        "barback": barback.supportedVersion.nextPatch.toString()
      }).validate();
    });

    integration("discovers transitive dependency on barback", () {
      servePackages([
        packageMap("barback", previousVersion.toString()),
        packageMap("barback", barback.supportedVersion.toString()),
        packageMap("barback", barback.supportedVersion.nextPatch.toString()),
        packageMap("barback", barback.supportedVersion.nextMinor.toString())
      ]);

      d.dir("foo", [
        d.libDir("foo", "foo 0.0.1"),
        d.libPubspec("foo", "0.0.1", deps: {
          "barback": "any"
        })
      ]).create();

      d.appDir({
        "foo": {"path": "../foo"}
      }).create();

      pubCommand(command);

      d.packagesDir({
        "barback": barback.supportedVersion.nextPatch.toString(),
        "foo": "0.0.1"
      }).validate();
    });
  });

  integration("unlock if the locked version doesn't meet pub's constraint", () {
    servePackages([
      packageMap("barback", previousVersion.toString()),
      packageMap("barback", barback.supportedVersion.toString())
    ]);

    d.appDir({"barback": "any"}).create();

    // Hand-create a lockfile to pin barback to an older version.
    createLockFile("myapp", hosted: {
      "barback": previousVersion.toString()
    });

    pubGet();

    // It should be upgraded.
    d.packagesDir({
      "barback": barback.supportedVersion.toString()
    }).validate();
  });
}