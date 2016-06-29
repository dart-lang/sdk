// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): this file needs to be refactored, it's a port from
// package:dev_compiler's tests
library analyzer.test.src.task.strong.strong_test_helper;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:source_span/source_span.dart';
import 'package:unittest/unittest.dart';

import '../../context/mock_sdk.dart';

MemoryResourceProvider files;
bool _checkCalled;

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
  files.newFile(name, content);
}

/// Run the checker on a program, staring from '/main.dart', and verifies that
/// errors/warnings/hints match the expected value.
///
/// See [addFile] for more information about how to encode expectations in
/// the file text.
///
/// Returns the main resolved library. This can be used for further checks.
CompilationUnit check({bool implicitCasts: true, bool implicitDynamic: true}) {
  _checkCalled = true;

  expect(files.getFile('/main.dart').exists, true,
      reason: '`/main.dart` is missing');

  var uriResolver = new _TestUriResolver(files);
  // Enable task model strong mode
  var context = AnalysisEngine.instance.createAnalysisContext();
  AnalysisOptionsImpl options = context.analysisOptions as AnalysisOptionsImpl;
  options.strongMode = true;
  options.strongModeHints = true;
  options.implicitCasts = implicitCasts;
  options.implicitDynamic = implicitDynamic;
  var mockSdk = new MockSdk();
  mockSdk.context.analysisOptions.strongMode = true;
  context.sourceFactory =
      new SourceFactory([new DartUriResolver(mockSdk), uriResolver]);

  // Run the checker on /main.dart.
  Source mainSource = uriResolver.resolveAbsolute(new Uri.file('/main.dart'));
  var initialLibrary = context.resolveCompilationUnit2(mainSource, mainSource);

  var collector = new _ErrorCollector(context);

  // Extract expectations from the comments in the test files, and
  // check that all errors we emit are included in the expected map.
  var allLibraries = _reachableLibraries(initialLibrary.element.library);
  for (var lib in allLibraries) {
    for (var unit in lib.units) {
      var errors = <AnalysisError>[];
      collector.errors = errors;

      var source = unit.source;
      if (source.uri.scheme == 'dart') continue;

      var librarySource = context.getLibrariesContaining(source).single;
      var resolved = context.resolveCompilationUnit2(source, librarySource);

      errors.addAll(context.computeErrors(source).where((e) =>
          // TODO(jmesserly): these are usually intentional dynamic calls.
          e.errorCode.name != 'UNDEFINED_METHOD' &&
          // We don't care about any of these:
          e.errorCode != HintCode.UNNECESSARY_CAST &&
          e.errorCode != HintCode.UNUSED_ELEMENT &&
          e.errorCode != HintCode.UNUSED_FIELD &&
          e.errorCode != HintCode.UNUSED_IMPORT &&
          e.errorCode != HintCode.UNUSED_LOCAL_VARIABLE &&
          e.errorCode != TodoCode.TODO));
      _expectErrors(context, resolved, errors);
    }
  }

  return initialLibrary;
}

/// Adds a file using [addFile] and calls [check].
///
/// Also returns the resolved compilation unit.
CompilationUnit checkFile(String content) {
  addFile(content);
  return check();
}

void initStrongModeTests() {
  setUp(() {
    AnalysisEngine.instance.processRequiredPlugins();
    files = new MemoryResourceProvider();
    _checkCalled = false;
  });

  tearDown(() {
    // This is a sanity check, in case only addFile is called.
    expect(_checkCalled, true, reason: 'must call check() method in test case');
    files = null;
  });
}

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

ErrorSeverity _errorSeverity(AnalysisContext context, AnalysisError error) {
  // Attempt to process severity in a similar way to analyzer_cli and server.
  return ErrorProcessor.getProcessor(context, error)?.severity ??
      error.errorCode.errorSeverity;
}

void _expectErrors(AnalysisContext context, CompilationUnit unit,
    List<AnalysisError> actualErrors) {
  var expectedErrors = _findExpectedErrors(unit.beginToken);

  // Sort both lists: by offset, then level, then name.
  actualErrors.sort((x, y) {
    int delta = x.offset.compareTo(y.offset);
    if (delta != 0) return delta;

    delta = _errorSeverity(context, x).compareTo(_errorSeverity(context, y));
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
      if (_errorSeverity(context, actual) != expected.severity ||
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
    _reportFailure(context, unit, unreported, unexpected, different);
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
List<LibraryElement> _reachableLibraries(LibraryElement start) {
  var results = <LibraryElement>[];
  var seen = new Set();
  void find(LibraryElement lib) {
    if (seen.contains(lib)) return;
    seen.add(lib);
    results.add(lib);
    lib.importedLibraries.forEach(find);
    lib.exportedLibraries.forEach(find);
  }
  find(start);
  return results;
}

void _reportFailure(
    AnalysisContext context,
    CompilationUnit unit,
    List<_ErrorExpectation> unreported,
    List<AnalysisError> unexpected,
    Map<_ErrorExpectation, AnalysisError> different) {
  // Get the source code. This reads the data again, but it's safe because
  // all tests use memory file system.
  var sourceCode = unit.element.source.contents.data;

  String formatActualError(AnalysisError error) {
    int offset = error.offset;
    int length = error.length;
    var span = _createSpanHelper(
        unit.lineInfo, offset, unit.element.source, sourceCode,
        end: offset + length);
    var levelName = _errorSeverity(context, error).displayName;
    return '@$offset $levelName:${_errorCodeName(error.errorCode)}\n' +
        span.message(error.message);
  }

  String formatExpectedError(_ErrorExpectation error) {
    int offset = error.offset;
    var span = _createSpanHelper(
        unit.lineInfo, offset, unit.element.source, sourceCode);
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

class _ErrorCollector implements AnalysisErrorListener {
  final AnalysisContext _context;
  List<AnalysisError> errors;
  final bool hints;

  _ErrorCollector(this._context, {this.hints: true});

  void onError(AnalysisError error) {
    // Unless DDC hints are requested, filter them out.
    var HINT = ErrorSeverity.INFO.ordinal;
    if (hints || _errorSeverity(_context, error).ordinal > HINT) {
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

class _TestUriResolver extends ResourceUriResolver {
  final MemoryResourceProvider provider;
  _TestUriResolver(provider)
      : provider = provider,
        super(provider);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    if (uri.scheme == 'package') {
      return (provider.getResource('/packages/' + uri.path) as File)
          .createSource(uri);
    }
    return super.resolveAbsolute(uri, actualUri);
  }
}
