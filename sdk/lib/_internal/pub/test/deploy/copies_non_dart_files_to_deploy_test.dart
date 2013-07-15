// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  integration("copies non-Dart files to deploy/", () {
    servePackages([packageMap("browser", "1.0.0")]);

    d.dir(appPath, [
      // A browser dependency with no entrypoints shouldn't cause dart.js to be
      // copied in.
      d.appPubspec([dependencyMap("browser", "1.0.0")]),
      d.dir('web', [
        d.file('file.txt', 'contents'),
        d.dir('subdir', [
          d.file('subfile.txt', 'subcontents')
        ])
      ])
    ]).create();

    schedulePub(args: ["deploy"],
        output: '''
Finding entrypoints...
Copying   web| => deploy|
'''.replaceAll('|', path.separator),
        exitCode: 0);

    d.dir(appPath, [
      d.dir('deploy', [
        d.nothing('packages'),
        d.file('file.txt', 'contents'),
        d.dir('subdir', [
          d.file('subfile.txt', 'subcontents')
        ])
      ])
    ]).validate();
  });
}
