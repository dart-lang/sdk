// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  integration("preserves .htaccess as a special case", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir('web', [
        d.file('.htaccess', 'fblthp'),
        d.file('.hidden', 'asdfgh')
      ])
    ]).create();

    schedulePub(args: ["build"],
        output: new RegExp(r'Built \d+ files? to "build".'));

    d.dir(appPath, [
      d.dir('build', [
        d.dir('web', [
          d.file('.htaccess', 'fblthp'),
          d.nothing('.hidden')
        ])
      ])
    ]).validate();
  });
}
