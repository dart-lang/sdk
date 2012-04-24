// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * FileMode describes the modes in which a file can be opened.
 */
class FileMode {
  static final READ = const FileMode._internal(0);
  static final WRITE = const FileMode._internal(1);
  static final APPEND = const FileMode._internal(2);
  const FileMode._internal(int this._mode);
  final int _mode;
}


/**
 * [File] objects are references to files.
 *
 * To operate on the underlying file data you need to either get
 * streams using [openInputStream] and [openOutputStream] or open the
 * file for random access operations using [open].
 */
interface File default _File {
  /**
   * Create a File object.
   */
  File(String name);

  /**
   * Check if the file exists. The callback is called with the result
   * when the operation completes. The [onError] function registered
   * on the file object is called if an error occurs.
   */
  void exists(void callback(bool exists));

  /**
   * Synchronously check if the file exists.
   */
  bool existsSync();

  /**
   * Create the file. The callback is called when the file has been
   * created. The [onError] function registered on the file object is
   * called if the file cannot be created. Existing files are left
   * untouched by create. Calling create on an existing file might
   * fail if there are restrictive permissions on the file.
   */
  void create(void callback());

  /**
   * Synchronously create the file. Existing files are left untouched
   * by create. Calling create on an existing file might fail if there
   * are restrictive permissions on the file.
   */
  void createSync();

  /**
   * Delete the file. The callback is called when the file has been
   * successfully deleted. The [onError] function registered on the
   * file object is called if the file cannot be deleted.
   */
  void delete(void callback());

  /**
   * Synchronously delete the file.
   */
  void deleteSync();

  /**
   * Get a Directory object for the directory containing this
   * file. When the operation completes the callback is called with
   * the result. If the file does not exist the [onError] function
   * registered on the file object is called.
   */
  void directory(void callback(Directory dir));

  /**
   * Synchronously get a Directory object for the directory containing
   * this file.
   */
  Directory directorySync();

  /**
   * Get the length of the file. When the operation completes the
   * callback is called with the length.
   */
  void length(void callback(int length));

  /**
   * Synchronously get the length of the file.
   */
  int lengthSync();

  /**
   * Open the file for random access operations. When the file is
   * opened the callback is called with the resulting
   * RandomAccessFile. RandomAccessFiles must be closed using the
   * [close] method. If the file cannot be opened [onError] is called.
   *
   * Files can be opened in three modes:
   *
   * FileMode.READ: open the file for reading. If the file does not
   * exist [onError] is called.
   *
   * FileMode.WRITE: open the file for both reading and writing and
   * truncate the file to length zero. If the file does not exist the
   * file is created.
   *
   * FileMode.APPEND: same as FileMode.WRITE except that the file is
   * not truncated.
   */
  void open(FileMode mode, void callback(RandomAccessFile opened));

  /**
   * Synchronously open the file for random access operations. The
   * result is a RandomAccessFile on which random access operations
   * can be performed. Opened RandomAccessFiles must be closed using
   * the [close] method.
   *
   * The default value for [mode] is [:FileMode.READ:].
   *
   * See [open] for information on the [mode] argument.
   */
  RandomAccessFile openSync([FileMode mode]);

  /**
   * Get the canonical full path corresponding to the file name.  The
   * callback is called with the result when the
   * fullPath operation completes. If the operation fails the
   * [onError] function registered on the file object is called.
   */
  void fullPath(void callback(String path));

  /**
   * Synchronously get the canonical full path corresponding to the file name.
   */
  String fullPathSync();

  /**
   * Create a new independent input stream for the file. The file
   * input stream must be closed when no longer used to free up system
   * resources.
   */
  InputStream openInputStream();

  /**
   * Creates a new independent output stream for the file. The file
   * output stream must be closed when no longer used to free up
   * system resources.
   *
   * An output stream can be opened in two modes:
   *
   * FileMode.WRITE: create the stream and truncate the underlying
   * file to length zero.
   *
   * FileMode.APPEND: create the stream and set the position to the end of
   * the underlying file.
   *
   * By default the mode is FileMode.WRITE.
   */
  OutputStream openOutputStream([FileMode mode]);

  /**
   * Read the entire file contents as a list of bytes. When the
   * operation completes the callback is called. The [onError]
   * function registered on the file object is called if the operation
   * fails.
   */
  void readAsBytes(void callback(List<int> bytes));

  /**
   * Synchronously read the entire file contents as a list of bytes.
   */
  List<int> readAsBytesSync();

  /**
   * Read the entire file contents as text using the given
   * [encoding]. The default encoding is UTF-8 - [:Encoding.UTF_8:].
   *
   * When the operation completes the callback is called. The
   * [onError] function registered on the file object is called if the
   * operation fails.
   */
  void readAsText(Encoding encoding, void callback(String text));

  /**
   * Synchronously read the entire file contents as text using the
   * given [encoding]. The default encoding is UTF-8 - [:Encoding.UTF_8:].
   */
  String readAsTextSync([Encoding encoding]);

  /**
   * Read the entire file contents as lines of text using the give
   * [encoding]. The default encoding is UTF-8 - [:Encoding.UTF_8:].
   *
   * When the operation completes the callback is called. The
   * [onError] function registered on the file object is called if the
   * operation fails.
   */
  void readAsLines(Encoding encoding, void callback(List<String> lines));

  /**
   * Synchronously read the entire file contents as lines of text
   * using the given [encoding] The default encoding is UTF-8 -
   * [:Encoding.UTF_8:].
   */
  List<String> readAsLinesSync([Encoding encoding]);

  /**
   * Get the name of the file.
   */
  String get name();

  /**
   * Sets the handler that gets called when errors occur during
   * operations on this file.
   */
  void set onError(void handler(Exception e));
}


/**
 * [RandomAccessFile] provides random access to the data in a
 * file. [RandomAccessFile] objects are obtained by calling the
 * [:open:] method on a [File] object.
 */
interface RandomAccessFile {
  /**
   * Close the file. When the file is closed the callback is called.
   */
  void close(void callback());

  /**
   * Synchronously close the file.
   */
  void closeSync();

  /**
   * Read a byte from the file. When the byte has been read the
   * callback is called with the value. If end of file has been
   * reached the value will be -1.
   */
  void readByte(void callback(int byte));

  /**
   * Synchronously read a single byte from the file. If end of file
   * has been reached -1 is returned.
   */
  int readByteSync();

  /**
   * Read a List<int> from the file. When the list has been read the
   * callback is called with an integer indicating how much was read.
   */
  void readList(List<int> buffer, int offset, int bytes,
                void callback(int read));

  /**
   * Synchronously read a List<int> from the file. Returns the number
   * of bytes read.
   */
  int readListSync(List<int> buffer, int offset, int bytes);

  /**
   * Write a single byte to the file. If the byte cannot be written
   * [onError] is called. When all pending write operations have
   * finished [onNoPendingWrites] is called.
   */
  void writeByte(int value);

  /**
   * Synchronously write a single byte to the file. Returns the
   * number of bytes successfully written.
   */
  int writeByteSync(int value);

  /**
   * Write a List<int> to the file. If the list cannot be written the
   * [onError] is called. When all pending write operations have
   * finished [onNoPendingWrites] is called.
   */
  void writeList(List<int> buffer, int offset, int bytes);

  /**
   * Synchronously write a List<int> to the file. Returns the number
   * of bytes successfully written.
   */
  int writeListSync(List<int> buffer, int offset, int bytes);

  /**
   * Write a string to the file using the given [encoding]. If the
   * string cannot be written [onError] is called. The default
   * encoding is UTF-8 - [:Encoding.UTF_8:].
   *
   * When all pending write operations have finished
   * [onNoPendingWrites] is called.
   */
  void writeString(String string, [Encoding encoding]);

  /**
   * Synchronously write a single string to the file using the given
   * [encoding]. Returns the number of characters successfully
   * written. The default encoding is UTF-8 - [:Encoding.UTF_8:].
   */
  int writeStringSync(String string, [Encoding encoding]);

  /**
   * Get the current byte position in the file. When the operation
   * completes the callback is called with the position.
   */
  void position(void callback(int position));

  /**
   * Synchronously get the current byte position in the file.
   */
  int positionSync();

  /**
   * Set the byte position in the file. When the operation completes
   * the callback is called.
   */
  void setPosition(int position, void callback());

  /**
   * Synchronously set the byte position in the file.
   */
  void setPositionSync(int position);

  /**
   * Truncate (or extend) the file to [length] bytes. When the
   * operation completes successfully the callback is called.
   */
  void truncate(int length, void callback());

  /**
   * Synchronously truncate (or extend) the file to [length] bytes.
   */
  void truncateSync(int length);

  /**
   * Get the length of the file. When the operation completes the
   * callback is called with the length.
   */
  void length(void callback(int length));

  /**
   * Synchronously get the length of the file.
   */
  int lengthSync();

  /**
   * Flush the contents of the file to disk. The callback is
   * called when the flush operation completes.
   */
  void flush(void callback());

  /**
   * Synchronously flush the contents of the file to disk.
   */
  void flushSync();

  /**
   * Get the name of the file.
   */
  String get name();

  /**
   * Sets the handler that gets called when there are no more write
   * operations pending for this file.
   */
  void set onNoPendingWrites(void handler());

  /**
   * Sets the handler that gets called when errors occur when
   * operating on this file.
   */
  void set onError(void handler(Exception e));
}


class FileIOException implements Exception {
  const FileIOException([String this.message = "",
                         OSError this.osError = null]);
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.add("FileIOException");
    if (!message.isEmpty()) {
      sb.add(": $message");
      if (osError != null) {
        sb.add(" ($osError)");
      }
    } else if (osError != null) {
      sb.add(": osError");
    }
    return sb.toString();
  }
  final String message;
  final OSError osError;
}
