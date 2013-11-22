// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'descriptor.dart' as d;
import 'test_pub.dart';

main() {
  initConfig();
  forBothPubGetAndUpgrade((command) {
    integration("chooses best version matching override constraint", () {
      servePackages([
        packageMap("foo", "1.0.0"),
        packageMap("foo", "2.0.0"),
        packageMap("foo", "3.0.0")
      ]);

      d.dir(appPath, [
        d.pubspec({
          "name": "myapp",
          "dependencies": {
            "foo": ">2.0.0"
          },
          "dependency_overrides": {
            "foo": "<3.0.0"
          }
        })
      ]).create();

      pubCommand(command);

      d.packagesDir({
        "foo": "2.0.0"
      }).validate();
    });

    integration("treats override as implicit dependency", () {
      servePackages([
        packageMap("foo", "1.0.0")
      ]);

      d.dir(appPath, [
        d.pubspec({
          "name": "myapp",
          "dependency_overrides": {
            "foo": "any"
          }
        })
      ]).create();

      pubCommand(command);

      d.packagesDir({
        "foo": "1.0.0"
      }).validate();
    });

    integration("ignores other constraints on overridden package", () {
      servePackages([
        packageMap("foo", "1.0.0"),
        packageMap("foo", "2.0.0"),
        packageMap("foo", "3.0.0"),
        packageMap("bar", "1.0.0", {"foo": "5.0.0-nonexistent"})
      ]);

      d.dir(appPath, [
        d.pubspec({
          "name": "myapp",
          "dependencies": {
            "bar": "any"
          },
          "dependency_overrides": {
            "foo": "<3.0.0"
          }
        })
      ]).create();

      pubCommand(command);

      d.packagesDir({
        "foo": "2.0.0",
        "bar": "1.0.0"
      }).validate();
    });

    integration("warns about overridden dependencies", () {
      servePackages([
        packageMap("foo", "1.0.0"),
        packageMap("bar", "1.0.0"),
        packageMap("baz", "1.0.0")
      ]);

      d.dir(appPath, [
        d.pubspec({
          "name": "myapp",
          "dependency_overrides": {
            "foo": "any",
            "bar": "any",
            "baz": "any"
          }
        })
      ]).create();

      schedulePub(args: [command.name], output: command.success, error:
          """
          Warning: You are overriding these dependencies:
          - bar any from hosted (bar)
          - baz any from hosted (baz)
          - foo any from hosted (foo)
          """);
    });
  });
}