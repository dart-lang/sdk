// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/// The modes in which a [File] can be opened.
class FileMode {
  /// The mode for opening a file only for reading.
  static const read = const FileMode._internal(0);
  @Deprecated("Use read instead")
  static const READ = read;

  /// Mode for opening a file for reading and writing. The file is
  /// overwritten if it already exists. The file is created if it does not
  /// already exist.
  static const write = const FileMode._internal(1);
  @Deprecated("Use write instead")
  static const WRITE = write;

  /// Mode for opening a file for reading and writing to the
  /// end of it. The file is created if it does not already exist.
  static const append = const FileMode._internal(2);
  @Deprecated("Use append instead")
  static const APPEND = append;

  /// Mode for opening a file for writing *only*. The file is
  /// overwritten if it already exists. The file is created if it does not
  /// already exist.
  static const writeOnly = const FileMode._internal(3);
  @Deprecated("Use writeOnly instead")
  static const WRITE_ONLY = writeOnly;

  /// Mode for opening a file for writing *only* to the
  /// end of it. The file is created if it does not already exist.
  static const writeOnlyAppend = const FileMode._internal(4);
  @Deprecated("Use writeOnlyAppend instead")
  static const WRITE_ONLY_APPEND = writeOnlyAppend;

  final int _mode;

  const FileMode._internal(this._mode);
}

/// The mode for opening a file only for reading.
@Deprecated("Use FileMode.read instead")
const READ = FileMode.read;

/// The mode for opening a file for reading and writing. The file is
/// overwritten if it already exists. The file is created if it does not
/// already exist.
@Deprecated("Use FileMode.write instead")
const WRITE = FileMode.write;

/// The mode for opening a file for reading and writing to the
/// end of it. The file is created if it does not already exist.
@Deprecated("Use FileMode.append instead")
const APPEND = FileMode.append;

/// Mode for opening a file for writing *only*. The file is
/// overwritten if it already exists. The file is created if it does not
/// already exist.
@Deprecated("Use FileMode.writeOnly instead")
const WRITE_ONLY = FileMode.writeOnly;

/// Mode for opening a file for writing *only* to the
/// end of it. The file is created if it does not already exist.
@Deprecated("Use FileMode.writeOnlyAppend instead")
const WRITE_ONLY_APPEND = FileMode.writeOnlyAppend;

/// Type of lock when requesting a lock on a file.
class FileLock {
  /// Shared file lock.
  static const shared = const FileLock._internal(1);
  @Deprecated("Use shared instead")
  static const SHARED = shared;

  /// Exclusive file lock.
  static const exclusive = const FileLock._internal(2);
  @Deprecated("Use exclusive instead")
  static const EXCLUSIVE = exclusive;

  /// Blocking shared file lock.
  static const blockingShared = const FileLock._internal(3);
  @Deprecated("Use blockingShared instead")
  static const BLOCKING_SHARED = blockingShared;

  /// Blocking exclusive file lock.
  static const blockingExclusive = const FileLock._internal(4);
  @Deprecated("Use blockingExclusive instead")
  static const BLOCKING_EXCLUSIVE = blockingExclusive;

  final int _type;

  const FileLock._internal(this._type);
}

/// A reference to a file on the file system.
///
/// A `File` holds a [path] on which operations can be performed.
/// You can get the parent directory of the file using [parent],
/// a property inherited from [FileSystemEntity].
///
/// Create a new `File` object with a pathname to access the specified file on the
/// file system from your program.
/// ```dart
/// var myFile = File('file.txt');
/// ```
/// The `File` class contains methods for manipulating files and their contents.
/// Using methods in this class, you can open and close files, read to and write
/// from them, create and delete them, and check for their existence.
///
/// When reading or writing a file, you can use streams (with [openRead]),
/// random access operations (with [open]),
/// or convenience methods such as [readAsString],
///
/// Most methods in this class occur in synchronous and asynchronous pairs,
/// for example, [readAsString] and [readAsStringSync].
/// Unless you have a specific reason for using the synchronous version
/// of a method, prefer the asynchronous version to avoid blocking your program.
///
/// ## If path is a link
///
/// If [path] is a symbolic link, rather than a file,
/// then the methods of `File` operate on the ultimate target of the
/// link, except for [delete] and [deleteSync], which operate on
/// the link.
///
/// ## Read from a file
///
/// The following code sample reads the entire contents from a file as a string
/// using the asynchronous [readAsString] method:
/// ```dart
/// import 'dart:async';
/// import 'dart:io';
///
/// void main() {
///   File('file.txt').readAsString().then((String contents) {
///     print(contents);
///   });
/// }
/// ```
/// A more flexible and useful way to read a file is with a [Stream].
/// Open the file with [openRead], which returns a stream that
/// provides the data in the file as chunks of bytes.
/// Read the stream to process the file contents when available.
/// You can use various transformers in succession to manipulate the
/// file content into the required format, or to prepare it for output.
///
/// You might want to use a stream to read large files,
/// to manipulate the data with transformers,
/// or for compatibility with another API, such as [WebSocket]s.
/// ```dart
/// import 'dart:io';
/// import 'dart:convert';
/// import 'dart:async';
///
/// void main() async {
///   final file = File('file.txt');
///   Stream<String> lines = file.openRead()
///     .transform(utf8.decoder)       // Decode bytes to UTF-8.
///     .transform(LineSplitter());    // Convert stream to individual lines.
///   try {
///     await for (var line in lines) {
///       print('$line: ${line.length} characters');
///     }
///     print('File is now closed.');
///   } catch (e) {
///     print('Error: $e');
///   }
/// }
/// ```
/// ## Write to a file
///
/// To write a string to a file, use the [writeAsString] method:
/// ```dart
/// import 'dart:io';
///
/// void main() async {
///   final filename = 'file.txt';
///   var file = await File(filename).writeAsString('some content');
///   // Do something with the file.
/// }
/// ```
/// You can also write to a file using a [Stream]. Open the file with
/// [openWrite], which returns an [IOSink] to which you can write data.
/// Be sure to close the sink with the [IOSink.close] method.
/// ```dart
/// import 'dart:io';
///
/// void main() {
///   var file = File('file.txt');
///   var sink = file.openWrite();
///   sink.write('FILE ACCESSED ${DateTime.now()}\n');
///
///   // Close the IOSink to free system resources.
///   sink.close();
/// }
/// ```
/// ## The use of asynchronous methods
///
/// To avoid unintentional blocking of the program,
/// several methods are asynchronous and return a [Future]. For example,
/// the [length] method, which gets the length of a file, returns a [Future].
/// Wait for the future to get the result when it's ready.
/// ```dart
/// import 'dart:io';
///
/// void main() async {
///   final file = File('file.txt');
///
///   var length = await file.length();
///   print(length);
/// }
/// ```
/// In addition to length, the [exists], [lastModified], [stat], and
/// other methods, are asynchronous.
///
/// ## Other resources
///
/// * The [Files and directories](https://dart.dev/guides/libraries/library-tour#files-and-directories)
///   section of the library tour.
///
/// * [Write Command-Line Apps](https://dart.dev/tutorials/server/cmdline),
///   a tutorial about writing command-line apps, includes information about
///   files and directories.
@pragma("vm:entry-point")
abstract class File implements FileSystemEntity {
  /// Creates a [File] object.
  ///
  /// If [path] is a relative path, it will be interpreted relative to the
  /// current working directory (see [Directory.current]), when used.
  ///
  /// If [path] is an absolute path, it will be immune to changes to the
  /// current working directory.
  @pragma("vm:entry-point")
  factory File(String path) {
    final IOOverrides? overrides = IOOverrides.current;
    if (overrides == null) {
      return new _File(path);
    }
    return overrides.createFile(path);
  }

  /// Create a [File] object from a URI.
  ///
  /// If [uri] cannot reference a file this throws [UnsupportedError].
  factory File.fromUri(Uri uri) => new File(uri.toFilePath());

  /// Creates a [File] object from a raw path.
  ///
  /// A raw path is a sequence of bytes, as paths are represented by the OS.
  @pragma("vm:entry-point")
  factory File.fromRawPath(Uint8List rawPath) {
    // TODO(bkonyi): Handle overrides.
    return new _File.fromRawPath(rawPath);
  }

  /// Creates the file.
  ///
  /// Returns a `Future<File>` that completes with
  /// the file when it has been created.
  ///
  /// If [recursive] is `false`, the default, the file is created only if
  /// all directories in its path already exist. If [recursive] is `true`, any
  /// non-existing parent paths are created first.
  ///
  /// Existing files are left untouched by [create]. Calling [create] on an
  /// existing file might fail if there are restrictive permissions on
  /// the file.
  ///
  /// Completes the future with a [FileSystemException] if the operation fails.
  Future<File> create({bool recursive = false});

  /// Synchronously creates the file.
  ///
  /// Existing files are left untouched by [createSync].
  /// Calling [createSync] on an existing file might fail
  /// if there are restrictive permissions on the file.
  ///
  /// If [recursive] is `false`, the default, the file is created
  /// only if all directories in its path already exist.
  /// If [recursive] is `true`, all non-existing parent paths are created first.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void createSync({bool recursive = false});

  /// Renames this file.
  ///
  /// Returns a `Future<File>` that completes
  /// with a [File] for the renamed file.
  ///
  /// If [newPath] is a relative path, it is resolved against
  /// the current working directory ([Directory.current]).
  /// This means that simply changing the name of a file,
  /// but keeping it the original directory,
  /// requires creating a new complete path with the new name
  /// at the end. Example:
  /// ```dart
  /// Future<File> changeFileNameOnly(File file, String newFileName) {
  ///   var path = file.path;
  ///   var lastSeparator = path.lastIndexOf(Platform.pathSeparator);
  ///   var newPath = path.substring(0, lastSeparator + 1) + newFileName;
  ///   return file.rename(newPath);
  /// }
  /// ```
  /// On some platforms, a rename operation cannot move a file between
  /// different file systems. If that is the case, instead [copy] the
  /// file to the new location and then remove the original.
  ///
  /// If [newPath] identifies an existing file, that file is
  /// removed first. If [newPath] identifies an existing directory, the
  /// operation fails and the future completes with an exception.
  Future<File> rename(String newPath);

  /// Synchronously renames this file.
  ///
  /// Returns a [File] for the renamed file.
  ///
  /// If [newPath] is a relative path, it is resolved against
  /// the current working directory ([Directory.current]).
  /// This means that simply changing the name of a file,
  /// but keeping it the original directory,
  /// requires creating a new complete path with the new name
  /// at the end. Example:
  /// ```dart
  /// File changeFileNameOnlySync(File file, String newFileName) {
  ///   var path = file.path;
  ///   var lastSeparator = path.lastIndexOf(Platform.pathSeparator);
  ///   var newPath = path.substring(0, lastSeparator + 1) + newFileName;
  ///   return file.renameSync(newPath);
  /// }
  /// ```
  /// On some platforms, a rename operation cannot move a file between
  /// different file systems. If that is the case, instead [copySync] the
  /// file to the new location and then [deleteSync] the original.
  ///
  /// If [newPath] identifies an existing file, that file is
  /// removed first. If [newPath] identifies an existing directory the
  /// operation fails and an exception is thrown.
  File renameSync(String newPath);

  /// Copies this file.
  ///
  /// If [newPath] is a relative path, it is resolved against
  /// the current working directory ([Directory.current]).
  ///
  /// Returns a `Future<File>` that completes
  /// with a [File] for the copied file.
  ///
  /// If [newPath] identifies an existing file, that file is
  /// removed first. If [newPath] identifies an existing directory, the
  /// operation fails and the future completes with an exception.
  Future<File> copy(String newPath);

  /// Synchronously copies this file.
  ///
  /// If [newPath] is a relative path, it is resolved against
  /// the current working directory ([Directory.current]).
  ///
  /// Returns a [File] for the copied file.
  ///
  /// If [newPath] identifies an existing file, that file is
  /// removed first. If [newPath] identifies an existing directory the
  /// operation fails and an exception is thrown.
  File copySync(String newPath);

  /// The length of the file.
  ///
  /// Returns a `Future<int>` that completes with the length in bytes.
  Future<int> length();

  /// The length of the file provided synchronously.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  int lengthSync();

  /// A [File] with the absolute path of [path].
  ///
  /// The absolute path is computed by prefixing
  /// a relative path with the current working directory,
  /// or returning an absolute path unchanged.
  File get absolute;

  /// The last-accessed time of the file.
  ///
  /// Returns a `Future<DateTime>` that completes with the date and time when the
  /// file was last accessed, if the information is available.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  Future<DateTime> lastAccessed();

  /// The last-accessed time of the file.
  ///
  /// Returns the date and time when the file was last accessed,
  /// if the information is available. Blocks until the information can be returned
  /// or it is determined that the information is not available.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  DateTime lastAccessedSync();

  /// Modifies the time the file was last accessed.
  ///
  /// Returns a [Future] that completes once the operation has completed.
  ///
  /// Throws a [FileSystemException] if the time cannot be set.
  Future setLastAccessed(DateTime time);

  /// Synchronously modifies the time the file was last accessed.
  ///
  /// Throws a [FileSystemException] if the time cannot be set.
  void setLastAccessedSync(DateTime time);

  /// Get the last-modified time of the file.
  ///
  /// Returns a `Future<DateTime>` that completes with the date and time when the
  /// file was last modified, if the information is available.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  Future<DateTime> lastModified();

  /// Get the last-modified time of the file.
  ///
  /// Returns the date and time when the file was last modified,
  /// if the information is available. Blocks until the information can be returned
  /// or it is determined that the information is not available.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  DateTime lastModifiedSync();

  /// Modifies the time the file was last modified.
  ///
  /// Returns a [Future] that completes once the operation has completed.
  ///
  /// Throws a [FileSystemException] if the time cannot be set.
  Future setLastModified(DateTime time);

  /// Synchronously modifies the time the file was last modified.
  ///
  /// If the attributes cannot be set, throws a [FileSystemException].
  void setLastModifiedSync(DateTime time);

  /// Opens the file for random access operations.
  ///
  /// Returns a `Future<RandomAccessFile>` that completes with the opened
  /// random access file. [RandomAccessFile]s must be closed using the
  /// [RandomAccessFile.close] method.
  ///
  /// Files can be opened in three modes:
  ///
  /// * [FileMode.read]: open the file for reading.
  ///
  /// * [FileMode.write]: open the file for both reading and writing and
  /// truncate the file to length zero. If the file does not exist the
  /// file is created.
  ///
  /// * [FileMode.append]: same as [FileMode.write] except that the file is
  /// not truncated.
  Future<RandomAccessFile> open({FileMode mode = FileMode.read});

  /// Synchronously opens the file for random access operations.
  ///
  /// The result is a [RandomAccessFile] on which random access operations
  /// can be performed. Opened [RandomAccessFile]s must be closed using
  /// the [RandomAccessFile.close] method.
  ///
  /// See [open] for information on the [mode] argument.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  RandomAccessFile openSync({FileMode mode = FileMode.read});

  /// Creates a new independent [Stream] for the contents of this file.
  ///
  /// If [start] is present, the file will be read from byte-offset [start].
  /// Otherwise from the beginning (index 0).
  ///
  /// If [end] is present, only bytes up to byte-index [end] will be read.
  /// Otherwise, until end of file.
  ///
  /// In order to make sure that system resources are freed, the stream
  /// must be read to completion or the subscription on the stream must
  /// be cancelled.
  Stream<List<int>> openRead([int? start, int? end]);

  /// Creates a new independent [IOSink] for the file.
  ///
  /// The [IOSink] must be closed when no longer used, to free
  /// system resources.
  ///
  /// An [IOSink] for a file can be opened in two modes:
  ///
  /// * [FileMode.write]: truncates the file to length zero.
  /// * [FileMode.append]: sets the initial write position to the end
  ///   of the file.
  ///
  ///  When writing strings through the returned [IOSink] the encoding
  ///  specified using [encoding] will be used. The returned [IOSink]
  ///  has an `encoding` property which can be changed after the
  ///  [IOSink] has been created.
  IOSink openWrite({FileMode mode = FileMode.write, Encoding encoding = utf8});

  /// Reads the entire file contents as a list of bytes.
  ///
  /// Returns a `Future<Uint8List>` that completes with the list of bytes that
  /// is the contents of the file.
  Future<Uint8List> readAsBytes();

  /// Synchronously reads the entire file contents as a list of bytes.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  Uint8List readAsBytesSync();

  /// Reads the entire file contents as a string using the given
  /// [Encoding].
  ///
  /// Returns a `Future<String>` that completes with the string once
  /// the file contents has been read.
  Future<String> readAsString({Encoding encoding = utf8});

  /// Synchronously reads the entire file contents as a string using the
  /// given [Encoding].
  ///
  /// Throws a [FileSystemException] if the operation fails.
  String readAsStringSync({Encoding encoding = utf8});

  /// Reads the entire file contents as lines of text using the given
  /// [Encoding].
  ///
  /// Returns a `Future<List<String>>` that completes with the lines
  /// once the file contents has been read.
  Future<List<String>> readAsLines({Encoding encoding = utf8});

  /// Synchronously reads the entire file contents as lines of text
  /// using the given [Encoding].
  ///
  /// Throws a [FileSystemException] if the operation fails.
  List<String> readAsLinesSync({Encoding encoding = utf8});

  /// Writes a list of bytes to a file.
  ///
  /// Opens the file, writes the list of bytes to it, and closes the file.
  /// Returns a `Future<File>` that completes with this [File] object once
  /// the entire operation has completed.
  ///
  /// By default [writeAsBytes] creates the file for writing and truncates the
  /// file if it already exists. In order to append the bytes to an existing
  /// file, pass [FileMode.append] as the optional mode parameter.
  ///
  /// If the argument [flush] is set to `true`, the data written will be
  /// flushed to the file system before the returned future completes.
  Future<File> writeAsBytes(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false});

  /// Synchronously writes a list of bytes to a file.
  ///
  /// Opens the file, writes the list of bytes to it and closes the file.
  ///
  /// By default [writeAsBytesSync] creates the file for writing and truncates
  /// the file if it already exists. In order to append the bytes to an existing
  /// file, pass [FileMode.append] as the optional mode parameter.
  ///
  /// If the [flush] argument is set to `true` data written will be
  /// flushed to the file system before returning.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void writeAsBytesSync(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false});

  /// Writes a string to a file.
  ///
  /// Opens the file, writes the string in the given encoding, and closes the
  /// file. Returns a `Future<File>` that completes with this [File] object
  /// once the entire operation has completed.
  ///
  /// By default [writeAsString] creates the file for writing and truncates the
  /// file if it already exists. In order to append the bytes to an existing
  /// file, pass [FileMode.append] as the optional mode parameter.
  ///
  /// If the argument [flush] is set to `true`, the data written will be
  /// flushed to the file system before the returned future completes.
  ///
  Future<File> writeAsString(String contents,
      {FileMode mode = FileMode.write,
      Encoding encoding = utf8,
      bool flush = false});

  /// Synchronously writes a string to a file.
  ///
  /// Opens the file, writes the string in the given encoding, and closes the
  /// file.
  ///
  /// By default [writeAsStringSync] creates the file for writing and
  /// truncates the file if it already exists. In order to append the bytes
  /// to an existing file, pass [FileMode.append] as the optional mode
  /// parameter.
  ///
  /// If the [flush] argument is set to `true` data written will be
  /// flushed to the file system before returning.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void writeAsStringSync(String contents,
      {FileMode mode = FileMode.write,
      Encoding encoding = utf8,
      bool flush = false});

  /// Get the path of the file.
  String get path;
}

/// Random access to the data in a file.
///
/// `RandomAccessFile` objects are obtained by calling the
/// `open` method on a [File] object.
///
/// A `RandomAccessFile` has both asynchronous and synchronous
/// methods. The asynchronous methods all return a [Future]
/// whereas the synchronous methods will return the result directly,
/// and block the current isolate until the result is ready.
///
/// At most one asynchronous method can be pending on a given `RandomAccessFile`
/// instance at the time. If another asynchronous method is called when one is
/// already in progress, a [FileSystemException] is thrown.
///
/// If an asynchronous method is pending, it is also not possible to call any
/// synchronous methods. This will also throw a [FileSystemException].
abstract class RandomAccessFile {
  /// Closes the file.
  ///
  /// Returns a [Future] that completes when it has been closed.
  Future<void> close();

  /// Synchronously closes the file.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void closeSync();

  /// Reads a byte from the file.
  ///
  /// Returns a `Future<int>` that completes with the byte,
  /// or with -1 if end-of-file has been reached.
  Future<int> readByte();

  /// Synchronously reads a single byte from the file.
  ///
  /// If end-of-file has been reached -1 is returned.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  int readByteSync();

  /// Reads up to [count] bytes from a file.
  Future<Uint8List> read(int count);

  /// Synchronously reads up to [count] bytes from a file
  ///
  /// Throws a [FileSystemException] if the operation fails.
  Uint8List readSync(int count);

  /// Reads bytes into an existing [buffer].
  ///
  /// Reads bytes and writes then into the the range of [buffer]
  /// from [start] to [end].
  /// The [start] must be non-negative and no greater than `buffer.length`.
  /// If [end] is omitted, it defaults to [buffer.length].
  /// Otherwise [end] must be no less than [start]
  /// and no greater than `buffer.length`.
  ///
  /// Returns the number of bytes read. This maybe be less than `end - start`
  /// if the file doesn't have that many bytes to read.
  Future<int> readInto(List<int> buffer, [int start = 0, int? end]);

  /// Synchronously reads into an existing [buffer].
  ///
  /// Reads bytes and writes then into the the range of [buffer]
  /// from [start] to [end].
  /// The [start] must be non-negative and no greater than `buffer.length`.
  /// If [end] is omitted, it defaults to [buffer.length].
  /// Otherwise [end] must be no less than [start]
  /// and no greater than `buffer.length`.
  ///
  /// Returns the number of bytes read. This maybe be less than `end - start`
  /// if the file doesn't have that many bytes to read.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  int readIntoSync(List<int> buffer, [int start = 0, int? end]);

  /// Writes a single byte to the file.
  ///
  /// Returns a `Future<RandomAccessFile>` that completes with this
  /// random access file when the write completes.
  Future<RandomAccessFile> writeByte(int value);

  /// Synchronously writes a single byte to the file.
  ///
  /// Returns 1 on success.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  int writeByteSync(int value);

  /// Writes from a [buffer] to the file.
  ///
  /// Will read the buffer from index [start] to index [end].
  /// The [start] must be non-negative and no greater than `buffer.length`.
  /// If [end] is omitted, it defaults to [buffer.length].
  /// Otherwise [end] must be no less than [start]
  /// and no greater than `buffer.length`.
  ///
  /// Returns a `Future<RandomAccessFile>` that completes with this
  /// [RandomAccessFile] when the write completes.
  Future<RandomAccessFile> writeFrom(List<int> buffer,
      [int start = 0, int? end]);

  /// Synchronously writes from a [buffer] to the file.
  ///
  /// Will read the buffer from index [start] to index [end].
  /// The [start] must be non-negative and no greater than `buffer.length`.
  /// If [end] is omitted, it defaults to [buffer.length].
  /// Otherwise [end] must be no less than [start]
  /// and no greater than `buffer.length`.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void writeFromSync(List<int> buffer, [int start = 0, int? end]);

  /// Writes a string to the file using the given [Encoding].
  ///
  /// Returns a `Future<RandomAccessFile>` that completes with this
  /// random access file when the write completes.
  Future<RandomAccessFile> writeString(String string,
      {Encoding encoding = utf8});

  /// Synchronously writes a single string to the file using the given
  /// [Encoding].
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void writeStringSync(String string, {Encoding encoding = utf8});

  /// Gets the current byte position in the file.
  ///
  /// Returns a `Future<int>` that completes with the position.
  Future<int> position();

  /// Synchronously gets the current byte position in the file.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  int positionSync();

  /// Sets the byte position in the file.
  ///
  /// Returns a `Future<RandomAccessFile>` that completes with this
  /// random access file when the position has been set.
  Future<RandomAccessFile> setPosition(int position);

  /// Synchronously sets the byte position in the file.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void setPositionSync(int position);

  /// Truncates (or extends) the file to [length] bytes.
  ///
  /// Returns a `Future<RandomAccessFile>` that completes with this
  /// random access file when the truncation has been performed.
  Future<RandomAccessFile> truncate(int length);

  /// Synchronously truncates (or extends) the file to [length] bytes.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void truncateSync(int length);

  /// Gets the length of the file.
  ///
  /// Returns a `Future<int>` that completes with the length in bytes.
  Future<int> length();

  /// Synchronously gets the length of the file.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  int lengthSync();

  /// Flushes the contents of the file to disk.
  ///
  /// Returns a `Future<RandomAccessFile>` that completes with this
  /// random access file when the flush operation completes.
  Future<RandomAccessFile> flush();

  /// Synchronously flushes the contents of the file to disk.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  void flushSync();

  /// Locks the file or part of the file.
  ///
  /// By default an exclusive lock will be obtained, but that can be overridden
  /// by the [mode] argument.
  ///
  /// Locks the byte range from [start] to [end] of the file, with the
  /// byte at position `end` not included. If no arguments are
  /// specified, the full file is locked, If only `start` is specified
  /// the file is locked from byte position `start` to the end of the
  /// file, no matter how large it grows. It is possible to specify an
  /// explicit value of `end` which is past the current length of the file.
  ///
  /// To obtain an exclusive lock on a file, it must be opened for writing.
  ///
  /// If [mode] is [FileLock.exclusive] or [FileLock.shared], an error is
  /// signaled if the lock cannot be obtained. If [mode] is
  /// [FileLock.blockingExclusive] or [FileLock.blockingShared], the
  /// returned [Future] is resolved only when the lock has been obtained.
  ///
  /// *NOTE* file locking does have slight differences in behavior across
  /// platforms:
  ///
  /// On Linux and OS X this uses advisory locks, which have the
  /// surprising semantics that all locks associated with a given file
  /// are removed when *any* file descriptor for that file is closed by
  /// the process. Note that this does not actually lock the file for
  /// access. Also note that advisory locks are on a process
  /// level. This means that several isolates in the same process can
  /// obtain an exclusive lock on the same file.
  ///
  /// On Windows the regions used for lock and unlock needs to match. If that
  /// is not the case unlocking will result in the OS error "The segment is
  /// already unlocked".
  Future<RandomAccessFile> lock(
      [FileLock mode = FileLock.exclusive, int start = 0, int end = -1]);

  /// Synchronously locks the file or part of the file.
  ///
  /// By default an exclusive lock will be obtained, but that can be overridden
  /// by the [mode] argument.
  ///
  /// Locks the byte range from [start] to [end] of the file ,with the
  /// byte at position `end` not included. If no arguments are
  /// specified, the full file is locked, If only `start` is specified
  /// the file is locked from byte position `start` to the end of the
  /// file, no matter how large it grows. It is possible to specify an
  /// explicit value of `end` which is past the current length of the file.
  ///
  /// To obtain an exclusive lock on a file it must be opened for writing.
  ///
  /// If [mode] is [FileLock.exclusive] or [FileLock.shared], an exception is
  /// thrown if the lock cannot be obtained. If [mode] is
  /// [FileLock.blockingExclusive] or [FileLock.blockingShared], the
  /// call returns only after the lock has been obtained.
  ///
  /// *NOTE* file locking does have slight differences in behavior across
  /// platforms:
  ///
  /// On Linux and OS X this uses advisory locks, which have the
  /// surprising semantics that all locks associated with a given file
  /// are removed when *any* file descriptor for that file is closed by
  /// the process. Note that this does not actually lock the file for
  /// access. Also note that advisory locks are on a process
  /// level. This means that several isolates in the same process can
  /// obtain an exclusive lock on the same file.
  ///
  /// On Windows the regions used for lock and unlock needs to match. If that
  /// is not the case unlocking will result in the OS error "The segment is
  /// already unlocked".
  ///
  void lockSync(
      [FileLock mode = FileLock.exclusive, int start = 0, int end = -1]);

  /// Unlocks the file or part of the file.
  ///
  /// Unlocks the byte range from [start] to [end] of the file, with
  /// the byte at position `end` not included. If no arguments are
  /// specified, the full file is unlocked, If only `start` is
  /// specified the file is unlocked from byte position `start` to the
  /// end of the file.
  ///
  /// *NOTE* file locking does have slight differences in behavior across
  /// platforms:
  ///
  /// See [lock] for more details.
  Future<RandomAccessFile> unlock([int start = 0, int end = -1]);

  /// Synchronously unlocks the file or part of the file.
  ///
  /// Unlocks the byte range from [start] to [end] of the file, with
  /// the byte at position `end` not included. If no arguments are
  /// specified, the full file is unlocked, If only `start` is
  /// specified the file is unlocked from byte position `start` to the
  /// end of the file.
  ///
  /// *NOTE* file locking does have slight differences in behavior across
  /// platforms:
  ///
  /// See [lockSync] for more details.
  void unlockSync([int start = 0, int end = -1]);

  /// Returns a human-readable string for this random access file.
  String toString();

  /// The path of the file underlying this random access file.
  String get path;
}

/// Exception thrown when a file operation fails.
@pragma("vm:entry-point")
class FileSystemException implements IOException {
  /// Message describing the error.
  ///
  /// The message does not include any detailed information from
  /// the underlying OS error. Check [osError] for that information.
  final String message;

  /// The file system path on which the error occurred.
  ///
  /// Can be `null` if the exception does not relate directly
  /// to a file system path.
  final String? path;

  /// The underlying OS error.
  ///
  /// Can be `null` if the exception is not raised due to an OS error.
  final OSError? osError;

  /// Creates a new file system exception with optional parts.
  ///
  /// Creates an exception with [FileSystemException.message],
  /// [FileSystemException.path] and [FileSystemException.osError]
  /// values take from the optional parameters of the same name.
  ///
  /// The [message] and [path] path defaults to empty strings if omitted,
  /// and [osError] defaults to `null`.
  @pragma("vm:entry-point")
  const FileSystemException([this.message = "", this.path = "", this.osError]);

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("FileSystemException");
    if (message.isNotEmpty) {
      sb.write(": $message");
      if (path != null) {
        sb.write(", path = '$path'");
      }
      if (osError != null) {
        sb.write(" ($osError)");
      }
    } else if (osError != null) {
      sb.write(": $osError");
      if (path != null) {
        sb.write(", path = '$path'");
      }
    } else if (path != null) {
      sb.write(": $path");
    }
    return sb.toString();
  }
}
