// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';

import '../../../lib/src/io.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  // Regression test for issue 20947.
  integration('checks out an unfetched and locked revision of a cached '
      'repository', () {
    ensureGit();

    // In order to get a lockfile that refers to a newer revision than is in the
    // cache, we'll switch between two caches. First we ensure that the repo is
    // in the first cache.
    d.git('foo.git', [
      d.libDir('foo'),
      d.libPubspec('foo', '1.0.0')
    ]).create();

    d.appDir({"foo": {"git": "../foo.git"}}).create();

    pubGet();

    // Switch to a new cache.
    schedule(() => renameDir(
        p.join(sandboxDir, cachePath), p.join(sandboxDir, "$cachePath.old")));

    // Make the lockfile point to a new revision of the git repository.
    d.git('foo.git', [
      d.libDir('foo', 'foo 2'),
      d.libPubspec('foo', '1.0.0')
    ]).commit();

    pubUpgrade(output: contains("Changed 1 dependency!"));

    // Switch back to the old cache.
    schedule(() {
      var cacheDir = p.join(sandboxDir, cachePath);
      deleteEntry(cacheDir);
      renameDir(p.join(sandboxDir, "$cachePath.old"), cacheDir);
    });

    // Get the updated version of the git dependency based on the lockfile.
    pubGet();

    d.dir(cachePath, [
      d.dir('git', [
        d.dir('cache', [d.gitPackageRepoCacheDir('foo')]),
        d.gitPackageRevisionCacheDir('foo'),
        d.gitPackageRevisionCacheDir('foo', 2)
      ])
    ]).validate();

    d.dir(packagesPath, [
      d.dir('foo', [
        d.file('foo.dart', 'main() => "foo 2";')
      ])
    ]).validate();
  });
}
