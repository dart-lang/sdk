// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library path_source;

import 'dart:async';
import 'dart:io';

import '../../pkg/path/lib/path.dart' as path;

import 'io.dart';
import 'package.dart';
import 'pubspec.dart';
import 'version.dart';
import 'source.dart';
import 'utils.dart';

// TODO(rnystrom): Support relative paths. (See comment in _validatePath().)
/// A package [Source] that installs packages from a given local file path.
class PathSource extends Source {
  final name = 'path';
  final shouldCache = false;

  Future<Pubspec> describe(PackageId id) {
    return defer(() {
      _validatePath(id.name, id.description);
      return new Pubspec.load(id.name, id.description, systemCache.sources);
    });
  }

  Future<bool> install(PackageId id, String path) {
    return defer(() {
      try {
        _validatePath(id.name, id.description);
      } on FormatException catch(err) {
        return false;
      }
      return createPackageSymlink(id.name, id.description, path);
    }).then((_) => true);
  }

  void validateDescription(description, {bool fromLockFile: false}) {
    if (description is! String) {
      throw new FormatException("The description must be a path string.");
    }
  }

  /// Ensures that [dir] is a valid path. It must be an absolute path that
  /// points to an existing directory. Throws a [FormatException] if the path
  /// is invalid.
  void _validatePath(String name, String dir) {
    // Relative paths are not (currently) allowed because the user would expect
    // them to be relative to the pubspec where the dependency appears. That in
    // turn means that two pubspecs in different locations with the same
    // relative path dependency could refer to two different packages. That
    // violates pub's rule that a description should uniquely identify a
    // package.
    //
    // At some point, we may want to loosen this, but it will mean tracking
    // where a given PackageId appeared.
    if (!path.isAbsolute(dir)) {
      throw new FormatException(
          "Path dependency for package '$name' must be an absolute path. "
          "Was '$dir'.");
    }

    if (fileExists(dir)) {
      throw new FormatException(
          "Path dependency for package '$name' must refer to a "
          "directory, not a file. Was '$dir'.");
    }

    if (!dirExists(dir)) {
      throw new FormatException("Could not find package '$name' at '$dir'.");
    }
  }
}