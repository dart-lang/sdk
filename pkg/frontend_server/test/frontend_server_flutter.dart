import 'dart:async' show StreamController;
import 'dart:convert' show utf8, LineSplitter;
import 'dart:io' show Directory, File, FileSystemEntity, IOSink, stdout;

import 'package:kernel/ast.dart' show Component;
import 'package:kernel/kernel.dart' show loadComponentFromBytes;
import 'package:kernel/verifier.dart' show verifyComponent;

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
  if (flutterDir == null || !(new Directory(flutterDir).existsSync())) {
    throw "Didn't get a valid flutter directory to work with.";
  }
  Directory flutterDirectory = new Directory(flutterDir);
  List<FileSystemEntity> allFlutterFiles =
      flutterDirectory.listSync(recursive: true, followLinks: false);
  Directory flutterPlatformDirectory;
  if (flutterPlatformDir == null) {
    List<File> platformFiles = new List<File>.from(allFlutterFiles.where((f) =>
        f.uri
            .toString()
            .endsWith("/flutter_patched_sdk/platform_strong.dill")));
    if (platformFiles.length < 1) {
      throw "Expected to find a flutter platform file but didn't.";
    }
    flutterPlatformDirectory = platformFiles.first.parent;
  } else {
    flutterPlatformDirectory = Directory(flutterPlatformDir);
  }
  if (!flutterPlatformDirectory.existsSync()) {
    throw "$flutterPlatformDirectory doesn't exist.";
  }
  if (!new File.fromUri(
          flutterPlatformDirectory.uri.resolve("platform_strong.dill"))
      .existsSync()) {
    throw "$flutterPlatformDirectory doesn't contain a "
        "platform_strong.dill file.";
  }
  print("Using $flutterPlatformDirectory as platform directory.");
  List<File> dotPackagesFiles = new List<File>.from(allFlutterFiles.where((f) =>
      (f.uri.toString().contains("/examples/") ||
          f.uri.toString().contains("/packages/")) &&
      f.uri.toString().endsWith("/.packages")));

  List<String> allCompilationErrors = [];
  for (File dotPackage in dotPackagesFiles) {
    Directory tempDir;
    Directory systemTempDir = Directory.systemTemp;
    tempDir = systemTempDir.createTempSync('foo bar');
    try {
      Directory testDir =
          new Directory.fromUri(dotPackage.parent.uri.resolve("test/"));
      if (!testDir.existsSync()) continue;
      if (testDir.toString().contains("packages/flutter_web_plugins/test/")) {
        // TODO(jensj): Figure out which tests are web-tests, and compile those
        // in a setup that can handle that.
        continue;
      }
      print("Go for $testDir");
      List<String> compilationErrors = await attemptStuff(
          tempDir, flutterPlatformDirectory, dotPackage, testDir);
      if (compilationErrors.isNotEmpty) {
        print("Notice that we had ${compilationErrors.length} "
            "compilation errors for $testDir");
        allCompilationErrors.addAll(compilationErrors);
      }
    } finally {
      tempDir.delete(recursive: true);
    }
  }
  if (allCompilationErrors.isNotEmpty) {
    print("Had a total of ${allCompilationErrors.length} compilation errors:");
    allCompilationErrors.forEach(print);
    throw "Had a total of ${allCompilationErrors.length} compilation errors";
  }
}

Future<List<String>> attemptStuff(
    Directory tempDir,
    Directory flutterPlatformDirectory,
    File dotPackage,
    Directory testDir) async {
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
    '--strong',
    '--target=flutter',
    '--packages',
    dotPackage.path,
    '--output-dill=${dillFile.path}',
    // '--unsafe-package-serialization',
  ];

  bool shouldSkip(File f) {
    // TODO(jensj): Come up with a better way to (temporarily) skip some tests.
    List<String> pathSegments = f.uri.pathSegments;
    if (pathSegments.sublist(pathSegments.length - 5).join("/") ==
        "packages/flutter/test/widgets/html_element_view_test.dart") {
      return true;
    }
    return false;
  }

  List<File> testFiles = new List<File>.from(testDir
      .listSync(recursive: true)
      .where((f) => f.path.endsWith("_test.dart") && !shouldSkip(f)));
  if (testFiles.isEmpty) return [];

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
  String shortTestPath =
      testFileIterator.current.path.substring(testDir.path.length);
  stdout.write("    => $shortTestPath");
  Stopwatch stopwatch2 = new Stopwatch()..start();
  inputStreamController
      .add('compile ${testFileIterator.current.path}\n'.codeUnits);
  int compilations = 0;
  List<String> compilationErrors = [];
  receivedResults.stream.listen((Result compiledResult) {
    stdout.write(" --- done in ${stopwatch2.elapsedMilliseconds} ms\n");
    stopwatch2.reset();
    bool error = false;
    try {
      compiledResult.expectNoErrors();
    } catch (e) {
      print("Got errors. Compiler output for this compile:");
      outputParser.allReceived.forEach(print);
      compilationErrors.add(testFileIterator.current.path);
      error = true;
    }
    if (!error) {
      List<int> resultBytes = dillFile.readAsBytesSync();
      Component component = loadComponentFromBytes(platformData);
      component = loadComponentFromBytes(resultBytes, component);
      verifyComponent(component);
      print("        => verified in ${stopwatch2.elapsedMilliseconds} ms.");
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
    String shortTestPath =
        testFileIterator.current.path.substring(testDir.path.length);
    stdout.write("    => $shortTestPath");
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

  print("Did $compilations compilations and verifications in "
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

  List<String> allReceived = new List<String>();

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
