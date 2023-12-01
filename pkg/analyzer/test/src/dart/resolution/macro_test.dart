// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../summary/macros_environment.dart';
import 'context_collection_resolution.dart';
import 'resolution.dart';

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
  void setUp() {
    super.setUp();

    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      macrosEnvironment: MacrosEnvironment.instance,
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

  test_getResolvedLibrary_macroAugmentation_hasErrors() async {
    newFile(
      '$testPackageLibPath/append.dart',
      getMacroCode('append.dart'),
    );

    newFile('$testPackageLibPath/test.dart', r'''
import 'append.dart';

@DeclareInType('  NotType foo() {}')
class A {}
''');

    final session = contextFor(testFile).currentSession;
    final result = await session.getResolvedLibrary(testFile.path);

    assertResolvedLibraryResultText(result, configure: (configuration) {
      configuration.unitConfiguration
        ..nodeSelector = (unitResult) {
          if (unitResult.isAugmentation) {
            return unitResult.findNode.namedType('NotType');
          }
          return null;
        }
        ..withContentPredicate = (unitResult) {
          return unitResult.isAugmentation;
        };
    }, r'''
ResolvedLibraryResult
  element: package:test/test.dart
  units
    /home/test/lib/test.dart
      flags: exists isLibrary
      uri: package:test/test.dart
    /home/test/lib/test.macro.dart
      flags: exists isAugmentation isMacroAugmentation
      uri: package:test/test.macro.dart
      content
---
library augment 'test.dart';

augment class A {
  NotType foo() {}
}
---
      errors
        50 +7 UNDEFINED_CLASS
      selectedNode: NamedType
        name: NotType
        element: <null>
        type: InvalidType
''');
  }

  @FailingTest(reason: 'Fails because exceptions are reported as diagnostics')
  test_macroExecutionException_compileTimeError() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    unresolved;
  }
}
''');

    await assertErrorsInCode('''
import 'a.dart';

@MyMacro()
class A {}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 41, 1),
    ]);
  }

  @FailingTest(reason: 'Fails because exceptions are reported as diagnostics')
  test_macroExecutionException_throwsException() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    throw 42;
  }
}
''');

    await assertErrorsInCode('''
import 'a.dart';

@MyMacro()
class A {}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 41, 1),
    ]);
  }
}
