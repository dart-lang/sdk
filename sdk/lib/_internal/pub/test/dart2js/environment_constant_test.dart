// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../serve/utils.dart';
import '../test_pub.dart';

main() {
  initConfig();
  group("passes environment constants to dart2js", () {
    setUp(() {
      // Dart2js can take a long time to compile dart code, so we increase the
      // timeout to cope with that.
      currentSchedule.timeout *= 3;

      d.dir(appPath, [
        d.appPubspec(),
        d.dir('web', [
          d.file('file.dart',
              'void main() => print(const String.fromEnvironment("name"));')
        ])
      ]).create();
    });

    integration('from "pub build"', () {
      schedulePub(args: ["build", "--define", "name=fblthp"],
          output: new RegExp(r'Built 1 file to "build".'));

      d.dir(appPath, [
        d.dir('build', [
          d.dir('web', [
            d.matcherFile('file.dart.js', contains('fblthp')),
          ])
        ])
      ]).validate();
    });

    integration('from "pub serve"', () {
      pubServe(args: ["--define", "name=fblthp"]);
      requestShouldSucceed("file.dart.js", contains("fblthp"));
      endPubServe();
    });

    integration('which takes precedence over the pubspec', () {
      d.dir(appPath, [
        d.pubspec({
          "name": "myapp",
          "transformers": [
            {"\$dart2js": {"environment": {"name": "slartibartfast"}}}
          ]
        })
      ]).create();

      pubServe(args: ["--define", "name=fblthp"]);
      requestShouldSucceed("file.dart.js", allOf([
        contains("fblthp"),
        isNot(contains("slartibartfast"))
      ]));
      endPubServe();
    });
  });
}
