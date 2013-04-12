// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * [Directory] objects are used for working with directories.
 */
abstract class Directory extends FileSystemEntity {
  /**
   * Creates a directory object. The path is either an absolute path,
   * or it is a relative path which is interpreted relative to the directory
   * in which the Dart VM was started.
   */
  factory Directory(String path) => new _Directory(path);

  /**
   * Creates a directory object from a Path object. The path is either
   * an absolute path, or it is a relative path which is interpreted
   * relative to the directory in which the Dart VM was started.
   */
  factory Directory.fromPath(Path path) => new _Directory.fromPath(path);

  /**
   * Creates a directory object pointing to the current working
   * directory.
   */
  factory Directory.current() => new _Directory.current();

  /**
   * Check whether a directory with this name already exists. Returns
   * a [:Future<bool>:] that completes with the result.
   */
  Future<bool> exists();

  /**
   * Synchronously check whether a directory with this name already exists.
   */
  bool existsSync();

  /**
   * Creates the directory with this name.
   *
   * If [recursive] is false, only the last directory in the path is
   * created. If [recursive] is true, all non-existing path components
   * are created. If the directory already exists nothing is done.
   *
   * Returns a [:Future<Directory>:] that completes with this
   * directory once it has been created. If the directory cannot be
   * created the future completes with an exception.
   */
  Future<Directory> create({recursive: false});

  /**
   * Synchronously creates the directory with this name.
   *
   * If [recursive] is false, only the last directory in the path is
   * created. If [recursive] is true, all non-existing path components
   * are created. If the directory already exists nothing is done.
   *
   * If the directory cannot be created an exception is thrown.
   */
  void createSync({recursive: false});

  /**
   * Creates a temporary directory with a name based on the current
   * path.  The path is used as a template, and additional
   * characters are appended to it to make a unique temporary
   * directory name.  If the path is the empty string, a default
   * system temp directory and name are used for the template.
   *
   * Returns a [:Future<Directory>:] that completes with the newly
   * created temporary directory.
   */
  Future<Directory> createTemp();

  /**
   * Synchronously creates a temporary directory with a name based on the
   * current path. The path is used as a template, and additional
   * characters are appended to it to make a unique temporary directory name.
   * If the path is the empty string, a default system temp directory and name
   * are used for the template. Returns the newly created temporary directory.
   */
  Directory createTempSync();

  /**
   * Deletes this directory.
   *
   * If [recursive] is false, the directory must be empty.  Only directories
   * and links to directories will be deleted.
   *
   * If [recursive] is true, this directory and all sub-directories
   * and files in the directories are deleted. Links are not followed
   * when deleting recursively. Only the link is deleted, not its target.
   *
   * If [recursive] is true, the target is deleted even if it is a file, or
   * a link to a file, not only if it is a directory.  This behavior allows
   * [delete] to be used to unconditionally delete any file system object.
   *
   * Returns a [:Future<Directory>:] that completes with this
   * directory when the deletion is done. If the directory cannot be
   * deleted, the future completes with an exception.
   */
  Future<Directory> delete({recursive: false});

  /**
   * Synchronously deletes this directory.
   *
   * If [recursive] is false, the directory must be empty.
   *
   * If [recursive] is true, this directory and all sub-directories
   * and files in the directories are deleted. Links are not followed
   * when deleting recursively. Only the link is deleted, not its target.
   *
   * If [recursive] is true, the target is deleted even if it is a file, or
   * a link to a file, not only if it is a directory.  This behavior allows
   * [delete] to be used to unconditionally delete any file system object.
   *
   * Throws an exception if the directory cannot be deleted.
   */
  void deleteSync({recursive: false});

  /**
   * Renames this directory. Returns a [:Future<Directory>:] that completes
   * with a [Directory] instance for the renamed directory.
   *
   * If newPath identifies an existing directory, that directory is
   * replaced. If newPath identifies an existing file, the operation
   * fails and the future completes with an exception.
   */
  Future<Directory> rename(String newPath);

  /**
   * Synchronously renames this directory. Returns a [Directory]
   * instance for the renamed directory.
   *
   * If newPath identifies an existing directory, that directory is
   * replaced. If newPath identifies an existing file the operation
   * fails and an exception is thrown.
   */
  Directory renameSync(String newPath);

  /**
   * Lists the sub-directories and files of this [Directory].
   * Optionally recurses into sub-directories.
   *
   * If [followLinks] is false, then any symbolic links found
   * are reported as [Link] objects, rather than as directories or files,
   * and are not recursed into.
   *
   * If [followLinks] is true, then working links are reported as
   * directories or files, depending on
   * their type, and links to directories are recursed into.
   * Broken links are reported as [Link] objects.
   * If a symbolic link makes a loop in the file system, then a recursive
   * listing will not follow a link twice in the
   * same recursive descent, but will report it as a [Link]
   * the second time it is seen.
   *
   * The result is a stream of [FileSystemEntity] objects
   * for the directories, files, and links.
   */
  Stream<FileSystemEntity> list({bool recursive: false,
                                 bool followLinks: true});

  /**
   * Lists the sub-directories and files of this [Directory].
   * Optionally recurses into sub-directories.
   *
   * If [followLinks] is false, then any symbolic links found
   * are reported as [Link] objects, rather than as directories or files,
   * and are not recursed into.
   *
   * If [followLinks] is true, then working links are reported as
   * directories or files, depending on
   * their type, and links to directories are recursed into.
   * Broken links are reported as [Link] objects.
   * If a link makes a loop in the file system, then a recursive
   * listing will not follow a link twice in the
   * same recursive descent, but will report it as a [Link]
   * the second time it is seen.
   *
   * Returns a [List] containing [FileSystemEntity] objects for the
   * directories, files, and links.
   */
  List<FileSystemEntity> listSync({bool recursive: false,
                                   bool followLinks: true});

  /**
   * Returns a human readable string for this Directory instance.
   */
  String toString();

  /**
   * Gets the path of this directory.
   */
  final String path;
}


class DirectoryIOException implements Exception {
  const DirectoryIOException([String this.message = "",
                              String this.path = "",
                              OSError this.osError = null]);
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("DirectoryIOException");
    if (!message.isEmpty) {
      sb.write(": $message");
      if (path != null) {
        sb.write(", path = $path");
      }
      if (osError != null) {
        sb.write(" ($osError)");
      }
    } else if (osError != null) {
      sb.write(": $osError");
      if (path != null) {
        sb.write(", path = $path");
      }
    }
    return sb.toString();
  }
  final String message;
  final String path;
  final OSError osError;
}
