// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'descriptor.dart' as d;
import 'test_pub.dart';
import '../lib/src/barback.dart' as barback;
import '../lib/src/version.dart';

main() {
  initConfig();

  var constraint = barback.pubConstraints["barback"];
  var current = constraint.min.toString();
  var previous = new Version(constraint.min.major, constraint.min.minor - 1, 0)
      .toString();
  var nextPatch = constraint.min.nextPatch.toString();
  var max = constraint.max.toString();

  var sourceMapsVersion = barback.pubConstraints["source_maps"].min.toString();
  var stackTraceVersion = barback.pubConstraints["stack_trace"].min.toString();

  forBothPubGetAndUpgrade((command) {
    integration("implicitly constrains barback to versions pub supports", () {
      servePackages([
        packageMap("barback", previous),
        packageMap("barback", current),
        packageMap("barback", nextPatch),
        packageMap("barback", max),
        packageMap("source_maps", sourceMapsVersion),
        packageMap("stack_trace", stackTraceVersion)
      ]);

      d.appDir({
        "barback": "any"
      }).create();

      pubCommand(command);

      d.packagesDir({
        "barback": nextPatch
      }).validate();
    });

    integration("discovers transitive dependency on barback", () {
      servePackages([
        packageMap("barback", previous),
        packageMap("barback", current),
        packageMap("barback", nextPatch),
        packageMap("barback", max),
        packageMap("source_maps", sourceMapsVersion),
        packageMap("stack_trace", stackTraceVersion)
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
        "description as a dependency override", () {
      servePackages([
        packageMap("source_maps", sourceMapsVersion),
        packageMap("stack_trace", stackTraceVersion)
      ]);

      d.dir('barback', [
        d.libDir('barback', 'barback $current'),
        d.libPubspec('barback', current),
      ]).create();

      d.dir(appPath, [
        d.pubspec({
          "name": "myapp",
          "dependency_overrides": {
            "barback": {"path": "../barback"}
          }
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
      packageMap("barback", current),
      packageMap("source_maps", sourceMapsVersion),
      packageMap("stack_trace", stackTraceVersion)
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
      packageMap("barback", previous),
      packageMap("source_maps", sourceMapsVersion),
      packageMap("stack_trace", stackTraceVersion)
    ]);

    d.appDir({"barback": "any"}).create();

    pubGet(error: """
Package barback 0.12.0 does not match >=$current <$max derived from:
- myapp 0.0.0 depends on version any
- pub itself depends on version >=$current <$max""");
  });

  integration("includes pub in the error if a solve failed because there "
      "is a disjoint constraint", () {
    servePackages([
      packageMap("barback", previous),
      packageMap("barback", current),
      packageMap("source_maps", sourceMapsVersion),
      packageMap("stack_trace", stackTraceVersion)
    ]);

    d.appDir({"barback": previous}).create();

    pubGet(error: """
Incompatible version constraints on barback:
- myapp 0.0.0 depends on version $previous
- pub itself depends on version >=$current <$max""");
  });
}