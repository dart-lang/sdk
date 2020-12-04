// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/command_line/arguments.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:args/args.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ArgumentsTest);
  });
}

@reflectiveTest
class ArgumentsTest with ResourceProviderMixin {
  void test_createContextBuilderOptions_all() {
    String dartSdkSummaryPath = 'a';
    String defaultAnalysisOptionsFilePath = 'b';
    String defaultPackageFilePath = 'c';
    ArgParser parser = ArgParser();
    defineAnalysisArguments(parser);
    List<String> args = [
      '--dart-sdk-summary=$dartSdkSummaryPath',
      '-Dfoo=1',
      '-Dbar=2',
      '--no-implicit-casts',
      '--no-implicit-dynamic',
      '--options=$defaultAnalysisOptionsFilePath',
      '--packages=$defaultPackageFilePath',
    ];
    ArgResults result = parse(resourceProvider, parser, args);
    ContextBuilderOptions options =
        createContextBuilderOptions(resourceProvider, result);
    expect(options, isNotNull);

    expect(
      options.defaultAnalysisOptionsFilePath,
      endsWith(defaultAnalysisOptionsFilePath),
    );
    expect(
      options.defaultPackageFilePath,
      endsWith(defaultPackageFilePath),
    );
    expect(
      options.dartSdkSummaryPath,
      endsWith(dartSdkSummaryPath),
    );

    Map<String, String> declaredVariables = options.declaredVariables;
    expect(declaredVariables, hasLength(2));
    expect(declaredVariables['foo'], '1');
    expect(declaredVariables['bar'], '2');

    AnalysisOptionsImpl defaultOptions = options.defaultOptions;
    expect(defaultOptions, isNotNull);
    expect(defaultOptions.implicitCasts, false);
    expect(defaultOptions.implicitDynamic, false);
  }

  void test_createContextBuilderOptions_none() {
    ArgParser parser = ArgParser();
    defineAnalysisArguments(parser);
    List<String> args = [];
    ArgResults result = parse(resourceProvider, parser, args);
    ContextBuilderOptions options =
        createContextBuilderOptions(resourceProvider, result);
    expect(options, isNotNull);
    expect(options.dartSdkSummaryPath, isNull);
    expect(options.declaredVariables, isEmpty);
    expect(options.defaultAnalysisOptionsFilePath, isNull);
    expect(options.defaultPackageFilePath, isNull);
    AnalysisOptionsImpl defaultOptions = options.defaultOptions;
    expect(defaultOptions, isNotNull);
    expect(defaultOptions.implicitCasts, true);
    expect(defaultOptions.implicitDynamic, true);
  }

  void test_defineAnalysisArguments() {
    ArgParser parser = ArgParser();
    defineAnalysisArguments(parser);
    expect(parser.options, hasLength(11));
  }

  void test_extractDefinedVariables() {
    List<String> args = ['--a', '-Dbaz', 'go', '-Dc=d', 'e=f', '-Dy=', '-Dx'];
    Map<String, String> definedVariables = {'one': 'two'};
    args = extractDefinedVariables(args, definedVariables);
    expect(args, orderedEquals(['--a', 'e=f', '-Dx']));
    expect(definedVariables['one'], 'two');
    expect(definedVariables['two'], isNull);
    expect(definedVariables['baz'], 'go');
    expect(definedVariables['go'], isNull);
    expect(definedVariables['c'], 'd');
    expect(definedVariables['d'], isNull);
    expect(definedVariables['y'], '');
    expect(definedVariables, hasLength(4));
  }

  void test_filterUnknownArguments() {
    List<String> args = ['--a', '--b', '--c=0', '--d=1', '-e=2', '-f', 'bar'];
    ArgParser parser = ArgParser();
    parser.addFlag('a');
    parser.addOption('c');
    parser.addOption('ee', abbr: 'e');
    parser.addFlag('ff', abbr: 'f');
    List<String> result = filterUnknownArguments(args, parser);
    expect(result, orderedEquals(['--a', '--c=0', '-e=2', '-f', 'bar']));
  }

  void test_implicitCast() {
    ArgParser parser = ArgParser();
    defineAnalysisArguments(parser);
    List<String> args = [
      '--implicit-casts',
    ];
    ArgResults result = parse(resourceProvider, parser, args);
    ContextBuilderOptions options =
        createContextBuilderOptions(resourceProvider, result);
    expect(options, isNotNull);
    AnalysisOptionsImpl defaultOptions = options.defaultOptions;
    expect(defaultOptions, isNotNull);
    expect(defaultOptions.implicitCasts, true);
  }

  void test_noImplicitCast() {
    ArgParser parser = ArgParser();
    defineAnalysisArguments(parser);
    List<String> args = [
      '--no-implicit-casts',
    ];
    ArgResults result = parse(resourceProvider, parser, args);
    ContextBuilderOptions options =
        createContextBuilderOptions(resourceProvider, result);
    expect(options, isNotNull);
    AnalysisOptionsImpl defaultOptions = options.defaultOptions;
    expect(defaultOptions, isNotNull);
    expect(defaultOptions.implicitCasts, false);
  }

  void test_parse_noReplacement_noIgnored() {
    ArgParser parser = ArgParser();
    parser.addFlag('xx');
    parser.addOption('yy');
    List<String> args = ['--xx', '--yy=abc', 'foo', 'bar'];
    ArgResults result = parse(resourceProvider, parser, args);
    expect(result, isNotNull);
    expect(result['xx'], true);
    expect(result['yy'], 'abc');
    expect(result.rest, orderedEquals(['foo', 'bar']));
  }

  void test_preprocessArgs_noReplacement() {
    List<String> original = ['--xx' '--yy' 'baz'];
    List<String> result = preprocessArgs(resourceProvider, original);
    expect(result, orderedEquals(original));
    expect(identical(original, result), isFalse);
  }

  void test_preprocessArgs_replacement_exists() {
    String filePath = convertPath('/args.txt');
    newFile(filePath, content: '''
-a
--xx

foo
bar
''');
    List<String> result =
        preprocessArgs(resourceProvider, ['--preserved', '@$filePath']);
    expect(result, orderedEquals(['--preserved', '-a', '--xx', 'foo', 'bar']));
  }

  void test_preprocessArgs_replacement_nonexistent() {
    String filePath = convertPath('/args.txt');
    List<String> args = ['ignored', '@$filePath'];
    try {
      preprocessArgs(resourceProvider, args);
      fail('Expect exception');
    } on Exception catch (e) {
      expect(e.toString(), contains('Failed to read file'));
      expect(e.toString(), contains('@$filePath'));
    }
  }

  void test_preprocessArgs_replacement_notLast() {
    String filePath = convertPath('/args.txt');
    List<String> args = ['a', '@$filePath', 'b'];
    List<String> result = preprocessArgs(resourceProvider, args);
    expect(result, orderedEquals(args));
  }
}
