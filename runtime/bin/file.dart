// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface File factory _File {
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
   * created.
   */
  void create();

  /**
   * Synchronously create the file.
   */
  void createSync();

  /**
   * Open the file for random access operations. When the file is
   * opened the openHandler is called. Opened files must be closed
   * using the [close] method. By default writable is false.
   */
  void open([bool writable]);

  /**
   * Synchronously open the file for random access operations. Opened
   * files must be closed using the [close] method. By default
   * writable is false.
   */
  void openSync([bool writable]);

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
   * Synchronously write a single byte to the file. Returns true if
   * the byte was successfully written and false otherwise.
   */
  bool writeByteSync(int value);

  /**
   * Write a List<int> to the file. If the list cannot be written the
   * [errorHandler] is called. When all pending write operations have
   * finished the [noPendingWriteHandler] is called.
   */
  void writeList(List<int> buffer, int offset, int bytes);

  /**
   * Synchronously write a List<int> to the file. Returns true if the
   * list was successfully written and false otherwise.
   */
  bool writeListSync(List<int> buffer, int offset, int bytes);

  /**
   * Write a string to the file. If the string cannot be written the
   * [errorHandler] is called. When all pending write operations have
   * finished the [noPendingWriteHandler] is called.
   */
  // TODO(ager): writeString should take an encoding.
  void writeString(String string);

  /**
   * Synchronously write a single string to the file. Returns true if
   * the string was successfully written and false otherwise.
   */
  // TODO(ager): writeStringSync should take an encoding.
  bool writeStringSync(String string);

  /**
   * Get the current position of the file. When the operation
   * completes the [positionHandler] is called with the position.
   */
  void position();

  /**
   * Synchronously get the current position of the file.
   */
  int positionSync();

  /**
   * Get the length of the file. When the operation completes the
   * [lengthHandler] is called with the length.
   */
  void length();

  /**
   * Get the length of the file. When the operation completes the
   * [lengthHandler] is called with the length.
   */
  int lengthSync();

  /**
   * Flush the contents of the file to disk. If there are no pending
   * write operation after the flush operation completes, the
   * [noPendingWriteHandler] is called.
   */
   void flush();

  /**
   * Synchronously flush the contents of the file to disk.
   */
  void flushSync();

  /**
   * Create a new independent input stream for the file. The file
   * input stream must be closed when no longer used.
   */
  FileInputStream openInputStream();

  /**
   * Creates a new independent output stream for the file. The file
   * output stream must be closed when no longer used.
   */
  FileOutputStream openOutputStream();

  /**
   * Get the name of the file.
   */
  String get name();

  // Event handlers.
  void set existsHandler(void handler(bool exists));
  void set createHandler(void handler());
  void set openHandler(void handler());
  void set closeHandler(void handler());
  void set readByteHandler(void handler(int byte));
  void set readListHandler(void handler(int read));
  void set noPendingWriteHandler(void handler());
  void set errorHandler(void handler(String error));
}


interface FileInputStream extends InputStream {
  void close();
}


interface FileOutputStream extends OutputStream {
}


class FileIOException implements Exception {
  const FileIOException([String this.message = ""]);
  String toString() => "FileIOException: $message";
  final String message;
}
