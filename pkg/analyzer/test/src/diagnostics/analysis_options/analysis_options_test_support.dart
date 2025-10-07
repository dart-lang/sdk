// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/analysis_options/options_file_validator.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/lint_registration_mixin.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../../generated/test_support.dart';

abstract class AbstractAnalysisOptionsTest
    with ResourceProviderMixin, LintRegistrationMixin {
  late SourceFactory sourceFactory;
  Map<String, String>? dependencies;

  late File analysisOptionsFile = newFile(analysisOptionsPath, '');
  late String analysisOptionsPath = convertPath('/analysis_options.yaml');
  VersionConstraint? get sdkVersionConstraint => null;

  Future<void> assertErrorsInCode(
    String code,
    List<ExpectedError> expectedErrors,
  ) async {
    analysisOptionsFile.writeAsStringSync(code);
    var diagnostics = analyzeAnalysisOptions(
      TestSource(analysisOptionsPath),
      code,
      sourceFactory,
      '/',
      sdkVersionConstraint,
      resourceProvider,
    );
    var diagnosticListener = GatheringDiagnosticListener();
    diagnosticListener.addAll(diagnostics);
    diagnosticListener.assertErrors(expectedErrors);
  }

  Future<void> assertNoErrorsInCode(String code) async =>
      await assertErrorsInCode(code, const []);

  ExpectedError error(
    DiagnosticCode code,
    int offset,
    int length, {
    Pattern? correctionContains,
    String? text,
    List<Pattern> messageContains = const [],
    List<ExpectedContextMessage> contextMessages =
        const <ExpectedContextMessage>[],
  }) => ExpectedError(
    code,
    offset,
    length,
    correctionContains: correctionContains,
    message: text,
    messageContains: messageContains,
    expectedContextMessages: contextMessages,
  );

  void setUp() {
    var resolvers = [
      ResourceUriResolver(resourceProvider),
      if (dependencies != null)
        PackageMapUriResolver(resourceProvider, {
          for (var entry in dependencies!.entries)
            entry.key: [getFolder(convertPath(entry.value))],
        }),
    ];
    sourceFactory = SourceFactoryImpl(resolvers);
  }

  @mustCallSuper
  void tearDown() {
    unregisterLintRules();
  }
}
