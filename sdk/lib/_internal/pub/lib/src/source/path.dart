// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.source.path;

import 'dart:async';

import 'package:path/path.dart' as path;

import '../io.dart';
import '../package.dart';
import '../pubspec.dart';
import '../source.dart';
import '../utils.dart';

/// A package [Source] that gets packages from a given local file path.
class PathSource extends Source {
  final name = 'path';

  Future<Pubspec> doDescribe(PackageId id) {
    return syncFuture(() {
      var dir = _validatePath(id.name, id.description);
      return new Pubspec.load(dir, systemCache.sources,
          expectedName: id.name);
    });
  }

  bool descriptionsEqual(description1, description2) {
    // Compare real paths after normalizing and resolving symlinks.
    var path1 = canonicalize(description1["path"]);
    var path2 = canonicalize(description2["path"]);
    return path1 == path2;
  }

  /// Create a symlink from the source path directly to the destination
  /// directory.
  Future get(PackageId id, String destination) {
    return syncFuture(() {
      var dir = _validatePath(id.name, id.description);
      createPackageSymlink(id.name, dir, destination,
          relative: id.description["relative"]);
    });
  }

  Future<String> getDirectory(PackageId id) =>
      newFuture(() => _validatePath(id.name, id.description));

  /// Parses a path dependency.
  ///
  /// This takes in a path string and returns a map. The "path" key will be the
  /// original path but resolved relative to the containing path. The
  /// "relative" key will be `true` if the original path was relative.
  ///
  /// A path coming from a pubspec is a simple string. From a lock file, it's
  /// an expanded {"path": ..., "relative": ...} map.
  dynamic parseDescription(String containingPath, description,
                           {bool fromLockFile: false}) {
    if (fromLockFile) {
      if (description is! Map) {
        throw new FormatException("The description must be a map.");
      }

      if (description["path"] is! String) {
        throw new FormatException("The 'path' field of the description must "
            "be a string.");
      }

      if (description["relative"] is! bool) {
        throw new FormatException("The 'relative' field of the description "
            "must be a boolean.");
      }

      return description;
    }

    if (description is! String) {
      throw new FormatException("The description must be a path string.");
    }

    // Resolve the path relative to the containing file path, and remember
    // whether the original path was relative or absolute.
    bool isRelative = path.isRelative(description);
    if (path.isRelative(description)) {
      // Can't handle relative paths coming from pubspecs that are not on the
      // local file system.
      assert(containingPath != null);

      description = path.normalize(
          path.join(path.dirname(containingPath), description));
    }

    return {
      "path": description,
      "relative": isRelative
    };
  }

  /// Serializes path dependency's [description].
  ///
  /// For the descriptions where `relative` attribute is `true`, tries to make
  /// `path` relative to the specified [containingPath].
  dynamic serializeDescription(String containingPath, description) {
    if (description["relative"]) {
      return {
        "path": path.relative(description['path'], from: containingPath),
        "relative": true
      };
    }
    return description;
  }

  /// Converts a parsed relative path to its original relative form.
  String formatDescription(String containingPath, description) {
    var sourcePath = description["path"];
    if (description["relative"]) {
      sourcePath = path.relative(description['path'], from: containingPath);
    }

    return sourcePath;
  }

  /// Ensures that [description] is a valid path description and returns a
  /// normalized path to the package.
  ///
  /// It must be a map, with a "path" key containing a path that points to an
  /// existing directory. Throws an [ApplicationException] if the path is
  /// invalid.
  String _validatePath(String name, description) {
    var dir = description["path"];

    if (dirExists(dir)) return dir;

    if (fileExists(dir)) {
      fail('Path dependency for package $name must refer to a directory, '
           'not a file. Was "$dir".');
    }

    throw new PackageNotFoundException(
        'Could not find package $name at "$dir".');
  }
}
