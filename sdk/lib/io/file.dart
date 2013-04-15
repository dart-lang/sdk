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

const READ = FileMode.READ;
const WRITE = FileMode.WRITE;
const APPEND = FileMode.APPEND;

/**
 * [File] objects are references to files.
 *
 * If [path] is a symbolic link, rather than a file, then
 * the methods of [File] operate on the ultimate target of the
 * link, except for File.delete and File.deleteSync, which operate on
 * the link.
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
   *
   * Throws a [FileIOException] if the operation fails.
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
   *
   * Throws a [FileIOException] if the operation fails.
   */
  void createSync();

  /**
   * Delete the file. Returns a [:Future<File>:] that completes with
   * the file when it has been deleted. Only a file or a link to a file
   * can be deleted with this method, not a directory or a broken link.
   */
  Future<File> delete();

  /**
   * Synchronously delete the file. Only a file or a link to a file
   * can be deleted with this method, not a directory or a broken link.
   *
   * Throws a [FileIOException] if the operation fails.
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
   *
   * Throws a [FileIOException] if the operation fails.
   */
  Directory directorySync();

  /**
   * Get the length of the file. Returns a [:Future<int>:] that
   * completes with the length in bytes.
   */
  Future<int> length();

  /**
   * Synchronously get the length of the file.
   *
   * Throws a [FileIOException] if the operation fails.
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
   *
   * Throws a [FileIOException] if the operation fails.
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
  Future<RandomAccessFile> open({FileMode mode: FileMode.READ});

  /**
   * Synchronously open the file for random access operations. The
   * result is a [RandomAccessFile] on which random access operations
   * can be performed. Opened [RandomAccessFile]s must be closed using
   * the [RandomAccessFile.close] method.
   *
   * See [open] for information on the [mode] argument.
   *
   * Throws a [FileIOException] if the operation fails.
   */
  RandomAccessFile openSync({FileMode mode: FileMode.READ});

  /**
   * Get the canonical full path corresponding to the file path.
   * Returns a [:Future<String>:] that completes with the path.
   */
  Future<String> fullPath();

  /**
   * Synchronously get the canonical full path corresponding to the file path.
   *
   * Throws a [FileIOException] if the operation fails.
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
  IOSink openWrite({FileMode mode: FileMode.WRITE,
                    Encoding encoding: Encoding.UTF_8});

  /**
   * Read the entire file contents as a list of bytes. Returns a
   * [:Future<List<int>>:] that completes with the list of bytes that
   * is the contents of the file.
   */
  Future<List<int>> readAsBytes();

  /**
   * Synchronously read the entire file contents as a list of bytes.
   *
   * Throws a [FileIOException] if the operation fails.
   */
  List<int> readAsBytesSync();

  /**
   * Read the entire file contents as a string using the given
   * [Encoding].
   *
   * Returns a [:Future<String>:] that completes with the string once
   * the file contents has been read.
   */
  Future<String> readAsString({Encoding encoding: Encoding.UTF_8});

  /**
   * Synchronously read the entire file contents as a string using the
   * given [Encoding].
   *
   * Throws a [FileIOException] if the operation fails.
   */
  String readAsStringSync({Encoding encoding: Encoding.UTF_8});

  /**
   * Read the entire file contents as lines of text using the given
   * [Encoding].
   *
   * Returns a [:Future<List<String>>:] that completes with the lines
   * once the file contents has been read.
   */
  Future<List<String>> readAsLines({Encoding encoding: Encoding.UTF_8});

  /**
   * Synchronously read the entire file contents as lines of text
   * using the given [Encoding].
   *
   * Throws a [FileIOException] if the operation fails.
   */
  List<String> readAsLinesSync({Encoding encoding: Encoding.UTF_8});

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
  Future<File> writeAsBytes(List<int> bytes, {FileMode mode: FileMode.WRITE});

  /**
   * Synchronously write a list of bytes to a file.
   *
   * Opens the file, writes the list of bytes to it and closes the file.
   *
   * By default [writeAsBytesSync] creates the file for writing and truncates
   * the file if it already exists. In order to append the bytes to an existing
   * file, pass [FileMode.APPEND] as the optional mode parameter.
   *
   * Throws a [FileIOException] if the operation fails.
   */
  void writeAsBytesSync(List<int> bytes, {FileMode mode: FileMode.WRITE});

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
   *
   * Throws a [FileIOException] if the operation fails.
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
   *
   * Throws a [FileIOException] if the operation fails.
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
   *
   * Throws a [FileIOException] if the operation fails.
   */
  int readByteSync();

  /**
   * Reads [bytes] bytes from a file and returns the result as a list of bytes.
   */
  Future<List<int>> read(int bytes);

  /**
   * Synchronously reads a maximum of [bytes] bytes from a file and
   * returns the result in a list of bytes.
   *
   * Throws a [FileIOException] if the operation fails.
   */
  List<int> readSync(int bytes);

  /**
   * Reads into an existing List<int> from the file. If [start] is present, the
   * bytes will be filled into [buffer] from at index [start], otherwise index
   * 0. If [end] is present, the [end] - [start] bytes will be read into
   * [buffer], otherwise up to [buffer.length]. If [end] == [start] nothing
   * happends.
   *
   * Returns a [:Future<int>:] that completes with the number of bytes read.
   */
  Future<int> readInto(List<int> buffer, [int start, int end]);

  /**
   * Synchronously reads into an existing List<int> from the file. If [start] is
   * present, the bytes will be filled into [buffer] from at index [start],
   * otherwise index 0.  If [end] is present, the [end] - [start] bytes will be
   * read into [buffer], otherwise up to [buffer.length]. If [end] == [start]
   * nothing happends.
   *
   * Throws a [FileIOException] if the operation fails.
   */
  int readIntoSync(List<int> buffer, [int start, int end]);

  /**
   * Writes a single byte to the file. Returns a
   * [:Future<RandomAccessFile>:] that completes with this
   * RandomAccessFile when the write completes.
   */
  Future<RandomAccessFile> writeByte(int value);

  /**
   * Synchronously writes a single byte to the file. Returns the
   * number of bytes successfully written.
   *
   * Throws a [FileIOException] if the operation fails.
   */
  int writeByteSync(int value);

  /**
   * Writes from a [List<int>] to the file. It will read the buffer from index
   * [start] to index [end]. If [start] is omitted, it'll start from index 0.
   * If [end] is omitted, it will write to end of [buffer].
   *
   * Returns a [:Future<RandomAccessFile>:] that completes with this
   * [RandomAccessFile] when the write completes.
   */
  Future<RandomAccessFile> writeFrom(List<int> buffer, [int start, int end]);

  /**
   * Synchronously writes from a [List<int>] to the file. It will read the
   * buffer from index [start] to index [end]. If [start] is omitted, it'll
   * start from index 0. If [end] is omitted, it will write to the end of
   * [buffer].
   *
   * Throws a [FileIOException] if the operation fails.
   */
  void writeFromSync(List<int> buffer, [int start, int end]);

  /**
   * Writes a string to the file using the given [Encoding]. Returns a
   * [:Future<RandomAccessFile>:] that completes with this
   * RandomAccessFile when the write completes.
   */
  Future<RandomAccessFile> writeString(String string,
                                       {Encoding encoding: Encoding.UTF_8});

  /**
   * Synchronously writes a single string to the file using the given
   * [Encoding].
   *
   * Throws a [FileIOException] if the operation fails.
   */
  void writeStringSync(String string,
                       {Encoding encoding: Encoding.UTF_8});

  /**
   * Gets the current byte position in the file. Returns a
   * [:Future<int>:] that completes with the position.
   */
  Future<int> position();

  /**
   * Synchronously gets the current byte position in the file.
   *
   * Throws a [FileIOException] if the operation fails.
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
   *
   * Throws a [FileIOException] if the operation fails.
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
   *
   * Throws a [FileIOException] if the operation fails.
   */
  void truncateSync(int length);

  /**
   * Gets the length of the file. Returns a [:Future<int>:] that
   * completes with the length in bytes.
   */
  Future<int> length();

  /**
   * Synchronously gets the length of the file.
   *
   * Throws a [FileIOException] if the operation fails.
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
   *
   * Throws a [FileIOException] if the operation fails.
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
