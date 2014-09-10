library pub.io;
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:pool/pool.dart';
import 'package:http/http.dart' show ByteStream;
import 'package:http_multi_server/http_multi_server.dart';
import 'package:stack_trace/stack_trace.dart';
import 'exit_codes.dart' as exit_codes;
import 'exceptions.dart';
import 'error_group.dart';
import 'log.dart' as log;
import 'sdk.dart' as sdk;
import 'utils.dart';
export 'package:http/http.dart' show ByteStream;
final _descriptorPool = new Pool(32);
bool entryExists(String path) =>
    dirExists(path) || fileExists(path) || linkExists(path);
bool linkExists(String link) => new Link(link).existsSync();
bool fileExists(String file) => new File(file).existsSync();
String canonicalize(String pathString) {
  var seen = new Set<String>();
  var components =
      new Queue<String>.from(path.split(path.normalize(path.absolute(pathString))));
  var newPath = components.removeFirst();
  while (!components.isEmpty) {
    seen.add(path.join(newPath, path.joinAll(components)));
    var resolvedPath =
        resolveLink(path.join(newPath, components.removeFirst()));
    var relative = path.relative(resolvedPath, from: newPath);
    if (relative == '.') continue;
    var relativeComponents = new Queue<String>.from(path.split(relative));
    if (path.isAbsolute(relative)) {
      if (seen.contains(relative)) {
        newPath = relative;
      } else {
        newPath = relativeComponents.removeFirst();
        relativeComponents.addAll(components);
        components = relativeComponents;
      }
      continue;
    }
    while (relativeComponents.first == '..') {
      newPath = path.dirname(newPath);
      relativeComponents.removeFirst();
    }
    if (relativeComponents.length == 1) {
      newPath = path.join(newPath, relativeComponents.single);
      continue;
    }
    var newSubPath = path.join(newPath, path.joinAll(relativeComponents));
    if (seen.contains(newSubPath)) {
      newPath = newSubPath;
      continue;
    }
    relativeComponents.addAll(components);
    components = relativeComponents;
  }
  return newPath;
}
String resolveLink(String link) {
  var seen = new Set<String>();
  while (linkExists(link) && !seen.contains(link)) {
    seen.add(link);
    link =
        path.normalize(path.join(path.dirname(link), new Link(link).targetSync()));
  }
  return link;
}
String readTextFile(String file) =>
    new File(file).readAsStringSync(encoding: UTF8);
List<int> readBinaryFile(String file) {
  log.io("Reading binary file $file.");
  var contents = new File(file).readAsBytesSync();
  log.io("Read ${contents.length} bytes from $file.");
  return contents;
}
String writeTextFile(String file, String contents, {bool dontLogContents:
    false}) {
  log.io("Writing ${contents.length} characters to text file $file.");
  if (!dontLogContents && contents.length < 1024 * 1024) {
    log.fine("Contents:\n$contents");
  }
  new File(file).writeAsStringSync(contents);
  return file;
}
String writeBinaryFile(String file, List<int> contents) {
  log.io("Writing ${contents.length} bytes to binary file $file.");
  new File(file).openSync(mode: FileMode.WRITE)
      ..writeFromSync(contents)
      ..closeSync();
  log.fine("Wrote text file $file.");
  return file;
}
Future<String> createFileFromStream(Stream<List<int>> stream, String file) {
  log.io("Creating $file from stream.");
  return _descriptorPool.withResource(() {
    return Chain.track(stream.pipe(new File(file).openWrite())).then((_) {
      log.fine("Created $file from stream.");
      return file;
    });
  });
}
void copyFiles(Iterable<String> files, String baseDir, String destination) {
  for (var file in files) {
    var newPath = path.join(destination, path.relative(file, from: baseDir));
    ensureDir(path.dirname(newPath));
    copyFile(file, newPath);
  }
}
void copyFile(String source, String destination) {
  writeBinaryFile(destination, readBinaryFile(source));
}
String createDir(String dir) {
  new Directory(dir).createSync();
  return dir;
}
String ensureDir(String dir) {
  new Directory(dir).createSync(recursive: true);
  return dir;
}
String createTempDir(String base, String prefix) {
  var tempDir = new Directory(base).createTempSync(prefix);
  log.io("Created temp directory ${tempDir.path}");
  return tempDir.path;
}
String createSystemTempDir() {
  var tempDir = Directory.systemTemp.createTempSync('pub_');
  log.io("Created temp directory ${tempDir.path}");
  return tempDir.path;
}
List<String> listDir(String dir, {bool recursive: false, bool includeHidden:
    false, bool includeDirs: true, Iterable<String> whitelist}) {
  if (whitelist == null) whitelist = [];
  var whitelistFilter = createFileFilter(whitelist);
  return new Directory(
      dir).listSync(recursive: recursive, followLinks: true).where((entity) {
    if (!includeDirs && entity is Directory) return false;
    if (entity is Link) return false;
    if (includeHidden) return true;
    assert(entity.path.startsWith(dir));
    var pathInDir = entity.path.substring(dir.length);
    var whitelistedBasename =
        whitelistFilter.firstWhere(pathInDir.contains, orElse: () => null);
    if (whitelistedBasename != null) {
      pathInDir =
          pathInDir.substring(0, pathInDir.length - whitelistedBasename.length);
    }
    if (pathInDir.contains("/.")) return false;
    if (Platform.operatingSystem != "windows") return true;
    return !pathInDir.contains("\\.");
  }).map((entity) => entity.path).toList();
}
bool dirExists(String dir) => new Directory(dir).existsSync();
void _attempt(String description, void operation()) {
  if (Platform.operatingSystem != 'windows') {
    operation();
    return;
  }
  getErrorReason(error) {
    if (error.osError.errorCode == 5) {
      return "access was denied";
    }
    if (error.osError.errorCode == 32) {
      return "it was in use by another process";
    }
    return null;
  }
  for (var i = 0; i < 2; i++) {
    try {
      operation();
      return;
    } on FileSystemException catch (error) {
      var reason = getErrorReason(error);
      if (reason == null) rethrow;
      log.io("Failed to $description because $reason. " "Retrying in 50ms.");
      sleep(new Duration(milliseconds: 50));
    }
  }
  try {
    operation();
  } on FileSystemException catch (error) {
    var reason = getErrorReason(error);
    if (reason == null) rethrow;
    fail(
        "Failed to $description because $reason.\n"
            "This may be caused by a virus scanner or having a file\n"
            "in the directory open in another application.");
  }
}
void deleteEntry(String path) {
  _attempt("delete entry", () {
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
  });
}
void cleanDir(String dir) {
  if (entryExists(dir)) deleteEntry(dir);
  ensureDir(dir);
}
void renameDir(String from, String to) {
  _attempt("rename directory", () {
    log.io("Renaming directory $from to $to.");
    try {
      new Directory(from).renameSync(to);
    } on IOException catch (error) {
      if (entryExists(to)) deleteEntry(to);
      rethrow;
    }
  });
}
void createSymlink(String target, String symlink, {bool relative: false}) {
  if (relative) {
    if (Platform.operatingSystem == 'windows') {
      target = path.normalize(path.absolute(target));
    } else {
      var symlinkDir = canonicalize(path.dirname(symlink));
      target = path.normalize(path.relative(target, from: symlinkDir));
    }
  }
  log.fine("Creating $symlink pointing to $target");
  new Link(symlink).createSync(target);
}
void createPackageSymlink(String name, String target, String symlink,
    {bool isSelfLink: false, bool relative: false}) {
  target = path.join(target, 'lib');
  if (!dirExists(target)) return;
  log.fine("Creating ${isSelfLink ? "self" : ""}link for package '$name'.");
  createSymlink(target, symlink, relative: relative);
}
final bool runningFromSdk = Platform.script.path.endsWith('.snapshot');
String assetPath(String target) {
  if (runningFromSdk) {
    return path.join(
        sdk.rootDirectory,
        'lib',
        '_internal',
        'pub',
        'asset',
        target);
  } else {
    return path.join(
        path.dirname(libraryPath('pub.io')),
        '..',
        '..',
        'asset',
        target);
  }
}
String get repoRoot {
  if (runningFromSdk) {
    throw new StateError("Can't get the repo root from the SDK.");
  }
  var libDir = path.dirname(libraryPath('pub.io'));
  if (libDir.contains('pub_async')) {
    return path.normalize(path.join(libDir, '..', '..', '..', '..', '..'));
  }
  return path.normalize(path.join(libDir, '..', '..', '..', '..', '..', '..'));
}
final Stream<String> stdinLines =
    streamToLines(new ByteStream(Chain.track(stdin)).toStringStream());
Future<bool> confirm(String message) {
  log.fine('Showing confirm message: $message');
  if (runningAsTest) {
    log.message("$message (y/n)?");
  } else {
    stdout.write(log.format("$message (y/n)? "));
  }
  return streamFirst(
      stdinLines).then((line) => new RegExp(r"^[yY]").hasMatch(line));
}
Future drainStream(Stream stream) {
  return stream.fold(null, (x, y) {});
}
Future flushThenExit(int status) {
  return Future.wait(
      [
          Chain.track(stdout.close()),
          Chain.track(stderr.close())]).then((_) => exit(status));
}
Pair<EventSink, Future> consumerToSink(StreamConsumer consumer) {
  var controller = new StreamController(sync: true);
  var done = controller.stream.pipe(consumer);
  return new Pair<EventSink, Future>(controller.sink, done);
}
Future store(Stream stream, EventSink sink, {bool cancelOnError: true,
    bool closeSink: true}) {
  var completer = new Completer();
  stream.listen(sink.add, onError: (e, stackTrace) {
    sink.addError(e, stackTrace);
    if (cancelOnError) {
      completer.complete();
      if (closeSink) sink.close();
    }
  }, onDone: () {
    if (closeSink) sink.close();
    completer.complete();
  }, cancelOnError: cancelOnError);
  return completer.future;
}
Future<PubProcessResult> runProcess(String executable, List<String> args,
    {workingDir, Map<String, String> environment}) {
  return _descriptorPool.withResource(() {
    return _doProcess(
        Process.run,
        executable,
        args,
        workingDir,
        environment).then((result) {
      var pubResult =
          new PubProcessResult(result.stdout, result.stderr, result.exitCode);
      log.processResult(executable, pubResult);
      return pubResult;
    });
  });
}
Future<PubProcess> startProcess(String executable, List<String> args,
    {workingDir, Map<String, String> environment}) {
  return _descriptorPool.request().then((resource) {
    return _doProcess(
        Process.start,
        executable,
        args,
        workingDir,
        environment).then((ioProcess) {
      var process = new PubProcess(ioProcess);
      process.exitCode.whenComplete(resource.release);
      return process;
    });
  });
}
PubProcessResult runProcessSync(String executable, List<String> args,
    {String workingDir, Map<String, String> environment}) {
  var result =
      _doProcess(Process.runSync, executable, args, workingDir, environment);
  var pubResult =
      new PubProcessResult(result.stdout, result.stderr, result.exitCode);
  log.processResult(executable, pubResult);
  return pubResult;
}
class PubProcess {
  final Process _process;
  EventSink<List<int>> _stdin;
  Future _stdinClosed;
  ByteStream _stdout;
  ByteStream _stderr;
  Future<int> _exitCode;
  EventSink<List<int>> get stdin => _stdin;
  Future get stdinClosed => _stdinClosed;
  ByteStream get stdout => _stdout;
  ByteStream get stderr => _stderr;
  Future<int> get exitCode => _exitCode;
  PubProcess(Process process) : _process = process {
    var errorGroup = new ErrorGroup();
    var pair = consumerToSink(process.stdin);
    _stdin = pair.first;
    _stdinClosed = errorGroup.registerFuture(Chain.track(pair.last));
    _stdout =
        new ByteStream(errorGroup.registerStream(Chain.track(process.stdout)));
    _stderr =
        new ByteStream(errorGroup.registerStream(Chain.track(process.stderr)));
    var exitCodeCompleter = new Completer();
    _exitCode =
        errorGroup.registerFuture(Chain.track(exitCodeCompleter.future));
    _process.exitCode.then((code) => exitCodeCompleter.complete(code));
  }
  bool kill([ProcessSignal signal = ProcessSignal.SIGTERM]) =>
      _process.kill(signal);
}
_doProcess(Function fn, String executable, List<String> args, String workingDir,
    Map<String, String> environment) {
  if ((Platform.operatingSystem == "windows") &&
      (executable.indexOf('\\') == -1)) {
    args = flatten(["/c", executable, args]);
    executable = "cmd";
  }
  log.process(executable, args, workingDir == null ? '.' : workingDir);
  return fn(
      executable,
      args,
      workingDirectory: workingDir,
      environment: environment);
}
Future timeout(Future input, int milliseconds, Uri url, String description) {
  var completer = new Completer();
  var duration = new Duration(milliseconds: milliseconds);
  var timer = new Timer(duration, () {
    var message =
        'Timed out after ${niceDuration(duration)} while ' '$description.';
    if (url.host == "pub.dartlang.org" ||
        url.host == "storage.googleapis.com") {
      message += "\nThis is likely a transient error. Please try again later.";
    }
    completer.completeError(new TimeoutException(message), new Chain.current());
  });
  input.then((value) {
    if (completer.isCompleted) return;
    timer.cancel();
    completer.complete(value);
  }).catchError((e, stackTrace) {
    if (completer.isCompleted) return;
    timer.cancel();
    completer.completeError(e, stackTrace);
  });
  return completer.future;
}
Future withTempDir(Future fn(String path)) {
  return syncFuture(() {
    var tempDir = createSystemTempDir();
    return syncFuture(
        () => fn(tempDir)).whenComplete(() => deleteEntry(tempDir));
  });
}
Future<HttpServer> bindServer(String host, int port) {
  if (host == 'localhost') return HttpMultiServer.loopback(port);
  return HttpServer.bind(host, port);
}
Future<bool> extractTarGz(Stream<List<int>> stream, String destination) {
  log.fine("Extracting .tar.gz stream to $destination.");
  if (Platform.operatingSystem == "windows") {
    return _extractTarGzWindows(stream, destination);
  }
  var args = ["--extract", "--gunzip", "--directory", destination];
  if (_noUnknownKeyword) {
    args.insert(0, "--warning=no-unknown-keyword");
  }
  return startProcess("tar", args).then((process) {
    store(process.stdout.handleError((_) {}), stdout, closeSink: false);
    store(process.stderr.handleError((_) {}), stderr, closeSink: false);
    return Future.wait([store(stream, process.stdin), process.exitCode]);
  }).then((results) {
    var exitCode = results[1];
    if (exitCode != exit_codes.SUCCESS) {
      throw new Exception(
          "Failed to extract .tar.gz stream to $destination " "(exit code $exitCode).");
    }
    log.fine("Extracted .tar.gz stream to $destination. Exit code $exitCode.");
  });
}
final bool _noUnknownKeyword = _computeNoUnknownKeyword();
bool _computeNoUnknownKeyword() {
  if (!Platform.isLinux) return false;
  var result = Process.runSync("tar", ["--version"]);
  if (result.exitCode != 0) {
    throw new ApplicationException(
        "Failed to run tar (exit code ${result.exitCode}):\n${result.stderr}");
  }
  var match =
      new RegExp(r"^tar \(GNU tar\) (\d+).(\d+)\n").firstMatch(result.stdout);
  if (match == null) return false;
  var major = int.parse(match[1]);
  var minor = int.parse(match[2]);
  return major >= 2 || (major == 1 && minor >= 23);
}
String get pathTo7zip {
  if (runningFromSdk) return assetPath(path.join('7zip', '7za.exe'));
  return path.join(repoRoot, 'third_party', '7zip', '7za.exe');
}
Future<bool> _extractTarGzWindows(Stream<List<int>> stream, String destination)
    {
  return withTempDir((tempDir) {
    var dataFile = path.join(tempDir, 'data.tar.gz');
    return createFileFromStream(stream, dataFile).then((_) {
      return runProcess(pathTo7zip, ['e', 'data.tar.gz'], workingDir: tempDir);
    }).then((result) {
      if (result.exitCode != exit_codes.SUCCESS) {
        throw new Exception(
            'Could not un-gzip (exit code ${result.exitCode}). ' 'Error:\n'
                '${result.stdout.join("\n")}\n' '${result.stderr.join("\n")}');
      }
      var tarFile = listDir(
          tempDir).firstWhere((file) => path.extension(file) == '.tar', orElse: () {
        throw new FormatException('The gzip file did not contain a tar file.');
      });
      return runProcess(pathTo7zip, ['x', tarFile], workingDir: destination);
    }).then((result) {
      if (result.exitCode != exit_codes.SUCCESS) {
        throw new Exception(
            'Could not un-tar (exit code ${result.exitCode}). ' 'Error:\n'
                '${result.stdout.join("\n")}\n' '${result.stderr.join("\n")}');
      }
      return true;
    });
  });
}
ByteStream createTarGz(List contents, {baseDir}) {
  return new ByteStream(futureStream(syncFuture(() {
    var buffer = new StringBuffer();
    buffer.write('Creating .tag.gz stream containing:\n');
    contents.forEach((file) => buffer.write('$file\n'));
    log.fine(buffer.toString());
    if (baseDir == null) baseDir = path.current;
    baseDir = path.absolute(baseDir);
    contents = contents.map((entry) {
      entry = path.absolute(entry);
      if (!path.isWithin(baseDir, entry)) {
        throw new ArgumentError('Entry $entry is not inside $baseDir.');
      }
      return path.relative(entry, from: baseDir);
    }).toList();
    if (Platform.operatingSystem != "windows") {
      var args = ["--create", "--gzip", "--directory", baseDir];
      args.addAll(contents);
      return startProcess("tar", args).then((process) => process.stdout);
    }
    var tempDir = createSystemTempDir();
    return syncFuture(() {
      var tarFile = path.join(tempDir, "intermediate.tar");
      var args = ["a", "-w$baseDir", tarFile];
      args.addAll(contents.map((entry) => '-i!$entry'));
      return runProcess(pathTo7zip, args, workingDir: baseDir).then((_) {
        args = ["a", "unused", "-tgzip", "-so", tarFile];
        return startProcess(pathTo7zip, args);
      }).then((process) => process.stdout);
    }).then((stream) {
      return stream.transform(onDoneTransformer(() => deleteEntry(tempDir)));
    }).catchError((e) {
      deleteEntry(tempDir);
      throw e;
    });
  })));
}
class PubProcessResult {
  final List<String> stdout;
  final List<String> stderr;
  final int exitCode;
  PubProcessResult(String stdout, String stderr, this.exitCode)
      : this.stdout = _toLines(stdout),
        this.stderr = _toLines(stderr);
  static List<String> _toLines(String output) {
    var lines = splitLines(output);
    if (!lines.isEmpty && lines.last == "") lines.removeLast();
    return lines;
  }
  bool get success => exitCode == exit_codes.SUCCESS;
}
Uri _getUri(uri) {
  if (uri is Uri) return uri;
  return Uri.parse(uri);
}
