// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.testing;

import 'dart:mirrors';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:cli_util/cli_util.dart' show getSdkDir;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart';
import 'package:test/test.dart';

import 'package:dev_compiler/strong_mode.dart';
import 'package:dev_compiler/src/analysis_context.dart';

import 'package:dev_compiler/src/server/dependency_graph.dart'
    show runtimeFilesForServerMode;
import 'package:dev_compiler/src/info.dart';
import 'package:dev_compiler/src/options.dart';
import 'package:dev_compiler/src/utils.dart';

/// Shared analysis context used for compilation.
final realSdkContext = createAnalysisContextWithSources(
    new StrongModeOptions(),
    new SourceResolverOptions(
        dartSdkPath: getSdkDir().path,
        customUrlMappings: {
          'package:expect/expect.dart': _testCodegenPath('expect.dart'),
          'package:async_helper/async_helper.dart':
              _testCodegenPath('async_helper.dart'),
          'package:unittest/unittest.dart': _testCodegenPath('unittest.dart'),
          'package:dom/dom.dart': _testCodegenPath('sunflower', 'dom.dart')
        }))..analysisOptions.cacheSize = 512;

String _testCodegenPath(String p1, [String p2]) =>
    path.join(testDirectory, 'codegen', p1, p2);

final String testDirectory =
    path.dirname((reflectClass(_TestUtils).owner as LibraryMirror).uri.path);

class _TestUtils {}

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
void testChecker(String name, Map<String, String> testFiles,
    {String sdkDir,
    customUrlMappings: const {},
    relaxedCasts: true,
    inferDownwards: StrongModeOptions.inferDownwardsDefault,
    inferFromOverrides: StrongModeOptions.inferFromOverridesDefault,
    inferTransitively: StrongModeOptions.inferTransitivelyDefault,
    nonnullableTypes: StrongModeOptions.NONNULLABLE_TYPES}) {
  test(name, () {
    expect(testFiles.containsKey('/main.dart'), isTrue,
        reason: '`/main.dart` is missing in testFiles');

    var provider = createTestResourceProvider(testFiles);
    var uriResolver = new TestUriResolver(provider);
    // Enable task model strong mode
    AnalysisEngine.instance.useTaskModel = true;
    var context = AnalysisEngine.instance.createAnalysisContext();
    context.analysisOptions.strongMode = true;
    context.sourceFactory = createSourceFactory(
        new SourceResolverOptions(
            customUrlMappings: customUrlMappings,
            useMockSdk: sdkDir == null,
            dartSdkPath: sdkDir),
        fileResolvers: [uriResolver]);

    var checker = new StrongChecker(
        context,
        new StrongModeOptions(
            relaxedCasts: relaxedCasts,
            inferDownwards: inferDownwards,
            inferFromOverrides: inferFromOverrides,
            inferTransitively: inferTransitively,
            nonnullableTypes: nonnullableTypes,
            hints: true));

    // Run the checker on /main.dart.
    var mainSource = uriResolver.resolveAbsolute(new Uri.file('/main.dart'));
    var initialLibrary =
        context.resolveCompilationUnit2(mainSource, mainSource);

    // Extract expectations from the comments in the test files, and
    // check that all errors we emit are included in the expected map.
    var allLibraries = reachableLibraries(initialLibrary.element.library);
    for (var lib in allLibraries) {
      for (var unit in lib.units) {
        if (unit.source.uri.scheme == 'dart') continue;

        var errorInfo = checker.computeErrors(unit.source);
        new _ExpectedErrorVisitor(errorInfo.errors).validate(unit.unit);
      }
    }
  });
}

/// Creates a [MemoryResourceProvider] with test data
MemoryResourceProvider createTestResourceProvider(
    Map<String, String> testFiles) {
  var provider = new MemoryResourceProvider();
  runtimeFilesForServerMode.forEach((filepath) {
    testFiles['/dev_compiler_runtime/$filepath'] =
        '/* test contents of $filepath */';
  });
  testFiles.forEach((key, value) {
    var scheme = 'package:';
    if (key.startsWith(scheme)) {
      key = '/packages/${key.substring(scheme.length)}';
    }
    provider.newFile(key, value);
  });
  return provider;
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
