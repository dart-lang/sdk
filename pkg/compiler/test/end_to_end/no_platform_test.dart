// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/kernel/dart2js_target.dart' show Dart2jsTarget;
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/target/targets.dart' hide DiagnosticReporter;
import 'package:front_end/src/api_prototype/standard_file_system.dart' as fe;
import 'package:front_end/src/api_unstable/dart2js.dart' as fe;
import 'package:compiler/src/util/memory_compiler.dart';

main() {
  runTest(Map<fe.ExperimentalFlag, bool> experimentalFlags) async {
    fe.InitializedCompilerState initializedCompilerState =
        fe.initializeCompiler(
            null,
            Dart2jsTarget('dart2js', TargetFlags()),
            sdkLibrariesSpecificationUri,
            [], // additionalDills
            Uri.base
                .resolve('.dart_tool/package_config.json'), // packagesFileUri
            explicitExperimentalFlags: experimentalFlags,
            verify: true);
    ir.Component component = (await fe.compile(
        initializedCompilerState, false, fe.StandardFileSystem.instance,
        (fe.DiagnosticMessage message) {
      message.plainTextFormatted.forEach(print);
      Expect.notEquals(fe.Severity.error, message.severity);
    }, [
      Uri.base.resolve('pkg/compiler/test/end_to_end/data/hello_world.dart')
    ]))!;
    Expect.isNotNull(new ir.CoreTypes(component).futureClass);
  }

  asyncTest(() async {
    Map<fe.ExperimentalFlag, bool> baseFlags = {
      fe.ExperimentalFlag.nonNullable: true
    };
    await runTest(baseFlags);
  });
}
