// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/analysis_options/options_file_validator.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/lint_registration_mixin.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:analyzer_testing/src/expected_diagnostics.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../../../util/diff.dart';
import '../../dart/resolution/node_text_expectations.dart';

abstract class AbstractAnalysisOptionsTest
    with
        ResourceProviderMixin,
        LintRegistrationMixin,
        AnalysisOptionsDiagnosticExpectationMixin {
  late SourceFactory sourceFactory;
  Map<String, String>? dependencies;

  late File analysisOptionsFile = getFile('/analysis_options.yaml');

  VersionConstraint? get sdkVersionConstraint => null;

  List<Diagnostic> assertAnalysisOptionsDiagnostics(String code) {
    return assertAnalysisOptionsDiagnosticsInFiles({analysisOptionsFile: code});
  }

  List<Diagnostic> assertAnalysisOptionsDiagnosticsInFiles(
    Map<File, String> codeByFile, {
    File? initialFile,
    VersionConstraint? sdkVersionConstraint,
  }) {
    initialFile ??= analysisOptionsFile;
    var cleanCodeByFile = writeFilesWithoutDiagnosticExpectations(codeByFile);
    var cleanContent = cleanCodeByFile[initialFile];
    if (cleanContent == null) {
      fail('Cannot validate ${initialFile.path}: no content was provided.');
    }

    var diagnostics = AnalysisOptionsAnalyzer(
      initialSource:
          sourceFactory.forUri2(initialFile.toUri()) ?? FileSource(initialFile),
      sourceFactory: sourceFactory,
      contextRoot: convertPath('/'),
      sdkVersionConstraint: sdkVersionConstraint ?? this.sdkVersionConstraint,
      resourceProvider: resourceProvider,
    ).walkIncludes(content: cleanContent);

    assertDiagnosticMarkersInFiles(
      codeByFile: codeByFile,
      diagnostics: diagnostics,
    );
    return diagnostics;
  }

  Future<void> assertDiagnosticsInCode(String code) async {
    assertAnalysisOptionsDiagnostics(code);
  }

  Future<void> assertDiagnosticsInFiles(Map<File, String> codeByFile) async {
    assertAnalysisOptionsDiagnosticsInFiles(codeByFile);
  }

  void setUp() {
    sourceFactory = _createSourceFactory(packageDependencies: dependencies);
  }

  @mustCallSuper
  void tearDown() {
    unregisterLintRules();
  }

  SourceFactory _createSourceFactory({
    Map<String, String>? packageDependencies,
  }) {
    var resolvers = [
      ResourceUriResolver(resourceProvider),
      if (packageDependencies != null)
        PackageMapUriResolver(resourceProvider, {
          for (var entry in packageDependencies.entries)
            entry.key: [getFolder(convertPath(entry.value))],
        }),
    ];
    return SourceFactoryImpl(resolvers);
  }
}

/// Shared inline diagnostic expectation checks for analysis-options tests.
///
/// These helpers only compare diagnostics with inline markers. The test
/// fixture remains responsible for choosing which analyzer or validator entry
/// point produces the diagnostics.
mixin AnalysisOptionsDiagnosticExpectationMixin {
  void assertDiagnosticMarkersInFiles({
    required Map<File, String> codeByFile,
    required List<Diagnostic> diagnostics,
  }) {
    var cleanCodeByFile = {
      for (var entry in codeByFile.entries)
        entry.key: removeDiagnosticExpectations(entry.value),
    };
    var actualCodeByFile = updateExpectedDiagnosticsForFiles(
      contentByFile: cleanCodeByFile,
      actualDiagnosticsByFile: _diagnosticsByFile(
        files: codeByFile.keys,
        diagnostics: diagnostics,
      ),
    );

    var hasMismatch = false;
    var index = 0;
    for (var entry in codeByFile.entries) {
      var actual = actualCodeByFile[entry.key]!;
      if (actual != entry.value) {
        NodeTextExpectationsCollector.add(actual, intraInvocationId: '$index');
        print('-------- ${entry.key.path} --------');
        printPrettyDiff(entry.value, actual);
        hasMismatch = true;
      }
      index++;
    }

    if (hasMismatch) {
      fail('See the difference above.');
    }
  }

  Map<File, String> writeFilesWithoutDiagnosticExpectations(
    Map<File, String> codeByFile,
  ) {
    var cleanCodeByFile = {
      for (var entry in codeByFile.entries)
        entry.key: removeDiagnosticExpectations(entry.value),
    };
    for (var entry in cleanCodeByFile.entries) {
      entry.key.writeAsStringSync(entry.value);
    }
    return cleanCodeByFile;
  }

  Map<File, List<Diagnostic>> _diagnosticsByFile({
    required Iterable<File> files,
    required List<Diagnostic> diagnostics,
  }) {
    var fileByPath = {for (var file in files) file.path: file};
    var diagnosticsByFile = {for (var file in files) file: <Diagnostic>[]};

    for (var diagnostic in diagnostics) {
      var filePath = diagnostic.problemMessage.filePath;
      var file = fileByPath[filePath];
      if (file == null) {
        fail(
          'Cannot generate diagnostic expectations for $filePath: '
          'no content was provided.',
        );
      }
      diagnosticsByFile[file]!.add(diagnostic);
    }

    return diagnosticsByFile;
  }
}
