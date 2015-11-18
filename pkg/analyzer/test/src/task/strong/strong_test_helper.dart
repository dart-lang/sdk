// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): this file needs to be refactored, it's a port from
// package:dev_compiler's tests
library test.src.task.strong.strong_test_helper;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/context/context.dart' show SdkAnalysisContext;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart' hide SdkAnalysisContext;
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/strong/checker.dart';
import 'package:analyzer/src/task/strong/rules.dart';
import 'package:logging/logging.dart'; // TODO(jmesserly): remove
import 'package:source_span/source_span.dart'; // TODO(jmesserly): remove
import 'package:unittest/unittest.dart';

/// Run the checker on a program with files contents as indicated in
/// [testFiles].
///
/// This function makes several assumptions to make it easier to describe error
/// expectations:
///
///   * a file named `/main.dart` exists in [testFiles].
///   * all expected failures are listed in the source code using comments
///   immediately in front of the AST node that should contain the error.
///   * errors are formatted as a token `level:Type`, where `level` is the
///   logging level were the error would be reported at, and `Type` is the
///   concrete subclass of [StaticInfo] that denotes the error.
///
/// For example, to check that an assignment produces a warning about a boxing
/// conversion, you can describe the test as follows:
///
///     testChecker({
///       '/main.dart': '''
///           testMethod() {
///             dynamic x = /*warning:Box*/3;
///           }
///       '''
///     });
///
void testChecker(String name, Map<String, String> testFiles) {
  test(name, () {
    expect(testFiles.containsKey('/main.dart'), isTrue,
        reason: '`/main.dart` is missing in testFiles');

    var provider = new MemoryResourceProvider();
    testFiles.forEach((key, value) {
      var scheme = 'package:';
      if (key.startsWith(scheme)) {
        key = '/packages/${key.substring(scheme.length)}';
      }
      provider.newFile(key, value);
    });
    var uriResolver = new TestUriResolver(provider);
    // Enable task model strong mode
    AnalysisEngine.instance.useTaskModel = true;
    var context = AnalysisEngine.instance.createAnalysisContext();
    context.analysisOptions.strongMode = true;

    context.sourceFactory = new SourceFactory([
      new MockDartSdk(mockSdkSources, reportMissing: true).resolver,
      uriResolver
    ]);

    // Run the checker on /main.dart.
    Source mainSource = uriResolver.resolveAbsolute(new Uri.file('/main.dart'));
    var initialLibrary =
        context.resolveCompilationUnit2(mainSource, mainSource);

    var collector = new _ErrorCollector();
    var checker = new CodeChecker(
        new TypeRules(context.typeProvider), collector,
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
        checker.visitCompilationUnit(resolved);

        new _ExpectedErrorVisitor(errors).validate(resolved);
      }
    }
  });
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
        if (start != -1 && end != -1) {
          expect(start, lessThan(end));
          var errors = commentText.substring(start + 2, end).split(',');
          var expectations =
              errors.map(_ErrorExpectation.parse).where((x) => x != null);

          for (var e in expectations) _expectError(node, e);
        }
      }
    }
    return super.visitNode(node);
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
    var msg = span.message(expected.typeName, color: colorOf(levelName));
    fail('expected error was not reported at:\n\n$levelName: $msg');
  }

  Level _actualErrorLevel(AnalysisError actual) {
    return const <ErrorSeverity, Level>{
      ErrorSeverity.ERROR: Level.SEVERE,
      ErrorSeverity.WARNING: Level.WARNING,
      ErrorSeverity.INFO: Level.INFO
    }[actual.errorCode.errorSeverity];
  }

  String _formatActualError(AnalysisError actual) {
    var span = _createSpan(actual.offset, actual.length);
    var levelName = _actualErrorLevel(actual).name.toLowerCase();
    var msg = span.message(actual.message, color: colorOf(levelName));
    return '$levelName: [${errorCodeName(actual.errorCode)}] $msg';
  }

  SourceSpan _createSpan(int offset, int len) {
    return createSpanHelper(_unit.lineInfo, offset, offset + len,
        _unit.element.source, _unitSourceCode);
  }
}

SourceLocation locationForOffset(LineInfo lineInfo, Uri uri, int offset) {
  var loc = lineInfo.getLocation(offset);
  return new SourceLocation(offset,
      sourceUrl: uri, line: loc.lineNumber - 1, column: loc.columnNumber - 1);
}

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

/// Describes an expected message that should be produced by the checker.
class _ErrorExpectation {
  final Level level;
  final String typeName;
  _ErrorExpectation(this.level, this.typeName);

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

  String toString() => '$level $typeName';
}

/// Dart SDK which contains a mock implementation of the SDK libraries. May be
/// used to speed up execution when most of the core libraries is not needed.
class MockDartSdk implements DartSdk {
  final Map<Uri, _MockSdkSource> _sources = {};
  final bool reportMissing;
  final Map<String, SdkLibrary> _libs = {};
  final String sdkVersion = '0';
  List<String> get uris => _sources.keys.map((uri) => '$uri').toList();
  final AnalysisContext context = new SdkAnalysisContext();
  DartUriResolver _resolver;
  DartUriResolver get resolver => _resolver;

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

  List<SdkLibrary> get sdkLibraries => _libs.values.toList();
  SdkLibrary getSdkLibrary(String dartUri) => _libs[dartUri];
  Source mapDartUri(String dartUri) => _getSource(Uri.parse(dartUri));

  Source fromEncoding(UriKind kind, Uri uri) {
    if (kind != UriKind.DART_URI) {
      throw new UnsupportedError('expected dart: uri kind, got $kind.');
    }
    return _getSource(uri);
  }

  Source _getSource(Uri uri) {
    var src = _sources[uri];
    if (src == null) {
      if (reportMissing) print('warning: missing mock for $uri.');
      _sources[uri] =
          src = new _MockSdkSource(uri, 'library dart.${uri.path};');
    }
    return src;
  }

  @override
  Source fromFileUri(Uri uri) {
    throw new UnsupportedError('MockDartSdk.fromFileUri');
  }
}

class _MockSdkSource implements Source {
  /// Absolute URI which this source can be imported from.
  final Uri uri;
  final String _contents;

  _MockSdkSource(this.uri, this._contents);

  bool exists() => true;

  int get hashCode => uri.hashCode;

  final int modificationStamp = 1;

  TimestampedData<String> get contents =>
      new TimestampedData(modificationStamp, _contents);

  String get encoding => "${uriKind.encoding}$uri";

  Source get source => this;

  String get fullName => shortName;

  String get shortName => uri.path;

  UriKind get uriKind => UriKind.DART_URI;

  bool get isInSystemLibrary => true;

  Source resolveRelative(Uri relativeUri) =>
      throw new UnsupportedError('not expecting relative urls in dart: mocks');

  Uri resolveRelativeUri(Uri relativeUri) =>
      throw new UnsupportedError('not expecting relative urls in dart: mocks');
}

/// Sample mock SDK sources.
final Map<String, String> mockSdkSources = {
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
          fold(initialValue, combine(previousValue, E element)) {}
          Iterable map(f(E element)) {}
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
        class Future<T> {
          Future(computation()) {}
          Future.value(T t) {}
          Future then(onValue(T value)) {}
          static Future<List> wait(Iterable<Future> futures) {}
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
        num min(num x, num y) {}
        num max(num x, num y) {}
        ''',
};

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

String errorCodeName(ErrorCode errorCode) {
  var name = errorCode.name;
  final prefix = 'dev_compiler.';
  if (name.startsWith(prefix)) {
    return name.substring(prefix.length);
  } else {
    // TODO(jmesserly): this is for backwards compat, but not sure it's very
    // useful to log this.
    return 'AnalyzerMessage';
  }
}

/// Returns an ANSII color escape sequence corresponding to [levelName]. Colors
/// are defined for: severe, error, warning, or info. Returns null if the level
/// name is not recognized.
String colorOf(String levelName) {
  levelName = levelName.toLowerCase();
  if (levelName == 'shout' || levelName == 'severe' || levelName == 'error') {
    return _RED_COLOR;
  }
  if (levelName == 'warning') return _MAGENTA_COLOR;
  if (levelName == 'info') return _CYAN_COLOR;
  return null;
}

const String _RED_COLOR = '\u001b[31m';
const String _MAGENTA_COLOR = '\u001b[35m';
const String _CYAN_COLOR = '\u001b[36m';
const String GREEN_COLOR = '\u001b[32m';
const String NO_COLOR = '\u001b[0m';
