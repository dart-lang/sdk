// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

const REJECT_CONFIG_TRANSFORMER = """
import 'dart:async';

import 'package:barback/barback.dart';

class RejectConfigTransformer extends Transformer {
  RejectConfigTransformer.asPlugin(BarbackSettings settings) {
    throw "I hate these settings!";
  }

  Future<bool> isPrimary(_) => new Future.value(true);
  Future apply(Transform transform) {}
}
""";

main() {
  initConfig();

  withBarbackVersions("any", () {
     integration("a transformer can reject is configuration", () {
       d.dir(appPath, [
         d.pubspec({
           "name": "myapp",
           "transformers": [{"myapp/src/transformer": {'foo': 'bar'}}]
         }),
         d.dir("lib", [d.dir("src", [
           d.file("transformer.dart", REJECT_CONFIG_TRANSFORMER)
         ])])
       ]).create();

       createLockFile('myapp', pkg: ['barback']);

       var pub = startPubServe();
       pub.stderr.expect(endsWith('Error loading transformer: I hate these '
           'settings!'));
       pub.shouldExit(1);
     });
  });
}