// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('git_source');

#import('io.dart');
#import('package.dart');
#import('source.dart');
#import('utils.dart');

/**
 * A package source that installs packages from Git repos.
 */
class GitSource extends Source {
  final String name = "git";

  // TODO(rnystrom): Git packages could in theory be cached, but that adds a
  // lot of complexity. When you install a git package, you are installing
  // and pinning to a specific commit. That means different installs of the
  // same git path but at different commits need to be disambiguated in the
  // system cache. It may also lead to a lot of garbage in the system cache.
  // For now, we are punting and simply not caching them.
  final bool shouldCache = false;

  GitSource();

  /**
   * Clones a Git repo to the local filesystem.
   */
  Future<bool> install(PackageId id, String destPath) {
    return isGitInstalled.chain((installed) {
      if (installed) {
        return runProcess("git",
            ["clone", "--progress", id.description, destPath],
            pipeStdout: true, pipeStderr: true).
          transform((result) => result.success);
      } else {
        throw new Exception(
            "Cannot install '${id.name}' from Git (${id.description}).\n"
            "Please ensure Git is correctly installed.");
      }
    });
  }

  /**
   * The package name of a Git repo is the name of the directory into which
   * it'll be cloned.
   */
  String packageName(PackageId id) =>
      basename(id.description).replaceFirst(const RegExp("\.git\$"), "");

  /**
   * Ensures [description] is a Git URL.
   */
  void validateDescription(description) {
    if (description is! String) {
      throw new FormatException("The description must be a git URL.");
    }
  }
}
