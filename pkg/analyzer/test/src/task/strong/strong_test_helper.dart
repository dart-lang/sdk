// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file

// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): this file needs to be refactored, it's a port from
// package:dev_compiler's tests
library analyzer.test.src.task.strong.strong_test_helper;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/context/context.dart' show SdkAnalysisContext;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/task/strong/checker.dart';
import 'package:logging/logging.dart';
import 'package:source_span/source_span.dart';
import 'package:unittest/unittest.dart';

MemoryResourceProvider files;
bool _checkCalled;

initStrongModeTests() {
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

/// Adds a file using [addFile] and calls [check].
void checkFile(String content) {
  addFile(content);
  check();
}

/// Adds a file to check. The file should contain:
///
///   * all expected failures are listed in the source code using comments
///     immediately in front of the AST node that should contain the error.
///
///   * errors are formatted as a token `level:Type`, where `level` is the
///     logging level were the error would be reported at, and `Type` is the
///     concrete subclass of [StaticInfo] that denotes the error.
///
/// For example to check that an assignment produces a type error, you can
/// create a file like:
///
///     addFile('''
///       String x = /*severe:STATIC_TYPE_ERROR*/3;
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
void check() {
  _checkCalled = true;

  expect(files.getFile('/main.dart').exists, true,
      reason: '`/main.dart` is missing');

  var uriResolver = new TestUriResolver(files);
  // Enable task model strong mode
  var context = AnalysisEngine.instance.createAnalysisContext();
  context.analysisOptions.strongMode = true;
  context.analysisOptions.strongModeHints = true;
  context.sourceFactory = new SourceFactory([
    new MockDartSdk(_mockSdkSources, reportMissing: true).resolver,
    uriResolver
  ]);

  // Run the checker on /main.dart.
  Source mainSource = uriResolver.resolveAbsolute(new Uri.file('/main.dart'));
  var initialLibrary = context.resolveCompilationUnit2(mainSource, mainSource);

  var collector = new _ErrorCollector();
  var checker = new CodeChecker(
      context.typeProvider, new StrongTypeSystemImpl(), collector,
      hints: true);

  // Extract expectations from the comments in the test files, and
  // check that all errors we emit are included in the expected map.
  var allLibraries = reachableLibraries(initialLibrary.element.library);
  for (var lib in allLibraries) {
    for (var unit in lib.units) {
      var errors = <AnalysisError>[];
      collector.errors = errors;

      var source = unit.source;
      if (source.uri.scheme == 'dart') continue;

      var librarySource = context.getLibrariesContaining(source).single;
      var resolved = context.resolveCompilationUnit2(source, librarySource);
      errors.addAll(context.getErrors(source).errors.where((error) =>
          error.errorCode.name.startsWith('STRONG_MODE_INFERRED_TYPE')));
      checker.visitCompilationUnit(resolved);

      _expectErrors(resolved, errors);
    }
  }
}

/// Sample mock SDK sources.
final Map<String, String> _mockSdkSources = {
  // The list of types below is derived from:
  //   * types we use via our smoke queries, including HtmlElement and
  //     types from `_typeHandlers` (deserialize.dart)
  //   * types that are used internally by the resolver (see
  //   _initializeFrom in resolver.dart).
  'dart:core': '''
        library dart.core;

        void print(Object o) {}

        class Object {
          int get hashCode {}
          Type get runtimeType {}
          String toString(){}
          bool ==(other){}
        }
        class Function {}
        class StackTrace {}
        class Symbol {}
        class Type {}

        class String {
          String operator +(String other) {}
          String substring(int len) {}
        }
        class bool {}
        class num {
          num operator +(num other) {}
        }
        class int extends num {
          bool operator<(num other) {}
          int operator-() {}
        }
        class double extends num {}
        class DateTime {}
        class Null {}

        class Deprecated {
          final String expires;
          const Deprecated(this.expires);
        }
        const Object deprecated = const Deprecated("next release");
        class _Override { const _Override(); }
        const Object override = const _Override();
        class _Proxy { const _Proxy(); }
        const Object proxy = const _Proxy();

        class Iterable<E> {
          Iterable/*<R>*/ map/*<R>*/(/*=R*/ f(E e));

          /*=R*/ fold/*<R>*/(/*=R*/ initialValue,
              /*=R*/ combine(/*=R*/ previousValue, E element));
        }
        class List<E> implements Iterable<E> {
          List([int length]);
          List.filled(int length, E fill);
        }
        class Map<K, V> {
          Iterable<K> get keys {}
        }
        ''',
  'dart:async': '''
        library dart.async;
        class Future<T> {
          Future(computation()) {}
          Future.value(T t) {}
          static Future<List/*<T>*/> wait/*<T>*/(
              Iterable<Future/*<T>*/> futures) => null;
          Future/*<R>*/ then/*<R>*/(/*=R*/ onValue(T value)) => null;
        }
        class Stream<T> {}
  ''',
  'dart:html': '''
        library dart.html;
        class HtmlElement {}
        ''',
  'dart:math': '''
        library dart.math;
        class Random {
          bool nextBool() {}
        }
        num/*=T*/ min/*<T extends num>*/(num/*=T*/ a, num/*=T*/ b) => null;
        num/*=T*/ max/*<T extends num>*/(num/*=T*/ a, num/*=T*/ b) => null;
        ''',

  'dart:_foreign_helper': '''
  library dart._foreign_helper;

  JS(String typeDescription, String codeTemplate,
    [arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11])
  {}
  '''
};

SourceSpanWithContext createSpanHelper(
    LineInfo lineInfo, int start, Source source, String content,
    {int end}) {
  var startLoc = locationForOffset(lineInfo, source.uri, start);
  var endLoc = locationForOffset(lineInfo, source.uri, end ?? start);

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
    endLoc = locationForOffset(lineInfo, source.uri, lineEnd);
  }

  var text = content.substring(start, end);
  var lineText = content.substring(lineStart, lineEnd);
  return new SourceSpanWithContext(startLoc, endLoc, text, lineText);
}

String errorCodeName(ErrorCode errorCode) {
  var name = errorCode.name;
  final prefix = 'STRONG_MODE_';
  if (name.startsWith(prefix)) {
    return name.substring(prefix.length);
  } else {
    // TODO(jmesserly): this is for backwards compat, but not sure it's very
    // useful to log this.
    return 'AnalyzerMessage';
  }
}

// TODO(jmesserly): can we reuse the same mock SDK as Analyzer tests?
SourceLocation locationForOffset(LineInfo lineInfo, Uri uri, int offset) {
  var loc = lineInfo.getLocation(offset);
  return new SourceLocation(offset,
      sourceUrl: uri, line: loc.lineNumber - 1, column: loc.columnNumber - 1);
}

/// Returns all libraries transitively imported or exported from [start].
List<LibraryElement> reachableLibraries(LibraryElement start) {
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

/// Dart SDK which contains a mock implementation of the SDK libraries. May be
/// used to speed up execution when most of the core libraries is not needed.
class MockDartSdk implements DartSdk {
  final Map<Uri, _MockSdkSource> _sources = {};
  final bool reportMissing;
  final Map<String, SdkLibrary> _libs = {};
  final String sdkVersion = '0';
  final AnalysisContext context = new SdkAnalysisContext();
  DartUriResolver _resolver;

  MockDartSdk(Map<String, String> sources, {this.reportMissing}) {
    sources.forEach((uriString, contents) {
      var uri = Uri.parse(uriString);
      _sources[uri] = new _MockSdkSource(uri, contents);
      _libs[uriString] = new SdkLibraryImpl(uri.path)
        ..setDart2JsLibrary()
        ..setVmLibrary();
    });
    _resolver = new DartUriResolver(this);
    context.sourceFactory = new SourceFactory([_resolver]);
  }

  DartUriResolver get resolver => _resolver;

  List<SdkLibrary> get sdkLibraries => _libs.values.toList();

  List<String> get uris => _sources.keys.map((uri) => '$uri').toList();

  Source fromEncoding(UriKind kind, Uri uri) {
    if (kind != UriKind.DART_URI) {
      throw new UnsupportedError('expected dart: uri kind, got $kind.');
    }
    return _getSource(uri);
  }

  @override
  Source fromFileUri(Uri uri) {
    throw new UnsupportedError('MockDartSdk.fromFileUri');
  }

  SdkLibrary getSdkLibrary(String dartUri) => _libs[dartUri];

  Source mapDartUri(String dartUri) => _getSource(Uri.parse(dartUri));

  Source _getSource(Uri uri) {
    var src = _sources[uri];
    if (src == null) {
      if (reportMissing) print('warning: missing mock for $uri.');
      _sources[uri] =
          src = new _MockSdkSource(uri, 'library dart.${uri.path};');
    }
    return src;
  }
}

class TestUriResolver extends ResourceUriResolver {
  final MemoryResourceProvider provider;

  TestUriResolver(provider)
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

class _ErrorCollector implements AnalysisErrorListener {
  List<AnalysisError> errors;
  final bool hints;

  _ErrorCollector({this.hints: true});

  void onError(AnalysisError error) {
    // Unless DDC hints are requested, filter them out.
    var HINT = ErrorSeverity.INFO.ordinal;
    if (hints || error.errorCode.errorSeverity.ordinal > HINT) {
      errors.add(error);
    }
  }
}

/// Describes an expected message that should be produced by the checker.
class _ErrorExpectation {
  final int offset;
  final Level level;
  final String typeName;

  _ErrorExpectation(this.offset, this.level, this.typeName);

  String toString() =>
      '@$offset ${level.toString().toLowerCase()}: [$typeName]';

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

    var level =
        Level.LEVELS.firstWhere((l) => l.name == name, orElse: () => null);
    expect(level, isNotNull,
        reason: 'invalid level in error descriptor: `${tokens[0]}`');
    expect(typeName, isNotNull,
        reason: 'invalid type in error descriptor: ${tokens[1]}');
    return new _ErrorExpectation(offset, level, typeName);
  }

  AnalysisError _removeMatchingActual(List<AnalysisError> actualErrors) {
    for (var actual in actualErrors) {
      if (actual.offset == offset) {
        actualErrors.remove(actual);
        return actual;
      }
    }
    return null;
  }
}

void _expectErrors(CompilationUnit unit, List<AnalysisError> actualErrors) {
  var expectedErrors = _findExpectedErrors(unit.beginToken);

  // Categorize the differences, if any.
  var unreported = <_ErrorExpectation>[];
  var different = <_ErrorExpectation, AnalysisError>{};

  for (var expected in expectedErrors) {
    AnalysisError actual = expected._removeMatchingActual(actualErrors);
    if (actual != null) {
      if (_actualErrorLevel(actual) != expected.level ||
          errorCodeName(actual.errorCode) != expected.typeName) {
        different[expected] = actual;
      }
    } else {
      unreported.add(expected);
    }
  }

  // Whatever is left was an unexpected error.
  List<AnalysisError> unexpected = actualErrors;

  if (unreported.isNotEmpty || unexpected.isNotEmpty || different.isNotEmpty) {
    _reportFailure(unit, unreported, unexpected, different);
  }
}

void _reportFailure(
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
    var span = createSpanHelper(
        unit.lineInfo, offset, unit.element.source, sourceCode,
        end: offset + length);
    var levelName = _actualErrorLevel(error).name.toLowerCase();
    return '@$offset $levelName: [${errorCodeName(error.errorCode)}]\n' +
        span.message(error.message);
  }

  String formatExpectedError(_ErrorExpectation error) {
    int offset = error.offset;
    var span = createSpanHelper(
        unit.lineInfo, offset, unit.element.source, sourceCode);
    var levelName = error.level.toString().toLowerCase();
    return '@$offset $levelName: [${error.typeName}]\n' + span.message('');
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

List<_ErrorExpectation> _findExpectedErrors(Token beginToken) {
  var expectedErrors = <_ErrorExpectation>[];

  // Collect expectations like "severe:STATIC_TYPE_ERROR" from comment tokens.
  for (Token t = beginToken; t.type != TokenType.EOF; t = t.next) {
    for (CommentToken c = t.precedingComments; c != null; c = c.next) {
      if (c.type == TokenType.MULTI_LINE_COMMENT) {
        String value = c.lexeme.substring(2, c.lexeme.length - 2);
        if (value.contains(':')) {
          var offset = c.end;
          if (c.next?.type == TokenType.GENERIC_METHOD_TYPE_LIST) {
            offset += 2;
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

Level _actualErrorLevel(AnalysisError actual) {
  return const <ErrorSeverity, Level>{
    ErrorSeverity.ERROR: Level.SEVERE,
    ErrorSeverity.WARNING: Level.WARNING,
    ErrorSeverity.INFO: Level.INFO
  }[actual.errorCode.errorSeverity];
}

class _MockSdkSource implements Source {
  /// Absolute URI which this source can be imported from.
  final Uri uri;
  final String _contents;

  final int modificationStamp = 1;

  _MockSdkSource(this.uri, this._contents);

  TimestampedData<String> get contents =>
      new TimestampedData(modificationStamp, _contents);

  String get encoding => "${uriKind.encoding}$uri";

  String get fullName => shortName;

  int get hashCode => uri.hashCode;

  bool get isInSystemLibrary => true;

  String get shortName => uri.path;

  Source get source => this;

  UriKind get uriKind => UriKind.DART_URI;

  bool exists() => true;

  Source resolveRelative(Uri relativeUri) =>
      throw new UnsupportedError('not expecting relative urls in dart: mocks');

  Uri resolveRelativeUri(Uri relativeUri) =>
      throw new UnsupportedError('not expecting relative urls in dart: mocks');
}
