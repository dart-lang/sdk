// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/error/analyzer_error_code.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/lint/util.dart';
import 'package:analyzer/src/test_utilities/mock_packages.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:collection/collection.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import 'mocks.dart';
import 'rule_test_support.dart';

export 'package:analyzer/src/dart/analysis/experiments.dart';
export 'package:analyzer/src/dart/error/syntactic_errors.dart';
export 'package:analyzer/src/error/codes.dart';
export 'package:analyzer/src/test_utilities/package_config_file_builder.dart';

ExpectedError error(ErrorCode code, int offset, int length,
        {Pattern? messageContains}) =>
    ExpectedError(code, offset, length, messageContains: messageContains);

typedef DiagnosticMatcher = bool Function(AnalysisError error);

class AnalysisOptionsFileConfig {
  final List<String> experiments;
  final List<String> lints;
  final bool propagateLinterExceptions;

  AnalysisOptionsFileConfig({
    this.experiments = const [],
    this.lints = const [],
    this.propagateLinterExceptions = false,
  });

  String toContent() {
    var buffer = StringBuffer();

    if (experiments.isNotEmpty || propagateLinterExceptions) {
      buffer.writeln('analyzer:');
      buffer.writeln('  enable-experiment:');
      for (var experiment in experiments) {
        buffer.writeln('    - $experiment');
      }

      if (propagateLinterExceptions) {
        buffer.writeln('  strong-mode:');
        buffer.writeln(
          '    propagate-linter-exceptions: $propagateLinterExceptions',
        );
      }
    }

    buffer.writeln('linter:');
    buffer.writeln('  rules:');
    for (var lint in lints) {
      buffer.writeln('    - $lint');
    }

    return buffer.toString();
  }
}

/// A description of a diagnostic that is expected to be reported.
class ExpectedDiagnostic {
  final DiagnosticMatcher diagnosticMatcher;

  /// The offset of the beginning of the diagnostic's region.
  final int offset;

  /// The offset of the beginning of the diagnostic's region.
  final int length;

  /// A pattern that should be contained in the diagnostic message or `null` if
  /// the message contents should not be checked.
  final Pattern? messageContains;

  /// Initialize a newly created diagnostic description.
  ExpectedDiagnostic(this.diagnosticMatcher, this.offset, this.length,
      {this.messageContains});

  /// Return `true` if the [error] matches this description of what it's
  /// expected to be.
  bool matches(AnalysisError error) {
    if (!diagnosticMatcher(error)) return false;
    if (error.offset != offset) return false;
    if (error.length != length) return false;
    if (messageContains != null && !error.message.contains(messageContains!)) {
      return false;
    }

    return true;
  }
}

class ExpectedError extends ExpectedDiagnostic {
  final ErrorCode code;

  /// Initialize a newly created error description.
  ExpectedError(this.code, int offset, int length, {Pattern? messageContains})
      : super((AnalysisError error) => error.errorCode == code, offset, length,
            messageContains: messageContains);
}

class ExpectedLint extends ExpectedDiagnostic {
  final String lintName;

  /// Initialize a newly created lint description.
  ExpectedLint(this.lintName, int offset, int length,
      {Pattern? messageContains})
      : super((AnalysisError error) => error.errorCode.name == lintName, offset,
            length,
            messageContains: messageContains);

  /// Initialize a newly created lint description.
  ExpectedLint.withLintCode(LintCode lintCode, int offset, int length,
      {Pattern? messageContains})
      : lintName = lintCode.uniqueName,
        super((AnalysisError error) => error.errorCode == lintCode, offset,
            length,
            messageContains: messageContains);
}

mixin LanguageVersion219Mixin on PubPackageResolutionTest {
  @override
  String? get testPackageLanguageVersion => '2.19';
}

abstract class LintRuleTest extends PubPackageResolutionTest {
  String get lintRule;

  @override
  List<String> get _lintRules {
    var ruleName = lintRule;
    if (!Registry.ruleRegistry.any((r) => r.name == ruleName)) {
      throw Exception("Unrecognized rule: '$ruleName'");
    }
    return [ruleName];
  }

  ExpectedLint lint(int offset, int length, {Pattern? messageContains}) =>
      ExpectedLint(lintRule, offset, length, messageContains: messageContains);
}

class PubPackageResolutionTest extends _ContextResolutionTest {
  final List<String> _lintRules = const [];

  bool get addFixnumPackageDep => false;

  bool get addFlutterPackageDep => false;

  bool get addJsPackageDep => false;

  bool get addKernelPackageDep => false;

  bool get addMetaPackageDep => false;

  @override
  List<String> get collectionIncludedPaths => [workspaceRootPath];

  bool get dumpAstOnFailures => true;

  List<String> get experiments => ['inline-class', 'macros'];

  /// The path that is not in [workspaceRootPath], contains external packages.
  String get packagesRootPath => '/packages';

  String get testFileName => 'test.dart';

  @override
  String get testFilePath => '$testPackageLibPath/$testFileName';

  String? get testPackageLanguageVersion => null;

  String get testPackageLibPath => '$testPackageRootPath/lib';

  String get testPackagePubspecPath => '$testPackageRootPath/pubspec.yaml';

  String get testPackageRootPath => '$workspaceRootPath/test';

  String get workspaceRootPath => '/home';

  /// Assert that the number of diagnostics that have been gathered matches the
  /// number of [expectedDiagnostics] and that they have the expected error
  /// descriptions and locations. The order in which the diagnostics were
  /// gathered is ignored.
  Future<void> assertDiagnostics(
      String code, List<ExpectedDiagnostic> expectedDiagnostics) async {
    addTestFile(code);
    await resolveTestFile();
    await assertDiagnosticsIn(errors, expectedDiagnostics);
  }

  /// Assert that the diagnostics in [errors] match [expectedDiagnostics].
  Future<void> assertDiagnosticsIn(List<AnalysisError> errors,
      List<ExpectedDiagnostic> expectedDiagnostics) async {
    //
    // Match actual diagnostics to expected diagnostics.
    //
    var unmatchedActual = errors.toList();
    var unmatchedExpected = expectedDiagnostics.toList();
    var actualIndex = 0;
    while (actualIndex < unmatchedActual.length) {
      var matchFound = false;
      var expectedIndex = 0;
      while (expectedIndex < unmatchedExpected.length) {
        if (unmatchedExpected[expectedIndex]
            .matches(unmatchedActual[actualIndex])) {
          matchFound = true;
          unmatchedActual.removeAt(actualIndex);
          unmatchedExpected.removeAt(expectedIndex);
          break;
        }
        expectedIndex++;
      }
      if (!matchFound) {
        actualIndex++;
      }
    }
    //
    // Write the results.
    //
    var buffer = StringBuffer();
    if (unmatchedExpected.isNotEmpty) {
      buffer.writeln('Expected but did not find:');
      for (var expected in unmatchedExpected) {
        buffer.write('  ');
        if (expected is ExpectedError) {
          buffer.write(expected.code);
        }
        if (expected is ExpectedLint) {
          buffer.write(expected.lintName);
        }
        buffer.write(' [');
        buffer.write(expected.offset);
        buffer.write(', ');
        buffer.write(expected.length);
        buffer.writeln(']');
      }
    }
    if (unmatchedActual.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.writeln();
      }
      buffer.writeln('Found but did not expect:');
      for (var actual in unmatchedActual) {
        buffer.write('  ');
        buffer.write(actual.errorCode);
        buffer.write(' [');
        buffer.write(actual.offset);
        buffer.write(', ');
        buffer.write(actual.length);
        buffer.write(', ');
        buffer.write(actual.message);
        buffer.writeln(']');
      }
    }
    if (buffer.isNotEmpty) {
      errors.sort((first, second) => first.offset.compareTo(second.offset));
      buffer.writeln();
      buffer.writeln('To accept the current state, expect:');
      for (var actual in errors) {
        late String diagnosticKind;
        Object? description;
        if (actual.errorCode is LintCode) {
          diagnosticKind = 'lint';
        } else {
          diagnosticKind = 'error';
          description = actual.errorCode;
        }
        buffer.write('  $diagnosticKind(');
        if (description != null) {
          buffer.write(description);
          buffer.write(', ');
        }
        buffer.write(actual.offset);
        buffer.write(', ');
        buffer.write(actual.length);
        buffer.writeln('),');
      }

      if (dumpAstOnFailures) {
        buffer.writeln();
        buffer.writeln();
        try {
          var astSink = CollectingSink();

          StringSpelunker(result.unit.toSource(),
                  sink: astSink, featureSet: result.unit.featureSet)
              .spelunk();
          buffer.write(astSink.buffer);
          buffer.writeln();
          // I hereby choose to catch this type.
          // ignore: avoid_catching_errors
        } on ArgumentError catch (_) {
          // Perhaps we encountered a parsing error while spelunking.
        }
      }

      fail(buffer.toString());
    }
  }

  /// Assert that there are no diagnostics in the given [code].
  Future<void> assertNoDiagnostics(String code) async =>
      assertDiagnostics(code, const []);

  /// Assert that there are no diagnostics in [errors].
  Future<void> assertNoDiagnosticsIn(List<AnalysisError> errors) =>
      assertDiagnosticsIn(errors, const []);

  /// Assert that no diagnostics are reported when resolving [content].
  Future<void> assertNoPubspecDiagnostics(String content) async {
    newFile(testPackagePubspecPath, content);
    var errors = await _resolvePubspecFile(content);
    await assertDiagnosticsIn(errors, []);
  }

  /// Assert that [expectedDiagnostics] are reported when resolving [content].
  Future<void> assertPubspecDiagnostics(
      String content, List<ExpectedDiagnostic> expectedDiagnostics) async {
    newFile(testPackagePubspecPath, content);
    var errors = await _resolvePubspecFile(content);
    await assertDiagnosticsIn(errors, expectedDiagnostics);
  }

  @override
  @mustCallSuper
  void setUp() {
    super.setUp();
    // Check for any needlessly enabled experiments.
    for (var experiment in experiments) {
      var feature = ExperimentStatus.knownFeatures[experiment];
      if (feature?.isEnabledByDefault ?? false) {
        fail("The '$experiment' experiment is enabled by default, "
            'try removing it from `experiments`.');
      }
    }

    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        experiments: experiments,
        lints: _lintRules,
        propagateLinterExceptions: true,
      ),
    );
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
    );
  }

  void writePackageConfig(String path, PackageConfigFileBuilder config) {
    newFile2(
      path,
      config.toContent(
        toUriStr: toUriStr,
      ),
    );
  }

  void writeTestPackageAnalysisOptionsFile(AnalysisOptionsFileConfig config) {
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      config.toContent(),
    );
  }

  void writeTestPackageConfig(PackageConfigFileBuilder config) {
    var configCopy = config.copy();

    configCopy.add(
      name: 'test',
      rootPath: testPackageRootPath,
      languageVersion: testPackageLanguageVersion,
    );

    if (addFixnumPackageDep) {
      var fixnumPath = '/packages/fixnum';
      addFixnumPackageFiles(
        getFolder(fixnumPath),
      );
      configCopy.add(name: 'fixnum', rootPath: fixnumPath);
    }

    if (addFlutterPackageDep) {
      var flutterPath = '/packages/flutter';
      addFlutterPackageFiles(
        getFolder(flutterPath),
      );
      configCopy.add(name: 'flutter', rootPath: flutterPath);
    }

    if (addJsPackageDep) {
      var jsPath = '/packages/js';
      MockPackages.addJsPackageFiles(
        getFolder(jsPath),
      );
      configCopy.add(name: 'js', rootPath: jsPath);
    }

    if (addKernelPackageDep) {
      var kernelPath = '/packages/kernel';
      MockPackages.addKernelPackageFiles(
        getFolder(kernelPath),
      );
      configCopy.add(name: 'kernel', rootPath: kernelPath);
    }

    if (addMetaPackageDep) {
      var metaPath = '/packages/meta';
      MockPackages.addMetaPackageFiles(
        getFolder(metaPath),
      );
      configCopy.add(name: 'meta', rootPath: metaPath);
    }

    var path = '$testPackageRootPath/.dart_tool/package_config.json';
    writePackageConfig(path, configCopy);
  }

  void writeTestPackagePubspecYamlFile(PubspecYamlFileConfig config) {
    newPubspecYamlFile(testPackageRootPath, config.toContent());
  }

  Future<List<AnalysisError>> _resolvePubspecFile(String content) async {
    var path = convertPath(testPackagePubspecPath);
    var pubspecRules = <LintRule, PubspecVisitor<Object?>>{};
    for (var rule in Registry.ruleRegistry
        .where((rule) => _lintRules.contains(rule.name))) {
      var visitor = rule.getPubspecVisitor();
      if (visitor != null) {
        pubspecRules[rule] = visitor;
      }
    }

    if (pubspecRules.isEmpty) {
      throw UnsupportedError(
          'Resolving pubspec files only supported with rules with '
          'PubspecVisitors.');
    }

    var sourceUri = resourceProvider.pathContext.toUri(path);
    var pubspecAst = Pubspec.parse(content,
        sourceUrl: sourceUri, resourceProvider: resourceProvider);
    var listener = RecordingErrorListener();
    var reporter = ErrorReporter(
        listener, resourceProvider.getFile(path).createSource(sourceUri),
        isNonNullableByDefault: false);
    for (var entry in pubspecRules.entries) {
      entry.key.reporter = reporter;
      pubspecAst.accept(entry.value);
    }
    return [...listener.errors];
  }

  /// Creates a fake 'fixnum' package that can be used by tests.
  static void addFixnumPackageFiles(Folder rootFolder) {
    var libFolder = rootFolder.getChildAssumingFolder('lib');
    libFolder.getChildAssumingFile('fixnum.dart').writeAsStringSync(r'''
library fixnum;

class Int32 {}

class Int64 {}
''');
  }

  /// Create a fake 'flutter' package that can be used by tests.
  static void addFlutterPackageFiles(Folder rootFolder) {
    var libFolder = rootFolder.getChildAssumingFolder('lib');

    libFolder.getChildAssumingFile('foundation.dart').writeAsStringSync(r'''
export 'src/foundation/constants.dart';
''');

    libFolder
        .getChildAssumingFolder('src')
        .getChildAssumingFolder('foundation')
        .getChildAssumingFile('constants.dart')
        .writeAsStringSync(r'''
mixin Diagnosticable {
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {}
}

class DiagnosticableTree with Diagnosticable {
  List<DiagnosticsNode> debugDescribeChildren() => const [];
}

class DiagnosticPropertiesBuilder {}

class DiagnosticsNode {}

class Key {
  Key(String value);
}

const bool kDebugMode = true;
''');

    libFolder.getChildAssumingFile('widgets.dart').writeAsStringSync(r'''
export 'src/widgets/basic.dart';
export 'src/widgets/container.dart';
export 'src/widgets/framework.dart';
''');

    libFolder
        .getChildAssumingFolder('src')
        .getChildAssumingFolder('widgets')
        .getChildAssumingFile('basic.dart')
        .writeAsStringSync(r'''
import 'package:flutter/foundation.dart';
import 'framework.dart';

class Column implements Widget {
  Column({
    Key? key,
    List<Widget> children = const <Widget>[],
  });
}

class RawMaterialButton implements Widget {
  RawMaterialButton({
    Key? key,
    Widget? child,
    void Function()? onPressed,
  });
}

class SizedBox implements Widget {
  SizedBox({
    Key? key,
    double height = 0,
    double width = 0,
    Widget? child,
  });
}

class Text implements Widget {
  Text(String data);
}
''');

    libFolder
        .getChildAssumingFolder('src')
        .getChildAssumingFolder('widgets')
        .getChildAssumingFile('container.dart')
        .writeAsStringSync(r'''
import 'framework.dart';

// This is found in dart:ui.
class Color {
  Color(int value);
}

class Container extends StatelessWidget {
  const Container({
    super.key,
    Color? color,
    Decoration? decoration,
    double? width,
    double? height,
    Widget? child,
  });
}

class Decoration with Diagnosticable {}

class BoxDecoration implements Decoration {}

class Row implements Widget {}
''');

    libFolder
        .getChildAssumingFolder('src')
        .getChildAssumingFolder('widgets')
        .getChildAssumingFile('framework.dart')
        .writeAsStringSync(r'''
import 'package:flutter/foundation.dart';

abstract class BuildContext {
  Widget get widget;
  bool get mounted;
}

class Navigator {
  static NavigatorState of(
      BuildContext context, {bool rootNavigator = false}) => NavigatorState();
}

class NavigatorState {}

abstract class StatefulWidget extends Widget {
  const StatefulWidget({super.key});

  State<StatefulWidget> createState();
}

class State<T extends StatefulWidget> {}

abstract class Widget {
  final Key? key;

  const Widget({thi.key});
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget({super.key});

  @protected
  Widget build(BuildContext context);
}
''');
  }
}

class PubspecYamlFileConfig {
  final String? name;
  final String? sdkVersion;
  final List<PubspecYamlFileDependency> dependencies;

  PubspecYamlFileConfig({
    this.name,
    this.sdkVersion,
    this.dependencies = const [],
  });

  String toContent() {
    var buffer = StringBuffer();

    if (name != null) {
      buffer.writeln('name: $name');
    }

    if (sdkVersion != null) {
      buffer.writeln('environment:');
      buffer.writeln("  sdk: '$sdkVersion'");
    }

    if (dependencies.isNotEmpty) {
      buffer.writeln('dependencies:');
      for (var dependency in dependencies) {
        buffer.writeln('  ${dependency.name}: ${dependency.version}');
      }
    }

    return buffer.toString();
  }
}

class PubspecYamlFileDependency {
  final String name;
  final String version;

  PubspecYamlFileDependency({
    required this.name,
    this.version = 'any',
  });
}

abstract class _ContextResolutionTest with ResourceProviderMixin {
  static bool _lintRulesAreRegistered = false;

  final ByteStore _byteStore = MemoryByteStore();

  AnalysisContextCollectionImpl? _analysisContextCollection;

  late ResolvedUnitResult result;

  List<String> get collectionIncludedPaths;

  /// The analysis errors that were computed during analysis.
  List<AnalysisError> get errors => result.errors
      .whereNot((e) => ignoredErrorCodes.any((c) => e.errorCode == c))
      .toList();

  /// Error codes that by default should be ignored in test expectations.
  List<AnalyzerErrorCode> get ignoredErrorCodes =>
      [WarningCode.UNUSED_LOCAL_VARIABLE];

  Folder get sdkRoot => newFolder('/sdk');

  String get testFilePath => '/test/lib/test.dart';

  void addTestFile(String content) {
    newFile2(testFilePath, content);
  }

  @override
  File newFile2(String path, String content) {
    if (_analysisContextCollection != null && !path.endsWith('.dart')) {
      throw StateError('Only dart files can be changed after analysis.');
    }

    return super.newFile(path, content);
  }

  /// Resolves a Dart source file at [path].
  ///
  /// [path] must be converted for this file system.
  Future<ResolvedUnitResult> resolveFile(String path) async {
    var analysisContext = _contextFor(path);
    var session = analysisContext.currentSession;
    return await session.getResolvedUnit(path) as ResolvedUnitResult;
  }

  Future<void> resolveTestFile() => _resolveFile(testFilePath);

  @mustCallSuper
  void setUp() {
    if (!_lintRulesAreRegistered) {
      registerLintRules();
      _lintRulesAreRegistered = true;
    }

    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );
  }

  DriverBasedAnalysisContext _contextFor(String path) {
    _createAnalysisContexts();

    var convertedPath = convertPath(path);
    return _analysisContextCollection!.contextFor(convertedPath);
  }

  /// Create all analysis contexts in [collectionIncludedPaths].
  void _createAnalysisContexts() {
    if (_analysisContextCollection != null) {
      return;
    }

    _analysisContextCollection = AnalysisContextCollectionImpl(
      byteStore: _byteStore,
      declaredVariables: {},
      enableIndex: true,
      includedPaths: collectionIncludedPaths.map(convertPath).toList(),
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
    );
  }

  /// Resolve the file with the [path] into [result].
  Future<void> _resolveFile(String path) async {
    var convertedPath = convertPath(path);

    result = await resolveFile(convertedPath);
  }
}
