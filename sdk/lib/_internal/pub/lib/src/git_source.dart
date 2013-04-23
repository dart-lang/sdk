// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library git_source;

import 'dart:async';

import 'package:pathos/path.dart' as path;

import 'git.dart' as git;
import 'io.dart';
import 'log.dart' as log;
import 'package.dart';
import 'source.dart';
import 'source_registry.dart';
import 'utils.dart';

/// A package source that installs packages from Git repos.
class GitSource extends Source {
  final String name = "git";

  final bool shouldCache = true;

  GitSource();

  /// Clones a Git repo to the local filesystem.
  ///
  /// The Git cache directory is a little idiosyncratic. At the top level, it
  /// contains a directory for each commit of each repository, named `<package
  /// name>-<commit hash>`. These are the canonical package directories that are
  /// linked to from the `packages/` directory.
  ///
  /// In addition, the Git system cache contains a subdirectory named `cache/`
  /// which contains a directory for each separate repository URL, named
  /// `<package name>-<url hash>`. These are used to check out the repository
  /// itself; each of the commit-specific directories are clones of a directory
  /// in `cache/`.
  Future<Package> installToSystemCache(PackageId id) {
    var revisionCachePath;

    return git.isInstalled.then((installed) {
      if (!installed) {
        throw new Exception(
            "Cannot install '${id.name}' from Git (${_getUrl(id)}).\n"
            "Please ensure Git is correctly installed.");
      }

      ensureDir(path.join(systemCacheRoot, 'cache'));
      return _ensureRepoCache(id);
    }).then((_) => systemCacheDirectory(id)).then((path) {
      revisionCachePath = path;
      if (entryExists(revisionCachePath)) return;
      return _clone(_repoCachePath(id), revisionCachePath, mirror: false);
    }).then((_) {
      var ref = _getEffectiveRef(id);
      if (ref == 'HEAD') return;
      return _checkOut(revisionCachePath, ref);
    }).then((_) {
      return new Package.load(id.name, revisionCachePath, systemCache.sources);
    });
  }

  /// Returns the path to the revision-specific cache of [id].
  Future<String> systemCacheDirectory(PackageId id) {
    return _revisionAt(id).then((rev) {
      var revisionCacheName = '${id.name}-$rev';
      return path.join(systemCacheRoot, revisionCacheName);
    });
  }

  /// Ensures [description] is a Git URL.
  dynamic parseDescription(String containingPath, description,
                           {bool fromLockFile: false}) {
    // TODO(rnystrom): Handle git URLs that are relative file paths (#8570).
    // TODO(rnystrom): Now that this function can modify the description, it
    // may as well canonicalize it to a map so that other code in the source
    // can assume that.
    // A single string is assumed to be a Git URL.
    if (description is String) return description;
    if (description is! Map || !description.containsKey('url')) {
      throw new FormatException("The description must be a Git URL or a map "
          "with a 'url' key.");
    }

    var parsed = new Map.from(description);
    parsed.remove('url');
    parsed.remove('ref');
    if (fromLockFile) parsed.remove('resolved-ref');

    if (!parsed.isEmpty) {
      var plural = parsed.length > 1;
      var keys = parsed.keys.join(', ');
      throw new FormatException("Invalid key${plural ? 's' : ''}: $keys.");
    }

    return description;
  }

  /// Two Git descriptions are equal if both their URLs and their refs are
  /// equal.
  bool descriptionsEqual(description1, description2) {
    // TODO(nweiz): Do we really want to throw an error if you have two
    // dependencies on some repo, one of which specifies a ref and one of which
    // doesn't? If not, how do we handle that case in the version solver?
    return _getUrl(description1) == _getUrl(description2) &&
      _getRef(description1) == _getRef(description2);
  }

  /// Attaches a specific commit to [id] to disambiguate it.
  Future<PackageId> resolveId(PackageId id) {
    return _revisionAt(id).then((revision) {
      var description = {'url': _getUrl(id), 'ref': _getRef(id)};
      description['resolved-ref'] = revision;
      return new PackageId(id.name, this, id.version, description);
    });
  }

  // TODO(keertip): Implement getCachedPackages().
  
  /// Ensure that the canonical clone of the repository referred to by [id] (the
  /// one in `<system cache>/git/cache`) exists and is up-to-date. Returns a
  /// future that completes once this is finished and throws an exception if it
  /// fails.
  Future _ensureRepoCache(PackageId id) {
    return new Future.sync(() {
      var path = _repoCachePath(id);
      if (!entryExists(path)) return _clone(_getUrl(id), path, mirror: true);
      return git.run(["fetch"], workingDir: path).then((result) => null);
    });
  }

  /// Returns a future that completes to the revision hash of [id].
  Future<String> _revisionAt(PackageId id) {
    return git.run(["rev-parse", _getEffectiveRef(id)],
        workingDir: _repoCachePath(id)).then((result) => result[0]);
  }

  /// Clones the repo at the URI [from] to the path [to] on the local
  /// filesystem.
  ///
  /// If [mirror] is true, create a bare, mirrored clone. This doesn't check out
  /// the working tree, but instead makes the repository a local mirror of the
  /// remote repository. See the manpage for `git clone` for more information.
  Future _clone(String from, String to, {bool mirror: false}) {
    return new Future.sync(() {
      // Git on Windows does not seem to automatically create the destination
      // directory.
      ensureDir(to);
      var args = ["clone", from, to];
      if (mirror) args.insert(1, "--mirror");
      return git.run(args);
    }).then((result) => null);
  }

  /// Checks out the reference [ref] in [repoPath].
  Future _checkOut(String repoPath, String ref) {
    return git.run(["checkout", ref], workingDir: repoPath).then(
        (result) => null);
  }

  /// Returns the path to the canonical clone of the repository referred to by
  /// [id] (the one in `<system cache>/git/cache`).
  String _repoCachePath(PackageId id) {
    var repoCacheName = '${id.name}-${sha1(_getUrl(id))}';
    return path.join(systemCacheRoot, 'cache', repoCacheName);
  }

  /// Returns the repository URL for [id].
  ///
  /// [description] may be a description or a [PackageId].
  String _getUrl(description) {
    description = _getDescription(description);
    if (description is String) return description;
    return description['url'];
  }

  /// Returns the commit ref that should be checked out for [description].
  ///
  /// This differs from [_getRef] in that it doesn't just return the ref in
  /// [description]. It will return a sensible default if that ref doesn't
  /// exist, and it will respect the "resolved-ref" parameter set by
  /// [resolveId].
  ///
  /// [description] may be a description or a [PackageId].
  String _getEffectiveRef(description) {
    description = _getDescription(description);
    if (description is Map && description.containsKey('resolved-ref')) {
      return description['resolved-ref'];
    }

    var ref = _getRef(description);
    return ref == null ? 'HEAD' : ref;
  }

  /// Returns the commit ref for [description], or null if none is given.
  ///
  /// [description] may be a description or a [PackageId].
  String _getRef(description) {
    description = _getDescription(description);
    if (description is String) return null;
    return description['ref'];
  }

  /// Returns [description] if it's a description, or [PackageId.description] if
  /// it's a [PackageId].
  _getDescription(description) {
    if (description is PackageId) return description.description;
    return description;
  }
}
