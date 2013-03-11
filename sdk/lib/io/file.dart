// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * FileMode describes the modes in which a file can be opened.
 */
class FileMode {
  static const READ = const FileMode._internal(0);
  static const WRITE = const FileMode._internal(1);
  static const APPEND = const FileMode._internal(2);
  const FileMode._internal(int this._mode);
  final int _mode;
}


/**
 * [File] objects are references to files.
 *
 * To operate on the underlying file data there are two options:
 *
 *  * Use streaming: read the contents of the file from the [Stream]
 *    this.[openRead]() and write to the file by writing to the [IOSink]
 *    this.[openWrite]().
 *  * Open the file for random access operations using [open].
 */
abstract class File extends FileSystemEntity {
  /**
   * Create a File object.
   */
  factory File(String path) => new _File(path);

  /**
   * Create a File object from a Path object.
   */
  factory File.fromPath(Path path) => new _File.fromPath(path);

  /**
   * Check if the file exists. Returns a
   * [:Future<bool>:] that completes when the answer is known.
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
   * Existing files are left untouched by [create]. Calling [create] on an
   * existing file might fail if there are restrictive permissions on
   * the file.
   */
  Future<File> create();

  /**
   * Synchronously create the file. Existing files are left untouched
   * by [createSync]. Calling [createSync] on an existing file might fail
   * if there are restrictive permissions on the file.
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
   * Get a [Directory] object for the directory containing this
   * file. Returns a [:Future<Directory>:] that completes with the
   * directory.
   */
  Future<Directory> directory();

  /**
   * Synchronously get a [Directory] object for the directory containing
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
   * [:Future<DateTime>:] that completes with a [DateTime] object for the
   * modification date.
   */
  Future<DateTime> lastModified();

  /**
   * Get the last-modified time of the file. Throws an exception
   * if the file does not exist.
   */
  DateTime lastModifiedSync();

  /**
   * Open the file for random access operations. Returns a
   * [:Future<RandomAccessFile>:] that completes with the opened
   * random access file. [RandomAccessFile]s must be closed using the
   * [RandomAccessFile.close] method.
   *
   * Files can be opened in three modes:
   *
   * [FileMode.READ]: open the file for reading.
   *
   * [FileMode.WRITE]: open the file for both reading and writing and
   * truncate the file to length zero. If the file does not exist the
   * file is created.
   *
   * [FileMode.APPEND]: same as [FileMode.WRITE] except that the file is
   * not truncated.
   */
  Future<RandomAccessFile> open([FileMode mode = FileMode.READ]);

  /**
   * Synchronously open the file for random access operations. The
   * result is a [RandomAccessFile] on which random access operations
   * can be performed. Opened [RandomAccessFile]s must be closed using
   * the [RandomAccessFile.close] method.
   *
   * See [open] for information on the [mode] argument.
   */
  RandomAccessFile openSync([FileMode mode = FileMode.READ]);

  /**
   * Get the canonical full path corresponding to the file path.
   * Returns a [:Future<String>:] that completes with the path.
   */
  Future<String> fullPath();

  /**
   * Synchronously get the canonical full path corresponding to the file path.
   */
  String fullPathSync();

  /**
   * Create a new independent [Stream](../dart_async/Stream.html) for the
   * contents of this file.
   *
   * In order to make sure that system resources are freed, the stream
   * must be read to completion or the subscription on the stream must
   * be cancelled.
   */
  Stream<List<int>> openRead();


  /**
   * Creates a new independent [IOSink] for the file. The
   * [IOSink] must be closed when no longer used, to free
   * system resources.
   *
   * An [IOSink] for a file can be opened in two modes:
   *
   * * [FileMode.WRITE]: truncates the file to length zero.
   * * [FileMode.APPEND]: sets the initial write position to the end
   *   of the file.
   *
   *  When writing strings through the returned [IOSink] the encoding
   *  specified using [encoding] will be used. The returned [IOSink]
   *  has an [:encoding:] property which can be changed after the
   *  [IOSink] has been created.
   */
  IOSink<File> openWrite({FileMode mode: FileMode.WRITE,
                          Encoding encoding: Encoding.UTF_8});

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
   * Read the entire file contents as a string using the given
   * [Encoding].
   *
   * Returns a [:Future<String>:] that completes with the string once
   * the file contents has been read.
   */
  Future<String> readAsString([Encoding encoding = Encoding.UTF_8]);

  /**
   * Synchronously read the entire file contents as a string using the
   * given [Encoding].
   */
  String readAsStringSync([Encoding encoding = Encoding.UTF_8]);

  /**
   * Read the entire file contents as lines of text using the given
   * [Encoding].
   *
   * Returns a [:Future<List<String>>:] that completes with the lines
   * once the file contents has been read.
   */
  Future<List<String>> readAsLines([Encoding encoding = Encoding.UTF_8]);

  /**
   * Synchronously read the entire file contents as lines of text
   * using the given [Encoding].
   */
  List<String> readAsLinesSync([Encoding encoding = Encoding.UTF_8]);

  /**
   * Write a list of bytes to a file.
   *
   * Opens the file, writes the list of bytes to it, and closes the file.
   * Returns a [:Future<File>:] that completes with this [File] object once
   * the entire operation has completed.
   *
   * By default [writeAsBytes] creates the file for writing and truncates the
   * file if it already exists. In order to append the bytes to an existing
   * file, pass [FileMode.APPEND] as the optional mode parameter.
   */
  Future<File> writeAsBytes(List<int> bytes, [FileMode mode = FileMode.WRITE]);

  /**
   * Synchronously write a list of bytes to a file.
   *
   * Opens the file, writes the list of bytes to it and closes the file.
   *
   * By default [writeAsBytesSync] creates the file for writing and truncates
   * the file if it already exists. In order to append the bytes to an existing
   * file, pass [FileMode.APPEND] as the optional mode parameter.
   */
  void writeAsBytesSync(List<int> bytes, [FileMode mode = FileMode.WRITE]);

  /**
   * Write a string to a file.
   *
   * Opens the file, writes the string in the given encoding, and closes the
   * file. Returns a [:Future<File>:] that completes with this [File] object
   * once the entire operation has completed.
   *
   * By default [writeAsString] creates the file for writing and truncates the
   * file if it already exists. In order to append the bytes to an existing
   * file, pass [FileMode.APPEND] as the optional mode parameter.
   */
  Future<File> writeAsString(String contents,
                             {FileMode mode: FileMode.WRITE,
                              Encoding encoding: Encoding.UTF_8});

  /**
   * Synchronously write a string to a file.
   *
   * Opens the file, writes the string in the given encoding, and closes the
   * file.
   *
   * By default [writeAsStringSync] creates the file for writing and
   * truncates the file if it already exists. In order to append the bytes
   * to an existing file, pass [FileMode.APPEND] as the optional mode
   * parameter.
   */
  void writeAsStringSync(String contents,
                         {FileMode mode: FileMode.WRITE,
                          Encoding encoding: Encoding.UTF_8});

  /**
   * Get the path of the file.
   */
  String get path;
}


/**
 * [RandomAccessFile] provides random access to the data in a
 * file. [RandomAccessFile] objects are obtained by calling the
 * [:open:] method on a [File] object.
 */
abstract class RandomAccessFile {
  /**
   * Closes the file. Returns a [:Future<RandomAccessFile>:] that
   * completes with this RandomAccessFile when it has been closed.
   */
  Future<RandomAccessFile> close();

  /**
   * Synchronously closes the file.
   */
  void closeSync();

  /**
   * Reads a byte from the file. Returns a [:Future<int>:] that
   * completes with the byte, or with -1 if end-of-file has been reached.
   */
  Future<int> readByte();

  /**
   * Synchronously reads a single byte from the file. If end-of-file
   * has been reached -1 is returned.
   */
  int readByteSync();

  /**
   * Reads [bytes] bytes from a file and returns the result as a list of bytes.
   */
  Future<List<int>> read(int bytes);

  /**
   * Synchronously reads a maximum of [bytes] bytes from a file
   * and returns the result in a
   * list of bytes.
   */
  List<int> readSync(int bytes);

  /**
   * Reads into an existing List<int> from the file. A maximum of [bytes] bytes
   * is read into [buffer], starting at position [offset] in the buffer.
   * Returns a [:Future<int>:] that completes with the number of bytes read.
   */
  Future<int> readList(List<int> buffer, int offset, int bytes);

  /**
   * Synchronously reads from a file into [buffer].  A maximum of [bytes] bytes
   * is read into [buffer], starting at position [offset] in the buffer.
   * Returns the number of bytes read.
   */
  int readListSync(List<int> buffer, int offset, int bytes);

  /**
   * Writes a single byte to the file. Returns a
   * [:Future<RandomAccessFile>:] that completes with this
   * RandomAccessFile when the write completes.
   */
  Future<RandomAccessFile> writeByte(int value);

  /**
   * Synchronously writes a single byte to the file. Returns the
   * number of bytes successfully written.
   */
  int writeByteSync(int value);

  /**
   * Writes from a List<int> to the file. [bytes] bytes are written from
   * [buffer], starting at position [offset] in the buffer. Returns a
   * [:Future<RandomAccessFile>:] that completes with this
   * RandomAccessFile when the write completes.
   */
  Future<RandomAccessFile> writeList(List<int> buffer, int offset, int bytes);

  /**
   * Synchronously writes a List<int> to the file.
   * [bytes] bytes are written from
   * [buffer], starting at position [offset] in the buffer. Returns the number
   * of bytes successfully written.
   */
  int writeListSync(List<int> buffer, int offset, int bytes);

  /**
   * Writes a string to the file using the given [Encoding]. Returns a
   * [:Future<RandomAccessFile>:] that completes with this
   * RandomAccessFile when the write completes.
   */
  Future<RandomAccessFile> writeString(String string,
                                       [Encoding encoding = Encoding.UTF_8]);

  /**
   * Synchronously writes a single string to the file using the given
   * [Encoding]. Returns the number of characters successfully
   * written.
   */
  int writeStringSync(String string,
                      [Encoding encoding = Encoding.UTF_8]);

  /**
   * Gets the current byte position in the file. Returns a
   * [:Future<int>:] that completes with the position.
   */
  Future<int> position();

  /**
   * Synchronously gets the current byte position in the file.
   */
  int positionSync();

  /**
   * Sets the byte position in the file. Returns a
   * [:Future<RandomAccessFile>:] that completes with this
   * RandomAccessFile when the position has been set.
   */
  Future<RandomAccessFile> setPosition(int position);

  /**
   * Synchronously sets the byte position in the file.
   */
  void setPositionSync(int position);

  /**
   * Truncates (or extends) the file to [length] bytes. Returns a
   * [:Future<RandomAccessFile>:] that completes with this
   * RandomAccessFile when the truncation has been performed.
   */
  Future<RandomAccessFile> truncate(int length);

  /**
   * Synchronously truncates (or extends) the file to [length] bytes.
   */
  void truncateSync(int length);

  /**
   * Gets the length of the file. Returns a [:Future<int>:] that
   * completes with the length in bytes.
   */
  Future<int> length();

  /**
   * Synchronously gets the length of the file.
   */
  int lengthSync();

  /**
   * Flushes the contents of the file to disk. Returns a
   * [:Future<RandomAccessFile>:] that completes with this
   * RandomAccessFile when the flush operation completes.
   */
  Future<RandomAccessFile> flush();

  /**
   * Synchronously flushes the contents of the file to disk.
   */
  void flushSync();

  /**
   * Returns a human-readable string for this RandomAccessFile instance.
   */
  String toString();

  /**
   * Gets the path of the file underlying this RandomAccessFile.
   */
  String get path;
}


class FileIOException implements Exception {
  const FileIOException([String this.message = "",
                         OSError this.osError = null]);
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("FileIOException");
    if (!message.isEmpty) {
      sb.write(": $message");
      if (osError != null) {
        sb.write(" ($osError)");
      }
    } else if (osError != null) {
      sb.write(": osError");
    }
    return sb.toString();
  }
  final String message;
  final OSError osError;
}
