// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.source.git;

import 'dart:async';

import 'package:path/path.dart' as path;

import '../git.dart' as git;
import '../io.dart';
import '../log.dart' as log;
import '../package.dart';
import '../pubspec.dart';
import '../utils.dart';
import 'cached.dart';

/// A package source that gets packages from Git repos.
class GitSource extends CachedSource {
  /// Given a valid git package description, returns the URL of the repository
  /// it pulls from.
  static String urlFromDescription(description) => description["url"];

  final name = "git";

  /// The paths to the canonical clones of repositories for which "git fetch"
  /// has already been run during this run of pub.
  final _updatedRepos = new Set<String>();

  /// Given a Git repo that contains a pub package, gets the name of the pub
  /// package.
  Future<String> getPackageNameFromRepo(String repo) {
    // Clone the repo to a temp directory.
    return withTempDir((tempDir) {
      return _clone(repo, tempDir, shallow: true).then((_) {
        var pubspec = new Pubspec.load(tempDir, systemCache.sources);
        return pubspec.name;
      });
    });
  }

  /// Since we don't have an easy way to read from a remote Git repo, this
  /// just installs [id] into the system cache, then describes it from there.
  Future<Pubspec> describeUncached(PackageId id) {
    return downloadToSystemCache(id).then((package) => package.pubspec);
  }

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
  Future<Package> downloadToSystemCache(PackageId id) {
    var revisionCachePath;

    if (!git.isInstalled) {
      fail(
          "Cannot get ${id.name} from Git (${_getUrl(id)}).\n"
              "Please ensure Git is correctly installed.");
    }

    ensureDir(path.join(systemCacheRoot, 'cache'));
    return _ensureRevision(id).then((_) => getDirectory(id)).then((path) {
      revisionCachePath = path;
      if (entryExists(revisionCachePath)) return null;
      return _clone(_repoCachePath(id), revisionCachePath, mirror: false);
    }).then((_) {
      var ref = _getEffectiveRef(id);
      if (ref == 'HEAD') return null;
      return _checkOut(revisionCachePath, ref);
    }).then((_) {
      return new Package.load(id.name, revisionCachePath, systemCache.sources);
    });
  }

  /// Returns the path to the revision-specific cache of [id].
  Future<String> getDirectory(PackageId id) {
    return _ensureRevision(id).then((rev) {
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
      throw new FormatException(
          "The description must be a Git URL or a map " "with a 'url' key.");
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
    return _ensureRevision(id).then((revision) {
      var description = {
        'url': _getUrl(id),
        'ref': _getRef(id)
      };
      description['resolved-ref'] = revision;
      return new PackageId(id.name, name, id.version, description);
    });
  }

  List<Package> getCachedPackages() {
    // TODO(keertip): Implement getCachedPackages().
    throw new UnimplementedError(
        "The git source doesn't support listing its cached packages yet.");
  }

  /// Resets all cached packages back to the pristine state of the Git
  /// repository at the revision they are pinned to.
  Future<Pair<int, int>> repairCachedPackages() {
    final completer0 = new Completer();
    scheduleMicrotask(() {
      try {
        join0() {
          var successes = 0;
          var failures = 0;
          var packages = listDir(systemCacheRoot).where(((entry) {
            return dirExists(path.join(entry, ".git"));
          })).map(((packageDir) {
            return new Package.load(null, packageDir, systemCache.sources);
          })).toList();
          packages.sort(Package.orderByNameAndVersion);
          var it0 = packages.iterator;
          break0() {
            completer0.complete(new Pair(successes, failures));
          }
          var trampoline0;
          continue0() {
            trampoline0 = null;
            if (it0.moveNext()) {
              var package = it0.current;
              log.message(
                  "Resetting Git repository for "
                      "${log.bold(package.name)} ${package.version}...");
              join1() {
                trampoline0 = continue0;
              }
              catch0(error, stackTrace) {
                try {
                  if (error is git.GitException) {
                    log.error(
                        "Failed to reset ${log.bold(package.name)} "
                            "${package.version}. Error:\n${error}");
                    log.fine(stackTrace);
                    failures++;
                    tryDeleteEntry(package.dir);
                    join1();
                  } else {
                    throw error;
                  }
                } catch (error, stackTrace) {
                  completer0.completeError(error, stackTrace);
                }
              }
              try {
                git.run(
                    ["clean", "-d", "--force", "-x"],
                    workingDir: package.dir).then((x0) {
                  trampoline0 = () {
                    trampoline0 = null;
                    try {
                      x0;
                      git.run(
                          ["reset", "--hard", "HEAD"],
                          workingDir: package.dir).then((x1) {
                        trampoline0 = () {
                          trampoline0 = null;
                          try {
                            x1;
                            successes++;
                            join1();
                          } catch (e0, s0) {
                            catch0(e0, s0);
                          }
                        };
                        do trampoline0(); while (trampoline0 != null);
                      }, onError: catch0);
                    } catch (e1, s1) {
                      catch0(e1, s1);
                    }
                  };
                  do trampoline0(); while (trampoline0 != null);
                }, onError: catch0);
              } catch (e2, s2) {
                catch0(e2, s2);
              }
            } else {
              break0();
            }
          }
          trampoline0 = continue0;
          do trampoline0(); while (trampoline0 != null);
        }
        if (!dirExists(systemCacheRoot)) {
          completer0.complete(new Pair(0, 0));
        } else {
          join0();
        }
      } catch (e, s) {
        completer0.completeError(e, s);
      }
    });
    return completer0.future;
  }

  /// Ensure that the canonical clone of the repository referred to by [id] (the
  /// one in `<system cache>/git/cache`) exists and contains the revision
  /// referred to by [id].
  ///
  /// Returns a future that completes to the hash of the revision identified by
  /// [id].
  Future<String> _ensureRevision(PackageId id) {
    return new Future.sync(() {
      var path = _repoCachePath(id);
      if (!entryExists(path)) {
        return _clone(
            _getUrl(id),
            path,
            mirror: true).then((_) => _revParse(id));
      }

      // If [id] didn't come from a lockfile, it may be using a symbolic
      // reference. We want to get the latest version of that reference.
      var description = id.description;
      if (description is! Map || !description.containsKey('resolved-ref')) {
        return _updateRepoCache(id).then((_) => _revParse(id));
      }

      // If [id] did come from a lockfile, then we want to avoid running "git
      // fetch" if possible to avoid networking time and errors. See if the
      // revision exists in the repo cache before updating it.
      return _revParse(id).catchError((error) {
        if (error is! git.GitException) throw error;
        return _updateRepoCache(id).then((_) => _revParse(id));
      });
    });
  }

  /// Runs "git fetch" in the canonical clone of the repository referred to by
  /// [id].
  ///
  /// This assumes that the canonical clone already exists.
  Future _updateRepoCache(PackageId id) {
    var path = _repoCachePath(id);
    if (_updatedRepos.contains(path)) return new Future.value();
    return git.run(["fetch"], workingDir: path).then((_) {
      _updatedRepos.add(path);
    });
  }

  /// Runs "git rev-parse" in the canonical clone of the repository referred to
  /// by [id] on the effective ref of [id].
  ///
  /// This assumes that the canonical clone already exists.
  Future<String> _revParse(PackageId id) {
    return git.run(
        ["rev-parse", _getEffectiveRef(id)],
        workingDir: _repoCachePath(id)).then((result) => result.first);
  }

  /// Clones the repo at the URI [from] to the path [to] on the local
  /// filesystem.
  ///
  /// If [mirror] is true, creates a bare, mirrored clone. This doesn't check
  /// out the working tree, but instead makes the repository a local mirror of
  /// the remote repository. See the manpage for `git clone` for more
  /// information.
  ///
  /// If [shallow] is true, creates a shallow clone that contains no history
  /// for the repository.
  Future _clone(String from, String to, {bool mirror: false, bool shallow:
      false}) {
    return new Future.sync(() {
      // Git on Windows does not seem to automatically create the destination
      // directory.
      ensureDir(to);
      var args = ["clone", from, to];

      if (mirror) args.insert(1, "--mirror");
      if (shallow) args.insertAll(1, ["--depth", "1"]);

      return git.run(args);
    }).then((result) => null);
  }

  /// Checks out the reference [ref] in [repoPath].
  Future _checkOut(String repoPath, String ref) {
    return git.run(
        ["checkout", ref],
        workingDir: repoPath).then((result) => null);
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
