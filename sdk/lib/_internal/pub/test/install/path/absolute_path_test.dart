// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE d.file.

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../../../lib/src/io.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('path dependency with absolute path', () {
    d.dir('foo', [
      d.libDir('foo'),
      d.libPubspec('foo', '0.0.1')
    ]).create();

    d.dir(appPath, [
      d.appPubspec({
        "foo": {"path": path.join(sandboxDir, "foo")}
      })
    ]).create();

    pubInstall();

    d.dir(packagesPath, [
      d.dir("foo", [
        d.file("foo.dart", 'main() => "foo";')
      ])
    ]).validate();

    // Move the packages directory and ensure the symlink still works. That
    // will validate that we actually created an absolute symlink.
    d.dir("moved").create();
    scheduleRename(packagesPath, "moved/packages");

    d.dir("moved/packages", [
      d.dir("foo", [
        d.file("foo.dart", 'main() => "foo";')
      ])
    ]).validate();
  });
}