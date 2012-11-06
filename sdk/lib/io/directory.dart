// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * [Directory] objects are used for working with directories.
 */
abstract class Directory {
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
   * path.  This name and path is used as a template, and additional
   * characters are appended to it by the call to make a unique
   * directory name.  If the path is the empty string, a default
   * system temp directory and name are used for the template.
   *
   * Returns a [:Future<Directory>:] that completes with the newly
   * created temporary directory.
   */
  Future<Directory> createTemp();

  /**
   * Synchronously creates a temporary directory with a name based on the
   * current path. This name and path is used as a template, and additional
   * characters are appended to it by the call to make a unique directory name.
   * If the path is the empty string, a default system temp directory and name
   * are used for the template. Returns the newly created temporary directory.
   */
  Directory createTempSync();

  /**
   * Deletes the directory with this name.
   *
   * If [recursive] is false, the directory must be empty.
   *
   * If [recursive] is true, this directory and all sub-directories
   * and files in the directories are deleted.
   *
   * Returns a [:Future<Directory>:] that completes with this
   * directory when the deletion is done. If the directory cannot be
   * deleted, the future completes with an exception.
   */
  Future<Directory> delete({recursive: false});

  /**
   * Synchronously deletes the directory with this name.
   *
   * If [recursive] is false, the directory must be empty.
   *
   * If [recursive] is true, this directory and all sub-directories
   * and files in the directories are deleted.
   *
   * Throws an exception if the directory cannot be deleted.
   */
  void deleteSync({recursive: false});

  /**
   * Rename this directory. Returns a [:Future<Directory>:] that completes
   * with a [Directory] instance for the renamed directory.
   *
   * If newPath identifies an existing directory, that directory is
   * replaced. If newPath identifies an existing file the operation
   * fails and the future completes with an exception.
   */
  Future<Directory> rename(String newPath);

  /**
   * Synchronously rename this directory. Returns a [Directory]
   * instance for the renamed directory.
   *
   * If newPath identifies an existing directory, that directory is
   * replaced. If newPath identifies an existing file the operation
   * fails and an exception is thrown.
   */
  Directory renameSync(String newPath);

  /**
   * List the sub-directories and files of this
   * [Directory]. Optionally recurse into sub-directories. Returns a
   * [DirectoryLister] object representing the active listing
   * operation. Handlers for files and directories should be
   * registered on this DirectoryLister object.
   */
  DirectoryLister list({bool recursive: false});

  /**
   * Gets the path of this directory.
   */
  final String path;
}


/**
 * A [DirectoryLister] represents an actively running listing operation.
 *
 * A [DirectoryLister] is obtained from a [Directory] object by calling
 * the [:Directory.list:] method.
 *
 *     Directory dir = new Directory('path/to/my/dir');
 *     DirectoryLister lister = dir.list();
 *
 * For each file and directory, the file or directory handler is
 * called. When all directories have been listed the done handler is
 * called. If the listing operation is recursive, the error handler is
 * called if a subdirectory cannot be opened for listing.
 */
abstract class DirectoryLister {
  /**
   * Sets the directory handler that is called for all directories
   * during listing. The directory handler is called with the full
   * path of the directory.
   */
  void set onDir(void onDir(String dir));

  /**
   * Sets the handler that is called for all files during listing. The
   * file handler is called with the full path of the file.
   */
  void set onFile(void onFile(String file));

  /**
   * Set the handler that is called when a listing is done. The
   * handler is called with an indication of whether or not the
   * listing operation completed.
   */
  void set onDone(void onDone(bool completed));

  /**
   * Sets the handler that is called if there is an error while
   * listing directories.
   */
  void set onError(void onError(e));
}


class DirectoryIOException implements Exception {
  const DirectoryIOException([String this.message = "",
                              String this.path = "",
                              OSError this.osError = null]);
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.add("DirectoryIOException");
    if (!message.isEmpty) {
      sb.add(": $message");
      if (path != null) {
        sb.add(", path = $path");
      }
      if (osError != null) {
        sb.add(" ($osError)");
      }
    } else if (osError != null) {
      sb.add(": $osError");
      if (path != null) {
        sb.add(", path = $path");
      }
    }
    return sb.toString();
  }
  final String message;
  final String path;
  final OSError osError;
}
