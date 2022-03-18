// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: deprecated_member_use
import 'dart:cli' as cli;

import 'package:_fe_analyzer_shared/src/macros/executor.dart' as macro
    show MacroExecutor;
import 'package:_fe_analyzer_shared/src/macros/executor/isolated_executor.dart'
    as isolated_executor;
import 'package:_fe_analyzer_shared/src/macros/executor/serialization.dart'
    as macro;
import 'package:analyzer/src/summary2/macro.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../summary/repository_macro_kernel_builder.dart';
import 'context_collection_resolution.dart';

main() {
  try {
    MacrosEnvironment.instance;
  } catch (_) {
    print('Cannot initialize environment. Skip macros tests.');
    return;
  }

  defineReflectiveSuite(() {
    defineReflectiveTests(MacroResolutionTest);
  });
}

@reflectiveTest
class MacroResolutionTest extends PubPackageResolutionTest {
  @override
  macro.MacroExecutor? get macroExecutor {
    // TODO(scheglov) For now we convert async into sync.
    // ignore: deprecated_member_use
    return cli.waitFor(
      isolated_executor.start(
        macro.SerializationMode.byteDataServer,
      ),
    );
  }

  @override
  MacroKernelBuilder? get macroKernelBuilder {
    return DartRepositoryMacroKernelBuilder(
      MacrosEnvironment.instance.platformDillBytes,
    );
  }

  @override
  void setUp() {
    super.setUp();

    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      macrosEnvironment: MacrosEnvironment.instance,
    );
  }

  test_0() async {
    newFile2('$testPackageLibPath/a.dart', r'''
import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class EmptyMacro implements ClassTypesMacro {
  const EmptyMacro();

  FutureOr<void> buildTypesForClass(clazz, builder) {
    var targetName = clazz.identifier.name;
    builder.declareType(
      '${targetName}_Macro',
      DeclarationCode.fromString('class ${targetName}_Macro {}'),
    );
  }
}
''');

    await assertNoErrorsInCode('''
import 'a.dart';

@EmptyMacro()
class A {}

void f(A_Macro a) {}
''');
  }
}
