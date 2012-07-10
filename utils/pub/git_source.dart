// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('git_source');

#import('io.dart');
#import('package.dart');
#import('source.dart');
#import('source_registry.dart');
#import('utils.dart');

/**
 * A package source that installs packages from Git repos.
 */
class GitSource extends Source {
  final String name = "git";

  final bool shouldCache = true;

  GitSource();

  /**
   * Clones a Git repo to the local filesystem.
   *
   * The Git cache directory is a little idiosyncratic. At the top level, it
   * contains a directory for each commit of each repository, named `<package
   * name>-<commit hash>`. These are the canonical package directories that are
   * linked to from the `packages/` directory.
   *
   * In addition, the Git system cache contains a subdirectory named `cache/`
   * which contains a directory for each separate repository URL, named
   * `<package name>-<url hash>`. These are used to check out the repository
   * itself; each of the commit-specific directories are clones of a directory
   * in `cache/`.
   */
  Future<Package> installToSystemCache(PackageId id) {
    var revisionCachePath;

    return isGitInstalled.chain((installed) {
      if (!installed) {
        throw new Exception(
            "Cannot install '${id.name}' from Git (${id.description}).\n"
            "Please ensure Git is correctly installed.");
      }

      return ensureDir(join(systemCacheRoot, 'cache'));
    }).chain((_) => _ensureRepoCache(id))
      .chain((_) => _revisionCachePath(id, "HEAD"))
      .chain((path) {
      revisionCachePath = path;
      return exists(revisionCachePath);
    }).chain((exists) {
      if (exists) return new Future.immediate(null);
      return _clone(_repoCachePath(id), revisionCachePath);
    }).chain((_) => Package.load(revisionCachePath, systemCache.sources));
  }

  /**
   * The package name of a Git repo is the name of the directory into which
   * it'll be cloned.
   */
  String packageName(description) =>
      basename(description).replaceFirst(const RegExp("\.git\$"), "");

  /**
   * Ensures [description] is a Git URL.
   */
  void validateDescription(description) {
    if (description is! String) {
      throw new FormatException("The description must be a git URL.");
    }
  }

  /**
   * Ensure that the canonical clone of the repository referred to by [id] (the
   * one in `<system cache>/git/cache`) exists and is up-to-date. Returns a
   * future that completes once this is finished and throws an exception if it
   * fails.
   */
  Future _ensureRepoCache(PackageId id) {
    var path = _repoCachePath(id);
    return exists(path).chain((exists) {
      if (!exists) return _clone(id.description, path);

      return runProcess("git", ["pull", "--force", "--progress"],
          workingDir: path, pipeStdout: true,
          pipeStderr: true).transform((result) {
        if (!result.success) throw 'Git failed.';
        return null;
      });
    });
  }

  /**
   * Returns a future that completes to the revision hash of the repository for
   * [id] at [ref], which can be any Git ref.
   */
  Future<String> _revisionAt(PackageId id, String ref) {
    return runProcess("git", ["rev-parse", ref],
        workingDir: _repoCachePath(id), pipeStderr: true).transform((result) {
      if (!result.success) throw 'Git failed.';
      return result.stdout[0];
    });
  }

  /**
   * Returns the path to the revision-specific cache of [id] at [ref], which can
   * be any Git ref.
   */
  Future<String> _revisionCachePath(PackageId id, String ref) {
    return _revisionAt(id, ref).transform((rev) {
      var revisionCacheName = '${id.name}-$rev';
      return join(systemCacheRoot, revisionCacheName);
    });
  }

  /**
   * Clones the repo at the URI [from] to the path [to] on the local filesystem.
   */
  Future _clone(String from, String to) {
    return runProcess("git", ["clone", "--progress", from, to],
        pipeStdout: true, pipeStderr: true).transform((result) {
      if (!result.success) throw 'Git failed.';
      return null;
    });
  }

  /**
   * Returns the path to the canonical clone of the repository referred to by
   * [id] (the one in `<system cache>/git/cache`).
   */
  String _repoCachePath(PackageId id) {
    var repoCacheName = '${id.name}-${sha1(id.description)}';
    return join(systemCacheRoot, 'cache', repoCacheName);
  }
}
