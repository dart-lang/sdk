// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * A [FileSystemEntity] is a common super class for [File] and
 * [Directory] objects.
 *
 * [FileSystemEntity] objects are returned from directory listing
 * operations. To determine if a FileSystemEntity is a [File] or a
 * [Directory], perform a type check:
 *
 *     if (entity is File) (entity as File).readAsStringSync();
 */
abstract class FileSystemEntity {
  String get path;
}
