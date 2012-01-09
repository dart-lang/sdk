// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * FileMode describes the modes in which a file can be opened.
 */
class FileMode {
  static final READ = const FileMode(0);
  static final WRITE = const FileMode(1);
  static final APPEND = const FileMode(2);
  const FileMode(int this.mode);
  final int mode;
}

interface File default _File {
  /**
   * Create a File object.
   */
  File(String name);

  /**
   * Check if the file exists. The [existsHandler] is called with the
   * result when the operation completes.
   */
  void exists();

  /**
   * Synchronously check if the file exists.
   */
  bool existsSync();

  /**
   * Create the file. The [createHandler] is called when the file has
   * been created. The errorHandler is called if the file cannot be
   * created. Existing files are left untouched by create. Calling
   * create on an existing file might fail if there are restrictive
   * permissions on the file.
   */
  void create();

  /**
   * Synchronously create the file. Existing files are left untouched
   * by create. Calling create on an existing file might fail if there
   * are restrictive permissions on the file.
   */
  void createSync();

  /**
   * Delete the file. The [deleteHandler] is called when the file has
   * been successfully deleted. The [errorHandler] is called if the
   * file cannot be deleted.
   */
  void delete();

  /**
   * Synchronously delete the file.
   */
  void deleteSync();

  /**
   * Open the file for random access operations. When the file is
   * opened the [openHandler] is called with the resulting
   * RandomAccessFile. RandomAccessFiles must be closed using the
   * [close] method. If the file cannot be opened the [errorHandler]
   * is called.
   *
   * Files can be opened in three modes:
   *
   * FileMode.READ: open the file for reading. If the file does not
   * exist the [errorHandler] is called.
   *
   * FileMode.WRITE: open the file for both reading and writing and
   * truncate the file to length zero. If the file does not exist the
   * file is created.
   *
   * FileMode.APPEND: same as FileMode.WRITE except that the file is
   * not truncated.
   *
   * By default mode is FileMode.READ.
   */
  void open([FileMode mode]);

  /**
   * Synchronously open the file for random access operations. The
   * result is a RandomAccessFile on which random access operations
   * can be performed. Opened RandomAccessFiles must be closed using
   * the [close] method.
   *
   * Files can be opened in three modes:
   *
   * FileMode.READ: open the file for reading. If the file does not
   * exist the [errorHandler] is called.
   *
   * FileMode.WRITE: open the file for both reading and writing and
   * truncate the file to length zero. If the file does not exist the
   * file is created.
   *
   * FileMode.APPEND: same as FileMode.WRITE except that the file is
   * not truncated.
   *
   * By default mode is FileMode.READ.
   */
  RandomAccessFile openSync([FileMode mode]);

  /**
   * Get the canonical full path corresponding to the file name. The
   * [fullPathHandler] is called with the result when the fullPath
   * operation completes.
   */
  void fullPath();

  /**
   * Synchronously get the canonical full path corresponding to the file name.
   */
  String fullPathSync();

  /**
   * Create a new independent input stream for the file. The file
   * input stream must be closed when no longer used to free up
   * system resources.
   */
  InputStream openInputStream();

  /**
   * Creates a new independent output stream for the file. The file
   * output stream must be closed when no longer used to free up
   * system resources.
   */
  OutputStream openOutputStream();

  /**
   * Get the name of the file.
   */
  String get name();

  // Event handlers.
  void set existsHandler(void handler(bool exists));
  void set createHandler(void handler());
  void set deleteHandler(void handler());
  void set openHandler(void handler(RandomAccessFile openedFile));
  void set fullPathHandler(void handler(String path));
  void set errorHandler(void handler(String error));
}


interface RandomAccessFile {
  /**
   * Close the file. When the file is closed the closeHandler is
   * called.
   */
  void close();

  /**
   * Synchronously close the file.
   */
  void closeSync();

  /**
   * Read a byte from the file. When the byte has been read the
   * [readByteHandler] is called with the value.
   */
  void readByte();

  /**
   * Synchronously read a single byte from the file.
   */
  int readByteSync();

  /**
   * Read a List<int> from the file. When the list has been read the
   * [readListHandler] is called with an integer indicating how much
   * was read.
   */
  void readList(List<int> buffer, int offset, int bytes);

  /**
   * Synchronously read a List<int> from the file. Returns the number
   * of bytes read.
   */
  int readListSync(List<int> buffer, int offset, int bytes);

  /**
   * Write a single byte to the file. If the byte cannot be written
   * the [errorHandler] is called. When all pending write operations
   * have finished the [noPendingWriteHandler] is called.
   */
  void writeByte(int value);

  /**
   * Synchronously write a single byte to the file. Returns the
   * number of bytes successfully written.
   */
  int writeByteSync(int value);

  /**
   * Write a List<int> to the file. If the list cannot be written the
   * [errorHandler] is called. When all pending write operations have
   * finished the [noPendingWriteHandler] is called.
   */
  void writeList(List<int> buffer, int offset, int bytes);

  /**
   * Synchronously write a List<int> to the file. Returns the number
   * of bytes successfully written.
   */
  int writeListSync(List<int> buffer, int offset, int bytes);

  /**
   * Write a string to the file. If the string cannot be written the
   * [errorHandler] is called. When all pending write operations have
   * finished the [noPendingWriteHandler] is called.
   */
  // TODO(ager): writeString should take an encoding.
  void writeString(String string);

  /**
   * Synchronously write a single string to the file. Returns the number
   * of characters successfully written.
   */
  // TODO(ager): writeStringSync should take an encoding.
  int writeStringSync(String string);

  /**
   * Get the current byte position in the file. When the operation
   * completes the [positionHandler] is called with the position.
   */
  void position();

  /**
   * Synchronously get the current byte position in the file.
   */
  int positionSync();

  /**
   * Set the byte position in the file. When the operation completes
   * the [setPositionHandler] is called.
   */
  void setPosition(int position);

  /**
   * Synchronously set the byte position in the file.
   */
  void setPositionSync(int position);

  /**
   * Truncate (or extend) the file to [length] bytes. When the
   * operation completes successfully the [truncateHandler] is called.
   */
  void truncate(int length);

  /**
   * Synchronously truncate (or extend) the file to [length] bytes.
   */
  void truncateSync(int length);

  /**
   * Get the length of the file. When the operation completes the
   * [lengthHandler] is called with the length.
   */
  void length();

  /**
   * Synchronously get the length of the file.
   */
  int lengthSync();

  /**
   * Flush the contents of the file to disk. The [flushHandler] is
   * called when the flush operation completes.
   */
   void flush();

  /**
   * Synchronously flush the contents of the file to disk.
   */
  void flushSync();

  /**
   * Get the name of the file.
   */
  String get name();

  void set closeHandler(void handler());
  void set readByteHandler(void handler(int byte));
  void set readListHandler(void handler(int read));
  void set noPendingWriteHandler(void handler());
  void set positionHandler(void handler(int position));
  void set setPositionHandler(void handler());
  void set truncateHandler(void handler());
  void set lengthHandler(void handler(int length));
  void set flushHandler(void handler());
  void set errorHandler(void handler(String error));
}


class FileIOException implements Exception {
  const FileIOException([String this.message = ""]);
  String toString() => "FileIOException: $message";
  final String message;
}
