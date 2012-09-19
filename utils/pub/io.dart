// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Helper functionality to make working with IO easier.
 */
#library('io');

#import('dart:io');
#import('dart:isolate');
#import('dart:uri');

#import('utils.dart');

bool _isGitInstalledCache;

/// The cached Git command.
String _gitCommandCache;

/** Gets the current working directory. */
String get workingDir => new File('.').fullPathSync();

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
  final parts = _getPath(part1).replaceAll('\\', '/').split('/');

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

  return Strings.join(parts, Platform.pathSeparator);
}

/**
 * Gets the basename, the file name without any leading directory path, for
 * [file], which can either be a [String], [File], or [Directory].
 */
// TODO(rnystrom): Copied from file_system (so that we don't have to add
// file_system to the SDK). Should unify.
String basename(file) {
  file = _getPath(file).replaceAll('\\', '/');

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
  file = _getPath(file).replaceAll('\\', '/');

  int lastSlash = file.lastIndexOf('/', file.length);
  if (lastSlash == -1) {
    return '.';
  } else {
    return file.substring(0, lastSlash);
  }
}

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
  return new File(_getPath(file)).readAsText(Encoding.UTF_8);
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
  return dir.deleteRecursively();
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
  var lister = dir.list(recursive: recursive);

  lister.onDone = (done) {
    // TODO(rnystrom): May need to sort here if it turns out onDir and onFile
    // aren't guaranteed to be called in a certain order. So far, they seem to.
    if (done) completer.complete(contents);
  };

  lister.onError = (error) => completer.completeException(error);
  lister.onDir = (file) => contents.add(file);
  lister.onFile = (file) {
    if (!includeSpecialFiles) {
      if (basename(file) == '.DS_Store') return;
    }
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
 * Creates a new symlink that creates an alias from the package [from] to [to],
 * both of which can be a [String], [File], or [Directory]. Returns a [Future]
 * which completes to the symlink file (i.e. [to]).
 *
 * Unlike [createSymlink], this has heuristics to detect if [from] is using
 * the old or new style of package layout. If it's using the new style, then
 * it will create a symlink to the "lib" directory contained inside that
 * package directory. Otherwise, it just symlinks to the package directory
 * itself.
 */
// TODO(rnystrom): Remove this when old style packages are no longer supported.
// See: http://code.google.com/p/dart/issues/detail?id=4964.
Future<File> createPackageSymlink(String name, from, to,
    [bool isSelfLink = false]) {
  // If from contains any Dart files at the top level (aside from build.dart)
  // we assume that means it's an old style package.
  return listDir(from).chain((contents) {
    var isOldStyle = contents.some(
        (file) => file.endsWith('.dart') && basename(file) != 'build.dart');

    if (isOldStyle) {
      if (isSelfLink) {
        printError('Warning: Package "$name" is using a deprecated layout.');
        printError('See http://www.dartlang.org/docs/pub-package-manager/'
            'package-layout.html for details.');

        // Do not create self-links on old style packages.
        return new Future.immediate(to);
      } else {
        return createSymlink(from, to);
      }
    }

    // It's a new style package, so symlink to the 'lib' directory. But only
    // if the package actually *has* one. Otherwise, we won't create a
    // symlink at all.
    from = join(from, 'lib');
    return dirExists(from).chain((exists) {
      if (exists) {
        return createSymlink(from, to);
      } else {
        printError('Warning: Package "$name" does not have a "lib" directory.');
        return new Future.immediate(to);
      }
    });
  });
}

/**
 * Given [entry] which may be a [String], [File], or [Directory] relative to
 * the current working directory, returns its full canonicalized path.
 */
// TODO(rnystrom): Should this be async?
String getFullPath(entry) => new File(_getPath(entry)).fullPathSync();

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
          new HttpException(response.statusCode, response.reasonPhrase));
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
  return timeout(future, HTTP_TIMEOUT, 'Timed out while fetching URL "$uri".');
}

/**
 * Takes all input from [source] and writes it to [sink].
 *
 * [onClosed] is called when [source] is closed.
 */
void pipeInputToInput(InputStream source, ListInputStream sink,
    [void onClosed()]) {
  source.onClosed = () {
    sink.markEndOfStream();
    if (onClosed != null) onClosed();
  };
  source.onData = () => sink.write(source.read());
  // TODO(nweiz): propagate this error to the sink. See issue 3657.
  source.onError = (e) { throw e; };
}

/**
 * Buffers all input from an InputStream and returns it as a future.
 */
Future<List<int>> consumeInputStream(InputStream stream) {
  var completer = new Completer<List<int>>();
  var buffer = <int>[];
  stream.onClosed = () => completer.complete(buffer);
  stream.onData = () => buffer.addAll(stream.read());
  stream.onError = (e) => completer.completeException(e);
  return completer.future;
}

/**
 * Spawns and runs the process located at [executable], passing in [args].
 * Returns a [Future] that will complete the results of the process after it
 * has ended.
 *
 * If [pipeStdout] and/or [pipeStderr] are set, all output from the subprocess's
 * output streams are sent to the parent process's output streams. Output from
 * piped streams won't be available in the result object.
 */
Future<PubProcessResult> runProcess(String executable, List<String> args,
    [workingDir, Map<String, String> environment, bool pipeStdout = false,
    bool pipeStderr = false]) {
  int exitCode;

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
  options.environment = environment;

  final process = Process.start(executable, args, options);

  final outStream = new StringInputStream(process.stdout);
  final processStdout = <String>[];

  final errStream = new StringInputStream(process.stderr);
  final processStderr = <String>[];

  final completer = new Completer<PubProcessResult>();

  checkComplete() {
    // Wait until the process is done and its output streams are closed.
    if (!pipeStdout && !outStream.closed) return;
    if (!pipeStderr && !errStream.closed) return;
    if (exitCode == null) return;

    completer.complete(new PubProcessResult(
        processStdout, processStderr, exitCode));
  }

  if (pipeStdout) {
    process.stdout.pipe(stdout, close: false);
  } else {
    outStream.onLine   = () => processStdout.add(outStream.readLine());
    outStream.onClosed = checkComplete;
    outStream.onError  = (error) => completer.completeException(error);
  }

  if (pipeStderr) {
    process.stderr.pipe(stderr, close: false);
  } else {
    errStream.onLine   = () => processStderr.add(errStream.readLine());
    errStream.onClosed = checkComplete;
    errStream.onError  = (error) => completer.completeException(error);
  }

  process.onExit = (actualExitCode) {
    exitCode = actualExitCode;
    checkComplete();
  };

  process.onError = (error) => completer.completeException(error);

  return completer.future;
}

/**
 * Wraps [input] to provide a timeout. If [input] completes before
 * [milliSeconds] have passed, then the return value completes in the same way.
 * However, if [milliSeconds] pass before [input] has completed, it completes
 * with a [TimeoutException] with [message].
 *
 * Note that timing out will not cancel the asynchronous operation behind
 * [input].
 */
Future timeout(Future input, int milliSeconds, String message) {
  var completer = new Completer();
  var timer = new Timer(milliSeconds, (_) {
    if (completer.future.isComplete) return;
    completer.completeException(new TimeoutException(message));
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
Future<PubProcessResult> runGit(List<String> args, [String workingDir]) =>
    _gitCommand.chain((git) => runProcess(git, args, workingDir));

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

  var process = Process.start("tar",
      ["--extract", "--gunzip", "--directory", destination]);
  var completer = new Completer<int>();

  // Wait for the process to be fully started before writing to its
  // stdin stream.
  process.onStart = () {
    stream.pipe(process.stdin);
    process.stdout.pipe(stdout, close: false);
    process.stderr.pipe(stderr, close: false);

    process.onExit = completer.complete;
    process.onError = completer.completeException;
  };

  return completer.future.transform((exitCode) => exitCode == 0);
}

Future<bool> _extractTarGzWindows(InputStream stream, String destination) {
  // Find 7zip.
  var scriptDir = new Path(new Options().script).directoryPath;

  // Note: This line of code gets munged by create_sdk.py to be the correct
  // relative path to 7zip in the SDK.
  var pathTo7zip = '../../third_party/7zip/7za.exe';

  var command = scriptDir.append(pathTo7zip).canonicalize().toNativePath();

  // 7zip can't unarchive from gzip -> tar -> destination all in one step so
  // we spawn it twice and pipe them together.
  var completer = new Completer<int>();
  var gzipProcess = Process.start(command, ["e", "-si", "-tgzip", '-so']);
  var tarProcess = Process.start(command,
      ["e", "-si", "-ttar", '-o"$destination"']);

  stream.pipe(gzipProcess.stdin);
  gzipProcess.stdout.pipe(tarProcess.stdin);

  tarProcess.onExit = completer.complete;
  gzipProcess.onError = completer.completeException;
  gzipProcess.onError = completer.completeException;

  return completer.future.transform((exitCode) => exitCode == 0);
}

/**
 * Exception thrown when an HTTP operation fails.
 */
class HttpException implements Exception {
  final int statusCode;
  final String reason;

  const HttpException(this.statusCode, this.reason);
}

/**
 * Exception thrown when an operation times out.
 */
class TimeoutException implements Exception {
  final String message;

  const TimeoutException(this.message);
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
