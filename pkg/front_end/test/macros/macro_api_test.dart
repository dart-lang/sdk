// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:front_end/src/api_prototype/terminal_color_support.dart';
import 'package:macros/src/executor/multi_executor.dart';
import 'package:expect/expect.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/api_prototype/front_end.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:front_end/src/macros/isolate_macro_serializer.dart';
import 'package:front_end/src/macros/macro_serializer.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';

Future<void> main(List<String> args) async {
  MacroSerializer macroSerializer = new IsolateMacroSerializer();
  try {
    CompilerOptions options = new CompilerOptions();
    options.sdkRoot = computePlatformBinariesLocation();
    options.environmentDefines = {};
    options.explicitExperimentalFlags[ExperimentalFlag.macros] = true;
    options.packagesFileUri = Platform.script.resolve(
        '../../../_fe_analyzer_shared/test/macros/api/package_config.json');
    options.macroExecutor ??= new MultiMacroExecutor();
    options.macroSerializer = macroSerializer;
    options.onDiagnostic = (DiagnosticMessage message) {
      printDiagnosticMessage(message, print);
    };
    InternalCompilerResult result = await kernelForProgramInternal(
        Platform.script.resolve(
            '../../../_fe_analyzer_shared/test/macros/api/api_test_data.dart'),
        options,
        retainDataForTesting: true) as InternalCompilerResult;
    Expect.isFalse(result.kernelTargetForTesting!.loader.hasSeenError);
  } finally {
    await macroSerializer.close();
  }
}
