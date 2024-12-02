// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/error/codes.dart';
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

  // TODO(srawlins): Add tests that exercise
  // `optionsProvider.getOptionsFromString` throwing an exception.
  AnalysisOptionsImpl parseOptions(String content) =>
      AnalysisOptionsImpl.fromYaml(
        optionsMap: optionsProvider.getOptionsFromString(content),
        file: resourceProvider.getFile(resourceProvider.convertPath(
            '/project/analysis_options.yaml')),
        resourceProvider: resourceProvider,
      );

  test_analyzer_cannotIgnore() {
    var analysisOptions = parseOptions('''
analyzer:
  cannot-ignore:
    - one_error_code
    - another
''');

    var unignorableNames = analysisOptions.unignorableNames;
    expect(unignorableNames, unorderedEquals(['ONE_ERROR_CODE', 'ANOTHER']));
  }

  test_analyzer_cannotIgnore_severity() {
    var analysisOptions = parseOptions('''
analyzer:
  cannot-ignore:
    - error
''');

    var unignorableNames = analysisOptions.unignorableNames;
    expect(unignorableNames, contains('INVALID_ANNOTATION'));
    expect(unignorableNames.length, greaterThan(500));
  }

  test_analyzer_cannotIgnore_severity_withProcessor() {
    var analysisOptions = parseOptions('''
analyzer:
  errors:
    unused_import: error
  cannot-ignore:
    - error
''');

    var unignorableNames = analysisOptions.unignorableNames;
    expect(unignorableNames, contains('UNUSED_IMPORT'));
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

    var warning = AnalysisError.tmp(
      source: TestSource(),
      offset: 0,
      length: 1,
      errorCode: WarningCode.RETURN_TYPE_INVALID_FOR_CATCH_ERROR,
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

    var warning = AnalysisError.tmp(
      source: TestSource(),
      offset: 0,
      length: 1,
      errorCode: WarningCode.UNUSED_LOCAL_VARIABLE,
      arguments: [
        ['x'],
      ],
    );

    var processor = processors.first;
    expect(processor.appliesTo(warning), isTrue);
    expect(processor.severity, ErrorSeverity.ERROR);
  }

  test_analyzer_errors_severityIsIgnore() {
    var analysisOptions = parseOptions('''
analyzer:
  errors:
    invalid_assignment: ignore
''');

    var processors = analysisOptions.errorProcessors;
    expect(processors, hasLength(1));

    var error = AnalysisError.tmp(
      source: TestSource(),
      offset: 0,
      length: 1,
      errorCode: CompileTimeErrorCode.INVALID_ASSIGNMENT,
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

    var warning = AnalysisError.tmp(
      source: TestSource(),
      offset: 0,
      length: 1,
      errorCode: WarningCode.RETURN_TYPE_INVALID_FOR_CATCH_ERROR,
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

  test_analyzer_plugins_pathConstraint() {
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

  test_analyzer_plugins_pathConstraint_relative() {
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
    path: ${resourceProvider.convertPath('/project/foo/bar')}
''',
      ),
    );
  }

  test_analyzer_plugins_pathConstraint_relativeNonNormal() {
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
    path: ${resourceProvider.convertPath('/foo/baz')}
''',
      ),
    );
  }

  test_analyzer_plugins_scalarConstraint() {
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

  test_analyzer_plugins_versionConstraint() {
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
}
