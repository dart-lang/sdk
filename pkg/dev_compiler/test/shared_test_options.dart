// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/src/compiler/module_builder.dart'
    show ModuleFormat;
import 'package:dev_compiler/src/kernel/command.dart'
    show addGeneratedVariables, getSdkPath;
import 'package:dev_compiler/src/kernel/target.dart' show DevCompilerTarget;
import 'package:front_end/src/api_unstable/ddc.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:front_end/src/fasta/incremental_serializer.dart';
import 'package:kernel/ast.dart' show Component;
import 'package:kernel/target/targets.dart';
import 'package:path/path.dart' as p;

class DevelopmentIncrementalCompiler extends IncrementalCompiler {
  Uri entryPoint;

  DevelopmentIncrementalCompiler(CompilerOptions options, this.entryPoint,
      [Uri? initializeFrom,
      bool? outlineOnly,
      IncrementalSerializer? incrementalSerializer])
      : super(
            CompilerContext(
                ProcessedOptions(options: options, inputs: [entryPoint])),
            initializeFrom,
            outlineOnly,
            incrementalSerializer);

  DevelopmentIncrementalCompiler.fromComponent(CompilerOptions options,
      this.entryPoint, Component componentToInitializeFrom,
      [bool? outlineOnly, IncrementalSerializer? incrementalSerializer])
      : super.fromComponent(
            CompilerContext(
                ProcessedOptions(options: options, inputs: [entryPoint])),
            componentToInitializeFrom,
            outlineOnly,
            incrementalSerializer);
}

class SetupCompilerOptions {
  static final sdkRoot = computePlatformBinariesLocation();
  // Unsound .dill files are not longer in the released SDK so this file must be
  // read from the build output directory.
  static final sdkUnsoundSummaryPath =
      computePlatformBinariesLocation(forceBuildDir: true)
          .resolve('ddc_outline_unsound.dill');
  // Use the outline copied to the released SDK.
  static final sdkSoundSummaryPath = sdkRoot.resolve('ddc_outline.dill');
  static final librariesSpecificationUri =
      p.join(p.dirname(p.dirname(getSdkPath())), 'libraries.json');

  static CompilerOptions getOptions(bool soundNullSafety) {
    var options = CompilerOptions()
      ..verbose = false // set to true for debugging
      ..sdkRoot = sdkRoot
      ..target =
          DevCompilerTarget(TargetFlags(soundNullSafety: soundNullSafety))
      ..librariesSpecificationUri = Uri.base.resolve('sdk/lib/libraries.json')
      ..omitPlatform = true
      ..sdkSummary =
          soundNullSafety ? sdkSoundSummaryPath : sdkUnsoundSummaryPath
      ..environmentDefines = addGeneratedVariables({}, enableAsserts: true)
      ..nnbdMode = soundNullSafety ? NnbdMode.Strong : NnbdMode.Weak;
    return options;
  }

  static final String dartUnsoundComment = '// @dart = 2.9';
  static final String dartSoundComment = '//';

  final List<String> errors = [];
  final CompilerOptions options;
  final String dartLangComment;
  final ModuleFormat moduleFormat;
  final bool soundNullSafety;
  final bool canaryFeatures;

  SetupCompilerOptions({
    this.soundNullSafety = true,
    this.moduleFormat = ModuleFormat.amd,
    this.canaryFeatures = false,
  })  : options = getOptions(soundNullSafety),
        dartLangComment =
            soundNullSafety ? dartSoundComment : dartUnsoundComment {
    options.onDiagnostic = (DiagnosticMessage m) {
      errors.addAll(m.plainTextFormatted);
    };
  }

  String get loadModule {
    switch (moduleFormat) {
      case ModuleFormat.amd:
        return 'require';
      case ModuleFormat.ddc:
        return 'dart_library.import';
      default:
        throw UnsupportedError('Module format: $moduleFormat');
    }
  }
}
