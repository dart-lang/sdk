// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary2/kernel_compilation_service.dart';
import 'package:analyzer/src/summary2/macro.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../summary/macros_environment.dart';
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
  MacroKernelBuilder? get macroKernelBuilder {
    return FrontEndServerMacroKernelBuilder();
  }

  @override
  void setUp() {
    super.setUp();

    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      macrosEnvironment: MacrosEnvironment.instance,
    );
  }

  @override
  Future<void> tearDown() async {
    await super.tearDown();
    KernelCompilationService.disposeDelayed(
      const Duration(milliseconds: 100),
    );
  }

  test_0() async {
    newFile('$testPackageLibPath/a.dart', r'''
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
