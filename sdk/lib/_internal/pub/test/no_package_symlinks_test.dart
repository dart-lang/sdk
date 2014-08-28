// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import 'descriptor.dart' as d;
import 'test_pub.dart';

main() {
  initConfig();

  forBothPubGetAndUpgrade((command) {
    group("with --no-package-symlinks", () {
      integration("installs hosted dependencies to the cache", () {
        servePackages((builder) {
          builder.serve("foo", "1.0.0");
          builder.serve("bar", "1.0.0");
        });

        d.appDir({"foo": "any", "bar": "any"}).create();

        pubCommand(command, args: ["--no-package-symlinks"]);

        d.nothing("$appPath/packages").validate();

        d.hostedCache([
          d.dir("foo-1.0.0", [
            d.dir("lib", [d.file("foo.dart", 'main() => "foo 1.0.0";')])
          ]),
          d.dir("bar-1.0.0", [
            d.dir("lib", [d.file("bar.dart", 'main() => "bar 1.0.0";')])
          ])
        ]).validate();
      });

      integration("installs git dependencies to the cache", () {
        ensureGit();

        d.git('foo.git', [
          d.libDir('foo'),
          d.libPubspec('foo', '1.0.0')
        ]).create();

        d.appDir({"foo": {"git": "../foo.git"}}).create();

        pubCommand(command, args: ["--no-package-symlinks"]);

        d.nothing("$appPath/packages").validate();

        d.dir(cachePath, [
          d.dir('git', [
            d.dir('cache', [d.gitPackageRepoCacheDir('foo')]),
            d.gitPackageRevisionCacheDir('foo')
          ])
        ]).validate();
      });

      integration("locks path dependencies", () {
        d.dir("foo", [
          d.libDir("foo"),
          d.libPubspec("foo", "0.0.1")
        ]).create();

        d.dir(appPath, [
          d.appPubspec({
            "foo": {"path": "../foo"}
          })
        ]).create();

        pubCommand(command, args: ["--no-package-symlinks"]);

        d.nothing("$appPath/packages").validate();
        d.matcherFile("$appPath/pubspec.lock", contains("foo"));
      });

      integration("removes package directories near entrypoints", () {
        d.dir(appPath, [
          d.appPubspec(),
          d.dir("packages"),
          d.dir("bin/packages"),
          d.dir("web/packages"),
          d.dir("web/subdir/packages")
        ]).create();

        pubCommand(command, args: ["--no-package-symlinks"]);

        d.dir(appPath, [
          d.nothing("packages"),
          d.nothing("bin/packages"),
          d.nothing("web/packages"),
          d.nothing("web/subdir/packages")
        ]).validate();
      });

      integration("doesn't remove package directories that pub wouldn't "
          "generate", () {
        d.dir(appPath, [
          d.appPubspec(),
          d.dir("packages"),
          d.dir("bin/subdir/packages"),
          d.dir("lib/packages")
        ]).create();

        pubCommand(command, args: ["--no-package-symlinks"]);

        d.dir(appPath, [
          d.nothing("packages"),
          d.dir("bin/subdir/packages"),
          d.dir("lib/packages")
        ]).validate();
      });
    });
  });
}
