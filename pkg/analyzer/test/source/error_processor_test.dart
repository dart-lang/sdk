// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.source.error_processor;

import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:plugin/manager.dart';
import 'package:plugin/plugin.dart';
import 'package:test/test.dart';
import 'package:yaml/src/yaml_node.dart';

import '../generated/test_support.dart';

main() {
  AnalysisError invalid_assignment =
      new AnalysisError(new TestSource(), 0, 1, HintCode.INVALID_ASSIGNMENT, [
    ['x'],
    ['y']
  ]);

  AnalysisError missing_return =
      new AnalysisError(new TestSource(), 0, 1, HintCode.MISSING_RETURN, [
    ['x']
  ]);

  AnalysisError unused_local_variable = new AnalysisError(
      new TestSource(), 0, 1, HintCode.UNUSED_LOCAL_VARIABLE, [
    ['x']
  ]);

  AnalysisError use_of_void_result =
      new AnalysisError(new TestSource(), 0, 1, HintCode.USE_OF_VOID_RESULT, [
    ['x']
  ]);

  AnalysisError non_bool_operand = new AnalysisError(
      new TestSource(), 0, 1, StaticTypeWarningCode.NON_BOOL_OPERAND, [
    ['x']
  ]);

  // We in-line a lint code here in order to avoid adding a dependency on the
  // linter package.
  AnalysisError annotate_overrides = new AnalysisError(
      new TestSource(), 0, 1, new LintCode('annotate_overrides', ''));

  oneTimeSetup();

  setUp(() {
    context = new TestContext();
  });

  group('ErrorProcessor', () {
    test('configureOptions', () {
      configureOptions('''
analyzer:
  errors:
    invalid_assignment: error # severity ERROR
    missing_return: false # ignore
    unused_local_variable: true # skipped
    use_of_void_result: unsupported_action # skipped
''');
      expect(getProcessor(invalid_assignment).severity, ErrorSeverity.ERROR);
      expect(getProcessor(missing_return).severity, isNull);
      expect(getProcessor(unused_local_variable), isNull);
      expect(getProcessor(use_of_void_result), isNull);
    });

    test('upgrades static type warnings to errors in strong mode', () {
      configureOptions('''
analyzer:
  strong-mode: true
''');
      expect(getProcessor(non_bool_operand).severity, ErrorSeverity.ERROR);
    });

    test('does not upgrade other warnings to errors in strong mode', () {
      configureOptions('''
analyzer:
  strong-mode: true
''');
      expect(getProcessor(unused_local_variable), isNull);
    });
  });

  group('ErrorConfig', () {
    var config = '''
analyzer:
  errors:
    invalid_assignment: unsupported_action # should be skipped
    missing_return: false
    unused_local_variable: error
''';

    group('processing', () {
      test('yaml map', () {
        var options = optionsProvider.getOptionsFromString(config);
        var errorConfig =
            new ErrorConfig((options['analyzer'] as YamlMap)['errors']);
        expect(errorConfig.processors, hasLength(2));

        // ignore
        var missingReturnProcessor = errorConfig.processors
            .firstWhere((p) => p.appliesTo(missing_return));
        expect(missingReturnProcessor.severity, isNull);

        // error
        var unusedLocalProcessor = errorConfig.processors
            .firstWhere((p) => p.appliesTo(unused_local_variable));
        expect(unusedLocalProcessor.severity, ErrorSeverity.ERROR);

        // skip
        var invalidAssignmentProcessor = errorConfig.processors.firstWhere(
            (p) => p.appliesTo(invalid_assignment),
            orElse: () => null);
        expect(invalidAssignmentProcessor, isNull);
      });

      test('string map', () {
        var options = {
          'invalid_assignment': 'unsupported_action', // should be skipped
          'missing_return': 'false',
          'unused_local_variable': 'error'
        };
        var errorConfig = new ErrorConfig(options);
        expect(errorConfig.processors, hasLength(2));

        // ignore
        var missingReturnProcessor = errorConfig.processors
            .firstWhere((p) => p.appliesTo(missing_return));
        expect(missingReturnProcessor.severity, isNull);

        // error
        var unusedLocalProcessor = errorConfig.processors
            .firstWhere((p) => p.appliesTo(unused_local_variable));
        expect(unusedLocalProcessor.severity, ErrorSeverity.ERROR);

        // skip
        var invalidAssignmentProcessor = errorConfig.processors.firstWhere(
            (p) => p.appliesTo(invalid_assignment),
            orElse: () => null);
        expect(invalidAssignmentProcessor, isNull);
      });
    });

    test('configure lints', () {
      var options = optionsProvider.getOptionsFromString(
          'analyzer:\n  errors:\n    annotate_overrides: warning\n');
      var errorConfig =
          new ErrorConfig((options['analyzer'] as YamlMap)['errors']);
      expect(errorConfig.processors, hasLength(1));

      ErrorProcessor processor = errorConfig.processors.first;
      expect(processor.appliesTo(annotate_overrides), true);
      expect(processor.severity, ErrorSeverity.WARNING);
    });
  });
}

TestContext context;

AnalysisOptionsProvider optionsProvider = new AnalysisOptionsProvider();
ErrorProcessor processor;

void configureOptions(String options) {
  Map<String, YamlNode> optionMap =
      optionsProvider.getOptionsFromString(options);
  applyToAnalysisOptions(context.analysisOptions, optionMap);
}

ErrorProcessor getProcessor(AnalysisError error) =>
    ErrorProcessor.getProcessor(context.analysisOptions, error);

void oneTimeSetup() {
  List<Plugin> plugins = <Plugin>[];
  plugins.addAll(AnalysisEngine.instance.requiredPlugins);
  ExtensionManager manager = new ExtensionManager();
  manager.processPlugins(plugins);
}

class TestContext extends AnalysisContextImpl {}
