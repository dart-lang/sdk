// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): this file needs to be refactored, it's a port from
// package:dev_compiler's tests
library analyzer.test.src.task.strong.strong_test_helper;

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:source_span/source_span.dart';
import 'package:test/test.dart';

import '../../context/mock_sdk.dart';

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
      lineInfo.getLocation(++lineEnd).lineNumber == lineNum);

  if (end == null) {
    end = lineEnd;
    endLoc = _locationForOffset(lineInfo, source.uri, lineEnd);
  }

  var text = content.substring(start, end);
  var lineText = content.substring(lineStart, lineEnd);
  return new SourceSpanWithContext(startLoc, endLoc, text, lineText);
}

String _errorCodeName(ErrorCode errorCode) {
  var name = errorCode.name;
  final prefix = 'STRONG_MODE_';
  if (name.startsWith(prefix)) {
    return name.substring(prefix.length);
  } else {
    return name;
  }
}

ErrorSeverity _errorSeverity(
    AnalysisOptions analysisOptions, AnalysisError error) {
  // TODO(brianwilkerson) Remove the if when top-level inference is made an
  // error again.
  if (error.errorCode.name.startsWith('STRONG_MODE_TOP_LEVEL_')) {
    return ErrorSeverity.ERROR;
  }
  return ErrorProcessor.getProcessor(analysisOptions, error)?.severity ??
      error.errorCode.errorSeverity;
}

void _expectErrors(AnalysisOptions analysisOptions, CompilationUnit unit,
    List<AnalysisError> actualErrors) {
  var expectedErrors = _findExpectedErrors(unit.beginToken);

  // Sort both lists: by offset, then level, then name.
  actualErrors.sort((x, y) {
    int delta = x.offset.compareTo(y.offset);
    if (delta != 0) return delta;

    delta = _errorSeverity(analysisOptions, x)
        .compareTo(_errorSeverity(analysisOptions, y));
    if (delta != 0) return delta;

    return _errorCodeName(x.errorCode).compareTo(_errorCodeName(y.errorCode));
  });
  expectedErrors.sort((x, y) {
    int delta = x.offset.compareTo(y.offset);
    if (delta != 0) return delta;

    delta = x.severity.compareTo(y.severity);
    if (delta != 0) return delta;

    return x.typeName.compareTo(y.typeName);
  });

  // Categorize the differences, if any.
  var unreported = <_ErrorExpectation>[];
  var different = <_ErrorExpectation, AnalysisError>{};

  for (var expected in expectedErrors) {
    AnalysisError actual = expected._removeMatchingActual(actualErrors);
    if (actual != null) {
      if (_errorSeverity(analysisOptions, actual) != expected.severity ||
          _errorCodeName(actual.errorCode) != expected.typeName) {
        different[expected] = actual;
      }
    } else {
      unreported.add(expected);
    }
  }

  // Whatever is left was an unexpected error.
  List<AnalysisError> unexpected = actualErrors;

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
  return new SourceLocation(offset,
      sourceUrl: uri, line: loc.lineNumber - 1, column: loc.columnNumber - 1);
}

/// Returns all libraries transitively imported or exported from [start].
Set<LibraryElement> _reachableLibraries(LibraryElement start) {
  Set<LibraryElement> results = new Set<LibraryElement>();

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
    Map<_ErrorExpectation, AnalysisError> different) {
  // Get the source code. This reads the data again, but it's safe because
  // all tests use memory file system.
  var sourceCode =
      resolutionMap.elementDeclaredByCompilationUnit(unit).source.contents.data;

  String formatActualError(AnalysisError error) {
    int offset = error.offset;
    int length = error.length;
    var span = _createSpanHelper(unit.lineInfo, offset,
        resolutionMap.elementDeclaredByCompilationUnit(unit).source, sourceCode,
        end: offset + length);
    var levelName = _errorSeverity(analysisOptions, error).displayName;
    return '@$offset $levelName:${_errorCodeName(error.errorCode)}\n' +
        span.message(error.message);
  }

  String formatExpectedError(_ErrorExpectation error) {
    int offset = error.offset;
    var span = _createSpanHelper(
        unit.lineInfo,
        offset,
        resolutionMap.elementDeclaredByCompilationUnit(unit).source,
        sourceCode);
    var severity = error.severity.displayName;
    return '@$offset $severity:${error.typeName}\n' + span.message('');
  }

  var message = new StringBuffer();
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
      message.writeln('Expected: ' + formatExpectedError(expected));
      message.writeln('Actual: ' + formatActualError(actual));
    });
    message.writeln();
  }
  fail('Checker errors do not match expected errors:\n\n$message');
}

class AbstractStrongTest {
  MemoryResourceProvider _resourceProvider = new MemoryResourceProvider();
  bool _checkCalled = false;

  AnalysisContext _context = null;
  AnalysisDriver _driver = null;

  bool get enableNewAnalysisDriver => false;

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
  void addFile(String content, {String name: '/main.dart'}) {
    name = name.replaceFirst('^package:', '/packages/');
    _resourceProvider.newFile(_resourceProvider.convertPath(name), content);
  }

  /// Run the checker on a program, staring from '/main.dart', and verifies that
  /// errors/warnings/hints match the expected value.
  ///
  /// See [addFile] for more information about how to encode expectations in
  /// the file text.
  ///
  /// Returns the main resolved library. This can be used for further checks.
  Future<CompilationUnit> check(
      {bool implicitCasts: true,
      bool implicitDynamic: true,
      List<String> nonnullableTypes:
          AnalysisOptionsImpl.NONNULLABLE_TYPES}) async {
    _checkCalled = true;

    File mainFile =
        _resourceProvider.getFile(_resourceProvider.convertPath('/main.dart'));
    expect(mainFile.exists, true, reason: '`/main.dart` is missing');

    AnalysisOptionsImpl analysisOptions = new AnalysisOptionsImpl();
    analysisOptions.strongMode = true;
    analysisOptions.strongModeHints = true;
    analysisOptions.implicitCasts = implicitCasts;
    analysisOptions.implicitDynamic = implicitDynamic;
    analysisOptions.nonnullableTypes = nonnullableTypes;

    var mockSdk = new MockSdk(resourceProvider: _resourceProvider);
    mockSdk.context.analysisOptions = analysisOptions;

    SourceFactory sourceFactory;
    {
      var uriResolver = new _TestUriResolver(_resourceProvider);
      sourceFactory =
          new SourceFactory([new DartUriResolver(mockSdk), uriResolver]);
    }

    CompilationUnit mainUnit;
    if (enableNewAnalysisDriver) {
      StringBuffer logBuffer = new StringBuffer();
      FileContentOverlay fileContentOverlay = new FileContentOverlay();
      PerformanceLog log = new PerformanceLog(logBuffer);
      AnalysisDriverScheduler scheduler = new AnalysisDriverScheduler(log);
      _driver = new AnalysisDriver(
          scheduler,
          log,
          _resourceProvider,
          new MemoryByteStore(),
          fileContentOverlay,
          'test',
          sourceFactory,
          analysisOptions);
      scheduler.start();

      mainUnit = (await _driver.getResult(mainFile.path)).unit;
    } else {
      _context = AnalysisEngine.instance.createAnalysisContext();
      _context.analysisOptions = analysisOptions;
      _context.sourceFactory = sourceFactory;

      // Run the checker on /main.dart.
      Source mainSource = sourceFactory.forUri2(mainFile.toUri());
      mainUnit = _context.resolveCompilationUnit2(mainSource, mainSource);
    }

    var collector = new _ErrorCollector(analysisOptions);

    // Extract expectations from the comments in the test files, and
    // check that all errors we emit are included in the expected map.
    LibraryElement mainLibrary =
        resolutionMap.elementDeclaredByCompilationUnit(mainUnit).library;
    Set<LibraryElement> allLibraries = _reachableLibraries(mainLibrary);
    for (LibraryElement library in allLibraries) {
      for (CompilationUnitElement unit in library.units) {
        var errors = <AnalysisError>[];
        collector.errors = errors;

        var source = unit.source;
        if (source.uri.scheme == 'dart') {
          continue;
        }

        var analysisResult = await _resolve(source);

        errors.addAll(analysisResult.errors.where((e) =>
            // TODO(jmesserly): these are usually intentional dynamic calls.
            e.errorCode.name != 'UNDEFINED_METHOD' &&
            // We don't care about any of these:
            e.errorCode != HintCode.UNUSED_ELEMENT &&
            e.errorCode != HintCode.UNUSED_FIELD &&
            e.errorCode != HintCode.UNUSED_IMPORT &&
            e.errorCode != HintCode.UNUSED_LOCAL_VARIABLE &&
            e.errorCode != TodoCode.TODO));
        _expectErrors(analysisOptions, analysisResult.unit, errors);
      }
    }

    return mainUnit;
  }

  /// Adds a file using [addFile] and calls [check].
  ///
  /// Also returns the resolved compilation unit.
  Future<CompilationUnit> checkFile(String content) async {
    addFile(content);
    return check();
  }

  void setUp() {
    AnalysisEngine.instance.processRequiredPlugins();
  }

  void tearDown() {
    // This is a sanity check, in case only addFile is called.
    expect(_checkCalled, true, reason: 'must call check() method in test case');
    _context?.dispose();
    _driver?.dispose();
    AnalysisEngine.instance.clearCaches();
  }

  Future<_TestAnalysisResult> _resolve(Source source) async {
    if (enableNewAnalysisDriver) {
      var result = await _driver.getResult(source.fullName);
      return new _TestAnalysisResult(source, result.unit, result.errors);
    } else {
      List<Source> libraries = _context.getLibrariesContaining(source);
      var unit = _context.resolveCompilationUnit2(source, libraries.single);
      var errors = _context.computeErrors(source);
      return new _TestAnalysisResult(source, unit, errors);
    }
  }
}

class _ErrorCollector implements AnalysisErrorListener {
  final AnalysisOptions analysisOptions;
  List<AnalysisError> errors;
  final bool hints;

  _ErrorCollector(this.analysisOptions, {this.hints: true});

  void onError(AnalysisError error) {
    // Unless DDC hints are requested, filter them out.
    var HINT = ErrorSeverity.INFO.ordinal;
    if (hints || _errorSeverity(analysisOptions, error).ordinal > HINT) {
      errors.add(error);
    }
  }
}

/// Describes an expected message that should be produced by the checker.
class _ErrorExpectation {
  final int offset;
  final ErrorSeverity severity;
  final String typeName;

  _ErrorExpectation(this.offset, this.severity, this.typeName);

  String toString() => '@$offset ${severity.displayName}: [$typeName]';

  AnalysisError _removeMatchingActual(List<AnalysisError> actualErrors) {
    for (var actual in actualErrors) {
      if (actual.offset == offset) {
        actualErrors.remove(actual);
        return actual;
      }
    }
    return null;
  }

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
    return new _ErrorExpectation(offset, level, typeName);
  }
}

class _TestAnalysisResult {
  final Source source;
  final CompilationUnit unit;
  final List<AnalysisError> errors;
  _TestAnalysisResult(this.source, this.unit, this.errors);
}

class _TestUriResolver extends ResourceUriResolver {
  final MemoryResourceProvider provider;
  _TestUriResolver(provider)
      : provider = provider,
        super(provider);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    if (uri.scheme == 'package') {
      return (provider.getResource(
              provider.convertPath('/packages/' + uri.path)) as File)
          .createSource(uri);
    }
    return super.resolveAbsolute(uri, actualUri);
  }
}
