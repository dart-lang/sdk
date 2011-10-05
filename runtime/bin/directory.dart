// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Directory factory DirectoryImpl {
  /**
   * Creates a directory object. The path is either a full path or
   * relative to the directory in which the Dart VM was
   * started. Throws an exception if the path does not specify a
   * directory.
   */
  Directory.open(String dir);

  /**
   * Close this [Directory]. Terminates listing operation if one is in
   * progress. Returns a boolean indicating whether the close operation
   * succeeded.
   */
  bool close();

  /**
   * List the sub-directories and files of this
   * [Directory]. Optionally recurse into sub-directories. For each
   * file and directory, the file or directory handler is called. When
   * all directories have been listed the done handler is called. If
   * the listing operation is recursive, the directory error handler
   * is called if a subdirectory cannot be opened for listing.
   */
  void list([bool recursive]);

  /**
   * Sets the directory handler that is called for all directories
   * during listing operations. The directory handler is called with
   * the full path of the directory.
   */
  void setDirHandler(void dirHandler(String dir));

  /**
   * Sets the file handler that is called for all directories during
   * listing operations. The directory handler is called with the full
   * path of the file.
   */
  void setFileHandler(void fileHandler(String file));

  /**
   * Set the done handler that is called either when a directory
   * listing is completed or when the close method is called.
   */
  void setDoneHandler(void doneHandler(bool completed));

  /**
   * Set the directory error handler that is called for all
   * directories that cannot be opened for listing during recursive
   * listing.
   */
  void setDirErrorHandler(void errorHandler(String dir));
}
