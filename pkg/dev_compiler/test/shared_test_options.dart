// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/src/compiler/module_builder.dart'
    show ModuleFormat;
import 'package:dev_compiler/src/kernel/command.dart' show getSdkPath;
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
  static final sdkUnsoundSummaryPath =
      p.join(sdkRoot.path, 'ddc_outline_unsound.dill');
  static final sdkSoundSummaryPath = p.join(sdkRoot.path, 'ddc_outline.dill');
  // TODO(46617) Call getSdkPath() from command.dart instead.
  static final librariesSpecificationUri =
      p.join(p.dirname(p.dirname(getSdkPath())), 'libraries.json');

  static CompilerOptions getOptions(bool soundNullSafety) {
    var options = CompilerOptions()
      ..verbose = false // set to true for debugging
      ..sdkRoot = sdkRoot
      ..target = DevCompilerTarget(TargetFlags())
      ..librariesSpecificationUri = Uri.base.resolve('sdk/lib/libraries.json')
      ..omitPlatform = true
      ..sdkSummary = sdkRoot.resolve(
          soundNullSafety ? sdkSoundSummaryPath : sdkUnsoundSummaryPath)
      ..environmentDefines = const {}
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

  SetupCompilerOptions(
      {this.soundNullSafety = true, this.moduleFormat = ModuleFormat.amd})
      : options = getOptions(soundNullSafety),
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
