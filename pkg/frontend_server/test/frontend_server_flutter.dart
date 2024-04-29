// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show StreamController, Zone;
import 'dart:collection' show HashSet;
import 'dart:convert' show Encoding, LineSplitter, utf8;
import 'dart:io'
    show
        Directory,
        File,
        FileMode,
        FileSystemEntity,
        IOOverrides,
        IOSink,
        exitCode;
import 'dart:typed_data' show BytesBuilder, Uint8List;

import 'package:frontend_server/starter.dart';
import 'package:kernel/ast.dart' show Component, Library;
import 'package:kernel/binary/multi_binary_loader.dart' show MultiBinaryLoader;
import 'package:kernel/target/targets.dart';
import 'package:kernel/verifier.dart' show VerificationStage, verifyComponent;
import 'package:vm/kernel_front_end.dart';

Future<void> main(List<String> args) async {
  String? flutterDir;
  String? flutterPlatformDir;
  for (String arg in args) {
    if (arg.startsWith("--flutterDir=")) {
      flutterDir = arg.substring(13);
    } else if (arg.startsWith("--flutterPlatformDir=")) {
      flutterPlatformDir = arg.substring(21);
    }
  }

  await compileTests(flutterDir, flutterPlatformDir, new StdoutLogger());
}

Future compileTests(
    String? flutterDir, String? flutterPlatformDir, Logger logger,
    {String? filter, int shards = 1, int shard = 0}) async {
  if (flutterDir == null || !(new Directory(flutterDir).existsSync())) {
    throw "Didn't get a valid flutter directory to work with.";
  }
  if (shards < 1) {
    throw "Shards must be >= 1";
  }
  if (shard < 0) {
    throw "Shard must be >= 0";
  }
  if (shard >= shards) {
    throw "Shard must be < shards";
  }
  // Ensure the path ends in a slash.
  final Directory flutterDirectory =
      new Directory.fromUri(new Directory(flutterDir).uri);

  List<FileSystemEntity> allFlutterFiles =
      flutterDirectory.listSync(recursive: true, followLinks: false);
  Directory flutterPlatformDirectoryTmp;

  if (flutterPlatformDir == null) {
    List<File> platformFiles = new List<File>.from(allFlutterFiles.where((f) =>
        f.uri
            .toString()
            .endsWith("/flutter_patched_sdk/platform_strong.dill")));
    if (platformFiles.isEmpty) {
      throw "Expected to find a flutter platform file but didn't.";
    }
    flutterPlatformDirectoryTmp = platformFiles.first.parent;
  } else {
    flutterPlatformDirectoryTmp = new Directory(flutterPlatformDir);
  }
  if (!flutterPlatformDirectoryTmp.existsSync()) {
    throw "$flutterPlatformDirectoryTmp doesn't exist.";
  }
  // Ensure the path ends in a slash.
  final Directory flutterPlatformDirectory =
      new Directory.fromUri(flutterPlatformDirectoryTmp.uri);

  if (!new File.fromUri(
          flutterPlatformDirectory.uri.resolve("platform_strong.dill"))
      .existsSync()) {
    throw "$flutterPlatformDirectory doesn't contain a "
        "platform_strong.dill file.";
  }
  logger.notice("Using $flutterPlatformDirectory as platform directory.");
  List<File> packageConfigFiles = new List<File>.from(allFlutterFiles.where(
      (f) =>
          (f.uri.toString().contains("/examples/") ||
              f.uri.toString().contains("/packages/")) &&
          f.uri.toString().endsWith("/.dart_tool/package_config.json")));

  List<String> allCompilationErrors = [];
  final Directory systemTempDir = Directory.systemTemp;
  List<_QueueEntry> queue = [];
  int totalFiles = 0;
  for (int i = 0; i < packageConfigFiles.length; i++) {
    File packageConfig = packageConfigFiles[i];
    Directory testDir =
        new Directory.fromUri(packageConfig.parent.uri.resolve("../test/"));
    if (!testDir.existsSync()) continue;
    if (testDir.toString().contains("packages/flutter_web_plugins/test/")) {
      // TODO(jensj): Figure out which tests are web-tests, and compile those
      // in a setup that can handle that.
      continue;
    }
    List<File> testFiles =
        new List<File>.from(testDir.listSync(recursive: true).where((f) {
      if (!f.path.endsWith("_test.dart")) return false;
      if (filter != null) {
        String testName = f.path.substring(flutterDirectory.path.length);
        if (!testName.startsWith(filter)) return false;
      }
      return true;
    }));

    if (testFiles.isEmpty) continue;
    queue.add(new _QueueEntry(testFiles, packageConfig, testDir));
    totalFiles += testFiles.length;
  }

  // Process queue, taking shards into account.
  // This involves ignoring some queue entries and cutting others up to
  // process exactly the files assigned to this shard.
  int shardChunkSize = (totalFiles + shards - 1) ~/ shards;
  int chunkStart = shard * shardChunkSize;
  int chunkEnd = (shard + 1) * shardChunkSize;
  int processedFiles = 0;

  for (_QueueEntry queueEntry in queue) {
    if (processedFiles < chunkEnd &&
        processedFiles + queueEntry.files.length >= chunkStart) {
      List<File> chunk = [];
      for (File file in queueEntry.files) {
        if (processedFiles >= chunkStart && processedFiles < chunkEnd) {
          chunk.add(file);
        }
        processedFiles++;
      }

      await _processFiles(
          systemTempDir,
          chunk,
          flutterPlatformDirectory,
          queueEntry.packageConfig,
          queueEntry.testDir,
          flutterDirectory,
          logger,
          filter,
          allCompilationErrors);
    } else {
      // None of these files are part of the chunk.
      processedFiles += queueEntry.files.length;
    }
  }

  if (allCompilationErrors.isNotEmpty) {
    logger.notice(
        "Had a total of ${allCompilationErrors.length} compilation errors:");
    allCompilationErrors.forEach(logger.notice);
    exitCode = 1;
  }
}

class _QueueEntry {
  final List<File> files;
  final File packageConfig;
  final Directory testDir;

  _QueueEntry(this.files, this.packageConfig, this.testDir);
}

Future<void> _processFiles(
    Directory systemTempDir,
    List<File> files,
    Directory flutterPlatformDirectory,
    File packageConfig,
    Directory testDir,
    Directory flutterDirectory,
    Logger logger,
    String? filter,
    List<String> allCompilationErrors) async {
  Directory tempDir = systemTempDir.createTempSync('flutter_frontend_test');
  try {
    List<String> compilationErrors = await attemptStuff(
        files,
        tempDir,
        flutterPlatformDirectory,
        packageConfig,
        testDir,
        flutterDirectory,
        logger,
        filter);
    if (compilationErrors.isNotEmpty) {
      logger.notice("Notice that we had ${compilationErrors.length} "
          "compilation errors for $testDir");
      allCompilationErrors.addAll(compilationErrors);
    }
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

Future<List<String>> attemptStuff(
    List<File> testFiles,
    Directory tempDir,
    Directory flutterPlatformDirectory,
    File packageConfig,
    Directory testDir,
    Directory flutterDirectory,
    Logger logger,
    String? filter) async {
  if (testFiles.isEmpty) return [];

  File dillFile = new File('${tempDir.path}/dill.dill');
  if (dillFile.existsSync()) {
    throw "$dillFile already exists.";
  }

  Uint8List platformData = new File.fromUri(
          flutterPlatformDirectory.uri.resolve("platform_strong.dill"))
      .readAsBytesSync();
  final String targetName = 'flutter';
  final Target target = createFrontEndTarget(targetName)!;
  final List<String> args = <String>[
    '--sdk-root',
    flutterPlatformDirectory.path,
    '--incremental',
    '--target=$targetName',
    '--packages',
    packageConfig.path,
    '--output-dill=${dillFile.path}',
  ];

  Stopwatch stopwatch = new Stopwatch()..start();

  final StreamController<List<int>> inputStreamController =
      new StreamController<List<int>>();
  final StreamController<List<int>> stdoutStreamController =
      new StreamController<List<int>>();
  final IOSink ioSink = new IOSink(stdoutStreamController.sink);
  StreamController<Result> receivedResults = new StreamController<Result>();

  final OutputParser outputParser = new OutputParser(receivedResults);
  stdoutStreamController.stream
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(outputParser.listener);

  Iterator<File> testFileIterator = testFiles.iterator;
  testFileIterator.moveNext();

  Zone parentZone = Zone.current;
  Map<String, _MockFile> files = {};

  /// Each test writes a complete (modulo platform) dill, often taking around
  /// 40 MB. With 1,500+ tests thats easily 50+ GB data to write. We don't
  /// really need it as an actual file though, we just need to get a hold on it
  /// below so we can run verification on it. We thus use [IOOverrides] to
  /// "catch" dill files (`new File("whatnot.dill")`) so we can write those to
  /// memory instead of to actual files.
  /// This is specialized for how it's actually written in the production code
  /// (via `openWrite`) and will fail if that changes (at which point it will
  /// have to be updated).
  final Future<int> result = IOOverrides.runZoned(() {
    return starter(args, input: inputStreamController.stream, output: ioSink);
  }, createFile: (String path) {
    if (files[path] != null) return files[path]!;
    File f = parentZone.run(() => new File(path));
    if (path.endsWith(".dill")) return files[path] = new _MockFile(f);
    return f;
  });

  Set<Library> alreadyVerifiedLibraries = new HashSet.identity();
  MultiBinaryLoader multiBinaryLoader = new MultiBinaryLoader();

  String testName =
      testFileIterator.current.path.substring(flutterDirectory.path.length);

  logger.logTestStart(testName);
  logger.notice("    => $testName");
  Stopwatch stopwatch2 = new Stopwatch()..start();
  inputStreamController
      .add('compile ${testFileIterator.current.path}\n'.codeUnits);
  int compilations = 0;
  List<String> compilationErrors = [];
  receivedResults.stream.listen((Result compiledResult) {
    logger.notice(" --- done in ${stopwatch2.elapsedMilliseconds} ms\n");
    stopwatch2.reset();
    bool error = false;
    try {
      compiledResult.expectNoErrors();
    } catch (e) {
      logger.log("Got errors. Compiler output for this compile:");
      outputParser.allReceived.forEach(logger.log);
      compilationErrors.add(testFileIterator.current.path);
      error = true;
    }

    if (!error) {
      try {
        _MockIOSink sink = files[dillFile.path]!.writeSink!;
        Uint8List resultBytes = sink.bb.takeBytes();
        List<List<int>> originalDataChunks = sink.originalDataChunks;
        // The frontend-server serializes with the incremental serializer which
        // works by outputting previously serialized component bytes, i.e. a
        // single dill actually contains several components, and many of these
        // components will byte-for-byte be the same between compiles.
        // Furthermore what's added to the sink will be the *identical*
        // Uint8List for the same bytes.
        // We utilize this here by a) loading with the (same) MultiBinaryLoader
        // which generally (with no additional help) figure out if a
        // sub-component was previously loaded from the exact same bytes;
        // b) additionally help it by returning the *identical* chunk
        // representing a sub components bytes if available, which will allow it
        // to not having to compare bytes, but simple use an identity hash on
        // the list.
        Component component = multiBinaryLoader.load(
            [platformData, resultBytes], (Uint8List data, int from, int to) {
          if (!identical(data, resultBytes)) return null;
          // We're asked if we have an alternative to the bytes in [data]
          // between [from] and [to]: We search the chunks used, and return the
          // matching one if any. This will generally be *identical* to any
          // previous one which allows us to not compare bytes.
          int at = 0;
          for (List<int> chunk in originalDataChunks) {
            if (from == at && chunk is Uint8List) {
              int length = to - from;
              if (chunk.length == length) {
                return chunk;
              }
            }
            if (at > from) return null;
            at += chunk.length;
          }
          return null;
        });
        verifyComponent(
          target,
          VerificationStage.afterModularTransformations,
          component,
          skipPlatform: true,
          librarySkipFilter: (library) =>
              !alreadyVerifiedLibraries.add(library),
        );
        logger.log(
            "        => verified in ${stopwatch2.elapsedMilliseconds} ms.");
      } catch (e, st) {
        logger.log("Crash when trying to verify:");
        logger.log("Error: $e");
        logger.log("Stack trace: $st");
        error = true;

        // If there's been a crash we might have left the AST in a bad state.
        // To avoid any potential issues caused by this we reset the loader etc.
        alreadyVerifiedLibraries = new HashSet.identity();
        multiBinaryLoader = new MultiBinaryLoader();
      }
    }

    if (!error) {
      logger.logExpectedResult(testName);
    } else {
      logger.logUnexpectedResult(testName);
    }

    files.clear();
    stopwatch2.reset();

    inputStreamController.add('accept\n'.codeUnits);
    inputStreamController.add('reset\n'.codeUnits);
    compilations++;
    outputParser.allReceived.clear();

    if (!testFileIterator.moveNext()) {
      inputStreamController.add('quit\n'.codeUnits);
      return;
    }

    testName =
        testFileIterator.current.path.substring(flutterDirectory.path.length);
    logger.logTestStart(testName);
    logger.notice("    => $testName");
    inputStreamController.add('recompile ${testFileIterator.current.path} abc\n'
            '${testFileIterator.current.uri}\n'
            'abc\n'
        .codeUnits);
  });

  int resultDone = await result;
  if (resultDone != 0) {
    throw "Got $resultDone, expected 0";
  }

  await inputStreamController.close();

  logger.log("Did $compilations compilations and verifications in "
      "${stopwatch.elapsedMilliseconds} ms.");

  return compilationErrors;
}

// The below is copied from incremental_compiler_test.dart,
// but with expect stuff replaced with ifs and throws
// (expect can only be used in tests via the test framework).

class OutputParser {
  OutputParser(this._receivedResults);
  bool expectSources = true;

  final StreamController<Result> _receivedResults;
  List<String>? _receivedSources;

  String? _boundaryKey;
  bool _readingSources = false;

  List<String> allReceived = <String>[];

  void listener(String s) {
    allReceived.add(s);
    if (_boundaryKey == null) {
      const String resultOutputSpace = 'result ';
      if (s.startsWith(resultOutputSpace)) {
        _boundaryKey = s.substring(resultOutputSpace.length);
      }
      _readingSources = false;
      _receivedSources?.clear();
      return;
    }

    if (s.startsWith(_boundaryKey!)) {
      // First boundaryKey separates compiler output from list of sources
      // (if we expect list of sources, which is indicated by receivedSources
      // being not null)
      if (expectSources && !_readingSources) {
        _readingSources = true;
        return;
      }
      // Second boundaryKey indicates end of frontend server response
      expectSources = true;
      _receivedResults.add(new Result(
          s.length > _boundaryKey!.length
              ? s.substring(_boundaryKey!.length + 1)
              : null,
          _receivedSources));
      _boundaryKey = null;
    } else {
      if (_readingSources) {
        (_receivedSources ??= <String>[]).add(s);
      }
    }
  }
}

class Result {
  String? status;
  List<String>? sources;

  Result(this.status, this.sources);

  void expectNoErrors({String? filename}) {
    CompilationResult result = new CompilationResult.parse(status!);
    if (result.errorsCount != 0) {
      throw "Got ${result.errorsCount} errors. Expected 0.";
    }
    if (filename != null) {
      if (result.filename != filename) {
        throw "Got ${result.filename} errors. Expected $filename.";
      }
    }
  }
}

class CompilationResult {
  late String filename;
  late int errorsCount;

  CompilationResult.parse(String? filenameAndErrorCount) {
    if (filenameAndErrorCount == null) {
      return;
    }
    int delim = filenameAndErrorCount.lastIndexOf(' ');
    if (delim <= 0) {
      throw "Expected $delim > 0...";
    }
    filename = filenameAndErrorCount.substring(0, delim);
    errorsCount = int.parse(filenameAndErrorCount.substring(delim + 1).trim());
  }
}

abstract class Logger {
  void logTestStart(String testName);
  void logExpectedResult(String testName);
  void logUnexpectedResult(String testName);
  void log(String s);
  void notice(String s);
}

class StdoutLogger extends Logger {
  final List<String> _log = <String>[];

  @override
  void logExpectedResult(String testName) {
    print("$testName: OK.");
    for (String s in _log) {
      print(s);
    }
  }

  @override
  void logTestStart(String testName) {
    _log.clear();
  }

  @override
  void logUnexpectedResult(String testName) {
    print("$testName: Fail.");
    for (String s in _log) {
      print(s);
    }
  }

  @override
  void log(String s) {
    _log.add(s);
  }

  @override
  void notice(String s) {
    print(s);
  }
}

class _MockFile implements File {
  final File _f;
  _MockIOSink? writeSink;

  _MockFile(this._f);

  @override
  bool existsSync() {
    return _f.existsSync();
  }

  @override
  Uint8List readAsBytesSync() {
    return _f.readAsBytesSync();
  }

  @override
  IOSink openWrite({FileMode mode = FileMode.write, Encoding encoding = utf8}) {
    return writeSink = new _MockIOSink();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class _MockIOSink implements IOSink {
  BytesBuilder bb = new BytesBuilder();
  List<List<int>> originalDataChunks = [];
  bool _closed = false;

  @override
  void add(List<int> data) {
    if (_closed) throw "Adding to closed";
    bb.add(data);
    originalDataChunks.add(data);
  }

  @override
  Future close() {
    _closed = true;
    return new Future.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
