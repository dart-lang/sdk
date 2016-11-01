// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.context.context_builder_test;

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/command_line/arguments.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:args/args.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ArgumentsTest);
  });
}

@reflectiveTest
class ArgumentsTest {
  void test_createContextBuilderOptions_all() {
    String dartSdkSummaryPath = 'a';
    String defaultAnalysisOptionsFilePath = 'b';
    String defaultPackageFilePath = 'c';
    String defaultPackagesDirectoryPath = 'd';
    MemoryResourceProvider provider = new MemoryResourceProvider();
    ArgParser parser = new ArgParser();
    defineAnalysisArguments(parser);
    List<String> args = [
      '--dart-sdk-summary=$dartSdkSummaryPath',
      '-Dfoo=1',
      '-Dbar=2',
      '--enable-strict-call-checks',
      '--initializing-formal-access',
      '--no-implicit-casts',
      '--no-implicit-dynamic',
      '--options=$defaultAnalysisOptionsFilePath',
      '--packages=$defaultPackageFilePath',
      '--package-root=$defaultPackagesDirectoryPath',
      '--strong',
      '--supermixin',
    ];
    ArgResults result = parse(provider, parser, args);
    ContextBuilderOptions options = createContextBuilderOptions(result);
    expect(options, isNotNull);
    expect(options.dartSdkSummaryPath, dartSdkSummaryPath);
    Map<String, String> declaredVariables = options.declaredVariables;
    expect(declaredVariables, hasLength(2));
    expect(declaredVariables['foo'], '1');
    expect(declaredVariables['bar'], '2');
    expect(
        options.defaultAnalysisOptionsFilePath, defaultAnalysisOptionsFilePath);
    expect(options.defaultPackageFilePath, defaultPackageFilePath);
    expect(options.defaultPackagesDirectoryPath, defaultPackagesDirectoryPath);
    AnalysisOptionsImpl defaultOptions = options.defaultOptions;
    expect(defaultOptions, isNotNull);
    expect(defaultOptions.enableInitializingFormalAccess, true);
    expect(defaultOptions.enableStrictCallChecks, true);
    expect(defaultOptions.strongMode, true);
    expect(defaultOptions.implicitCasts, false);
    expect(defaultOptions.implicitDynamic, false);
    expect(options.pubSummaryManager, isNull);
  }

  void test_createContextBuilderOptions_none() {
    MemoryResourceProvider provider = new MemoryResourceProvider();
    ArgParser parser = new ArgParser();
    defineAnalysisArguments(parser);
    List<String> args = [];
    ArgResults result = parse(provider, parser, args);
    ContextBuilderOptions options = createContextBuilderOptions(result);
    expect(options, isNotNull);
    expect(options.dartSdkSummaryPath, isNull);
    expect(options.declaredVariables, isEmpty);
    expect(options.defaultAnalysisOptionsFilePath, isNull);
    expect(options.defaultPackageFilePath, isNull);
    expect(options.defaultPackagesDirectoryPath, isNull);
    AnalysisOptionsImpl defaultOptions = options.defaultOptions;
    expect(defaultOptions, isNotNull);
    expect(defaultOptions.enableInitializingFormalAccess, false);
    expect(defaultOptions.enableStrictCallChecks, false);
    expect(defaultOptions.strongMode, false);
    expect(defaultOptions.implicitCasts, true);
    expect(defaultOptions.implicitDynamic, true);
    expect(options.pubSummaryManager, isNull);
  }

  void test_createDartSdkManager_noPath_noSummaries() {
    MemoryResourceProvider provider = new MemoryResourceProvider();
    ArgParser parser = new ArgParser();
    defineAnalysisArguments(parser);
    List<String> args = [];
    ArgResults result = parse(provider, parser, args);
    DartSdkManager manager = createDartSdkManager(provider, false, result);
    expect(manager, isNotNull);
    expect(manager.defaultSdkDirectory,
        FolderBasedDartSdk.defaultSdkDirectory(provider));
    expect(manager.canUseSummaries, false);
  }

  void test_createDartSdkManager_noPath_summaries() {
    MemoryResourceProvider provider = new MemoryResourceProvider();
    ArgParser parser = new ArgParser();
    defineAnalysisArguments(parser);
    List<String> args = [];
    ArgResults result = parse(provider, parser, args);
    DartSdkManager manager = createDartSdkManager(provider, true, result);
    expect(manager, isNotNull);
    expect(manager.defaultSdkDirectory,
        FolderBasedDartSdk.defaultSdkDirectory(provider));
    expect(manager.canUseSummaries, true);
  }

  void test_createDartSdkManager_path_noSummaries() {
    MemoryResourceProvider provider = new MemoryResourceProvider();
    ArgParser parser = new ArgParser();
    defineAnalysisArguments(parser);
    List<String> args = ['--dart-sdk=x'];
    ArgResults result = parse(provider, parser, args);
    DartSdkManager manager = createDartSdkManager(provider, false, result);
    expect(manager, isNotNull);
    expect(manager.defaultSdkDirectory, 'x');
    expect(manager.canUseSummaries, false);
  }

  void test_createDartSdkManager_path_summaries() {
    MemoryResourceProvider provider = new MemoryResourceProvider();
    ArgParser parser = new ArgParser();
    defineAnalysisArguments(parser);
    List<String> args = ['--dart-sdk=y'];
    ArgResults result = parse(provider, parser, args);
    DartSdkManager manager = createDartSdkManager(provider, true, result);
    expect(manager, isNotNull);
    expect(manager.defaultSdkDirectory, 'y');
    expect(manager.canUseSummaries, true);
  }

  void test_defineAnalysisArguments() {
    ArgParser parser = new ArgParser();
    defineAnalysisArguments(parser);
    expect(parser.options, hasLength(12));
  }

  void test_filterUnknownArguments() {
    List<String> args = ['--a', '--b', '--c', 'foo', 'bar'];
    ArgParser parser = new ArgParser();
    parser.addFlag('a');
    parser.addFlag('c');
    List<String> result = filterUnknownArguments(args, parser);
    expect(result, orderedEquals(['--a', '--c', 'foo', 'bar']));
  }

  void test_parse_noReplacement_noIgnored() {
    MemoryResourceProvider provider = new MemoryResourceProvider();
    ArgParser parser = new ArgParser();
    parser.addFlag('xx');
    parser.addOption('yy');
    List<String> args = ['--xx', '--yy=abc', 'foo', 'bar'];
    ArgResults result = parse(provider, parser, args);
    expect(result, isNotNull);
    expect(result['xx'], true);
    expect(result['yy'], 'abc');
    expect(result.rest, orderedEquals(['foo', 'bar']));
  }

  void test_preprocessArgs_noReplacement() {
    MemoryResourceProvider provider = new MemoryResourceProvider();
    List<String> result = preprocessArgs(provider, ['--xx' '--yy' 'baz']);
    expect(result, orderedEquals(['--xx' '--yy' 'baz']));
  }

  void test_preprocessArgs_replacement_exists() {
    MemoryResourceProvider provider = new MemoryResourceProvider();
    String filePath = provider.convertPath('/args.txt');
    provider.newFile(
        filePath,
        '''
-a
--xx

foo
bar
''');
    List<String> result =
        preprocessArgs(provider, ['--preserved', '@$filePath']);
    expect(result, orderedEquals(['--preserved', '-a', '--xx', 'foo', 'bar']));
  }

  void test_preprocessArgs_replacement_nonexistent() {
    MemoryResourceProvider provider = new MemoryResourceProvider();
    String filePath = provider.convertPath('/args.txt');
    List<String> args = ['ignored', '@$filePath'];
    List<String> result = preprocessArgs(provider, args);
    expect(result, orderedEquals(args));
  }

  void test_preprocessArgs_replacement_notLast() {
    MemoryResourceProvider provider = new MemoryResourceProvider();
    String filePath = provider.convertPath('/args.txt');
    List<String> args = ['a', '@$filePath', 'b'];
    List<String> result = preprocessArgs(provider, args);
    expect(result, orderedEquals(args));
  }
}
