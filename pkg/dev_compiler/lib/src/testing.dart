// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.testing;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart' show TimestampedData;
import 'package:analyzer/src/generated/source.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart';
import 'package:unittest/unittest.dart';

import 'package:dev_compiler/src/checker/dart_sdk.dart'
    show mockSdkSources, dartSdkDirectory;
import 'package:dev_compiler/src/checker/resolver.dart' show TypeResolver;
import 'package:dev_compiler/src/utils.dart';
import 'package:dev_compiler/src/info.dart';
import 'package:dev_compiler/src/options.dart';
import 'package:dev_compiler/src/report.dart';
import 'package:dev_compiler/config.dart';
import 'package:dev_compiler/devc.dart' show Compiler;

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
CheckerResults testChecker(Map<String, String> testFiles,
    {bool allowConstCasts: true, String sdkDir, CheckerReporter reporter,
    covariantGenerics: true, relaxedCasts: true,
    inferFromOverrides: ResolverOptions.inferFromOverridesDefault,
    inferStaticsFromIdentifiers: ResolverOptions.inferStaticsFromIdentifiersDefault,
    inferInNonStableOrder: ResolverOptions.inferInNonStableOrderDefault,
    nonnullableTypes: TypeOptions.NONNULLABLE_TYPES}) {
  expect(testFiles.containsKey('/main.dart'), isTrue,
      reason: '`/main.dart` is missing in testFiles');

  // Create a resolver that can load test files from memory.
  var testUriResolver = new TestUriResolver(testFiles);
  var options = new CompilerOptions(
      allowConstCasts: allowConstCasts,
      covariantGenerics: covariantGenerics,
      relaxedCasts: relaxedCasts,
      inferFromOverrides: inferFromOverrides,
      inferStaticsFromIdentifiers: inferStaticsFromIdentifiers,
      inferInNonStableOrder: inferInNonStableOrder,
      nonnullableTypes: nonnullableTypes,
      useMockSdk: sdkDir == null,
      dartSdkPath: sdkDir,
      entryPointFile: '/main.dart');
  var resolver = sdkDir == null
      ? new TypeResolver.fromMock(mockSdkSources, options,
          otherResolvers: [testUriResolver])
      : new TypeResolver.fromDir(sdkDir, options,
          otherResolvers: [testUriResolver]);

  // Run the checker on /main.dart.
  var mainFile = new Uri.file('/main.dart');
  var checkExpectations = reporter == null;
  if (reporter == null) reporter = new TestReporter();
  var results = new Compiler(options, resolver, reporter).run();

  // Extract expectations from the comments in the test files.
  var expectedErrors = <AstNode, List<_ErrorExpectation>>{};
  var visitor = new _ErrorMarkerVisitor(expectedErrors);
  var initialLibrary =
      resolver.context.getLibraryElement(testUriResolver.files[mainFile]);
  for (var lib in reachableLibraries(initialLibrary)) {
    for (var unit in lib.units) {
      unit.unit.accept(visitor);
    }
  }

  if (!checkExpectations) return results;

  var total = expectedErrors.values.fold(0, (p, l) => p + l.length);
  // Check that all errors we emit are included in the expected map.
  for (var lib in results.libraries) {
    var uri = lib.library.source.uri;
    (reporter as TestReporter).infoMap[uri].forEach((node, actual) {
      var expected = expectedErrors[node];
      var expectedTotal = expected == null ? 0 : expected.length;
      if (actual.length != expectedTotal) {
        expect(actual.length, expectedTotal,
            reason: 'The checker found ${actual.length} errors on the '
            'expression `$node`, but we expected $expectedTotal. These are the '
            'errors the checker found:\n\n ${_unexpectedErrors(node, actual)}');
      }

      for (int i = 0; i < expected.length; i++) {
        expect(actual[i].level, expected[i].level,
            reason: 'expected different logging level at:\n\n'
            '${_messageWithSpan(actual[i])}');
        expect(actual[i].runtimeType, expected[i].type,
            reason: 'expected different error type at:\n\n'
            '${_messageWithSpan(actual[i])}');
      }
      expectedErrors.remove(node);
    });
  }

  // Check that all expected errors are accounted for.
  if (!expectedErrors.isEmpty) {
    var newTotal = expectedErrors.values.fold(0, (p, l) => p + l.length);
    // Non empty error expectation lists remaining
    if (newTotal > 0) {
      fail('Not all expected errors were reported by the checker. Only'
          ' ${total - newTotal} out of $total expected errors were reported.\n'
          'The following errors were not reported:\n'
          '${_unreportedErrors(expectedErrors)}');
    }
  }

  return results;
}

class TestReporter extends SummaryReporter {
  Map<Uri, Map<AstNode, List<StaticInfo>>> infoMap = {};
  Uri _current;

  void enterLibrary(Uri uri) {
    super.enterLibrary(uri);
    infoMap[uri] = {};
    _current = uri;
  }

  void log(Message info) {
    super.log(info);
    if (info is! StaticInfo) return;
    infoMap[_current].putIfAbsent(info.node, () => []).add(info);
  }
}

/// Create an error explanation for errors that were not expected, but that the
/// checker produced.
String _unexpectedErrors(AstNode node, List errors) {
  final span = _spanFor(node);
  return errors.map((e) {
    var level = e.level.name.toLowerCase();
    return '$level: ${span.message(e.message, color: colorOf(level))}';
  }).join('\n');
}

String _unreportedErrors(Map<AstNode, List<_ErrorExpectation>> expected) {
  var sb = new StringBuffer();
  for (var node in expected.keys) {
    var span = _spanFor(node);
    expected[node].forEach((e) {
      var level = e.level.name.toLowerCase();
      sb.write('$level: ${span.message("${e.type}", color: colorOf(level))}\n');
    });
  }
  return sb.toString();
}

String _messageWithSpan(StaticInfo info) {
  var span = _spanFor(info.node);
  var level = info.level.name.toLowerCase();
  return '$level: ${span.message(info.message, color: colorOf(level))}';
}

SourceSpan _spanFor(AstNode node) {
  var root = node.root as CompilationUnit;
  TestSource source = (root.element as CompilationUnitElementImpl).source;
  return source.spanFor(node);
}

/// Visitor that extracts expected errors from comments.
class _ErrorMarkerVisitor extends UnifyingAstVisitor {
  Map<AstNode, List<_ErrorExpectation>> expectedErrors;

  _ErrorMarkerVisitor(this.expectedErrors);

  visitNode(AstNode node) {
    var token = node.beginToken;
    var comment = token.precedingComments;
    // Use error marker found in an immediately preceding comment,
    // and attach it to the outermost expression that starts at that token.
    if (comment != null) {
      while (comment.next != null) {
        comment = comment.next;
      }
      if (comment.end == token.offset &&
          _realParent(node).beginToken != token) {
        var commentText = '$comment';
        var start = commentText.lastIndexOf('/*');
        var end = commentText.lastIndexOf('*/');
        if (start != -1 && end != -1) {
          expect(start, lessThan(end));
          var errors = commentText.substring(start + 2, end).split(',');
          var expectations = errors.map(_ErrorExpectation.parse);
          expectedErrors[node] = expectations.where((x) => x != null).toList();
        }
      }
    }
    return super.visitNode(node);
  }

  /// Get the node's parent, ignoring fake conversion nodes.
  AstNode _realParent(AstNode node) {
    var p = node.parent;
    while (p is Conversion) p = p.parent;
    return p;
  }
}

/// Describes an expected message that should be produced by the checker.
class _ErrorExpectation {
  final Level level;
  final Type type;
  _ErrorExpectation(this.level, this.type);

  static _ErrorExpectation _parse(String descriptor) {
    var tokens = descriptor.split(':');
    expect(tokens.length, 2, reason: 'invalid error descriptor');
    var name = tokens[0].toUpperCase();
    var typeName = tokens[1].toLowerCase();

    var level =
        Level.LEVELS.firstWhere((l) => l.name == name, orElse: () => null);
    expect(level, isNotNull,
        reason: 'invalid level in error descriptor: `${tokens[0]}`');
    var type = infoTypes.firstWhere((t) => '$t'.toLowerCase() == typeName,
        orElse: () => null);
    expect(type, isNotNull,
        reason: 'invalid type in error descriptor: ${tokens[1]}');
    return new _ErrorExpectation(level, type);
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

  String toString() => '$level $type';
}

/// Uri resolver that can load test files from memory.
class TestUriResolver extends UriResolver {
  final Map<Uri, TestSource> files = <Uri, TestSource>{};

  /// Whether to represent a non-existing file with a [TestSource] (default
  /// behavior from analyzer), or to use null (possible when overriding the
  /// package-url-resolvers.)
  final bool representNonExistingFiles;

  TestUriResolver(Map<String, String> allFiles,
      {this.representNonExistingFiles: true}) {
    allFiles.forEach((key, value) {
      var uri = key.startsWith('package:') ? Uri.parse(key) : new Uri.file(key);
      files[uri] = new TestSource(uri, value);
    });
  }

  Source resolveAbsolute(Uri uri) {
    if (uri.scheme != 'file' && uri.scheme != 'package') return null;
    if (!representNonExistingFiles) return files[uri];
    return files.putIfAbsent(uri, () => new TestSource(uri, null));
  }
}

class TestContents implements TimestampedData<String> {
  int modificationTime;
  String data;

  TestContents(this.modificationTime, this.data);
}

/// An in memory source file.
class TestSource implements Source {
  final Uri uri;
  TestContents contents;
  final SourceFile _file;
  final UriKind uriKind;

  TestSource(uri, contents)
      : uri = uri,
        contents = new TestContents(1, contents),
        _file = contents != null ? new SourceFile(contents, url: uri) : null,
        uriKind = uri.scheme == 'file' ? UriKind.FILE_URI : UriKind.PACKAGE_URI;

  bool exists() => contents.data != null;

  Source get source => this;

  String _encoding;
  String get encoding => _encoding != null ? _encoding : (_encoding = '$uri');

  String get fullName => uri.path;

  int get modificationStamp => contents.modificationTime;
  String get shortName => path.basename(uri.path);

  operator ==(other) => other is TestSource && uri == other.uri;
  int get hashCode => uri.hashCode;
  bool get isInSystemLibrary => false;

  Uri resolveRelativeUri(Uri relativeUri) => uri.resolveUri(relativeUri);

  SourceSpan spanFor(AstNode node) {
    final begin = node is AnnotatedNode
        ? node.firstTokenAfterCommentAndMetadata.offset
        : node.offset;
    return _file.span(begin, node.end);
  }

  String toString() => '[$runtimeType: $uri]';
}
