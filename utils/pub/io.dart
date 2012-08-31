// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Helper functionality to make working with IO easier.
 */
#library('io');

#import('dart:io');
#import('dart:uri');

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
Future<Directory> deleteFile(file) {
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
    command = 'cmd';
    args = ['/c', 'mklink', '/j', to, from];
  }

  return runProcess(command, args).transform((result) {
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
 * Opens an input stream for a HTTP GET request to [uri], which may be a
 * [String] or [Uri].
 */
InputStream httpGet(uri) {
  var resultStream = new ListInputStream();
  var client = new HttpClient();
  var connection = client.getUrl(_getUri(uri));

  // TODO(nweiz): propagate this error to the return value. See issue 3657.
  connection.onError = (e) { throw e; };
  connection.onResponse = (response) {
    if (response.statusCode >= 400) {
      // TODO(nweiz): propagate this error to the return value. See issue 3657.
      throw new Exception(
          "HTTP request for $uri failed with status ${response.statusCode}");
    }

    pipeInputToInput(response.inputStream, resultStream, client.shutdown);
  };

  return resultStream;
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
 * Tests whether or not the git command-line app is available for use.
 */
Future<bool> get isGitInstalled {
  // TODO(rnystrom): We could cache this after the first check. We aren't right
  // now because Future.immediate() will invoke its callback synchronously.
  // That does bad things in cases where the caller expects futures to always
  // be async. In particular, withGit() in the pub tests which calls
  // expectAsync() will fail horribly if the test isn't actually async.

  var completer = new Completer<bool>();

  // If "git --version" prints something familiar, git is working.
  var future = runProcess("git", ["--version"]);

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
  var process = Process.start("tar",
      ["--extract", "--gunzip", "--directory", _getPath(destination)]);
  var completer = new Completer<int>();

  stream.pipe(process.stdin);
  process.stdout.pipe(stdout, close: false);
  process.stderr.pipe(stderr, close: false);

  process.onExit = completer.complete;
  process.onError = completer.completeException;
  return completer.future.transform((exitCode) => exitCode == 0);
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
