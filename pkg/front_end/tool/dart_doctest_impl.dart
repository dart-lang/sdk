// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/messages/codes.dart' as codes;
import 'package:_fe_analyzer_shared/src/parser/async_modifier.dart'
    show AsyncModifier;
import 'package:_fe_analyzer_shared/src/parser/forwarding_listener.dart'
    show NullListener;
import 'package:_fe_analyzer_shared/src/parser/parser.dart' show Parser;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ScannerConfiguration;
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:_fe_analyzer_shared/src/scanner/utf8_bytes_scanner.dart'
    show Utf8BytesScanner;
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/file_system.dart';
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart';
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:front_end/src/api_prototype/standard_file_system.dart';
import 'package:front_end/src/base/combinator.dart';
import 'package:front_end/src/base/command_line_reporting.dart'
    as command_line_reporting;
import 'package:front_end/src/base/compiler_context.dart';
import 'package:front_end/src/base/hybrid_file_system.dart';
import 'package:front_end/src/base/incremental_compiler.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/base/uri_translator.dart';
import 'package:front_end/src/builder/library_builder.dart';
import 'package:front_end/src/codes/cfe_codes.dart';
import 'package:front_end/src/dill/dill_library_builder.dart';
import 'package:front_end/src/dill/dill_target.dart';
import 'package:front_end/src/kernel/utils.dart';
import 'package:front_end/src/source/diet_parser.dart'
    show useImplicitCreationExpressionInCfe;
import 'package:front_end/src/source/source_library_builder.dart';
import 'package:front_end/src/source/source_loader.dart';
import 'package:kernel/kernel.dart' as kernel
    show Combinator, Component, LibraryDependency, Location, Source;
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/target/targets.dart';
import 'package:vm/modular/target/vm.dart';

import '../test/incremental_suite.dart' show getOptions;
import 'utils.dart';

const _portMessageTest = "test";
const _portMessageGood = "good";
const _portMessageBad = "bad";
const _portMessageCrash = "crash";
const _portMessageParseError = "parseError";
const _portMessageDone = "done";

// TODO: This doesn't work on parts... (Well, it might, depending on how
// the part declares what file it's part of and if we've compiled other stuff
// first so we know more stuff).
class DartDocTest {
  DocTestIncrementalCompiler? savedIncrementalCompiler;
  late CompilerOptions options;
  late ProcessedOptions processedOpts;
  bool errors = false;
  List<DiagnosticMessage> errorMessages = [];
  final FileSystem? underlyingFileSystem;
  final bool silent;
  final bool onlyIncludeFirstError;
  bool printOnDiagnostic = true;

  DartDocTest(
      {this.underlyingFileSystem,
      this.silent = false,
      this.onlyIncludeFirstError = false});

  FileSystem _getFileSystem() =>
      underlyingFileSystem ?? StandardFileSystem.instance;

  void _print(Object? object) {
    if (!silent) print(object);
  }

  /// All-in-one. Process a file and return if it was good.
  Future<List<TestResult>> process(Uri uri) async {
    _print("\n\nProcessing $uri");
    Stopwatch stopwatch = new Stopwatch()..start();

    // Extract test cases in file.
    List<Test> tests = await extractTestsFromUri(uri);

    if (tests.isEmpty) {
      _print("No tests found in file in ${stopwatch.elapsedMilliseconds} ms.");
      return [];
    }
    _print("Found ${tests.length} test(s) in file "
        "in ${stopwatch.elapsedMilliseconds} ms.");

    return await compileAndRun(uri, tests);
  }

  Future<List<Test>> extractTestsFromUri(Uri uri) async {
    // Extract test cases in file.
    FileSystemEntity file = _getFileSystem().entityForUri(uri);
    List<int> rawBytes = await file.readAsBytes();
    return extractTests(
        rawBytes is Uint8List ? rawBytes : new Uint8List.fromList(rawBytes),
        uri);
  }

  Future<List<TestResult>> compileAndRun(Uri uri, List<Test> tests,
      {bool silent = false}) async {
    errors = false;
    errorMessages.clear();

    // Create code to amend the file with.
    List<int> lineNumberForStartOfTest = [];
    String testSource = "";
    if (tests.isNotEmpty) {
      StringBuffer sb = new StringBuffer();
      int lineNumber = 0;
      void addLine(String line, {bool newTest = false}) {
        sb.writeln(line);
        // Account for tests with line breaks in them.
        lineNumber += line.codeUnits.where((codeUnit) => codeUnit == 10).length;
        lineNumber++;
        if (newTest) {
          lineNumberForStartOfTest.add(lineNumber);
        }
      }

      addLine(
          r"Future<void> $dart$doc$test$tester(dynamic dartDocTest) async {");
      lineNumber++;
      for (Test test in tests) {
        switch (test) {
          case TestParseError():
            addLine(
                "dartDocTest.parseError(\"Parse error @ ${test.position}\");",
                newTest: true);
          case ExpectTest():
            addLine("try {", newTest: true);
            addLine("  dartDocTest.test(${test.call}, ${test.result});");
            addLine("} catch (e, st) {");
            addLine("  dartDocTest.crash(e, st);");
            addLine("}");
          case ThrowsTest():
            addLine("try {", newTest: true);
            addLine("  await dartDocTest.throws(() async { ${test.call}; });");
            addLine("} catch (e, st) {");
            addLine("  dartDocTest.crash(e, st);");
            addLine("}");
        }
      }
      addLine("}");

      testSource = sb.toString();
    }

    // Setup the incremental compiler.
    // We only want to reuse it if it didn't crash as that will make it wait
    // for the crashed compile to finish (and it won't).
    DocTestIncrementalCompiler incrementalCompiler =
        savedIncrementalCompiler ?? createIncrementalCompiler(uri);
    savedIncrementalCompiler = null;

    processedOpts.inputs.clear();
    processedOpts.inputs.add(uri);
    HybridFileSystem fileSystem = new HybridFileSystem(
        new MemoryFileSystem(new Uri(scheme: "dartdoctest", path: "/")),
        _getFileSystem());
    options.fileSystem = fileSystem;
    processedOpts.clearFileSystemCache();
    // Invalidate package uri to force re-finding of packages
    // (e.g. if we're now compiling somewhere else).
    incrementalCompiler.invalidate(processedOpts.packagesUri);

    Stopwatch stopwatch = new Stopwatch()..start();
    // Do print any errors in the actual file.
    printOnDiagnostic = true;
    IncrementalCompilerResult compilerResult =
        await incrementalCompiler.computeDelta(entryPoints: [uri]);
    kernel.Component component = compilerResult.component;
    if (errors) {
      _print("Got errors when compiling $uri "
          "in ${stopwatch.elapsedMilliseconds} ms.");
      List<String> errorStrings = [];
      for (DiagnosticMessage message in errorMessages) {
        for (String errorString in message.plainTextFormatted) {
          errorStrings.add(errorString);
          if (onlyIncludeFirstError) break;
        }
      }
      return [
        new TestResult(null, TestOutcome.CompilationError)
          ..message = errorStrings.join("\n")
      ];
    }
    _print("Compiled (1) in ${stopwatch.elapsedMilliseconds} ms.");
    stopwatch.reset();

    // Don't print errors in the tests up front.
    printOnDiagnostic = false;
    await incrementalCompiler.compileDartDocTestLibrary(
        testSource, component.uriToSource[uri]?.importUri ?? uri);

    final Uri dartDocMainUri = new Uri(scheme: "dartdoctest", path: "main");
    fileSystem.memory
        .entityForUri(dartDocMainUri)
        .writeAsStringSync(mainFileContent);

    incrementalCompiler.invalidate(dartDocMainUri);
    IncrementalCompilerResult compilerMainResult = await incrementalCompiler
        .computeDelta(entryPoints: [dartDocMainUri], fullComponent: true);
    kernel.Component componentMain = compilerMainResult.component;
    if (errors) {
      _print("Got errors in ${stopwatch.elapsedMilliseconds} ms.");

      // Map back to the offending test.
      List<List<String>?> testsWithErrors = List.filled(tests.length + 1, null);
      for (DiagnosticMessage message in errorMessages) {
        int testIndex = tests.length; // indicating no test.
        if (message is FormattedMessage) {
          testIndex = binarySearch(lineNumberForStartOfTest, message.line);
        }
        List<String> errorStrings = testsWithErrors[testIndex] ??= [];
        for (String errorString in message.plainTextFormatted) {
          // TODO(jensj): Should the fake url etc
          // (e.g. 'dartdoctest:tester:13:29:') be removed if we can map it to
          // a test?
          errorStrings.add(errorString);
          if (onlyIncludeFirstError) break;
        }
      }
      List<TestResult> result = [];
      for (int i = 0; i <= tests.length; i++) {
        List<String>? errors = testsWithErrors[i];
        if (errors == null) continue;
        Test? offendingTest;
        if (i < tests.length) {
          offendingTest = tests[i];
        }
        String message = errors.join("\n");
        result.add(new TestResult(offendingTest, TestOutcome.CompilationError)
          ..message = message);
        if (offendingTest != null) {
          _print("Compilation error:\n"
              "Test from ${offendingTest.location} has errors when compiling:\n"
              "$message\n");
        } else {
          _print("Compilation error:\n"
              "$message\n");
        }
      }
      return result;
    }
    _print("Compiled (2) in ${stopwatch.elapsedMilliseconds} ms.");
    stopwatch.reset();

    Directory tmpDir = Directory.systemTemp.createTempSync();
    Uri dillOutUri = tmpDir.uri.resolve("dartdoctestrun.dill");
    await writeComponentToFile(componentMain, dillOutUri);
    _print("Wrote dill in ${stopwatch.elapsedMilliseconds} ms.");
    stopwatch.reset();

    // Spawn URI (dill uri) to run tests.
    ReceivePort exitPort = new ReceivePort();
    ReceivePort errorPort = new ReceivePort();
    ReceivePort communicationPort = new ReceivePort();
    Completer<dynamic> completer = new Completer();
    bool error = false;
    exitPort.listen((message) {
      exitPort.close();
      errorPort.close();
      communicationPort.close();
      completer.complete();
    });
    errorPort.listen((message) {
      _print("Isolate had an error: $message.");
      error = true;
      exitPort.close();
      errorPort.close();
      communicationPort.close();
      completer.complete();
    });
    int testCount = 0;
    int goodCount = 0;
    int badCount = 0;
    int crashCount = 0;
    int parseErrorCount = 0;
    bool done = false;
    Test? currentTest;

    List<TestResult> result = [];

    communicationPort.listen((message) {
      if (done) {
        throw "Didn't expect any more messages. Got '$message'";
      }
      if (message == _portMessageTest) {
        currentTest = tests[testCount];
        testCount++;
      } else if (message == _portMessageGood) {
        goodCount++;
        result.add(new TestResult(currentTest!, TestOutcome.Pass));
      } else if (message.toString().startsWith("$_portMessageBad: ")) {
        badCount++;
        String strippedMessage =
            message.toString().substring("$_portMessageBad: ".length);
        result.add(new TestResult(currentTest!, TestOutcome.Failed)
          ..message = strippedMessage);
        _print("Failure:\n"
            "Test from ${currentTest!.location} failed with this message:\n"
            "$strippedMessage\n");
      } else if (message.toString().startsWith("$_portMessageCrash: ")) {
        List<String> strippedMessageLines = message
            .toString()
            .substring("$_portMessageCrash: ".length)
            .split("\n");
        int end = 1;
        for (int i = 0; i < strippedMessageLines.length; i++) {
          if (strippedMessageLines[i].contains(r"$dart$doc$test$tester ()")) {
            end = i;
            break;
          }
        }
        String strippedMessage =
            strippedMessageLines.sublist(0, end).join("\n");

        result.add(new TestResult(currentTest!, TestOutcome.Crash)
          ..message = strippedMessage);
        crashCount++;
        _print("Failure:\n"
            "Test from ${currentTest!.location} crashed with this message:\n"
            "$strippedMessage\n");
      } else if (message.toString().startsWith("$_portMessageParseError: ")) {
        String strippedMessage =
            message.toString().substring("$_portMessageParseError: ".length);
        result.add(
            new TestResult(currentTest!, TestOutcome.TestCompilationError)
              ..message = strippedMessage);
        parseErrorCount++;
        _print("Failure:\n"
            "Test from ${currentTest!.location} has a parse error:\n"
            "$strippedMessage\n");
      } else if (message == _portMessageDone) {
        done = true;
        // don't complete completer here. Expect the exit port to close.
      } else {
        throw "Didn't expect '$message'";
      }
    });
    // TODO: Possibly it should be launched in a process instead so we can
    // (sort of) catch and report exit calls in test code.
    await Isolate.spawnUri(
      dillOutUri,
      [],
      communicationPort.sendPort,
      onExit: exitPort.sendPort,
      onError: errorPort.sendPort,
    );
    await completer.future;
    tmpDir.deleteSync(recursive: true);

    // We finished successfully. Save the incremental compiler.
    savedIncrementalCompiler = incrementalCompiler;

    if (error) {
      _print("Completed with an error in ${stopwatch.elapsedMilliseconds} ms.");
      return [new TestResult(null, TestOutcome.RuntimeError)];
    } else if (!done) {
      _print(
          "Didn't complete correctly in ${stopwatch.elapsedMilliseconds} ms.");
      return [new TestResult(null, TestOutcome.FrameworkError)];
    } else if (testCount != tests.length) {
      _print("Didn't complete with error but ran "
          "${testCount} tests while expecting ${tests.length} "
          "in ${stopwatch.elapsedMilliseconds} ms.");
      return [new TestResult(null, TestOutcome.FrameworkError)];
    } else {
      _print("Processed $testCount test(s) "
          "in ${stopwatch.elapsedMilliseconds} ms.");
      if (goodCount == testCount &&
          badCount == 0 &&
          crashCount == 0 &&
          parseErrorCount == 0) {
        _print("All tests passed.");
      } else {
        _print("$goodCount OK; "
            "$badCount bad; "
            "$crashCount crashed; "
            "$parseErrorCount parse errors.");
      }
      return result;
    }
  }

  DocTestIncrementalCompiler createIncrementalCompiler(Uri uri) {
    options = getOptions();
    TargetFlags targetFlags = new TargetFlags();
    // TODO: Target could possible be something else...
    Target target = new VmTarget(targetFlags);
    options.target = target;
    options.omitPlatform = true;
    options.onDiagnostic = (DiagnosticMessage message) {
      if (printOnDiagnostic) {
        _print(message.plainTextFormatted.first);
      }
      if (message.severity == Severity.error) {
        errors = true;
        errorMessages.add(message);
      }
    };
    processedOpts = new ProcessedOptions(options: options, inputs: [uri]);
    CompilerContext compilerContext = new CompilerContext(processedOpts);
    return new DocTestIncrementalCompiler(compilerContext);
  }
}

final String mainFileContent = """
// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "${DocTestIncrementalCompiler.dartDocTestUri}" as tester;
import "dart:isolate";

Future<void> main(List<String> args, SendPort port) async {
  DartDocTest test = new DartDocTest(port);
  await tester.\$dart\$doc\$test\$tester(test);
  port.send("$_portMessageDone");
}

class DartDocTest {
  final SendPort port;

  DartDocTest(this.port);

  void test(dynamic actual, dynamic expected) {
    port.send("$_portMessageTest");
    if (_testImpl(actual, expected)) {
      port.send("$_portMessageGood");
    } else {
      port.send("$_portMessageBad: Expected '\$expected'; got '\$actual'.");
    }
  }

  Future<void> throws(Function() computation) async {
    port.send("$_portMessageTest");
    try {
      await computation();
      port.send("$_portMessageBad: Expected a crash, but didn't get one.");
    } catch(e) {
      port.send("$_portMessageGood");
    }
  }

  void crash(dynamic error, dynamic st) {
    port.send("$_portMessageTest");
    port.send("$_portMessageCrash: \$error\\n\\nStacktrace:\\n\$st");
  }

  void parseError(String message) {
    port.send("$_portMessageTest");
    port.send("$_portMessageParseError: \$message");
  }

  bool _testImpl(dynamic actual, dynamic expected) {
    if (identical(actual, expected)) return true;
    if (actual == expected) return true;
    if (actual == null || expected == null) return false;
    if (actual is List && expected is List) {
      if (actual.runtimeType != expected.runtimeType) return false;
      if (actual.length != expected.length) return false;
      for (int i = 0; i < actual.length; i++) {
        if (actual[i] != expected[i]) return false;
      }
      return true;
    }
    if (actual is List || expected is List) return false;

    if (actual is Map && expected is Map) {
      if (actual.runtimeType != expected.runtimeType) return false;
      if (actual.length != expected.length) return false;
      for (dynamic key in actual.keys) {
        if (!expected.containsKey(key)) return false;
        if (actual[key] != expected[key]) return false;
      }
      return true;
    }
    if (actual is Map || expected is Map) return false;

    if (actual is Set && expected is Set) {
      if (actual.runtimeType != expected.runtimeType) return false;
      if (actual.length != expected.length) return false;
      for (dynamic value in actual) {
        if (!expected.contains(value)) return false;
      }
      return true;
    }
    if (actual is Set || expected is Set) return false;

    // More stuff?
    return false;
  }
}
""";

List<Test> extractTests(Uint8List rawBytes, Uri uriForReporting) {
  String rawString = utf8.decode(rawBytes);
  List<int> lineStarts = [];
  Token firstToken = scanRawBytes(rawBytes, lineStarts: lineStarts);
  kernel.Source source =
      new kernel.Source(lineStarts, rawBytes, uriForReporting, uriForReporting);
  Token token = firstToken;
  List<Test> tests = [];
  while (true) {
    CommentToken? comment = token.precedingComments;
    if (comment != null) {
      tests.addAll(extractTestsFromComment(comment, rawString, source));
    }
    if (token.isEof) break;
    Token? next = token.next;
    if (next == null) break;
    token = next;
  }
  return tests;
}

Token scanRawBytes(Uint8List rawBytes, {List<int>? lineStarts}) {
  Uint8List bytes = new Uint8List(rawBytes.length + 1);
  bytes.setRange(0, rawBytes.length, rawBytes);

  ScannerConfiguration scannerConfiguration = new ScannerConfiguration(
      enableExtensionMethods: true,
      enableNonNullable: true,
      enableTripleShift: true);

  Utf8BytesScanner scanner = new Utf8BytesScanner(
    bytes,
    includeComments: true,
    configuration: scannerConfiguration,
    languageVersionChanged: (scanner, languageVersion) {
      // For now don't do anything, but having it (making it non-null) means the
      // configuration won't be reset.
    },
  );
  Token result = scanner.tokenize();
  if (lineStarts != null) {
    lineStarts.clear();
    lineStarts.addAll(scanner.lineStarts);
  }
  return result;
}

const int $LF = 10;
const int $SPACE = 32;
const int $STAR = 42;

sealed class Test {
  String get location;
}

class ExpectTest implements Test {
  final String call;
  final String result;
  @override
  final String location;

  ExpectTest(this.call, this.result, this.location);

  @override
  bool operator ==(Object other) {
    if (other is! ExpectTest) return false;
    if (other.call != call) return false;
    if (other.result != result) return false;
    if (other.location != location) return false;
    return true;
  }

  @override
  String toString() {
    return "ExpectTest[$call, $result, $location]";
  }
}

class ThrowsTest implements Test {
  final String call;
  @override
  final String location;

  ThrowsTest(this.call, this.location);

  @override
  bool operator ==(Object other) {
    if (other is! ThrowsTest) return false;
    if (other.call != call) return false;
    if (other.location != location) return false;
    return true;
  }

  @override
  String toString() {
    return "ThrowsTest[$call, $location]";
  }
}

class TestParseError implements Test {
  final String message;
  final int position;
  @override
  final String location;

  TestParseError(this.message, this.position, this.location);

  @override
  bool operator ==(Object other) {
    if (other is! TestParseError) return false;
    if (other.message != message) return false;
    if (other.position != position) return false;
    if (other.location != location) return false;
    return true;
  }

  @override
  String toString() {
    return "TestParseError[$position, $message]";
  }
}

enum TestOutcome {
  Pass,
  Failed,
  Crash,
  TestCompilationError,
  CompilationError,
  RuntimeError,
  FrameworkError
}

class TestResult {
  final Test? test;
  final TestOutcome outcome;
  String? message;

  TestResult(this.test, this.outcome);

  @override
  bool operator ==(Object other) {
    if (other is! TestResult) return false;
    if (other.test != test) return false;
    if (other.outcome != outcome) return false;
    if (other.message != message) return false;
    return true;
  }

  @override
  String toString() {
    if (message != null) {
      return "TestResult[$outcome, $test, $message]";
    }
    return "TestResult[$outcome, $test]";
  }
}

List<Test> extractTestsFromComment(
    CommentToken comment, String rawString, kernel.Source source) {
  CommentString commentsData = extractComments(comment, rawString);
  final String comments = commentsData.string;
  int index = -1;

  String getLocation(int offset) {
    return source
        .getLocation(source.importUri ?? source.fileUri!, offset)
        .toString();
  }

  Test scanVariableDartDoc(
      int scanOffset,
      String expectedLexeme,
      int expressionCount,
      Test Function(List<String> expressions, String location) testCreator) {
    final Token firstToken =
        scanRawBytes(utf8.encode(comments.substring(scanOffset)));
    final ErrorListener listener = new ErrorListener();
    final Parser parser = new Parser(listener,
        useImplicitCreationExpression: useImplicitCreationExpressionInCfe);
    parser.asyncState = AsyncModifier.Async;

    final Token pastErrors = parser.skipErrorTokens(firstToken);
    assert(pastErrors.isIdentifier);
    assert(pastErrors.lexeme == expectedLexeme);

    final Token startParen = pastErrors.next!;
    assert(identical("(", startParen.stringValue));

    // Advance index so we don't parse the same thing again (for error cases).
    index = scanOffset + startParen.charEnd;

    Token parseFrom = startParen;
    final Token firstExpressionToken = parseFrom.next!;
    List<String> expressionsText = [];

    for (int i = 1; i <= expressionCount; i++) {
      final Token expressionFirstToken = parseFrom.next!;
      final Token beforeNextSeparator = parser.parseExpression(parseFrom);
      final Token nextSeparator = parseFrom = beforeNextSeparator.next!;
      final String expectedSeparator = i == expressionCount ? ")" : ",";

      if (listener.hasErrors) {
        StringBuffer sb = new StringBuffer();
        int firstPosition = _createParseErrorMessages(
            listener, sb, commentsData, scanOffset, source);
        return new TestParseError(
          sb.toString(),
          firstPosition,
          getLocation(firstPosition),
        );
      } else if (!identical(expectedSeparator, nextSeparator.stringValue)) {
        int position =
            commentsData.charOffset + scanOffset + nextSeparator.charOffset;
        Message message =
            codes.templateExpectedButGot.withArguments(expectedSeparator);
        return new TestParseError(
          _createParseErrorMessage(
              source, position, nextSeparator, nextSeparator, message),
          position,
          getLocation(position),
        );
      } else {
        // Good.
        expressionsText.add(comments.substring(
            scanOffset + expressionFirstToken.charOffset,
            scanOffset + beforeNextSeparator.charEnd));
      }
    }

    assert(expressionsText.length == expressionCount);

    return testCreator(
      expressionsText,
      getLocation(
        commentsData.charOffset + scanOffset + firstExpressionToken.charOffset,
      ),
    );
  }

  List<Test> result = [];
  index = comments.indexOf("DartDocTest(");
  while (index >= 0) {
    result.add(scanVariableDartDoc(
        index,
        "DartDocTest",
        2,
        (List<String> expressions, String location) =>
            new ExpectTest(expressions[0], expressions[1], location)));
    index = comments.indexOf("DartDocTest(", index);
  }
  index = comments.indexOf("DartDocTestThrows(");
  while (index >= 0) {
    result.add(scanVariableDartDoc(
        index,
        "DartDocTestThrows",
        1,
        (List<String> expressions, String location) =>
            new ThrowsTest(expressions[0], location)));
    index = comments.indexOf("DartDocTestThrows(", index);
  }
  return result;
}

int _createParseErrorMessages(ErrorListener listener, StringBuffer sb,
    CommentString commentsData, int scanOffset, kernel.Source source) {
  assert(listener.recoverableErrors.isNotEmpty);
  sb.writeln("Parse error(s):");
  int? firstPosition;
  for (RecoverableError recoverableError in listener.recoverableErrors) {
    final int position = commentsData.charOffset +
        scanOffset +
        recoverableError.startToken.charOffset;
    firstPosition ??= position;
    sb.writeln("");
    sb.write(_createParseErrorMessage(
      source,
      position,
      recoverableError.startToken,
      recoverableError.endToken,
      recoverableError.message,
    ));
  }
  return firstPosition!;
}

String _createParseErrorMessage(kernel.Source source, int position,
    Token startToken, Token endToken, Message message) {
  kernel.Location location = source.getLocation(source.importUri!, position);
  return command_line_reporting.formatErrorMessage(
      source.getTextLine(location.line),
      location,
      endToken.charEnd - startToken.charOffset,
      source.importUri!.toString(),
      message.problemMessage);
}

CommentString extractComments(CommentToken comment, String rawString) {
  List<int> fileCodeUnits = rawString.codeUnits;
  final int charOffset = comment.charOffset;
  int expectedCharOffset = charOffset;
  StringBuffer sb = new StringBuffer();
  CommentToken? commentToken = comment;
  bool commentBlock = false;
  bool commentBlockStar = false;
  while (commentToken != null) {
    if (expectedCharOffset != commentToken.charOffset) {
      // Missing spaces/linebreaks.
      assert(expectedCharOffset < commentToken.offset);
      for (int i = expectedCharOffset; i < commentToken.offset; i++) {
        if (fileCodeUnits[i] == $LF) {
          sb.writeCharCode($LF);
        } else {
          sb.write(" ");
        }
      }
    }
    expectedCharOffset = commentToken.charEnd;
    String data = commentToken.lexeme;
    if (!commentBlock) {
      if (data.startsWith("///")) {
        data = data.substring(3);
        sb.write("   ");
      } else if (data.startsWith("//")) {
        data = data.substring(2);
        sb.write("  ");
      } else if (data.startsWith("/**")) {
        data = data.substring(3);
        commentBlock = true;
        commentBlockStar = true;
        sb.write("   ");
      } else if (data.startsWith("/*")) {
        data = data.substring(2);
        commentBlock = true;
        sb.write("  ");
      }
    }

    if (commentBlock && data.endsWith("*/")) {
      // Remove ending "*/"" as well as "starting" "*" if in a "/**" block.
      List<int> codeUnits = data.codeUnits;
      bool sawNewlineLast = false;
      for (int i = 0; i < codeUnits.length - 2; i++) {
        int codeUnit = codeUnits[i];
        if (codeUnit == $LF) {
          sb.writeCharCode($LF);
          sawNewlineLast = true;
        } else if (codeUnit <= $SPACE) {
          sb.writeCharCode($SPACE);
        } else if (commentBlockStar && sawNewlineLast && codeUnit == $STAR) {
          sb.writeCharCode($SPACE);
          sawNewlineLast = false;
        } else {
          sawNewlineLast = false;
          sb.writeCharCode(codeUnit);
        }
      }
      sb.write("  ");
      commentBlock = false;
      commentBlockStar = false;
    } else {
      sb.write(data);
    }
    Token? next = commentToken.next;
    commentToken = null;
    if (next is CommentToken) commentToken = next;
  }
  return new CommentString(sb.toString(), charOffset);
}

class CommentString {
  final String string;
  final int charOffset;

  CommentString(this.string, this.charOffset);

  @override
  bool operator ==(Object other) {
    if (other is! CommentString) return false;
    if (other.string != string) return false;
    if (other.charOffset != charOffset) return false;
    return true;
  }

  @override
  String toString() {
    return "CommentString[$charOffset, $string]";
  }
}

class ErrorListener extends NullListener {
  List<RecoverableError> recoverableErrors = [];

  @override
  void handleRecoverableError(
      Message message, Token startToken, Token endToken) {
    super.handleRecoverableError(message, startToken, endToken);
    recoverableErrors.add(new RecoverableError(message, startToken, endToken));
  }
}

class RecoverableError {
  final Message message;
  final Token startToken;
  final Token endToken;

  RecoverableError(this.message, this.startToken, this.endToken);
}

class DocTestIncrementalCompiler extends IncrementalCompiler {
  static final Uri dartDocTestUri =
      new Uri(scheme: "dartdoctest", path: "tester");
  DocTestIncrementalCompiler(CompilerContext context) : super(context);

  @override
  bool dontReissueLibraryProblemsFor(Uri? uri) {
    return super.dontReissueLibraryProblemsFor(uri) || uri == dartDocTestUri;
  }

  @override
  IncrementalKernelTarget createIncrementalKernelTarget(
      FileSystem fileSystem,
      bool includeComments,
      DillTarget dillTarget,
      UriTranslator uriTranslator) {
    return new DocTestIncrementalKernelTarget(
        context, this, fileSystem, includeComments, dillTarget, uriTranslator);
  }

  LibraryBuilder? _dartDocTestLibraryBuilder;
  String? _dartDocTestCode;

  Future<kernel.Component> compileDartDocTestLibrary(
      String dartDocTestCode, Uri libraryUri) async {
    assert(dillTargetForTesting != null && kernelTargetForTesting != null);

    return await context.runInContext((_) async {
      LibraryBuilder libraryBuilder = kernelTargetForTesting!.loader
          .lookupLoadedLibraryBuilder(libraryUri)!;

      kernelTargetForTesting!.loader.resetSeenMessages();

      _dartDocTestLibraryBuilder = libraryBuilder;
      _dartDocTestCode = dartDocTestCode;

      invalidate(dartDocTestUri);
      IncrementalCompilerResult compilerResult = await computeDelta(
          entryPoints: [dartDocTestUri], fullComponent: true);
      kernel.Component result = compilerResult.component;
      _dartDocTestLibraryBuilder = null;
      _dartDocTestCode = null;

      kernelTargetForTesting!.uriToSource.remove(dartDocTestUri);
      kernelTargetForTesting!.loader.sourceBytes.remove(dartDocTestUri);

      return result;
    });
  }

  SourceLibraryBuilder createDartDocTestLibrary(
      SourceLoader loader, LibraryBuilder libraryBuilder) {
    SourceLibraryBuilder dartDocTestLibrary = new SourceLibraryBuilder(
      importUri: dartDocTestUri,
      fileUri: dartDocTestUri,
      originImportUri: dartDocTestUri,
      packageLanguageVersion:
          new ImplicitLanguageVersion(libraryBuilder.languageVersion),
      loader: loader,
      parentScope: libraryBuilder.scope,
      nameOrigin: libraryBuilder,
      isUnsupported: false,
      isAugmentation: false,
      isPatch: false,
    );

    if (libraryBuilder is DillLibraryBuilder) {
      for (kernel.LibraryDependency dependency
          in libraryBuilder.library.dependencies) {
        if (!dependency.isImport) continue;

        List<CombinatorBuilder>? combinators;

        for (kernel.Combinator combinator in dependency.combinators) {
          combinators ??= <CombinatorBuilder>[];

          combinators.add(combinator.isShow
              ? new CombinatorBuilder.show(combinator.names,
                  combinator.fileOffset, libraryBuilder.fileUri)
              : new CombinatorBuilder.hide(combinator.names,
                  combinator.fileOffset, libraryBuilder.fileUri));
        }

        dartDocTestLibrary.compilationUnit.addSyntheticImport(
            uri: dependency.importedLibraryReference.asLibrary.importUri
                .toString(),
            prefix: dependency.name,
            combinators: combinators,
            deferred: dependency.isDeferred);
      }

      dartDocTestLibrary.compilationUnit.addSyntheticImport(
          uri: libraryBuilder.importUri.toString(),
          prefix: null,
          combinators: null,
          deferred: false);
    } else {
      throw "Got ${libraryBuilder.runtimeType}";
    }

    return dartDocTestLibrary;
  }
}

class DocTestIncrementalKernelTarget extends IncrementalKernelTarget {
  final DocTestIncrementalCompiler compiler;
  DocTestIncrementalKernelTarget(
      CompilerContext compilerContext,
      this.compiler,
      FileSystem fileSystem,
      bool includeComments,
      DillTarget dillTarget,
      UriTranslator uriTranslator)
      : super(compilerContext, fileSystem, includeComments, dillTarget,
            uriTranslator);

  @override
  SourceLoader createLoader() {
    return new DocTestSourceLoader(compiler, fileSystem, includeComments, this);
  }
}

class DocTestSourceLoader extends SourceLoader {
  final DocTestIncrementalCompiler compiler;

  DocTestSourceLoader(this.compiler, FileSystem fileSystem,
      bool includeComments, DocTestIncrementalKernelTarget target)
      : super(fileSystem, includeComments, target);

  @override
  SourceLibraryBuilder createLibraryBuilder(
      {required Uri importUri,
      required Uri fileUri,
      Uri? packageUri,
      required Uri originImportUri,
      required LanguageVersion packageLanguageVersion,
      SourceLibraryBuilder? origin,
      IndexedLibrary? referencesFromIndex,
      bool? referenceIsPartOwner,
      bool isAugmentation = false,
      bool isPatch = false}) {
    if (importUri == DocTestIncrementalCompiler.dartDocTestUri) {
      HybridFileSystem hfs = target.fileSystem as HybridFileSystem;
      MemoryFileSystem fs = hfs.memory;
      fs
          .entityForUri(DocTestIncrementalCompiler.dartDocTestUri)
          .writeAsStringSync(compiler._dartDocTestCode!);
      return compiler.createDartDocTestLibrary(
          this, compiler._dartDocTestLibraryBuilder!);
    }
    return super.createLibraryBuilder(
        importUri: importUri,
        fileUri: fileUri,
        originImportUri: originImportUri,
        packageUri: packageUri,
        packageLanguageVersion: packageLanguageVersion,
        origin: origin,
        referencesFromIndex: referencesFromIndex,
        referenceIsPartOwner: referenceIsPartOwner,
        isAugmentation: isAugmentation,
        isPatch: isPatch);
  }
}
