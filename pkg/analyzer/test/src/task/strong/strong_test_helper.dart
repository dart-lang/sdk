// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): this file needs to be refactored, it's a port from
// package:dev_compiler's tests
library analyzer.test.src.task.strong.strong_test_helper;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/context/context.dart' show SdkAnalysisContext;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
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
  var initialLibrary =
      context.resolveCompilationUnit2(mainSource, mainSource);

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
      var analyzerErrors = context
          .getErrors(source)
          .errors
          .where((error) =>
              error.errorCode.name.startsWith('STRONG_MODE_INFERRED_TYPE'))
          .toList();
      errors.addAll(analyzerErrors);
      checker.visitCompilationUnit(resolved);

      new _ExpectedErrorVisitor(errors).validate(resolved);
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
    LineInfo lineInfo, int start, int end, Source source, String content) {
  var startLoc = locationForOffset(lineInfo, source.uri, start);
  var endLoc = locationForOffset(lineInfo, source.uri, end);

  var lineStart = startLoc.offset - startLoc.column;
  // Find the end of the line. This is not exposed directly on LineInfo, but
  // we can find it pretty easily.
  // TODO(jmesserly): for now we do the simple linear scan. Ideally we can get
  // some help from the LineInfo API.
  int lineEnd = endLoc.offset;
  int lineNum = lineInfo.getLocation(lineEnd).lineNumber;
  while (lineEnd < content.length &&
      lineInfo.getLocation(++lineEnd).lineNumber == lineNum);

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
  final Level level;
  final String typeName;
  _ErrorExpectation(this.level, this.typeName);

  String toString() => '$level $typeName';

  static _ErrorExpectation parse(String descriptor) {
    descriptor = descriptor.trim();
    var tokens = descriptor.split(' ');
    if (tokens.length == 1) return _parse(tokens[0]);
    expect(tokens.length, 4, reason: 'invalid error descriptor');
    expect(tokens[1], "should", reason: 'invalid error descriptor');
    expect(tokens[2], "be", reason: 'invalid error descriptor');
    if (tokens[0] == "pass") return null;
    // TODO(leafp) For now, we just use whatever the current expectation is,
    // eventually we could do more automated reporting here.
    return _parse(tokens[0]);
  }

  static _ErrorExpectation _parse(String descriptor) {
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
    return new _ErrorExpectation(level, typeName);
  }
}

class _ExpectedErrorVisitor extends UnifyingAstVisitor {
  final Set<AnalysisError> _actualErrors;
  CompilationUnit _unit;
  String _unitSourceCode;

  _ExpectedErrorVisitor(List<AnalysisError> actualErrors)
      : _actualErrors = new Set.from(actualErrors);

  validate(CompilationUnit unit) {
    _unit = unit;
    // This reads the file. Only safe because tests use MemoryFileSystem.
    _unitSourceCode = unit.element.source.contents.data;

    // Visit the compilation unit.
    unit.accept(this);

    if (_actualErrors.isNotEmpty) {
      var actualMsgs = _actualErrors.map(_formatActualError).join('\n');
      fail('Unexpected errors reported by checker:\n\n$actualMsgs');
    }
  }

  visitNode(AstNode node) {
    var token = node.beginToken;
    var comment = token.precedingComments;
    // Use error marker found in an immediately preceding comment,
    // and attach it to the outermost expression that starts at that token.
    if (comment != null) {
      while (comment.next != null) {
        comment = comment.next;
      }
      if (comment.end == token.offset && node.parent.beginToken != token) {
        var commentText = '$comment';
        var start = commentText.lastIndexOf('/*');
        var end = commentText.lastIndexOf('*/');
        if (start != -1 &&
            end != -1 &&
            !commentText.startsWith('/*<', start) &&
            !commentText.startsWith('/*=', start)) {
          expect(start, lessThan(end));
          var errors = commentText.substring(start + 2, end).split(',');
          var expectations =
              errors.map(_ErrorExpectation.parse).where((x) => x != null);

          for (var e in expectations) {
            _expectError(node, e);
          }
        }
      }
    }
    return super.visitNode(node);
  }

  Level _actualErrorLevel(AnalysisError actual) {
    return const <ErrorSeverity, Level>{
      ErrorSeverity.ERROR: Level.SEVERE,
      ErrorSeverity.WARNING: Level.WARNING,
      ErrorSeverity.INFO: Level.INFO
    }[actual.errorCode.errorSeverity];
  }

  SourceSpan _createSpan(int offset, int len) {
    return createSpanHelper(_unit.lineInfo, offset, offset + len,
        _unit.element.source, _unitSourceCode);
  }

  void _expectError(AstNode node, _ErrorExpectation expected) {
    // See if we can find the expected error in our actual errors
    for (var actual in _actualErrors) {
      if (actual.offset == node.offset && actual.length == node.length) {
        var actualMsg = _formatActualError(actual);
        expect(_actualErrorLevel(actual), expected.level,
            reason: 'expected different error code at:\n\n$actualMsg');
        expect(errorCodeName(actual.errorCode), expected.typeName,
            reason: 'expected different error type at:\n\n$actualMsg');

        // We found it. Stop the search.
        _actualErrors.remove(actual);
        return;
      }
    }

    var span = _createSpan(node.offset, node.length);
    var levelName = expected.level.name.toLowerCase();
    var msg = span.message(expected.typeName, color: _colorOf(levelName));
    fail('expected error was not reported at:\n\n$levelName: $msg');
  }

  String _formatActualError(AnalysisError actual) {
    var span = _createSpan(actual.offset, actual.length);
    var levelName = _actualErrorLevel(actual).name.toLowerCase();
    var msg = span.message(actual.message, color: _colorOf(levelName));
    return '$levelName: [${errorCodeName(actual.errorCode)}] $msg';
  }

  /// Returns an ANSII color escape sequence corresponding to [levelName].
  ///
  /// Colors are defined for: severe, error, warning, or info.
  /// Returns null if the level name is not recognized.
  String _colorOf(String levelName) {
    const String CYAN_COLOR = '\u001b[36m';
    const String MAGENTA_COLOR = '\u001b[35m';
    const String RED_COLOR = '\u001b[31m';

    levelName = levelName.toLowerCase();
    if (levelName == 'shout' || levelName == 'severe' || levelName == 'error') {
      return RED_COLOR;
    }
    if (levelName == 'warning') return MAGENTA_COLOR;
    if (levelName == 'info') return CYAN_COLOR;
    return null;
  }
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
