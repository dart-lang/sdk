// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer_utilities/message_examples.dart';
import 'package:analyzer_utilities/messages.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'src/dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VerifySharedMessageExamplesTest);
  });
}

/// Verifies that the analyzer reports the expected diagnostic for each of the
/// examples in `pkg/_fe_analyzer_shared/messages.yaml`.
///
/// These are the same examples that the front end checks in
/// `pkg/front_end/test/messages_suite.dart`, and they're checked in a similar
/// way: each example must cause the diagnostic to be reported exactly once
/// (unless `exampleAllowMultipleReports` is set), and must not cause any other
/// errors to be reported (unless `exampleAllowOtherCodes` is set). Unlike the
/// front end, diagnostics that aren't errors (such as warnings and lints) are
/// ignored, unless they're the diagnostic being tested.
@reflectiveTest
class VerifySharedMessageExamplesTest {
  /// Examples that cause an assertion failure in the analyzer, mapped to the
  /// reason why.
  ///
  /// Keys have the same form as in [knownFailures].
  ///
  /// When assertions are enabled, these examples are treated like the ones in
  /// [knownFailures]. When assertions are disabled, they're expected to pass.
  static const Map<String, String> knownAssertionFailures = {};

  /// Examples that are known not to work with the analyzer, mapped to the
  /// reason why.
  ///
  /// Keys are of the form `<messageName>/<exampleName>`, where
  /// `<messageName>` is the key of the message in `messages.yaml`, and
  /// `<exampleName>` is the name of the example (e.g. `script` or
  /// `script2`).
  ///
  /// If an example listed here starts working, the test fails, so that the
  /// entry can be removed.
  static const Map<String, String> knownFailures = {
    'constAndFinal/declaration3':
        'Parser recovery reports missing_identifier instead (the CFE has '
        'the same problem)',
    'constAndFinal/declaration4':
        'Parser recovery reports missing_identifier instead (the CFE has '
        'the same problem)',
    'constructorWithTypeArguments/script1':
        'Analyzer reports wrong_number_of_type_arguments_constructor instead',
    'constructorWithTypeArguments/script2':
        'Analyzer reports wrong_number_of_type_arguments_constructor instead',
    'constructorWithWrongName/script2':
        'Analyzer reports invalid_factory_name_not_a_class instead',
    'constructorWithWrongName/script3':
        'Analyzer reports invalid_factory_name_not_a_class instead',
    'expectedAnInitializer/script1':
        'Analyzer also reports initializer_for_non_existent_field',
    'expectedStatement/statement':
        'Analyzer reports missing_identifier instead',
    'experimentNotEnabledOffByDefault/script':
        'Analyzer reports experiment_not_enabled instead',
    'extensionAugmentationHasOnClause/script':
        'Analyzer parses `augment` as a type name (the CFE has the same '
        'problem)',
    'externalMethodWithBody/script2': 'Analyzer reports nothing',
    'externalMethodWithBody/script3': 'Analyzer reports nothing',
    'illegalAssignmentToNonAssignable/script1':
        'Analyzer also reports undefined_function',
    'initializingDeclaringParameter/script':
        'Analyzer also reports initializing_formal_for_non_existent_field',
    'invalidInitializer/script': 'Analyzer reports nothing',
    'metadataTypeArguments/script':
        'Analyzer reports experiment_not_enabled instead',
    'metadataTypeArgumentsUninstantiated/script1':
        'Analyzer also reports disallowed_type_instantiation_expression',
    'missingAssignableSelector/script1':
        'Analyzer also reports undefined_function',
    'missingPrimaryConstructor/script':
        'Analyzer also reports expected_representation_field',
    'missingPrimaryConstructorParameters/script':
        'Analyzer also reports expected_representation_field',
    'partOfTwice/script1': 'Analyzer also reports part_of_different_library',
    'typeArgumentsOnTypeVariable/script1':
        'Analyzer reports wrong_number_of_type_arguments instead',
  };

  @TestTimeout(Timeout.factor(4))
  test_examples() async {
    var assertionsEnabled = false;
    assert(assertionsEnabled = true);
    var problems = <String>[];
    var knownFailuresSeen = <String>{};
    for (var message in feAnalyzerSharedMessages) {
      if (message.isRemoved) continue;
      var expectedCode =
          (message.sharedName ?? message.analyzerCode).snakeCaseName;
      for (var example in message.examples) {
        // TODO(paulberry): consider supporting `bytes` examples.
        if (example is! SourceExample) continue;
        var id = '${message.keyString}/${example.name}';
        var problem = await _checkExample(message, example, expectedCode);
        var isKnownAssertionFailure = knownAssertionFailures.containsKey(id);
        if (knownFailures.containsKey(id) || isKnownAssertionFailure) {
          knownFailuresSeen.add(id);
        }
        if (knownFailures.containsKey(id) ||
            (isKnownAssertionFailure && assertionsEnabled)) {
          if (problem == null) {
            problems.add(
              '$id: passes, but is listed as a known failure. Please remove '
              'it from the list.',
            );
          }
        } else if (problem != null) {
          problems.add('$id: $problem');
        }
      }
    }
    for (var id in [...knownFailures.keys, ...knownAssertionFailures.keys]) {
      if (!knownFailuresSeen.contains(id)) {
        problems.add(
          '$id: listed as a known failure, but no such example exists. Please '
          'remove it from the list.',
        );
      }
    }
    if (problems.isNotEmpty) {
      fail(problems.join('\n\n'));
    }
  }

  /// Analyzes the given [files] (a map from file name to contents) with the
  /// given [experimentalFeatures] enabled, and returns all the diagnostics
  /// that are reported.
  Future<List<Diagnostic>> _analyze(
    Map<String, String> files, {
    required List<Feature> experimentalFeatures,
  }) async {
    var test = _ExampleTest(experimentalFeatures);
    test.setUp();
    try {
      var diagnostics = <Diagnostic>[];
      for (var MapEntry(key: fileName, value: content) in files.entries) {
        test.newFile('${test.testPackageLibPath}/$fileName', content);
      }
      for (var fileName in files.keys) {
        var result = await test.resolveFile2(
          test.getFile('${test.testPackageLibPath}/$fileName'),
        );
        diagnostics.addAll(result.diagnostics);
      }
      return diagnostics;
    } finally {
      await test.tearDown();
    }
  }

  /// Analyzes [example] and checks that it produces the diagnostic named
  /// [expectedCode], subject to the options specified in [message].
  ///
  /// Returns `null` if the example behaves as expected; otherwise returns a
  /// description of the problem. An exception thrown during analysis
  /// (including an assertion failure) is treated as a problem.
  Future<String?> _checkExample(
    SharedMessage message,
    SourceExample example,
    String expectedCode,
  ) async {
    List<Diagnostic> diagnostics;
    try {
      diagnostics = await _analyze(
        example.files,
        experimentalFeatures: [
          for (var experiment in message.experiments)
            if (ExperimentStatus.knownFeatures[experiment] case var feature?
                when !feature.isEnabledByDefault)
              feature,
        ],
      );
    } catch (e, stackTrace) {
      // Report the exception (which may be an assertion failure) as a problem
      // with this example, so that the other examples are still checked.
      return 'Exception during analysis: $e\n$stackTrace';
    }
    var expected = <Diagnostic>[];
    var unexpected = <Diagnostic>[];
    for (var diagnostic in diagnostics) {
      if (diagnostic.diagnosticCode.lowerCaseName == expectedCode) {
        expected.add(diagnostic);
      } else if (diagnostic.severity == Severity.error) {
        unexpected.add(diagnostic);
      }
    }
    if (message.exampleAllowOtherCodes) {
      unexpected.clear();
    }
    var expectedCount =
        message.exampleAllowMultipleReports && expected.isNotEmpty
        ? 1
        : expected.length;
    if (expectedCount == 1 && unexpected.isEmpty) {
      return null;
    }
    var description = switch ((expectedCount, unexpected.isEmpty)) {
      (0, true) => 'No diagnostic reported',
      (0, false) => 'Got only unrelated errors',
      (1, false) =>
        'Got the expected diagnostic, but also other errors. Maybe add '
            '`exampleAllowOtherCodes: true`.',
      (_, true) =>
        'Expected diagnostic reported multiple times. Maybe add '
            '`exampleAllowMultipleReports: true`.',
      (_, false) =>
        'Expected diagnostic reported multiple times, and also other errors.',
    };
    var buffer = StringBuffer('$description (expected $expectedCode).');
    for (var diagnostic in [...expected, ...unexpected]) {
      buffer.write(
        '\n  ${diagnostic.diagnosticCode.lowerCaseName} '
        '(${diagnostic.source.shortName}:${diagnostic.offset}): '
        '${diagnostic.message}',
      );
    }
    return buffer.toString();
  }
}

/// A test class that creates an environment suitable for analyzing a single
/// example.
class _ExampleTest extends PubPackageResolutionTest {
  @override
  final List<Feature> experimentalFeatures;

  new(this.experimentalFeatures);
}
