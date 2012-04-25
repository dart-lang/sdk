// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Handles the `update` pub command. */
void commandUpdate(PubOptions options, List<String> args) {
  // TODO(rnystrom): Should validate args.

  var entrypoint;
  var dependencies;
  var packagesDir;

  getWorkingPackage().chain((package) {
    entrypoint = package;
    return package.traverseDependencies();
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
