// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Helper functionality to make working with IO easier.
 */
library io;

import 'dart:io';
import 'dart:isolate';
import 'dart:uri';

import 'utils.dart';

bool _isGitInstalledCache;

/// The cached Git command.
String _gitCommandCache;

/** Gets the current working directory. */
String get currentWorkingDir => new File('.').fullPathSync();

final NEWLINE_PATTERN = new RegExp("\r\n?|\n\r?");

/**
 * Prints the given string to `stderr` on its own line.
 */
void printError(value) {
  stderr.writeString(value.toString());
  stderr.writeString('\n');
}


/**
 * Joins a number of path string parts into a single path. Handles
 * platform-specific path separators. Parts can be [String], [Directory], or
 * [File] objects.
 */
String join(part1, [part2, part3, part4]) {
  final parts = _sanitizePath(part1).split('/');

  for (final part in [part2, part3, part4]) {
    if (part == null) continue;

    for (final piece in _getPath(part).split('/')) {
      if (piece == '..' && parts.length > 0 &&
          parts.last != '.' && parts.last != '..') {
        parts.removeLast();
      } else if (piece != '') {
        if (parts.length > 0 && parts.last == '.') {
          parts.removeLast();
        }
        parts.add(piece);
      }
    }
  }

  return Strings.join(parts, Platform.pathSeparator);
}

/**
 * Gets the basename, the file name without any leading directory path, for
 * [file], which can either be a [String], [File], or [Directory].
 */
// TODO(rnystrom): Copied from file_system (so that we don't have to add
// file_system to the SDK). Should unify.
String basename(file) {
  file = _sanitizePath(file);

  int lastSlash = file.lastIndexOf('/', file.length);
  if (lastSlash == -1) {
    return file;
  } else {
    return file.substring(lastSlash + 1);
  }
}

/**
 * Gets the the leading directory path for [file], which can either be a
 * [String], [File], or [Directory].
 */
// TODO(nweiz): Copied from file_system (so that we don't have to add
// file_system to the SDK). Should unify.
String dirname(file) {
  file = _sanitizePath(file);

  int lastSlash = file.lastIndexOf('/', file.length);
  if (lastSlash == -1) {
    return '.';
  } else {
    return file.substring(0, lastSlash);
  }
}

/// Returns whether or not [entry] is nested somewhere within [dir]. This just
/// performs a path comparison; it doesn't look at the actual filesystem.
bool isBeneath(entry, dir) =>
  _sanitizePath(entry).startsWith('${_sanitizePath(dir)}/');

/**
 * Asynchronously determines if [path], which can be a [String] file path, a
 * [File], or a [Directory] exists on the file system. Returns a [Future] that
 * completes with the result.
 */
Future<bool> exists(path) {
  path = _getPath(path);
  return Futures.wait([fileExists(path), dirExists(path)]).transform((results) {
    return results[0] || results[1];
  });
}

/**
 * Asynchronously determines if [file], which can be a [String] file path or a
 * [File], exists on the file system. Returns a [Future] that completes with
 * the result.
 */
Future<bool> fileExists(file) {
  return new File(_getPath(file)).exists();
}

/**
 * Reads the contents of the text file [file], which can either be a [String] or
 * a [File].
 */
Future<String> readTextFile(file) {
  return new File(_getPath(file)).readAsString(Encoding.UTF_8);
}

/**
 * Creates [file] (which can either be a [String] or a [File]), and writes
 * [contents] to it. Completes when the file is written and closed.
 */
Future<File> writeTextFile(file, String contents) {
  file = new File(_getPath(file));
  return file.open(FileMode.WRITE).chain((opened) {
    return opened.writeString(contents).chain((ignore) {
        return opened.close().transform((ignore) => file);
    });
  });
}

/**
 * Asynchronously deletes [file], which can be a [String] or a [File]. Returns a
 * [Future] that completes when the deletion is done.
 */
Future<File> deleteFile(file) {
  return new File(_getPath(file)).delete();
}

/// Writes [stream] to a new file at [path], which may be a [String] or a
/// [File]. Will replace any file already at that path. Completes when the file
/// is done being written.
Future<File> createFileFromStream(InputStream stream, path) {
  path = _getPath(path);

  var completer = new Completer<File>();
  var file = new File(path);
  var outputStream = file.openOutputStream();
  stream.pipe(outputStream);

  outputStream.onClosed = () {
    completer.complete(file);
  };

  completeError(error) {
    if (!completer.isComplete) completer.completeException(error);
  }

  stream.onError = completeError;
  outputStream.onError = completeError;

  return completer.future;
}

/**
 * Creates a directory [dir]. Returns a [Future] that completes when the
 * directory is created.
 */
Future<Directory> createDir(dir) {
  dir = _getDirectory(dir);
  return dir.create();
}

/**
 * Ensures that [path] and all its parent directories exist. If they don't
 * exist, creates them. Returns a [Future] that completes once all the
 * directories are created.
 */
Future<Directory> ensureDir(path) {
  path = _getPath(path);
  if (path == '.') return new Future.immediate(new Directory('.'));

  return dirExists(path).chain((exists) {
    if (exists) return new Future.immediate(new Directory(path));
    return ensureDir(dirname(path)).chain((_) {
      var completer = new Completer<Directory>();
      var future = createDir(path);
      future.handleException((error) {
        if (error is! DirectoryIOException) return false;
        // Error 17 means the directory already exists (or 183 on Windows).
        if (error.osError.errorCode != 17 &&
            error.osError.errorCode != 183) return false;

        completer.complete(_getDirectory(path));
        return true;
      });
      future.then(completer.complete);
      return completer.future;
    });
  });
}

/**
 * Creates a temp directory whose name will be based on [dir] with a unique
 * suffix appended to it. If [dir] is not provided, a temp directory will be
 * created in a platform-dependent temporary location. Returns a [Future] that
 * completes when the directory is created.
 */
Future<Directory> createTempDir([dir = '']) {
  dir = _getDirectory(dir);
  return dir.createTemp();
}

/**
 * Asynchronously recursively deletes [dir], which can be a [String] or a
 * [Directory]. Returns a [Future] that completes when the deletion is done.
 */
Future<Directory> deleteDir(dir) {
  dir = _getDirectory(dir);
  return dir.delete(recursive: true);
}

/**
 * Asynchronously lists the contents of [dir], which can be a [String] directory
 * path or a [Directory]. If [recursive] is `true`, lists subdirectory contents
 * (defaults to `false`). If [includeHiddenFiles] is `true`, includes files
 * beginning with `.` (defaults to `false`).
 */
Future<List<String>> listDir(dir,
    {bool recursive: false, bool includeHiddenFiles: false}) {
  final completer = new Completer<List<String>>();
  final contents = <String>[];

  dir = _getDirectory(dir);
  var lister = dir.list(recursive: recursive);

  lister.onDone = (done) {
    // TODO(rnystrom): May need to sort here if it turns out onDir and onFile
    // aren't guaranteed to be called in a certain order. So far, they seem to.
    if (done) completer.complete(contents);
  };

  lister.onError = (error) => completer.completeException(error);
  lister.onDir = (file) => contents.add(file);
  lister.onFile = (file) {
    if (!includeHiddenFiles && basename(file).startsWith('.')) return;
    contents.add(file);
  };

  return completer.future;
}

/**
 * Asynchronously determines if [dir], which can be a [String] directory path
 * or a [Directory], exists on the file system. Returns a [Future] that
 * completes with the result.
 */
Future<bool> dirExists(dir) {
  dir = _getDirectory(dir);
  return dir.exists();
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

/// Renames (i.e. moves) the directory [from] to [to]. Returns a [Future] with
/// the destination directory.
Future<Directory> renameDir(from, String to) =>_getDirectory(from).rename(to);

/**
 * Creates a new symlink that creates an alias from [from] to [to], both of
 * which can be a [String], [File], or [Directory]. Returns a [Future] which
 * completes to the symlink file (i.e. [to]).
 */
Future<File> createSymlink(from, to) {
  from = _getPath(from);
  to = _getPath(to);

  var command = 'ln';
  var args = ['-s', from, to];

  if (Platform.operatingSystem == 'windows') {
    // Call mklink on Windows to create an NTFS junction point. Only works on
    // Vista or later. (Junction points are available earlier, but the "mklink"
    // command is not.) I'm using a junction point (/j) here instead of a soft
    // link (/d) because the latter requires some privilege shenanigans that
    // I'm not sure how to specify from the command line.
    command = 'mklink';
    args = ['/j', to, from];
  }

  return runProcess(command, args).transform((result) {
    // TODO(rnystrom): Check exit code and output?
    return new File(to);
  });
}

/**
 * Creates a new symlink that creates an alias from the `lib` directory of
 * package [from] to [to], both of which can be a [String], [File], or
 * [Directory]. Returns a [Future] which completes to the symlink file (i.e.
 * [to]). If [from] does not have a `lib` directory, this shows a warning if
 * appropriate and then does nothing.
 */
Future<File> createPackageSymlink(String name, from, to,
    {bool isSelfLink: false}) {
  // See if the package has a "lib" directory.
  from = join(from, 'lib');
  return dirExists(from).chain((exists) {
    if (exists) return createSymlink(from, to);

    // It's OK for the self link (i.e. the root package) to not have a lib
    // directory since it may just be a leaf application that only has
    // code in bin or web.
    if (!isSelfLink) {
      printError(
          'Warning: Package "$name" does not have a "lib" directory so you '
          'will not be able to import any libraries from it.');
    }

    return new Future.immediate(to);
  });
}

/// Given [entry] which may be a [String], [File], or [Directory] relative to
/// the current working directory, returns its full canonicalized path.
String getFullPath(entry) {
  var path = _getPath(entry);

  // Don't do anything if it's already absolute.
  if (Platform.operatingSystem == 'windows') {
    // An absolute path on Windows is either UNC (two leading backslashes),
    // or a drive letter followed by a colon and a slash.
    var ABSOLUTE = new RegExp(r'^(\\\\|[a-zA-Z]:[/\\])');
    if (ABSOLUTE.hasMatch(path)) return path;
  } else {
    if (path.startsWith('/')) return path;
  }

  // Using Path.join here instead of File().fullPathSync() because the former
  // does not require an actual file to exist at that path.
  return new Path.fromNative(currentWorkingDir).join(new Path(path))
      .toNativePath();
}

/// Resolves [path] relative to the location of pub.dart.
String relativeToPub(String path) {
  var scriptPath = new File(new Options().script).fullPathSync();

  // Walk up until we hit the "utils" directory. This lets us figure out where
  // we are if this function is called from pub.dart, or one of the tests,
  // which also live under "utils".
  var utilsDir = new Path.fromNative(scriptPath).directoryPath;
  while (utilsDir.filename != 'utils') {
    utilsDir = utilsDir.directoryPath;
  }

  return utilsDir.append('pub').append(path).canonicalize().toNativePath();
}

/// A StringInputStream reading from stdin.
final _stringStdin = new StringInputStream(stdin);

/// Returns a single line read from a [StringInputStream]. By default, reads
/// from stdin.
///
/// A [StringInputStream] passed to this should have no callbacks registered.
Future<String> readLine([StringInputStream stream]) {
  if (stream == null) stream = _stringStdin;
  if (stream.closed) return new Future.immediate('');
  void removeCallbacks() {
    stream.onClosed = null;
    stream.onLine = null;
    stream.onError = null;
  }

  var completer = new Completer();
  stream.onClosed = () {
    removeCallbacks();
    completer.complete('');
  };

  stream.onLine = () {
    removeCallbacks();
    completer.complete(stream.readLine());
  };

  stream.onError = (e) {
    removeCallbacks();
    completer.completeException(e);
  };

  return completer.future;
}

// TODO(nweiz): make this configurable
/**
 * The amount of time in milliseconds to allow HTTP requests before assuming
 * they've failed.
 */
final HTTP_TIMEOUT = 30 * 1000;

/**
 * Opens an input stream for a HTTP GET request to [uri], which may be a
 * [String] or [Uri].
 *
 * Callers should be sure to use [timeout] to make sure that the HTTP request
 * doesn't last indefinitely
 */
Future<InputStream> httpGet(uri) {
  // TODO(nweiz): This could return an InputStream synchronously if issue 3657
  // were fixed and errors could be propagated through it. Then we could also
  // automatically attach a timeout to that stream.
  uri = _getUri(uri);

  var completer = new Completer<InputStream>();
  var client = new HttpClient();
  var connection = client.getUrl(uri);

  connection.onError = (e) {
    // Show a friendly error if the URL couldn't be resolved.
    if (e is SocketIOException &&
        e.osError != null &&
        (e.osError.errorCode == 8 ||
         e.osError.errorCode == -2 ||
         e.osError.errorCode == -5 ||
         e.osError.errorCode == 11004)) {
      e = 'Could not resolve URL "${uri.origin}".';
    }

    client.shutdown();
    completer.completeException(e);
  };

  connection.onResponse = (response) {
    if (response.statusCode >= 400) {
      client.shutdown();
      completer.completeException(
          new PubHttpException(response.statusCode, response.reasonPhrase));
      return;
    }

    completer.complete(response.inputStream);
  };

  return completer.future;
}

/**
 * Opens an input stream for a HTTP GET request to [uri], which may be a
 * [String] or [Uri]. Completes with the result of the request as a String.
 */
Future<String> httpGetString(uri) {
  var future = httpGet(uri).chain((stream) => consumeInputStream(stream))
      .transform((bytes) => new String.fromCharCodes(bytes));
  return timeout(future, HTTP_TIMEOUT, 'fetching URL "$uri"');
}

/**
 * Takes all input from [source] and writes it to [sink].
 *
 * Returns a future that completes when [source] is closed.
 */
Future pipeInputToInput(InputStream source, ListInputStream sink) {
  var completer = new Completer();
  source.onClosed = () {
    sink.markEndOfStream();
    completer.complete(null);
  };
  source.onData = () => sink.write(source.read());
  // TODO(nweiz): propagate this error to the sink. See issue 3657.
  source.onError = (e) { throw e; };
  return completer.future;
}

/**
 * Buffers all input from an InputStream and returns it as a future.
 */
Future<List<int>> consumeInputStream(InputStream stream) {
  if (stream.closed) return new Future.immediate(<int>[]);

  var completer = new Completer<List<int>>();
  var buffer = <int>[];
  stream.onClosed = () => completer.complete(buffer);
  stream.onData = () => buffer.addAll(stream.read());
  stream.onError = (e) => completer.completeException(e);
  return completer.future;
}

/// Buffers all input from a StringInputStream and returns it as a future.
Future<String> consumeStringInputStream(StringInputStream stream) {
  if (stream.closed) return new Future.immediate('');

  var completer = new Completer<String>();
  var buffer = new StringBuffer();
  stream.onClosed = () => completer.complete(buffer.toString());
  stream.onData = () => buffer.add(stream.read());
  stream.onError = (e) => completer.completeException(e);
  return completer.future;
}

/// Spawns and runs the process located at [executable], passing in [args].
/// Returns a [Future] that will complete with the results of the process after
/// it has ended.
///
/// The spawned process will inherit its parent's environment variables. If
/// [environment] is provided, that will be used to augment (not replace) the
/// the inherited variables.
Future<PubProcessResult> runProcess(String executable, List<String> args,
    {workingDir, Map<String, String> environment}) {
  return _doProcess(Process.run, executable, args, workingDir, environment)
      .transform((result) {
    // TODO(rnystrom): Remove this and change to returning one string.
    List<String> toLines(String output) {
      var lines = output.split(NEWLINE_PATTERN);
      if (!lines.isEmpty && lines.last == "") lines.removeLast();
      return lines;
    }
    return new PubProcessResult(toLines(result.stdout),
                                toLines(result.stderr),
                                result.exitCode);
  });
}

/// Spawns the process located at [executable], passing in [args]. Returns a
/// [Future] that will complete with the [Process] once it's been started.
///
/// The spawned process will inherit its parent's environment variables. If
/// [environment] is provided, that will be used to augment (not replace) the
/// the inherited variables.
Future<Process> startProcess(String executable, List<String> args,
    {workingDir, Map<String, String> environment}) =>
  _doProcess(Process.start, executable, args, workingDir, environment);

/// Calls [fn] with appropriately modified arguments. [fn] should have the same
/// signature as [Process.start], except that the returned [Future] may have a
/// type other than [Process].
Future _doProcess(Function fn, String executable, List<String> args, workingDir,
    Map<String, String> environment) {
  // TODO(rnystrom): Should dart:io just handle this?
  // Spawning a process on Windows will not look for the executable in the
  // system path. So, if executable looks like it needs that (i.e. it doesn't
  // have any path separators in it), then spawn it through a shell.
  if ((Platform.operatingSystem == "windows") &&
      (executable.indexOf('\\') == -1)) {
    args = flatten(["/c", executable, args]);
    executable = "cmd";
  }

  final options = new ProcessOptions();
  if (workingDir != null) {
    options.workingDirectory = _getDirectory(workingDir).path;
  }

  if (environment != null) {
    options.environment = new Map.from(Platform.environment);
    environment.forEach((key, value) => options.environment[key] = value);
  }

  return fn(executable, args, options);
}

/// Closes [response] while ignoring the body of [request]. Returns a Future
/// that completes once the response is closed.
///
/// Due to issue 6984, it's necessary to drain the request body before closing
/// the response.
Future closeHttpResponse(HttpRequest request, HttpResponse response) {
  var completer = new Completer();
  request.inputStream.onError = completer.completeException;
  request.inputStream.onData = request.inputStream.read;
  request.inputStream.onClosed = () {
    response.outputStream.close();
    completer.complete(null);
  };
  return completer.future;
}

/**
 * Wraps [input] to provide a timeout. If [input] completes before
 * [milliseconds] have passed, then the return value completes in the same way.
 * However, if [milliseconds] pass before [input] has completed, it completes
 * with a [TimeoutException] with [description] (which should be a fragment
 * describing the action that timed out).
 *
 * Note that timing out will not cancel the asynchronous operation behind
 * [input].
 */
Future timeout(Future input, int milliseconds, String description) {
  var completer = new Completer();
  var timer = new Timer(milliseconds, (_) {
    if (completer.future.isComplete) return;
    completer.completeException(new TimeoutException(
        'Timed out while $description.'));
  });
  input.handleException((e) {
    if (completer.future.isComplete) return false;
    timer.cancel();
    completer.completeException(e);
    return true;
  });
  input.then((value) {
    if (completer.future.isComplete) return;
    timer.cancel();
    completer.complete(value);
  });
  return completer.future;
}

/// Creates a temporary directory and passes its path to [fn]. Once the [Future]
/// returned by [fn] completes, the temporary directory and all its contents
/// will be deleted.
Future withTempDir(Future fn(String path)) {
  var tempDir;
  var future = createTempDir().chain((dir) {
    tempDir = dir;
    return fn(tempDir.path);
  });
  future.onComplete((_) => tempDir.delete(recursive: true));
  return future;
}

/// Tests whether or not the git command-line app is available for use.
Future<bool> get isGitInstalled {
  if (_isGitInstalledCache != null) {
    // TODO(rnystrom): The sleep is to pump the message queue. Can use
    // Future.immediate() when #3356 is fixed.
    return sleep(0).transform((_) => _isGitInstalledCache);
  }

  return _gitCommand.transform((git) => git != null);
}

/// Run a git process with [args] from [workingDir].
Future<PubProcessResult> runGit(List<String> args,
    {String workingDir, Map<String, String> environment}) {
  return _gitCommand.chain((git) => runProcess(git, args,
        workingDir: workingDir, environment: environment));
}

/// Returns the name of the git command-line app, or null if Git could not be
/// found on the user's PATH.
Future<String> get _gitCommand {
  // TODO(nweiz): Just use Future.immediate once issue 3356 is fixed.
  if (_gitCommandCache != null) {
    return sleep(0).transform((_) => _gitCommandCache);
  }

  return _tryGitCommand("git").chain((success) {
    if (success) return new Future.immediate("git");

    // Git is sometimes installed on Windows as `git.cmd`
    return _tryGitCommand("git.cmd").transform((success) {
      if (success) return "git.cmd";
      return null;
    });
  }).transform((command) {
    _gitCommandCache = command;
    return command;
  });
}

/// Checks whether [command] is the Git command for this computer.
Future<bool> _tryGitCommand(String command) {
  var completer = new Completer<bool>();

  // If "git --version" prints something familiar, git is working.
  var future = runProcess(command, ["--version"]);

  future.then((results) {
    var regex = new RegExp("^git version");
    completer.complete(results.stdout.length == 1 &&
                       regex.hasMatch(results.stdout[0]));
  });

  future.handleException((err) {
    // If the process failed, they probably don't have it.
    completer.complete(false);
    return true;
  });

  return completer.future;
}

/**
 * Extracts a `.tar.gz` file from [stream] to [destination], which can be a
 * directory or a path. Returns whether or not the extraction was successful.
 */
Future<bool> extractTarGz(InputStream stream, destination) {
  destination = _getPath(destination);

  if (Platform.operatingSystem == "windows") {
    return _extractTarGzWindows(stream, destination);
  }

  var completer = new Completer<int>();
  var processFuture = Process.start("tar",
      ["--extract", "--gunzip", "--directory", destination]);
  processFuture.then((process) {
    process.onExit = completer.complete;
    stream.pipe(process.stdin);
    process.stdout.pipe(stdout, close: false);
    process.stderr.pipe(stderr, close: false);
  });
  processFuture.handleException((error) {
    completer.completeException(error);
    return true;
  });

  return completer.future.transform((exitCode) => exitCode == 0);
}

Future<bool> _extractTarGzWindows(InputStream stream, String destination) {
  // TODO(rnystrom): In the repo's history, there is an older implementation of
  // this that does everything in memory by piping streams directly together
  // instead of writing out temp files. The code is simpler, but unfortunately,
  // 7zip seems to periodically fail when we invoke it from Dart and tell it to
  // read from stdin instead of a file. Consider resurrecting that version if
  // we can figure out why it fails.

  // Note: This line of code gets munged by create_sdk.py to be the correct
  // relative path to 7zip in the SDK.
  var pathTo7zip = '../../third_party/7zip/7za.exe';
  var command = relativeToPub(pathTo7zip);

  var tempDir;

  // TODO(rnystrom): Use withTempDir().
  return createTempDir().chain((temp) {
    // Write the archive to a temp file.
    tempDir = temp;
    return createFileFromStream(stream, join(tempDir, 'data.tar.gz'));
  }).chain((_) {
    // 7zip can't unarchive from gzip -> tar -> destination all in one step
    // first we un-gzip it to a tar file.
    // Note: Setting the working directory instead of passing in a full file
    // path because 7zip says "A full path is not allowed here."
    return runProcess(command, ['e', 'data.tar.gz'], workingDir: tempDir);
  }).chain((result) {
    if (result.exitCode != 0) {
      throw 'Could not un-gzip (exit code ${result.exitCode}). Error:\n'
          '${Strings.join(result.stdout, "\n")}\n'
          '${Strings.join(result.stderr, "\n")}';
    }
    // Find the tar file we just created since we don't know its name.
    return listDir(tempDir);
  }).chain((files) {
    var tarFile;
    for (var file in files) {
      if (new Path(file).extension == 'tar') {
        tarFile = file;
        break;
      }
    }

    if (tarFile == null) throw 'The gzip file did not contain a tar file.';

    // Untar the archive into the destination directory.
    return runProcess(command, ['x', tarFile], workingDir: destination);
  }).chain((result) {
    if (result.exitCode != 0) {
      throw 'Could not un-tar (exit code ${result.exitCode}). Error:\n'
          '${Strings.join(result.stdout, "\n")}\n'
          '${Strings.join(result.stderr, "\n")}';
    }

    // Clean up the temp directory.
    // TODO(rnystrom): Should also delete this if anything fails.
    return deleteDir(tempDir);
  }).transform((_) => true);
}

/// Create a .tar.gz archive from a list of entries. Each entry can be a
/// [String], [Directory], or [File] object. The root of the archive is
/// considered to be [baseDir], which defaults to the current working directory.
/// Returns an [InputStream] that will emit the contents of the archive.
InputStream createTarGz(List contents, {baseDir}) {
  // TODO(nweiz): Propagate errors to the returned stream (including non-zero
  // exit codes). See issue 3657.
  var stream = new ListInputStream();

  if (baseDir == null) baseDir = currentWorkingDir;
  baseDir = getFullPath(baseDir);
  contents = contents.map((entry) {
    entry = getFullPath(entry);
    if (!isBeneath(entry, baseDir)) {
      throw 'Entry $entry is not inside $baseDir.';
    }
    return new Path.fromNative(entry).relativeTo(new Path.fromNative(baseDir))
        .toNativePath();
  });

  if (Platform.operatingSystem != "windows") {
    var args = ["--create", "--gzip", "--directory", baseDir];
    args.addAll(contents.map(_getPath));
    // TODO(nweiz): It's possible that enough command-line arguments will make
    // the process choke, so at some point we should save the arguments to a
    // file and pass them in via --files-from for tar and -i@filename for 7zip.
    startProcess("tar", args).then((process) {
      pipeInputToInput(process.stdout, stream);
      process.stderr.pipe(stderr, close: false);
    });
    return stream;
  }

  withTempDir((tempDir) {
    // Create the tar file.
    var tarFile = join(tempDir, "intermediate.tar");
    var args = ["a", "-w$baseDir", tarFile];
    args.addAll(contents.map((entry) => '-i!"$entry"'));

    // Note: This line of code gets munged by create_sdk.py to be the correct
    // relative path to 7zip in the SDK.
    var pathTo7zip = '../../third_party/7zip/7za.exe';
    var command = relativeToPub(pathTo7zip);

    // We're passing 'baseDir' both as '-w' and setting it as the working
    // directory explicitly here intentionally. The former ensures that the
    // files added to the archive have the correct relative path in the archive.
    // The latter enables relative paths in the "-i" args to be resolved.
    return runProcess(command, args, workingDir: baseDir).chain((_) {
      // GZIP it. 7zip doesn't support doing both as a single operation. Send
      // the output to stdout.
      args = ["a", "unused", "-tgzip", "-so", tarFile];
      return startProcess(command, args);
    }).chain((process) {
      process.stderr.pipe(stderr, close: false);
      return pipeInputToInput(process.stdout, stream);
    });
  });
  return stream;
}

/**
 * Exception thrown when an HTTP operation fails.
 */
class PubHttpException implements Exception {
  final int statusCode;
  final String reason;

  const PubHttpException(this.statusCode, this.reason);

  String toString() => 'HTTP error $statusCode: $reason';
}

/**
 * Exception thrown when an operation times out.
 */
class TimeoutException implements Exception {
  final String message;

  const TimeoutException(this.message);

  String toString() => message;
}

/**
 * Contains the results of invoking a [Process] and waiting for it to complete.
 */
class PubProcessResult {
  final List<String> stdout;
  final List<String> stderr;
  final int exitCode;

  const PubProcessResult(this.stdout, this.stderr, this.exitCode);

  bool get success => exitCode == 0;
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

/// Gets the path string for [entry] as in [_getPath], but normalizes
/// backslashes to forward slashes on Windows.
String _sanitizePath(entry) {
  entry = _getPath(entry);
  if (Platform.operatingSystem == 'windows') {
    entry = entry.replaceAll('\\', '/');
  }
  return entry;
}

/**
 * Gets a [Directory] for [entry], which can either already be one, or be a
 * [String].
 */
Directory _getDirectory(entry) {
  if (entry is Directory) return entry;
  return new Directory(entry);
}

/**
 * Gets a [Uri] for [uri], which can either already be one, or be a [String].
 */
Uri _getUri(uri) {
  if (uri is Uri) return uri;
  return new Uri.fromString(uri);
}
