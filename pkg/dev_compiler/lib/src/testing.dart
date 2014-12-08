library ddc.src.testing;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart' show TimestampedData;
import 'package:analyzer/src/generated/source.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart';
import 'package:unittest/unittest.dart';

import 'package:ddc/src/dart_sdk.dart' show mockSdkSources, dartSdkDirectory;
import 'package:ddc/src/resolver.dart' show TypeResolver;
import 'package:ddc/src/utils.dart';
import 'package:ddc/src/static_info.dart';
import 'package:ddc/typechecker.dart';

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
/// For example, to check that an assigment produces a warning about a boxing
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
testChecker(Map<String, String> testFiles, {bool mockSdk: true}) {
  expect(testFiles.containsKey('/main.dart'), isTrue,
      reason: '`/main.dart` is missing in testFiles');

  // Create a resolver that can load test files from memory.
  var dartUriResolver = mockSdk
      ? TypeResolver.sdkResolverFromMock(mockSdkSources)
      : TypeResolver.sdkResolverFromDir(dartSdkDirectory);
  var testUriResolver = new _TestUriResolver(testFiles);
  var resolver = new TypeResolver(dartUriResolver, [testUriResolver]);

  // Run the checker on /main.dart.
  var mainFile = new Uri.file('/main.dart');
  var results = checkProgram(mainFile, resolver: resolver);

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

  var total = expectedErrors.values.fold(0, (p, l) => p + l.length);

  // Check that all errors we emit are included in the expected map.
  results.infoMap.forEach((key, value) {
    var expected = expectedErrors[key];
    var expectedTotal = expected == null ? 0 : expected.length;
    if (value.length != expectedTotal) {
      expect(value.length, expectedTotal,
          reason: 'The checker found ${value.length} errors on the expression'
              ' `$key`, but we expected $expectedTotal. These are the errors '
              'the checker found:\n\n'
              '${_unexpectedErrors(key, value)}');
    }

    for (int i = 0; i < expected.length; i++) {
      expect(value[i].level, expected[i].level,
          reason: 'expected different logging level at:\n\n'
              '${_messageWithSpan(value[i])}');
      expect(value[i].runtimeType, expected[i].type,
          reason: 'expected different error type at:\n\n'
              '${_messageWithSpan(value[i])}');
    }
    expectedErrors.remove(key);
  });


  // Check that all expected errors are accounted for.
  if (!expectedErrors.isEmpty) {
    var newTotal = expectedErrors.values.fold(0, (p, l) => p + l.length);
    fail('Not all expected errors were reported by the checker. Only'
        ' ${total - newTotal} out of $total expected errors were reported.\n'
        'The following errors were not reported:\n'
        '${_unreportedErrors(expectedErrors)}');
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
  _TestSource source = (root.element as CompilationUnitElementImpl).source;
  return source.spanFor(node);
}

/// Visitor that extracts expected errors from comments.
class _ErrorMarkerVisitor extends UnifyingAstVisitor {
  Map<AstNode, List<_ErrorExpectation>> expectedErrors;

  _ErrorMarkerVisitor(this.expectedErrors);

  visitNode(AstNode node) {
    var token = node.beginToken;
    var comment = token.precedingComments;
    // Use error marker found in an immediately preceding comment.
    if (comment != null && comment.end == token.offset
        // and attach it to the outermost expression that starts at that token.
        && node.parent.beginToken != token) {
      var commentText = '$comment';
      expect(commentText.startsWith('/*'), isTrue);
      expect(commentText.startsWith('/**'), isFalse);
      expect(commentText.endsWith('*/'), isTrue);
      expect(commentText.endsWith('**/'), isFalse);
      var errors = commentText.substring(2, commentText.length - 2).split(',');
      expectedErrors[node] = errors.map(_ErrorExpectation.parse).toList();
    }
    return super.visitNode(node);
  }
}

/// Describes an expected message that should be produced by the checker.
class _ErrorExpectation {
  final Level level;
  final Type type;
  _ErrorExpectation(this.level, this.type);

  static _ErrorExpectation parse(String descriptor) {
    descriptor = descriptor.trim();
    var tokens = descriptor.split(':');
    expect(tokens.length, 2, reason: 'invalid error descriptor');
    var name = tokens[0].toUpperCase();
    var typeName = tokens[1].toLowerCase();

    var level = Level.LEVELS.firstWhere((l) => l.name == name,
        orElse: () => null);
    expect(level, isNotNull,
        reason: 'invalid level in error descriptor: `${tokens[0]}`');
    var type = _infoTypes.firstWhere((t) => '$t'.toLowerCase() == typeName,
        orElse: () => null);
    expect(type, isNotNull,
        reason: 'invalid type in error descriptor: ${tokens[1]}');
    return new _ErrorExpectation(level, type);
  }
}

/// Uri resolver that can load test files from memory.
class _TestUriResolver extends UriResolver {
  final Map<Uri, _TestSource> files = <Uri, _TestSource>{};

  _TestUriResolver(Map<String, String> allFiles) {
    allFiles.forEach((key, value) {
      var uri = new Uri.file(key);
      files[uri] = new _TestSource(uri, value);
    });
  }

  Source resolveAbsolute(Uri uri) {
    if (uri.scheme != 'file') return null;
    return files[uri];
  }
}

/// An in memory source file.
class _TestSource implements Source {
  final Uri uri;
  final TimestampedData<String> contents;
  final SourceFile _file;

  _TestSource(uri, contents)
      : uri = uri,
        contents = new TimestampedData<String>(0, contents),
        _file = new SourceFile(contents, url: uri);

  bool exists() => true;

  String _encoding;
  String get encoding => _encoding != null ? _encoding : (_encoding = '$uri');

  String get fullName => uri.path;

  int get modificationStamp => 0;
  String get shortName => path.basename(uri.path);

  final UriKind uriKind = UriKind.FILE_URI;

  operator ==(other) => other is _TestSource && uri == other.uri;
  int get hashCode => uri.hashCode;
  bool get isInSystemLibrary => false;

  Uri resolveRelativeUri(Uri relativeUri) => uri.resolveUri(relativeUri);

  SourceSpan spanFor(AstNode node) => _file.span(node.offset, node.end);
}

const _infoTypes = const [Box, ClosureWrap, DownCast, DynamicInvoke,
    InvalidOverride, InvalidRuntimeCheckError, NumericConversion,
    StaticTypeError, Unbox];
