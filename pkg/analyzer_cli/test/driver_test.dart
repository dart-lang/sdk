// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.test.driver;

import 'dart:io';

import 'package:analyzer/plugin/options.dart';
import 'package:analyzer/source/analysis_options_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/plugin/plugin_configuration.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer_cli/src/bootloader.dart';
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:path/path.dart' as path;
import 'package:plugin/plugin.dart';
import 'package:unittest/unittest.dart';
import 'package:yaml/src/yaml_node.dart';

// TODO(pq): fix tests to run safely on the bots
// https://github.com/dart-lang/sdk/issues/25001
main() {}
_main() {
  group('Driver', () {
    StringSink savedOutSink, savedErrorSink;
    int savedExitCode;
    setUp(() {
      savedOutSink = outSink;
      savedErrorSink = errorSink;
      savedExitCode = exitCode;
      outSink = new StringBuffer();
      errorSink = new StringBuffer();
    });
    tearDown(() {
      outSink = savedOutSink;
      errorSink = savedErrorSink;
      exitCode = savedExitCode;
    });

    group('options', () {
      test('custom processor', () {
        Driver driver = new Driver();
        TestProcessor processor = new TestProcessor();
        driver.userDefinedPlugins = [new TestPlugin(processor)];
        driver.start([
          '--options',
          'test/data/test_options.yaml',
          'test/data/test_file.dart'
        ]);
        expect(processor.options['test_plugin'], isNotNull);
        expect(processor.exception, isNull);
      });
    });

    group('exit codes', () {
      StringSink savedOutSink, savedErrorSink;
      int savedExitCode;
      ExitHandler savedExitHandler;
      setUp(() {
        savedOutSink = outSink;
        savedErrorSink = errorSink;
        savedExitCode = exitCode;
        savedExitHandler = exitHandler;
        exitHandler = (code) => exitCode = code;
        outSink = new StringBuffer();
        errorSink = new StringBuffer();
      });
      tearDown(() {
        outSink = savedOutSink;
        errorSink = savedErrorSink;
        exitCode = savedExitCode;
        exitHandler = savedExitHandler;
      });

      test('fatal hints', () {
        drive('test/data/file_with_hint.dart', args: ['--fatal-hints']);
        expect(exitCode, 3);
      });

      test('not fatal hints', () {
        drive('test/data/file_with_hint.dart');
        expect(exitCode, 0);
      });

      test('fatal errors', () {
        drive('test/data/file_with_error.dart');
        expect(exitCode, 3);
      });

      test('not fatal warnings', () {
        drive('test/data/file_with_warning.dart');
        expect(exitCode, 0);
      });

      test('fatal warnings', () {
        drive('test/data/file_with_warning.dart', args: ['--fatal-warnings']);
        expect(exitCode, 3);
      });

      test('missing options file', () {
        drive('test/data/test_file.dart', options: 'test/data/NO_OPTIONS_HERE');
        expect(exitCode, 3);
      });

      test('missing dart file', () {
        drive('test/data/NO_DART_FILE_HERE.dart');
        expect(exitCode, 3);
      });

      test('part file', () {
        drive('test/data/library_and_parts/part2.dart');
        expect(exitCode, 3);
      });

      test('non-dangling part file', () {
        Driver driver = new Driver();
        driver.start([
          'test/data/library_and_parts/lib.dart',
          'test/data/library_and_parts/part1.dart',
        ]);
        expect(exitCode, 0);
      });

      test('extra part file', () {
        Driver driver = new Driver();
        driver.start([
          'test/data/library_and_parts/lib.dart',
          'test/data/library_and_parts/part1.dart',
          'test/data/library_and_parts/part2.dart',
        ]);
        expect(exitCode, 3);
      });
    });

    group('linter', () {
      group('lints in options', () {
        StringSink savedOutSink;
        Driver driver;

        setUp(() {
          savedOutSink = outSink;
          outSink = new StringBuffer();

          driver = new Driver();
          driver.start([
            '--options',
            'test/data/linter_project/.analysis_options',
            '--lints',
            'test/data/linter_project/test_file.dart'
          ]);
        });
        tearDown(() {
          outSink = savedOutSink;
        });

        test('gets analysis options', () {
          /// Lints should be enabled.
          expect(driver.context.analysisOptions.lint, isTrue);

          /// The .analysis_options file only specifies 'camel_case_types'.
          var lintNames = getLints(driver.context).map((r) => r.name);
          expect(lintNames, orderedEquals(['camel_case_types']));
        });

        test('generates lints', () {
          expect(outSink.toString(),
              contains('[lint] Name types using UpperCamelCase.'));
        });
      });

      group('default lints', () {
        StringSink savedOutSink;
        Driver driver;

        setUp(() {
          savedOutSink = outSink;
          outSink = new StringBuffer();

          driver = new Driver();
          driver.start([
            '--lints',
            'test/data/linter_project/test_file.dart',
            '--options',
            'test/data/linter_project/.analysis_options'
          ]);
        });
        tearDown(() {
          outSink = savedOutSink;
        });

        test('gets default lints', () {
          /// Lints should be enabled.
          expect(driver.context.analysisOptions.lint, isTrue);

          /// Default list should include camel_case_types.
          var lintNames = getLints(driver.context).map((r) => r.name);
          expect(lintNames, contains('camel_case_types'));
        });

        test('generates lints', () {
          expect(outSink.toString(),
              contains('[lint] Name types using UpperCamelCase.'));
        });
      });

      group('no `--lints` flag (none in options)', () {
        StringSink savedOutSink;
        Driver driver;

        setUp(() {
          savedOutSink = outSink;
          outSink = new StringBuffer();

          driver = new Driver();
          driver.start([
            'test/data/no_lints_project/test_file.dart',
            '--options',
            'test/data/no_lints_project/.analysis_options'
          ]);
        });
        tearDown(() {
          outSink = savedOutSink;
        });

        test('lints disabled', () {
          expect(driver.context.analysisOptions.lint, isFalse);
        });

        test('no registered lints', () {
          expect(getLints(driver.context), isEmpty);
        });

        test('no generated warnings', () {
          expect(outSink.toString(), contains('No issues found'));
        });
      });
    });

    test('containsLintRuleEntry', () {
      Map<String, YamlNode> options;
      options = parseOptions('''
linter:
  rules:
    - foo
        ''');
      expect(containsLintRuleEntry(options), true);
      options = parseOptions('''
        ''');
      expect(containsLintRuleEntry(options), false);
      options = parseOptions('''
linter:
  rules:
    # - foo
        ''');
      expect(containsLintRuleEntry(options), true);
      options = parseOptions('''
linter:
 # rules:
    # - foo
        ''');
      expect(containsLintRuleEntry(options), false);
    });

    group('options processing', () {
      group('error filters', () {
        StringSink savedOutSink;
        Driver driver;

        setUp(() {
          savedOutSink = outSink;
          outSink = new StringBuffer();

          driver = new Driver();
          driver.start([
            'test/data/options_tests_project/test_file.dart',
            '--options',
            'test/data/options_tests_project/.analysis_options'
          ]);
        });
        tearDown(() {
          outSink = savedOutSink;
        });

        test('filters', () {
          var filters =
              driver.context.getConfigurationData(CONFIGURED_ERROR_FILTERS);
          expect(filters, hasLength(1));

          var unused_error = new AnalysisError(
              new TestSource(), 0, 1, HintCode.UNUSED_LOCAL_VARIABLE, [
            ['x']
          ]);
          expect(filters.any((filter) => filter(unused_error)), isTrue);
        });

        test('language config', () {
          expect(driver.context.analysisOptions.enableSuperMixins, isTrue);
        });
      });
    });

    group('in temp directory', () {
      StringSink savedOutSink, savedErrorSink;
      int savedExitCode;
      Directory savedCurrentDirectory;
      Directory tempDir;
      setUp(() {
        savedOutSink = outSink;
        savedErrorSink = errorSink;
        savedExitCode = exitCode;
        outSink = new StringBuffer();
        errorSink = new StringBuffer();
        savedCurrentDirectory = Directory.current;
        tempDir = Directory.systemTemp.createTempSync('analyzer_');
      });
      tearDown(() {
        outSink = savedOutSink;
        errorSink = savedErrorSink;
        exitCode = savedExitCode;
        Directory.current = savedCurrentDirectory;
        tempDir.deleteSync(recursive: true);
      });

      test('packages folder', () {
        Directory.current = tempDir;
        new File(path.join(tempDir.path, 'test.dart')).writeAsStringSync('''
import 'package:foo/bar.dart';
main() {
  baz();
}
        ''');
        Directory packagesDir =
            new Directory(path.join(tempDir.path, 'packages'));
        packagesDir.createSync();
        Directory fooDir = new Directory(path.join(packagesDir.path, 'foo'));
        fooDir.createSync();
        new File(path.join(fooDir.path, 'bar.dart')).writeAsStringSync('''
void baz() {}
        ''');
        new Driver().start(['test.dart']);
        expect(exitCode, 0);
      });

      test('no package resolution', () {
        Directory.current = tempDir;
        new File(path.join(tempDir.path, 'test.dart')).writeAsStringSync('''
import 'package:path/path.dart';
main() {}
        ''');
        new Driver().start(['test.dart']);
        expect(exitCode, 3);
        String stdout = outSink.toString();
        expect(stdout, contains('[error] Target of URI does not exist'));
        expect(stdout, contains('1 error found.'));
        expect(errorSink.toString(), '');
      });

      test('bad package root', () {
        new Driver().start(['--package-root', 'does/not/exist', 'test.dart']);
        String stdout = outSink.toString();
        expect(exitCode, 3);
        expect(
            stdout,
            contains(
                'Package root directory (does/not/exist) does not exist.'));
      });
    });
  });
  group('Bootloader', () {
    group('plugin processing', () {
      StringSink savedErrorSink;
      setUp(() {
        savedErrorSink = errorSink;
        errorSink = new StringBuffer();
      });
      tearDown(() {
        errorSink = savedErrorSink;
      });
      test('bad format', () {
        BootLoader loader = new BootLoader();
        loader.createImage([
          '--options',
          'test/data/bad_plugin_options.yaml',
          'test/data/test_file.dart'
        ]);
        expect(
            errorSink.toString(),
            equals('Plugin configuration skipped: Unrecognized plugin config '
                'format, expected `YamlMap`, got `YamlList` '
                '(line 2, column 4)\n'));
      });
      test('plugin config', () {
        BootLoader loader = new BootLoader();
        Image image = loader.createImage([
          '--options',
          'test/data/plugin_options.yaml',
          'test/data/test_file.dart'
        ]);
        var plugins = image.config.plugins;
        expect(plugins, hasLength(1));
        expect(plugins.first.name, equals('my_plugin1'));
      });
      group('plugin validation', () {
        test('requires class name', () {
          expect(
              validate(new PluginInfo(
                  name: 'test_plugin', libraryUri: 'my_package/foo.dart')),
              isNotNull);
        });
        test('requires library URI', () {
          expect(
              validate(
                  new PluginInfo(name: 'test_plugin', className: 'MyPlugin')),
              isNotNull);
        });
        test('check', () {
          expect(
              validate(new PluginInfo(
                  name: 'test_plugin',
                  className: 'MyPlugin',
                  libraryUri: 'my_package/foo.dart')),
              isNull);
        });
      });
    });
  });
}

const emptyOptionsFile = 'test/data/empty_options.yaml';

/// Start a driver for the given [source], optionally providing additional
/// [args] and an [options] file path.  The value of [options] defaults to
/// an empty options file to avoid unwanted configuration from an otherwise
/// discovered options file.
void drive(String source,
        {String options: emptyOptionsFile,
        List<String> args: const <String>[]}) =>
    new Driver().start(['--options', options, source]..addAll(args));

Map<String, YamlNode> parseOptions(String src) =>
    new AnalysisOptionsProvider().getOptionsFromString(src);

class TestPlugin extends Plugin {
  TestProcessor processor;
  TestPlugin(this.processor);

  @override
  String get uniqueIdentifier => 'test_plugin.core';

  @override
  void registerExtensionPoints(RegisterExtensionPoint register) {
    // None
  }

  @override
  void registerExtensions(RegisterExtension register) {
    register(OPTIONS_PROCESSOR_EXTENSION_POINT_ID, processor);
  }
}

class TestProcessor extends OptionsProcessor {
  Map<String, YamlNode> options;
  Exception exception;

  @override
  void onError(Exception exception) {
    this.exception = exception;
  }

  @override
  void optionsProcessed(
      AnalysisContext context, Map<String, YamlNode> options) {
    this.options = options;
  }
}

class TestSource implements Source {
  TestSource();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
