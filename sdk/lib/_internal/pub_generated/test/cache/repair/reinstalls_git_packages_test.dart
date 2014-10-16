// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../../../lib/src/io.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('reinstalls previously cached git packages', () {
    // Create two cached revisions of foo.
    d.git('foo.git', [d.libDir('foo'), d.libPubspec('foo', '1.0.0')]).create();

    d.appDir({
      "foo": {
        "git": "../foo.git"
      }
    }).create();
    pubGet();

    d.git('foo.git', [d.libDir('foo'), d.libPubspec('foo', '1.0.1')]).commit();

    pubUpgrade();

    // Break them.
    var fooDirs;
    schedule(() {
      // Find the cached foo packages for each revision.
      var gitCacheDir = path.join(sandboxDir, cachePath, "git");
      fooDirs = listDir(
          gitCacheDir).where((dir) => path.basename(dir).startsWith("foo-")).toList();

      // Delete "foo.dart" from them.
      for (var dir in fooDirs) {
        deleteEntry(path.join(dir, "lib", "foo.dart"));
      }
    });

    // Repair them.
    schedulePub(args: ["cache", "repair"], output: '''
          Resetting Git repository for foo 1.0.0...
          Resetting Git repository for foo 1.0.1...
          Reinstalled 2 packages.''');

    // The missing libraries should have been replaced.
    schedule(() {
      var fooLibs = fooDirs.map((dir) {
        var fooDirName = path.basename(dir);
        return d.dir(
            fooDirName,
            [d.dir("lib", [d.file("foo.dart", 'main() => "foo";')])]);
      }).toList();

      d.dir(cachePath, [d.dir("git", fooLibs)]).validate();
    });
  });
}
