// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper functionality to make working with IO easier.
library io;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:json';
import 'dart:uri';

import '../../pkg/path/lib/path.dart' as path;
import '../../pkg/http/lib/http.dart' show ByteStream;
import 'error_group.dart';
import 'exit_codes.dart' as exit_codes;
import 'log.dart' as log;
import 'utils.dart';

export '../../pkg/http/lib/http.dart' show ByteStream;

final NEWLINE_PATTERN = new RegExp("\r\n?|\n\r?");

/// Joins a number of path string parts into a single path. Handles
/// platform-specific path separators. Parts can be [String], [Directory], or
/// [File] objects.
String join(part1, [part2, part3, part4, part5, part6, part7, part8]) {
  var parts = [part1, part2, part3, part4, part5, part6, part7, part8]
      .map((part) => part == null ? null : _getPath(part)).toList();

  return path.join(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5],
      parts[6], parts[7]);
}

/// Gets the basename, the file name without any leading directory path, for
/// [file], which can either be a [String], [File], or [Directory].
String basename(file) => path.basename(_getPath(file));

/// Gets the the leading directory path for [file], which can either be a
/// [String], [File], or [Directory].
String dirname(file) => path.dirname(_getPath(file));

/// Splits [entry] into its individual components.
List<String> splitPath(entry) => path.split(_getPath(entry));

/// Returns whether or not [entry] is nested somewhere within [dir]. This just
/// performs a path comparison; it doesn't look at the actual filesystem.
bool isBeneath(entry, dir) {
  var relative = relativeTo(entry, dir);
  return !path.isAbsolute(relative) && splitPath(relative)[0] != '..';
}

/// Returns the path to [target] from [base].
String relativeTo(target, base) => path.relative(target, from: base);

/// Determines if [path], which can be a [String] file path, a [File], or a
/// [Directory] exists on the file system.
bool entryExists(path) => fileExists(path) || dirExists(path);

/// Determines if [file], which can be a [String] file path or a [File], exists
/// on the file system.
bool fileExists(file) => _getFile(file).existsSync();

/// Reads the contents of the text file [file], which can either be a [String]
/// or a [File].
String readTextFile(file) => _getFile(file).readAsStringSync(Encoding.UTF_8);

/// Reads the contents of the binary file [file], which can either be a [String]
/// or a [File].
List<int> readBinaryFile(file) {
  var path = _getPath(file);
  log.io("Reading binary file $path.");
  var contents = new File(path).readAsBytesSync();
  log.io("Read ${contents.length} bytes from $path.");
  return contents;
}

/// Creates [file] (which can either be a [String] or a [File]), and writes
/// [contents] to it.
///
/// If [dontLogContents] is true, the contents of the file will never be logged.
File writeTextFile(file, String contents, {dontLogContents: false}) {
  var path = _getPath(file);
  file = new File(path);

  // Sanity check: don't spew a huge file.
  log.io("Writing ${contents.length} characters to text file $path.");
  if (!dontLogContents && contents.length < 1024 * 1024) {
    log.fine("Contents:\n$contents");
  }

  return file..writeAsStringSync(contents);
}

/// Deletes [file], which can be a [String] or a [File]. Returns a [Future]
/// that completes when the deletion is done.
File deleteFile(file) => _getFile(file)..delete();

/// Creates [file] (which can either be a [String] or a [File]), and writes
/// [contents] to it.
File writeBinaryFile(file, List<int> contents) {
  var path = _getPath(file);
  file = new File(path);

  log.io("Writing ${contents.length} bytes to binary file $path.");
  file.openSync(FileMode.WRITE)
      ..writeListSync(contents, 0, contents.length)
      ..closeSync();
  log.fine("Wrote text file $path.");
  return file;
}

/// Writes [stream] to a new file at [path], which may be a [String] or a
/// [File]. Will replace any file already at that path. Completes when the file
/// is done being written.
Future<File> createFileFromStream(Stream<List<int>> stream, path) {
  path = _getPath(path);

  log.io("Creating $path from stream.");

  var file = new File(path);
  return stream.pipe(wrapOutputStream(file.openOutputStream())).then((_) {
    log.fine("Created $path from stream.");
  });
}

/// Creates a directory [dir].
Directory createDir(dir) => _getDirectory(dir)..createSync();

/// Ensures that [path] and all its parent directories exist. If they don't
/// exist, creates them.
Directory ensureDir(path) {
  path = _getPath(path);

  log.fine("Ensuring directory $path exists.");
  var dir = new Directory(path);
  if (path == '.' || dirExists(path)) return dir;

  ensureDir(dirname(path));

  try {
    createDir(dir);
  } on DirectoryIOException catch (ex) {
    // Error 17 means the directory already exists (or 183 on Windows).
    if (ex.osError.errorCode == 17 || ex.osError.errorCode == 183) {
      log.fine("Got 'already exists' error when creating directory.");
    } else {
      throw ex;
    }
  }

  return dir;
}

/// Creates a temp directory whose name will be based on [dir] with a unique
/// suffix appended to it. If [dir] is not provided, a temp directory will be
/// created in a platform-dependent temporary location. Returns a [Future] that
/// completes when the directory is created.
Future<Directory> createTempDir([dir = '']) {
  dir = _getDirectory(dir);
  return log.ioAsync("create temp directory ${dir.path}",
      dir.createTemp());
}

/// Asynchronously recursively deletes [dir], which can be a [String] or a
/// [Directory]. Returns a [Future] that completes when the deletion is done.
Future<Directory> deleteDir(dir) {
  dir = _getDirectory(dir);

  return _attemptRetryable(() => log.ioAsync("delete directory ${dir.path}",
      dir.delete(recursive: true)));
}

/// Asynchronously lists the contents of [dir], which can be a [String]
/// directory path or a [Directory]. If [recursive] is `true`, lists
/// subdirectory contents (defaults to `false`). If [includeHiddenFiles] is
/// `true`, includes files and directories beginning with `.` (defaults to
/// `false`).
///
/// If [dir] is a string, the returned paths are guaranteed to begin with it.
Future<List<String>> listDir(dir,
    {bool recursive: false, bool includeHiddenFiles: false}) {
  Future<List<String>> doList(Directory dir, Set<String> listedDirectories) {
    var contents = <String>[];
    var completer = new Completer<List<String>>();

    // Avoid recursive symlinks.
    var resolvedPath = new File(dir.path).fullPathSync();
    if (listedDirectories.contains(resolvedPath)) {
      return new Future.immediate([]);
    }

    listedDirectories = new Set<String>.from(listedDirectories);
    listedDirectories.add(resolvedPath);

    log.io("Listing directory ${dir.path}.");
    var lister = dir.list();

    lister.onDone = (done) {
      // TODO(rnystrom): May need to sort here if it turns out onDir and onFile
      // aren't guaranteed to be called in a certain order. So far, they seem to.
      if (done) {
        log.fine("Listed directory ${dir.path}:\n"
                  "${Strings.join(contents, '\n')}");
        completer.complete(contents);
      }
    };

    // TODO(nweiz): remove this when issue 4061 is fixed.
    var stackTrace;
    try {
      throw "";
    } catch (_, localStackTrace) {
      stackTrace = localStackTrace;
    }

    var children = [];
    lister.onError = (error) => completer.completeError(error, stackTrace);
    lister.onDir = (file) {
      if (!includeHiddenFiles && basename(file).startsWith('.')) return;
      file = join(dir, basename(file));
      contents.add(file);
      // TODO(nweiz): don't manually recurse once issue 7358 is fixed. Note that
      // once we remove the manual recursion, we'll need to explicitly filter
      // out files in hidden directories.
      if (recursive) {
        children.add(doList(new Directory(file), listedDirectories));
      }
    };

    lister.onFile = (file) {
      if (!includeHiddenFiles && basename(file).startsWith('.')) return;
      contents.add(join(dir, basename(file)));
    };

    return completer.future.then((contents) {
      return Future.wait(children).then((childContents) {
        contents.addAll(flatten(childContents));
        return contents;
      });
    });
  }

  return doList(_getDirectory(dir), new Set<String>());
}

/// Determines if [dir], which can be a [String] directory path or a
/// [Directory], exists on the file system.
bool dirExists(dir) => _getDirectory(dir).existsSync();

/// "Cleans" [dir]. If that directory already exists, it will be deleted. Then a
/// new empty directory will be created. Returns a [Future] that completes when
/// the new clean directory is created.
Future<Directory> cleanDir(dir) {
  return defer(() {
    if (dirExists(dir)) {
      // Delete it first.
      return deleteDir(dir).then((_) => createDir(dir));
    } else {
      // Just create it.
      return createDir(dir);
    }
  });
}

/// Renames (i.e. moves) the directory [from] to [to]. Returns a [Future] with
/// the destination directory.
Future<Directory> renameDir(from, String to) {
  from = _getDirectory(from);
  log.io("Renaming directory ${from.path} to $to.");

  return _attemptRetryable(() => from.rename(to)).then((dir) {
    log.fine("Renamed directory ${from.path} to $to.");
    return dir;
  });
}

/// On Windows, we sometimes get failures where the directory is still in use
/// when we try to do something with it. This is usually because the OS hasn't
/// noticed yet that a process using that directory has closed. To be a bit
/// more resilient, we wait and retry a few times.
///
/// Takes a [callback] which returns a future for the operation being attempted.
/// If that future completes with an error, it will slepp and then [callback]
/// will be invoked again to retry the operation. It will try a few times before
/// giving up.
Future _attemptRetryable(Future callback()) {
  // Only do lame retry logic on Windows.
  if (Platform.operatingSystem != 'windows') return callback();

  var attempts = 0;
  makeAttempt(_) {
    attempts++;
    return callback().catchError((e) {
      if (attempts >= 10) {
        throw 'Could not complete operation. Gave up after $attempts attempts.';
      }

      // Wait a bit and try again.
      log.fine("Operation failed, retrying (attempt $attempts).");
      return sleep(500).then(makeAttempt);
    });
  }

  return makeAttempt(null);
}

/// Creates a new symlink that creates an alias from [from] to [to], both of
/// which can be a [String], [File], or [Directory]. Returns a [Future] which
/// completes to the symlink file (i.e. [to]).
///
/// Note that on Windows, only directories may be symlinked to.
Future<File> createSymlink(from, to) {
  from = _getPath(from);
  to = _getPath(to);

  log.fine("Create symlink $from -> $to.");

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

  return runProcess(command, args).then((result) {
    // TODO(rnystrom): Check exit code and output?
    return new File(to);
  });
}

/// Creates a new symlink that creates an alias from the `lib` directory of
/// package [from] to [to], both of which can be a [String], [File], or
/// [Directory]. Returns a [Future] which completes to the symlink file (i.e.
/// [to]). If [from] does not have a `lib` directory, this shows a warning if
/// appropriate and then does nothing.
Future<File> createPackageSymlink(String name, from, to,
    {bool isSelfLink: false}) {
  return defer(() {
    // See if the package has a "lib" directory.
    from = join(from, 'lib');
    log.fine("Creating ${isSelfLink ? "self" : ""}link for package '$name'.");
    if (dirExists(from)) return createSymlink(from, to);

    // It's OK for the self link (i.e. the root package) to not have a lib
    // directory since it may just be a leaf application that only has
    // code in bin or web.
    if (!isSelfLink) {
      log.warning('Warning: Package "$name" does not have a "lib" directory so '
                  'you will not be able to import any libraries from it.');
    }

    return _getFile(to);
  });
}

/// Given [entry] which may be a [String], [File], or [Directory] relative to
/// the current working directory, returns its full canonicalized path.
String getFullPath(entry) => path.absolute(_getPath(entry));

/// Returns whether or not [entry] is an absolute path.
bool isAbsolute(entry) => path.isAbsolute(_getPath(entry));

/// Resolves [target] relative to the location of pub.dart.
String relativeToPub(String target) {
  var scriptPath = new File(new Options().script).fullPathSync();

  // Walk up until we hit the "util(s)" directory. This lets us figure out where
  // we are if this function is called from pub.dart, or one of the tests,
  // which also live under "utils", or from the SDK where pub is in "util".
  var utilDir = dirname(scriptPath);
  while (basename(utilDir) != 'utils' && basename(utilDir) != 'util') {
    if (basename(utilDir) == '') throw 'Could not find path to pub.';
    utilDir = dirname(utilDir);
  }

  return path.normalize(join(utilDir, 'pub', target));
}

// TODO(nweiz): add a ByteSink wrapper to make writing strings to stdout/stderr
// nicer.

/// A sink that writes to standard output. Errors piped to this stream will be
/// surfaced to the top-level error handler.
final StreamSink<List<int>> stdoutSink = _wrapStdio(stdout, "stdout");

/// A sink that writes to standard error. Errors piped to this stream will be
/// surfaced to the top-level error handler.
final StreamSink<List<int>> stderrSink = _wrapStdio(stderr, "stderr");

/// Wrap the standard output or error [stream] in a [StreamSink]. Any errors are
/// logged, and then the program is terminated. [name] is used for debugging.
StreamSink<List<int>> _wrapStdio(OutputStream stream, String name) {
  var pair = consumerToSink(wrapOutputStream(stream));
  pair.last.catchError((e) {
    // This log may or may not work, depending on how the stream failed. Not
    // much we can do about that.
    log.error("Error writing to $name: $e");
    exit(exit_codes.IO);
  });
  return pair.first;
}

/// A line-by-line stream of standard input.
final Stream<String> stdinLines =
    streamToLines(wrapInputStream(stdin).toStringStream());

/// Displays a message and reads a yes/no confirmation from the user. Returns
/// a [Future] that completes to `true` if the user confirms or `false` if they
/// do not.
///
/// This will automatically append " (y/n)?" to the message, so [message]
/// should just be a fragment like, "Are you sure you want to proceed".
Future<bool> confirm(String message) {
  log.fine('Showing confirm message: $message');
  stdoutSink.add("$message (y/n)? ".charCodes);
  return streamFirst(stdinLines)
      .then((line) => new RegExp(r"^[yY]").hasMatch(line));
}

/// Wraps [stream] in a single-subscription [Stream] that emits the same data.
ByteStream wrapInputStream(InputStream stream) {
  var controller = new StreamController();
  if (stream.closed) {
    controller.close();
    return new ByteStream(controller.stream);
  }

  stream.onClosed = controller.close;
  stream.onData = () => controller.add(stream.read());
  stream.onError = (e) => controller.signalError(new AsyncError(e));
  return new ByteStream(controller.stream);
}

/// Wraps [stream] in a [StreamConsumer] so that [Stream]s can by piped into it
/// using [Stream.pipe]. Errors piped to the returned [StreamConsumer] will be
/// forwarded to the [Future] returned by [Stream.pipe].
StreamConsumer<List<int>, dynamic> wrapOutputStream(OutputStream stream) =>
  new _OutputStreamConsumer(stream);

/// A [StreamConsumer] that pipes data into an [OutputStream].
class _OutputStreamConsumer implements StreamConsumer<List<int>, dynamic> {
  final OutputStream _outputStream;

  _OutputStreamConsumer(this._outputStream);

  Future consume(Stream<List<int>> stream) {
    // TODO(nweiz): we have to manually keep track of whether or not the
    // completer has completed since the output stream could signal an error
    // after close() has been called but before it has shut down internally. See
    // the following TODO.
    var completed = false;
    var completer = new Completer();
    stream.listen((data) {
      // Writing empty data to a closed stream can cause errors.
      if (data.isEmpty) return;

      // TODO(nweiz): remove this try/catch when issue 7836 is fixed.
      try {
        _outputStream.write(data);
      } catch (e, stack) {
        if (!completed) completer.completeError(e, stack);
        completed = true;
      }
    }, onError: (e) {
      if (!completed) completer.completeError(e.error, e.stackTrace);
      completed = true;
    }, onDone: () => _outputStream.close());

    _outputStream.onError = (e) {
      if (!completed) completer.completeError(e);
      completed = true;
    };

    _outputStream.onClosed = () {
      if (!completed) completer.complete();
      completed = true;
    };

    return completer.future;
  }
}

/// Returns a [StreamSink] that pipes all data to [consumer] and a [Future] that
/// will succeed when [StreamSink] is closed or fail with any errors that occur
/// while writing.
Pair<StreamSink, Future> consumerToSink(StreamConsumer consumer) {
  var controller = new StreamController();
  var done = controller.stream.pipe(consumer);
  return new Pair<StreamSink, Future>(controller.sink, done);
}

// TODO(nweiz): remove this when issue 7786 is fixed.
/// Pipes all data and errors from [stream] into [sink]. When [stream] is done,
/// the returned [Future] is completed and [sink] is closed if [closeSink] is
/// true.
///
/// When an error occurs on [stream], that error is passed to [sink]. If
/// [unsubscribeOnError] is true, [Future] will be completed successfully and no
/// more data or errors will be piped from [stream] to [sink]. If
/// [unsubscribeOnError] and [closeSink] are both true, [sink] will then be
/// closed.
Future store(Stream stream, StreamSink sink,
    {bool unsubscribeOnError: true, closeSink: true}) {
  var completer = new Completer();
  stream.listen(sink.add,
      onError: (e) {
        sink.signalError(e);
        if (unsubscribeOnError) {
          completer.complete();
          if (closeSink) sink.close();
        }
      },
      onDone: () {
        if (closeSink) sink.close();
        completer.complete();
      }, unsubscribeOnError: unsubscribeOnError);
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
      .then((result) {
    // TODO(rnystrom): Remove this and change to returning one string.
    List<String> toLines(String output) {
      var lines = output.split(NEWLINE_PATTERN);
      if (!lines.isEmpty && lines.last == "") lines.removeLast();
      return lines;
    }

    var pubResult = new PubProcessResult(toLines(result.stdout),
                                toLines(result.stderr),
                                result.exitCode);

    log.processResult(executable, pubResult);
    return pubResult;
  });
}

/// Spawns the process located at [executable], passing in [args]. Returns a
/// [Future] that will complete with the [Process] once it's been started.
///
/// The spawned process will inherit its parent's environment variables. If
/// [environment] is provided, that will be used to augment (not replace) the
/// the inherited variables.
Future<PubProcess> startProcess(String executable, List<String> args,
    {workingDir, Map<String, String> environment}) =>
  _doProcess(Process.start, executable, args, workingDir, environment)
      .then((process) => new PubProcess(process));

/// A wrapper around [Process] that exposes `dart:async`-style APIs.
class PubProcess {
  /// The underlying `dart:io` [Process].
  final Process _process;

  /// The mutable field for [stdin].
  StreamSink<List<int>> _stdin;

  /// The mutable field for [stdinClosed].
  Future _stdinClosed;

  /// The mutable field for [stdout].
  ByteStream _stdout;

  /// The mutable field for [stderr].
  ByteStream _stderr;

  /// The mutable field for [exitCode].
  Future<int> _exitCode;

  /// The sink used for passing data to the process's standard input stream.
  /// Errors on this stream are surfaced through [stdinClosed], [stdout],
  /// [stderr], and [exitCode], which are all members of an [ErrorGroup].
  StreamSink<List<int>> get stdin => _stdin;

  // TODO(nweiz): write some more sophisticated Future machinery so that this
  // doesn't surface errors from the other streams/futures, but still passes its
  // unhandled errors to them. Right now it's impossible to recover from a stdin
  // error and continue interacting with the process.
  /// A [Future] that completes when [stdin] is closed, either by the user or by
  /// the process itself.
  ///
  /// This is in an [ErrorGroup] with [stdout], [stderr], and [exitCode], so any
  /// error in process will be passed to it, but won't reach the top-level error
  /// handler unless nothing has handled it.
  Future get stdinClosed => _stdinClosed;

  /// The process's standard output stream.
  ///
  /// This is in an [ErrorGroup] with [stdinClosed], [stderr], and [exitCode],
  /// so any error in process will be passed to it, but won't reach the
  /// top-level error handler unless nothing has handled it.
  ByteStream get stdout => _stdout;

  /// The process's standard error stream.
  ///
  /// This is in an [ErrorGroup] with [stdinClosed], [stdout], and [exitCode],
  /// so any error in process will be passed to it, but won't reach the
  /// top-level error handler unless nothing has handled it.
  ByteStream get stderr => _stderr;

  /// A [Future] that will complete to the process's exit code once the process
  /// has finished running.
  ///
  /// This is in an [ErrorGroup] with [stdinClosed], [stdout], and [stderr], so
  /// any error in process will be passed to it, but won't reach the top-level
  /// error handler unless nothing has handled it.
  Future<int> get exitCode => _exitCode;

  /// Creates a new [PubProcess] wrapping [process].
  PubProcess(Process process)
    : _process = process {
    var errorGroup = new ErrorGroup();

    var pair = consumerToSink(wrapOutputStream(process.stdin));
    _stdin = pair.first;
    _stdinClosed = errorGroup.registerFuture(pair.last);

    _stdout = new ByteStream(
        errorGroup.registerStream(wrapInputStream(process.stdout)));
    _stderr = new ByteStream(
        errorGroup.registerStream(wrapInputStream(process.stderr)));

    var exitCodeCompleter = new Completer();
    _exitCode = errorGroup.registerFuture(exitCodeCompleter.future);
    _process.onExit = (code) => exitCodeCompleter.complete(code);
  }

  /// Sends [signal] to the underlying process.
  bool kill([ProcessSignal signal = ProcessSignal.SIGTERM]) =>
    _process.kill(signal);
}

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

  log.process(executable, args);

  return fn(executable, args, options);
}

/// Wraps [input] to provide a timeout. If [input] completes before
/// [milliseconds] have passed, then the return value completes in the same way.
/// However, if [milliseconds] pass before [input] has completed, it completes
/// with a [TimeoutException] with [description] (which should be a fragment
/// describing the action that timed out).
///
/// Note that timing out will not cancel the asynchronous operation behind
/// [input].
Future timeout(Future input, int milliseconds, String description) {
  bool completed = false;
  var completer = new Completer();
  var timer = new Timer(milliseconds, (_) {
    completed = true;
    completer.completeError(new TimeoutException(
        'Timed out while $description.'));
  });
  input.then((value) {
    if (completed) return;
    timer.cancel();
    completer.complete(value);
  }).catchError((e) {
    if (completed) return;
    timer.cancel();
    completer.completeError(e.error, e.stackTrace);
  });
  return completer.future;
}

/// Creates a temporary directory and passes its path to [fn]. Once the [Future]
/// returned by [fn] completes, the temporary directory and all its contents
/// will be deleted.
Future withTempDir(Future fn(String path)) {
  var tempDir;
  return createTempDir().then((dir) {
    tempDir = dir;
    return fn(tempDir.path);
  }).whenComplete(() {
    log.fine('Cleaning up temp directory ${tempDir.path}.');
    return deleteDir(tempDir);
  });
}

/// Extracts a `.tar.gz` file from [stream] to [destination], which can be a
/// directory or a path. Returns whether or not the extraction was successful.
Future<bool> extractTarGz(Stream<List<int>> stream, destination) {
  destination = _getPath(destination);

  log.fine("Extracting .tar.gz stream to $destination.");

  if (Platform.operatingSystem == "windows") {
    return _extractTarGzWindows(stream, destination);
  }

  return startProcess("tar",
      ["--extract", "--gunzip", "--directory", destination]).then((process) {
    // Ignore errors on process.std{out,err}. They'll be passed to
    // process.exitCode, and we don't want them being top-levelled by
    // std{out,err}Sink.
    store(process.stdout.handleError((_) {}), stdoutSink, closeSink: false);
    store(process.stderr.handleError((_) {}), stderrSink, closeSink: false);
    return Future.wait([
      store(stream, process.stdin),
      process.exitCode
    ]);
  }).then((results) {
    var exitCode = results[1];
    if (exitCode != 0) {
      throw "Failed to extract .tar.gz stream to $destination (exit code "
        "$exitCode).";
    }
    log.fine("Extracted .tar.gz stream to $destination. Exit code $exitCode.");
  });
}

Future<bool> _extractTarGzWindows(Stream<List<int>> stream,
    String destination) {
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
  return createTempDir().then((temp) {
    // Write the archive to a temp file.
    tempDir = temp;
    return createFileFromStream(stream, join(tempDir, 'data.tar.gz'));
  }).then((_) {
    // 7zip can't unarchive from gzip -> tar -> destination all in one step
    // first we un-gzip it to a tar file.
    // Note: Setting the working directory instead of passing in a full file
    // path because 7zip says "A full path is not allowed here."
    return runProcess(command, ['e', 'data.tar.gz'], workingDir: tempDir);
  }).then((result) {
    if (result.exitCode != 0) {
      throw 'Could not un-gzip (exit code ${result.exitCode}). Error:\n'
          '${Strings.join(result.stdout, "\n")}\n'
          '${Strings.join(result.stderr, "\n")}';
    }
    // Find the tar file we just created since we don't know its name.
    return listDir(tempDir);
  }).then((files) {
    var tarFile;
    for (var file in files) {
      if (path.extension(file) == '.tar') {
        tarFile = file;
        break;
      }
    }

    if (tarFile == null) throw 'The gzip file did not contain a tar file.';

    // Untar the archive into the destination directory.
    return runProcess(command, ['x', tarFile], workingDir: destination);
  }).then((result) {
    if (result.exitCode != 0) {
      throw 'Could not un-tar (exit code ${result.exitCode}). Error:\n'
          '${Strings.join(result.stdout, "\n")}\n'
          '${Strings.join(result.stderr, "\n")}';
    }

    log.fine('Clean up 7zip temp directory ${tempDir.path}.');
    // TODO(rnystrom): Should also delete this if anything fails.
    return deleteDir(tempDir);
  }).then((_) => true);
}

/// Create a .tar.gz archive from a list of entries. Each entry can be a
/// [String], [Directory], or [File] object. The root of the archive is
/// considered to be [baseDir], which defaults to the current working directory.
/// Returns a [ByteStream] that will emit the contents of the archive.
ByteStream createTarGz(List contents, {baseDir}) {
  var buffer = new StringBuffer();
  buffer.add('Creating .tag.gz stream containing:\n');
  contents.forEach((file) => buffer.add('$file\n'));
  log.fine(buffer.toString());

  // TODO(nweiz): Propagate errors to the returned stream (including non-zero
  // exit codes). See issue 3657.
  var controller = new StreamController<List<int>>();

  if (baseDir == null) baseDir = path.current;
  baseDir = getFullPath(baseDir);
  contents = contents.map((entry) {
    entry = getFullPath(entry);
    if (!isBeneath(entry, baseDir)) {
      throw 'Entry $entry is not inside $baseDir.';
    }
    return relativeTo(entry, baseDir);
  }).toList();

  if (Platform.operatingSystem != "windows") {
    var args = ["--create", "--gzip", "--directory", baseDir];
    args.addAll(contents.map(_getPath));
    // TODO(nweiz): It's possible that enough command-line arguments will make
    // the process choke, so at some point we should save the arguments to a
    // file and pass them in via --files-from for tar and -i@filename for 7zip.
    startProcess("tar", args).then((process) {
      store(process.stdout, controller);
    }).catchError((e) {
      // We don't have to worry about double-signaling here, since the store()
      // above will only be reached if startProcess succeeds.
      controller.signalError(e.error, e.stackTrace);
      controller.close();
    });
    return new ByteStream(controller.stream);
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
    return runProcess(command, args, workingDir: baseDir).then((_) {
      // GZIP it. 7zip doesn't support doing both as a single operation. Send
      // the output to stdout.
      args = ["a", "unused", "-tgzip", "-so", tarFile];
      return startProcess(command, args);
    }).then((process) {
      // Ignore 7zip's stderr. 7zip writes its normal output to stderr. We don't
      // want to show that since it's meaningless.
      //
      // TODO(rnystrom): Should log the stderr and display it if an actual error
      // occurs.
      store(process.stdout, controller);
    });
  }).catchError((e) {
    // We don't have to worry about double-signaling here, since the store()
    // above will only be reached if everything succeeds.
    controller.signalError(e.error, e.stackTrace);
    controller.close();
  });
  return new ByteStream(controller.stream);
}

/// Exception thrown when an operation times out.
class TimeoutException implements Exception {
  final String message;

  const TimeoutException(this.message);

  String toString() => message;
}

/// Contains the results of invoking a [Process] and waiting for it to complete.
class PubProcessResult {
  final List<String> stdout;
  final List<String> stderr;
  final int exitCode;

  const PubProcessResult(this.stdout, this.stderr, this.exitCode);

  bool get success => exitCode == 0;
}

/// Gets a dart:io [File] for [entry], which can either already be a File or be
/// a path string.
File _getFile(entry) {
  if (entry is File) return entry;
  if (entry is String) return new File(entry);
  throw 'Entry $entry is not a supported type.';
}

/// Gets the path string for [entry], which can either already be a path string,
/// or be a [File] or [Directory]. Allows working generically with "file-like"
/// objects.
String _getPath(entry) {
  if (entry is String) return entry;
  if (entry is File) return entry.name;
  if (entry is Directory) return entry.path;
  throw 'Entry $entry is not a supported type.';
}

/// Gets a [Directory] for [entry], which can either already be one, or be a
/// [String].
Directory _getDirectory(entry) {
  if (entry is Directory) return entry;
  return new Directory(entry);
}

/// Gets a [Uri] for [uri], which can either already be one, or be a [String].
Uri _getUri(uri) {
  if (uri is Uri) return uri;
  return Uri.parse(uri);
}
