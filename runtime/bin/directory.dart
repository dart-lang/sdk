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
  bool exists();

  /**
   * Creates the directory with this name if it does not exist.
   * Throw an exception if the directory already exists.
   */
  void create();

  /**
   * Deletes the directory with this name. Throws an exception
   * if the directory is not empty or if deletion failed.
   */
  void delete();

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
  void setDirHandler(void dirHandler(String dir));

  /**
   * Sets the file handler that is called for all files during listing
   * operations. The file handler is called with the full path of the
   * file.
   */
  void setFileHandler(void fileHandler(String file));

  /**
   * Set the done handler that is called when a directory listing is
   * done. The handler is called with an indication of whether or not
   * the listing operation completed.
   */
  void setDoneHandler(void doneHandler(bool completed));

  /**
   * Sets the error handler that is called on error listing
   * directories.
   */
  void setErrorHandler(void errorHandler(String error));

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
