// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/utilities/extensions/resource_provider.dart';
import 'package:collection/collection.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisOptionsTest);
  });
}

@reflectiveTest
class AnalysisOptionsTest {
  final AnalysisOptionsProvider optionsProvider = AnalysisOptionsProvider();

  final resourceProvider = MemoryResourceProvider();

  String convertPath(String filePath) =>
      ResourceProviderExtension(resourceProvider).convertPath(filePath);

  // TODO(srawlins): Add tests that exercise
  // `optionsProvider.getOptionsFromString` throwing an exception.
  AnalysisOptionsImpl parseOptions(String content) =>
      AnalysisOptionsImpl.fromYaml(
        optionsMap: optionsProvider.getOptionsFromString(content),
        file: resourceProvider.getFile(
          convertPath('/project/analysis_options.yaml'),
        ),
        resourceProvider: resourceProvider,
      );

  test_analyzer_cannotIgnore() {
    var analysisOptions = parseOptions('''
analyzer:
  cannot-ignore:
    - one_error_code
    - another
''');

    var unignorableCodeNames = analysisOptions.unignorableDiagnosticCodeNames;
    expect(
      unignorableCodeNames,
      unorderedEquals(['ONE_ERROR_CODE', 'ANOTHER']),
    );
  }

  test_analyzer_cannotIgnore_severity() {
    var analysisOptions = parseOptions('''
analyzer:
  cannot-ignore:
    - error
''');

    var unignorableCodeNames = analysisOptions.unignorableDiagnosticCodeNames;
    expect(unignorableCodeNames, contains('INVALID_ANNOTATION'));
    expect(unignorableCodeNames.length, greaterThan(500));
  }

  test_analyzer_cannotIgnore_severity_withProcessor() {
    var analysisOptions = parseOptions('''
analyzer:
  errors:
    unused_import: error
  cannot-ignore:
    - error
''');

    var unignorableCodeNames = analysisOptions.unignorableDiagnosticCodeNames;
    expect(unignorableCodeNames, contains('UNUSED_IMPORT'));
  }

  test_analyzer_chromeos_checks() {
    var analysisOptions = parseOptions('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks
''');
    expect(analysisOptions.chromeOsManifestChecks, true);
  }

  test_analyzer_chromeos_checks_map() {
    var analysisOptions = parseOptions('''
analyzer:
  optional-checks:
    chrome-os-manifest-checks : true
''');
    expect(analysisOptions.chromeOsManifestChecks, true);
  }

  test_analyzer_errors_cannotBeIgnoredByUniqueName() {
    var analysisOptions = parseOptions('''
analyzer:
  errors:
    return_type_invalid_for_catch_error: ignore
''');

    var processors = analysisOptions.errorProcessors;
    expect(processors, hasLength(1));

    var warning = Diagnostic.tmp(
      source: TestSource(),
      offset: 0,
      length: 1,
      diagnosticCode: WarningCode.returnTypeInvalidForCatchError,
      arguments: [
        ['x'],
        ['y'],
      ],
    );

    var processor = processors.first;
    expect(processor.appliesTo(warning), isFalse);
  }

  test_analyzer_errors_severityIsError() {
    var analysisOptions = parseOptions('''
analyzer:
  errors:
    unused_local_variable: error
''');

    var processors = analysisOptions.errorProcessors;
    expect(processors, hasLength(1));

    var warning = Diagnostic.tmp(
      source: TestSource(),
      offset: 0,
      length: 1,
      diagnosticCode: WarningCode.unusedLocalVariable,
      arguments: [
        ['x'],
      ],
    );

    var processor = processors.first;
    expect(processor.appliesTo(warning), isTrue);
    expect(processor.severity, DiagnosticSeverity.ERROR);
  }

  test_analyzer_errors_severityIsIgnore() {
    var analysisOptions = parseOptions('''
analyzer:
  errors:
    invalid_assignment: ignore
''');

    var processors = analysisOptions.errorProcessors;
    expect(processors, hasLength(1));

    var error = Diagnostic.tmp(
      source: TestSource(),
      offset: 0,
      length: 1,
      diagnosticCode: CompileTimeErrorCode.invalidAssignment,
      arguments: [
        ['x'],
        ['y'],
      ],
    );

    var processor = processors.first;
    expect(processor.appliesTo(error), isTrue);
    expect(processor.severity, isNull);
  }

  test_analyzer_errors_sharedNameAppliesToAllSharedCodes() {
    var analysisOptions = parseOptions('''
analyzer:
  errors:
    invalid_return_type_for_catch_error: ignore
''');

    var processors = analysisOptions.errorProcessors;
    expect(processors, hasLength(1));

    var warning = Diagnostic.tmp(
      source: TestSource(),
      offset: 0,
      length: 1,
      diagnosticCode: WarningCode.returnTypeInvalidForCatchError,
      arguments: [
        ['x'],
        ['y'],
      ],
    );

    var processor = processors.first;
    expect(processor.appliesTo(warning), isTrue);
    expect(processor.severity, isNull);
  }

  test_analyzer_exclude() {
    var analysisOptions = parseOptions('''
analyzer:
  exclude:
    - foo/bar.dart
    - 'test/**'
''');

    var excludes = analysisOptions.excludePatterns;
    expect(excludes, unorderedEquals(['foo/bar.dart', 'test/**']));
  }

  test_analyzer_exclude_withNonStrings() {
    var analysisOptions = parseOptions('''
analyzer:
  exclude:
    - foo/bar.dart
    - 'test/**'
    - a: b
''');

    var excludes = analysisOptions.excludePatterns;
    expect(excludes, unorderedEquals(['foo/bar.dart', 'test/**']));
  }

  test_analyzer_legacyPlugins_list() {
    // TODO(srawlins): Test legacy plugins as a list of non-scalar values
    // (`- angular2: yes`).
    var analysisOptions = parseOptions('''
analyzer:
  plugins:
    - angular2
    - intl
''');

    var names = analysisOptions.enabledLegacyPluginNames;
    expect(names, ['angular2']);
  }

  test_analyzer_legacyPlugins_map() {
    // TODO(srawlins): Test legacy plugins as a map of scalar values
    // (`angular2: yes`).
    var analysisOptions = parseOptions('''
analyzer:
  plugins:
    angular2:
      enabled: true
''');

    var names = analysisOptions.enabledLegacyPluginNames;
    expect(names, ['angular2']);
  }

  test_analyzer_legacyPlugins_string() {
    var analysisOptions = parseOptions('''
analyzer:
  plugins:
    angular2
''');

    var names = analysisOptions.enabledLegacyPluginNames;
    expect(names, ['angular2']);
  }

  test_analyzer_optionalChecks_propagateLinterExceptions_default() {
    var analysisOptions = parseOptions('''
analyzer:
  optional-checks:
''');
    expect(analysisOptions.propagateLinterExceptions, false);
  }

  test_analyzer_optionalChecks_propagateLinterExceptions_empty() {
    var analysisOptions = parseOptions('''
analyzer:
  optional-checks:
    propagate-linter-exceptions
''');
    expect(analysisOptions.propagateLinterExceptions, true);
  }

  test_analyzer_optionalChecks_propagateLinterExceptions_false() {
    var analysisOptions = parseOptions('''
analyzer:
  optional-checks:
    propagate-linter-exceptions: false
''');
    expect(analysisOptions.propagateLinterExceptions, false);
  }

  test_analyzer_optionalChecks_propagateLinterExceptions_true() {
    var analysisOptions = parseOptions('''
analyzer:
  optional-checks:
    propagate-linter-exceptions: true
''');
    expect(analysisOptions.propagateLinterExceptions, true);
  }

  test_codeStyle_format_false() {
    var analysisOptions = parseOptions('''
code-style:
  format: false
''');
    expect(analysisOptions.codeStyleOptions.useFormatter, false);
  }

  test_codeStyle_format_true() {
    var analysisOptions = parseOptions('''
code-style:
  format: true
''');
    expect(analysisOptions.codeStyleOptions.useFormatter, true);
  }

  test_plugins_dependency_overrides_relative() {
    var analysisOptions = parseOptions('''
plugins:
  plugin_one:
    path: foo/bar
  dependency_overrides:
    some_package1:
      path: ../some_package1
    some_package2:
      path: sub_folder/some_package2
''');

    var dependencyOverrides =
        analysisOptions.pluginsOptions.dependencyOverrides;
    expect(dependencyOverrides, isNotNull);
    expect(dependencyOverrides, hasLength(2));
    var package1 = dependencyOverrides!.entries.singleWhereOrNull(
      (entry) => entry.key == 'some_package1',
    );
    var package2 = dependencyOverrides.entries.singleWhereOrNull(
      (entry) => entry.key == 'some_package2',
    );
    expect(package1, isNotNull);
    expect(package1!.key, 'some_package1');
    expect(
      package1.value,
      isA<PathPluginSource>().having(
        (e) => e.toYaml(name: 'some_package1'),
        'toYaml',
        '''
  some_package1:
    path: ${convertPath('/some_package1')}
''',
      ),
    );
    expect(package2, isNotNull);
    expect(package2!.key, 'some_package2');
    expect(
      package2.value,
      isA<PathPluginSource>().having(
        (e) => e.toYaml(name: 'some_package2'),
        'toYaml',
        '''
  some_package2:
    path: ${convertPath('/project/sub_folder/some_package2')}
''',
      ),
    );
  }

  test_plugins_pathConstraint() {
    var analysisOptions = parseOptions('''
plugins:
  plugin_one:
    path: /foo/bar
''');

    var configuration = analysisOptions.pluginConfigurations.single;
    expect(configuration.isEnabled, isTrue);
    expect(configuration.name, 'plugin_one');
    expect(
      configuration.source,
      isA<PathPluginSource>().having(
        (e) => e.toYaml(name: 'plugin_one'),
        'toYaml',
        '''
  plugin_one:
    path: /foo/bar
''',
      ),
    );
  }

  test_plugins_pathConstraint_relative() {
    var analysisOptions = parseOptions('''
plugins:
  plugin_one:
    path: foo/bar
''');

    var configuration = analysisOptions.pluginConfigurations.single;
    expect(configuration.isEnabled, isTrue);
    expect(configuration.name, 'plugin_one');
    expect(
      configuration.source,
      isA<PathPluginSource>().having(
        (e) => e.toYaml(name: 'plugin_one'),
        'toYaml',
        '''
  plugin_one:
    path: ${convertPath('/project/foo/bar')}
''',
      ),
    );
  }

  test_plugins_pathConstraint_relativeNonNormal() {
    var analysisOptions = parseOptions('''
plugins:
  plugin_one:
    path: .././foo/bar/../baz
''');

    var configuration = analysisOptions.pluginConfigurations.single;
    expect(configuration.isEnabled, isTrue);
    expect(configuration.name, 'plugin_one');
    expect(
      configuration.source,
      isA<PathPluginSource>().having(
        (e) => e.toYaml(name: 'plugin_one'),
        'toYaml',
        '''
  plugin_one:
    path: ${convertPath('/foo/baz')}
''',
      ),
    );
  }

  test_plugins_scalarConstraint() {
    var analysisOptions = parseOptions('''
plugins:
  plugin_one: ^1.2.3
''');

    var configuration = analysisOptions.pluginConfigurations.single;
    expect(configuration.isEnabled, isTrue);
    expect(configuration.name, 'plugin_one');
    expect(
      configuration.source,
      isA<VersionedPluginSource>().having(
        (e) => e.toYaml(name: 'plugin_one'),
        'toYaml',
        '  plugin_one: ^1.2.3\n',
      ),
    );
  }

  test_plugins_versionConstraint() {
    var analysisOptions = parseOptions('''
plugins:
  plugin_one:
    version: ^1.2.3
''');

    var configuration = analysisOptions.pluginConfigurations.single;
    expect(configuration.isEnabled, isTrue);
    expect(configuration.name, 'plugin_one');
    expect(
      configuration.source,
      isA<VersionedPluginSource>().having(
        (e) => e.toYaml(name: 'plugin_one'),
        'toYaml',
        '  plugin_one: ^1.2.3\n',
      ),
    );
  }

  test_signature_on_different_error_ordering() {
    var options = parseOptions('''
analyzer:
  errors:
    a: warning
    b: ignore
    c: ignore
''');
    var sig1 = options.signature;
    for (var i = 0; i < 10; i++) {
      var options2 = parseOptions('''
analyzer:
  errors:
    b: ignore
    a: warning
    c: ignore
''');
      var sig2 = options2.signature;
      expect(sig1, sig2);
    }
  }

  test_signature_on_different_lints_ordering() {
    registerLintRules();
    var knownRules = Registry.ruleRegistry.rules
        .map((rule) => "    - ${rule.name}")
        .toList(growable: false);
    var options = parseOptions('''
linter:
  rules:
${knownRules.reversed.join("\n")}
''');
    var sig1 = options.signature;
    for (var i = 0; i < 10; i++) {
      knownRules.shuffle();
      var options2 = parseOptions('''
linter:
  rules:
${knownRules.join("\n")}
''');
      var sig2 = options2.signature;
      expect(sig1, sig2);
    }
  }

  test_signature_on_different_plugin_ordering() {
    var options = parseOptions('''
plugins:
  plugin_one: ^1.2.3
  plugin_two: ^1.2.3
  plugin_three: ^1.2.3
''');
    var sig1 = options.signature;
    for (var i = 0; i < 10; i++) {
      var options2 = parseOptions('''
plugins:
  plugin_three: ^1.2.3
  plugin_one: ^1.2.3
  plugin_two: ^1.2.3
''');
      var sig2 = options2.signature;
      expect(sig1, sig2);
    }
  }

  test_signature_on_merge() {
    var sourceFactory = SourceFactory([ResourceUriResolver(resourceProvider)]);
    var optionsProvider = AnalysisOptionsProvider(sourceFactory);
    var otherOptions = resourceProvider.getFile(
      convertPath("/project/analysis_options_helper.yaml"),
    );
    otherOptions.writeAsStringSync('''
analyzer:
  errors:
    a: warning
    b: ignore
    c: ignore
''');
    var mainOptions = resourceProvider.getFile(
      convertPath("/project/analysis_options.yaml"),
    );
    mainOptions.writeAsStringSync('''
include: analysis_options_helper.yaml
analyzer:
  errors:
    d: ignore
''');

    var options = AnalysisOptionsImpl.fromYaml(
      optionsMap: optionsProvider.getOptionsFromFile(mainOptions),
      file: mainOptions,
      resourceProvider: resourceProvider,
    );
    var sig1 = options.signature;
    for (var i = 0; i < 100; i++) {
      var options2 = AnalysisOptionsImpl.fromYaml(
        optionsMap: optionsProvider.getOptionsFromFile(mainOptions),
        file: mainOptions,
        resourceProvider: resourceProvider,
      );
      var sig2 = options2.signature;
      expect(sig1, sig2);
    }
  }
}
