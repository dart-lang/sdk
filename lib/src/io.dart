// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.io;

import 'dart:io';

import 'package:glob/glob.dart';
import 'package:linter/src/pub.dart';
import 'package:linter/src/util.dart';
import 'package:path/path.dart' as p;

final dartMatcher = new Glob('**.dart');

/// Shared IO sink for standard error reporting.
/// Visible for testing
IOSink errorSink = stderr;

/// Shared IO sink for standard out reporting.
/// Visible for testing
IOSink outSink = stdout;

/// Cached project package.
String _projectPackageName;

/// Cached project root.
String _projectRoot;

/// Collect all lintable files, recursively, under this [path] root, ignoring
/// links.
Iterable<File> collectFiles(String path) {
  List<File> files = [];

  var file = new File(path);
  if (file.existsSync()) {
    files.add(file);
  } else {
    var directory = new Directory(path);
    if (directory.existsSync()) {
      for (var entry
          in directory.listSync(recursive: true, followLinks: false)) {
        var relative = p.relative(entry.path, from: directory.path);

        if (isLintable(entry) && !isInHiddenDir(relative)) {
          files.add(entry);
        }
      }
    }
  }

  return files;
}

/// Calculates the project package name based on a pubspec found relative to
/// the given path.  In case a pubspec is not found, default to the project
/// root directory name.
/// Note that the name will be calculated just once.  After the first call,
/// the argument is ignored and the cached result returned.
String getProjectPackageName(String path) {
  if (_projectPackageName == null) {
    _projectPackageName = _calculateProjectPackageName(path);
  }
  return _projectPackageName;
}

/// Calculates the absolute path to the project root based on the given path
/// (which is assumed to be a file path in the project).
/// Note that the root will be calculated just once.  After the first call,
/// the argument is ignored and the cached result returned.
String getProjectRoot(String path) {
  if (_projectRoot == null) {
    _projectRoot = _calculateProjectRoot(path);
  }
  return _projectRoot;
}

/// Returns `true` if this [entry] is a Dart file.
bool isDartFile(FileSystemEntity entry) => isDartFileName(entry.path);

/// Returns `true` if this relative path is a hidden directory.
bool isInHiddenDir(String relative) =>
    p.split(relative).any((part) => part.startsWith("."));

/// Returns `true` if this relative path is a hidden directory.
bool isLintable(FileSystemEntity file) =>
    file is File && (isDartFile(file) || isPubspecFile(file));

/// Returns `true` if this [entry] is a pubspec file.
bool isPubspecFile(FileSystemEntity entry) =>
    isPubspecFileName(p.basename(entry.path));

/// Synchronously read the contents of the file at the given [path] as a string.
String readFile(String path) => new File(path).readAsStringSync();

String _calculateProjectPackageName(String path) {
  var pubspec = _findPubspecFileRelativeTo(path);
  if (pubspec != null) {
    var spec =
        new Pubspec.parse(pubspec.readAsStringSync(), sourceUrl: pubspec.path);
    var nameEntry = spec.name;
    if (nameEntry != null) {
      var value = nameEntry.value.text;
      if (value != null) {
        return value;
      }
    }
  }
  // Fall back
  return p.basename(Directory.current.path);
}

String _calculateProjectRoot(String path) {
  var pubspec = _findPubspecFileRelativeTo(path);
  var dir = pubspec != null ? pubspec.parent : Directory.current;
  return dir.absolute.path;
}

File _findPubspecFileRelativeTo(String path) {
  var file = new File(path);
  if (file.existsSync()) {
    if (isPubspecFile(file)) {
      return file;
    }
  } else {
    var directory = new Directory(path);
    if (directory.existsSync()) {
      for (var file
          in directory.listSync(recursive: true, followLinks: false)) {
        if (isPubspecFile(file)) {
          return file;
        }
      }
    }
  }
  return null;
}
