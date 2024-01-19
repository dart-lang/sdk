// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/src/compiler/module_builder.dart'
    show ModuleFormat;
import 'package:dev_compiler/src/kernel/command.dart'
    show addGeneratedVariables;
import 'package:dev_compiler/src/kernel/target.dart' show DevCompilerTarget;
import 'package:front_end/src/api_unstable/ddc.dart' as fe;
import 'package:front_end/src/compute_platform_binaries_location.dart' as fe;
import 'package:front_end/src/fasta/incremental_serializer.dart' as fe;
import 'package:kernel/ast.dart' show Component;
import 'package:kernel/target/targets.dart' show TargetFlags;

class DevelopmentIncrementalCompiler extends fe.IncrementalCompiler {
  Uri entryPoint;

  DevelopmentIncrementalCompiler(fe.CompilerOptions options, this.entryPoint,
      [Uri? initializeFrom,
      bool? outlineOnly,
      fe.IncrementalSerializer? incrementalSerializer])
      : super(
            fe.CompilerContext(
                fe.ProcessedOptions(options: options, inputs: [entryPoint])),
            initializeFrom,
            outlineOnly,
            incrementalSerializer);

  DevelopmentIncrementalCompiler.fromComponent(fe.CompilerOptions options,
      this.entryPoint, Component componentToInitializeFrom,
      [bool? outlineOnly, fe.IncrementalSerializer? incrementalSerializer])
      : super.fromComponent(
            fe.CompilerContext(
                fe.ProcessedOptions(options: options, inputs: [entryPoint])),
            componentToInitializeFrom,
            outlineOnly,
            incrementalSerializer);
}

class SetupCompilerOptions {
  static final sdkRoot = fe.computePlatformBinariesLocation();
  static final buildRoot =
      fe.computePlatformBinariesLocation(forceBuildDir: true);
  static final _sdkUnsoundSummaryPath =
      buildRoot.resolve('ddc_outline_unsound.dill');
  static final _sdkSoundSummaryPath = buildRoot.resolve('ddc_outline.dill');

  final List<String> errors = [];
  final List<String> diagnosticMessages = [];
  final ModuleFormat moduleFormat;
  final fe.CompilerOptions options;
  final bool soundNullSafety;
  final bool canaryFeatures;
  final bool enableAsserts;

  static fe.CompilerOptions _getOptions(
      {required bool enableAsserts,
      required bool soundNullSafety,
      required List<String> enableExperiments}) {
    var options = fe.CompilerOptions()
      ..verbose = false // set to true for debugging
      ..sdkRoot = sdkRoot
      ..target =
          DevCompilerTarget(TargetFlags(soundNullSafety: soundNullSafety))
      ..omitPlatform = true
      ..sdkSummary =
          soundNullSafety ? _sdkSoundSummaryPath : _sdkUnsoundSummaryPath
      ..environmentDefines =
          addGeneratedVariables({}, enableAsserts: enableAsserts)
      ..nnbdMode = soundNullSafety ? fe.NnbdMode.Strong : fe.NnbdMode.Weak
      ..explicitExperimentalFlags = fe.parseExperimentalFlags(
          fe.parseExperimentalArguments(enableExperiments),
          onError: (e) => throw e);
    return options;
  }

  SetupCompilerOptions._({
    this.enableAsserts = true,
    this.soundNullSafety = true,
    this.moduleFormat = ModuleFormat.amd,
    this.canaryFeatures = false,
    List<String> enableExperiments = const [],
  }) : options = _getOptions(
            soundNullSafety: soundNullSafety,
            enableAsserts: enableAsserts,
            enableExperiments: enableExperiments) {
    options.onDiagnostic = (fe.DiagnosticMessage m) {
      diagnosticMessages.addAll(m.plainTextFormatted);
      if (m.severity == fe.Severity.error ||
          m.severity == fe.Severity.internalProblem) {
        errors.addAll(m.plainTextFormatted);
      }
    };
  }

  /// Creates current compiler setup options.
  ///
  /// Reads options determined by the test configuration from the configuration
  /// environment variable set by the test runner.
  ///
  /// To run tests locally using test.py, pass a vm option defining required
  /// configuration, for example:
  ///
  /// `./tools/test.py -n web-dev-canary-unittest-asserts-mac`
  ///
  /// To run a single test locally, pass the --canary or --enable-asserts flags
  /// to the command line to enable corresponding features, for example:
  ///
  /// `dart test/expression_compiler/assertions_enabled_test.dart --canary --enable-asserts`
  factory SetupCompilerOptions({
    bool soundNullSafety = true,
    ModuleFormat moduleFormat = ModuleFormat.amd,
    List<String> enableExperiments = const [],
    List<String> args = const [],
  }) {
    // Find if the test is run with arguments overriding the configuration
    late bool enableAsserts;
    late bool canaryFeatures;

    // Read configuration settings from matrix.json
    var configuration = String.fromEnvironment('test_runner.configuration');
    if (configuration.isEmpty) {
      // If not running from test runner, read options from the args
      enableAsserts = args.contains('--enable-asserts');
      canaryFeatures = args.contains('--canary');
    } else {
      // If running from the test runner, read options from the environment
      // (set to configuration settings from matrix.json).
      enableAsserts = configuration.contains('-asserts-');
      canaryFeatures = configuration.contains('-canary-');
    }
    return SetupCompilerOptions._(
      enableAsserts: enableAsserts,
      soundNullSafety: soundNullSafety,
      moduleFormat: moduleFormat,
      canaryFeatures: canaryFeatures,
      enableExperiments: enableExperiments,
    );
  }

  String get loadModule =>
      moduleFormat == ModuleFormat.amd ? 'require' : 'dart_library.import';
}
