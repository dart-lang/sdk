// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/command_line/arguments.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../lib/src/analyzer/context.dart';
import '../../lib/src/compiler/command.dart';
import '../../lib/src/compiler/compiler.dart';
import '../testing.dart' show repoDirectory, testDirectory;

/// The `test/options` directory.
final optionsDir = path.join(testDirectory, 'options');

/// Summary file for testing.
final sdkSummaryFile = path.join(repoDirectory, 'lib', 'sdk', 'ddc_sdk.sum');

final sdkSummaryArgs = ['--$sdkSummaryPathOption', sdkSummaryFile];

main() {
  test('basic', () {
    var options = new AnalyzerOptions.basic();
    var compiler = new ModuleCompiler(options, analysisRoot: optionsDir);
    var processors = compiler.context.analysisOptions.errorProcessors;
    expect(processors, hasLength(1));
    expect(processors[0].code, CompileTimeErrorCode.UNDEFINED_CLASS.name);
  });

  test('basic sdk summary', () {
    expect(new File(sdkSummaryFile).existsSync(), isTrue);
    var options = new AnalyzerOptions.basic(dartSdkSummaryPath: sdkSummaryFile);
    var compiler = new ModuleCompiler(options, analysisRoot: optionsDir);
    var context = compiler.context;
    var sdk = context.sourceFactory.dartSdk;
    expect(sdk, new isInstanceOf<SummaryBasedDartSdk>());
    var processors = context.analysisOptions.errorProcessors;
    expect(processors, hasLength(1));
    expect(processors[0].code, CompileTimeErrorCode.UNDEFINED_CLASS.name);
  });

  test('fromArgs', () {
    var args = <String>[];
    //TODO(danrubel) remove sdkSummaryArgs once all SDKs have summary file
    args.addAll(sdkSummaryArgs);
    var argResults = ddcArgParser().parse(args);
    var options = new AnalyzerOptions.fromArguments(argResults);
    var compiler = new ModuleCompiler(options, analysisRoot: optionsDir);
    var processors = compiler.context.analysisOptions.errorProcessors;
    expect(processors, hasLength(1));
    expect(processors[0].code, CompileTimeErrorCode.UNDEFINED_CLASS.name);
  });

  test('fromArgs options file 2', () {
    var optionsFile2 = path.join(optionsDir, 'analysis_options_2.yaml');
    expect(new File(optionsFile2).existsSync(), isTrue);
    var args = <String>['--$analysisOptionsFileOption', optionsFile2];
    //TODO(danrubel) remove sdkSummaryArgs once all SDKs have summary file
    args.addAll(sdkSummaryArgs);
    var argResults = ddcArgParser().parse(args);
    var options = new AnalyzerOptions.fromArguments(argResults);
    var compiler = new ModuleCompiler(options, analysisRoot: optionsDir);
    var processors = compiler.context.analysisOptions.errorProcessors;
    expect(processors, hasLength(1));
    expect(processors[0].code, CompileTimeErrorCode.DUPLICATE_DEFINITION.name);
  });

  test('fromArgs options flag', () {
    var args = <String>['--$enableStrictCallChecksFlag'];
    //TODO(danrubel) remove sdkSummaryArgs once all SDKs have summary file
    args.addAll(sdkSummaryArgs);
    var argResults = ddcArgParser().parse(args);
    var options = new AnalyzerOptions.fromArguments(argResults);
    var compiler = new ModuleCompiler(options, analysisRoot: optionsDir);
    var analysisOptions = compiler.context.analysisOptions;
    expect(analysisOptions.enableStrictCallChecks, isTrue);
  });

  test('custom module name for summary', () {
    var args = <String>[
      '-snormal',
      '-scustom/path|module',
      '-sanother',
      '-scustom/path2|module2'
    ];

    var argResults = ddcArgParser().parse(args);
    var options = new AnalyzerOptions.fromArguments(argResults);
    expect(options.summaryPaths,
        orderedEquals(['normal', 'custom/path', 'another', 'custom/path2']));
    expect(options.customSummaryModules['custom/path'], equals('module'));
    expect(options.customSummaryModules['custom/path2'], equals('module2'));
    expect(options.customSummaryModules.containsKey('normal'), isFalse);
  });
}
