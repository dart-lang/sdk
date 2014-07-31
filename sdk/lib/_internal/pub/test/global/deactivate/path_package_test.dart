// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;

import '../../../lib/src/io.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('deactivates an active path package', () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("bin", [
        d.file("myapp.dart", "main() => print('ok');")
      ])
    ]).create();

    schedulePub(args: ["global", "activate", "--source", "path", "."]);

    schedulePub(args: ["global", "deactivate", "myapp"],
        output: 'Deactivated package myapp at path "'
                '${canonicalize(p.join(sandboxDir, appPath))}".');
  });
}
