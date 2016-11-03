// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library front_end.file_system;

import 'dart:async';

import 'package:path/path.dart' as path;

/// Abstract interface to file system operations.
///
/// All front end interaction with the file system goes through this interface;
/// this makes it possible for clients to use the front end in a way that
/// doesn't require file system access (e.g. to run unit tests, or to run
/// inside a browser).
///
/// Not intended to be implemented or extended by clients.
abstract class FileSystem {
  /// Returns a path context suitable for use with this [FileSystem].
  path.Context get context;

  /// Returns a [FileSystemEntity] corresponding to the given [path].
  ///
  /// Uses of `..` and `.` in path are normalized before returning (so, for
  /// example, `entityForPath('./foo')` and `entityForPath('foo')` are
  /// equivalent).  Relative paths are also converted to absolute paths.
  ///
  /// Does not check whether a file or folder exists at the given location.
  FileSystemEntity entityForPath(String path);

  /// Returns a [FileSystemEntity] corresponding to the given [uri].
  ///
  /// Uses of `..` and `.` in the URI are normalized before returning.
  ///
  /// If [uri] is not an absolute `file:` URI, an [Error] will be thrown.
  ///
  /// Does not check whether a file or folder exists at the given location.
  FileSystemEntity entityForUri(Uri uri);
}

/// Abstract representation of a file system entity that may or may not exist.
///
/// Instances of this class have suitable implementations of equality tests and
/// hashCode.
///
/// Not intended to be implemented or extended by clients.
abstract class FileSystemEntity {
  /// Returns the absolute normalized path represented by this file system
  /// entity.
  ///
  /// Note: if the [FileSystemEntity] was created using
  /// [FileSystem.entityForPath], this is not necessarily the same as the path
  /// that was used to create the object, since the path might have been
  /// normalized.
  String get path;

  /// Attempts to access this file system entity as a file and read its contents
  /// as raw bytes.
  ///
  /// If an error occurs while attempting to read the file (e.g. because no such
  /// file exists, or the entity is a directory), the future is completed with
  /// an [Exception].
  Future<List<int>> readAsBytes();

  /// Attempts to access this file system entity as a file and read its contents
  /// as a string.
  ///
  /// The file is assumed to be UTF-8 encoded.
  ///
  /// If an error occurs while attempting to read the file (e.g. because no such
  /// file exists, the entity is a directory, or the file is not valid UTF-8),
  /// the future is completed with an [Exception].
  Future<String> readAsString();
}
