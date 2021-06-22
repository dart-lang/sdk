// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ScannerConfiguration;

import 'package:_fe_analyzer_shared/src/scanner/token.dart';

import 'package:_fe_analyzer_shared/src/scanner/utf8_bytes_scanner.dart'
    show Utf8BytesScanner;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/api_prototype/file_system.dart';
import 'package:front_end/src/api_prototype/standard_file_system.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/fasta_codes.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:front_end/src/fasta/incremental_compiler.dart';
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/target/targets.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:vm/target/vm.dart';

// ignore: import_of_legacy_library_into_null_safe
import '../test/incremental_suite.dart' show getOptions;

const _portMessageTest = "test";
const _portMessageGood = "good";
const _portMessageBad = "bad";
const _portMessageBadDetails = "badDetails";
const _portMessageCrash = "crash";
const _portMessageParseError = "parseError";
const _portMessageDone = "done";

// TODO: This doesn't work on parts... (Well, it might, depending on how
// the part declares what file it's part of and if we've compiled other stuff
// first so we know more stuff).
class DartDocTest {
  IncrementalCompiler? incrementalCompiler;
  late CompilerOptions options;
  late ProcessedOptions processedOpts;
  bool errors = false;

  /// All-in-one. Process a file and return if it was good.
  Future<bool> process(Uri uri) async {
    print("\n\nProcessing $uri");
    Stopwatch stopwatch = new Stopwatch()..start();

    // Extract test cases in file.
    List<Test> tests = extractTestsFromUri(uri);

    if (tests.isEmpty) {
      print("No tests found in file in ${stopwatch.elapsedMilliseconds} ms.");
      return true;
    }
    print("Found ${tests.length} test(s) in file "
        "in ${stopwatch.elapsedMilliseconds} ms.");

    return await compileAndRun(uri, tests);
  }

  Future<bool> compileAndRun(Uri uri, List<Test> tests) async {
    errors = false;

    // Create code to amend the file with.
    StringBuffer sb = new StringBuffer();
    if (tests.isNotEmpty) {
      sb.writeln(
          r"Future<void> $dart$doc$test$tester(dynamic dartDocTest) async {");
      for (Test test in tests) {
        if (test is TestParseError) {
          sb.writeln("dartDocTest.parseError(\"${test.message}\");");
        } else {
          sb.writeln("try {");
          sb.writeln("  dartDocTest.test(${test.call}, ${test.result});");
          sb.writeln("} catch (e) {");
          sb.writeln("  dartDocTest.crash(e);");
          sb.writeln("}");
        }
      }
      sb.writeln("}");
    }

    if (incrementalCompiler == null) {
      setupIncrementalCompiler(uri);
    }

    processedOpts.inputs.clear();
    processedOpts.inputs.add(uri);
    AmendedFileSystem fileSystem =
        new AmendedFileSystem(StandardFileSystem.instance);
    fileSystem.amendFileUri = uri;
    fileSystem.amendWith = sb.toString();
    options.fileSystem = fileSystem;
    processedOpts.clearFileSystemCache();
    // Invalidate file and package uri to force compilation and re-finding of
    // packages (e.g. if we're now compiling somewhere else).
    incrementalCompiler!.invalidate(uri);
    incrementalCompiler!.invalidate(processedOpts.packagesUri);

    Stopwatch stopwatch = new Stopwatch()..start();
    Component component =
        await incrementalCompiler!.computeDelta(entryPoints: [uri]);
    if (errors) {
      print("Got errors in ${stopwatch.elapsedMilliseconds} ms.");
      return false;
    }
    print("Compiled (1) in ${stopwatch.elapsedMilliseconds} ms.");
    stopwatch.reset();

    fileSystem.amendImportUri = component.uriToSource[uri]?.importUri;
    incrementalCompiler!.invalidate(AmendedFileSystem.mainUri);
    Component componentMain = await incrementalCompiler!.computeDelta(
        entryPoints: [AmendedFileSystem.mainUri], fullComponent: true);
    if (errors) {
      print("Got errors in ${stopwatch.elapsedMilliseconds} ms.");
      return false;
    }
    print("Compiled (2) in ${stopwatch.elapsedMilliseconds} ms.");
    stopwatch.reset();

    Directory tmpDir = Directory.systemTemp.createTempSync();
    Uri dillOutUri = tmpDir.uri.resolve("dartdoctestrun.dill");
    await writeComponentToFile(componentMain, dillOutUri);
    print("Wrote dill in ${stopwatch.elapsedMilliseconds} ms.");
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
      print("Isolate had an error: $message.");
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
    communicationPort.listen((message) {
      if (done) {
        throw "Didn't expect any more messages. Got '$message'";
      }
      if (message == _portMessageTest) {
        testCount++;
      } else if (message == _portMessageGood) {
        goodCount++;
      } else if (message == _portMessageBad) {
        badCount++;
      } else if (message.toString().startsWith("$_portMessageBadDetails: ")) {
        print(message.toString().substring("$_portMessageBadDetails: ".length));
      } else if (message == _portMessageCrash) {
        crashCount++;
      } else if (message.toString().startsWith("$_portMessageParseError: ")) {
        parseErrorCount++;
        print(message.toString().substring("$_portMessageParseError: ".length));
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
    if (error) {
      print("Completed with an error in ${stopwatch.elapsedMilliseconds} ms.");
      return false;
    } else if (!done) {
      print(
          "Didn't complete correctly in ${stopwatch.elapsedMilliseconds} ms.");
      return false;
    } else if (testCount != tests.length) {
      print("Didn't complete with error but ran "
          "${testCount} tests while expecting ${tests.length} "
          "in ${stopwatch.elapsedMilliseconds} ms.");
      return false;
    } else {
      print("Processed $testCount test(s) "
          "in ${stopwatch.elapsedMilliseconds} ms.");
      if (goodCount == testCount &&
          badCount == 0 &&
          crashCount == 0 &&
          parseErrorCount == 0) {
        print("All tests passed.");
        return true;
      }
      print("$goodCount OK; "
          "$badCount bad; "
          "$crashCount crashed; "
          "$parseErrorCount parse errors.");
      return false;
    }
  }

  void setupIncrementalCompiler(Uri uri) {
    options = getOptions();
    TargetFlags targetFlags = new TargetFlags(enableNullSafety: true);
    // TODO: Target could possible be something else...
    Target target = new VmTarget(targetFlags);
    options.target = target;
    options.omitPlatform = true;
    options.onDiagnostic = (DiagnosticMessage message) {
      if (message.codeName == "InferredPackageUri") return;
      print(message.plainTextFormatted.first);
      if (message.severity == Severity.error) {
        errors = true;
      }
    };

    // Because we add a top-level method this doesn't currently do anything
    // but maybe it will in the future.
    options.explicitExperimentalFlags[
        ExperimentalFlag.alternativeInvalidationStrategy] = true;

    processedOpts = new ProcessedOptions(options: options, inputs: [uri]);
    CompilerContext compilerContext = new CompilerContext(processedOpts);
    this.incrementalCompiler = new IncrementalCompiler(compilerContext);
  }
}

List<Test> extractTestsFromUri(Uri uri) {
  // Extract test cases in file.
  File file = new File.fromUri(uri);
  Uint8List rawBytes = file.readAsBytesSync();
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
  Token firstToken = scanner.tokenize();
  Token token = firstToken;
  List<Test> tests = [];
  while (!token.isEof) {
    CommentToken? comment = token.precedingComments;
    if (comment != null) {
      tests.addAll(processComment(comment));
      // TODO: Use parser to verify there's at least no syntax errors in the
      // tests.
    }
    Token? next = token.next;
    if (next == null) break;
    token = next;
  }
  return tests;
}

const int $LF = 10;
const int $OPEN_PAREN = 40;
const int $CLOSE_PAREN = 41;
const int $COMMA = 44;

class Test {
  final String call;
  final String result;

  Test(this.call, this.result);
}

class TestParseError implements Test {
  final String message;

  TestParseError(this.message);

  @override
  String get call => throw UnimplementedError();

  @override
  String get result => throw UnimplementedError();
}

List<Test> processComment(CommentToken comment) {
  StringBuffer sb = new StringBuffer();
  CommentToken? commentToken = comment;
  bool commentBlock = false;
  while (commentToken != null) {
    String data = commentToken.lexeme.trim();
    if (!commentBlock) {
      if (data.startsWith("///")) {
        data = data.substring(3).trim();
      } else if (data.startsWith("//")) {
        data = data.substring(2).trim();
      } else if (data.startsWith("/*")) {
        data = data.substring(2).trim();
        commentBlock = true;
      }
    }

    if (commentBlock && data.endsWith("*/")) {
      data = data.substring(0, data.length - 2).trim();
      commentBlock = false;
    }
    if (data.isNotEmpty) {
      sb.write(data);
    }
    Token? next = commentToken.next;
    commentToken = null;
    if (next is CommentToken) commentToken = next;
  }
  String comments = sb.toString();
  List<Test> result = [];
  int index = comments.indexOf("DartDocTest(");
  if (index < 0) {
    return result;
  }
  List<int> codeUnits = comments.codeUnits;

  while (index >= 0) {
    // DartDocTest starts at (the current) $index --- now find the end,
    // parenthesis, comma etc.
    // TODO: This doesn't work for string literals with e.g. '(' and ',' in it.
    int parenDepth = 0;
    int firstParen = -1;
    int commaAt = -1;
    while (index < comments.length) {
      int codeUnit = codeUnits[index++];
      if (codeUnit == $OPEN_PAREN) {
        parenDepth++;
        if (parenDepth == 1) {
          firstParen = index;
        }
      } else if (codeUnit == $CLOSE_PAREN) {
        parenDepth--;
        if (parenDepth == 0) {
          break;
        }
      } else if (parenDepth == 1 && commaAt < 0 && codeUnit == $COMMA) {
        commaAt = index;
      }
    }

    int end = index;
    if (parenDepth != 0 || firstParen < 0 || commaAt < 0) {
      // TODO: Insert code-snippet that didn't parse...
      result.add(new TestParseError("Parse error for test"));
    } else {
      result.add(new Test(
        comments.substring(firstParen, commaAt - 1).trim(),
        comments.substring(commaAt, end - 1).trim(),
      ));
    }
    index = comments.indexOf("DartDocTest(", index);
  }
  return result;
}

class AmendedFileSystem implements FileSystem {
  static Uri mainUri = Uri.parse("dartdoctest:main");
  final FileSystem fs;
  late Uri amendFileUri;
  Uri? amendImportUri;
  late String amendWith;

  AmendedFileSystem(this.fs);

  @override
  FileSystemEntity entityForUri(Uri uri) {
    if (uri == mainUri) {
      return DartdoctestMainFile(amendImportUri ?? amendFileUri);
    }
    return new AmendedFileSystemEntity(
        fs.entityForUri(uri), uri == amendFileUri ? amendWith : null);
  }
}

class DartdoctestMainFile implements FileSystemEntity {
  late final String content;
  late final List<int> contentBytes = utf8.encode(content);

  DartdoctestMainFile(Uri amendImportUri) {
    content = """
// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "$amendImportUri" as tester;
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
      port.send("$_portMessageBad");
      port.send("$_portMessageBadDetails: Expected '\$expected'; got '\$actual'.");
    }
  }

  void crash(dynamic error) {
    port.send("$_portMessageTest");
    port.send("$_portMessageCrash");
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
  }

  @override
  Future<bool> exists() {
    return Future.value(true);
  }

  @override
  Future<bool> existsAsyncIfPossible() {
    return Future.value(true);
  }

  @override
  Future<List<int>> readAsBytes() {
    return Future.value(contentBytes);
  }

  @override
  Future<List<int>> readAsBytesAsyncIfPossible() {
    return Future.value(contentBytes);
  }

  @override
  Future<String> readAsString() {
    return Future.value(content);
  }

  @override
  Uri get uri => AmendedFileSystem.mainUri;
}

class AmendedFileSystemEntity implements FileSystemEntity {
  final FileSystemEntity entityForUri;
  final String? amendWith;
  AmendedFileSystemEntity(this.entityForUri, this.amendWith);

  @override
  Future<bool> exists() {
    return entityForUri.exists();
  }

  @override
  Future<bool> existsAsyncIfPossible() {
    return entityForUri.existsAsyncIfPossible();
  }

  @override
  Future<List<int>> readAsBytes() async {
    List<int> result = await entityForUri.readAsBytes();
    return _amendIfNeeded(result);
  }

  List<int> _amendIfNeeded(List<int> existing) {
    final String? amendWith = this.amendWith;
    if (amendWith != null) {
      List<int> encoded = utf8.encode(amendWith);
      if (encoded.length > 0) {
        Uint8List combined =
            new Uint8List(existing.length + 1 + encoded.length);
        combined.setRange(0, existing.length, existing);
        combined[existing.length] = $LF;
        combined.setRange(existing.length + 1, combined.length, encoded);
        return combined;
      }
    }
    return existing;
  }

  @override
  Future<List<int>> readAsBytesAsyncIfPossible() async {
    List<int> result = await entityForUri.readAsBytesAsyncIfPossible();
    return _amendIfNeeded(result);
  }

  @override
  Future<String> readAsString() async {
    String result = await entityForUri.readAsString();
    if (amendWith != null) return "$result\n$amendWith";
    return result;
  }

  @override
  Uri get uri => entityForUri.uri;
}
