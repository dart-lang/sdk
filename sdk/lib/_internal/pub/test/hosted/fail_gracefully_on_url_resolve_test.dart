// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  forBothPubInstallAndUpdate((command) {
    integration('fails gracefully if the url does not resolve', () {
      d.dir(appPath, [
        d.appPubspec({
          "foo": {
            "hosted": {
              "name": "foo",
              "url": "http://pub.invalid"
            }
          }
        })
      ]).create();

      pubCommand(command, error: 'Could not resolve URL "http://pub.invalid".');
    });
  });
}
