// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;

import 'descriptor.dart' as d;
import 'test_pub.dart';

main() {
  initConfig();
  forBothPubGetAndUpgrade((command) {
    integration("chooses best version matching override constraint", () {
      servePackages((builder) {
        builder.serve("foo", "1.0.0");
        builder.serve("foo", "2.0.0");
        builder.serve("foo", "3.0.0");
      });

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
      servePackages((builder) {
        builder.serve("foo", "1.0.0");
      });

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
      servePackages((builder) {
        builder.serve("foo", "1.0.0");
        builder.serve("foo", "2.0.0");
        builder.serve("foo", "3.0.0");
        builder.serve("bar", "1.0.0", pubspec: {
          "dependencies": {"foo": "5.0.0-nonexistent"}
        });
      });

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
      servePackages((builder) {
        builder.serve("foo", "1.0.0");
        builder.serve("bar", "1.0.0");
      });

      d.dir("baz", [
        d.libDir("baz"),
        d.libPubspec("baz", "0.0.1")
      ]).create();

      d.dir(appPath, [
        d.pubspec({
          "name": "myapp",
          "dependency_overrides": {
            "foo": "any",
            "bar": "any",
            "baz": {"path": "../baz"}
          }
        })
      ]).create();

      var bazPath = path.join("..", "baz");

      schedulePub(args: [command.name], output: command.success, error:
          """
          Warning: You are using these overridden dependencies:
          ! bar 1.0.0
          ! baz 0.0.1 from path $bazPath
          ! foo 1.0.0
          """);
    });
  });
}