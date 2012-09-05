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
            "Cannot install '${id.name}' from Git (${_getUrl(id)}).\n"
            "Please ensure Git is correctly installed.");
      }

      return ensureDir(join(systemCacheRoot, 'cache'));
    }).chain((_) => _ensureRepoCache(id))
      .chain((_) => _revisionCachePath(id))
      .chain((path) {
      revisionCachePath = path;
      return exists(revisionCachePath);
    }).chain((exists) {
      if (exists) return new Future.immediate(null);
      return _clone(_repoCachePath(id), revisionCachePath, mirror: false);
    }).chain((_) {
      var ref = _getEffectiveRef(id);
      if (ref == 'HEAD') return new Future.immediate(null);
      return _checkOut(revisionCachePath, ref);
    }).chain((_) => Package.load(revisionCachePath, systemCache.sources));
  }

  /**
   * The package name of a Git repo is the name of the directory into which
   * it'll be cloned.
   */
  String packageName(description) {
    return basename(_getUrl(description)
        .replaceFirst(const RegExp(@"(\.git)?/?$"), ""));
  }

  /**
   * Ensures [description] is a Git URL.
   */
  void validateDescription(description, [bool fromLockFile = false]) {
    // A single string is assumed to be a Git URL.
    if (description is String) return;
    if (description is! Map || !description.containsKey('url')) {
      throw new FormatException("The description must be a Git URL or a map "
          "with a 'url' key.");
    }
    description = new Map.from(description);
    description.remove('url');
    description.remove('ref');
    if (fromLockFile) description.remove('resolved-ref');

    if (!description.isEmpty()) {
      var plural = description.length > 1;
      var keys = Strings.join(description.getKeys(), ', ');
      throw new FormatException("Invalid key${plural ? 's' : ''}: $keys.");
    }
  }

  /**
   * Two Git descriptions are equal if both their URLs and their refs are equal.
   */
  bool descriptionsEqual(description1, description2) {
    // TODO(nweiz): Do we really want to throw an error if you have two
    // dependencies on some repo, one of which specifies a ref and one of which
    // doesn't? If not, how do we handle that case in the version solver?
    return _getUrl(description1) == _getUrl(description2) &&
      _getRef(description1) == _getRef(description2);
  }

  /**
   * Attaches a specific commit to [id] to disambiguate it.
   */
  Future<PackageId> resolveId(PackageId id) {
    return _revisionAt(id).transform((revision) {
      var description = {'url': _getUrl(id), 'ref': _getRef(id)};
      description['resolved-ref'] = revision;
      return new PackageId(this, id.version, description);
    });
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
      if (!exists) return _clone(_getUrl(id), path, mirror: true);

      return runProcess("git", ["fetch"], workingDir: path)
          .transform((result) {
        if (!result.success) throw 'Git failed.';
        return null;
      });
    });
  }

  /**
   * Returns a future that completes to the revision hash of [id].
   */
  Future<String> _revisionAt(PackageId id) {
    return runProcess("git", ["rev-parse", _getEffectiveRef(id)],
        workingDir: _repoCachePath(id)).transform((result) {
      if (!result.success) throw 'Git failed.';
      return result.stdout[0];
    });
  }

  /**
   * Returns the path to the revision-specific cache of [id].
   */
  Future<String> _revisionCachePath(PackageId id) {
    return _revisionAt(id).transform((rev) {
      var revisionCacheName = '${id.name}-$rev';
      return join(systemCacheRoot, revisionCacheName);
    });
  }

  /**
   * Clones the repo at the URI [from] to the path [to] on the local filesystem.
   *
   * If [mirror] is true, create a bare, mirrored clone. This doesn't check out
   * the working tree, but instead makes the repository a local mirror of the
   * remote repository. See the manpage for `git clone` for more information.
   */
  Future _clone(String from, String to, [bool mirror=false]) {
    var args = ["clone", from, to];
    if (mirror) args.insertRange(1, 1, "--mirror");
    return runProcess("git", args).transform((result) {
      if (!result.success) throw 'Git failed.';
      return null;
    });
  }

  /**
   * Checks out the reference [ref] in [repoPath].
   */
  Future _checkOut(String repoPath, String ref) {
    return runProcess("git", ["checkout", ref], workingDir: repoPath)
        .transform((result) {
      if (!result.success) throw 'Git failed.';
      return null;
    });
  }

  /**
   * Returns the path to the canonical clone of the repository referred to by
   * [id] (the one in `<system cache>/git/cache`).
   */
  String _repoCachePath(PackageId id) {
    var repoCacheName = '${id.name}-${sha1(_getUrl(id))}';
    return join(systemCacheRoot, 'cache', repoCacheName);
  }

  /**
   * Returns the repository URL for [id].
   *
   * [description] may be a description or a [PackageId].
   */
  String _getUrl(description) {
    description = _getDescription(description);
    if (description is String) return description;
    return description['url'];
  }

  /**
   * Returns the commit ref that should be checked out for [description].
   *
   * This differs from [_getRef] in that it doesn't just return the ref in
   * [description]. It will return a sensible default if that ref doesn't exist,
   * and it will respect the "resolved-ref" parameter set by [resolveId].
   *
   * [description] may be a description or a [PackageId].
   */
  String _getEffectiveRef(description) {
    description = _getDescription(description);
    if (description is Map && description.containsKey('resolved-ref')) {
      return description['resolved-ref'];
    }

    var ref = _getRef(description);
    return ref == null ? 'HEAD' : ref;
  }

  /**
   * Returns the commit ref for [description], or null if none is given.
   *
   * [description] may be a description or a [PackageId].
   */
  String _getRef(description) {
    description = _getDescription(description);
    if (description is String) return null;
    return description['ref'];
  }

  /**
   * Returns [description] if it's a description, or [PackageId.description] if
   * it's a [PackageId].
   */
  _getDescription(description) {
    if (description is PackageId) return description.description;
    return description;
  }
}
