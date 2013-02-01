// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library check_sdk_test;

import "test_pub.dart";
import "../../../pkg/unittest/lib/unittest.dart";

main() {
  initConfig();

  for (var command in ["install", "update"]) {
    var success = new RegExp(r"Dependencies installed!$");
    if (command == "update") {
      success = new RegExp(r"Dependencies updated!$");
    }

    integration("gives a friendly message if there are no constraints", () {
      dir(appPath, [
        pubspec({"name": "myapp"}),
      ]).scheduleCreate();

      schedulePub(args: [command], output: success);
    });

    integration("gives an error if the root package does not match", () {
      dir(appPath, [
        pubspec({
          "name": "myapp",
          "environment": {"sdk": ">2.0.0"}
        })
      ]).scheduleCreate();

      schedulePub(args: [command],
          error:
            """
            Some packages are not compatible with your SDK version 0.1.2+3:
            - 'myapp' requires >2.0.0

            You may be able to resolve this by upgrading to the latest Dart SDK
            or adding a version constraint to use an older version of a package.
            """);
    });

    integration("gives an error if some dependencies do not match", () {
      // Using an SDK source, but this should be true of all sources.
      dir(sdkPath, [
        dir("pkg", [
          dir("foo", [
            libPubspec("foo", "0.0.1", sdk: ">0.1.3"),
            libDir("foo")
          ]),
          dir("bar", [
            libPubspec("bar", "0.0.1", sdk: ">0.1.1"),
            libDir("bar")
          ])
        ])
      ]).scheduleCreate();

      dir(appPath, [
        pubspec({
          "name": "myapp",
          "dependencies": {
            "foo": { "sdk": "foo" },
            "bar": { "sdk": "bar" }
          },
          "environment": {"sdk": ">2.0.0"}
        })
      ]).scheduleCreate();

      schedulePub(args: [command],
          error:
            """
            Some packages are not compatible with your SDK version 0.1.2+3:
            - 'myapp' requires >2.0.0
            - 'foo' requires >0.1.3

            You may be able to resolve this by upgrading to the latest Dart SDK
            or adding a version constraint to use an older version of a package.
            """);
    });

    integration("gives an error if a transitive dependency doesn't match", () {
      // Using an SDK source, but this should be true of all sources.
      dir(sdkPath, [
        dir("pkg", [
          dir("foo", [
            libPubspec("foo", "0.0.1", deps: [
              {"sdk": "bar"}
            ]),
            libDir("foo")
          ]),
          dir("bar", [
            libPubspec("bar", "0.0.1", sdk: "<0.1.1"),
            libDir("bar")
          ])
        ])
      ]).scheduleCreate();

      dir(appPath, [
        pubspec({
          "name": "myapp",
          "dependencies": {
            "foo": { "sdk": "foo" }
          }
        })
      ]).scheduleCreate();

      schedulePub(args: [command],
          error:
            """
            Some packages are not compatible with your SDK version 0.1.2+3:
            - 'bar' requires <0.1.1

            You may be able to resolve this by upgrading to the latest Dart SDK
            or adding a version constraint to use an older version of a package.
            """);
    });
  }
}
