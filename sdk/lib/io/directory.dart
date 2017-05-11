// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:io";

/**
 * A reference to a directory (or _folder_) on the file system.
 *
 * A Directory instance is an object holding a [path] on which operations can
 * be performed. The path to the directory can be [absolute] or relative.
 * You can get the parent directory using the getter [parent],
 * a property inherited from [FileSystemEntity].
 *
 * In addition to being used as an instance to access the file system,
 * Directory has a number of static properties, such as [systemTemp],
 * which gets the system's temporary directory, and the getter and setter
 * [current], which you can use to access or change the current directory.
 *
 * Create a new Directory object with a pathname to access the specified
 * directory on the file system from your program.
 *
 *     var myDir = new Directory('myDir');
 *
 * Most methods in this class occur in synchronous and asynchronous pairs,
 * for example, [create] and [createSync].
 * Unless you have a specific reason for using the synchronous version
 * of a method, prefer the asynchronous version to avoid blocking your program.
 *
 * ## Create a directory
 *
 * The following code sample creates a directory using the [create] method.
 * By setting the `recursive` parameter to true, you can create the
 * named directory and all its necessary parent directories,
 * if they do not already exist.
 *
 *     import 'dart:io';
 *
 *     void main() {
 *       // Creates dir/ and dir/subdir/.
 *       new Directory('dir/subdir').create(recursive: true)
 *         // The created directory is returned as a Future.
 *         .then((Directory directory) {
 *           print(directory.path);
 *       });
 *     }
 *
 * ## List a directory
 *
 * Use the [list] or [listSync] methods to get the files and directories
 * contained by a directory.
 * Set `recursive` to true to recursively list all subdirectories.
 * Set `followLinks` to true to follow symbolic links.
 * The list method returns a [Stream] that provides FileSystemEntity
 * objects. Use the listen callback function to process each object
 * as it become available.
 *
 *     import 'dart:io';
 *
 *     void main() {
 *       // Get the system temp directory.
 *       var systemTempDir = Directory.systemTemp;
 *
 *       // List directory contents, recursing into sub-directories,
 *       // but not following symbolic links.
 *       systemTempDir.list(recursive: true, followLinks: false)
 *         .listen((FileSystemEntity entity) {
 *           print(entity.path);
 *         });
 *     }
 *
 * ## The use of Futures
 *
 * I/O operations can block a program for some period of time while it waits for
 * the operation to complete. To avoid this, all
 * methods involving I/O have an asynchronous variant which returns a [Future].
 * This future completes when the I/O operation finishes. While the I/O
 * operation is in progress, the Dart program is not blocked,
 * and can perform other operations.
 *
 * For example,
 * the [exists] method, which determines whether the directory exists,
 * returns a boolean value using a Future.
 * Use `then` to register a callback function, which is called when
 * the value is ready.
 *
 *     import 'dart:io';
 *
 *     main() {
 *       final myDir = new Directory('dir');
 *       myDir.exists().then((isThere) {
 *         isThere ? print('exists') : print('non-existent');
 *       });
 *     }
 *
 *
 * In addition to exists, the [stat], [rename], and
 * other methods, return Futures.
 *
 * ## Other resources
 *
 * * [Dart by Example](https://www.dartlang.org/dart-by-example/#files-directories-and-symlinks)
 *   provides additional task-oriented code samples that show how to use
 *   various API from the Directory class and the related [File] class.
 *
 * * [I/O for Command-Line
 *   Apps](https://www.dartlang.org/docs/dart-up-and-running/ch03.html#dartio---io-for-command-line-apps)
 *   a section from _A Tour of the Dart Libraries_ covers files and directories.
 *
 * * [Write Command-Line Apps](https://www.dartlang.org/docs/tutorials/cmdline/),
 *   a tutorial about writing command-line apps, includes information about
 *   files and directories.
 */
abstract class Directory implements FileSystemEntity {
  /**
   * Gets the path of this directory.
   */
  final String path;

  /**
   * Creates a [Directory] object.
   *
   * If [path] is a relative path, it will be interpreted relative to the
   * current working directory (see [Directory.current]), when used.
   *
   * If [path] is an absolute path, it will be immune to changes to the
   * current working directory.
   */
  factory Directory(String path) => new _Directory(path);

  /**
   * Create a Directory object from a URI.
   *
   * If [uri] cannot reference a directory this throws [UnsupportedError].
   */
  factory Directory.fromUri(Uri uri) => new Directory(uri.toFilePath());

  /**
   * Creates a directory object pointing to the current working
   * directory.
   */
  static Directory get current => _Directory.current;

  /**
   * Returns a [Uri] representing the directory's location.
   *
   * The returned URI's scheme is always "file" if the entity's [path] is
   * absolute, otherwise the scheme will be empty.
   * The returned URI's path always ends in a slash ('/').
   */
  Uri get uri;

  /**
   * Sets the current working directory of the Dart process including
   * all running isolates. The new value set can be either a [Directory]
   * or a [String].
   *
   * The new value is passed to the OS's system call unchanged, so a
   * relative path passed as the new working directory will be
   * resolved by the OS.
   *
   * Note that setting the current working directory is a synchronous
   * operation and that it changes the working directory of *all*
   * isolates.
   *
   * Use this with care - especially when working with asynchronous
   * operations and multiple isolates. Changing the working directory,
   * while asynchronous operations are pending or when other isolates
   * are working with the file system, can lead to unexpected results.
   */
  static void set current(path) {
    _Directory.current = path;
  }

  /**
   * Creates the directory with this name.
   *
   * If [recursive] is false, only the last directory in the path is
   * created. If [recursive] is true, all non-existing path components
   * are created. If the directory already exists nothing is done.
   *
   * Returns a [:Future<Directory>:] that completes with this
   * directory once it has been created. If the directory cannot be
   * created the future completes with an exception.
   */
  Future<Directory> create({bool recursive: false});

  /**
   * Synchronously creates the directory with this name.
   *
   * If [recursive] is false, only the last directory in the path is
   * created. If [recursive] is true, all non-existing path components
   * are created. If the directory already exists nothing is done.
   *
   * If the directory cannot be created an exception is thrown.
   */
  void createSync({bool recursive: false});

  /**
   * Gets the system temp directory.
   *
   * Gets the directory provided by the operating system for creating
   * temporary files and directories in.
   * The location of the system temp directory is platform-dependent,
   * and may be set by an environment variable.
   */
  static Directory get systemTemp => _Directory.systemTemp;

  /**
   * Creates a temporary directory in this directory. Additional random
   * characters are appended to [prefix] to produce a unique directory
   * name. If [prefix] is missing or null, the empty string is used
   * for [prefix].
   *
   * Returns a [:Future<Directory>:] that completes with the newly
   * created temporary directory.
   */
  Future<Directory> createTemp([String prefix]);

  /**
   * Synchronously creates a temporary directory in this directory.
   * Additional random characters are appended to [prefix] to produce
   * a unique directory name. If [prefix] is missing or null, the empty
   * string is used for [prefix].
   *
   * Returns the newly created temporary directory.
   */
  Directory createTempSync([String prefix]);

  Future<String> resolveSymbolicLinks();

  String resolveSymbolicLinksSync();

  /**
   * Renames this directory. Returns a [:Future<Directory>:] that completes
   * with a [Directory] instance for the renamed directory.
   *
   * If newPath identifies an existing directory, that directory is
   * replaced. If newPath identifies an existing file, the operation
   * fails and the future completes with an exception.
   */
  Future<Directory> rename(String newPath);

  /**
   * Synchronously renames this directory. Returns a [Directory]
   * instance for the renamed directory.
   *
   * If newPath identifies an existing directory, that directory is
   * replaced. If newPath identifies an existing file the operation
   * fails and an exception is thrown.
   */
  Directory renameSync(String newPath);

  /**
   * Returns a [Directory] instance whose path is the absolute path to [this].
   *
   * The absolute path is computed by prefixing
   * a relative path with the current working directory, and returning
   * an absolute path unchanged.
   */
  Directory get absolute;

  /**
   * Lists the sub-directories and files of this [Directory].
   * Optionally recurses into sub-directories.
   *
   * If [followLinks] is false, then any symbolic links found
   * are reported as [Link] objects, rather than as directories or files,
   * and are not recursed into.
   *
   * If [followLinks] is true, then working links are reported as
   * directories or files, depending on
   * their type, and links to directories are recursed into.
   * Broken links are reported as [Link] objects.
   * If a symbolic link makes a loop in the file system, then a recursive
   * listing will not follow a link twice in the
   * same recursive descent, but will report it as a [Link]
   * the second time it is seen.
   *
   * The result is a stream of [FileSystemEntity] objects
   * for the directories, files, and links.
   */
  Stream<FileSystemEntity> list(
      {bool recursive: false, bool followLinks: true});

  /**
   * Lists the sub-directories and files of this [Directory].
   * Optionally recurses into sub-directories.
   *
   * If [followLinks] is false, then any symbolic links found
   * are reported as [Link] objects, rather than as directories or files,
   * and are not recursed into.
   *
   * If [followLinks] is true, then working links are reported as
   * directories or files, depending on
   * their type, and links to directories are recursed into.
   * Broken links are reported as [Link] objects.
   * If a link makes a loop in the file system, then a recursive
   * listing will not follow a link twice in the
   * same recursive descent, but will report it as a [Link]
   * the second time it is seen.
   *
   * Returns a [List] containing [FileSystemEntity] objects for the
   * directories, files, and links.
   */
  List<FileSystemEntity> listSync(
      {bool recursive: false, bool followLinks: true});

  /**
   * Returns a human readable string for this Directory instance.
   */
  String toString();
}
