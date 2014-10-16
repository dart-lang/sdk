// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('checks out and upgrades a package from Git', () {
    ensureGit();

    d.git('foo.git', [d.libDir('foo'), d.libPubspec('foo', '1.0.0')]).create();

    d.appDir({
      "foo": {
        "git": "../foo.git"
      }
    }).create();

    pubGet();

    d.dir(
        cachePath,
        [
            d.dir(
                'git',
                [
                    d.dir('cache', [d.gitPackageRepoCacheDir('foo')]),
                    d.gitPackageRevisionCacheDir('foo')])]).validate();

    d.dir(
        packagesPath,
        [d.dir('foo', [d.file('foo.dart', 'main() => "foo";')])]).validate();

    d.git(
        'foo.git',
        [d.libDir('foo', 'foo 2'), d.libPubspec('foo', '1.0.0')]).commit();

    pubUpgrade();

    // When we download a new version of the git package, we should re-use the
    // git/cache directory but create a new git/ directory.
    d.dir(
        cachePath,
        [
            d.dir(
                'git',
                [
                    d.dir('cache', [d.gitPackageRepoCacheDir('foo')]),
                    d.gitPackageRevisionCacheDir('foo'),
                    d.gitPackageRevisionCacheDir('foo', 2)])]).validate();

    d.dir(
        packagesPath,
        [d.dir('foo', [d.file('foo.dart', 'main() => "foo 2";')])]).validate();
  });
}
