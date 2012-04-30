// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Handles the `update` pub command. */
class UpdateCommand extends PubCommand {
  String get description() =>
    "update the current package's dependencies to the latest versions";

  void onRun() {
    var entrypoint;
    var packagesDir;
    var dependencies;

    getWorkingPackage().chain((package) {
      entrypoint = package;
      return package.traverseDependencies(cache);
    }).chain((packages) {
      dependencies = packages;
      // TODO(rnystrom): Make this path configurable.
      packagesDir = join(entrypoint.dir, 'packages');
      return cleanDir(packagesDir);
    }).then((dir) {
      // Symlink each dependency.
      for (final package in dependencies) {
        createSymlink(package.dir, join(packagesDir, package.name));
      }
    });
  }
}
