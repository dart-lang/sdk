// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'descriptor.dart' as d;
import 'test_pub.dart';
import '../lib/src/barback.dart' as barback;
import '../lib/src/version.dart';

main() {
  initConfig();

  var current = barback.supportedVersions.min.toString();
  var previous = new Version(barback.supportedVersions.min.major,
      barback.supportedVersions.min.minor - 1, 0).toString();
  var nextPatch = barback.supportedVersions.min.nextPatch.toString();
  var max = barback.supportedVersions.max.toString();

  forBothPubGetAndUpgrade((command) {
    integration("implicitly constrains barback to versions pub supports", () {
      servePackages([
        packageMap("barback", previous),
        packageMap("barback", current),
        packageMap("barback", nextPatch),
        packageMap("barback", max)
      ]);

      d.appDir({
        "barback": "any"
      }).create();

      pubCommand(command);

      d.packagesDir({
        "barback": barback.supportedVersions.min.nextPatch.toString()
      }).validate();
    });

    integration("discovers transitive dependency on barback", () {
      servePackages([
        packageMap("barback", previous),
        packageMap("barback", current),
        packageMap("barback", nextPatch),
        packageMap("barback", max)
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
        "barback": nextPatch,
        "foo": "0.0.1"
      }).validate();
    });

    integration("pub's implicit constraint uses the same source and "
        "description as the explicit one", () {
      d.dir('barback', [
        d.libDir('barback', 'barback $current'),
        d.libPubspec('barback', current)
      ]).create();

      d.dir(appPath, [
        d.appPubspec({
          "barback": {"path": "../barback"}
        })
      ]).create();

      pubCommand(command);

      d.packagesDir({
        "barback": current
      }).validate();
    });
  });

  integration("unlock if the locked version doesn't meet pub's constraint", () {
    servePackages([
      packageMap("barback", previous),
      packageMap("barback", current)
    ]);

    d.appDir({"barback": "any"}).create();

    // Hand-create a lockfile to pin barback to an older version.
    createLockFile("myapp", hosted: {
      "barback": previous
    });

    pubGet();

    // It should be upgraded.
    d.packagesDir({
      "barback": current
    }).validate();
  });

  integration("includes pub in the error if a solve failed because there "
      "is no version available", () {
    servePackages([
      packageMap("barback", previous)
    ]);

    d.appDir({"barback": "any"}).create();

    pubGet(error: """
Package barback has no versions that match >=$current <$max derived from:
- myapp depends on version any
- pub itself depends on version >=$current <$max""");
  });

  integration("includes pub in the error if a solve failed because there "
      "is a disjoint constraint", () {
    servePackages([
      packageMap("barback", current)
    ]);

    d.appDir({"barback": previous}).create();

    pubGet(error: """
Incompatible version constraints on barback:
- myapp depends on version $previous
- pub itself depends on version >=$current <$max""");
  });
}