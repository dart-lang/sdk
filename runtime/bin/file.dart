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
   * Check if the file exists. Does not block and returns a
   * [:Future<bool>:].
   */
  Future<bool> exists();

  /**
   * Synchronously check if the file exists.
   */
  bool existsSync();

  /**
   * Create the file. Returns a [:Future<File>:] that completes with
   * the file when it has been created.
   *
   * Existing files are left untouched by create. Calling create on an
   * existing file might fail if there are restrictive permissions on
   * the file.
   */
  Future<File> create();

  /**
   * Synchronously create the file. Existing files are left untouched
   * by create. Calling create on an existing file might fail if there
   * are restrictive permissions on the file.
   */
  void createSync();

  /**
   * Delete the file. Returns a [:Future<File>:] that completes with
   * the file when it has been deleted.
   */
  Future<File> delete();

  /**
   * Synchronously delete the file.
   */
  void deleteSync();

  /**
   * Get a Directory object for the directory containing this
   * file. Returns a [:Future<Directory>:] that completes with the
   * directory.
   */
  Future<Directory> directory();

  /**
   * Synchronously get a Directory object for the directory containing
   * this file.
   */
  Directory directorySync();

  /**
   * Get the length of the file. Returns a [:Future<int>:] that
   * completes with the length in bytes.
   */
  Future<int> length();

  /**
   * Synchronously get the length of the file.
   */
  int lengthSync();

  /**
   * Get the last-modified time of the file. Returns a
   * [:Future<Date>:] that completes with a [Date] object for the
   * modification date.
   */
  Future<Date> lastModified();

  /**
   * Get the last-modified time of the file. Throws an exception
   * if the file does not exist.
   */
  Date lastModifiedSync();

  /**
   * Open the file for random access operations. Returns a
   * [:Future<RandomAccessFile>:] that completes with the opened
   * random access file. RandomAccessFiles must be closed using the
   * [close] method.
   *
   * Files can be opened in three modes:
   *
   * FileMode.READ: open the file for reading.
   *
   * FileMode.WRITE: open the file for both reading and writing and
   * truncate the file to length zero. If the file does not exist the
   * file is created.
   *
   * FileMode.APPEND: same as FileMode.WRITE except that the file is
   * not truncated.
   *
   * The default value for [mode] is [:FileMode.READ:].
   */
  Future<RandomAccessFile> open([FileMode mode]);

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
   * Get the canonical full path corresponding to the file name.
   * Returns a [:Future<String>:] that completes with the path.
   */
  Future<String> fullPath();

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
   * Read the entire file contents as a list of bytes. Returns a
   * [:Future<List<int>>:] that completes with the list of bytes that
   * is the contents of the file.
   */
  Future<List<int>> readAsBytes();

  /**
   * Synchronously read the entire file contents as a list of bytes.
   */
  List<int> readAsBytesSync();

  /**
   * Read the entire file contents as text using the given
   * [encoding]. The default encoding is [:Encoding.UTF_8:].
   *
   * Returns a [:Future<String>:] that completes with the string once
   * the file contents has been read.
   */
  Future<String> readAsText([Encoding encoding]);

  /**
   * Synchronously read the entire file contents as text using the
   * given [encoding]. The default encoding is [:Encoding.UTF_8:].
   */
  String readAsTextSync([Encoding encoding]);

  /**
   * Read the entire file contents as lines of text using the give
   * [encoding]. The default encoding is [:Encoding.UTF_8:].
   *
   * Returns a [:Future<List<String>>:] that completes with the lines
   * once the file contents has been read.
   */
  Future<List<String>> readAsLines([Encoding encoding]);

  /**
   * Synchronously read the entire file contents as lines of text
   * using the given [encoding] The default encoding is
   * [:Encoding.UTF_8:].
   */
  List<String> readAsLinesSync([Encoding encoding]);

  /**
   * Get the name of the file.
   */
  String get name();
}


/**
 * [RandomAccessFile] provides random access to the data in a
 * file. [RandomAccessFile] objects are obtained by calling the
 * [:open:] method on a [File] object.
 */
interface RandomAccessFile {
  /**
   * Close the file. Returns a [:Future<RandomAccessFile>:] that
   * completes with this RandomAccessFile when it has been closed.
   */
  Future<RandomAccessFile> close();

  /**
   * Synchronously close the file.
   */
  void closeSync();

  /**
   * Read a byte from the file. Returns a [:Future<int>:] that
   * completes with the byte or -1 if end of file has been reached.
   */
  Future<int> readByte();

  /**
   * Synchronously read a single byte from the file. If end of file
   * has been reached -1 is returned.
   */
  int readByteSync();

  /**
   * Read a List<int> from the file. Returns a [:Future<int>:] that
   * completes with an indication of how much was read.
   */
  Future<int> readList(List<int> buffer, int offset, int bytes);

  /**
   * Synchronously read a List<int> from the file. Returns the number
   * of bytes read.
   */
  int readListSync(List<int> buffer, int offset, int bytes);

  /**
   * Write a single byte to the file. Returns a
   * [:Future<RandomAccessFile>:] that completes with this
   * RandomAccessFile when the write completes.
   */
  Future<RandomAccessFile> writeByte(int value);

  /**
   * Synchronously write a single byte to the file. Returns the
   * number of bytes successfully written.
   */
  int writeByteSync(int value);

  /**
   * Write a List<int> to the file. Returns a
   * [:Future<RandomAccessFile>:] that completes with this
   * RandomAccessFile when the write completes.
   */
  Future<RandomAccessFile> writeList(List<int> buffer, int offset, int bytes);

  /**
   * Synchronously write a List<int> to the file. Returns the number
   * of bytes successfully written.
   */
  int writeListSync(List<int> buffer, int offset, int bytes);

  /**
   * Write a string to the file using the given [encoding]. The
   * default encoding is UTF-8 - [:Encoding.UTF_8:]. Returns a
   * [:Future<RandomAccessFile>:] that completes with this
   * RandomAccessFile when the write completes.
   */
  Future<RandomAccessFile> writeString(String string, [Encoding encoding]);

  /**
   * Synchronously write a single string to the file using the given
   * [encoding]. Returns the number of characters successfully
   * written. The default encoding is UTF-8 - [:Encoding.UTF_8:].
   */
  int writeStringSync(String string, [Encoding encoding]);

  /**
   * Get the current byte position in the file. Returns a
   * [:Future<int>:] that completes with the position.
   */
  Future<int> position();

  /**
   * Synchronously get the current byte position in the file.
   */
  int positionSync();

  /**
   * Set the byte position in the file. Returns a
   * [:Future<RandomAccessFile>:] that completes with this
   * RandomAccessFile when the position has been set.
   */
  Future<RandomAccessFile> setPosition(int position);

  /**
   * Synchronously set the byte position in the file.
   */
  void setPositionSync(int position);

  /**
   * Truncate (or extend) the file to [length] bytes. Returns a
   * [:Future<RandomAccessFile>:] that completes with this
   * RandomAccessFile when the truncation has been performed.
   */
  Future<RandomAccessFile> truncate(int length);

  /**
   * Synchronously truncate (or extend) the file to [length] bytes.
   */
  void truncateSync(int length);

  /**
   * Get the length of the file. Returns a [:Future<int>:] that
   * completes with the length in bytes.
   */
  Future<int> length();

  /**
   * Synchronously get the length of the file.
   */
  int lengthSync();

  /**
   * Flush the contents of the file to disk. Returns a
   * [:Future<RandomAccessFile>:] that completes with this
   * RandomAccessFile when the flush operation completes.
   */
  Future<RandomAccessFile> flush();

  /**
   * Synchronously flush the contents of the file to disk.
   */
  void flushSync();

  /**
   * Get the name of the file.
   */
  String get name();
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
