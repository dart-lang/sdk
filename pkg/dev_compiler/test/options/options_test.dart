// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/command_line/arguments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:dev_compiler/src/analyzer/context.dart';
import 'package:dev_compiler/src/analyzer/command.dart';
import 'package:dev_compiler/src/analyzer/driver.dart';
import 'package:dev_compiler/src/analyzer/module_compiler.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing.dart' show repoDirectory, testDirectory;

/// The `test/options` directory.
final optionsDir = p.join(testDirectory, 'options');

/// Summary file for testing.
final sdkSummaryFile = p.join(repoDirectory, 'gen', 'sdk', 'ddc_sdk.sum');

final sdkSummaryArgs = ['--$sdkSummaryPathOption', sdkSummaryFile];

void main() {
  test('basic', () {
    var options = AnalyzerOptions.basic()..analysisRoot = optionsDir;
    var driver = CompilerAnalysisDriver(options);
    var processors = driver.analysisOptions.errorProcessors;
    expect(processors, hasLength(1));
    expect(processors[0].code, CompileTimeErrorCode.UNDEFINED_CLASS.name);
  });

  test('basic sdk summary', () {
    expect(File(sdkSummaryFile).existsSync(), isTrue);
    var options = AnalyzerOptions.basic(dartSdkSummaryPath: sdkSummaryFile)
      ..analysisRoot = optionsDir;
    var driver = CompilerAnalysisDriver(options);
    var sdk = driver.dartSdk;
    expect(sdk, const TypeMatcher<SummaryBasedDartSdk>());
    var processors = driver.analysisOptions.errorProcessors;
    expect(processors, hasLength(1));
    expect(processors[0].code, CompileTimeErrorCode.UNDEFINED_CLASS.name);
  });

  test('fromArgs', () {
    var args = <String>[];
    //TODO(danrubel) remove sdkSummaryArgs once all SDKs have summary file
    args.addAll(sdkSummaryArgs);
    var argResults = ddcArgParser().parse(args);
    var options = AnalyzerOptions.fromArguments(argResults)
      ..analysisRoot = optionsDir;
    var driver = CompilerAnalysisDriver(options);
    var processors = driver.analysisOptions.errorProcessors;
    expect(processors, hasLength(1));
    expect(processors[0].code, CompileTimeErrorCode.UNDEFINED_CLASS.name);
  });

  test('fromArgs options file 2', () {
    var optionsFile2 = p.join(optionsDir, 'analysis_options_2.yaml');
    expect(File(optionsFile2).existsSync(), isTrue);
    var args = <String>['--$analysisOptionsFileOption', optionsFile2];
    //TODO(danrubel) remove sdkSummaryArgs once all SDKs have summary file
    args.addAll(sdkSummaryArgs);
    var argResults = ddcArgParser().parse(args);
    var options = AnalyzerOptions.fromArguments(argResults)
      ..analysisRoot = optionsDir;
    var driver = CompilerAnalysisDriver(options);
    var processors = driver.analysisOptions.errorProcessors;
    expect(processors, hasLength(1));
    expect(processors[0].code, CompileTimeErrorCode.DUPLICATE_DEFINITION.name);
  });

  test('custom module name for summary', () {
    var args = <String>[
      '-snormal',
      '-scustom/path=module',
      '-sanother',
      '--summary=custom/path2=module2'
    ];

    var argResults = ddcArgParser().parse(args);
    var options = CompilerOptions.fromArguments(argResults);
    expect(options.summaryModules.keys.toList(),
        orderedEquals(['normal', 'custom/path', 'another', 'custom/path2']));
    expect(options.summaryModules['custom/path'], equals('module'));
    expect(options.summaryModules['custom/path2'], equals('module2'));
    expect(options.summaryModules.containsKey('normal'), isFalse);
  });
}
