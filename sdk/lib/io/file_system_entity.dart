// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

/**
 * The type of an entity on the file system, such as a file, directory, or link.
 *
 * These constants are used by the [FileSystemEntity] class
 * to indicate the object's type.
 *
 */

class FileSystemEntityType {
  static const file = const FileSystemEntityType._internal(0);
  @Deprecated("Use file instead")
  static const FILE = file;

  static const directory = const FileSystemEntityType._internal(1);
  @Deprecated("Use directory instead")
  static const DIRECTORY = directory;

  static const link = const FileSystemEntityType._internal(2);
  @Deprecated("Use link instead")
  static const LINK = link;

  static const notFound = const FileSystemEntityType._internal(3);
  @Deprecated("Use notFound instead")
  static const NOT_FOUND = notFound;

  static const _typeList = const [
    FileSystemEntityType.file,
    FileSystemEntityType.directory,
    FileSystemEntityType.link,
    FileSystemEntityType.notFound,
  ];
  final int _type;

  const FileSystemEntityType._internal(this._type);

  static FileSystemEntityType _lookup(int type) => _typeList[type];
  String toString() => const ['file', 'directory', 'link', 'notFound'][_type];
}

/**
 * A FileStat object represents the result of calling the POSIX stat() function
 * on a file system object.  It is an immutable object, representing the
 * snapshotted values returned by the stat() call.
 */
class FileStat {
  // These must agree with enum FileStat in file.h.
  static const _type = 0;
  static const _changedTime = 1;
  static const _modifiedTime = 2;
  static const _accessedTime = 3;
  static const _mode = 4;
  static const _size = 5;

  static const _notFound = const FileStat._internalNotFound();

  /**
   * The time of the last change to the data or metadata of the file system
   * object.
   *
   * On Windows platforms, this is instead the file creation time.
   */
  final DateTime changed;

  /**
   * The time of the last change to the data of the file system object.
   */
  final DateTime modified;

  /**
   * The time of the last access to the data of the file system object.
   *
   * On Windows platforms, this may have 1 day granularity, and be
   * out of date by an hour.
   */
  final DateTime accessed;

  /**
   * The type of the object (file, directory, or link).
   *
   * If the call to stat() fails, the type of the returned object is notFound.
   */
  final FileSystemEntityType type;

  /**
   * The mode of the file system object.
   *
   * Permissions are encoded in the lower 16 bits of this number, and can be
   * decoded using the [modeString] getter.
   */
  final int mode;

  /**
   * The size of the file system object.
   */
  final int size;

  FileStat._internal(this.changed, this.modified, this.accessed, this.type,
      this.mode, this.size);

  const FileStat._internalNotFound()
      : changed = null,
        modified = null,
        accessed = null,
        type = FileSystemEntityType.notFound,
        mode = 0,
        size = -1;

  external static _statSync(_Namespace namespace, String path);

  /**
   * Calls the operating system's stat() function on [path].
   *
   * Returns a [FileStat] object containing the data returned by stat().
   * If the call fails, returns a [FileStat] object with .type set to
   * FileSystemEntityType.notFound and the other fields invalid.
   */
  static FileStat statSync(String path) {
    final IOOverrides overrides = IOOverrides.current;
    if (overrides == null) {
      return _statSyncInternal(path);
    }
    return overrides.statSync(path);
  }

  static FileStat _statSyncInternal(String path) {
    // Trailing path is not supported on Windows.
    if (Platform.isWindows) {
      path = FileSystemEntity._trimTrailingPathSeparators(path);
    }
    var data = _statSync(_Namespace._namespace, path);
    if (data is OSError) return FileStat._notFound;
    return new FileStat._internal(
        new DateTime.fromMillisecondsSinceEpoch(data[_changedTime]),
        new DateTime.fromMillisecondsSinceEpoch(data[_modifiedTime]),
        new DateTime.fromMillisecondsSinceEpoch(data[_accessedTime]),
        FileSystemEntityType._lookup(data[_type]),
        data[_mode],
        data[_size]);
  }

  /**
   * Asynchronously calls the operating system's stat() function on [path].
   *
   * Returns a Future which completes with a [FileStat] object containing
   * the data returned by stat(). If the call fails, completes the future with a
   * [FileStat] object with `.type` set to FileSystemEntityType.notFound and
   * the other fields invalid.
   */
  static Future<FileStat> stat(String path) {
    final IOOverrides overrides = IOOverrides.current;
    if (overrides == null) {
      return _stat(path);
    }
    return overrides.stat(path);
  }

  static Future<FileStat> _stat(String path) {
    // Trailing path is not supported on Windows.
    if (Platform.isWindows) {
      path = FileSystemEntity._trimTrailingPathSeparators(path);
    }
    return _File._dispatchWithNamespace(_IOService.fileStat, [null, path])
        .then((response) {
      if (_isErrorResponse(response)) {
        return FileStat._notFound;
      }
      // Unwrap the real list from the "I'm not an error" wrapper.
      List data = response[1];
      return new FileStat._internal(
          new DateTime.fromMillisecondsSinceEpoch(data[_changedTime]),
          new DateTime.fromMillisecondsSinceEpoch(data[_modifiedTime]),
          new DateTime.fromMillisecondsSinceEpoch(data[_accessedTime]),
          FileSystemEntityType._lookup(data[_type]),
          data[_mode],
          data[_size]);
    });
  }

  String toString() => """
FileStat: type $type
          changed $changed
          modified $modified
          accessed $accessed
          mode ${modeString()}
          size $size""";

  /**
   * Returns the mode value as a human-readable string.
   *
   * The string is in the format "rwxrwxrwx", reflecting the user, group, and
   * world permissions to read, write, and execute the file system object, with
   * "-" replacing the letter for missing permissions.  Extra permission bits
   * may be represented by prepending "(suid)", "(guid)", and/or "(sticky)" to
   * the mode string.
   */
  String modeString() {
    var permissions = mode & 0xFFF;
    var codes = const ['---', '--x', '-w-', '-wx', 'r--', 'r-x', 'rw-', 'rwx'];
    var result = [];
    if ((permissions & 0x800) != 0) result.add("(suid) ");
    if ((permissions & 0x400) != 0) result.add("(guid) ");
    if ((permissions & 0x200) != 0) result.add("(sticky) ");
    result
      ..add(codes[(permissions >> 6) & 0x7])
      ..add(codes[(permissions >> 3) & 0x7])
      ..add(codes[permissions & 0x7]);
    return result.join();
  }
}

/**
 * The common super class for [File], [Directory], and [Link] objects.
 *
 * [FileSystemEntity] objects are returned from directory listing
 * operations. To determine if a FileSystemEntity is a [File], a
 * [Directory], or a [Link] perform a type check:
 *
 *     if (entity is File) (entity as File).readAsStringSync();
 *
 * You can also use the [type] or [typeSync] methods to determine
 * the type of a file system object.
 *
 * Most methods in this class occur in synchronous and asynchronous pairs,
 * for example, [exists] and [existsSync].
 * Unless you have a specific reason for using the synchronous version
 * of a method, prefer the asynchronous version to avoid blocking your program.
 *
 * Here's the exists method in action:
 *
 *     entity.exists().then((isThere) {
 *       isThere ? print('exists') : print('non-existent');
 *     });
 *
 *
 * ## Other resources
 *
 * * [Dart by
 *   Example](https://www.dartlang.org/dart-by-example/#files-directories-and-symlinks)
 *   provides additional task-oriented code samples that show how to use various
 *   API from the [Directory] class and the [File] class, both subclasses of
 *   FileSystemEntity.
 *
 * * [I/O for Command-Line
 *   Apps](https://www.dartlang.org/docs/dart-up-and-running/ch03.html#dartio---io-for-command-line-apps),
 *   a section from _A Tour of the Dart Libraries_ covers files and directories.
 *
 * * [Write Command-Line Apps](https://www.dartlang.org/docs/tutorials/cmdline/),
 *   a tutorial about writing command-line apps, includes information about
 *   files and directories.
 */
abstract class FileSystemEntity {
  String _path;
  Uint8List _rawPath;

  String get path;

  /**
   * Returns a [Uri] representing the file system entity's location.
   *
   * The returned URI's scheme is always "file" if the entity's [path] is
   * absolute, otherwise the scheme will be empty.
   */
  Uri get uri => new Uri.file(path);

  /**
   * Checks whether the file system entity with this path exists. Returns
   * a [:Future<bool>:] that completes with the result.
   *
   * Since FileSystemEntity is abstract, every FileSystemEntity object
   * is actually an instance of one of the subclasses [File],
   * [Directory], and [Link].  Calling [exists] on an instance of one
   * of these subclasses checks whether the object exists in the file
   * system object exists and is of the correct type (file, directory,
   * or link).  To check whether a path points to an object on the
   * file system, regardless of the object's type, use the [type]
   * static method.
   *
   */
  Future<bool> exists();

  /**
   * Synchronously checks whether the file system entity with this path
   * exists.
   *
   * Since FileSystemEntity is abstract, every FileSystemEntity object
   * is actually an instance of one of the subclasses [File],
   * [Directory], and [Link].  Calling [existsSync] on an instance of
   * one of these subclasses checks whether the object exists in the
   * file system object exists and is of the correct type (file,
   * directory, or link).  To check whether a path points to an object
   * on the file system, regardless of the object's type, use the
   * [typeSync] static method.
   */
  bool existsSync();

  /**
   * Renames this file system entity.
   *
   * Returns a `Future<FileSystemEntity>` that completes with a
   * [FileSystemEntity] instance for the renamed file system entity.
   *
   * If [newPath] identifies an existing entity of the same type, that entity
   * is replaced. If [newPath] identifies an existing entity of a different
   * type, the operation fails and the future completes with an exception.
   */
  Future<FileSystemEntity> rename(String newPath);

  /**
   * Synchronously renames this file system entity.
   *
   * Returns a [FileSystemEntity] instance for the renamed entity.
   *
   * If [newPath] identifies an existing entity of the same type, that entity
   * is replaced. If [newPath] identifies an existing entity of a different
   * type, the operation fails and an exception is thrown.
   */
  FileSystemEntity renameSync(String newPath);

  /**
   * Resolves the path of a file system object relative to the
   * current working directory.
   *
   * Resolves all symbolic links on the path and resolves all `..` and `.` path
   * segments.
   *
   * [resolveSymbolicLinks] uses the operating system's native
   * file system API to resolve the path, using the `realpath` function
   * on linux and OS X, and the `GetFinalPathNameByHandle` function on
   * Windows. If the path does not point to an existing file system object,
   * `resolveSymbolicLinks` throws a `FileSystemException`.
   *
   * On Windows the `..` segments are resolved _before_ resolving the symbolic
   * link, and on other platforms the symbolic links are _resolved to their
   * target_ before applying a `..` that follows.
   *
   * To ensure the same behavior on all platforms resolve `..` segments before
   * calling `resolveSymbolicLinks`. One way of doing this is with the `Uri`
   * class:
   *
   *     var path = Uri.parse('.').resolveUri(new Uri.file(input)).toFilePath();
   *     if (path == '') path = '.';
   *     new File(path).resolveSymbolicLinks().then((resolved) {
   *       print(resolved);
   *     });
   *
   * since `Uri.resolve` removes `..` segments. This will result in the Windows
   * behavior.
   */
  Future<String> resolveSymbolicLinks() {
    return _File._dispatchWithNamespace(
        _IOService.fileResolveSymbolicLinks, [null, _rawPath]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(
            response, "Cannot resolve symbolic links", path);
      }
      return response;
    });
  }

  /**
   * Resolves the path of a file system object relative to the
   * current working directory.
   *
   * Resolves all symbolic links on the path and resolves all `..` and `.` path
   * segments.
   *
   * [resolveSymbolicLinksSync] uses the operating system's native
   * file system API to resolve the path, using the `realpath` function
   * on linux and OS X, and the `GetFinalPathNameByHandle` function on
   * Windows. If the path does not point to an existing file system object,
   * `resolveSymbolicLinksSync` throws a `FileSystemException`.
   *
   * On Windows the `..` segments are resolved _before_ resolving the symbolic
   * link, and on other platforms the symbolic links are _resolved to their
   * target_ before applying a `..` that follows.
   *
   * To ensure the same behavior on all platforms resolve `..` segments before
   * calling `resolveSymbolicLinksSync`. One way of doing this is with the `Uri`
   * class:
   *
   *     var path = Uri.parse('.').resolveUri(new Uri.file(input)).toFilePath();
   *     if (path == '') path = '.';
   *     var resolved = new File(path).resolveSymbolicLinksSync();
   *     print(resolved);
   *
   * since `Uri.resolve` removes `..` segments. This will result in the Windows
   * behavior.
   */
  String resolveSymbolicLinksSync() {
    var result = _resolveSymbolicLinks(_Namespace._namespace, _rawPath);
    _throwIfError(result, "Cannot resolve symbolic links", path);
    return result;
  }

  /**
   * Calls the operating system's stat() function on the [path] of this
   * [FileSystemEntity].
   *
   * Identical to [:FileStat.stat(this.path):].
   *
   * Returns a [:Future<FileStat>:] object containing the data returned by
   * stat().
   *
   * If the call fails, completes the future with a [FileStat] object
   * with .type set to
   * FileSystemEntityType.notFound and the other fields invalid.
   */
  Future<FileStat> stat() => FileStat.stat(path);

  /**
   * Synchronously calls the operating system's stat() function on the
   * [path] of this [FileSystemEntity].
   *
   * Identical to [:FileStat.statSync(this.path):].
   *
   * Returns a [FileStat] object containing the data returned by stat().
   *
   * If the call fails, returns a [FileStat] object with .type set to
   * FileSystemEntityType.notFound and the other fields invalid.
   */
  FileStat statSync() => FileStat.statSync(path);

  /**
   * Deletes this [FileSystemEntity].
   *
   * If the [FileSystemEntity] is a directory, and if [recursive] is false,
   * the directory must be empty. Otherwise, if [recursive] is true, the
   * directory and all sub-directories and files in the directories are
   * deleted. Links are not followed when deleting recursively. Only the link
   * is deleted, not its target.
   *
   * If [recursive] is true, the [FileSystemEntity] is deleted even if the type
   * of the [FileSystemEntity] doesn't match the content of the file system.
   * This behavior allows [delete] to be used to unconditionally delete any file
   * system object.
   *
   * Returns a [:Future<FileSystemEntity>:] that completes with this
   * [FileSystemEntity] when the deletion is done. If the [FileSystemEntity]
   * cannot be deleted, the future completes with an exception.
   */
  Future<FileSystemEntity> delete({bool recursive: false}) =>
      _delete(recursive: recursive);

  /**
   * Synchronously deletes this [FileSystemEntity].
   *
   * If the [FileSystemEntity] is a directory, and if [recursive] is false,
   * the directory must be empty. Otherwise, if [recursive] is true, the
   * directory and all sub-directories and files in the directories are
   * deleted. Links are not followed when deleting recursively. Only the link
   * is deleted, not its target.
   *
   * If [recursive] is true, the [FileSystemEntity] is deleted even if the type
   * of the [FileSystemEntity] doesn't match the content of the file system.
   * This behavior allows [deleteSync] to be used to unconditionally delete any
   * file system object.
   *
   * Throws an exception if the [FileSystemEntity] cannot be deleted.
   */
  void deleteSync({bool recursive: false}) => _deleteSync(recursive: recursive);

  /**
   * Start watching the [FileSystemEntity] for changes.
   *
   * The implementation uses platform-dependent event-based APIs for receiving
   * file-system notifications, thus behavior depends on the platform.
   *
   *   * `Windows`: Uses `ReadDirectoryChangesW`. The implementation only
   *     supports watching directories. Recursive watching is supported.
   *   * `Linux`: Uses `inotify`. The implementation supports watching both
   *     files and directories. Recursive watching is not supported.
   *     Note: When watching files directly, delete events might not happen
   *     as expected.
   *   * `OS X`: Uses `FSEvents`. The implementation supports watching both
   *     files and directories. Recursive watching is supported.
   *
   * The system will start listening for events once the returned [Stream] is
   * being listened to, not when the call to [watch] is issued.
   *
   * The returned value is an endless broadcast [Stream], that only stops when
   * one of the following happens:
   *
   *   * The [Stream] is canceled, e.g. by calling `cancel` on the
   *      [StreamSubscription].
   *   * The [FileSystemEntity] being watches, is deleted.
   *
   * Use `events` to specify what events to listen for. The constants in
   * [FileSystemEvent] can be or'ed together to mix events. Default is
   * [FileSystemEvent.ALL].
   *
   * A move event may be reported as seperate delete and create events.
   */
  Stream<FileSystemEvent> watch(
      {int events: FileSystemEvent.all, bool recursive: false}) {
    // FIXME(bkonyi): find a way to do this using the raw path.
    final String trimmedPath = _trimTrailingPathSeparators(path);
    final IOOverrides overrides = IOOverrides.current;
    if (overrides == null) {
      return _FileSystemWatcher._watch(trimmedPath, events, recursive);
    }
    return overrides.fsWatch(trimmedPath, events, recursive);
  }

  Future<FileSystemEntity> _delete({bool recursive: false});
  void _deleteSync({bool recursive: false});

  static Future<bool> _identical(String path1, String path2) {
    return _File._dispatchWithNamespace(
        _IOService.fileIdentical, [null, path1, path2]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response,
            "Error in FileSystemEntity.identical($path1, $path2)", "");
      }
      return response;
    });
  }

  /**
   * Checks whether two paths refer to the same object in the
   * file system.
   *
   * Returns a [:Future<bool>:] that completes with the result.
   *
   * Comparing a link to its target returns false, as does comparing two links
   * that point to the same target.  To check the target of a link, use
   * Link.target explicitly to fetch it.  Directory links appearing
   * inside a path are followed, though, to find the file system object.
   *
   * Completes the returned Future with an error if one of the paths points
   * to an object that does not exist.
   */
  static Future<bool> identical(String path1, String path2) {
    IOOverrides overrides = IOOverrides.current;
    if (overrides == null) {
      return _identical(path1, path2);
    }
    return overrides.fseIdentical(path1, path2);
  }

  static final RegExp _absoluteWindowsPathPattern =
      new RegExp(r'^(\\\\|[a-zA-Z]:[/\\])');

  /**
   * Returns a [bool] indicating whether this object's path is absolute.
   *
   * On Windows, a path is absolute if it starts with \\\\ or a drive letter
   * between a and z (upper or lower case) followed by :\\ or :/.
   * On non-Windows, a path is absolute if it starts with /.
   */
  bool get isAbsolute {
    if (Platform.isWindows) {
      return path.startsWith(_absoluteWindowsPathPattern);
    } else {
      return path.startsWith('/');
    }
  }

  /**
   * Returns a [FileSystemEntity] whose path is the absolute path to [this].
   *
   * The type of the returned instance is the type of [this].
   *
   * The absolute path is computed by prefixing
   * a relative path with the current working directory, and returning
   * an absolute path unchanged.
   */
  FileSystemEntity get absolute;

  String get _absolutePath {
    if (isAbsolute) return path;
    String current = Directory.current.path;
    if (current.endsWith('/') ||
        (Platform.isWindows && current.endsWith('\\'))) {
      return '$current$path';
    } else {
      return '$current${Platform.pathSeparator}$path';
    }
  }

  Uint8List get _rawAbsolutePath {
    if (isAbsolute) return _rawPath;
    var current = Directory.current._rawPath.toList();
    assert(current.last == 0);
    current.removeLast(); // Remove null terminator.
    if ((current.last == '/'.codeUnitAt(0)) ||
        (Platform.isWindows && (current.last == '\\'.codeUnitAt(0)))) {
      current.addAll(_rawPath);
      return new Uint8List.fromList(current);
    } else {
      current.addAll(utf8.encode(Platform.pathSeparator));
      current.addAll(_rawPath);
      return new Uint8List.fromList(current);
    }
  }

  static bool _identicalSync(String path1, String path2) {
    var result = _identicalNative(_Namespace._namespace, path1, path2);
    _throwIfError(result, 'Error in FileSystemEntity.identicalSync');
    return result;
  }

  /**
   * Synchronously checks whether two paths refer to the same object in the
   * file system.
   *
   * Comparing a link to its target returns false, as does comparing two links
   * that point to the same target.  To check the target of a link, use
   * Link.target explicitly to fetch it.  Directory links appearing
   * inside a path are followed, though, to find the file system object.
   *
   * Throws an error if one of the paths points to an object that does not
   * exist.
   */
  static bool identicalSync(String path1, String path2) {
    IOOverrides overrides = IOOverrides.current;
    if (overrides == null) {
      return _identicalSync(path1, path2);
    }
    return overrides.fseIdenticalSync(path1, path2);
  }

  /**
   * Test if [watch] is supported on the current system.
   *
   * OS X 10.6 and below is not supported.
   */
  static bool get isWatchSupported {
    final IOOverrides overrides = IOOverrides.current;
    if (overrides == null) {
      return _FileSystemWatcher.isSupported;
    }
    return overrides.fsWatchIsSupported();
  }

  // The native methods which determine type of the FileSystemEntity require
  // that the buffer provided is null terminated.
  static Uint8List _toUtf8Array(String s) =>
      _toNullTerminatedUtf8Array(utf8.encode(s));

  static Uint8List _toNullTerminatedUtf8Array(Uint8List l) {
    if (l == null) {
      return null;
    }
    if (l.isNotEmpty && l.last != 0) {
      final tmp = new Uint8List(l.length + 1);
      tmp.setRange(0, l.length, l);
      return tmp;
    } else {
      return l;
    }
  }

  static String _toStringFromUtf8Array(Uint8List l) {
    if (l == null) {
      return '';
    }
    Uint8List nonNullTerminated = l;
    if (l.last == 0) {
      nonNullTerminated = new Uint8List.view(l.buffer, 0, l.length - 1);
    }
    return utf8.decode(nonNullTerminated, allowMalformed: true);
  }

  /**
   * Finds the type of file system object that a path points to.
   *
   * Returns a [:Future<FileSystemEntityType>:] that completes with the result.
   *
   * [FileSystemEntityType] has the constant instances file, directory,
   * link, and notFound.  [type] will return link only if the optional
   * named argument [followLinks] is false, and [path] points to a link.
   * If the path does not point to a file system object, or any other error
   * occurs in looking up the path, notFound is returned.  The only
   * error or exception that may be put on the returned future is ArgumentError,
   * caused by passing the wrong type of arguments to the function.
   */
  static Future<FileSystemEntityType> type(String path,
      {bool followLinks: true}) {
    return _getType(_toUtf8Array(path), followLinks);
  }

  /**
   * Synchronously finds the type of file system object that a path points to.
   *
   * Returns a [FileSystemEntityType].
   *
   * [FileSystemEntityType] has the constant instances file, directory,
   * link, and notFound.  [type] will return link only if the optional
   * named argument [followLinks] is false, and [path] points to a link.
   * If the path does not point to a file system object, or any other error
   * occurs in looking up the path, notFound is returned.  The only
   * error or exception that may be thrown is ArgumentError,
   * caused by passing the wrong type of arguments to the function.
   */
  static FileSystemEntityType typeSync(String path, {bool followLinks: true}) {
    return _getTypeSync(_toUtf8Array(path), followLinks);
  }

  /**
   * Checks if type(path, followLinks: false) returns FileSystemEntityType.link.
   */
  static Future<bool> isLink(String path) => _isLinkRaw(_toUtf8Array(path));

  static Future<bool> _isLinkRaw(Uint8List rawPath) => _getType(rawPath, false)
      .then((type) => (type == FileSystemEntityType.link));

  /**
   * Checks if type(path) returns FileSystemEntityType.file.
   */
  static Future<bool> isFile(String path) => _getType(_toUtf8Array(path), true)
      .then((type) => (type == FileSystemEntityType.file));

  /**
   * Checks if type(path) returns FileSystemEntityType.directory.
   */
  static Future<bool> isDirectory(String path) =>
      _getType(_toUtf8Array(path), true)
          .then((type) => (type == FileSystemEntityType.directory));

  /**
   * Synchronously checks if typeSync(path, followLinks: false) returns
   * FileSystemEntityType.link.
   */
  static bool isLinkSync(String path) => _isLinkRawSync(_toUtf8Array(path));

  static bool _isLinkRawSync(rawPath) =>
      (_getTypeSync(rawPath, false) == FileSystemEntityType.link);

  /**
   * Synchronously checks if typeSync(path) returns
   * FileSystemEntityType.file.
   */
  static bool isFileSync(String path) =>
      (_getTypeSync(_toUtf8Array(path), true) == FileSystemEntityType.file);

  /**
   * Synchronously checks if typeSync(path) returns
   * FileSystemEntityType.directory.
   */
  static bool isDirectorySync(String path) =>
      (_getTypeSync(_toUtf8Array(path), true) ==
          FileSystemEntityType.directory);

  external static _getTypeNative(
      _Namespace namespace, Uint8List rawPath, bool followLinks);
  external static _identicalNative(
      _Namespace namespace, String path1, String path2);
  external static _resolveSymbolicLinks(_Namespace namespace, Uint8List path);

  // Finds the next-to-last component when dividing at path separators.
  static final RegExp _parentRegExp = Platform.isWindows
      ? new RegExp(r'[^/\\][/\\]+[^/\\]')
      : new RegExp(r'[^/]/+[^/]');

  /**
   * Removes the final path component of a path, using the platform's
   * path separator to split the path.
   *
   * Will not remove the root component of a Windows path, like "C:\\" or
   * "\\\\server_name\\". Ignores trailing path separators, and leaves no
   * trailing path separators.
   */
  static String parentOf(String path) {
    int rootEnd = -1;
    if (Platform.isWindows) {
      if (path.startsWith(_absoluteWindowsPathPattern)) {
        // Root ends at first / or \ after the first two characters.
        rootEnd = path.indexOf(new RegExp(r'[/\\]'), 2);
        if (rootEnd == -1) return path;
      } else if (path.startsWith('\\') || path.startsWith('/')) {
        rootEnd = 0;
      }
    } else if (path.startsWith('/')) {
      rootEnd = 0;
    }
    // Ignore trailing slashes.
    // All non-trivial cases have separators between two non-separators.
    int pos = path.lastIndexOf(_parentRegExp);
    if (pos > rootEnd) {
      return path.substring(0, pos + 1);
    } else if (rootEnd > -1) {
      return path.substring(0, rootEnd + 1);
    } else {
      return '.';
    }
  }

  /**
   * The directory containing [this].
   */
  Directory get parent => new Directory(parentOf(path));

  static FileSystemEntityType _getTypeSyncHelper(
      Uint8List rawPath, bool followLinks) {
    var result = _getTypeNative(_Namespace._namespace, rawPath, followLinks);
    _throwIfError(result, 'Error getting type of FileSystemEntity');
    return FileSystemEntityType._lookup(result);
  }

  static FileSystemEntityType _getTypeSync(
      Uint8List rawPath, bool followLinks) {
    IOOverrides overrides = IOOverrides.current;
    if (overrides == null) {
      return _getTypeSyncHelper(rawPath, followLinks);
    }
    return overrides.fseGetTypeSync(
        utf8.decode(rawPath, allowMalformed: true), followLinks);
  }

  static Future<FileSystemEntityType> _getTypeRequest(
      Uint8List rawPath, bool followLinks) {
    return _File._dispatchWithNamespace(
        _IOService.fileType, [null, rawPath, followLinks]).then((response) {
      if (_isErrorResponse(response)) {
        throw _exceptionFromResponse(response, "Error getting type",
            utf8.decode(rawPath, allowMalformed: true));
      }
      return FileSystemEntityType._lookup(response);
    });
  }

  static Future<FileSystemEntityType> _getType(
      Uint8List rawPath, bool followLinks) {
    IOOverrides overrides = IOOverrides.current;
    if (overrides == null) {
      return _getTypeRequest(rawPath, followLinks);
    }
    return overrides.fseGetType(
        utf8.decode(rawPath, allowMalformed: true), followLinks);
  }

  static _throwIfError(Object result, String msg, [String path]) {
    if (result is OSError) {
      throw new FileSystemException(msg, path, result);
    } else if (result is ArgumentError) {
      throw result;
    }
  }

  // TODO(bkonyi): find a way to do this with raw paths.
  static String _trimTrailingPathSeparators(String path) {
    // Don't handle argument errors here.
    if (path == null) return path;
    if (Platform.isWindows) {
      while (path.length > 1 &&
          (path.endsWith(Platform.pathSeparator) || path.endsWith('/'))) {
        path = path.substring(0, path.length - 1);
      }
    } else {
      while (path.length > 1 && path.endsWith(Platform.pathSeparator)) {
        path = path.substring(0, path.length - 1);
      }
    }
    return path;
  }

  // TODO(bkonyi): find a way to do this with raw paths.
  static String _ensureTrailingPathSeparators(String path) {
    // Don't handle argument errors here.
    if (path == null) return path;
    if (path.isEmpty) path = '.';
    if (Platform.isWindows) {
      while (!path.endsWith(Platform.pathSeparator) && !path.endsWith('/')) {
        path = "$path${Platform.pathSeparator}";
      }
    } else {
      while (!path.endsWith(Platform.pathSeparator)) {
        path = "$path${Platform.pathSeparator}";
      }
    }
    return path;
  }
}

/**
 * Base event class emitted by [FileSystemEntity.watch].
 */
class FileSystemEvent {
  /**
   * Bitfield for [FileSystemEntity.watch], to enable [FileSystemCreateEvent]s.
   */
  static const int create = 1 << 0;
  @Deprecated("Use create instead")
  static const int CREATE = 1 << 0;

  /**
   * Bitfield for [FileSystemEntity.watch], to enable [FileSystemModifyEvent]s.
   */
  static const int modify = 1 << 1;
  @Deprecated("Use modify instead")
  static const int MODIFY = 1 << 1;

  /**
   * Bitfield for [FileSystemEntity.watch], to enable [FileSystemDeleteEvent]s.
   */
  static const int delete = 1 << 2;
  @Deprecated("Use delete instead")
  static const int DELETE = 1 << 2;

  /**
   * Bitfield for [FileSystemEntity.watch], to enable [FileSystemMoveEvent]s.
   */
  static const int move = 1 << 3;
  @Deprecated("Use move instead")
  static const int MOVE = 1 << 3;

  /**
   * Bitfield for [FileSystemEntity.watch], for enabling all of [create],
   * [modify], [delete] and [move].
   */
  static const int all = create | modify | delete | move;
  @Deprecated("Use all instead")
  static const int ALL = create | modify | delete | move;

  static const int _modifyAttributes = 1 << 4;
  static const int _deleteSelf = 1 << 5;
  static const int _isDir = 1 << 6;

  /**
   * The type of event. See [FileSystemEvent] for a list of events.
   */
  final int type;

  /**
   * The path that triggered the event.
   *
   * Depending on the platform and the FileSystemEntity, the path may be
   * relative.
   */
  final String path;

  /**
   * Is `true` if the event target was a directory.
   *
   * Note that if the file has been deleted by the time the event has arrived,
   * this will always be `false` on Windows. In particular, it will always be
   * `false` for `delete` events.
   */
  final bool isDirectory;

  FileSystemEvent._(this.type, this.path, this.isDirectory);
}

/**
 * File system event for newly created file system objects.
 */
class FileSystemCreateEvent extends FileSystemEvent {
  FileSystemCreateEvent._(path, isDirectory)
      : super._(FileSystemEvent.create, path, isDirectory);

  String toString() => "FileSystemCreateEvent('$path')";
}

/**
 * File system event for modifications of file system objects.
 */
class FileSystemModifyEvent extends FileSystemEvent {
  /**
   * If the content was changed and not only the attributes, [contentChanged]
   * is `true`.
   */
  final bool contentChanged;

  FileSystemModifyEvent._(path, isDirectory, this.contentChanged)
      : super._(FileSystemEvent.modify, path, isDirectory);

  String toString() =>
      "FileSystemModifyEvent('$path', contentChanged=$contentChanged)";
}

/**
 * File system event for deletion of file system objects.
 */
class FileSystemDeleteEvent extends FileSystemEvent {
  FileSystemDeleteEvent._(path, isDirectory)
      : super._(FileSystemEvent.delete, path, isDirectory);

  String toString() => "FileSystemDeleteEvent('$path')";
}

/**
 * File system event for moving of file system objects.
 */
class FileSystemMoveEvent extends FileSystemEvent {
  /**
   * If the underlying implementation is able to identify the destination of
   * the moved file, [destination] will be set. Otherwise, it will be `null`.
   */
  final String destination;

  FileSystemMoveEvent._(path, isDirectory, this.destination)
      : super._(FileSystemEvent.move, path, isDirectory);

  String toString() {
    var buffer = new StringBuffer();
    buffer.write("FileSystemMoveEvent('$path'");
    if (destination != null) buffer.write(", '$destination'");
    buffer.write(')');
    return buffer.toString();
  }
}

class _FileSystemWatcher {
  external static Stream<FileSystemEvent> _watch(
      String path, int events, bool recursive);
  external static bool get isSupported;
}
