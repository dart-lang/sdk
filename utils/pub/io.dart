// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Helper functionality to make working with IO easier.
 */
#library('pub_io');

#import('dart:io');

#import('../lib/file_system.dart', prefix: 'fs');

/** Gets the current working directory. */
String get workingDir() => new File('.').fullPathSync();

/**
 * Joins a number of path string parts into a single path. Handles
 * platform-specific path separators. Parts can be [String], [Directory], or
 * [File] objects.
 */
String join(part1, [part2, part3, part4]) {
  final parts = _getPath(part1).split('/');

  for (final part in [part2, part3, part4]) {
    if (part == null) continue;

    for (final piece in _getPath(part).split('/')) {
      if (piece == '..' && parts.length > 0 &&
          parts.last() != '.' && parts.last() != '..') {
        parts.removeLast();
      } else if (piece != '') {
        if (parts.length > 0 && parts.last() == '.') {
          parts.removeLast();
        }
        parts.add(piece);
      }
    }
  }

  return Strings.join(parts, Platform.pathSeparator());
}

/**
 * Gets the basename, the file name without any leading directory path, for
 * [file], which can either be a [String], [File], or [Directory].
 */
String basename(file) {
  return fs.basename(_getPath(file));
}

/**
 * Asynchronously determines if [file], which can be a [String] file path or a
 * [File], exists on the file system. Returns a [Future] that completes with
 * the result.
 */
Future<bool> fileExists(file) {
  final completer = new Completer<bool>();

  file = new File(_getPath(file));
  file.onError = (error) => completer.completeException(error);
  file.exists((exists) => completer.complete(exists));

  return completer.future;
}

/**
 * Reads the contents of the text file [file], which can either be a [String] or
 * a [File].
 */
Future<String> readTextFile(file) {
  file = new File(_getPath(file));
  final completer = new Completer<String>();
  file.onError = (error) => completer.completeException(error);
  file.readAsText(Encoding.UTF_8, (text) => completer.complete(text));

  return completer.future;
}

/**
 * Creates [file] (which can either be a [String] or a [File]), and writes
 * [contents] to it. Completes when the file is written and closed.
 */
Future<File> writeTextFile(file, String contents) {
  file = new File(_getPath(file));
  final completer = new Completer<File>();
  file.onError = (error) => completer.completeException(error);
  file.open(FileMode.WRITE, (opened) {
    opened.onError = (error) => completer.completeException(error);
    opened.onNoPendingWrites = () {
      opened.close(() => completer.complete(file));
    };
    opened.writeString(contents);
  });

  return completer.future;
}

/**
 * Creates a directory [dir]. Returns a [Future] that completes when the
 * directory is created.
 */
Future<Directory> createDir(dir) {
  final completer = new Completer<Directory>();
  dir = _getDirectory(dir);
  dir.onError = (error) => completer.completeException(error);
  dir.create(() => completer.complete(dir));

  return completer.future;
}

/**
 * Creates a temp directory whose name will be based on [dir] with a unique
 * suffix appended to it. Returns a [Future] that completes when the directory
 * is created.
 */
Future<Directory> createTempDir(dir) {
  final completer = new Completer<Directory>();
  dir = _getDirectory(dir);
  dir.onError = (error) => completer.completeException(error);
  dir.createTemp(() => completer.complete(dir));

  return completer.future;
}

/**
 * Asynchronously recursively deletes [dir], which can be a [String] or a
 * [Directory]. Returns a [Future] that completes when the deletion is done.
 */
Future<Directory> deleteDir(dir) {
  // TODO(rnystrom): Hack! Temporary! Right now, dart:io's Directory delete
  // method can't handle directories with symlinks, which is exactly what pub
  // creates and deletes. Instead, we'll just shell out to 'rm'. Remove this
  // when dartbug.com/2646 is fixed.
  dir = _getDirectory(dir);

  // Sanity check!
  if (dir.path == '/' ||
      dir.path == '.' ||
      dir.path == '..' ||
      dir.path == '~' ||
      dir.path == '*') throw "(O.o) I don't think you want to do that!";

  return runProcess('rm', ['-rf', dir.path]).transform((_) => dir);
  // End hack!

  // Real code:
  /*
  final completer = new Completer<Directory>();
  dir = _getDirectory(dir);
  dir.onError = (error) => completer.completeException(error);
  dir.deleteRecursively(() => completer.complete(dir));

  return completer.future;
  */
}

/**
 * Asynchronously lists the contents of [dir], which can be a [String] directory
 * path or a [Directory]. If [recursive] is `true`, lists subdirectory contents
 * (defaults to `false`). If [includeSpecialFiles] is `true`, includes
 * hidden `.DS_Store` files (defaults to `false`, other hidden files may be
 * omitted later).
 */
Future<List<String>> listDir(dir,
    [bool recursive = false, bool includeSpecialFiles = false]) {
  final completer = new Completer<List<String>>();
  final contents = <String>[];

  dir = _getDirectory(dir);

  dir.onDone = (done) {
    // TODO(rnystrom): May need to sort here if it turns out onDir and onFile
    // aren't guaranteed to be called in a certain order. So far, they seem to.
    if (done) completer.complete(contents);
  };

  dir.onError = (error) => completer.completeException(error);
  dir.onDir = (file) => contents.add(file);
  dir.onFile = (file) {
    if (!includeSpecialFiles) {
      if (basename(file) == '.DS_Store') return;
    }
    contents.add(file);
  };

  dir.list(recursive: recursive);

  return completer.future;
}

/**
 * Asynchronously determines if [dir], which can be a [String] directory path
 * or a [Directory], exists on the file system. Returns a [Future] that
 * completes with the result.
 */
Future<bool> dirExists(dir) {
  final completer = new Completer<bool>();

  dir = _getDirectory(dir);
  dir.onError = (error) => completer.completeException(error);
  dir.exists((exists) => completer.complete(exists));

  return completer.future;
}

/**
 * "Cleans" [dir]. If that directory already exists, it will be deleted. Then a
 * new empty directory will be created. Returns a [Future] that completes when
 * the new clean directory is created.
 */
Future<Directory> cleanDir(dir) {
  return dirExists(dir).chain((exists) {
    if (exists) {
      // Delete it first.
      return deleteDir(dir).chain((_) => createDir(dir));
    } else {
      // Just create it.
      return createDir(dir);
    }
  });
}

/**
 * Creates a new symlink that creates an alias from [from] to [to], both of
 * which can be a [String], [File], or [Directory]. Returns a [Future] which
 * completes to the symlink file (i.e. [to]).
 */
Future<File> createSymlink(from, to) {
  // TODO(rnystrom): What should this do on Windows?
  from = _getPath(from);
  to = _getPath(to);

  return runProcess('ln', ['-s', from, to]).transform((result) {
    // TODO(rnystrom): Check exit code and output?
    return new File(to);
  });
}

/**
 * Given [entry] which may be a [String], [File], or [Directory] relative to
 * the current working directory, returns its full canonicalized path.
 */
// TODO(rnystrom): Should this be async?
String getFullPath(entry) => new File(_getPath(entry)).fullPathSync();

/**
 * Spawns and runs the process located at [executable], passing in [args].
 * Returns a [Future] that will complete the results of the process after it
 * has ended.
 */
Future<ProcessResult> runProcess(String executable, List<String> args,
    [String workingDir]) {
  int exitCode;

  final options = new ProcessOptions();
  if (workingDir != null) options.workingDirectory = workingDir;

  final process = new Process.start(executable, args, options);

  final outStream = new StringInputStream(process.stdout);
  final processStdout = <String>[];

  final errStream = new StringInputStream(process.stderr);
  final processStderr = <String>[];

  final completer = new Completer<ProcessResult>();

  checkComplete() {
    // Wait until the process is done and its output streams are closed.
    if (!outStream.closed) return;
    if (!errStream.closed) return;
    if (exitCode == null) return;

    completer.complete(new ProcessResult(
        processStdout, processStderr, exitCode));
  }

  outStream.onLine   = () => processStdout.add(outStream.readLine());
  outStream.onClosed = checkComplete;
  outStream.onError  = (error) => completer.completeException(error);

  errStream.onLine   = () => processStderr.add(errStream.readLine());
  errStream.onClosed = checkComplete;
  errStream.onError  = (error) => completer.completeException(error);

  process.onExit = (actualExitCode) {
    exitCode = actualExitCode;
    checkComplete();
  };

  process.onError = (error) => completer.completeException(error);

  return completer.future;
}

/**
 * Contains the results of invoking a [Process] and waiting for it to complete.
 */
class ProcessResult {
  final List<String> stdout;
  final List<String> stderr;
  final int exitCode;

  const ProcessResult(this.stdout, this.stderr, this.exitCode);
}

/**
 * Gets the path string for [entry], which can either already be a path string,
 * or be a [File] or [Directory]. Allows working generically with "file-like"
 * objects.
 */
String _getPath(entry) {
  if (entry is String) return entry;
  if (entry is File) return entry.name;
  if (entry is Directory) return entry.path;
  throw 'Entry $entry is not a supported type.';
}

/**
 * Gets a [Directory] for [entry], which can either already be one, or be a
 * [String].
 */
Directory _getDirectory(entry) {
  if (entry is Directory) return entry;
  return new Directory(entry);
}
