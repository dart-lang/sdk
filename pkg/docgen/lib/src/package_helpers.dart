// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.package_helpers;

import '../../../../sdk/lib/_internal/compiler/implementation/mirrors/source_mirrors.dart';

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Helper accessor to determine the full pathname of the root of the dart
/// checkout. We can be in one of three situations:
/// 1) Running from pkg/docgen/bin/docgen.dart
/// 2) Running from a snapshot in a build,
///   e.g. xcodebuild/ReleaseIA32/dart-sdk/bin
/// 3) Running from a built distribution,
///   e.g. ...somename/dart-sdk/bin/snapshots
String get rootDirectory {
  if (_rootDirectoryCache != null) return _rootDirectoryCache;
  var scriptDir = path.absolute(path.dirname(Platform.script.toFilePath()));
  var root = scriptDir;
  var base = path.basename(root);
  // When we find dart-sdk or sdk we are one level below the root.
  while (base != 'dart-sdk' && base != 'sdk' && base != 'pkg') {
    root = path.dirname(root);
    base = path.basename(root);
    if (root == base) {
      // We have reached the root of the filesystem without finding anything.
      throw new FileSystemException("Cannot find SDK directory starting from ",
          scriptDir);
    }
  }
  _rootDirectoryCache = path.dirname(root);
  return _rootDirectoryCache;
}
String _rootDirectoryCache;

/// Given a LibraryMirror that is a library, return the name of the directory
/// holding the package information for that library. If the library is not
/// part of a package, return null.
String getPackageDirectory(LibraryMirror mirror) {
  var file = mirror.uri.toFilePath();
  // Any file that's in a package will be in a directory of the form
  // packagename/lib/.../filename.dart, so we know that a possible
  // package directory is at least in the directory above the one containing
  // [file]
  var directoryAbove = path.dirname(path.dirname(file));
  var possiblePackage = _packageDirectoryFor(directoryAbove);
  // We only want components that are somewhere underneath the lib directory.
  var subPath = path.relative(file, from: possiblePackage);
  var subPathComponents = path.split(subPath);
  if (subPathComponents.isNotEmpty && subPathComponents.first == 'lib') {
    return possiblePackage;
  } else {
    return null;
  }
}

/// Read a pubspec and return the library name, given a directory
String packageNameFor(String directoryName) {
  var pubspecName = path.join(directoryName, 'pubspec.yaml');
  File pubspec = new File(pubspecName);
  if (!pubspec.existsSync()) return '';
  var contents = pubspec.readAsStringSync();
  var spec = loadYaml(contents);
  return spec["name"];
}

/// Recursively walk up from directory name looking for a pubspec. Return
/// the directory that contains it, or null if none is found.
String _packageDirectoryFor(String directoryName) {
  var dir = directoryName;
  while (!_pubspecFor(dir).existsSync()) {
    var newDir = path.dirname(dir);
    if (newDir == dir) return null;
    dir = newDir;
  }
  return dir;
}

File _pubspecFor(String directoryName) =>
    new File(path.join(directoryName, 'pubspec.yaml'));
