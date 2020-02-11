// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): this file needs to be refactored, it's a port from
// package:dev_compiler's tests
import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:source_span/source_span.dart';
import 'package:test/test.dart';

SourceSpanWithContext _createSpanHelper(
    LineInfo lineInfo, int start, Source source, String content,
    {int end}) {
  var startLoc = _locationForOffset(lineInfo, source.uri, start);
  var endLoc = _locationForOffset(lineInfo, source.uri, end ?? start);

  var lineStart = startLoc.offset - startLoc.column;
  // Find the end of the line. This is not exposed directly on LineInfo, but
  // we can find it pretty easily.
  // TODO(jmesserly): for now we do the simple linear scan. Ideally we can get
  // some help from the LineInfo API.
  int lineEnd = endLoc.offset;
  int lineNum = lineInfo.getLocation(lineEnd).lineNumber;
  while (lineEnd < content.length &&
      lineInfo.getLocation(++lineEnd).lineNumber == lineNum) {}

  if (end == null) {
    end = lineEnd;
    endLoc = _locationForOffset(lineInfo, source.uri, lineEnd);
  }

  var text = content.substring(start, end);
  var lineText = content.substring(lineStart, lineEnd);
  return SourceSpanWithContext(startLoc, endLoc, text, lineText);
}

ErrorSeverity _errorSeverity(
    AnalysisOptions analysisOptions, AnalysisError error) {
  // TODO(brianwilkerson) Remove the if when top-level inference is made an
  // error again.
  if (error.errorCode.name.startsWith('TOP_LEVEL_')) {
    return ErrorSeverity.ERROR;
  }
  return ErrorProcessor.getProcessor(analysisOptions, error)?.severity ??
      error.errorCode.errorSeverity;
}

void _expectErrors(AnalysisOptions analysisOptions, CompilationUnit unit,
    Iterable<AnalysisError> actualErrors) {
  var expectedErrors = _findExpectedErrors(unit.beginToken);

  var actualMap = SplayTreeMap<int, List<AnalysisError>>();
  for (var e in actualErrors) {
    actualMap.putIfAbsent(e.offset, () => []).add(e);
  }
  var expectedMap = SplayTreeMap<int, List<_ErrorExpectation>>();
  for (var e in expectedErrors) {
    expectedMap.putIfAbsent(e.offset, () => []).add(e);
  }

  // Categorize the differences, if any.
  var unreported = <_ErrorExpectation>[];
  var different = <List<_ErrorExpectation>, List<AnalysisError>>{};

  expectedMap.forEach((offset, expectedList) {
    var actualList = actualMap[offset] ?? [];

    var unmatched = <_ErrorExpectation>[];
    for (var expected in expectedList) {
      var match = actualList.firstWhere(
          (a) => expected.matches(analysisOptions, a),
          orElse: () => null);
      if (match != null) {
        actualList.remove(match);
        if (actualList.isEmpty) actualMap.remove(offset);
      } else {
        unmatched.add(expected);
      }
    }

    if (actualList.isEmpty) {
      unreported.addAll(unmatched);
    } else if (unmatched.isNotEmpty) {
      different[unmatched] = actualList;
      actualMap.remove(offset);
    }
  });

  // Whatever is left was an unexpected error.
  List<AnalysisError> unexpected = actualMap.values.expand((a) => a).toList();

  if (unreported.isNotEmpty || unexpected.isNotEmpty || different.isNotEmpty) {
    _reportFailure(analysisOptions, unit, unreported, unexpected, different);
  }
}

List<_ErrorExpectation> _findExpectedErrors(Token beginToken) {
  var expectedErrors = <_ErrorExpectation>[];

  // Collect expectations like "error:STATIC_TYPE_ERROR" from comment tokens.
  for (Token t = beginToken; t.type != TokenType.EOF; t = t.next) {
    for (CommentToken c = t.precedingComments; c != null; c = c.next) {
      if (c.type == TokenType.MULTI_LINE_COMMENT) {
        String value = c.lexeme.substring(2, c.lexeme.length - 2);
        if (value.contains(':')) {
          int offset = t.offset;
          Token previous = t.previous;
          while (previous != null && previous.offset > c.offset) {
            offset = previous.offset;
            previous = previous.previous;
          }
          for (var expectCode in value.split(',')) {
            var expected = _ErrorExpectation.parse(offset, expectCode);
            if (expected != null) {
              expectedErrors.add(expected);
            }
          }
        }
      }
    }
  }
  return expectedErrors;
}

SourceLocation _locationForOffset(LineInfo lineInfo, Uri uri, int offset) {
  var loc = lineInfo.getLocation(offset);
  return SourceLocation(offset,
      sourceUrl: uri, line: loc.lineNumber - 1, column: loc.columnNumber - 1);
}

/// Returns all libraries transitively imported or exported from [start].
Set<LibraryElement> _reachableLibraries(LibraryElement start) {
  Set<LibraryElement> results = <LibraryElement>{};

  void find(LibraryElement library) {
    if (results.add(library)) {
      library.importedLibraries.forEach(find);
      library.exportedLibraries.forEach(find);
    }
  }

  find(start);
  return results;
}

void _reportFailure(
    AnalysisOptions analysisOptions,
    CompilationUnit unit,
    List<_ErrorExpectation> unreported,
    List<AnalysisError> unexpected,
    Map<List<_ErrorExpectation>, List<AnalysisError>> different) {
  // Get the source code. This reads the data again, but it's safe because
  // all tests use memory file system.
  var sourceCode = unit.declaredElement.source.contents.data;

  String formatActualError(AnalysisError error) {
    int offset = error.offset;
    int length = error.length;
    var span = _createSpanHelper(
        unit.lineInfo, offset, unit.declaredElement.source, sourceCode,
        end: offset + length);
    var levelName = _errorSeverity(analysisOptions, error).displayName;
    return '@$offset $levelName:${error.errorCode.name}\n' +
        span.message(error.message);
  }

  String formatExpectedError(_ErrorExpectation error,
      {bool showSource = true}) {
    int offset = error.offset;
    var severity = error.severity.displayName;
    var result = '@$offset $severity:${error.typeName}';
    if (!showSource) return result;
    var span = _createSpanHelper(
        unit.lineInfo, offset, unit.declaredElement.source, sourceCode);
    return '$result\n${span.message('')}';
  }

  var message = StringBuffer();
  if (unreported.isNotEmpty) {
    message.writeln('Expected errors that were not reported:');
    unreported.map(formatExpectedError).forEach(message.writeln);
    message.writeln();
  }
  if (unexpected.isNotEmpty) {
    message.writeln('Errors that were not expected:');
    unexpected.map(formatActualError).forEach(message.writeln);
    message.writeln();
  }
  if (different.isNotEmpty) {
    message.writeln('Errors that were reported, but different than expected:');
    different.forEach((expected, actual) {
      // The source location is the same for the expected and actual, so we only
      // print it once.
      message.writeln('Expected: ' +
          expected
              .map((e) => formatExpectedError(e, showSource: false))
              .join(', '));
      message.writeln('Actual: ' + actual.map(formatActualError).join(', '));
    });
    message.writeln();
  }
  fail('Checker errors do not match expected errors:\n\n$message');
}

class AbstractStrongTest with ResourceProviderMixin {
  bool _checkCalled = true;

  AnalysisDriver _driver;

  Map<String, List<Folder>> packageMap;

  List<String> get enabledExperiments => [];

  /// Adds a file to check. The file should contain:
  ///
  ///   * all expected failures are listed in the source code using comments
  ///     immediately in front of the AST node that should contain the error.
  ///
  ///   * errors are formatted as a token `severity:ErrorCode`, where
  ///     `severity` is the ErrorSeverity the error would be reported at, and
  ///     `ErrorCode` is the error code's name.
  ///
  /// For example to check that an assignment produces a type error, you can
  /// create a file like:
  ///
  ///     addFile('''
  ///       String x = /*error:STATIC_TYPE_ERROR*/3;
  ///     ''');
  ///     check();
  ///
  /// For a single file, you may also use [checkFile].
  void addFile(String content, {String name = '/main.dart'}) {
    name = name.replaceFirst(RegExp('^package:'), '/packages/');
    newFile(name, content: content);
    _checkCalled = false;
  }

  /// Run the checker on a program, staring from '/main.dart', and verifies that
  /// errors/warnings/hints match the expected value.
  ///
  /// See [addFile] for more information about how to encode expectations in
  /// the file text.
  ///
  /// Returns the main resolved library. This can be used for further checks.
  Future<CompilationUnit> check(
      {bool implicitCasts = true,
      bool implicitDynamic = true,
      bool strictInference = false,
      bool strictRawTypes = false}) async {
    _checkCalled = true;

    File mainFile = getFile('/main.dart');
    expect(mainFile.exists, true, reason: '`/main.dart` is missing');

    AnalysisOptionsImpl analysisOptions = AnalysisOptionsImpl();
    analysisOptions.implicitCasts = implicitCasts;
    analysisOptions.implicitDynamic = implicitDynamic;
    analysisOptions.strictInference = strictInference;
    analysisOptions.strictRawTypes = strictRawTypes;
    analysisOptions.contextFeatures = FeatureSet.fromEnableFlags(
      enabledExperiments,
    );

    var mockSdk = MockSdk(
      resourceProvider: resourceProvider,
      analysisOptions: analysisOptions,
    );

    SourceFactory sourceFactory = SourceFactory([
      DartUriResolver(mockSdk),
      PackageMapUriResolver(resourceProvider, packageMap),
      ResourceUriResolver(resourceProvider),
    ]);

    CompilationUnit mainUnit;
    StringBuffer logBuffer = StringBuffer();
    FileContentOverlay fileContentOverlay = FileContentOverlay();
    PerformanceLog log = PerformanceLog(logBuffer);
    AnalysisDriverScheduler scheduler = AnalysisDriverScheduler(log);
    _driver = AnalysisDriver(
        scheduler,
        log,
        resourceProvider,
        MemoryByteStore(),
        fileContentOverlay,
        null,
        sourceFactory,
        analysisOptions,
        packages: Packages.empty);
    scheduler.start();

    mainUnit = (await _driver.getResult(mainFile.path)).unit;

    bool isRelevantError(AnalysisError error) {
      var code = error.errorCode;
      // We don't care about these.
      if (code == HintCode.UNUSED_ELEMENT ||
          code == HintCode.UNUSED_FIELD ||
          code == HintCode.UNUSED_IMPORT ||
          code == HintCode.UNUSED_LOCAL_VARIABLE ||
          code == TodoCode.TODO) {
        return false;
      }
      if (strictInference || strictRawTypes) {
        // When testing strict-inference or strict-raw-types, ignore anything
        // else.
        return code.errorSeverity.ordinal > ErrorSeverity.INFO.ordinal ||
            code == HintCode.INFERENCE_FAILURE_ON_COLLECTION_LITERAL ||
            code == HintCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION ||
            code == HintCode.STRICT_RAW_TYPE;
      }
      return true;
    }

    // Extract expectations from the comments in the test files, and
    // check that all errors we emit are included in the expected map.
    LibraryElement mainLibrary = mainUnit.declaredElement.library;
    Set<LibraryElement> allLibraries = _reachableLibraries(mainLibrary);

    for (LibraryElement library in allLibraries) {
      for (CompilationUnitElement unit in library.units) {
        var source = unit.source;
        if (source.uri.scheme == 'dart') {
          continue;
        }

        var analysisResult = await _resolve(source);

        Iterable<AnalysisError> errors =
            analysisResult.errors.where(isRelevantError);
        _expectErrors(analysisOptions, analysisResult.unit, errors);
      }
    }

    return mainUnit;
  }

  /// Adds a file using [addFile] and calls [check].
  ///
  /// Also returns the resolved compilation unit.
  Future<CompilationUnit> checkFile(String content,
      {bool implicitCasts = true, bool implicitDynamic = true}) async {
    addFile(content);
    return await check(
      implicitCasts: implicitCasts,
      implicitDynamic: implicitDynamic,
    );
  }

  void setUp() {
    packageMap = {
      'meta': [getFolder('/.pub-cache/meta/lib')],
    };
  }

  void tearDown() {
    // This is a sanity check, in case only addFile is called.
    expect(_checkCalled, true, reason: 'must call check() method in test case');
    _driver?.dispose();
    AnalysisEngine.instance.clearCaches();
  }

  Future<_TestAnalysisResult> _resolve(Source source) async {
    var result = await _driver.getResult(source.fullName);
    return _TestAnalysisResult(source, result.unit, result.errors);
  }
}

/// Describes an expected message that should be produced by the checker.
class _ErrorExpectation {
  final int offset;
  final ErrorSeverity severity;
  final String typeName;

  _ErrorExpectation(this.offset, this.severity, this.typeName);

  bool matches(AnalysisOptions options, AnalysisError e) {
    return _errorSeverity(options, e) == severity &&
        e.errorCode.name == typeName;
  }

  @override
  String toString() => '@$offset ${severity.displayName}: [$typeName]';

  static _ErrorExpectation parse(int offset, String descriptor) {
    descriptor = descriptor.trim();
    var tokens = descriptor.split(' ');
    if (tokens.length == 1) return _parse(offset, tokens[0]);
    expect(tokens.length, 4, reason: 'invalid error descriptor');
    expect(tokens[1], "should", reason: 'invalid error descriptor');
    expect(tokens[2], "be", reason: 'invalid error descriptor');
    if (tokens[0] == "pass") return null;
    // TODO(leafp) For now, we just use whatever the current expectation is,
    // eventually we could do more automated reporting here.
    return _parse(offset, tokens[0]);
  }

  static _ErrorExpectation _parse(offset, String descriptor) {
    var tokens = descriptor.split(':');
    expect(tokens.length, 2, reason: 'invalid error descriptor');
    var name = tokens[0].toUpperCase();
    var typeName = tokens[1];

    var level = ErrorSeverity.values
        .firstWhere((l) => l.name == name, orElse: () => null);
    expect(level, isNotNull,
        reason: 'invalid severity in error descriptor: `${tokens[0]}`');
    expect(typeName, isNotNull,
        reason: 'invalid type in error descriptor: ${tokens[1]}');
    return _ErrorExpectation(offset, level, typeName);
  }
}

class _TestAnalysisResult {
  final Source source;
  final CompilationUnit unit;
  final List<AnalysisError> errors;
  _TestAnalysisResult(this.source, this.unit, this.errors);
}
