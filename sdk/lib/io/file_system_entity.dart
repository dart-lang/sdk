// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

class FileSystemEntityType {
  static const FILE = const FileSystemEntityType._internal(0);
  static const DIRECTORY = const FileSystemEntityType._internal(1);
  static const LINK = const FileSystemEntityType._internal(2);
  static const NOT_FOUND = const FileSystemEntityType._internal(3);
  static const _typeList = const [FileSystemEntityType.FILE,
                                  FileSystemEntityType.DIRECTORY,
                                  FileSystemEntityType.LINK,
                                  FileSystemEntityType.NOT_FOUND];
  const FileSystemEntityType._internal(int this._type);

  static FileSystemEntityType _lookup(int type) => _typeList[type];
  String toString() => const ['FILE', 'DIRECTORY', 'LINK', 'NOT_FOUND'][_type];

  final int _type;
}

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

  external static int _getType(String path, bool followLinks);
  external static bool _identical(String path1, String path2);

  static int _getTypeSync(String path, bool followLinks) {
    var result = _getType(path, followLinks);
    _throwIfError(result, 'Error getting type of FileSystemEntity');
    return result;
  }

  /**
   * Do two paths refer to the same object in the file system?
   * Links are not identical to their targets, and two links
   * are not identical just because they point to identical targets.
   * Links in intermediate directories in the paths are followed, though.
   *
   * Throws an error if one of the paths points to an object that does not
   * exist.
   * The target of a link can be compared by first getting it with Link.target.
   */
  static bool identicalSync(String path1, String path2) {
    var result = _identical(path1, path2);
    _throwIfError(result, 'Error in FileSystemEntity.identical');
    return result;
  }

  static FileSystemEntityType typeSync(String path, {bool followLinks: true})
      => FileSystemEntityType._lookup(_getTypeSync(path, followLinks));

  static bool isLinkSync(String path) =>
      (_getTypeSync(path, false) == FileSystemEntityType.LINK._type);

  static bool isFileSync(String path) =>
      (_getTypeSync(path, true) == FileSystemEntityType.FILE._type);

  static bool isDirectorySync(String path) =>
      (_getTypeSync(path, true) == FileSystemEntityType.DIRECTORY._type);

  static _throwIfError(Object result, String msg) {
    if (result is OSError) {
      throw new FileIOException(msg, result);
    } else if (result is ArgumentError) {
      throw result;
    }
  }
}
