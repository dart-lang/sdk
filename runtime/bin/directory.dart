// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Directory factory _Directory {
  /**
   * Creates a directory object. The path is either a full path or
   * relative to the directory in which the Dart VM was
   * started.
   */
  Directory(String path);

  /**
   * Returns whether a directory with this name already exists.
   */
  bool existsSync();

  /**
   * Creates the directory with this name if it does not exist.
   * Throw an exception if the directory already exists.
   */
  void createSync();

  /**
   * Creates a temporary directory with a name based on the current path.
   * This name and path is used as a template, and additional characters are
   * appended to it by the call to make a unique directory name.  If the
   * path is the empty string, a default system temp directory and name
   * are used for the template.
   * The path is modified to be the path of the new directory.
   * After the new directory is created, and the path modified, the callback
   * createTempHandler will be called.  The error handler is called if
   * the temporary directory cannot be created.
   */
  void createTemp();

  /**
   * Synchronously creates a temporary directory with a name based on the current path.
   * This name and path is used as a template, and additional characters are
   * appended to it by the call to make a unique directory name.  If the
   * path is the empty string, a default system temp directory and name
   * are used for the template.
   * The path is modified to be the path of the new directory.
   */
  void createTempSync();

  /**
   * Deletes the directory with this name. Throws an exception
   * if the directory is not empty or if deletion failed.
   */
  void deleteSync();

  /**
   * List the sub-directories and files of this
   * [Directory]. Optionally recurse into sub-directories. For each
   * file and directory, the file or directory handler is called. When
   * all directories have been listed the done handler is called. If
   * the listing operation is recursive, the error handler is called
   * if a subdirectory cannot be opened for listing.
   */
  void list([bool recursive]);

  /**
   * Sets the directory handler that is called for all directories
   * during listing operations. The directory handler is called with
   * the full path of the directory.
   */
  void set dirHandler(void dirHandler(String dir));

  /**
   * Sets the handler that is called for all files during listing
   * operations. The file handler is called with the full path of the
   * file.
   */
  void set fileHandler(void fileHandler(String file));

  /**
   * Set the handler that is called when a directory listing is
   * done. The handler is called with an indication of whether or not
   * the listing operation completed.
   */
  void set doneHandler(void doneHandler(bool completed));

  /**
   * Set the handler that is called when a temporary directory is
   * successfully created.
   */
  void set createTempHandler(void doneHandler(bool completed));

  /**
   * Sets the handler that is called if there is an error while listing
   * or creating directories.
   */
  void set errorHandler(void errorHandler(String error));

  /**
   * Gets the path of this directory.
   */
  final String path;
}


class DirectoryException {
  const DirectoryException(String this.message);
  String toString() => "DirectoryException: $message";
  final String message;
}
