// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/executor/multi_executor.dart'
    as macro;
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'element_text.dart';
import 'elements_base.dart';
import 'repository_macro_kernel_builder.dart';

main() {
  try {
    MacrosEnvironment.instance;
  } catch (_) {
    print('Cannot initialize environment. Skip macros tests.');
    return;
  }

  defineReflectiveSuite(() {
    defineReflectiveTests(MacroElementsKeepLinkingTest);
    defineReflectiveTests(MacroElementsFromBytesTest);
  });
}

@reflectiveTest
class MacroElementsFromBytesTest extends MacroElementsTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class MacroElementsKeepLinkingTest extends MacroElementsTest {
  @override
  bool get keepLinkingLibraries => true;
}

class MacroElementsTest extends ElementsBaseTest {
  @override
  bool get keepLinkingLibraries => false;

  /// The path for external packages.
  String get packagesRootPath => '/packages';

  Future<void> setUp() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      macrosEnvironment: MacrosEnvironment.instance,
    );

    macroKernelBuilder = DartRepositoryMacroKernelBuilder(
      MacrosEnvironment.instance.platformDillBytes,
    );

    macroExecutor = macro.MultiMacroExecutor();
  }

  Future<void> tearDown() async {
    await macroExecutor?.close();
  }

  test_build_types() async {
    newFile2('$testPackageLibPath/a.dart', r'''
import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  FutureOr<void> buildTypesForClass(clazz, builder) {
    builder.declareType(
      'MyClass',
      DeclarationCode.fromString('class MyClass {}'),
    );
  }
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';

@MyMacro()
class A {}
''', preBuildSequence: [
      {'package:test/a.dart'}
    ]);

    checkElementText(library, r'''
library
  imports
    package:test/a.dart
  definingUnit
    classes
      class A @35
        metadata
          Annotation
            atSign: @ @18
            name: SimpleIdentifier
              token: MyMacro @19
              staticElement: package:test/a.dart::@class::MyMacro
              staticType: null
            arguments: ArgumentList
              leftParenthesis: ( @26
              rightParenthesis: ) @27
            element: package:test/a.dart::@class::MyMacro::@constructor::•
        constructors
          synthetic @-1
  parts
    package:test/_macro_types.dart
      classes
        class MyClass @6
          constructors
            synthetic @-1
''');
  }

  test_class_macro() async {
    var library = await buildLibrary(r'''
macro class A {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      macro class A @12
        constructors
          synthetic @-1
''');
  }

  test_classAlias_macro() async {
    var library = await buildLibrary(r'''
mixin M {}
macro class A = Object with M;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      macro class alias A @23
        supertype: Object
        mixins
          M
        constructors
          synthetic const @-1
            constantInitializers
              SuperConstructorInvocation
                superKeyword: super @0
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: dart:core::@class::Object::@constructor::•
    mixins
      mixin M @6
        superclassConstraints
          Object
''');
  }

  void writeTestPackageConfig(
    PackageConfigFileBuilder config, {
    MacrosEnvironment? macrosEnvironment,
  }) {
    config = config.copy();

    config.add(
      name: 'test',
      rootPath: testPackageRootPath,
    );

    if (macrosEnvironment != null) {
      var packagesRootFolder = getFolder(packagesRootPath);
      macrosEnvironment.packageSharedFolder.copyTo(packagesRootFolder);
      config.add(
        name: '_fe_analyzer_shared',
        rootPath: getFolder('$packagesRootPath/_fe_analyzer_shared').path,
      );
    }

    newPackageConfigJsonFile(
      testPackageRootPath,
      config.toContent(
        toUriStr: toUriStr,
      ),
    );
  }
}
