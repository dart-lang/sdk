// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  integration("outputs results to JSON in a successful build", () {
    // Dart2js can take a long time to compile dart code, so we increase the
    // timeout to cope with that.
    currentSchedule.timeout *= 3;

    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                'web',
                [d.file('main.dart', 'void main() => print("hello");')])]).create();

    schedulePub(args: ["build", "--format", "json"], outputJson: {
      'buildResult': 'success',
      'outputDirectory': 'build',
      'numFiles': 1,
      'log': [{
          'level': 'Info',
          'transformer': {
            'name': 'Dart2JS',
            'primaryInput': {
              'package': 'myapp',
              'path': 'web/main.dart'
            }
          },
          'assetId': {
            'package': 'myapp',
            'path': 'web/main.dart'
          },
          'message': 'Compiling myapp|web/main.dart...'
        }, {
          'level': 'Info',
          'transformer': {
            'name': 'Dart2JS',
            'primaryInput': {
              'package': 'myapp',
              'path': 'web/main.dart'
            }
          },
          'assetId': {
            'package': 'myapp',
            'path': 'web/main.dart'
          },
          'message': contains(r'to compile myapp|web/main.dart.')
        }, {
          'level': 'Fine',
          'transformer': {
            'name': 'Dart2JS',
            'primaryInput': {
              'package': 'myapp',
              'path': 'web/main.dart'
            }
          },
          'assetId': {
            'package': 'myapp',
            'path': 'web/main.dart'
          },
          'message': contains(r'Took')
        }]
    });
  });
}
