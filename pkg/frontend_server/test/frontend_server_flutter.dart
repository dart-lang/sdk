import 'dart:async' show StreamController;
import 'dart:convert' show utf8, LineSplitter;
import 'dart:io' show Directory, File, FileSystemEntity, IOSink, exitCode;

import 'package:kernel/ast.dart' show Component;
import 'package:kernel/kernel.dart' show loadComponentFromBytes;
import 'package:kernel/verifier.dart' show verifyComponent;

import 'package:front_end/src/api_prototype/language_version.dart'
    show uriUsesLegacyLanguageVersion;

import 'package:front_end/src/api_unstable/vm.dart'
    show CompilerOptions, NnbdMode, StandardFileSystem;

import '../lib/frontend_server.dart';

main(List<String> args) async {
  String flutterDir;
  String flutterPlatformDir;
  for (String arg in args) {
    if (arg.startsWith("--flutterDir=")) {
      flutterDir = arg.substring(13);
    } else if (arg.startsWith("--flutterPlatformDir=")) {
      flutterPlatformDir = arg.substring(21);
    }
  }

  await compileTests(flutterDir, flutterPlatformDir, new StdoutLogger());
}

Future<NnbdMode> _getNNBDMode(Uri script, Uri packagesFileUri) async {
  final CompilerOptions compilerOptions = new CompilerOptions()
    ..sdkRoot = null
    ..fileSystem = StandardFileSystem.instance
    ..packagesFileUri = packagesFileUri
    ..sdkSummary = null
    ..nnbdMode = NnbdMode.Weak;

  if (await uriUsesLegacyLanguageVersion(script, compilerOptions)) {
    return NnbdMode.Weak;
  }
  return NnbdMode.Strong;
}

Future compileTests(String flutterDir, String flutterPlatformDir, Logger logger,
    {String filter, int shards: 1, int shard: 0}) async {
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
    if (platformFiles.length < 1) {
      throw "Expected to find a flutter platform file but didn't.";
    }
    flutterPlatformDirectoryTmp = platformFiles.first.parent;
  } else {
    flutterPlatformDirectoryTmp = Directory(flutterPlatformDir);
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
  List<File> dotPackagesFiles = new List<File>.from(allFlutterFiles.where((f) =>
      (f.uri.toString().contains("/examples/") ||
          f.uri.toString().contains("/packages/")) &&
      f.uri.toString().endsWith("/.packages")));

  List<String> allCompilationErrors = [];
  final Directory systemTempDir = Directory.systemTemp;
  List<_QueueEntry> queue = [];
  int totalFiles = 0;
  for (int i = 0; i < dotPackagesFiles.length; i++) {
    File dotPackage = dotPackagesFiles[i];
    Directory testDir =
        new Directory.fromUri(dotPackage.parent.uri.resolve("test/"));
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

    // Split into NNBD Strong and Weak so only the ones that match are
    // compiled togeher. If mixing-and-matching the first file (which could
    // be either) will setup the compiler which can lead to compilation errors
    // for another file, for instance if the first one is strong but a
    // subsequent one tries to opt out (i.e. is weak) an error is issued that
    // that's not possible.
    List<File> weak = [];
    List<File> strong = [];
    for (File file in testFiles) {
      if (await _getNNBDMode(file.uri, dotPackage.uri) == NnbdMode.Weak) {
        weak.add(file);
      } else {
        strong.add(file);
      }
    }
    for (List<File> files in [weak, strong]) {
      if (files.isEmpty) continue;
      queue.add(new _QueueEntry(files, dotPackage, testDir));
      totalFiles += files.length;
    }
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
          queueEntry.dotPackage,
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
  final File dotPackage;
  final Directory testDir;

  _QueueEntry(this.files, this.dotPackage, this.testDir);
}

Future<void> _processFiles(
    Directory systemTempDir,
    List<File> files,
    Directory flutterPlatformDirectory,
    File dotPackage,
    Directory testDir,
    Directory flutterDirectory,
    Logger logger,
    String filter,
    List<String> allCompilationErrors) async {
  Directory tempDir = systemTempDir.createTempSync('flutter_frontend_test');
  try {
    List<String> compilationErrors = await attemptStuff(
        files,
        tempDir,
        flutterPlatformDirectory,
        dotPackage,
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
    tempDir.delete(recursive: true);
  }
}

Future<List<String>> attemptStuff(
    List<File> testFiles,
    Directory tempDir,
    Directory flutterPlatformDirectory,
    File dotPackage,
    Directory testDir,
    Directory flutterDirectory,
    Logger logger,
    String filter) async {
  if (testFiles.isEmpty) return [];

  File dillFile = new File('${tempDir.path}/dill.dill');
  if (dillFile.existsSync()) {
    throw "$dillFile already exists.";
  }

  List<int> platformData = new File.fromUri(
          flutterPlatformDirectory.uri.resolve("platform_strong.dill"))
      .readAsBytesSync();
  final List<String> args = <String>[
    '--sdk-root',
    flutterPlatformDirectory.path,
    '--incremental',
    '--target=flutter',
    '--packages',
    dotPackage.path,
    '--output-dill=${dillFile.path}',
    // '--unsafe-package-serialization',
  ];

  Stopwatch stopwatch = new Stopwatch()..start();

  final StreamController<List<int>> inputStreamController =
      new StreamController<List<int>>();
  final StreamController<List<int>> stdoutStreamController =
      new StreamController<List<int>>();
  final IOSink ioSink = new IOSink(stdoutStreamController.sink);
  StreamController<Result> receivedResults = new StreamController<Result>();

  final outputParser = new OutputParser(receivedResults);
  stdoutStreamController.stream
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(outputParser.listener);

  Iterator<File> testFileIterator = testFiles.iterator;
  testFileIterator.moveNext();

  final Future<int> result =
      starter(args, input: inputStreamController.stream, output: ioSink);
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
      logger.logExpectedResult(testName);
    } catch (e) {
      logger.log("Got errors. Compiler output for this compile:");
      outputParser.allReceived.forEach(logger.log);
      compilationErrors.add(testFileIterator.current.path);
      error = true;
      logger.logUnexpectedResult(testName);
    }
    if (!error) {
      List<int> resultBytes = dillFile.readAsBytesSync();
      Component component = loadComponentFromBytes(platformData);
      component = loadComponentFromBytes(resultBytes, component);
      verifyComponent(component);
      logger
          .log("        => verified in ${stopwatch2.elapsedMilliseconds} ms.");
    }
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

  inputStreamController.close();

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

  StreamController<Result> _receivedResults;
  List<String> _receivedSources;

  String _boundaryKey;
  bool _readingSources;

  List<String> allReceived = <String>[];

  void listener(String s) {
    allReceived.add(s);
    if (_boundaryKey == null) {
      const String RESULT_OUTPUT_SPACE = 'result ';
      if (s.startsWith(RESULT_OUTPUT_SPACE)) {
        _boundaryKey = s.substring(RESULT_OUTPUT_SPACE.length);
      }
      _readingSources = false;
      _receivedSources?.clear();
      return;
    }

    if (s.startsWith(_boundaryKey)) {
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
          s.length > _boundaryKey.length
              ? s.substring(_boundaryKey.length + 1)
              : null,
          _receivedSources));
      _boundaryKey = null;
    } else {
      if (_readingSources) {
        if (_receivedSources == null) {
          _receivedSources = <String>[];
        }
        _receivedSources.add(s);
      }
    }
  }
}

class Result {
  String status;
  List<String> sources;

  Result(this.status, this.sources);

  void expectNoErrors({String filename}) {
    CompilationResult result = new CompilationResult.parse(status);
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
  String filename;
  int errorsCount;

  CompilationResult.parse(String filenameAndErrorCount) {
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
  List<String> _log = <String>[];

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

  void log(String s) {
    _log.add(s);
  }

  void notice(String s) {
    print(s);
  }
}
