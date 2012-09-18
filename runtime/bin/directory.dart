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
   * Creates the directory with this name if it does not
   * exist. Returns a [:Future<Directory>:] that completes with this
   * directory once it has been created.
   */
  Future<Directory> create();

  /**
   * Synchronously creates the directory with this name if it does not exist.
   * Throws an exception if the directory already exists.
   */
  void createSync();

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
   * Deletes the directory with this name. The directory must be
   * empty. Returns a [:Future<Directory>:] that completes with
   * this directory when the deletion is done.
   */
  Future<Directory> delete();

  /**
   * Synchronously deletes the directory with this name. The directory
   * must be empty. Throws an exception if the directory cannot be
   * deleted.
   */
  void deleteSync();

  /**
   * Deletes this directory and all sub-directories and files in the
   * directories. Returns a [:Future<Directory>:] that completes with
   * this directory when the deletion is done.
   */
  Future<Directory> deleteRecursively();

  /**
   * Synchronously deletes this directory and all sub-directories and
   * files in the directories. Throws an exception if the directory
   * cannot be deleted.
   */
  void deleteRecursivelySync();

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
  DirectoryLister list([bool recursive = false]);

  /**
   * Gets the path of this directory.
   */
  final String path;
}


/**
 * A [DirectoryLister] represents an actively running listing operation.
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
    if (!message.isEmpty()) {
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
