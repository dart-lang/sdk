// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;

import 'package:_fe_analyzer_shared/src/macros/isolated_executor/isolated_executor.dart'
    as isolatedExecutor;
import 'package:expect/expect.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/api_prototype/front_end.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:front_end/src/fasta/kernel/macro.dart';
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:kernel/ast.dart' hide Arguments;
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:vm/target/vm.dart';

Future<void> main(List<String> args) async {
  enableMacros = true;

  Directory tempDirectory =
      await Directory.systemTemp.createTemp('macro_api_test');
  int precompiledCount = 0;
  try {
    CompilerOptions options = new CompilerOptions();
    options.sdkRoot = computePlatformBinariesLocation();
    options.environmentDefines = {};
    options.explicitExperimentalFlags[ExperimentalFlag.macros] = true;
    options.packagesFileUri = Platform.script.resolve(
        '../../_fe_analyzer_shared/test/macros/api/package_config.json');
    options.macroExecutorProvider = () async {
      return await isolatedExecutor.start();
    };
    options.precompiledMacroUris = {};
    options.target = options.macroTarget = new VmTarget(new TargetFlags());
    options.macroSerializer = (Component component) async {
      Uri uri = tempDirectory.absolute.uri
          .resolve('macros${precompiledCount++}.dill');
      await writeComponentToFile(component, uri);
      return uri;
    };

    InternalCompilerResult result = await kernelForProgramInternal(
        Platform.script.resolve(
            '../../_fe_analyzer_shared/test/macros/api/api_test_data.dart'),
        options,
        retainDataForTesting: true) as InternalCompilerResult;
    Expect.isFalse(result.kernelTargetForTesting!.loader.hasSeenError);
  } finally {
    await tempDirectory.delete(recursive: true);
  }
}
