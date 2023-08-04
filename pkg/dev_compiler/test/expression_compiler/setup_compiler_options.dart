// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/src/compiler/module_builder.dart';
import 'package:dev_compiler/src/kernel/command.dart';
import 'package:dev_compiler/src/kernel/target.dart' show DevCompilerTarget;
import 'package:front_end/src/api_unstable/ddc.dart' as fe;
import 'package:front_end/src/compute_platform_binaries_location.dart' as fe;
import 'package:kernel/target/targets.dart';
import 'package:path/path.dart' as p;

class SetupCompilerOptions {
  static final sdkRoot = fe.computePlatformBinariesLocation();
  static final buildRoot =
      fe.computePlatformBinariesLocation(forceBuildDir: true);
  static final sdkUnsoundSummaryPath =
      buildRoot.resolve('ddc_outline_unsound.dill').toFilePath();
  static final sdkSoundSummaryPath =
      buildRoot.resolve('ddc_outline.dill').toFilePath();
  static final librariesSpecificationUri =
      buildRoot.resolve('lib/libraries.json').toFilePath();

  final bool legacyCode;
  final List<String> errors = [];
  final List<String> diagnosticMessages = [];
  final ModuleFormat moduleFormat;
  final fe.CompilerOptions options;
  final bool soundNullSafety;
  final bool canaryFeatures;
  final bool enableAsserts;

  static fe.CompilerOptions _getOptions(
      {required bool enableAsserts, required bool soundNullSafety}) {
    var options = fe.CompilerOptions()
      ..verbose = false // set to true for debugging
      ..sdkRoot = sdkRoot
      ..target =
          DevCompilerTarget(TargetFlags(soundNullSafety: soundNullSafety))
      ..librariesSpecificationUri = p.toUri('sdk/lib/libraries.json')
      ..omitPlatform = true
      ..sdkSummary =
          p.toUri(soundNullSafety ? sdkSoundSummaryPath : sdkUnsoundSummaryPath)
      ..environmentDefines =
          addGeneratedVariables({}, enableAsserts: enableAsserts)
      ..nnbdMode = soundNullSafety ? fe.NnbdMode.Strong : fe.NnbdMode.Weak;
    return options;
  }

  SetupCompilerOptions._({
    this.enableAsserts = true,
    this.soundNullSafety = true,
    this.legacyCode = false,
    this.moduleFormat = ModuleFormat.amd,
    this.canaryFeatures = false,
  }) : options = _getOptions(
            soundNullSafety: soundNullSafety, enableAsserts: enableAsserts) {
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
    bool legacyCode = false,
    ModuleFormat moduleFormat = ModuleFormat.amd,
    List<String> args = const <String>[],
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
      legacyCode: legacyCode,
      moduleFormat: moduleFormat,
      canaryFeatures: canaryFeatures,
    );
  }
}
