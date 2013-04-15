// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper functionality to make working with IO easier.
library io;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:json';
import 'dart:uri';

import 'package:pathos/path.dart' as path;
import 'package:http/http.dart' show ByteStream;
import 'error_group.dart';
import 'exit_codes.dart' as exit_codes;
import 'log.dart' as log;
import 'utils.dart';

export 'package:http/http.dart' show ByteStream;

/// Returns whether or not [entry] is nested somewhere within [dir]. This just
/// performs a path comparison; it doesn't look at the actual filesystem.
bool isBeneath(String entry, String dir) {
  var relative = path.relative(entry, from: dir);
  return !path.isAbsolute(relative) && path.split(relative)[0] != '..';
}

/// Determines if a file or directory exists at [path].
bool entryExists(String path) =>
  dirExists(path) || fileExists(path) || linkExists(path);

/// Returns whether [link] exists on the file system. This will return `true`
/// for any symlink, regardless of what it points at or whether it's broken.
bool linkExists(String link) => new Link(link).existsSync();

/// Returns whether [file] exists on the file system. This will return `true`
/// for a symlink only if that symlink is unbroken and points to a file.
bool fileExists(String file) => new File(file).existsSync();

/// Reads the contents of the text file [file].
String readTextFile(String file) =>
    new File(file).readAsStringSync(encoding: Encoding.UTF_8);

/// Reads the contents of the binary file [file].
List<int> readBinaryFile(String file) {
  log.io("Reading binary file $file.");
  var contents = new File(file).readAsBytesSync();
  log.io("Read ${contents.length} bytes from $file.");
  return contents;
}

/// Creates [file] and writes [contents] to it.
///
/// If [dontLogContents] is true, the contents of the file will never be logged.
String writeTextFile(String file, String contents, {dontLogContents: false}) {
  // Sanity check: don't spew a huge file.
  log.io("Writing ${contents.length} characters to text file $file.");
  if (!dontLogContents && contents.length < 1024 * 1024) {
    log.fine("Contents:\n$contents");
  }

  new File(file).writeAsStringSync(contents);
  return file;
}

/// Creates [file] and writes [contents] to it.
String writeBinaryFile(String file, List<int> contents) {
  log.io("Writing ${contents.length} bytes to binary file $file.");
  new File(file).openSync(mode: FileMode.WRITE)
      ..writeFromSync(contents)
      ..closeSync();
  log.fine("Wrote text file $file.");
  return file;
}

/// Writes [stream] to a new file at path [file]. Will replace any file already
/// at that path. Completes when the file is done being written.
Future<String> createFileFromStream(Stream<List<int>> stream, String file) {
  log.io("Creating $file from stream.");

  return stream.pipe(new File(file).openWrite()).then((_) {
    log.fine("Created $file from stream.");
    return file;
  });
}

/// Creates a directory [dir].
String createDir(String dir) {
  new Directory(dir).createSync();
  return dir;
}

/// Ensures that [dirPath] and all its parent directories exist. If they don't
/// exist, creates them.
String ensureDir(String dirPath) {
  log.fine("Ensuring directory $dirPath exists.");
  var dir = new Directory(dirPath);
  if (dirPath == '.' || dirExists(dirPath)) return dirPath;

  ensureDir(path.dirname(dirPath));

  try {
    createDir(dirPath);
  } on DirectoryIOException catch (ex) {
    // Error 17 means the directory already exists (or 183 on Windows).
    if (ex.osError.errorCode == 17 || ex.osError.errorCode == 183) {
      log.fine("Got 'already exists' error when creating directory.");
    } else {
      throw ex;
    }
  }

  return dirPath;
}

/// Creates a temp directory whose name will be based on [dir] with a unique
/// suffix appended to it. If [dir] is not provided, a temp directory will be
/// created in a platform-dependent temporary location. Returns the path of the
/// created directory.
String createTempDir([dir = '']) {
  var tempDir = new Directory(dir).createTempSync();
  log.io("Created temp directory ${tempDir.path}");
  return tempDir.path;
}

/// Lists the contents of [dir]. If [recursive] is `true`, lists subdirectory
/// contents (defaults to `false`). If [includeHidden] is `true`, includes files
/// and directories beginning with `.` (defaults to `false`).
///
/// The returned paths are guaranteed to begin with [dir].
List<String> listDir(String dir, {bool recursive: false,
    bool includeHidden: false}) {
  List<String> doList(String dir, Set<String> listedDirectories) {
    var contents = <String>[];

    // Avoid recursive symlinks.
    var resolvedPath = new File(dir).fullPathSync();
    if (listedDirectories.contains(resolvedPath)) return [];

    listedDirectories = new Set<String>.from(listedDirectories);
    listedDirectories.add(resolvedPath);

    log.io("Listing directory $dir.");

    var children = <String>[];
    for (var entity in new Directory(dir).listSync()) {
      if (!includeHidden && path.basename(entity.path).startsWith('.')) {
        continue;
      }

      contents.add(entity.path);
      if (entity is Directory) {
        // TODO(nweiz): don't manually recurse once issue 4794 is fixed.
        // Note that once we remove the manual recursion, we'll need to
        // explicitly filter out files in hidden directories.
        if (recursive) {
          children.addAll(doList(entity.path, listedDirectories));
        }
      }
    }

    log.fine("Listed directory $dir:\n${contents.join('\n')}");
    contents.addAll(children);
    return contents;
  }

  return doList(dir, new Set<String>());
}

/// Returns whether [dir] exists on the file system. This will return `true` for
/// a symlink only if that symlink is unbroken and points to a directory.
bool dirExists(String dir) => new Directory(dir).existsSync();

/// Deletes whatever's at [path], whether it's a file, directory, or symlink. If
/// it's a directory, it will be deleted recursively.
void deleteEntry(String path) {
  if (linkExists(path)) {
    log.io("Deleting link $path.");
    new Link(path).deleteSync();
  } else if (dirExists(path)) {
    log.io("Deleting directory $path.");
    new Directory(path).deleteSync(recursive: true);
  } else if (fileExists(path)) {
    log.io("Deleting file $path.");
    new File(path).deleteSync();
  }
}

/// "Cleans" [dir]. If that directory already exists, it will be deleted. Then a
/// new empty directory will be created.
void cleanDir(String dir) {
  if (entryExists(dir)) deleteEntry(dir);
  createDir(dir);
}

/// Renames (i.e. moves) the directory [from] to [to].
void renameDir(String from, String to) {
  log.io("Renaming directory $from to $to.");
  new Directory(from).renameSync(to);
}

/// Creates a new symlink at path [symlink] that points to [target]. Returns a
/// [Future] which completes to the path to the symlink file.
///
/// If [relative] is true, creates a symlink with a relative path from the
/// symlink to the target. Otherwise, uses the [target] path unmodified.
///
/// Note that on Windows, only directories may be symlinked to.
void createSymlink(String target, String symlink,
    {bool relative: false}) {
  if (relative) {
    // Relative junction points are not supported on Windows. Instead, just
    // make sure we have a clean absolute path because it will interpret a
    // relative path to be relative to the cwd, not the symlink, and will be
    // confused by forward slashes.
    if (Platform.operatingSystem == 'windows') {
      target = path.normalize(path.absolute(target));
    } else {
      target = path.normalize(
          path.relative(target, from: path.dirname(symlink)));
    }
  }

  log.fine("Creating $symlink pointing to $target");
  new Link(symlink).createSync(target);
}

/// Creates a new symlink that creates an alias at [symlink] that points to the
/// `lib` directory of package [target]. If [target] does not have a `lib`
/// directory, this shows a warning if appropriate and then does nothing.
///
/// If [relative] is true, creates a symlink with a relative path from the
/// symlink to the target. Otherwise, uses the [target] path unmodified.
void createPackageSymlink(String name, String target, String symlink,
    {bool isSelfLink: false, bool relative: false}) {
  // See if the package has a "lib" directory.
  target = path.join(target, 'lib');
  log.fine("Creating ${isSelfLink ? "self" : ""}link for package '$name'.");
  if (dirExists(target)) {
    createSymlink(target, symlink, relative: relative);
    return;
  }

  // It's OK for the self link (i.e. the root package) to not have a lib
  // directory since it may just be a leaf application that only has
  // code in bin or web.
  if (!isSelfLink) {
    log.warning('Warning: Package "$name" does not have a "lib" directory so '
                'you will not be able to import any libraries from it.');
  }
}

/// Resolves [target] relative to the location of pub.dart.
String relativeToPub(String target) {
  var scriptPath = new File(new Options().script).fullPathSync();

  // Walk up until we hit the "util(s)" directory. This lets us figure out where
  // we are if this function is called from pub.dart, or one of the tests,
  // which also live under "utils", or from the SDK where pub is in "util".
  var utilDir = path.dirname(scriptPath);
  while (path.basename(utilDir) != 'utils' &&
         path.basename(utilDir) != 'util') {
    if (path.basename(utilDir) == '') throw 'Could not find path to pub.';
    utilDir = path.dirname(utilDir);
  }

  return path.normalize(path.join(utilDir, 'pub', target));
}

/// A line-by-line stream of standard input.
final Stream<String> stdinLines = streamToLines(
    new ByteStream(stdin).toStringStream());

/// Displays a message and reads a yes/no confirmation from the user. Returns
/// a [Future] that completes to `true` if the user confirms or `false` if they
/// do not.
///
/// This will automatically append " (y/n)?" to the message, so [message]
/// should just be a fragment like, "Are you sure you want to proceed".
Future<bool> confirm(String message) {
  log.fine('Showing confirm message: $message');
  stdout.write("$message (y/n)? ");
  return streamFirst(stdinLines)
      .then((line) => new RegExp(r"^[yY]").hasMatch(line));
}

/// Reads and discards all output from [stream]. Returns a [Future] that
/// completes when the stream is closed.
Future drainStream(Stream stream) {
  return stream.fold(null, (x, y) {});
}

/// Returns a [EventSink] that pipes all data to [consumer] and a [Future] that
/// will succeed when [EventSink] is closed or fail with any errors that occur
/// while writing.
Pair<EventSink, Future> consumerToSink(StreamConsumer consumer) {
  var controller = new StreamController();
  var done = controller.stream.pipe(consumer);
  return new Pair<EventSink, Future>(controller.sink, done);
}

// TODO(nweiz): remove this when issue 7786 is fixed.
/// Pipes all data and errors from [stream] into [sink]. When [stream] is done,
/// the returned [Future] is completed and [sink] is closed if [closeSink] is
/// true.
///
/// When an error occurs on [stream], that error is passed to [sink]. If
/// [cancelOnError] is true, [Future] will be completed successfully and no
/// more data or errors will be piped from [stream] to [sink]. If
/// [cancelOnError] and [closeSink] are both true, [sink] will then be
/// closed.
Future store(Stream stream, EventSink sink,
    {bool cancelOnError: true, closeSink: true}) {
  var completer = new Completer();
  stream.listen(sink.add,
      onError: (e) {
        sink.addError(e);
        if (cancelOnError) {
          completer.complete();
          if (closeSink) sink.close();
        }
      },
      onDone: () {
        if (closeSink) sink.close();
        completer.complete();
      }, cancelOnError: cancelOnError);
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
      var lines = splitLines(output);
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
  EventSink<List<int>> _stdin;

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
  EventSink<List<int>> get stdin => _stdin;

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

    var pair = consumerToSink(process.stdin);
    _stdin = pair.first;
    _stdinClosed = errorGroup.registerFuture(pair.last);

    _stdout = new ByteStream(
        errorGroup.registerStream(process.stdout));
    _stderr = new ByteStream(
        errorGroup.registerStream(process.stderr));

    var exitCodeCompleter = new Completer();
    _exitCode = errorGroup.registerFuture(exitCodeCompleter.future);
    _process.exitCode.then((code) => exitCodeCompleter.complete(code));
  }

  /// Sends [signal] to the underlying process.
  bool kill([ProcessSignal signal = ProcessSignal.SIGTERM]) =>
    _process.kill(signal);
}

/// Calls [fn] with appropriately modified arguments. [fn] should have the same
/// signature as [Process.start], except that the returned [Future] may have a
/// type other than [Process].
Future _doProcess(Function fn, String executable, List<String> args,
    String workingDir, Map<String, String> environment) {
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
    options.workingDirectory = workingDir;
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
  var completer = new Completer();
  var timer = new Timer(new Duration(milliseconds: milliseconds), () {
    completer.completeError(new TimeoutException(
        'Timed out while $description.'));
  });
  input.then((value) {
    if (completer.isCompleted) return;
    timer.cancel();
    completer.complete(value);
  }).catchError((e) {
    if (completer.isCompleted) return;
    timer.cancel();
    completer.completeError(e);
  });
  return completer.future;
}

/// Creates a temporary directory and passes its path to [fn]. Once the [Future]
/// returned by [fn] completes, the temporary directory and all its contents
/// will be deleted. [fn] can also return `null`, in which case the temporary
/// directory is deleted immediately afterwards.
///
/// Returns a future that completes to the value that the future returned from
/// [fn] completes to.
Future withTempDir(Future fn(String path)) {
  return new Future.sync(() {
    var tempDir = createTempDir();
    return new Future.sync(() => fn(tempDir))
        .whenComplete(() => deleteEntry(tempDir));
  });
}

/// Extracts a `.tar.gz` file from [stream] to [destination]. Returns whether
/// or not the extraction was successful.
Future<bool> extractTarGz(Stream<List<int>> stream, String destination) {
  log.fine("Extracting .tar.gz stream to $destination.");

  if (Platform.operatingSystem == "windows") {
    return _extractTarGzWindows(stream, destination);
  }

  return startProcess("tar",
      ["--extract", "--gunzip", "--directory", destination]).then((process) {
    // Ignore errors on process.std{out,err}. They'll be passed to
    // process.exitCode, and we don't want them being top-levelled by
    // std{out,err}Sink.
    store(process.stdout.handleError((_) {}), stdout, closeSink: false);
    store(process.stderr.handleError((_) {}), stderr, closeSink: false);
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

  return withTempDir((tempDir) {
    // Write the archive to a temp file.
    var dataFile = path.join(tempDir, 'data.tar.gz');
    return createFileFromStream(stream, dataFile).then((_) {
      // 7zip can't unarchive from gzip -> tar -> destination all in one step
      // first we un-gzip it to a tar file.
      // Note: Setting the working directory instead of passing in a full file
      // path because 7zip says "A full path is not allowed here."
      return runProcess(command, ['e', 'data.tar.gz'], workingDir: tempDir);
    }).then((result) {
      if (result.exitCode != 0) {
        throw 'Could not un-gzip (exit code ${result.exitCode}). Error:\n'
            '${result.stdout.join("\n")}\n'
            '${result.stderr.join("\n")}';
      }

      // Find the tar file we just created since we don't know its name.
      var tarFile = listDir(tempDir).firstWhere(
          (file) => path.extension(file) == '.tar',
          orElse: () {
        throw 'The gzip file did not contain a tar file.';
      });

      // Untar the archive into the destination directory.
      return runProcess(command, ['x', tarFile], workingDir: destination);
    }).then((result) {
      if (result.exitCode != 0) {
        throw 'Could not un-tar (exit code ${result.exitCode}). Error:\n'
            '${result.stdout.join("\n")}\n'
            '${result.stderr.join("\n")}';
      }
      return true;
    });
  });
}

/// Create a .tar.gz archive from a list of entries. Each entry can be a
/// [String], [Directory], or [File] object. The root of the archive is
/// considered to be [baseDir], which defaults to the current working directory.
/// Returns a [ByteStream] that will emit the contents of the archive.
ByteStream createTarGz(List contents, {baseDir}) {
  var buffer = new StringBuffer();
  buffer.write('Creating .tag.gz stream containing:\n');
  contents.forEach((file) => buffer.write('$file\n'));
  log.fine(buffer.toString());

  var controller = new StreamController<List<int>>();

  if (baseDir == null) baseDir = path.current;
  baseDir = path.absolute(baseDir);
  contents = contents.map((entry) {
    entry = path.absolute(entry);
    if (!isBeneath(entry, baseDir)) {
      throw 'Entry $entry is not inside $baseDir.';
    }
    return path.relative(entry, from: baseDir);
  }).toList();

  if (Platform.operatingSystem != "windows") {
    var args = ["--create", "--gzip", "--directory", baseDir];
    args.addAll(contents);
    // TODO(nweiz): It's possible that enough command-line arguments will make
    // the process choke, so at some point we should save the arguments to a
    // file and pass them in via --files-from for tar and -i@filename for 7zip.
    startProcess("tar", args).then((process) {
      store(process.stdout, controller);
    }).catchError((e) {
      // We don't have to worry about double-signaling here, since the store()
      // above will only be reached if startProcess succeeds.
      controller.addError(e);
      controller.close();
    });
    return new ByteStream(controller.stream);
  }

  withTempDir((tempDir) {
    // Create the tar file.
    var tarFile = path.join(tempDir, "intermediate.tar");
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
      return store(process.stdout, controller);
    });
  }).catchError((e) {
    // We don't have to worry about double-signaling here, since the store()
    // above will only be reached if everything succeeds.
    controller.addError(e);
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

/// Gets a [Uri] for [uri], which can either already be one, or be a [String].
Uri _getUri(uri) {
  if (uri is Uri) return uri;
  return Uri.parse(uri);
}
