// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A package source that installs packages from Git repos.
 */
class GitSource extends Source {
  final String name = "git";

  // TODO(nweiz): this should be cached since it uses the network, but until we
  // support versions there's no good way to distinguish between different
  // checkouts of the same repository.
  final bool shouldCache = false;

  GitSource();

  /**
   * Clones a Git repo to the local filesystem.
   */
  Future<bool> install(PackageId id, String destPath) {
    return runProcess("git", ["clone", "--progress", id.fullName, destPath],
        pipeStdout: true, pipeStderr: true).
      transform((result) => result.success);
  }

  /**
   * The package name of a Git repo is the name of the directory into which
   * it'll be cloned.
   */
  String packageName(PackageId id) =>
      basename(id.fullName).replaceFirst(const RegExp("\.git\$"), "");
}
