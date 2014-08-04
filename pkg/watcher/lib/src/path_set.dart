// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library watcher.path_dart;

import 'dart:collection';

import 'package:path/path.dart' as p;

/// A set of paths, organized into a directory hierarchy.
///
/// When a path is [add]ed, it creates an implicit directory structure above
/// that path. Directories can be inspected using [containsDir] and removed
/// using [remove]. If they're removed, their contents are removed as well.
///
/// The paths in the set are normalized so that they all begin with [root].
class PathSet {
  /// The root path, which all paths in the set must be under.
  final String root;

  /// The path set's directory hierarchy.
  ///
  /// Each level of this hierarchy has the same structure: a map from strings to
  /// other maps, which are further levels of the hierarchy. A map with no
  /// elements indicates a path that was added to the set that has no paths
  /// beneath it. Such a path should not be treated as a directory by
  /// [containsDir].
  final _entries = new Map<String, Map>();

  /// The set of paths that were explicitly added to this set.
  ///
  /// This is needed to disambiguate a directory that was explicitly added to
  /// the set from a directory that was implicitly added by adding a path
  /// beneath it.
  final _paths = new Set<String>();

  PathSet(this.root);

  /// Adds [path] to the set.
  void add(String path) {
    path = _normalize(path);
    _paths.add(path);

    var parts = _split(path);
    var dir = _entries;
    for (var part in parts) {
      dir = dir.putIfAbsent(part, () => {});
    }
  }

  /// Removes [path] and any paths beneath it from the set and returns the
  /// removed paths.
  ///
  /// Even if [path] itself isn't in the set, if it's a directory containing
  /// paths that are in the set those paths will be removed and returned.
  ///
  /// If neither [path] nor any paths beneath it are in the set, returns an
  /// empty set.
  Set<String> remove(String path) {
    path = _normalize(path);
    var parts = new Queue.from(_split(path));

    // Remove the children of [dir], as well as [dir] itself if necessary.
    //
    // [partialPath] is the path to [dir], and a prefix of [path]; the remaining
    // components of [path] are in [parts].
    recurse(dir, partialPath) {
      if (parts.length > 1) {
        // If there's more than one component left in [path], recurse down to
        // the next level.
        var part = parts.removeFirst();
        var entry = dir[part];
        if (entry == null || entry.isEmpty) return new Set();

        partialPath = p.join(partialPath, part);
        var paths = recurse(entry, partialPath);
        // After removing this entry's children, if it has no more children and
        // it's not in the set in its own right, remove it as well.
        if (entry.isEmpty && !_paths.contains(partialPath)) dir.remove(part);
        return paths;
      }

      // If there's only one component left in [path], we should remove it.
      var entry = dir.remove(parts.first);
      if (entry == null) return new Set();

      if (entry.isEmpty) {
        _paths.remove(path);
        return new Set.from([path]);
      }

      var set = _removePathsIn(entry, path);
      if (_paths.contains(path)) {
        _paths.remove(path);
        set.add(path);
      }
      return set;
    }

    return recurse(_entries, root);
  }

  /// Recursively removes and returns all paths in [dir].
  ///
  /// [root] should be the path to [dir].
  Set<String> _removePathsIn(Map dir, String root) {
    var removedPaths = new Set();
    recurse(dir, path) {
      dir.forEach((name, entry) {
        var entryPath = p.join(path, name);
        if (_paths.remove(entryPath)) removedPaths.add(entryPath);
        recurse(entry, entryPath);
      });
    }

    recurse(dir, root);
    return removedPaths;
  }

  /// Returns whether [this] contains [path].
  ///
  /// This only returns true for paths explicitly added to [this].
  /// Implicitly-added directories can be inspected using [containsDir].
  bool contains(String path) => _paths.contains(_normalize(path));

  /// Returns whether [this] contains paths beneath [path].
  bool containsDir(String path) {
    path = _normalize(path);
    var dir = _entries;

    for (var part in _split(path)) {
      dir = dir[part];
      if (dir == null) return false;
    }

    return !dir.isEmpty;
  }

  /// Returns a [Set] of all paths in [this].
  Set<String> toSet() => _paths.toSet();

  /// Removes all paths from [this].
  void clear() {
    _paths.clear();
    _entries.clear();
  }

  String toString() => _paths.toString();

  /// Returns a normalized version of [path].
  ///
  /// This removes any extra ".." or "."s and ensure that the returned path
  /// begins with [root]. It's an error if [path] isn't within [root].
  String _normalize(String path) {
    var relative = p.relative(p.normalize(path), from: root);
    var parts = p.split(relative);
    // TODO(nweiz): replace this with [p.isWithin] when that exists (issue
    // 14980).
    if (!p.isRelative(relative) || parts.first == '..' || parts.first == '.') {
      throw new ArgumentError('Path "$path" is not inside "$root".');
    }
    return p.join(root, relative);
  }

  /// Returns the segments of [path] beneath [root].
  List<String> _split(String path) => p.split(p.relative(path, from: root));
}
