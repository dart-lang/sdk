// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * [Directory] objects are used for working with directories.
 */
interface Directory default _Directory {
  /**
   * Creates a directory object. The path is either a full path or
   * relative to the directory in which the Dart VM was
   * started.
   */
  Directory(String path);

  /**
   * Creates a directory object pointing to the current working
   * directory.
   */
  Directory.current();

  /**
   * Check whether a directory with this name already exists. If the
   * operation completes successfully the callback is called with the
   * result. Otherwise [onError] is called.
   */
  void exists(void callback(bool exists));

  /**
   * Synchronously check whether a directory with this name already exists.
   */
  bool existsSync();

  /**
   * Creates the directory with this name if it does not exist.  If
   * the directory is successfully created the callback is
   * called. Otherwise [onError] is called.
   */
  void create(void callback());

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
   * The path is modified to be the path of the new directory.  After
   * the new directory is created, and the path modified, the callback
   * will be called.  The error handler is called if the temporary
   * directory cannot be created.
   */
  void createTemp(void callback());

  /**
   * Synchronously creates a temporary directory with a name based on the
   * current path. This name and path is used as a template, and additional
   * characters are appended to it by the call to make a unique directory name.
   * If the path is the empty string, a default system temp directory and name
   * are used for the template.
   * The path is modified to be the path of the new directory.
   */
  void createTempSync();

  /**
   * Deletes the directory with this name. The directory must be
   * empty. If the operation completes successfully the callback is
   * called. Otherwise [onError] is called.
   */
  void delete(void callback());

  /**
   * Deletes this directory and all sub-directories and files in the
   * directories. If the operation completes successfully the callback
   * is called. Otherwise [onError] is called.
   */
  void deleteRecursively(void callback());

  /**
   * Synchronously deletes the directory with this name. The directory
   * must be empty. Throws an exception if the directory cannot be
   * deleted.
   */
  void deleteSync();

  /**
   * Synchronously deletes this directory and all sub-directories and
   * files in the directories. Throws an exception if the directory
   * cannot be deleted.
   */
  void deleteRecursivelySync();

  /**
   * List the sub-directories and files of this
   * [Directory]. Optionally recurse into sub-directories. For each
   * file and directory, the file or directory handler is called. When
   * all directories have been listed the done handler is called. If
   * the listing operation is recursive, the error handler is called
   * if a subdirectory cannot be opened for listing.
   */
  // TODO(ager): Should we change this to return an event emitting
  // DirectoryLister object. Alternatively, pass in one callback that
  // gets called with an indication of whether what it is called with
  // is a file, a directory or an indication that the listing is over.
  void list([bool recursive]);

  /**
   * Sets the directory handler that is called for all directories
   * during listing operations. The directory handler is called with
   * the full path of the directory.
   */
  void set onDir(void onDir(String dir));

  /**
   * Sets the handler that is called for all files during listing
   * operations. The file handler is called with the full path of the
   * file.
   */
  void set onFile(void onFile(String file));

  /**
   * Set the handler that is called when a directory listing is
   * done. The handler is called with an indication of whether or not
   * the listing operation completed.
   */
  void set onDone(void onDone(bool completed));

  /**
   * Sets the handler that is called if there is an error while listing
   * or creating directories.
   */
  void set onError(void onError(e));

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
