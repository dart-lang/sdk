// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;
import 'dart:typed_data';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/macro.dart';
import 'package:analyzer/src/summary2/macro_application.dart';
import 'package:analyzer/src/summary2/macro_application_error.dart';
import 'package:macros/src/bootstrap.dart' as macro;
import 'package:macros/src/executor/serialization.dart' as macro;
import 'package:path/path.dart' as package_path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';
import 'element_text.dart';
import 'elements_base.dart';
import 'macros_environment.dart';

main() {
  try {
    MacrosEnvironment.instance;
  } catch (_) {
    print('Cannot initialize environment. Skip macros tests.');
    test('fake', () {});
    return;
  }

  defineReflectiveSuite(() {
    defineReflectiveTests(MacroArgumentsTest);
    defineReflectiveTests(MacroIntrospectNodeTest);
    defineReflectiveTests(MacroIntrospectNodeDefinitionsTest);
    defineReflectiveTests(MacroIntrospectElementTest);
    defineReflectiveTests(MacroTypesTest_keepLinking);
    defineReflectiveTests(MacroTypesTest_fromBytes);
    defineReflectiveTests(MacroDeclarationsTest_keepLinking);
    defineReflectiveTests(MacroDeclarationsTest_fromBytes);
    defineReflectiveTests(MacroDefinitionTest_keepLinking);
    defineReflectiveTests(MacroDefinitionTest_fromBytes);
    defineReflectiveTests(MacroElementsTest_keepLinking);
    defineReflectiveTests(MacroElementsTest_fromBytes);
    defineReflectiveTests(MacroApplicationOrderTest_keepLinking);
    defineReflectiveTests(MacroApplicationOrderTest_fromBytes);
    defineReflectiveTests(MacroCodeGenerationTest);
    defineReflectiveTests(MacroStaticTypeTest);
    defineReflectiveTests(MacroExampleTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class MacroApplicationOrderTest extends MacroElementsBaseTest {
  @override
  Future<void> setUp() async {
    await super.setUp();

    newFile(
      '$testPackageLibPath/order.dart',
      _getMacroCode('order.dart'),
    );
  }

  test_declarations_class_constructorsOf_alreadyDone() async {
    var library = await buildLibrary(r'''
import 'append.dart';
import 'order.dart';

@DeclareInType('  A1.named12();')
class A1 {
  A1.named11();
}

@DeclarationsIntrospectConstructors('A1')
class A2 {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

augment class A1 {
  A1.named12();
}
augment class A2 {
  void introspected_A1_named11();
  void introspected_A1_named12();
}
''');
  }

  test_declarations_class_constructorsOf_cycle2() async {
    var library = await buildLibrary(r'''
import 'order.dart';

@DeclarationsIntrospectConstructors('A2')
class A1 {}

@DeclarationsIntrospectConstructors('A1')
class A2 {}

@DeclarationsIntrospectConstructors('A1')
@DeclarationsIntrospectConstructors('A2')
class A3 {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;

    // Note, the errors are also reported when introspecting `A1` and `A2`
    // during running macro applications on `A3`, because we know that
    // `A1` and `A2` declarations are incomplete.
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/order.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/order.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A1 @70
          reference: <testLibraryFragment>::@class::A1
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            DeclarationsIntrospectionCycleDiagnostic
              annotationIndex: 0
              introspectedElement: <testLibraryFragment>::@class::A2
              components
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A1
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A2
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A2
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A1
        class A2 @125
          reference: <testLibraryFragment>::@class::A2
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            DeclarationsIntrospectionCycleDiagnostic
              annotationIndex: 0
              introspectedElement: <testLibraryFragment>::@class::A1
              components
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A1
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A2
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A2
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A1
        class A3 @222
          reference: <testLibraryFragment>::@class::A3
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            DeclarationsIntrospectionCycleDiagnostic
              annotationIndex: 1
              introspectedElement: <testLibraryFragment>::@class::A2
              components
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A1
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A2
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A2
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A1
            DeclarationsIntrospectionCycleDiagnostic
              annotationIndex: 0
              introspectedElement: <testLibraryFragment>::@class::A1
              components
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A1
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A2
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A2
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/order.dart
      classes
        class A1 @70
          reference: <testLibraryFragment>::@class::A1
          element: <testLibraryFragment>::@class::A1#element
        class A2 @125
          reference: <testLibraryFragment>::@class::A2
          element: <testLibraryFragment>::@class::A2#element
        class A3 @222
          reference: <testLibraryFragment>::@class::A3
          element: <testLibraryFragment>::@class::A3#element
  classes
    class A1
      firstFragment: <testLibraryFragment>::@class::A1
    class A2
      firstFragment: <testLibraryFragment>::@class::A2
    class A3
      firstFragment: <testLibraryFragment>::@class::A3
''');
  }

  test_declarations_class_constructorsOf_notYetDone() async {
    var library = await buildLibrary(r'''
import 'append.dart';
import 'order.dart';

@DeclarationsIntrospectConstructors('A2')
class A1 {
}

@DeclareInType('  A2.named23();')
class A2 {
  @DeclareInType('  A2.named22();')
  A2.named21();
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

augment class A2 {
  A2.named22();
  A2.named23();
}
augment class A1 {
  void introspected_A2_named21();
  void introspected_A2_named22();
  void introspected_A2_named23();
}
''');
  }

  test_declarations_class_fieldsOf_alreadyDone() async {
    var library = await buildLibrary(r'''
import 'append.dart';
import 'order.dart';

@DeclareInType('  int f12 = 0;')
class A1 {
  int f11 = 0;
}

@DeclarationsIntrospectFields('A1')
class A2 {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

augment class A1 {
  int f12 = 0;
}
augment class A2 {
  void introspected_A1_f11();
  void introspected_A1_f12();
}
''');
  }

  test_declarations_class_fieldsOf_cycle2() async {
    var library = await buildLibrary(r'''
import 'order.dart';

@DeclarationsIntrospectFields('A2')
class A1 {}

@DeclarationsIntrospectFields('A1')
class A2 {}

@DeclarationsIntrospectFields('A1')
@DeclarationsIntrospectFields('A2')
class A3 {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/order.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/order.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A1 @64
          reference: <testLibraryFragment>::@class::A1
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            DeclarationsIntrospectionCycleDiagnostic
              annotationIndex: 0
              introspectedElement: <testLibraryFragment>::@class::A2
              components
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A1
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A2
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A2
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A1
        class A2 @113
          reference: <testLibraryFragment>::@class::A2
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            DeclarationsIntrospectionCycleDiagnostic
              annotationIndex: 0
              introspectedElement: <testLibraryFragment>::@class::A1
              components
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A1
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A2
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A2
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A1
        class A3 @198
          reference: <testLibraryFragment>::@class::A3
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            DeclarationsIntrospectionCycleDiagnostic
              annotationIndex: 1
              introspectedElement: <testLibraryFragment>::@class::A2
              components
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A1
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A2
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A2
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A1
            DeclarationsIntrospectionCycleDiagnostic
              annotationIndex: 0
              introspectedElement: <testLibraryFragment>::@class::A1
              components
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A1
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A2
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A2
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/order.dart
      classes
        class A1 @64
          reference: <testLibraryFragment>::@class::A1
          element: <testLibraryFragment>::@class::A1#element
        class A2 @113
          reference: <testLibraryFragment>::@class::A2
          element: <testLibraryFragment>::@class::A2#element
        class A3 @198
          reference: <testLibraryFragment>::@class::A3
          element: <testLibraryFragment>::@class::A3#element
  classes
    class A1
      firstFragment: <testLibraryFragment>::@class::A1
    class A2
      firstFragment: <testLibraryFragment>::@class::A2
    class A3
      firstFragment: <testLibraryFragment>::@class::A3
''');
  }

  test_declarations_class_fieldsOf_notYetDone() async {
    var library = await buildLibrary(r'''
import 'append.dart';
import 'order.dart';

@DeclarationsIntrospectFields('A2')
class A1 {}

@DeclareInType('  int f23 = 0;')
class A2 {
  @DeclareInType('  int f22 = 0;')
  int f21 = 0;
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

augment class A2 {
  int f22 = 0;
  int f23 = 0;
}
augment class A1 {
  void introspected_A2_f21();
  void introspected_A2_f22();
  void introspected_A2_f23();
}
''');
  }

  test_declarations_class_methodsOf_alreadyDone() async {
    var library = await buildLibrary(r'''
import 'append.dart';
import 'order.dart';

@DeclareInType('  void f12() {}')
class A1 {
  void f11() {}
}

@DeclarationsIntrospectMethods('A1')
class A2 {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

augment class A1 {
  void f12() {}
}
augment class A2 {
  void introspected_A1_f11();
  void introspected_A1_f12();
}
''');
  }

  test_declarations_class_methodsOf_cycle2() async {
    var library = await buildLibrary(r'''
import 'order.dart';

@DeclarationsIntrospectMethods('A2')
class A1 {}

@DeclarationsIntrospectMethods('A1')
class A2 {}

@DeclarationsIntrospectMethods('A1')
@DeclarationsIntrospectMethods('A2')
class A3 {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/order.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/order.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A1 @65
          reference: <testLibraryFragment>::@class::A1
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            DeclarationsIntrospectionCycleDiagnostic
              annotationIndex: 0
              introspectedElement: <testLibraryFragment>::@class::A2
              components
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A1
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A2
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A2
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A1
        class A2 @115
          reference: <testLibraryFragment>::@class::A2
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            DeclarationsIntrospectionCycleDiagnostic
              annotationIndex: 0
              introspectedElement: <testLibraryFragment>::@class::A1
              components
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A1
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A2
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A2
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A1
        class A3 @202
          reference: <testLibraryFragment>::@class::A3
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            DeclarationsIntrospectionCycleDiagnostic
              annotationIndex: 1
              introspectedElement: <testLibraryFragment>::@class::A2
              components
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A1
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A2
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A2
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A1
            DeclarationsIntrospectionCycleDiagnostic
              annotationIndex: 0
              introspectedElement: <testLibraryFragment>::@class::A1
              components
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A1
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A2
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A2
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A1
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/order.dart
      classes
        class A1 @65
          reference: <testLibraryFragment>::@class::A1
          element: <testLibraryFragment>::@class::A1#element
        class A2 @115
          reference: <testLibraryFragment>::@class::A2
          element: <testLibraryFragment>::@class::A2#element
        class A3 @202
          reference: <testLibraryFragment>::@class::A3
          element: <testLibraryFragment>::@class::A3#element
  classes
    class A1
      firstFragment: <testLibraryFragment>::@class::A1
    class A2
      firstFragment: <testLibraryFragment>::@class::A2
    class A3
      firstFragment: <testLibraryFragment>::@class::A3
''');
  }

  test_declarations_class_methodsOf_cycle2_withHead() async {
    var library = await buildLibrary(r'''
import 'order.dart';

@DeclarationsIntrospectMethods('A2')
class A1 {}

@DeclarationsIntrospectMethods('A3')
class A2 {}

@DeclarationsIntrospectMethods('A2')
class A3 {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/order.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/order.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A1 @65
          reference: <testLibraryFragment>::@class::A1
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            DeclarationsIntrospectionCycleDiagnostic
              annotationIndex: 0
              introspectedElement: <testLibraryFragment>::@class::A2
              components
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A2
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A3
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A3
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A2
        class A2 @115
          reference: <testLibraryFragment>::@class::A2
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            DeclarationsIntrospectionCycleDiagnostic
              annotationIndex: 0
              introspectedElement: <testLibraryFragment>::@class::A3
              components
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A2
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A3
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A3
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A2
        class A3 @165
          reference: <testLibraryFragment>::@class::A3
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            DeclarationsIntrospectionCycleDiagnostic
              annotationIndex: 0
              introspectedElement: <testLibraryFragment>::@class::A2
              components
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A2
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A3
                DeclarationsIntrospectionCycleComponent
                  element: <testLibraryFragment>::@class::A3
                  annotationIndex: 0
                  introspectedElement: <testLibraryFragment>::@class::A2
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/order.dart
      classes
        class A1 @65
          reference: <testLibraryFragment>::@class::A1
          element: <testLibraryFragment>::@class::A1#element
        class A2 @115
          reference: <testLibraryFragment>::@class::A2
          element: <testLibraryFragment>::@class::A2#element
        class A3 @165
          reference: <testLibraryFragment>::@class::A3
          element: <testLibraryFragment>::@class::A3#element
  classes
    class A1
      firstFragment: <testLibraryFragment>::@class::A1
    class A2
      firstFragment: <testLibraryFragment>::@class::A2
    class A3
      firstFragment: <testLibraryFragment>::@class::A3
''');
  }

  test_declarations_class_methodsOf_notYetDone() async {
    var library = await buildLibrary(r'''
import 'append.dart';
import 'order.dart';

@DeclarationsIntrospectMethods('A2')
class A1 {}

@DeclareInType('  void f23() {}')
class A2 {
  @DeclareInType('  void f22() {}')
  void f21() {}
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

augment class A2 {
  void f22() {}
  void f23() {}
}
augment class A1 {
  void introspected_A2_f21();
  void introspected_A2_f22();
  void introspected_A2_f23();
}
''');
  }

  test_declarations_class_methodsOf_self() async {
    var library = await buildLibrary(r'''
import 'order.dart';

@DeclarationsIntrospectMethods('A')
class A {
  void foo() {}
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

augment class A {
  void introspected_A_foo();
}
''');
  }

  test_phases_class_types_declarations() async {
    var library = await buildLibrary(r'''
import 'order.dart';

@AddClass('A1')
@AddFunction('f1')
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

class A1 {}
void f1() {}
''');
  }

  test_types_class_method_rightToLeft() async {
    var library = await buildLibrary(r'''
import 'order.dart';

class X {
  @AddClass('A1')
  @AddClass('A2')
  void foo() {}
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

class A2 {}
class A1 {}
''');
  }

  test_types_class_method_sourceOrder() async {
    var library = await buildLibrary(r'''
import 'order.dart';

class X {
  @AddClass('A1')
  void foo() {}

  @AddClass('A2')
  void bar() {}
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

class A1 {}
class A2 {}
''');
  }

  test_types_class_rightToLeft() async {
    var library = await buildLibrary(r'''
import 'order.dart';

@AddClass('A1')
@AddClass('A2')
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

class A2 {}
class A1 {}
''');
  }

  test_types_class_sourceOrder() async {
    var library = await buildLibrary(r'''
import 'order.dart';

@AddClass('A1')
class X1 {}

@AddClass('A2')
class X2 {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

class A1 {}
class A2 {}
''');
  }

  test_types_enum() async {
    var library = await buildLibrary(r'''
import 'order.dart';

@AddClass('A1')
enum X {
  @AddClass('A2')
  v1,
  @AddClass('A3')
  v2;
  @AddClass('A4')
  void foo() {}
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

class A2 {}
class A3 {}
class A4 {}
class A1 {}
''');
  }

  test_types_innerBeforeOuter_class_method() async {
    var library = await buildLibrary(r'''
import 'order.dart';

@AddClass('A1')
class X {
  @AddClass('A2')
  void foo() {}
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

class A2 {}
class A1 {}
''');
  }

  test_types_innerBeforeOuter_mixin_method() async {
    var library = await buildLibrary(r'''
import 'order.dart';

@AddClass('A1')
mixin X {
  @AddClass('A2')
  void foo() {}
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

class A2 {}
class A1 {}
''');
  }

  test_types_libraryDirective_last() async {
    var library = await buildLibrary(r'''
@AddClass('A1')
library;

import 'order.dart';

@AddClass('A2')
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

class A2 {}
class A1 {}
''');
  }

  test_types_mixin_method_rightToLeft() async {
    var library = await buildLibrary(r'''
import 'order.dart';

mixin X {
  @AddClass('A1')
  @AddClass('A2')
  void foo() {}
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

class A2 {}
class A1 {}
''');
  }

  test_types_mixin_method_sourceOrder() async {
    var library = await buildLibrary(r'''
import 'order.dart';

mixin X {
  @AddClass('A1')
  void foo() {}

  @AddClass('A2')
  void bar() {}
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

class A1 {}
class A2 {}
''');
  }

  test_types_mixin_rightToLeft() async {
    var library = await buildLibrary(r'''
import 'order.dart';

@AddClass('A1')
@AddClass('A2')
mixin X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

class A2 {}
class A1 {}
''');
  }

  test_types_mixin_sourceOrder() async {
    var library = await buildLibrary(r'''
import 'order.dart';

@AddClass('A1')
mixin X1 {}

@AddClass('A2')
mixin X2 {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

class A1 {}
class A2 {}
''');
  }
}

@reflectiveTest
class MacroApplicationOrderTest_fromBytes extends MacroApplicationOrderTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class MacroApplicationOrderTest_keepLinking extends MacroApplicationOrderTest {
  @override
  bool get keepLinkingLibraries => true;
}

@reflectiveTest
class MacroArgumentsTest extends MacroElementsBaseTest {
  @override
  bool get keepLinkingLibraries => true;

  @TestTimeout(Timeout(Duration(seconds: 60)))
  test_error() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'Object',
        'bar': 'Object',
      },
      constructorParametersCode: '(this.foo, this.bar)',
      argumentsCode: '(0, const Object())',
      hasErrors: true,
      expected: r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/arguments_text.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/arguments_text.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @76
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            ArgumentMacroDiagnostic
              annotationIndex: 0
              argumentIndex: 1
              message: Not supported: InstanceCreationExpressionImpl
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/arguments_text.dart
      classes
        class A @76
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
''',
    );
  }

  test_kind_named_positional() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'List<int>',
        'bar': 'List<double>',
      },
      constructorParametersCode: '(this foo, {required this.bar})',
      argumentsCode: '(bar: [0.1], [2])',
      expected: r'''
foo: List<int> [2]
bar: List<double> [0.1]
''',
    );
  }

  test_kind_optionalNamed() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'int',
        'bar': 'int',
      },
      constructorParametersCode: '({this.foo = -1, this.bar = -2})',
      argumentsCode: '(foo: 1)',
      expected: r'''
foo: int 1
bar: int -2
''',
    );
  }

  test_kind_optionalPositional() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'int',
        'bar': 'int',
      },
      constructorParametersCode: '([this.foo = -1, this.bar = -2])',
      argumentsCode: '(1)',
      expected: r'''
foo: int 1
bar: int -2
''',
    );
  }

  test_kind_requiredNamed() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'int'},
      constructorParametersCode: '({required this.foo})',
      argumentsCode: '(foo: 42)',
      expected: r'''
foo: int 42
''',
    );
  }

  test_kind_requiredPositional() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'int'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(42)',
      expected: r'''
foo: int 42
''',
    );
  }

  test_type_bool() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'bool',
        'bar': 'bool',
      },
      constructorParametersCode: '(this.foo, this.bar)',
      argumentsCode: '(true, false)',
      expected: r'''
foo: bool true
bar: bool false
''',
    );
  }

  test_type_double() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'double'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(1.2)',
      expected: r'''
foo: double 1.2
''',
    );
  }

  test_type_double_negative() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'double'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(-1.2)',
      expected: r'''
foo: double -1.2
''',
    );
  }

  test_type_int() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'int'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(42)',
      expected: r'''
foo: int 42
''',
    );
  }

  test_type_int_negative() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'int'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(-42)',
      expected: r'''
foo: int -42
''',
    );
  }

  test_type_list_int() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'List<int>',
      },
      constructorParametersCode: '(this.foo)',
      argumentsCode: '([0, 1, 2])',
      expected: r'''
foo: List<int> [0, 1, 2]
''',
    );
  }

  test_type_list_intQ() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'List<int?>',
      },
      constructorParametersCode: '(this.foo)',
      argumentsCode: '([0, null, 2])',
      expected: r'''
foo: List<int?> [0, null, 2]
''',
    );
  }

  test_type_list_map_int_string() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'List<Map<int, String>>',
      },
      constructorParametersCode: '(this.foo)',
      argumentsCode: '([{0: "a"}, {1: "b", 2: "c"}])',
      expected: r'''
foo: List<Map<int, String>> [{0: a}, {1: b, 2: c}]
''',
    );
  }

  test_type_list_objectQ() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'List<Object?>',
      },
      constructorParametersCode: '(this.foo)',
      argumentsCode: '([1, 2, true, 3, 4.2])',
      expected: r'''
foo: List<Object?> [1, 2, true, 3, 4.2]
''',
    );
  }

  test_type_map_int_string() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'Map<int, String>',
      },
      constructorParametersCode: '(this.foo)',
      argumentsCode: '({0: "a", 1: "b"})',
      expected: r'''
foo: _Map<int, String> {0: a, 1: b}
''',
    );
  }

  test_type_null() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'Object?'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(null)',
      expected: r'''
foo: Null null
''',
    );
  }

  test_type_set() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'Set<int>',
      },
      constructorParametersCode: '(this.foo)',
      argumentsCode: '({1, 2, 3})',
      expected: r'''
foo: _Set<int> {1, 2, 3}
''',
    );
  }

  test_type_string() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'String'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: "('aaa')",
      expected: r'''
foo: String aaa
''',
    );
  }

  test_type_string_adjacent() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'String'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: "('aaa' 'bbb' 'ccc')",
      expected: r'''
foo: String aaabbbccc
''',
    );
  }

  /// Build a macro with specified [fields], initialized in the constructor
  /// with [constructorParametersCode], and apply this macro  with
  /// [argumentsCode] to an empty class.
  ///
  /// The macro generates exactly one top-level constant `x`, with a textual
  /// dump of the field values. So, we check that the analyzer built these
  /// values, and the macro executor marshalled these values to the running
  /// macro isolate.
  Future<void> _assertTypesPhaseArgumentsText({
    required Map<String, String> fields,
    required String constructorParametersCode,
    required String argumentsCode,
    required String expected,
    bool hasErrors = false,
  }) async {
    var dumpCode = fields.keys.map((name) {
      return "$name: \${$name.runtimeType} \$$name\\\\n";
    }).join();

    newFile('$testPackageLibPath/arguments_text.dart', '''
import 'dart:async';
import 'package:macros/macros.dart';

macro class ArgumentsTextMacro implements ClassTypesMacro {
${fields.entries.map((e) => '  final ${e.value} ${e.key};').join('\n')}

  const ArgumentsTextMacro${constructorParametersCode.trim()};

  FutureOr<void> buildTypesForClass(clazz, builder) {
    builder.declareType(
      'x',
      DeclarationCode.fromString(
        "const x = '$dumpCode';",
      ),
    );
  }
}
''');

    var library = await buildLibrary('''
import 'arguments_text.dart';

@ArgumentsTextMacro$argumentsCode
class A {}
''');

    if (hasErrors) {
      configuration
        ..withConstructors = false
        ..withMetadata = false;
      checkElementText(library, expected);
    } else {
      if (library.allMacroDiagnostics.isNotEmpty) {
        failWithLibraryText(library);
      }

      var x = library.topLevelElements
          .whereType<ConstTopLevelVariableElementImpl>()
          .single;
      expect(x.name, 'x');
      var actual = (x.constantInitializer as SimpleStringLiteral).value;
      if (actual != expected) {
        print('-------- Actual --------');
        print('$actual------------------------');
        NodeTextExpectationsCollector.add(actual);
      }
      expect(actual, expected);
    }
  }
}

@reflectiveTest
class MacroCodeGenerationTest extends MacroElementsBaseTest {
  @override
  bool get keepLinkingLibraries => true;

  @override
  Future<void> setUp() async {
    await super.setUp();

    newFile(
      '$testPackageLibPath/code_generation.dart',
      _getMacroCode('code_generation.dart'),
    );
  }

  test_class_addMethod2_augmentMethod2() async {
    var library = await buildLibrary(r'''
import 'append.dart';

@DeclareInType("""
  @{{package:test/append.dart@AugmentDefinition}}('{}')
  void foo();""")
@DeclareInType("""
  @{{package:test/append.dart@AugmentDefinition}}('{}')
  void bar();""")
class A {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/append.dart' as prefix0;

augment class A {
  @prefix0.AugmentDefinition('{}')
  void bar();
  @prefix0.AugmentDefinition('{}')
  void foo();
  augment void foo() {}
  augment void bar() {}
}
''');
  }

  test_declarationsPhase_metadata_class_type() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

@DeclarationsPhaseAnnotationType()
@A()
class X {}

class A {
  const A();
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/code_generation.dart' as prefix0;
import 'package:test/test.dart' as prefix1;

var x = [prefix0.DeclarationsPhaseAnnotationType, prefix1.A];
''');
  }

  test_declarationsPhase_metadata_class_type_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A();
}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@DeclarationsPhaseAnnotationType()
@A()
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/code_generation.dart' as prefix0;
import 'package:test/a.dart' as prefix1;

var x = [prefix0.DeclarationsPhaseAnnotationType, prefix1.A];
''');
  }

  test_declarationsPhase_metadata_class_type_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A();
}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart' as prefix;

@DeclarationsPhaseAnnotationType()
@prefix.A()
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/code_generation.dart' as prefix0;
import 'package:test/a.dart' as prefix1;

var x = [prefix0.DeclarationsPhaseAnnotationType, prefix1.A];
''');
  }

  test_declarationsPhase_metadata_classAlias() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

@DeclarationsPhaseAnnotationType()
@A()
class X = Object with M;

class A {
  const A();
}

mixin M {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/code_generation.dart' as prefix0;
import 'package:test/test.dart' as prefix1;

var x = [prefix0.DeclarationsPhaseAnnotationType, prefix1.A];
''');
  }

  test_declarationsPhase_metadata_classConstructor() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

class X {
  @DeclarationsPhaseAnnotationType()
  @A()
  X();
}

class A {
  const A();
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/code_generation.dart' as prefix0;
import 'package:test/test.dart' as prefix1;

var x = [prefix0.DeclarationsPhaseAnnotationType, prefix1.A];
''');
  }

  test_declarationsPhase_metadata_classField() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

class X {
  @DeclarationsPhaseAnnotationType()
  @A()
  final foo = 0;
}

class A {
  const A();
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/code_generation.dart' as prefix0;
import 'package:test/test.dart' as prefix1;

var x = [prefix0.DeclarationsPhaseAnnotationType, prefix1.A];
''');
  }

  test_declarationsPhase_metadata_classMethod() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

class X {
  @DeclarationsPhaseAnnotationType()
  @A()
  void foo() {}
}

class A {
  const A();
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/code_generation.dart' as prefix0;
import 'package:test/test.dart' as prefix1;

var x = [prefix0.DeclarationsPhaseAnnotationType, prefix1.A];
''');
  }

  test_declarationsPhase_metadata_enum() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

@DeclarationsPhaseAnnotationType()
@A()
enum X {v}

class A {
  const A();
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/code_generation.dart' as prefix0;
import 'package:test/test.dart' as prefix1;

var x = [prefix0.DeclarationsPhaseAnnotationType, prefix1.A];
''');
  }

  test_declarationsPhase_metadata_extension() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

@DeclarationsPhaseAnnotationType()
@A()
extension X on int {}

class A {
  const A();
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/code_generation.dart' as prefix0;
import 'package:test/test.dart' as prefix1;

var x = [prefix0.DeclarationsPhaseAnnotationType, prefix1.A];
''');
  }

  test_declarationsPhase_metadata_extensionType() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

@DeclarationsPhaseAnnotationType()
@A()
extension type X(int it) {}

class A {
  const A();
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/code_generation.dart' as prefix0;
import 'package:test/test.dart' as prefix1;

var x = [prefix0.DeclarationsPhaseAnnotationType, prefix1.A];
''');
  }

  test_declarationsPhase_metadata_function() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

@DeclarationsPhaseAnnotationType()
@A()
void foo() {}

class A {
  const A();
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/code_generation.dart' as prefix0;
import 'package:test/test.dart' as prefix1;

var x = [prefix0.DeclarationsPhaseAnnotationType, prefix1.A];
''');
  }

  test_declarationsPhase_metadata_mixin() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

@DeclarationsPhaseAnnotationType()
@A()
mixin X {}

class A {
  const A();
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/code_generation.dart' as prefix0;
import 'package:test/test.dart' as prefix1;

var x = [prefix0.DeclarationsPhaseAnnotationType, prefix1.A];
''');
  }

  test_declarationsPhase_metadata_topLevelVariable() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

@DeclarationsPhaseAnnotationType()
@A()
final foo = 0;

class A {
  const A();
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/code_generation.dart' as prefix0;
import 'package:test/test.dart' as prefix1;

var x = [prefix0.DeclarationsPhaseAnnotationType, prefix1.A];
''');
  }

  test_declarationsPhase_metadata_typeAlias() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

@DeclarationsPhaseAnnotationType()
@A()
typedef X = int;

class A {
  const A();
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/code_generation.dart' as prefix0;
import 'package:test/test.dart' as prefix1;

var x = [prefix0.DeclarationsPhaseAnnotationType, prefix1.A];
''');
  }

  test_inferOmittedType_fieldInstance_type() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

class A {
  num? foo = 42;
}

class B extends A {
  @AugmentForOmittedTypes()
  var foo;
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'dart:core' as prefix0;

augment class B {
  augment prefix0.num? foo = 0;
}
''');
  }

  test_inferOmittedType_fieldStatic_type() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

class A {
  @AugmentForOmittedTypes()
  static var foo;
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'dart:core' as prefix0;

augment class A {
  augment static prefix0.dynamic foo = 0;
}
''');
  }

  test_inferOmittedType_function_returnType() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

@AugmentForOmittedTypes()
foo() {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'dart:core' as prefix0;

augment prefix0.dynamic foo() {}
''');
  }

  test_inferOmittedType_functionType_returnType() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

@AugmentForOmittedTypes()
void foo(Function() a) {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'dart:core' as prefix0;

augment void foo(prefix0.dynamic Function() a, ) {}
''');
  }

  test_inferOmittedType_getterInstance_returnType() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

class A {
  int get foo => 0;
}

class B extends A {
  @AugmentForOmittedTypes()
  get foo => 0;
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'dart:core' as prefix0;

augment class B {
  augment prefix0.int get foo {}
}
''');
  }

  test_inferOmittedType_methodInstance_formalParameter() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

class A {
  void foo(int a) {}
}

class B extends A {
  @AugmentForOmittedTypes()
  void foo(a) {}
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'dart:core' as prefix0;

augment class B {
  augment void foo(prefix0.int a, ) {}
}
''');
  }

  test_inferOmittedType_methodInstance_returnType() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

class A {
  int foo() => 0;
}

class B extends A {
  @AugmentForOmittedTypes()
  foo() {}
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'dart:core' as prefix0;

augment class B {
  augment prefix0.int foo() {}
}
''');
  }

  test_inferOmittedType_methodStatic_formalParameter() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

class A {
  @AugmentForOmittedTypes()
  static void foo(a) {}
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'dart:core' as prefix0;

augment class A {
  augment static void foo(prefix0.dynamic a, ) {}
}
''');
  }

  test_inferOmittedType_methodStatic_returnType() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

class A {
  @AugmentForOmittedTypes()
  static foo() {}
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'dart:core' as prefix0;

augment class A {
  augment static prefix0.dynamic foo() {}
}
''');
  }

  test_inferOmittedType_setterInstance_formalParameter() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

class A {
  void set foo(int a) {}
}

class B extends A {
  @AugmentForOmittedTypes()
  void set foo(a) {}
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'dart:core' as prefix0;

augment class B {
  augment void set foo(prefix0.int a, ) {}
}
''');
  }

  test_inferOmittedType_setterInstance_returnType() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

class A {
  @AugmentForOmittedTypes()
  set foo(int _) {}
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'dart:core' as prefix0;

augment class A {
  augment void set foo(prefix0.int _, ) {}
}
''');
  }

  test_inferOmittedType_setterStatic_formalParameter() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

class A {
  @AugmentForOmittedTypes()
  static void set foo(a) {}
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'dart:core' as prefix0;

augment class A {
  augment static void set foo(prefix0.dynamic a, ) {}
}
''');
  }

  test_inferOmittedType_setterStatic_returnType() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

class A {
  @AugmentForOmittedTypes()
  static set foo(int _) {}
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'dart:core' as prefix0;

augment class A {
  augment static void set foo(prefix0.int _, ) {}
}
''');
  }

  test_macroGeneratedFile_existedBeforeLinking() async {
    // See https://github.com/dart-lang/sdk/issues/54713
    // Create `FileState` with the same name as would be macro generated.
    // If we don't have implementation to discard it, we will get exception.
    var macroFile = getFile('$testPackageLibPath/test.macro.dart');
    driverFor(testFile).getFileSync2(macroFile);

    var library = await buildLibrary(r'''
import 'append.dart';

@DeclareTypesPhase('B', 'class B {}')
class A {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

class B {}
''');
  }

  test_resolveIdentifier_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'A')
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class X {
  void doReference() {
    prefix0.A;
  }
}
''');
  }

  test_resolveIdentifier_class_constructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A.named();
}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'A', memberName: 'named')
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class X {
  void doReference() {
    prefix0.A.named;
  }
}
''');
  }

  test_resolveIdentifier_class_constructor_fromPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
class A {
  A.named();
}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'A', memberName: 'named')
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class X {
  void doReference() {
    prefix0.A.named;
  }
}
''');
  }

  test_resolveIdentifier_class_exported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'b.dart';

@ReferenceIdentifier('package:test/b.dart', 'A')
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class X {
  void doReference() {
    prefix0.A;
  }
}
''');
  }

  test_resolveIdentifier_class_field_instance() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo = 0;
}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier(
  'package:test/a.dart',
  'A',
  memberName: 'foo',
  parametersCode: 'dynamic a',
  leadCode: 'a.',
)
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

augment class X {
  void doReference(dynamic a) {
    a.foo;
  }
}
''');
  }

  test_resolveIdentifier_class_field_static() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static int foo = 0;
}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'A', memberName: 'foo')
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class X {
  void doReference() {
    prefix0.A.foo;
  }
}
''');
  }

  test_resolveIdentifier_class_field_static_fromPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
class A {
  static int foo = 0;
}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'A', memberName: 'foo')
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class X {
  void doReference() {
    prefix0.A.foo;
  }
}
''');
  }

  test_resolveIdentifier_class_fromPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
class B {}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'B')
class A {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class A {
  void doReference() {
    prefix0.B;
  }
}
''');
  }

  test_resolveIdentifier_class_getter_instance() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier(
  'package:test/a.dart',
  'A',
  memberName: 'foo',
  parametersCode: 'dynamic a',
  leadCode: 'a.',
)
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

augment class X {
  void doReference(dynamic a) {
    a.foo;
  }
}
''');
  }

  test_resolveIdentifier_class_getter_static() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'A', memberName: 'foo')
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class X {
  void doReference() {
    prefix0.A.foo;
  }
}
''');
  }

  test_resolveIdentifier_class_getter_static_fromPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
class A {
  static int get foo => 0;
}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'A', memberName: 'foo')
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class X {
  void doReference() {
    prefix0.A.foo;
  }
}
''');
  }

  test_resolveIdentifier_class_method_instance() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void foo() {}
}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier(
  'package:test/a.dart',
  'A',
  memberName: 'foo',
  parametersCode: 'dynamic a',
  leadCode: 'a.',
)
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

augment class X {
  void doReference(dynamic a) {
    a.foo;
  }
}
''');
  }

  test_resolveIdentifier_class_method_static() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static void foo() {}
}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'A', memberName: 'foo')
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class X {
  void doReference() {
    prefix0.A.foo;
  }
}
''');
  }

  test_resolveIdentifier_class_method_static_fromPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
class A {
  static void foo() {}
}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'A', memberName: 'foo')
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class X {
  void doReference() {
    prefix0.A.foo;
  }
}
''');
  }

  test_resolveIdentifier_extension() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension A on int {}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'A')
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class X {
  void doReference() {
    prefix0.A;
  }
}
''');
  }

  test_resolveIdentifier_extensionType() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension type A(int it) {}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'A')
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class X {
  void doReference() {
    prefix0.A;
  }
}
''');
  }

  test_resolveIdentifier_formalParameter() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

@ReferenceFirstFormalParameter()
void foo(int a);
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'dart:core' as prefix0;

augment void foo(prefix0.int a, ) {
  a;
}
''');
  }

  test_resolveIdentifier_functionTypeAlias() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef void A();
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'A')
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class X {
  void doReference() {
    prefix0.A;
  }
}
''');
  }

  test_resolveIdentifier_genericTypeAlias() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef A = int;
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'A')
class X {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class X {
  void doReference() {
    prefix0.A;
  }
}
''');
  }

  test_resolveIdentifier_typeParameter() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

@ReferenceFirstTypeParameter()
void foo<T>();
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

augment void foo<T>() {
  T;
}
''');
  }

  test_resolveIdentifier_unit_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo() {}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'foo')
class A {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class A {
  void doReference() {
    prefix0.foo;
  }
}
''');
  }

  test_resolveIdentifier_unit_function_fromPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
void foo() {}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'foo')
class A {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class A {
  void doReference() {
    prefix0.foo;
  }
}
''');
  }

  test_resolveIdentifier_unit_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
int get foo => 0;
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'foo')
class A {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class A {
  void doReference() {
    prefix0.foo;
  }
}
''');
  }

  test_resolveIdentifier_unit_getter_fromPart() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
int get foo => 0;
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'foo')
class A {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class A {
  void doReference() {
    prefix0.foo;
  }
}
''');
  }

  test_resolveIdentifier_unit_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
set foo(int value) {}
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'foo=')
class A {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class A {
  void doReference() {
    prefix0.foo;
  }
}
''');
  }

  test_resolveIdentifier_unit_setter_exported() async {
    newFile('$testPackageLibPath/a.dart', r'''
set foo(int value) {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'b.dart';

@ReferenceIdentifier('package:test/b.dart', 'foo=')
class A {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class A {
  void doReference() {
    prefix0.foo;
  }
}
''');
  }

  test_resolveIdentifier_unit_variable() async {
    newFile('$testPackageLibPath/a.dart', r'''
var foo = 0;
''');

    var library = await buildLibrary(r'''
import 'code_generation.dart';
import 'a.dart';

@ReferenceIdentifier('package:test/a.dart', 'foo')
class A {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class A {
  void doReference() {
    prefix0.foo;
  }
}
''');
  }

  test_toStringAsTypeName_atClass() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

@DefineToStringAsTypeName()
class A {
  String toString();
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'dart:core' as prefix0;

augment class A {
  augment prefix0.String toString() {
    return 'A';
  }
}
''');
  }

  test_toStringAsTypeName_atMethod() async {
    var library = await buildLibrary(r'''
import 'code_generation.dart';

class A {
  @DefineToStringAsTypeName()
  String toString();
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'dart:core' as prefix0;

augment class A {
  augment prefix0.String toString() => 'A';
}
''');
  }
}

abstract class MacroDeclarationsTest extends MacroElementsBaseTest {
  @SkippedTest(reason: 'fails') // TODO(scheglov): fix it
  test_addClass_addMethod_addMethod() async {
    _addSingleMacro('addClass_addMethod_addMethod.dart');

    var library = await buildLibrary(r'''
import 'a.dart';

@AddClassB()
class A {}
''');

    configuration.withConstructors = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement: <testLibrary>
      libraryImports
        package:test/a.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @37
          reference: <testLibraryFragment>::@class::A
          enclosingElement: <testLibraryFragment>
          metadata
            Annotation
              atSign: @ @18
              name: SimpleIdentifier
                token: AddClassB @19
                staticElement: package:test/a.dart::<fragment>::@class::AddClassB
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @28
                rightParenthesis: ) @29
              element: package:test/a.dart::<fragment>::@class::AddClassB::@constructor::new
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement: <testLibrary>
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

@prefix0.AddMethodFoo()
class B {}

augment class B {
  @prefix0.AddMethodBar()
  void foo() {}
  void bar() {}
}
---
      libraryImports
        package:test/a.dart as prefix0 @67
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImportPrefixes
        prefix0 @67
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
          enclosingElement: <testLibrary>
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class B @107
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B
          enclosingElement: <testLibrary>::@fragment::package:test/test.macro.dart
          metadata
            Annotation
              atSign: @ @77
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: prefix0 @78
                  staticElement: <null>
                  staticType: null
                period: . @85
                identifier: SimpleIdentifier
                  token: AddMethodFoo @86
                  staticElement: package:test/a.dart::<fragment>::@class::AddMethodFoo
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@class::AddMethodFoo
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @98
                rightParenthesis: ) @99
              element: package:test/a.dart::<fragment>::@class::AddMethodFoo
          augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B
          augmented
            methods
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@method::bar
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@method::foo
        augment class B @127
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B
          enclosingElement: <testLibrary>::@fragment::package:test/test.macro.dart
          augmentationTarget: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B
          methods
            foo @164
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@method::foo
              enclosingElement: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B
              metadata
                Annotation
                  atSign: @ @133
                  name: PrefixedIdentifier
                    prefix: SimpleIdentifier
                      token: prefix0 @134
                      staticElement: <testLibrary>::@fragment::package:test/test.macro1.dart::@prefix::prefix0
                      staticType: null
                    period: . @141
                    identifier: SimpleIdentifier
                      token: AddMethodBar @142
                      staticElement: package:test/a.dart::<fragment>::@class::AddMethodBar
                      staticType: null
                    staticElement: package:test/a.dart::<fragment>::@class::AddMethodBar
                    staticType: null
                  arguments: ArgumentList
                    leftParenthesis: ( @154
                    rightParenthesis: ) @155
                  element: package:test/a.dart::<fragment>::@class::AddMethodBar::@constructor::new
              returnType: void
            bar @180
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@method::bar
              enclosingElement: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/a.dart
      classes
        class A @37
          reference: <testLibraryFragment>::@class::A
    <testLibrary>::@fragment::package:test/test.macro.dart
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart
      prefixes
        prefix0
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
      classes
        class B @107
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B
          nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B
        class B @127
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B
          previousFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B
  classes
    class A
      reference: <testLibraryFragment>::@class::A
      enclosingElement2: <testLibrary>
      firstFragment: <testLibraryFragment>::@class::A
    class B
      reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B
      enclosingElement2: <testLibrary>
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B
''');
  }

  test_class_constructor_add_fieldFormalParameter() async {
    var library = await buildLibrary(r'''
import 'append.dart';

@DeclareInType('  A.named(this.f);')
class A {
  final int f;
}
''');

    configuration.withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @66
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          fields
            final f @82
              reference: <testLibraryFragment>::@class::A::@field::f
              enclosingElement3: <testLibraryFragment>::@class::A
              type: int
          accessors
            synthetic get f @-1
              reference: <testLibraryFragment>::@class::A::@getter::f
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
          augmented
            fields
              <testLibraryFragment>::@class::A::@field::f
            constructors
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::named
            accessors
              <testLibraryFragment>::@class::A::@getter::f
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

augment class A {
  A.named(this.f);
}
---
      classes
        augment class A @49
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          augmentationTarget: <testLibraryFragment>::@class::A
          constructors
            named @57
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::named
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              periodOffset: 56
              nameEnd: 62
              parameters
                requiredPositional final this.f @68
                  type: int
                  field: <testLibraryFragment>::@class::A::@field::f
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/append.dart
      classes
        class A @66
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          fields
            f @82
              reference: <testLibraryFragment>::@class::A::@field::f
              element: <testLibraryFragment>::@class::A::@field::f#element
              getter2: <testLibraryFragment>::@class::A::@getter::f
          getters
            get f @-1
              reference: <testLibraryFragment>::@class::A::@getter::f
              element: <testLibraryFragment>::@class::A::@getter::f#element
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class A @49
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          element: <testLibraryFragment>::@class::A#element
          previousFragment: <testLibraryFragment>::@class::A
          constructors
            named @57
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::named
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::named#element
              periodOffset: 56
              nameEnd: 62
              formalParameters
                this.f @68
                  element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::named::@parameter::f#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        final f
          firstFragment: <testLibraryFragment>::@class::A::@field::f
          type: int
          getter: <testLibraryFragment>::@class::A::@getter::f#element
      constructors
        named
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::named
          formalParameters
            requiredPositional final f
              type: int
      getters
        synthetic get f
          firstFragment: <testLibraryFragment>::@class::A::@getter::f
''');
  }

  test_class_constructor_add_named() async {
    var library = await buildLibrary(r'''
import 'append.dart';

@DeclareInType('  A.named(int a);')
class A {}
''');

    configuration.withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @65
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          augmented
            constructors
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::named
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

augment class A {
  A.named(int a);
}
---
      classes
        augment class A @49
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          augmentationTarget: <testLibraryFragment>::@class::A
          constructors
            named @57
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::named
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              periodOffset: 56
              nameEnd: 62
              parameters
                requiredPositional a @67
                  type: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/append.dart
      classes
        class A @65
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class A @49
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          element: <testLibraryFragment>::@class::A#element
          previousFragment: <testLibraryFragment>::@class::A
          constructors
            named @57
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::named
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::named#element
              periodOffset: 56
              nameEnd: 62
              formalParameters
                a @67
                  element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::named::@parameter::a#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        named
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::named
          formalParameters
            requiredPositional a
              type: int
''');
  }

  test_class_constructor_add_unnamed() async {
    var library = await buildLibrary(r'''
import 'append.dart';

@DeclareInType('  A(int a);')
class A {}
''');

    configuration.withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @59
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          augmented
            constructors
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::new
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

augment class A {
  A(int a);
}
---
      classes
        augment class A @49
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          augmentationTarget: <testLibraryFragment>::@class::A
          constructors
            @55
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              parameters
                requiredPositional a @61
                  type: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/append.dart
      classes
        class A @59
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class A @49
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          element: <testLibraryFragment>::@class::A#element
          previousFragment: <testLibraryFragment>::@class::A
          constructors
            new @55
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::new
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::new#element
              formalParameters
                a @61
                  element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::new::@parameter::a#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        new
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::new
          formalParameters
            requiredPositional a
              type: int
''');
  }

  test_class_field_add() async {
    var library = await buildLibrary(r'''
import 'append.dart';

@DeclareInType('  int foo = 0;')
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @62
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          augmented
            fields
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
            accessors
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

augment class A {
  int foo = 0;
}
---
      classes
        augment class A @49
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          augmentationTarget: <testLibraryFragment>::@class::A
          fields
            foo @59
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
          accessors
            synthetic get foo @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              returnType: int
            synthetic set foo= @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/append.dart
      classes
        class A @62
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class A @49
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          element: <testLibraryFragment>::@class::A#element
          previousFragment: <testLibraryFragment>::@class::A
          fields
            foo @59
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo#element
              getter2: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
              setter2: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
          getters
            get foo @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo#element
          setters
            set foo= @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo#element
              formalParameters
                _foo @-1
                  element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo::@parameter::_foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
          type: int
          getter: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo#element
          setter: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
      setters
        synthetic set foo=
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
''');
  }

  test_class_getter_add() async {
    var library = await buildLibrary(r'''
import 'append.dart';

@DeclareInType('  int get foo => 0;')
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @67
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          augmented
            fields
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
            accessors
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

augment class A {
  int get foo => 0;
}
---
      classes
        augment class A @49
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          augmentationTarget: <testLibraryFragment>::@class::A
          fields
            synthetic foo @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              type: int
          accessors
            get foo @63
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/append.dart
      classes
        class A @67
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class A @49
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          element: <testLibraryFragment>::@class::A#element
          previousFragment: <testLibraryFragment>::@class::A
          fields
            foo @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo#element
              getter2: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
          getters
            get foo @63
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        synthetic foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
          type: int
          getter: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo#element
      getters
        get foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
''');
  }

  test_class_method_add() async {
    var library = await buildLibrary(r'''
import 'append.dart';

@DeclareInType('  int foo(double a) => 0;')
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @73
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          augmented
            methods
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::foo
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

augment class A {
  int foo(double a) => 0;
}
---
      classes
        augment class A @49
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          augmentationTarget: <testLibraryFragment>::@class::A
          methods
            foo @59
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              parameters
                requiredPositional a @70
                  type: double
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/append.dart
      classes
        class A @73
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class A @49
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          element: <testLibraryFragment>::@class::A#element
          previousFragment: <testLibraryFragment>::@class::A
          methods
            foo @59
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::foo#element
              formalParameters
                a @70
                  element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::foo::@parameter::a#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::foo
          formalParameters
            requiredPositional a
              type: double
''');
  }

  test_class_setter_add() async {
    var library = await buildLibrary(r'''
import 'append.dart';

@DeclareInType('  set foo(int a) {}')
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @67
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          augmented
            fields
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
            accessors
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

augment class A {
  set foo(int a) {}
}
---
      classes
        augment class A @49
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          augmentationTarget: <testLibraryFragment>::@class::A
          fields
            synthetic foo @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              type: int
          accessors
            set foo= @59
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              parameters
                requiredPositional a @67
                  type: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/append.dart
      classes
        class A @67
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class A @49
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          element: <testLibraryFragment>::@class::A#element
          previousFragment: <testLibraryFragment>::@class::A
          fields
            foo @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo#element
              setter2: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
          setters
            set foo= @59
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo#element
              formalParameters
                a @67
                  element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo::@parameter::a#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        synthetic foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
          type: int
          setter: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo#element
      setters
        set foo=
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
          formalParameters
            requiredPositional a
              type: int
''');
  }

  test_codeOptimizer_class_constructor_optionalPositional_defaultValue() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInType('  B([x = {{package:test/a.dart@a}}]);')
class B {}
''');

    configuration
      ..forCodeOptimizer()
      ..withConstructors = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        new
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@constructor::new
          formalParameters
            optionalPositional x
              type: dynamic
''');
  }

  test_codeOptimizer_class_method_optionalPositional_defaultValue() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInType('  void foo([x = {{package:test/a.dart@a}}]) {}')
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      methods
        foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@method::foo
          formalParameters
            optionalPositional x
              type: dynamic
''');
  }

  test_codeOptimizer_class_method_optionalPositional_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInType('  void foo([@{{package:test/a.dart@a}} x]) {}')
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      methods
        foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@method::foo
          formalParameters
            optionalPositional x
              type: dynamic
              metadata
                Annotation
                  atSign: @ @107
                  name: PrefixedIdentifier
                    prefix: SimpleIdentifier
                      token: prefix0 @108
                      staticElement: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
                      element: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
                      staticType: null
                    period: . @115
                    identifier: SimpleIdentifier
                      token: a @116
                      staticElement: package:test/a.dart::<fragment>::@getter::a
                      element: package:test/a.dart::<fragment>::@getter::a#element
                      staticType: null
                    staticElement: package:test/a.dart::<fragment>::@getter::a
                    element: package:test/a.dart::<fragment>::@getter::a#element
                    staticType: null
                  element: package:test/a.dart::<fragment>::@getter::a
                  element2: package:test/a.dart::<fragment>::@getter::a#element
''');
  }

  test_codeOptimizer_class_method_requiredPositional_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInType('  void foo(@{{package:test/a.dart@a}} x) {}')
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      methods
        foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@method::foo
          formalParameters
            requiredPositional x
              type: dynamic
              metadata
                Annotation
                  atSign: @ @106
                  name: PrefixedIdentifier
                    prefix: SimpleIdentifier
                      token: prefix0 @107
                      staticElement: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
                      element: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
                      staticType: null
                    period: . @114
                    identifier: SimpleIdentifier
                      token: a @115
                      staticElement: package:test/a.dart::<fragment>::@getter::a
                      element: package:test/a.dart::<fragment>::@getter::a#element
                      staticType: null
                    staticElement: package:test/a.dart::<fragment>::@getter::a
                    element: package:test/a.dart::<fragment>::@getter::a#element
                    staticType: null
                  element: package:test/a.dart::<fragment>::@getter::a
                  element2: package:test/a.dart::<fragment>::@getter::a#element
''');
  }

  test_codeOptimizer_class_setter_requiredPositional_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInType('  set foo(@{{package:test/a.dart@a}} x) {}')
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      fields
        synthetic foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@field::foo
          type: dynamic
          setter: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@setter::foo#element
      setters
        set foo=
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@setter::foo
          formalParameters
            requiredPositional x
              type: dynamic
              metadata
                Annotation
                  atSign: @ @105
                  name: PrefixedIdentifier
                    prefix: SimpleIdentifier
                      token: prefix0 @106
                      staticElement: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
                      element: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
                      staticType: null
                    period: . @113
                    identifier: SimpleIdentifier
                      token: a @114
                      staticElement: package:test/a.dart::<fragment>::@getter::a
                      element: package:test/a.dart::<fragment>::@getter::a#element
                      staticType: null
                    staticElement: package:test/a.dart::<fragment>::@getter::a
                    element: package:test/a.dart::<fragment>::@getter::a#element
                    staticType: null
                  element: package:test/a.dart::<fragment>::@getter::a
                  element2: package:test/a.dart::<fragment>::@getter::a#element
''');
  }

  test_codeOptimizer_constant_class_field_const() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInType('  static const x = {{package:test/a.dart@a}};')
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      fields
        static const x
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@field::x
          type: int
          getter: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@getter::x#element
      getters
        synthetic static get x
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@getter::x
''');
  }

  test_codeOptimizer_constant_class_field_final_hasConstConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInType('  final x = {{package:test/a.dart@a}};')
class B {
  const B();
}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      fields
        final x
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@field::x
          type: int
          getter: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@getter::x#element
      getters
        synthetic get x
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@getter::x
''');
  }

  test_codeOptimizer_constant_class_field_final_noConstConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInType('  final x = {{package:test/a.dart@a}};')
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      fields
        final x
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@field::x
          type: int
          getter: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@getter::x#element
      getters
        synthetic get x
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@getter::x
''');
  }

  test_codeOptimizer_constant_class_field_namedType() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInType('  static const x = {{package:test/a.dart@A}}<void>;')
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      fields
        static const x
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@field::x
          type: Type
          getter: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@getter::x#element
      getters
        synthetic static get x
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@getter::x
''');
  }

  test_codeOptimizer_constant_topVariable_constant() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInLibrary('const x = {{package:test/a.dart@a}};')
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
  topLevelVariables
    const x
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@topLevelVariable::x
      type: int
      getter: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x#element
  getters
    synthetic static get x
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x
''');
  }

  test_codeOptimizer_constant_topVariable_constant2() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
const b = 0;
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInLibrary('const x = {{package:test/a.dart@a}} + {{package:test/a.dart@b}};')
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
  topLevelVariables
    const x
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@topLevelVariable::x
      type: int
      getter: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x#element
  getters
    synthetic static get x
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x
''');
  }

  test_codeOptimizer_constant_topVariable_constant3() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;

class A {
  const A();
}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInLibrary("""
@{{package:test/a.dart@A}}()
const x = {{package:test/a.dart@a}}, y = {{package:test/a.dart@a}};
""")
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
  topLevelVariables
    const x
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@topLevelVariable::x
      metadata
        Annotation
          atSign: @ @77
          name: PrefixedIdentifier
            prefix: SimpleIdentifier
              token: prefix0 @78
              staticElement: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
              staticType: null
            period: . @85
            identifier: SimpleIdentifier
              token: A @86
              staticElement: package:test/a.dart::<fragment>::@class::A
              element: package:test/a.dart::<fragment>::@class::A#element
              staticType: null
            staticElement: package:test/a.dart::<fragment>::@class::A
            element: package:test/a.dart::<fragment>::@class::A#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @87
            rightParenthesis: ) @88
          element: package:test/a.dart::<fragment>::@class::A::@constructor::new
          element2: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
      type: int
      getter: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x#element
    const y
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@topLevelVariable::y
      metadata
        Annotation
          atSign: @ @77
          name: PrefixedIdentifier
            prefix: SimpleIdentifier
              token: prefix0 @78
              staticElement: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
              staticType: null
            period: . @85
            identifier: SimpleIdentifier
              token: A @86
              staticElement: package:test/a.dart::<fragment>::@class::A
              element: package:test/a.dart::<fragment>::@class::A#element
              staticType: null
            staticElement: package:test/a.dart::<fragment>::@class::A
            element: package:test/a.dart::<fragment>::@class::A#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @87
            rightParenthesis: ) @88
          element: package:test/a.dart::<fragment>::@class::A::@constructor::new
          element2: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
      type: int
      getter: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::y#element
  getters
    synthetic static get x
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x
    synthetic static get y
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::y
''');
  }

  test_codeOptimizer_constant_topVariable_namedType() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInLibrary('const x = {{package:test/a.dart@A}}<void>;')
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
  topLevelVariables
    const x
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@topLevelVariable::x
      type: Type
      getter: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x#element
  getters
    synthetic static get x
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x
''');
  }

  test_codeOptimizer_metadata_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A();
}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareTypesPhase('C', """
@{{package:test/a.dart@A}}()
class C {}""")
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
    class C
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::C
''');
  }

  test_codeOptimizer_metadata_class_constructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A();
}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInType("""
  @{{package:test/a.dart@A}}()
  B.named();""")
class B {}
''');

    configuration
      ..forCodeOptimizer()
      ..withConstructors = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      constructors
        named
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@constructor::named
          metadata
            Annotation
              atSign: @ @97
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: prefix0 @98
                  staticElement: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
                  element: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
                  staticType: null
                period: . @105
                identifier: SimpleIdentifier
                  token: A @106
                  staticElement: package:test/a.dart::<fragment>::@class::A
                  element: package:test/a.dart::<fragment>::@class::A#element
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@class::A
                element: package:test/a.dart::<fragment>::@class::A#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @107
                rightParenthesis: ) @108
              element: package:test/a.dart::<fragment>::@class::A::@constructor::new
              element2: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
''');
  }

  test_codeOptimizer_metadata_class_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A();
}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInType("""
  @{{package:test/a.dart@A}}()
  final int foo = 0;""")
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      fields
        final foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@field::foo
          type: int
          getter: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@getter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@getter::foo
''');
  }

  test_codeOptimizer_metadata_class_field2() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A();
}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInType("""
  @{{package:test/a.dart@A}}()
  final int foo = 0, bar = 1;""")
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      fields
        final foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@field::foo
          type: int
          getter: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@getter::foo#element
        final bar
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@field::bar
          type: int
          getter: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@getter::bar#element
      getters
        synthetic get foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@getter::foo
        synthetic get bar
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@getter::bar
''');
  }

  test_codeOptimizer_metadata_class_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A();
}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInType("""
  @{{package:test/a.dart@A}}()
  int get foo => 0;""")
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      fields
        synthetic foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@field::foo
          type: int
          getter: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@getter::foo#element
      getters
        get foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@getter::foo
          metadata
            Annotation
              atSign: @ @97
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: prefix0 @98
                  staticElement: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
                  element: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
                  staticType: null
                period: . @105
                identifier: SimpleIdentifier
                  token: A @106
                  staticElement: package:test/a.dart::<fragment>::@class::A
                  element: package:test/a.dart::<fragment>::@class::A#element
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@class::A
                element: package:test/a.dart::<fragment>::@class::A#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @107
                rightParenthesis: ) @108
              element: package:test/a.dart::<fragment>::@class::A::@constructor::new
              element2: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
''');
  }

  test_codeOptimizer_metadata_class_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A();
}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInType("""
  @{{package:test/a.dart@A}}()
  void foo() {}""")
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      methods
        foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@method::foo
          metadata
            Annotation
              atSign: @ @97
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: prefix0 @98
                  staticElement: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
                  element: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
                  staticType: null
                period: . @105
                identifier: SimpleIdentifier
                  token: A @106
                  staticElement: package:test/a.dart::<fragment>::@class::A
                  element: package:test/a.dart::<fragment>::@class::A#element
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@class::A
                element: package:test/a.dart::<fragment>::@class::A#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @107
                rightParenthesis: ) @108
              element: package:test/a.dart::<fragment>::@class::A::@constructor::new
              element2: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
''');
  }

  test_codeOptimizer_metadata_class_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A();
}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInType("""
  @{{package:test/a.dart@A}}()
  set foo(int _) {}""")
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
      fields
        synthetic foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@field::foo
          type: int
          setter: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@setter::foo#element
      setters
        set foo=
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B::@setter::foo
          metadata
            Annotation
              atSign: @ @97
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: prefix0 @98
                  staticElement: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
                  element: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
                  staticType: null
                period: . @105
                identifier: SimpleIdentifier
                  token: A @106
                  staticElement: package:test/a.dart::<fragment>::@class::A
                  element: package:test/a.dart::<fragment>::@class::A#element
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@class::A
                element: package:test/a.dart::<fragment>::@class::A#element
                staticType: null
              arguments: ArgumentList
                leftParenthesis: ( @107
                rightParenthesis: ) @108
              element: package:test/a.dart::<fragment>::@class::A::@constructor::new
              element2: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
          formalParameters
            requiredPositional _
              type: int
''');
  }

  test_codeOptimizer_metadata_unit_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A();
}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInLibrary("""
@{{package:test/a.dart@A}}()
void foo() {}""")
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
  functions
    foo
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@function::foo
      metadata
        Annotation
          atSign: @ @77
          name: PrefixedIdentifier
            prefix: SimpleIdentifier
              token: prefix0 @78
              staticElement: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
              staticType: null
            period: . @85
            identifier: SimpleIdentifier
              token: A @86
              staticElement: package:test/a.dart::<fragment>::@class::A
              element: package:test/a.dart::<fragment>::@class::A#element
              staticType: null
            staticElement: package:test/a.dart::<fragment>::@class::A
            element: package:test/a.dart::<fragment>::@class::A#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @87
            rightParenthesis: ) @88
          element: package:test/a.dart::<fragment>::@class::A::@constructor::new
          element2: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
      returnType: void
''');
  }

  test_codeOptimizer_metadata_unit_function_optionalPositional_defaultValue() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInLibrary('void foo([x = {{package:test/a.dart@a}}]) {}')
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
  functions
    foo
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@function::foo
      formalParameters
        optionalPositional x
          type: dynamic
      returnType: void
''');
  }

  test_codeOptimizer_metadata_unit_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A();
}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInLibrary("""
@{{package:test/a.dart@A}}()
int get foo => 0;""")
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
  topLevelVariables
    synthetic foo
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@topLevelVariable::foo
      type: int
      getter: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::foo#element
  getters
    static get foo
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::foo
      metadata
        Annotation
          atSign: @ @77
          name: PrefixedIdentifier
            prefix: SimpleIdentifier
              token: prefix0 @78
              staticElement: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
              staticType: null
            period: . @85
            identifier: SimpleIdentifier
              token: A @86
              staticElement: package:test/a.dart::<fragment>::@class::A
              element: package:test/a.dart::<fragment>::@class::A#element
              staticType: null
            staticElement: package:test/a.dart::<fragment>::@class::A
            element: package:test/a.dart::<fragment>::@class::A#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @87
            rightParenthesis: ) @88
          element: package:test/a.dart::<fragment>::@class::A::@constructor::new
          element2: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
''');
  }

  test_codeOptimizer_metadata_unit_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A();
}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInLibrary("""
@{{package:test/a.dart@A}}()
set foo(int _) {}""")
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
  topLevelVariables
    synthetic foo
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@topLevelVariable::foo
      type: int
      setter: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::foo#element
  setters
    static set foo=
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::foo
      metadata
        Annotation
          atSign: @ @77
          name: PrefixedIdentifier
            prefix: SimpleIdentifier
              token: prefix0 @78
              staticElement: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
              staticType: null
            period: . @85
            identifier: SimpleIdentifier
              token: A @86
              staticElement: package:test/a.dart::<fragment>::@class::A
              element: package:test/a.dart::<fragment>::@class::A#element
              staticType: null
            staticElement: package:test/a.dart::<fragment>::@class::A
            element: package:test/a.dart::<fragment>::@class::A#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @87
            rightParenthesis: ) @88
          element: package:test/a.dart::<fragment>::@class::A::@constructor::new
          element2: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
      formalParameters
        requiredPositional _
          type: int
''');
  }

  test_codeOptimizer_metadata_unit_setter_requiredPositional_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInLibrary('set foo(@{{package:test/a.dart@a}} x) {}')
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
  topLevelVariables
    synthetic foo
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@topLevelVariable::foo
      type: dynamic
      setter: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::foo#element
  setters
    static set foo=
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::foo
      formalParameters
        requiredPositional x
          type: dynamic
          metadata
            Annotation
              atSign: @ @85
              name: PrefixedIdentifier
                prefix: SimpleIdentifier
                  token: prefix0 @86
                  staticElement: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
                  element: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
                  staticType: null
                period: . @93
                identifier: SimpleIdentifier
                  token: a @94
                  staticElement: package:test/a.dart::<fragment>::@getter::a
                  element: package:test/a.dart::<fragment>::@getter::a#element
                  staticType: null
                staticElement: package:test/a.dart::<fragment>::@getter::a
                element: package:test/a.dart::<fragment>::@getter::a#element
                staticType: null
              element: package:test/a.dart::<fragment>::@getter::a
              element2: package:test/a.dart::<fragment>::@getter::a#element
''');
  }

  test_codeOptimizer_metadata_unit_variable() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A();
}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInLibrary("""
@{{package:test/a.dart@A}}()
final foo = 0;""")
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
  topLevelVariables
    final foo
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@topLevelVariable::foo
      metadata
        Annotation
          atSign: @ @77
          name: PrefixedIdentifier
            prefix: SimpleIdentifier
              token: prefix0 @78
              staticElement: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
              staticType: null
            period: . @85
            identifier: SimpleIdentifier
              token: A @86
              staticElement: package:test/a.dart::<fragment>::@class::A
              element: package:test/a.dart::<fragment>::@class::A#element
              staticType: null
            staticElement: package:test/a.dart::<fragment>::@class::A
            element: package:test/a.dart::<fragment>::@class::A#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @87
            rightParenthesis: ) @88
          element: package:test/a.dart::<fragment>::@class::A::@constructor::new
          element2: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
      type: int
      getter: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::foo
''');
  }

  test_codeOptimizer_metadata_unit_variable2() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A();
}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInLibrary("""
@{{package:test/a.dart@A}}()
final foo = 0, bar = 1;""")
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
  topLevelVariables
    final foo
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@topLevelVariable::foo
      metadata
        Annotation
          atSign: @ @77
          name: PrefixedIdentifier
            prefix: SimpleIdentifier
              token: prefix0 @78
              staticElement: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
              staticType: null
            period: . @85
            identifier: SimpleIdentifier
              token: A @86
              staticElement: package:test/a.dart::<fragment>::@class::A
              element: package:test/a.dart::<fragment>::@class::A#element
              staticType: null
            staticElement: package:test/a.dart::<fragment>::@class::A
            element: package:test/a.dart::<fragment>::@class::A#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @87
            rightParenthesis: ) @88
          element: package:test/a.dart::<fragment>::@class::A::@constructor::new
          element2: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
      type: int
      getter: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::foo#element
    final bar
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@topLevelVariable::bar
      metadata
        Annotation
          atSign: @ @77
          name: PrefixedIdentifier
            prefix: SimpleIdentifier
              token: prefix0 @78
              staticElement: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
              staticType: null
            period: . @85
            identifier: SimpleIdentifier
              token: A @86
              staticElement: package:test/a.dart::<fragment>::@class::A
              element: package:test/a.dart::<fragment>::@class::A#element
              staticType: null
            staticElement: package:test/a.dart::<fragment>::@class::A
            element: package:test/a.dart::<fragment>::@class::A#element
            staticType: null
          arguments: ArgumentList
            leftParenthesis: ( @87
            rightParenthesis: ) @88
          element: package:test/a.dart::<fragment>::@class::A::@constructor::new
          element2: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
      type: int
      getter: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::bar#element
  getters
    synthetic static get foo
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::foo
    synthetic static get bar
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::bar
''');
  }

  test_codeOptimizer_metadata_uses_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A(Object _);
}

void foo() {}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareTypesPhase('C', """
@{{package:test/a.dart@A}}({{package:test/a.dart@foo}})
class C {}""")
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
    class C
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::C
''');
  }

  test_codeOptimizer_metadata_uses_namedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A.named();
}

class X<T> {}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareTypesPhase('C', """
@{{package:test/a.dart@A}}.named()
class C {}""")
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
    class C
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::C
''');
  }

  test_codeOptimizer_metadata_uses_namedType() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A(Object _);
}

class X<T> {}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareTypesPhase('C', """
@{{package:test/a.dart@A}}({{package:test/a.dart@X}}<void>)
class C {}""")
class B {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
    class C
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::C
''');
  }

  test_codeOptimizer_namedType_notUniqueImport() async {
    newFile('$testPackageLibPath/a.dart', r'''
class X {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
class X {}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';
import 'b.dart';

@DeclareInLibrary('void foo({{package:test/a.dart@X}} x1, {{package:test/b.dart@X}} x2) {}')
class A {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
    package:test/b.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
  functions
    foo
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@function::foo
      formalParameters
        requiredPositional x1
          type: X
        requiredPositional x2
          type: X
      returnType: void
''');
  }

  test_codeOptimizer_namedType_shadowedLocally() async {
    newFile('$testPackageLibPath/a.dart', r'''
class X {}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInLibrary('void foo({{package:test/a.dart@X}} x) {}')
class A {}

class X {}
''');

    configuration.forCodeOptimizer();
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  parts
    part_0
----------------------------------------
library
  reference: <testLibrary>
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
    class X
      firstFragment: <testLibraryFragment>::@class::X
  functions
    foo
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@function::foo
      formalParameters
        requiredPositional x
          type: X
      returnType: void
''');
  }

  test_libraryCycle_class_constructor_add() async {
    // Checks https://github.com/dart-lang/sdk/issues/55362
    newFile('$testPackageLibPath/a.dart', r'''
import 'append.dart';

// Just to make it a library cycle.
import 'test.dart';

@DeclareInType('  A();')
class A {}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareInType('  B();')
class B {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class B @71
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B
          augmented
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

augment class B {
  B();
}
---
      classes
        augment class B @49
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          augmentationTarget: <testLibraryFragment>::@class::B
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/append.dart
        package:test/a.dart
      classes
        class B @71
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class B @49
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B
          element: <testLibraryFragment>::@class::B#element
          previousFragment: <testLibraryFragment>::@class::B
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
''');
  }

  test_unit_function_add() async {
    var library = await buildLibrary(r'''
import 'append.dart';

@DeclareInLibrary('void foo() {}')
class A {}
''');

    configuration
      ..withConstructors = false
      ..withExportScope = true
      ..withMetadata = false
      ..withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @64
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

void foo() {}
---
      functions
        foo @40
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@function::foo
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          returnType: void
  exportedReferences
    declared <testLibraryFragment>::@class::A
    declared <testLibrary>::@fragment::package:test/test.macro.dart::@function::foo
  exportNamespace
    A: <testLibraryFragment>::@class::A
    foo: <testLibrary>::@fragment::package:test/test.macro.dart::@function::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/append.dart
      classes
        class A @64
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      functions
        foo @40
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@function::foo
          element: <testLibrary>::@fragment::package:test/test.macro.dart::@function::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
  functions
    foo
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@function::foo
      returnType: void
  exportedReferences
    declared <testLibraryFragment>::@class::A
    declared <testLibrary>::@fragment::package:test/test.macro.dart::@function::foo
  exportNamespace
    A: <testLibraryFragment>::@class::A
    foo: <testLibrary>::@fragment::package:test/test.macro.dart::@function::foo
''');
  }

  test_unit_variable_add() async {
    var library = await buildLibrary(r'''
import 'append.dart';

@DeclareInLibrary('final x = 42;')
class A {}
''');

    configuration
      ..withConstructors = false
      ..withExportScope = true
      ..withMetadata = false
      ..withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @64
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

final x = 42;
---
      topLevelVariables
        static final x @41
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@topLevelVariable::x
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          type: int
          shouldUseTypeForInitializerInference: false
          id: variable_0
          getter: getter_0
      accessors
        synthetic static get x @-1
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          returnType: int
          id: getter_0
          variable: variable_0
  exportedReferences
    declared <testLibraryFragment>::@class::A
    declared <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x
  exportNamespace
    A: <testLibraryFragment>::@class::A
    x: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/append.dart
      classes
        class A @64
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      topLevelVariables
        final x @41
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@topLevelVariable::x
          element: <testLibrary>::@fragment::package:test/test.macro.dart::@topLevelVariable::x#element
          getter2: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x
      getters
        get x @-1
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x
          element: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
  topLevelVariables
    final x
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@topLevelVariable::x
      type: int
      getter: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x#element
  getters
    synthetic static get x
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x
  exportedReferences
    declared <testLibraryFragment>::@class::A
    declared <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x
  exportNamespace
    A: <testLibraryFragment>::@class::A
    x: <testLibrary>::@fragment::package:test/test.macro.dart::@accessor::x
''');
  }
}

@reflectiveTest
class MacroDeclarationsTest_fromBytes extends MacroDeclarationsTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class MacroDeclarationsTest_keepLinking extends MacroDeclarationsTest {
  @override
  bool get keepLinkingLibraries => true;
}

abstract class MacroDefinitionTest extends MacroElementsBaseTest {
  test_class_addConstructor_augmentConstructor() async {
    newFile(
      '$testPackageLibPath/a.dart',
      _getMacroCode('add_augment_declaration.dart'),
    );

    var library = await buildLibrary(r'''
import 'a.dart';

@AddConstructor()
class A {}
''');

    configuration.withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @42
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          augmented
            constructors
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructorAugmentation::named
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

augment class A {
  @prefix0.AugmentConstructor()
  A.named();
  augment A.named() { print(42); }
}
---
      libraryImports
        package:test/a.dart as prefix0 @67
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImportPrefixes
        prefix0 @67
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        augment class A @91
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          augmentationTarget: <testLibraryFragment>::@class::A
          constructors
            named @131
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::named
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              periodOffset: 130
              nameEnd: 136
              augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructorAugmentation::named
            augment named @152
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructorAugmentation::named
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              periodOffset: 151
              nameEnd: 157
              augmentationTarget: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::named
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/a.dart
      classes
        class A @42
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart as prefix0 @67
      prefixes
        <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
          fragments: @67
      classes
        class A @91
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          element: <testLibraryFragment>::@class::A#element
          previousFragment: <testLibraryFragment>::@class::A
          constructors
            named @131
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::named
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::named#element
              periodOffset: 130
              nameEnd: 136
              nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructorAugmentation::named
            augment named @152
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructorAugmentation::named
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::named#element
              periodOffset: 151
              nameEnd: 157
              previousFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::named
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        named
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::named
''');
  }

  test_class_addField_augmentField() async {
    newFile(
      '$testPackageLibPath/a.dart',
      _getMacroCode('add_augment_declaration.dart'),
    );

    var library = await buildLibrary(r'''
import 'a.dart';

@AddField()
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false
      ..withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @36
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          augmented
            fields
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@fieldAugmentation::foo
            accessors
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;
import 'dart:core' as prefix1;

augment class A {
  @prefix0.AugmentField()
  prefix1.int foo;
  augment prefix1.int foo = 42;
}
---
      libraryImports
        package:test/a.dart as prefix0 @67
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
        dart:core as prefix1 @98
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImportPrefixes
        prefix0 @67
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
        prefix1 @98
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix1
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        augment class A @122
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          augmentationTarget: <testLibraryFragment>::@class::A
          fields
            foo @166
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              type: int
              id: field_0
              getter: getter_0
              setter: setter_0
              augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@fieldAugmentation::foo
            augment foo @193
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@fieldAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              type: int
              shouldUseTypeForInitializerInference: true
              id: field_1
              augmentationTarget: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
          accessors
            synthetic get foo @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              returnType: int
              id: getter_0
              variable: field_0
            synthetic set foo= @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/a.dart
      classes
        class A @36
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart as prefix0 @67
        dart:core as prefix1 @98
      prefixes
        <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
          fragments: @67
        <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix1
          fragments: @98
      classes
        class A @122
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          element: <testLibraryFragment>::@class::A#element
          previousFragment: <testLibraryFragment>::@class::A
          fields
            foo @166
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@fieldAugmentation::foo
              getter2: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
              setter2: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
            foo @193
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@fieldAugmentation::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
          getters
            get foo @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo#element
          setters
            set foo= @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo#element
              formalParameters
                _foo @-1
                  element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo::@parameter::_foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
          type: int
          getter: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo#element
          setter: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
      setters
        synthetic set foo=
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
''');
  }

  test_class_addGetter_augmentGetter() async {
    newFile(
      '$testPackageLibPath/a.dart',
      _getMacroCode('add_augment_declaration.dart'),
    );

    var library = await buildLibrary(r'''
import 'a.dart';

@AddGetter()
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false
      ..withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @37
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          augmented
            fields
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
            accessors
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getterAugmentation::foo
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;
import 'dart:core' as prefix1;

augment class A {
  @prefix0.AugmentGetter()
  external prefix1.int get foo;
  augment prefix1.int get foo => 42;
}
---
      libraryImports
        package:test/a.dart as prefix0 @67
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
        dart:core as prefix1 @98
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImportPrefixes
        prefix0 @67
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
        prefix1 @98
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix1
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        augment class A @122
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          augmentationTarget: <testLibraryFragment>::@class::A
          fields
            synthetic foo @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              type: int
              id: field_0
              getter: getter_0
          accessors
            external get foo @180
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              returnType: int
              id: getter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getterAugmentation::foo
            augment get foo @211
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              returnType: int
              id: getter_1
              variable: field_0
              augmentationTarget: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/a.dart
      classes
        class A @37
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart as prefix0 @67
        dart:core as prefix1 @98
      prefixes
        <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
          fragments: @67
        <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix1
          fragments: @98
      classes
        class A @122
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          element: <testLibraryFragment>::@class::A#element
          previousFragment: <testLibraryFragment>::@class::A
          fields
            foo @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo#element
              getter2: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
          getters
            get foo @180
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getterAugmentation::foo
            augment get foo @211
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getterAugmentation::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        synthetic foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
          type: int
          getter: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo#element
      getters
        external get foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
''');
  }

  test_class_addMethod_augmentMethod() async {
    newFile(
      '$testPackageLibPath/a.dart',
      _getMacroCode('add_augment_declaration.dart'),
    );

    var library = await buildLibrary(r'''
import 'a.dart';

@AddMethod()
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @37
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          augmented
            methods
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;
import 'dart:core' as prefix1;

augment class A {
  @prefix0.AugmentMethod()
  external prefix1.int foo();
  augment prefix1.int foo() => 42;
}
---
      libraryImports
        package:test/a.dart as prefix0 @67
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
        dart:core as prefix1 @98
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImportPrefixes
        prefix0 @67
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
        prefix1 @98
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix1
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        augment class A @122
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          augmentationTarget: <testLibraryFragment>::@class::A
          methods
            external foo @176
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              returnType: int
              augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::foo
            augment foo @205
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              returnType: int
              augmentationTarget: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/a.dart
      classes
        class A @37
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart as prefix0 @67
        dart:core as prefix1 @98
      prefixes
        <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
          fragments: @67
        <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix1
          fragments: @98
      classes
        class A @122
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          element: <testLibraryFragment>::@class::A#element
          previousFragment: <testLibraryFragment>::@class::A
          methods
            foo @176
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::foo
            augment foo @205
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::foo#element
              previousFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::foo
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        external foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::foo
''');
  }

  test_class_addSetter_augmentSetter() async {
    newFile(
      '$testPackageLibPath/a.dart',
      _getMacroCode('add_augment_declaration.dart'),
    );

    var library = await buildLibrary(r'''
import 'a.dart';

@AddSetter()
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false
      ..withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @37
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          augmented
            fields
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
            accessors
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setterAugmentation::foo
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;
import 'dart:core' as prefix1;

augment class A {
  @prefix0.AugmentSetter()
  external void set foo(prefix1.int value);
  augment void set foo(prefix1.int value, ) { print(42); }
}
---
      libraryImports
        package:test/a.dart as prefix0 @67
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
        dart:core as prefix1 @98
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImportPrefixes
        prefix0 @67
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
        prefix1 @98
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix1
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        augment class A @122
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          augmentationTarget: <testLibraryFragment>::@class::A
          fields
            synthetic foo @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              type: int
              id: field_0
              setter: setter_0
          accessors
            external set foo= @173
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              parameters
                requiredPositional value @189
                  type: int
              returnType: void
              id: setter_0
              variable: field_0
              augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setterAugmentation::foo
            augment set foo= @216
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setterAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              parameters
                requiredPositional value @232
                  type: int
              returnType: void
              id: setter_1
              variable: field_0
              augmentationTarget: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/a.dart
      classes
        class A @37
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart as prefix0 @67
        dart:core as prefix1 @98
      prefixes
        <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
          fragments: @67
        <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix1
          fragments: @98
      classes
        class A @122
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          element: <testLibraryFragment>::@class::A#element
          previousFragment: <testLibraryFragment>::@class::A
          fields
            foo @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo#element
              setter2: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
          setters
            set foo= @173
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo#element
              formalParameters
                value @189
                  element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo::@parameter::value#element
              nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setterAugmentation::foo
            augment set foo= @216
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setterAugmentation::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo#element
              formalParameters
                value @232
                  element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setterAugmentation::foo::@parameter::value#element
              previousFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        synthetic foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@field::foo
          type: int
          setter: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo#element
      setters
        external set foo=
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
          formalParameters
            requiredPositional value
              type: int
''');
  }
}

@reflectiveTest
class MacroDefinitionTest_fromBytes extends MacroDefinitionTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class MacroDefinitionTest_keepLinking extends MacroDefinitionTest {
  @override
  bool get keepLinkingLibraries => true;
}

abstract class MacroElementsBaseTest extends ElementsBaseTest {
  /// We decided that we want to fail, and want to print the library.
  void failWithLibraryText(LibraryElementImpl library) {
    // While developing, we hit unimplemented branches.
    // It is useful to see where, so include stack traces.
    configuration.withMacroStackTraces = true;

    var text = getLibraryText(
      library: library,
      configuration: configuration,
    );
    print('------------------------');
    print('$text------------------------');
    fail('The library text above should have details.');
  }

  @override
  Future<void> setUp() async {
    super.setUp();

    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      macrosEnvironment: MacrosEnvironment.instance,
    );

    newFile(
      '$testPackageLibPath/append.dart',
      _getMacroCode('append.dart'),
    );
  }

  /// Adds `a.dart` with the content from `single/` directory.
  void _addSingleMacro(String fileName) {
    var code = _getMacroCode('single/$fileName');
    newFile('$testPackageLibPath/a.dart', code);
  }

  /// Matches [library]'s generated code against `=> r'''(.+)''';` pattern,
  /// and verifies that the extracted content is [expected].
  void _assertDefinitionsPhaseText(
    LibraryElementImpl library,
    String expected,
  ) {
    if (library.allMacroDiagnostics.isNotEmpty) {
      failWithLibraryText(library);
    }

    var generated = _getMacroGeneratedCode(library);

    var regExp = RegExp(r'=> r"""(.+)""";', dotAll: true);
    var match = regExp.firstMatch(generated);
    var actual = match?.group(1);

    if (actual == null) {
      print('-------- Generated --------');
      print('$generated---------------------------');
      fail('No introspection result.');
    }

    if (actual != expected) {
      print('-------- Actual --------');
      print('$actual------------------------');
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  /// Runs the definitions phase macro that introspects the declaration in
  /// the library [uriStr], with the [name].
  Future<void> _assertIntrospectDefinitionText(
    String leadCode,
    String expected, {
    required String name,
    required String uriStr,
    required bool withUnnamedConstructor,
  }) async {
    var library = await buildLibrary('''
$leadCode

@IntrospectDeclaration(
  uriStr: '$uriStr',
  name: '$name',
  withUnnamedConstructor: $withUnnamedConstructor,
)
void _starter() {}
''');

    _assertDefinitionsPhaseText(library, expected);
  }

  /// Verifies the code of the macro generated augmentation.
  void _assertMacroCode(LibraryElementImpl library, String expected) {
    var actual = _getMacroGeneratedCode(library);
    if (actual != expected) {
      print('-------- Actual --------');
      print('$actual------------------------');
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  String _getMacroCode(String relativePath) {
    var code = MacrosEnvironment.instance.packageAnalyzerFolder
        .getChildAssumingFile('test/src/summary/macro/$relativePath')
        .readAsStringSync();
    return code.replaceAll('/*macro*/', 'macro');
  }

  String _getMacroGeneratedCode(LibraryElementImpl library) {
    if (library.allMacroDiagnostics.isNotEmpty) {
      failWithLibraryText(library);
    }

    return library.units.last.macroGenerated!.code;
  }
}

abstract class MacroElementsTest extends MacroElementsBaseTest {
  @override
  bool get retainDataForTesting => true;

  test_disable_declarationsPhase() async {
    var library = await buildLibrary(r'''
// @dart = 3.2
import 'append.dart';

@DeclareInType('  void foo() {}')
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @78
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @78
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
''');
  }

  test_disable_definitionsPhase() async {
    var library = await buildLibrary(r'''
// @dart = 3.2
import 'append.dart';

class A {
  @AugmentDefinition('{ print(0); }')
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @44
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @93
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @44
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @93
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_disable_typesPhase() async {
    var library = await buildLibrary(r'''
// @dart = 3.2
import 'append.dart';

@DeclareType('B', 'class B {}')
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @76
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @76
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
''');
  }

  test_exportedMacro() async {
    newFile('$testPackageLibPath/a.dart', r'''
export 'append.dart';
''');

    var library = await buildLibrary(r'''
import 'a.dart';

@DeclareType('B', 'class B {}')
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @56
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

class B {}
---
      classes
        class B @41
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/a.dart
      classes
        class A @56
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class B @41
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B
          element: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
    class B
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B
''');
  }

  test_macroApplicationErrors_typesPhase_compileTimeError() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:macros/macros.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    unresolved;
  }
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';

@MyMacro()
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false
      ..macroDiagnosticMessagePatterns = [
        'Macro application failed due to a bug in the macro.',
        'package:test/a.dart',
        'MyMacro',
        'unresolved',
      ];
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @35
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                contains
                  Macro application failed due to a bug in the macro.
                target: ApplicationMacroDiagnosticTarget
                  annotationIndex: 0
              contextMessages
                MacroDiagnosticMessage
                  contains
                    package:test/a.dart
                    MyMacro
                    unresolved
                  target: ApplicationMacroDiagnosticTarget
                    annotationIndex: 0
              severity: error
              correctionMessage: Try reporting the failure to the macro author.
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/a.dart
      classes
        class A @35
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
''');
  }

  test_macroDiagnostics_invalidTarget_wantsClassOrMixin_hasFunction() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@TargetClassOrMixinMacro()
void f() {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      functions
        f @59
          reference: <testLibraryFragment>::@function::f
          enclosingElement3: <testLibraryFragment>
          returnType: void
          macroDiagnostics
            InvalidMacroTargetDiagnostic
              annotationIndex: 0
              supportedKinds
                classType
                mixinType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      functions
        f @59
          reference: <testLibraryFragment>::@function::f
          element: <testLibraryFragment>::@function::f#element
  functions
    f
      firstFragment: <testLibraryFragment>::@function::f
      returnType: void
''');
  }

  test_macroDiagnostics_invalidTarget_wantsClassOrMixin_hasLibrary() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
@TargetClassOrMixinMacro()
library;

import 'diagnostic.dart';
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
  macroDiagnostics
    InvalidMacroTargetDiagnostic
      annotationIndex: 0
      supportedKinds
        classType
        mixinType
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
  macroDiagnostics
    InvalidMacroTargetDiagnostic
      annotationIndex: 0
      supportedKinds
        classType
        mixinType
''');
  }

  test_macroDiagnostics_report_atAnnotation_constructor() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A();
}
''');

    var library = await buildLibrary(r'''
import 'diagnostic.dart';
import 'a.dart';

@ReportAtTargetAnnotation(1)
@A()
class X {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class X @84
          reference: <testLibraryFragment>::@class::X
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: ElementAnnotationMacroDiagnosticTarget
                  element: <testLibraryFragment>::@class::X
                  annotationIndex: 1
              severity: warning
              correctionMessage: Correction message
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
        package:test/a.dart
      classes
        class X @84
          reference: <testLibraryFragment>::@class::X
          element: <testLibraryFragment>::@class::X#element
  classes
    class X
      firstFragment: <testLibraryFragment>::@class::X
''');
  }

  test_macroDiagnostics_report_atAnnotation_identifier() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    var library = await buildLibrary(r'''
import 'diagnostic.dart';
import 'a.dart';

@ReportAtTargetAnnotation(1)
@a
class X {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class X @82
          reference: <testLibraryFragment>::@class::X
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: ElementAnnotationMacroDiagnosticTarget
                  element: <testLibraryFragment>::@class::X
                  annotationIndex: 1
              severity: warning
              correctionMessage: Correction message
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
        package:test/a.dart
      classes
        class X @82
          reference: <testLibraryFragment>::@class::X
          element: <testLibraryFragment>::@class::X#element
  classes
    class X
      firstFragment: <testLibraryFragment>::@class::X
''');
  }

  test_macroDiagnostics_report_atDeclaration_class() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtTargetDeclaration()
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @62
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: ElementMacroDiagnosticTarget
                  element: <testLibraryFragment>::@class::A
              severity: warning
              correctionMessage: Correction message
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @62
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
''');
  }

  test_macroDiagnostics_report_atDeclaration_class_method_typeParameter() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

class A {
  @ReportAtDeclaration([
    'typeParameter 0',
  ])
  void foo<T>() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @97
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              typeParameters
                covariant T @101
                  defaultType: dynamic
              returnType: void
              macroDiagnostics
                MacroDiagnostic
                  message: MacroDiagnosticMessage
                    message: Reported message
                    target: ElementMacroDiagnosticTarget
                      element: T@101
                  severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @97
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
              typeParameters
                T @101
                  element: <not-implemented>
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
          typeParameters
            T
''');
  }

  test_macroDiagnostics_report_atDeclaration_class_typeParameter() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtDeclaration([
  'typeParameter 1',
])
class A<T, U, V> {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @80
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @82
              defaultType: dynamic
            covariant U @85
              defaultType: dynamic
            covariant V @88
              defaultType: dynamic
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: ElementMacroDiagnosticTarget
                  element: U@85
              severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @80
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          typeParameters
            T @82
              element: <not-implemented>
            U @85
              element: <not-implemented>
            V @88
              element: <not-implemented>
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      typeParameters
        T
        U
        V
''');
  }

  test_macroDiagnostics_report_atDeclaration_constructor() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

class A {
  @ReportAtTargetDeclaration()
  A();
}
''');

    configuration.withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            @70
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              macroDiagnostics
                MacroDiagnostic
                  message: MacroDiagnosticMessage
                    message: Reported message
                    target: ElementMacroDiagnosticTarget
                      element: <testLibraryFragment>::@class::A::@constructor::new
                  severity: warning
                  correctionMessage: Correction message
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            new @70
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              macroDiagnostics
                MacroDiagnostic
                  message: MacroDiagnosticMessage
                    message: Reported message
                    target: ElementMacroDiagnosticTarget
                      element: <testLibraryFragment>::@class::A::@constructor::new
                  severity: warning
                  correctionMessage: Correction message
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
''');
  }

  test_macroDiagnostics_report_atDeclaration_field() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

class A {
  @ReportAtTargetDeclaration()
  final int foo = 0;
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          fields
            final foo @80
              reference: <testLibraryFragment>::@class::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              type: int
              shouldUseTypeForInitializerInference: true
              macroDiagnostics
                MacroDiagnostic
                  message: MacroDiagnosticMessage
                    message: Reported message
                    target: ElementMacroDiagnosticTarget
                      element: <testLibraryFragment>::@class::A::@field::foo
                  severity: warning
                  correctionMessage: Correction message
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          fields
            foo @80
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <testLibraryFragment>::@class::A::@field::foo#element
              getter2: <testLibraryFragment>::@class::A::@getter::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              element: <testLibraryFragment>::@class::A::@getter::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        final foo
          firstFragment: <testLibraryFragment>::@class::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@class::A::@getter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@class::A::@getter::foo
''');
  }

  test_macroDiagnostics_report_atDeclaration_function_typeParameter() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtDeclaration([
  'typeParameter 0',
])
void foo<T>() {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      functions
        foo @79
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @83
              defaultType: dynamic
          returnType: void
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: ElementMacroDiagnosticTarget
                  element: T@83
              severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      functions
        foo @79
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
          typeParameters
            T @83
              element: <not-implemented>
  functions
    foo
      firstFragment: <testLibraryFragment>::@function::foo
      typeParameters
        T
      returnType: void
''');
  }

  test_macroDiagnostics_report_atDeclaration_method() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

class A {
  @ReportAtTargetDeclaration()
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @75
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              macroDiagnostics
                MacroDiagnostic
                  message: MacroDiagnosticMessage
                    message: Reported message
                    target: ElementMacroDiagnosticTarget
                      element: <testLibraryFragment>::@class::A::@method::foo
                  severity: warning
                  correctionMessage: Correction message
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @75
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_macroDiagnostics_report_atDeclaration_mixin() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtTargetDeclaration()
mixin A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      mixins
        mixin A @62
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: ElementMacroDiagnosticTarget
                  element: <testLibraryFragment>::@mixin::A
              severity: warning
              correctionMessage: Correction message
          superclassConstraints
            Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      mixins
        mixin A @62
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibraryFragment>::@mixin::A#element
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      superclassConstraints
        Object
''');
  }

  test_macroDiagnostics_report_atDeclaration_mixin_typeParameter() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtDeclaration([
  'typeParameter 0',
])
mixin A<T> {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      mixins
        mixin A @80
          reference: <testLibraryFragment>::@mixin::A
          enclosingElement3: <testLibraryFragment>
          typeParameters
            covariant T @82
              defaultType: dynamic
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: ElementMacroDiagnosticTarget
                  element: T@82
              severity: warning
          superclassConstraints
            Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      mixins
        mixin A @80
          reference: <testLibraryFragment>::@mixin::A
          element: <testLibraryFragment>::@mixin::A#element
          typeParameters
            T @82
              element: <not-implemented>
  mixins
    mixin A
      firstFragment: <testLibraryFragment>::@mixin::A
      typeParameters
        T
      superclassConstraints
        Object
''');
  }

  test_macroDiagnostics_report_atDeclaration_typeAlias_typeParameter() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtDeclaration([
  'typeParameter 0',
])
typedef A<T> = List<T>;
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      typeAliases
        A @82
          reference: <testLibraryFragment>::@typeAlias::A
          typeParameters
            covariant T @84
              defaultType: dynamic
          aliasedType: List<T>
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: ElementMacroDiagnosticTarget
                  element: T@84
              severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      typeAliases
        A @82
          reference: <testLibraryFragment>::@typeAlias::A
          element: <testLibraryFragment>::@typeAlias::A#element
          typeParameters
            T @84
              element: <not-implemented>
  typeAliases
    A
      firstFragment: <testLibraryFragment>::@typeAlias::A
      typeParameters
        T
      aliasedType: List<T>
''');
  }

  test_macroDiagnostics_report_atTarget_method() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtFirstMethod()
class A {
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @56
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: ElementMacroDiagnosticTarget
                  element: <testLibraryFragment>::@class::A::@method::foo
              severity: warning
          methods
            foo @67
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @56
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @67
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_class_extends() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'superclass',
])
class A extends Object {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @78
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: TypeAnnotationMacroDiagnosticTarget
                  ElementTypeLocation
                    element: <testLibraryFragment>::@class::A
                  ExtendsClauseTypeLocation
              severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @78
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_field_type() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

class A {
  @ReportAtTypeAnnotation([
    'variableType',
  ])
  final int foo = 0;
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          fields
            final foo @102
              reference: <testLibraryFragment>::@class::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              type: int
              shouldUseTypeForInitializerInference: true
              macroDiagnostics
                MacroDiagnostic
                  message: MacroDiagnosticMessage
                    message: Reported message
                    target: TypeAnnotationMacroDiagnosticTarget
                      ElementTypeLocation
                        element: <testLibraryFragment>::@class::A::@field::foo
                      VariableTypeLocation
                  severity: warning
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          fields
            foo @102
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <testLibraryFragment>::@class::A::@field::foo#element
              getter2: <testLibraryFragment>::@class::A::@getter::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              element: <testLibraryFragment>::@class::A::@getter::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        final foo
          firstFragment: <testLibraryFragment>::@class::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@class::A::@getter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@class::A::@getter::foo
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_function_formalParameter_named() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'namedFormalParameterType 0',
])
void foo(int a, {String? b, bool? c}) {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      functions
        foo @93
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional a @101
              type: int
            optionalNamed default b @113
              reference: <testLibraryFragment>::@function::foo::@parameter::b
              type: String?
            optionalNamed default c @122
              reference: <testLibraryFragment>::@function::foo::@parameter::c
              type: bool?
          returnType: void
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: TypeAnnotationMacroDiagnosticTarget
                  ElementTypeLocation
                    element: <testLibraryFragment>::@function::foo
                  FormalParameterTypeLocation
                    index: 1
                  VariableTypeLocation
              severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      functions
        foo @93
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
          formalParameters
            a @101
              element: <testLibraryFragment>::@function::foo::@parameter::a#element
            default b @113
              reference: <testLibraryFragment>::@function::foo::@parameter::b
              element: <testLibraryFragment>::@function::foo::@parameter::b#element
            default c @122
              reference: <testLibraryFragment>::@function::foo::@parameter::c
              element: <testLibraryFragment>::@function::foo::@parameter::c#element
  functions
    foo
      firstFragment: <testLibraryFragment>::@function::foo
      formalParameters
        requiredPositional a
          type: int
        optionalNamed b
          firstFragment: <testLibraryFragment>::@function::foo::@parameter::b
          type: String?
        optionalNamed c
          firstFragment: <testLibraryFragment>::@function::foo::@parameter::c
          type: bool?
      returnType: void
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_function_formalParameter_positional() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'positionalFormalParameterType 1',
])
void foo(int a, String b) {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      functions
        foo @98
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional a @106
              type: int
            requiredPositional b @116
              type: String
          returnType: void
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: TypeAnnotationMacroDiagnosticTarget
                  ElementTypeLocation
                    element: <testLibraryFragment>::@function::foo
                  FormalParameterTypeLocation
                    index: 1
                  VariableTypeLocation
              severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      functions
        foo @98
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
          formalParameters
            a @106
              element: <testLibraryFragment>::@function::foo::@parameter::a#element
            b @116
              element: <testLibraryFragment>::@function::foo::@parameter::b#element
  functions
    foo
      firstFragment: <testLibraryFragment>::@function::foo
      formalParameters
        requiredPositional a
          type: int
        requiredPositional b
          type: String
      returnType: void
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_function_returnType() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'returnType',
])
int foo() => 0;
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      functions
        foo @76
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: TypeAnnotationMacroDiagnosticTarget
                  ElementTypeLocation
                    element: <testLibraryFragment>::@function::foo
                  ReturnTypeLocation
              severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      functions
        foo @76
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
  functions
    foo
      firstFragment: <testLibraryFragment>::@function::foo
      returnType: int
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_functionType_formalParameter_named() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'returnType',
  'namedFormalParameterType 1',
])
int Function(bool a, {int b, String c}) foo() => throw 0;
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      functions
        foo @144
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int Function(bool, {int b, String c})
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: TypeAnnotationMacroDiagnosticTarget
                  ElementTypeLocation
                    element: <testLibraryFragment>::@function::foo
                  ReturnTypeLocation
                  FormalParameterTypeLocation
                    index: 2
              severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      functions
        foo @144
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
  functions
    foo
      firstFragment: <testLibraryFragment>::@function::foo
      returnType: int Function(bool, {int b, String c})
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_functionType_formalParameter_positional() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'returnType',
  'positionalFormalParameterType 1',
])
int Function(int a, String b) foo() => throw 0;
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      functions
        foo @139
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int Function(int, String)
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: TypeAnnotationMacroDiagnosticTarget
                  ElementTypeLocation
                    element: <testLibraryFragment>::@function::foo
                  ReturnTypeLocation
                  FormalParameterTypeLocation
                    index: 1
              severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      functions
        foo @139
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
  functions
    foo
      firstFragment: <testLibraryFragment>::@function::foo
      returnType: int Function(int, String)
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_functionType_returnType() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'returnType',
  'returnType',
])
int Function() foo() => throw 0;
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      functions
        foo @103
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int Function()
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: TypeAnnotationMacroDiagnosticTarget
                  ElementTypeLocation
                    element: <testLibraryFragment>::@function::foo
                  ReturnTypeLocation
                  ReturnTypeLocation
              severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      functions
        foo @103
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
  functions
    foo
      firstFragment: <testLibraryFragment>::@function::foo
      returnType: int Function()
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_kind_functionType() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'returnType',
])
void Function() foo() => throw 0;
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      functions
        foo @88
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          returnType: void Function()
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: TypeAnnotationMacroDiagnosticTarget
                  ElementTypeLocation
                    element: <testLibraryFragment>::@function::foo
                  ReturnTypeLocation
              severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      functions
        foo @88
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
  functions
    foo
      firstFragment: <testLibraryFragment>::@function::foo
      returnType: void Function()
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_kind_omittedType_fieldType() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

class A {
  @ReportAtTypeAnnotation([
    'variableType',
  ])
  final foo = 0;
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          fields
            final foo @98
              reference: <testLibraryFragment>::@class::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              type: int
              shouldUseTypeForInitializerInference: false
              macroDiagnostics
                MacroDiagnostic
                  message: MacroDiagnosticMessage
                    message: Reported message
                    target: TypeAnnotationMacroDiagnosticTarget
                      ElementTypeLocation
                        element: <testLibraryFragment>::@class::A::@field::foo
                      VariableTypeLocation
                  severity: warning
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          fields
            foo @98
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <testLibraryFragment>::@class::A::@field::foo#element
              getter2: <testLibraryFragment>::@class::A::@getter::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              element: <testLibraryFragment>::@class::A::@getter::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        final foo
          firstFragment: <testLibraryFragment>::@class::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@class::A::@getter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@class::A::@getter::foo
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_kind_omittedType_formalParameterType() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'positionalFormalParameterType 0',
])
void foo(a) {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      functions
        foo @98
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          parameters
            requiredPositional a @102
              type: dynamic
          returnType: void
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: TypeAnnotationMacroDiagnosticTarget
                  ElementTypeLocation
                    element: <testLibraryFragment>::@function::foo
                  FormalParameterTypeLocation
                    index: 0
                  VariableTypeLocation
              severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      functions
        foo @98
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
          formalParameters
            a @102
              element: <testLibraryFragment>::@function::foo::@parameter::a#element
  functions
    foo
      firstFragment: <testLibraryFragment>::@function::foo
      formalParameters
        requiredPositional a
          type: dynamic
      returnType: void
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_kind_omittedType_functionReturnType() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'returnType',
])
foo() => throw 0;
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      functions
        foo @72
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          returnType: dynamic
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: TypeAnnotationMacroDiagnosticTarget
                  ElementTypeLocation
                    element: <testLibraryFragment>::@function::foo
                  ReturnTypeLocation
              severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      functions
        foo @72
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
  functions
    foo
      firstFragment: <testLibraryFragment>::@function::foo
      returnType: dynamic
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_kind_omittedType_methodReturnType() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

class A {
  @ReportAtTypeAnnotation([
    'returnType',
  ])
  foo() => throw 0;
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @90
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: dynamic
              macroDiagnostics
                MacroDiagnostic
                  message: MacroDiagnosticMessage
                    message: Reported message
                    target: TypeAnnotationMacroDiagnosticTarget
                      ElementTypeLocation
                        element: <testLibraryFragment>::@class::A::@method::foo
                      ReturnTypeLocation
                  severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @90
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_kind_omittedType_topLevelVariableType() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'variableType',
])
final foo = 0;
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      topLevelVariables
        static final foo @80
          reference: <testLibraryFragment>::@topLevelVariable::foo
          enclosingElement3: <testLibraryFragment>
          type: int
          shouldUseTypeForInitializerInference: false
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: TypeAnnotationMacroDiagnosticTarget
                  ElementTypeLocation
                    element: <testLibraryFragment>::@topLevelVariable::foo
                  VariableTypeLocation
              severity: warning
      accessors
        synthetic static get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          enclosingElement3: <testLibraryFragment>
          returnType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      topLevelVariables
        final foo @80
          reference: <testLibraryFragment>::@topLevelVariable::foo
          element: <testLibraryFragment>::@topLevelVariable::foo#element
          getter2: <testLibraryFragment>::@getter::foo
      getters
        get foo @-1
          reference: <testLibraryFragment>::@getter::foo
          element: <testLibraryFragment>::@getter::foo#element
  topLevelVariables
    final foo
      firstFragment: <testLibraryFragment>::@topLevelVariable::foo
      type: int
      getter: <testLibraryFragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: <testLibraryFragment>::@getter::foo
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_kind_recordType() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'returnType',
])
(int, String) foo() => throw 0;
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      functions
        foo @86
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          returnType: (int, String)
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: TypeAnnotationMacroDiagnosticTarget
                  ElementTypeLocation
                    element: <testLibraryFragment>::@function::foo
                  ReturnTypeLocation
              severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      functions
        foo @86
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
  functions
    foo
      firstFragment: <testLibraryFragment>::@function::foo
      returnType: (int, String)
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_kind_typedef_namedType() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

typedef A = List<int>;

@ReportAtTypeAnnotation([
  'returnType',
])
A foo() => throw 0;
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      typeAliases
        A @35
          reference: <testLibraryFragment>::@typeAlias::A
          aliasedType: List<int>
      functions
        foo @98
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          returnType: List<int>
            alias: <testLibraryFragment>::@typeAlias::A
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: TypeAnnotationMacroDiagnosticTarget
                  ElementTypeLocation
                    element: <testLibraryFragment>::@function::foo
                  ReturnTypeLocation
              severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      typeAliases
        A @35
          reference: <testLibraryFragment>::@typeAlias::A
          element: <testLibraryFragment>::@typeAlias::A#element
      functions
        foo @98
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
  typeAliases
    A
      firstFragment: <testLibraryFragment>::@typeAlias::A
      aliasedType: List<int>
  functions
    foo
      firstFragment: <testLibraryFragment>::@function::foo
      returnType: List<int>
        alias: <testLibraryFragment>::@typeAlias::A
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_method_formalParameter_positional() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

class A {
  @ReportAtTypeAnnotation([
    'positionalFormalParameterType 1',
  ])
  void foo(int a, String b) {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @116
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional a @124
                  type: int
                requiredPositional b @134
                  type: String
              returnType: void
              macroDiagnostics
                MacroDiagnostic
                  message: MacroDiagnosticMessage
                    message: Reported message
                    target: TypeAnnotationMacroDiagnosticTarget
                      ElementTypeLocation
                        element: <testLibraryFragment>::@class::A::@method::foo
                      FormalParameterTypeLocation
                        index: 1
                      VariableTypeLocation
                  severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @116
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
              formalParameters
                a @124
                  element: <testLibraryFragment>::@class::A::@method::foo::@parameter::a#element
                b @134
                  element: <testLibraryFragment>::@class::A::@method::foo::@parameter::b#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
          formalParameters
            requiredPositional a
              type: int
            requiredPositional b
              type: String
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_method_returnType() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

class A {
  @ReportAtTypeAnnotation([
    'returnType',
  ])
  int foo() => 0;
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @94
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
              macroDiagnostics
                MacroDiagnostic
                  message: MacroDiagnosticMessage
                    message: Reported message
                    target: TypeAnnotationMacroDiagnosticTarget
                      ElementTypeLocation
                        element: <testLibraryFragment>::@class::A::@method::foo
                      ReturnTypeLocation
                  severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @94
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_namedTypeArgument() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'returnType',
  'namedTypeArgument 1',
])
Map<int, String> foo() {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      functions
        foo @114
          reference: <testLibraryFragment>::@function::foo
          enclosingElement3: <testLibraryFragment>
          returnType: Map<int, String>
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: TypeAnnotationMacroDiagnosticTarget
                  ElementTypeLocation
                    element: <testLibraryFragment>::@function::foo
                  ReturnTypeLocation
                  ListIndexTypeLocation
                    index: 1
              severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      functions
        foo @114
          reference: <testLibraryFragment>::@function::foo
          element: <testLibraryFragment>::@function::foo#element
  functions
    foo
      firstFragment: <testLibraryFragment>::@function::foo
      returnType: Map<int, String>
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_record_namedField() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

class A {
  @ReportAtTypeAnnotation([
    'variableType',
    'namedField 1',
  ])
  final (bool, {int a, String b})? foo = null;
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          fields
            final foo @145
              reference: <testLibraryFragment>::@class::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              type: (bool, {int a, String b})?
              shouldUseTypeForInitializerInference: true
              macroDiagnostics
                MacroDiagnostic
                  message: MacroDiagnosticMessage
                    message: Reported message
                    target: TypeAnnotationMacroDiagnosticTarget
                      ElementTypeLocation
                        element: <testLibraryFragment>::@class::A::@field::foo
                      VariableTypeLocation
                      RecordNamedFieldTypeLocation
                        index: 1
                  severity: warning
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: (bool, {int a, String b})?
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          fields
            foo @145
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <testLibraryFragment>::@class::A::@field::foo#element
              getter2: <testLibraryFragment>::@class::A::@getter::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              element: <testLibraryFragment>::@class::A::@getter::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        final foo
          firstFragment: <testLibraryFragment>::@class::A::@field::foo
          type: (bool, {int a, String b})?
          getter: <testLibraryFragment>::@class::A::@getter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@class::A::@getter::foo
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_record_positionalField() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

class A {
  @ReportAtTypeAnnotation([
    'variableType',
    'positionalField 1',
  ])
  final (int, String)? foo = null;
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          fields
            final foo @138
              reference: <testLibraryFragment>::@class::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              type: (int, String)?
              shouldUseTypeForInitializerInference: true
              macroDiagnostics
                MacroDiagnostic
                  message: MacroDiagnosticMessage
                    message: Reported message
                    target: TypeAnnotationMacroDiagnosticTarget
                      ElementTypeLocation
                        element: <testLibraryFragment>::@class::A::@field::foo
                      VariableTypeLocation
                      RecordPositionalFieldTypeLocation
                        index: 1
                  severity: warning
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: (int, String)?
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          fields
            foo @138
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <testLibraryFragment>::@class::A::@field::foo#element
              getter2: <testLibraryFragment>::@class::A::@getter::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              element: <testLibraryFragment>::@class::A::@getter::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        final foo
          firstFragment: <testLibraryFragment>::@class::A::@field::foo
          type: (int, String)?
          getter: <testLibraryFragment>::@class::A::@getter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@class::A::@getter::foo
''');
  }

  test_macroDiagnostics_report_atTypeAnnotation_typeAlias_aliasedType() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportAtTypeAnnotation([
  'aliasedType',
])
typedef A = List<int>;
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      typeAliases
        A @81
          reference: <testLibraryFragment>::@typeAlias::A
          aliasedType: List<int>
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: TypeAnnotationMacroDiagnosticTarget
                  ElementTypeLocation
                    element: <testLibraryFragment>::@typeAlias::A
                  AliasedTypeLocation
              severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      typeAliases
        A @81
          reference: <testLibraryFragment>::@typeAlias::A
          element: <testLibraryFragment>::@typeAlias::A#element
  typeAliases
    A
      firstFragment: <testLibraryFragment>::@typeAlias::A
      aliasedType: List<int>
''');
  }

  test_macroDiagnostics_report_contextMessages() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportWithContextMessages()
class A {
  void foo() {}
  void bar() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @62
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: ElementMacroDiagnosticTarget
                  element: <testLibraryFragment>::@class::A
              contextMessages
                MacroDiagnosticMessage
                  message: See foo
                  target: ElementMacroDiagnosticTarget
                    element: <testLibraryFragment>::@class::A::@method::foo
                MacroDiagnosticMessage
                  message: See bar
                  target: ElementMacroDiagnosticTarget
                    element: <testLibraryFragment>::@class::A::@method::bar
              severity: warning
              correctionMessage: Correction message
          methods
            foo @73
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
            bar @89
              reference: <testLibraryFragment>::@class::A::@method::bar
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @62
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @73
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
            bar @89
              reference: <testLibraryFragment>::@class::A::@method::bar
              element: <testLibraryFragment>::@class::A::@method::bar#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
        bar
          firstFragment: <testLibraryFragment>::@class::A::@method::bar
''');
  }

  test_macroDiagnostics_report_withoutTarget_error() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportWithoutTargetError()
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @61
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: ApplicationMacroDiagnosticTarget
                  annotationIndex: 0
              severity: error
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @61
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
''');
  }

  test_macroDiagnostics_report_withoutTarget_info() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportWithoutTargetInfo()
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @60
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: ApplicationMacroDiagnosticTarget
                  annotationIndex: 0
              severity: info
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @60
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
''');
  }

  test_macroDiagnostics_report_withoutTarget_warning() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ReportWithoutTargetWarning()
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @63
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Reported message
                target: ApplicationMacroDiagnosticTarget
                  annotationIndex: 0
              severity: warning
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @63
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
''');
  }

  test_macroDiagnostics_throwException_declarationsPhase_class() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ThrowExceptionDeclarationsPhase()
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @68
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Macro application failed due to a bug in the macro.
                target: ApplicationMacroDiagnosticTarget
                  annotationIndex: 0
              contextMessages
                MacroDiagnosticMessage
                  message:
My declarations phase
#0 <cut>
                  target: ApplicationMacroDiagnosticTarget
                    annotationIndex: 0
              severity: error
              correctionMessage: Try reporting the failure to the macro author.
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @68
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
''');
  }

  test_macroDiagnostics_throwException_declarationsPhase_class_constructor() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

class A {
  @ThrowExceptionDeclarationsPhase()
  A();
}
''');

    configuration.withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            @76
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              macroDiagnostics
                MacroDiagnostic
                  message: MacroDiagnosticMessage
                    message: Macro application failed due to a bug in the macro.
                    target: ApplicationMacroDiagnosticTarget
                      annotationIndex: 0
                  contextMessages
                    MacroDiagnosticMessage
                      message:
My declarations phase
#0 <cut>
                      target: ApplicationMacroDiagnosticTarget
                        annotationIndex: 0
                  severity: error
                  correctionMessage: Try reporting the failure to the macro author.
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            new @76
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              macroDiagnostics
                MacroDiagnostic
                  message: MacroDiagnosticMessage
                    message: Macro application failed due to a bug in the macro.
                    target: ApplicationMacroDiagnosticTarget
                      annotationIndex: 0
                  contextMessages
                    MacroDiagnosticMessage
                      message:
My declarations phase
#0 <cut>
                      target: ApplicationMacroDiagnosticTarget
                        annotationIndex: 0
                  severity: error
                  correctionMessage: Try reporting the failure to the macro author.
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
''');
  }

  test_macroDiagnostics_throwException_declarationsPhase_class_field() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

class A {
  @ThrowExceptionDeclarationsPhase()
  int foo = 0;
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          fields
            foo @80
              reference: <testLibraryFragment>::@class::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              type: int
              shouldUseTypeForInitializerInference: true
              macroDiagnostics
                MacroDiagnostic
                  message: MacroDiagnosticMessage
                    message: Macro application failed due to a bug in the macro.
                    target: ApplicationMacroDiagnosticTarget
                      annotationIndex: 0
                  contextMessages
                    MacroDiagnosticMessage
                      message:
My declarations phase
#0 <cut>
                      target: ApplicationMacroDiagnosticTarget
                        annotationIndex: 0
                  severity: error
                  correctionMessage: Try reporting the failure to the macro author.
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
            synthetic set foo= @-1
              reference: <testLibraryFragment>::@class::A::@setter::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          fields
            foo @80
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <testLibraryFragment>::@class::A::@field::foo#element
              getter2: <testLibraryFragment>::@class::A::@getter::foo
              setter2: <testLibraryFragment>::@class::A::@setter::foo
          getters
            get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              element: <testLibraryFragment>::@class::A::@getter::foo#element
          setters
            set foo= @-1
              reference: <testLibraryFragment>::@class::A::@setter::foo
              element: <testLibraryFragment>::@class::A::@setter::foo#element
              formalParameters
                _foo @-1
                  element: <testLibraryFragment>::@class::A::@setter::foo::@parameter::_foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        foo
          firstFragment: <testLibraryFragment>::@class::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@class::A::@getter::foo#element
          setter: <testLibraryFragment>::@class::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@class::A::@getter::foo
      setters
        synthetic set foo=
          firstFragment: <testLibraryFragment>::@class::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
''');
  }

  test_macroDiagnostics_throwException_declarationsPhase_class_method() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

class A {
  @ThrowExceptionDeclarationsPhase()
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @81
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              macroDiagnostics
                MacroDiagnostic
                  message: MacroDiagnosticMessage
                    message: Macro application failed due to a bug in the macro.
                    target: ApplicationMacroDiagnosticTarget
                      annotationIndex: 0
                  contextMessages
                    MacroDiagnosticMessage
                      message:
My declarations phase
#0 <cut>
                      target: ApplicationMacroDiagnosticTarget
                        annotationIndex: 0
                  severity: error
                  correctionMessage: Try reporting the failure to the macro author.
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @33
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @81
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_macroDiagnostics_throwException_definitionsPhase_class() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ThrowExceptionDefinitionsPhase()
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @67
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Macro application failed due to a bug in the macro.
                target: ApplicationMacroDiagnosticTarget
                  annotationIndex: 0
              contextMessages
                MacroDiagnosticMessage
                  message:
My definitions phase
#0 <cut>
                  target: ApplicationMacroDiagnosticTarget
                    annotationIndex: 0
              severity: error
              correctionMessage: Try reporting the failure to the macro author.
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @67
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
''');
  }

  test_macroDiagnostics_throwException_duringInstantiating() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@MacroWithArguments()
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false
      ..macroDiagnosticMessagePatterns = [
        'NoSuchMethodError',
        'Closure call with mismatched arguments',
        'Tried calling: MacroWithArguments.MacroWithArguments()',
      ];
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @55
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            ExceptionMacroDiagnostic
              annotationIndex: 0
              contains
                NoSuchMethodError
                Closure call with mismatched arguments
                Tried calling: MacroWithArguments.MacroWithArguments()
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @55
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
''');
  }

  test_macroDiagnostics_throwException_duringIntrospection() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    LibraryElementImpl library;
    try {
      LibraryMacroApplier.testThrowExceptionIntrospection = true;
      library = await buildLibrary(r'''
import 'diagnostic.dart';

@AskFieldsWillThrow()
class A {}
''');
    } finally {
      LibraryMacroApplier.testThrowExceptionIntrospection = false;
    }

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @55
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            ExceptionMacroDiagnostic
              annotationIndex: 0
              message: Intentional exception
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @55
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
''');
  }

  test_macroDiagnostics_throwException_typesPhase_class() async {
    newFile(
      '$testPackageLibPath/diagnostic.dart',
      _getMacroCode('diagnostic.dart'),
    );

    var library = await buildLibrary(r'''
import 'diagnostic.dart';

@ThrowExceptionTypesPhase()
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/diagnostic.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/diagnostic.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @61
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          macroDiagnostics
            MacroDiagnostic
              message: MacroDiagnosticMessage
                message: Macro application failed due to a bug in the macro.
                target: ApplicationMacroDiagnosticTarget
                  annotationIndex: 0
              contextMessages
                MacroDiagnosticMessage
                  message:
My types phase
#0 <cut>
                  target: ApplicationMacroDiagnosticTarget
                    annotationIndex: 0
              severity: error
              correctionMessage: Try reporting the failure to the macro author.
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/diagnostic.dart
      classes
        class A @61
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
''');
  }

  test_macroFlag_class() async {
    var library = await buildLibrary(r'''
macro class A {}
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        macro class A @12
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @12
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
''');
  }

  test_macroFlag_classAlias() async {
    var library = await buildLibrary(r'''
mixin M {}
macro class A = Object with M;
''');
    checkElementText(library, r'''
library
  reference: <testLibrary>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      classes
        macro class alias A @23
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          supertype: Object
          mixins
            M
          constructors
            synthetic const @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          enclosingElement3: <testLibraryFragment>
          superclassConstraints
            Object
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      classes
        class A @23
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            synthetic const new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
              constantInitializers
                SuperConstructorInvocation
                  superKeyword: super @0
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticElement: dart:core::<fragment>::@class::Object::@constructor::new
                  element: dart:core::<fragment>::@class::Object::@constructor::new#element
      mixins
        mixin M @6
          reference: <testLibraryFragment>::@mixin::M
          element: <testLibraryFragment>::@mixin::M#element
  classes
    class alias A
      firstFragment: <testLibraryFragment>::@class::A
      supertype: Object
      constructors
        synthetic const new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
  mixins
    mixin M
      firstFragment: <testLibraryFragment>::@mixin::M
      superclassConstraints
        Object
''');
  }

  test_merge_m1_setExtends1_m2_addClass2() async {
    var library = await buildLibrary(r'''
import 'append.dart';

class A {}

@DeclareType('C', 'class C {}')
@SetExtendsType('{{package:test/test.dart@A}}', [])
class B {}
''');

    // New `class C` is the first.
    // Augmented `class B` next.
    // Even if applications have different order.
    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
        class B @125
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B
          supertype: A
          augmented
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

import 'package:test/test.dart' as prefix0;

class C {}
augment class B extends prefix0.A {
}
---
      libraryImports
        package:test/test.dart as prefix0 @70
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImportPrefixes
        prefix0 @70
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class C @86
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::C
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
        augment class B @105
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          augmentationTarget: <testLibraryFragment>::@class::B
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
        class B @125
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
          nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/test.dart as prefix0 @70
      prefixes
        <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
          fragments: @70
      classes
        class C @86
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::C
          element: <testLibrary>::@fragment::package:test/test.macro.dart::@class::C#element
        class B @105
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::B
          element: <testLibraryFragment>::@class::B#element
          previousFragment: <testLibraryFragment>::@class::B
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
    class B
      firstFragment: <testLibraryFragment>::@class::B
      supertype: A
    class C
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::C
''');
  }

  test_notAllowedDeclaration_declarations_class() async {
    if (!keepLinkingLibraries) {
      return;
    }
    useEmptyByteStore();

    var library = await buildLibrary(r'''
import 'append.dart';

class A {
  @DeclareInLibrary('class B {}')
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @74
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              macroDiagnostics
                NotAllowedDeclarationDiagnostic
                  annotationIndex: 0
                  phase: declarations
                  nodeRanges: (35, 10)
---
part of 'package:test/test.dart';

class B {}
---
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @74
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');

    assertDriverStateString(testFile, r'''
files
  /home/test/lib/append.dart
    uri: package:test/append.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_9 package:macros/macros.dart
          library_10 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core package:macros/macros.dart
          libraries: library_0
          apiSignature_0
          users: cycle_1
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_0
          library_10 dart:core synthetic
        fileKinds: library_1
        cycle_1
          dependencies: cycle_0 dart:core
          libraries: library_1
          apiSignature_1
      unlinkedKey: k01
libraryCycles
  /home/test/lib/append.dart
    current: cycle_0
      key: k02
    get: []
    put: [k02]
  /home/test/lib/test.dart
    current: cycle_1
      key: k03
    get: []
    put: [k03]
elementFactory
  hasElement
    package:test/append.dart
    package:test/test.dart
''');
  }

  test_notAllowedDeclaration_declarations_enum() async {
    var library = await buildLibrary(r'''
import 'append.dart';

class A {
  @DeclareInLibrary('enum B {v}')
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @74
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              macroDiagnostics
                NotAllowedDeclarationDiagnostic
                  annotationIndex: 0
                  phase: declarations
                  nodeRanges: (35, 10)
---
part of 'package:test/test.dart';

enum B {v}
---
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @74
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_notAllowedDeclaration_declarations_extension() async {
    var library = await buildLibrary(r'''
import 'append.dart';

class A {
  @DeclareInLibrary('extension B on int {}')
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @85
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

extension B on int {}
---
      extensions
        B @45
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@extension::B
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          extendedType: int
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @85
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      extensions
        extension B @45
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@extension::B
          element: <testLibrary>::@fragment::package:test/test.macro.dart::@extension::B#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
  extensions
    extension B
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@extension::B
''');
  }

  test_notAllowedDeclaration_declarations_extensionType() async {
    var library = await buildLibrary(r'''
import 'append.dart';

class A {
  @DeclareInLibrary('extension type B(int it) {}')
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @91
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              macroDiagnostics
                NotAllowedDeclarationDiagnostic
                  annotationIndex: 0
                  phase: declarations
                  nodeRanges: (35, 27)
---
part of 'package:test/test.dart';

extension type B(int it) {}
---
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @91
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_notAllowedDeclaration_declarations_mixin() async {
    var library = await buildLibrary(r'''
import 'append.dart';

class A {
  @DeclareInLibrary('mixin B {}')
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @74
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              macroDiagnostics
                NotAllowedDeclarationDiagnostic
                  annotationIndex: 0
                  phase: declarations
                  nodeRanges: (35, 10)
---
part of 'package:test/test.dart';

mixin B {}
---
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @74
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_notAllowedDeclaration_declarations_typedef() async {
    var library = await buildLibrary(r'''
import 'append.dart';

class A {
  @DeclareInLibrary('typedef B = int;')
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @80
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              macroDiagnostics
                NotAllowedDeclarationDiagnostic
                  annotationIndex: 0
                  phase: declarations
                  nodeRanges: (35, 16)
---
part of 'package:test/test.dart';

typedef B = int;
---
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @80
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_notAllowedDeclaration_definitions_class() async {
    var library = await buildLibrary(r'''
import 'append.dart';

class A {
  @AugmentDefinition(';} class B {}')
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @78
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              macroDiagnostics
                NotAllowedDeclarationDiagnostic
                  annotationIndex: 0
                  phase: definitions
                  nodeRanges: (77, 10)
---
part of 'package:test/test.dart';

augment class A {
  augment void foo() ;} class B {}
}
---
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @78
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_notAllowedDeclaration_definitions_class_constructor() async {
    var library = await buildLibrary(r'''
import 'append.dart';

class A {
  @AugmentDefinition('; A.named();')
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @77
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              macroDiagnostics
                NotAllowedDeclarationDiagnostic
                  annotationIndex: 0
                  phase: definitions
                  nodeRanges: (76, 10)
---
part of 'package:test/test.dart';

augment class A {
  augment void foo() ; A.named();
}
---
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @77
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_notAllowedDeclaration_definitions_class_field() async {
    var library = await buildLibrary(r'''
import 'append.dart';

class A {
  @AugmentDefinition('; int bar = 0;')
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @79
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              macroDiagnostics
                NotAllowedDeclarationDiagnostic
                  annotationIndex: 0
                  phase: definitions
                  nodeRanges: (76, 12)
---
part of 'package:test/test.dart';

augment class A {
  augment void foo() ; int bar = 0;
}
---
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @79
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_notAllowedDeclaration_definitions_class_method() async {
    var library = await buildLibrary(r'''
import 'append.dart';

class A {
  @AugmentDefinition('; void bar() {}')
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @80
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              macroDiagnostics
                NotAllowedDeclarationDiagnostic
                  annotationIndex: 0
                  phase: definitions
                  nodeRanges: (76, 13)
---
part of 'package:test/test.dart';

augment class A {
  augment void foo() ; void bar() {}
}
---
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @80
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_notAllowedDeclaration_definitions_enum() async {
    var library = await buildLibrary(r'''
import 'append.dart';

class A {
  @AugmentDefinition(';} enum B {v}')
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @78
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              macroDiagnostics
                NotAllowedDeclarationDiagnostic
                  annotationIndex: 0
                  phase: definitions
                  nodeRanges: (77, 10)
---
part of 'package:test/test.dart';

augment class A {
  augment void foo() ;} enum B {v}
}
---
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @78
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_notAllowedDeclaration_definitions_enum_constants() async {
    var library = await buildLibrary(r'''
import 'append.dart';

class A {
  @AugmentDefinition(';} augment enum B {v2}')
  void foo() {}
}

enum B {v}
''');

    configuration
      ..withConstructors = false
      ..withConstantInitializers = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @87
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              macroDiagnostics
                NotAllowedDeclarationDiagnostic
                  annotationIndex: 0
                  phase: definitions
                  nodeRanges: (93, 2)
---
part of 'package:test/test.dart';

augment class A {
  augment void foo() ;} augment enum B {v2}
}
---
      enums
        enum B @104
          reference: <testLibraryFragment>::@enum::B
          enclosingElement3: <testLibraryFragment>
          supertype: Enum
          fields
            static const enumConstant v @107
              reference: <testLibraryFragment>::@enum::B::@field::v
              enclosingElement3: <testLibraryFragment>::@enum::B
              type: B
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: <testLibraryFragment>::@enum::B::@field::values
              enclosingElement3: <testLibraryFragment>::@enum::B
              type: List<B>
          accessors
            synthetic static get v @-1
              reference: <testLibraryFragment>::@enum::B::@getter::v
              enclosingElement3: <testLibraryFragment>::@enum::B
              returnType: B
            synthetic static get values @-1
              reference: <testLibraryFragment>::@enum::B::@getter::values
              enclosingElement3: <testLibraryFragment>::@enum::B
              returnType: List<B>
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @87
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
      enums
        enum B @104
          reference: <testLibraryFragment>::@enum::B
          element: <testLibraryFragment>::@enum::B#element
          fields
            enumConstant v @107
              reference: <testLibraryFragment>::@enum::B::@field::v
              element: <testLibraryFragment>::@enum::B::@field::v#element
              getter2: <testLibraryFragment>::@enum::B::@getter::v
            values @-1
              reference: <testLibraryFragment>::@enum::B::@field::values
              element: <testLibraryFragment>::@enum::B::@field::values#element
              getter2: <testLibraryFragment>::@enum::B::@getter::values
          getters
            get v @-1
              reference: <testLibraryFragment>::@enum::B::@getter::v
              element: <testLibraryFragment>::@enum::B::@getter::v#element
            get values @-1
              reference: <testLibraryFragment>::@enum::B::@getter::values
              element: <testLibraryFragment>::@enum::B::@getter::values#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
  enums
    enum B
      firstFragment: <testLibraryFragment>::@enum::B
      supertype: Enum
      fields
        static const v
          firstFragment: <testLibraryFragment>::@enum::B::@field::v
          type: B
          getter: <testLibraryFragment>::@enum::B::@getter::v#element
        synthetic static const values
          firstFragment: <testLibraryFragment>::@enum::B::@field::values
          type: List<B>
          getter: <testLibraryFragment>::@enum::B::@getter::values#element
      getters
        synthetic static get v
          firstFragment: <testLibraryFragment>::@enum::B::@getter::v
        synthetic static get values
          firstFragment: <testLibraryFragment>::@enum::B::@getter::values
''');
  }

  test_notAllowedDeclaration_definitions_extension() async {
    var library = await buildLibrary(r'''
import 'append.dart';

class A {
  @AugmentDefinition(';} extension B on int {}')
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @89
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              macroDiagnostics
                NotAllowedDeclarationDiagnostic
                  annotationIndex: 0
                  phase: definitions
                  nodeRanges: (77, 21)
---
part of 'package:test/test.dart';

augment class A {
  augment void foo() ;} extension B on int {}
}
---
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @89
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_notAllowedDeclaration_definitions_extensionType() async {
    var library = await buildLibrary(r'''
import 'append.dart';

class A {
  @AugmentDefinition(';} extension type B(int it) {}')
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @95
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              macroDiagnostics
                NotAllowedDeclarationDiagnostic
                  annotationIndex: 0
                  phase: definitions
                  nodeRanges: (77, 27)
---
part of 'package:test/test.dart';

augment class A {
  augment void foo() ;} extension type B(int it) {}
}
---
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @95
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_notAllowedDeclaration_definitions_function_local() async {
    var library = await buildLibrary(r'''
import 'append.dart';

class A {
  @AugmentDefinition('{ void bar() {} }')
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          methods
            foo @82
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::foo
          augmented
            methods
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

augment class A {
  augment void foo() { void bar() {} }
}
---
      classes
        augment class A @49
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          augmentationTarget: <testLibraryFragment>::@class::A
          methods
            augment foo @68
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              returnType: void
              augmentationTarget: <testLibraryFragment>::@class::A::@method::foo
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          methods
            foo @82
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
              nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::foo
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class A @49
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          element: <testLibraryFragment>::@class::A#element
          previousFragment: <testLibraryFragment>::@class::A
          methods
            augment foo @68
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
              previousFragment: <testLibraryFragment>::@class::A::@method::foo
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_notAllowedDeclaration_definitions_function_topLevel() async {
    var library = await buildLibrary(r'''
import 'append.dart';

class A {
  @AugmentDefinition(';} void bar() {}')
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @81
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              macroDiagnostics
                NotAllowedDeclarationDiagnostic
                  annotationIndex: 0
                  phase: definitions
                  nodeRanges: (77, 13)
---
part of 'package:test/test.dart';

augment class A {
  augment void foo() ;} void bar() {}
}
---
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @81
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_notAllowedDeclaration_definitions_mixin() async {
    var library = await buildLibrary(r'''
import 'append.dart';

class A {
  @AugmentDefinition(';} mixin B {}')
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @78
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              macroDiagnostics
                NotAllowedDeclarationDiagnostic
                  annotationIndex: 0
                  phase: definitions
                  nodeRanges: (77, 10)
---
part of 'package:test/test.dart';

augment class A {
  augment void foo() ;} mixin B {}
}
---
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @78
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_notAllowedDeclaration_definitions_topLevelVariable() async {
    var library = await buildLibrary(r'''
import 'append.dart';

class A {
  @AugmentDefinition(';} int bar = 0;')
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @80
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              macroDiagnostics
                NotAllowedDeclarationDiagnostic
                  annotationIndex: 0
                  phase: definitions
                  nodeRanges: (77, 12)
---
part of 'package:test/test.dart';

augment class A {
  augment void foo() ;} int bar = 0;
}
---
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @80
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }

  test_notAllowedDeclaration_definitions_typedef() async {
    var library = await buildLibrary(r'''
import 'append.dart';

class A {
  @AugmentDefinition(';} typedef B = int;')
  void foo() {}
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          methods
            foo @84
              reference: <testLibraryFragment>::@class::A::@method::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: void
              macroDiagnostics
                NotAllowedDeclarationDiagnostic
                  annotationIndex: 0
                  phase: definitions
                  nodeRanges: (77, 16)
---
part of 'package:test/test.dart';

augment class A {
  augment void foo() ;} typedef B = int;
}
---
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      libraryImports
        package:test/append.dart
      classes
        class A @29
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          methods
            foo @84
              reference: <testLibraryFragment>::@class::A::@method::foo
              element: <testLibraryFragment>::@class::A::@method::foo#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      methods
        foo
          firstFragment: <testLibraryFragment>::@class::A::@method::foo
''');
  }
}

@reflectiveTest
class MacroElementsTest_fromBytes extends MacroElementsTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class MacroElementsTest_keepLinking extends MacroElementsTest {
  @override
  bool get keepLinkingLibraries => true;
}

@reflectiveTest
class MacroExampleTest extends MacroElementsBaseTest {
  @override
  bool get keepLinkingLibraries => true;

  test_autoToString() async {
    _addExampleMacro('auto_to_string.dart');

    var library = await buildLibrary(r'''
import 'auto_to_string.dart';

@AutoToString()
class A {
  final int foo;
  final int bar;
  A(this.foo, this.bar);
}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/auto_to_string.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/auto_to_string.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @53
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          fields
            final foo @69
              reference: <testLibraryFragment>::@class::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              type: int
            final bar @86
              reference: <testLibraryFragment>::@class::A::@field::bar
              enclosingElement3: <testLibraryFragment>::@class::A
              type: int
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
            synthetic get bar @-1
              reference: <testLibraryFragment>::@class::A::@getter::bar
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
          augmented
            fields
              <testLibraryFragment>::@class::A::@field::bar
              <testLibraryFragment>::@class::A::@field::foo
            accessors
              <testLibraryFragment>::@class::A::@getter::bar
              <testLibraryFragment>::@class::A::@getter::foo
            methods
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::toString
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

import 'dart:core' as prefix0;

augment class A {
  @prefix0.override
  prefix0.String toString();
  augment prefix0.String toString() {
    // You can add breakpoints here!
    return """
A {
  foo: ${this.foo}
  bar: ${this.bar}
}""";
  }
}
---
      libraryImports
        dart:core as prefix0 @57
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImportPrefixes
        prefix0 @57
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        augment class A @81
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          augmentationTarget: <testLibraryFragment>::@class::A
          methods
            abstract toString @122
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::toString
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              returnType: String
              augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::toString
            augment toString @159
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::toString
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              returnType: String
              augmentationTarget: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::toString
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/auto_to_string.dart
      classes
        class A @53
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          fields
            foo @69
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <testLibraryFragment>::@class::A::@field::foo#element
              getter2: <testLibraryFragment>::@class::A::@getter::foo
            bar @86
              reference: <testLibraryFragment>::@class::A::@field::bar
              element: <testLibraryFragment>::@class::A::@field::bar#element
              getter2: <testLibraryFragment>::@class::A::@getter::bar
          getters
            get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              element: <testLibraryFragment>::@class::A::@getter::foo#element
            get bar @-1
              reference: <testLibraryFragment>::@class::A::@getter::bar
              element: <testLibraryFragment>::@class::A::@getter::bar#element
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      libraryImports
        dart:core as prefix0 @57
      prefixes
        <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
          fragments: @57
      classes
        class A @81
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          element: <testLibraryFragment>::@class::A#element
          previousFragment: <testLibraryFragment>::@class::A
          methods
            toString @122
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::toString
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::toString#element
              nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::toString
            augment toString @159
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::toString
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::toString#element
              previousFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::toString
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        final foo
          firstFragment: <testLibraryFragment>::@class::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@class::A::@getter::foo#element
        final bar
          firstFragment: <testLibraryFragment>::@class::A::@field::bar
          type: int
          getter: <testLibraryFragment>::@class::A::@getter::bar#element
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@class::A::@getter::foo
        synthetic get bar
          firstFragment: <testLibraryFragment>::@class::A::@getter::bar
      methods
        toString
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::toString
''');
  }

  test_jsonSerializable() async {
    _addExampleMacro('json_key.dart');
    _addExampleMacro('json_serializable.dart');

    var library = await buildLibrary(r'''
import 'json_serializable.dart';

@JsonSerializable()
class A {
  final int foo;
  final int bar;
}
''');

    configuration.withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/json_serializable.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/json_serializable.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @60
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          fields
            final foo @76
              reference: <testLibraryFragment>::@class::A::@field::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              type: int
            final bar @93
              reference: <testLibraryFragment>::@class::A::@field::bar
              enclosingElement3: <testLibraryFragment>::@class::A
              type: int
          accessors
            synthetic get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
            synthetic get bar @-1
              reference: <testLibraryFragment>::@class::A::@getter::bar
              enclosingElement3: <testLibraryFragment>::@class::A
              returnType: int
          augmented
            fields
              <testLibraryFragment>::@class::A::@field::bar
              <testLibraryFragment>::@class::A::@field::foo
            constructors
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructorAugmentation::fromJson
            accessors
              <testLibraryFragment>::@class::A::@getter::bar
              <testLibraryFragment>::@class::A::@getter::foo
            methods
              <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::toJson
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

import 'package:test/json_serializable.dart' as prefix0;
import 'dart:core' as prefix1;

augment class A {
  @prefix0.FromJson()
  external A.fromJson(prefix1.Map<prefix1.String, prefix1.Object?> json);
  @prefix0.ToJson()
  external prefix1.Map<prefix1.String, prefix1.Object?> toJson();
  augment A.fromJson(prefix1.Map<prefix1.String, prefix1.Object?> json, )
      : this.foo = json['foo'] as prefix1.int,
        this.bar = json['bar'] as prefix1.int;
  augment prefix1.Map<prefix1.String, prefix1.Object?> toJson() {
    var json = <prefix1.String, prefix1.Object?>{};
    json['foo'] = this.foo;
json['bar'] = this.bar;
    return json;
  }
}
---
      libraryImports
        package:test/json_serializable.dart as prefix0 @83
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
        dart:core as prefix1 @114
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImportPrefixes
        prefix0 @83
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
        prefix1 @114
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix1
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        augment class A @138
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          augmentationTarget: <testLibraryFragment>::@class::A
          constructors
            external fromJson @177
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::fromJson
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              periodOffset: 176
              nameEnd: 185
              parameters
                requiredPositional json @231
                  type: Map<String, Object?>
              augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructorAugmentation::fromJson
            augment fromJson @336
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructorAugmentation::fromJson
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              periodOffset: 335
              nameEnd: 344
              parameters
                requiredPositional json @390
                  type: Map<String, Object?>
              augmentationTarget: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::fromJson
          methods
            external toJson @314
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::toJson
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              returnType: Map<String, Object?>
              augmentation: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::toJson
            augment toJson @547
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::toJson
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
              returnType: Map<String, Object?>
              augmentationTarget: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::toJson
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/json_serializable.dart
      classes
        class A @60
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          fields
            foo @76
              reference: <testLibraryFragment>::@class::A::@field::foo
              element: <testLibraryFragment>::@class::A::@field::foo#element
              getter2: <testLibraryFragment>::@class::A::@getter::foo
            bar @93
              reference: <testLibraryFragment>::@class::A::@field::bar
              element: <testLibraryFragment>::@class::A::@field::bar#element
              getter2: <testLibraryFragment>::@class::A::@getter::bar
          getters
            get foo @-1
              reference: <testLibraryFragment>::@class::A::@getter::foo
              element: <testLibraryFragment>::@class::A::@getter::foo#element
            get bar @-1
              reference: <testLibraryFragment>::@class::A::@getter::bar
              element: <testLibraryFragment>::@class::A::@getter::bar#element
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/json_serializable.dart as prefix0 @83
        dart:core as prefix1 @114
      prefixes
        <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
          fragments: @83
        <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix1
          fragments: @114
      classes
        class A @138
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A
          element: <testLibraryFragment>::@class::A#element
          previousFragment: <testLibraryFragment>::@class::A
          constructors
            external fromJson @177
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::fromJson
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::fromJson#element
              periodOffset: 176
              nameEnd: 185
              formalParameters
                json @231
                  element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::fromJson::@parameter::json#element
              nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructorAugmentation::fromJson
            augment fromJson @336
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructorAugmentation::fromJson
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::fromJson#element
              periodOffset: 335
              nameEnd: 344
              formalParameters
                json @390
                  element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructorAugmentation::fromJson::@parameter::json#element
              previousFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::fromJson
          methods
            toJson @314
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::toJson
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::toJson#element
              nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::toJson
            augment toJson @547
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@methodAugmentation::toJson
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::toJson#element
              previousFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::toJson
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      fields
        final foo
          firstFragment: <testLibraryFragment>::@class::A::@field::foo
          type: int
          getter: <testLibraryFragment>::@class::A::@getter::foo#element
        final bar
          firstFragment: <testLibraryFragment>::@class::A::@field::bar
          type: int
          getter: <testLibraryFragment>::@class::A::@getter::bar#element
      constructors
        external fromJson
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@constructor::fromJson
          formalParameters
            requiredPositional json
              type: Map<String, Object?>
      getters
        synthetic get foo
          firstFragment: <testLibraryFragment>::@class::A::@getter::foo
        synthetic get bar
          firstFragment: <testLibraryFragment>::@class::A::@getter::bar
      methods
        external toJson
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@classAugmentation::A::@method::toJson
''');
  }

  test_observable() async {
    _addExampleMacro('observable.dart');

    var library = await buildLibrary(r'''
import 'observable.dart';

class A {
  @Observable()
  int _foo = 0;
}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

import 'dart:core' as prefix0;

augment class A {
  prefix0.int get foo => this._foo;
  set foo(prefix0.int val) {
    prefix0.print('Setting foo to ${val}');
    this._foo = val;
  }
}
''');
  }

  void _addExampleMacro(String fileName) {
    var code = _getMacroCode('example/$fileName');
    newFile('$testPackageLibPath/$fileName', code);
  }
}

@reflectiveTest
class MacroIntrospectElementTest extends MacroElementsBaseTest {
  @override
  bool get keepLinkingLibraries => true;

  test_class_constructor_flags_isFactory() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A();
  factory A.named() => A();
}
''');

    await _assertIntrospectText('A', withUnnamedConstructor: true, r'''
class A
  superclass: Object
  constructors
    <unnamed>
      flags: hasBody hasStatic
      returnType: A
    named
      flags: hasBody hasStatic isFactory
      returnType: A
''');
  }

  test_class_constructor_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;

class A {
  @a
  A();
}
''');

    await _assertIntrospectText('A', withUnnamedConstructor: true, r'''
class A
  superclass: Object
  constructors
    <unnamed>
      flags: hasBody hasStatic
      metadata
        IdentifierMetadataAnnotation
          identifier: a
      returnType: A
''');
  }

  test_class_constructor_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A.named();
}
''');

    await _assertIntrospectText('A', withUnnamedConstructor: true, r'''
class A
  superclass: Object
  constructors
    named
      flags: hasBody hasStatic
      returnType: A
''');
  }

  test_class_constructor_namedParameters() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A({required int a, String? b});
}
''');

    await _assertIntrospectText('A', withUnnamedConstructor: true, r'''
class A
  superclass: Object
  constructors
    <unnamed>
      flags: hasBody hasStatic
      namedParameters
        a
          flags: isNamed isRequired
          type: int
        b
          flags: isNamed
          type: String?
      returnType: A
''');
  }

  test_class_constructor_positionalParameters() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A(int a, [String? b]);
}
''');

    await _assertIntrospectText('A', withUnnamedConstructor: true, r'''
class A
  superclass: Object
  constructors
    <unnamed>
      flags: hasBody hasStatic
      positionalParameters
        a
          flags: isRequired
          type: int
        b
          type: String?
      returnType: A
''');
  }

  test_class_field_flag_hasConst() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const int foo = 0;
}
''');

    await _assertIntrospectText('A', r'''
class A
  superclass: Object
  fields
    foo
      flags: hasConst hasInitializer hasStatic
      type: int
''');
  }

  test_class_field_flag_hasExternal() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  external int foo;
}
''');

    await _assertIntrospectText('A', r'''
class A
  superclass: Object
  fields
    foo
      flags: hasExternal
      type: int
''');
  }

  test_class_field_flag_hasFinal() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int foo = 0;
}
''');

    await _assertIntrospectText('A', r'''
class A
  superclass: Object
  fields
    foo
      flags: hasFinal hasInitializer
      type: int
''');
  }

  test_class_field_flag_hasLate() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  late int foo;
}
''');

    await _assertIntrospectText('A', r'''
class A
  superclass: Object
  fields
    foo
      flags: hasLate
      type: int
''');
  }

  test_class_field_flag_hasStatic() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static int foo = 0;
}
''');

    await _assertIntrospectText('A', r'''
class A
  superclass: Object
  fields
    foo
      flags: hasInitializer hasStatic
      type: int
''');
  }

  test_class_field_metadata_identifier() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;

class A {
  @a
  int? foo;
}
''');

    await _assertIntrospectText('A', r'''
class A
  superclass: Object
  fields
    foo
      metadata
        IdentifierMetadataAnnotation
          identifier: a
      type: int?
''');
  }

  test_class_field_metadata_identifier_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

class A {
  @a
  int? foo;
}
''');

    await _assertIntrospectText('A', uriStr: 'package:test/b.dart', r'''
class A
  superclass: Object
  fields
    foo
      metadata
        IdentifierMetadataAnnotation
          identifier: a
      type: int?
''');
  }

  test_class_fields_augmented() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {
  final int foo = 0;
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class A {
  final int bar = 0;
}
''');

    await _assertIntrospectText('A', r'''
class A
  superclass: Object
  fields
    foo
      flags: hasFinal hasInitializer
      type: int
    bar
      flags: hasFinal hasInitializer
      type: int
''');
  }

  test_class_flags_hasAbstract() async {
    newFile('$testPackageLibPath/a.dart', r'''
abstract class A {}
''');

    await _assertIntrospectText('A', r'''
class A
  flags: hasAbstract
  superclass: Object
''');
  }

  test_class_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int get foo => 0;
}
''');

    await _assertIntrospectText('A', r'''
class A
  superclass: Object
  methods
    foo
      flags: hasBody isGetter
      returnType: int
''');
  }

  test_class_interfaces() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
class B {}
class C implements A, B {}
''');

    await _assertIntrospectText('C', r'''
class C
  superclass: Object
  interfaces
    A
    B
''');
  }

  test_class_metadata_augmented() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
const b = 1;

part 'b.dart';

@a
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

@b
augment class A {}
''');

    await _assertIntrospectText('A', r'''
class A
  metadata
    IdentifierMetadataAnnotation
      identifier: a
    IdentifierMetadataAnnotation
      identifier: b
  superclass: Object
''');
  }

  test_class_metadata_constructor_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A.named()
}

@A.named()
class B {}
''');

    await _assertIntrospectText('B', r'''
class B
  metadata
    ConstructorMetadataAnnotation
      type: A
      constructorName: named
  superclass: Object
''');
  }

  test_class_metadata_constructor_named_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A.named()
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

@A.named()
class B {}
''');

    await _assertIntrospectText('B', uriStr: 'package:test/b.dart', r'''
class B
  metadata
    ConstructorMetadataAnnotation
      type: A
      constructorName: named
  superclass: Object
''');
  }

  test_class_metadata_constructor_named_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A.named()
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart' as prefix;

@prefix.A.named()
class B {}
''');

    await _assertIntrospectText('B', uriStr: 'package:test/b.dart', r'''
class B
  metadata
    ConstructorMetadataAnnotation
      type: A
      constructorName: named
  superclass: Object
''');
  }

  test_class_metadata_constructor_unnamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A()
}

@A()
class B {}
''');

    await _assertIntrospectText('B', r'''
class B
  metadata
    ConstructorMetadataAnnotation
      type: A
  superclass: Object
''');
  }

  test_class_metadata_constructor_unnamed_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A()
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

@A()
class B {}
''');

    await _assertIntrospectText('B', uriStr: 'package:test/b.dart', r'''
class B
  metadata
    ConstructorMetadataAnnotation
      type: A
  superclass: Object
''');
  }

  test_class_metadata_constructor_unnamed_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A()
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart' as prefix;

@prefix.A()
class B {}
''');

    await _assertIntrospectText('B', uriStr: 'package:test/b.dart', r'''
class B
  metadata
    ConstructorMetadataAnnotation
      type: A
  superclass: Object
''');
  }

  test_class_metadata_identifier() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;

@a
class A {}
''');

    await _assertIntrospectText('A', r'''
class A
  metadata
    IdentifierMetadataAnnotation
      identifier: a
  superclass: Object
''');
  }

  test_class_metadata_identifier_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

@a
class A {}
''');

    await _assertIntrospectText('A', uriStr: 'package:test/b.dart', r'''
class A
  metadata
    IdentifierMetadataAnnotation
      identifier: a
  superclass: Object
''');
  }

  test_class_metadata_identifier_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart' as prefix;

@prefix.a
class A {}
''');

    await _assertIntrospectText('A', uriStr: 'package:test/b.dart', r'''
class A
  metadata
    IdentifierMetadataAnnotation
      identifier: a
  superclass: Object
''');
  }

  test_class_method_flags_hasBody_false() async {
    newFile('$testPackageLibPath/a.dart', r'''
abstract class A {
  void foo();
}
''');

    await _assertIntrospectText('A', r'''
class A
  flags: hasAbstract
  superclass: Object
  methods
    foo
      returnType: void
''');
  }

  test_class_method_flags_hasExternal() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  external void foo();
}
''');

    await _assertIntrospectText('A', r'''
class A
  superclass: Object
  methods
    foo
      flags: hasBody hasExternal
      returnType: void
''');
  }

  test_class_method_flags_hasStatic() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static void foo() {}
}
''');

    await _assertIntrospectText('A', r'''
class A
  superclass: Object
  methods
    foo
      flags: hasBody hasStatic
      returnType: void
''');
  }

  test_class_method_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

class A {
  @a
  void foo() {}
}
''');

    await _assertIntrospectText('A', uriStr: 'package:test/b.dart', r'''
class A
  superclass: Object
  methods
    foo
      flags: hasBody
      metadata
        IdentifierMetadataAnnotation
          identifier: a
      returnType: void
''');
  }

  test_class_method_namedParameters() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void foo({required int a, String? b}) {}
}
''');

    await _assertIntrospectText('A', r'''
class A
  superclass: Object
  methods
    foo
      flags: hasBody
      namedParameters
        a
          flags: isNamed isRequired
          type: int
        b
          flags: isNamed
          type: String?
      returnType: void
''');
  }

  test_class_method_namedParameters_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

class A {
  void foo({@a required int x}) {}
}
''');

    await _assertIntrospectText('A', uriStr: 'package:test/b.dart', r'''
class A
  superclass: Object
  methods
    foo
      flags: hasBody
      namedParameters
        x
          flags: isNamed isRequired
          metadata
            IdentifierMetadataAnnotation
              identifier: a
          type: int
      returnType: void
''');
  }

  test_class_method_positionalParameters() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void foo(int a, [String? b]) {}
}
''');

    await _assertIntrospectText('A', r'''
class A
  superclass: Object
  methods
    foo
      flags: hasBody
      positionalParameters
        a
          flags: isRequired
          type: int
        b
          type: String?
      returnType: void
''');
  }

  test_class_method_positionalParameters_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

class A {
  void foo(@a int x) {}
}
''');

    await _assertIntrospectText('A', uriStr: 'package:test/b.dart', r'''
class A
  superclass: Object
  methods
    foo
      flags: hasBody
      positionalParameters
        x
          flags: isRequired
          metadata
            IdentifierMetadataAnnotation
              identifier: a
          type: int
      returnType: void
''');
  }

  test_class_methods_augmented() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';

class A {
  void foo() {}
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

augment class A {
  void bar() {}
}
''');

    await _assertIntrospectText('A', r'''
class A
  superclass: Object
  methods
    foo
      flags: hasBody
      returnType: void
    bar
      flags: hasBody
      returnType: void
''');
  }

  test_class_mixins() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin M1 {}
mixin M2 {}
class C with M1, M2 {}
''');

    await _assertIntrospectText('C', r'''
class C
  superclass: Object
  mixins
    M1
    M2
''');
  }

  test_class_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  set foo(int value) {}
}
''');

    await _assertIntrospectText('A', r'''
class A
  superclass: Object
  methods
    foo
      flags: hasBody isSetter
      positionalParameters
        value
          flags: isRequired
          type: int
      returnType: void
''');
  }

  test_class_superclass() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {}
class B<U> extends A<U> {}
''');

    await _assertIntrospectText('B', r'''
class B
  superclass: A<U>
  typeParameters
    U
''');
  }

  test_class_typeParameters() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T, U extends List<T>> {}
''');

    await _assertIntrospectText('A', r'''
class A
  superclass: Object
  typeParameters
    T
    U
      bound: List<T>
''');
  }

  test_classAlias_interfaces() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
mixin M {}
class I {}
class J {}

class C = A with M implements I, J;
''');

    await _assertIntrospectText('C', r'''
class C
  superclass: A
  mixins
    M
  interfaces
    I
    J
''');
  }

  test_classAlias_typeParameters() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T1> {}
mixin M<U1> {}

class C<T2, U2> = A<T2> with M<U2>;
''');

    await _assertIntrospectText('C', r'''
class C
  superclass: A<T2>
  typeParameters
    T2
    U2
  mixins
    M<U2>
''');
  }

  test_enum_fields() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum A {
  v(0);
  final int foo;
  const A(this.foo);
}
''');

    await _assertIntrospectText('A', r'''
enum A
  values
    v
  fields
    foo
      flags: hasFinal
      type: int
''');
  }

  test_enum_getters() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum A {
  v;
  int get foo => 0;
}
''');

    await _assertIntrospectText('A', r'''
enum A
  values
    v
  methods
    foo
      flags: hasBody isGetter
      returnType: int
''');
  }

  test_enum_interfaces() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
class B {}

enum X implements A, B {
  v
}
''');

    await _assertIntrospectText('X', r'''
enum X
  interfaces
    A
    B
  values
    v
''');
  }

  test_enum_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
@a1
@a2
enum X {
  v
}

const a1 = 0;
const a2 = 0;
''');

    await _assertIntrospectText('X', r'''
enum X
  metadata
    IdentifierMetadataAnnotation
      identifier: a1
    IdentifierMetadataAnnotation
      identifier: a2
  values
    v
''');
  }

  test_enum_methods() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum A {
  v;
  void foo() {}
}
''');

    await _assertIntrospectText('A', r'''
enum A
  values
    v
  methods
    foo
      flags: hasBody
      returnType: void
''');
  }

  test_enum_mixins() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {}
mixin B {}

enum X with A, B {
  v
}
''');

    await _assertIntrospectText('X', r'''
enum X
  mixins
    A
    B
  values
    v
''');
  }

  test_enum_setters() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum A {
  v;
  set foo(int value) {}
}
''');

    await _assertIntrospectText('A', r'''
enum A
  values
    v
  methods
    foo
      flags: hasBody isSetter
      positionalParameters
        value
          flags: isRequired
          type: int
      returnType: void
''');
  }

  test_enum_typeParameters() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum A<T> {
  v
}
''');

    await _assertIntrospectText('A', r'''
enum A
  typeParameters
    T
  values
    v
''');
  }

  test_enum_values() async {
    newFile('$testPackageLibPath/a.dart', r'''
enum X with A, B {
  foo, bar
}
''');

    await _assertIntrospectText('X', r'''
enum X
  values
    foo
    bar
''');
  }

  test_extension_getters() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension A on int {
  int get foo => 0;
}
''');

    await _assertIntrospectText('A', r'''
extension A
  onType: int
  methods
    foo
      flags: hasBody isGetter
      returnType: int
''');
  }

  test_extension_metadata_identifier() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;

@a
extension A on int {}
''');

    await _assertIntrospectText('A', r'''
extension A
  metadata
    IdentifierMetadataAnnotation
      identifier: a
  onType: int
''');
  }

  test_extension_methods() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension A on int {
  void foo() {}
}
''');

    await _assertIntrospectText('A', r'''
extension A
  onType: int
  methods
    foo
      flags: hasBody
      returnType: void
''');
  }

  test_extension_setters() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension A on int {
  set foo(int value) {}
}
''');

    await _assertIntrospectText('A', r'''
extension A
  onType: int
  methods
    foo
      flags: hasBody isSetter
      positionalParameters
        value
          flags: isRequired
          type: int
      returnType: void
''');
  }

  test_extension_typeParameters() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension A<T> on Map<int, T> {}
''');

    await _assertIntrospectText('A', r'''
extension A
  typeParameters
    T
  onType: Map<int, T>
''');
  }

  test_extensionType_getters() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension type A(int it) {
  int get foo => 0;
}
''');

    await _assertIntrospectText('A', r'''
extension type A
  representationType: int
  fields
    it
      flags: hasFinal
      type: int
  methods
    foo
      flags: hasBody isGetter
      returnType: int
''');
  }

  test_extensionType_metadata_identifier() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;

@a
extension type A(int it) {}
''');

    await _assertIntrospectText('A', r'''
extension type A
  metadata
    IdentifierMetadataAnnotation
      identifier: a
  representationType: int
  fields
    it
      flags: hasFinal
      type: int
''');
  }

  test_extensionType_methods() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension type A(int it) {
  void foo() {}
}
''');

    await _assertIntrospectText('A', r'''
extension type A
  representationType: int
  fields
    it
      flags: hasFinal
      type: int
  methods
    foo
      flags: hasBody
      returnType: void
''');
  }

  test_extensionType_typeParameters() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension type A<T>(int it) {}
''');

    await _assertIntrospectText('A', r'''
extension type A
  typeParameters
    T
  representationType: int
  fields
    it
      flags: hasFinal
      type: int
''');
  }

  test_functionType_formalParameters_namedOptional_simpleFormalParameter() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo(void Function(int a, {int? b, int? c}) t) {}
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasBody
  positionalParameters
    t
      flags: isRequired
      type: void Function(int a, {int? b}, {int? c})
  returnType: void
''');
  }

  test_functionType_formalParameters_namedRequired_simpleFormalParameter() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo(void Function(int a, {required int b, required int c}) t) {}
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasBody
  positionalParameters
    t
      flags: isRequired
      type: void Function(int a, {required int b}, {required int c})
  returnType: void
''');
  }

  test_functionType_formalParameters_positionalOptional_simpleFormalParameter() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo(void Function(int a, [int b, int c]) t) {}
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasBody
  positionalParameters
    t
      flags: isRequired
      type: void Function(int a, [int b], [int c])
  returnType: void
''');
  }

  test_functionType_formalParameters_positionalOptional_simpleFormalParameter_noName() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo(void Function(int a, [int, int]) t) {}
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasBody
  positionalParameters
    t
      flags: isRequired
      type: void Function(int a, [int ], [int ])
  returnType: void
''');
  }

  test_functionType_formalParameters_positionalRequired_simpleFormalParameter() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo(void Function(int a, double b) t) {}
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasBody
  positionalParameters
    t
      flags: isRequired
      type: void Function(int a, double b)
  returnType: void
''');
  }

  test_functionType_formalParameters_positionalRequired_simpleFormalParameter_noName() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo(void Function(int, double) t) {}
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasBody
  positionalParameters
    t
      flags: isRequired
      type: void Function(int , double )
  returnType: void
''');
  }

  test_functionType_nullable() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo(void Function()? t) {}
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasBody
  positionalParameters
    t
      flags: isRequired
      type: void Function()?
  returnType: void
''');
  }

  test_functionType_returnType() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo(void Function() t) {}
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasBody
  positionalParameters
    t
      flags: isRequired
      type: void Function()
  returnType: void
''');
  }

  test_functionType_returnType_omitted() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo(Function() t) {}
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasBody
  positionalParameters
    t
      flags: isRequired
      type: dynamic Function()
  returnType: void
''');
  }

  test_functionType_typeParameters() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo(void Function<T, U extends num>() t) {}
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasBody
  positionalParameters
    t
      flags: isRequired
      type: void Function<T, U extends num>()
  returnType: void
''');
  }

  test_mixin_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  final int foo = 0;
}
''');

    await _assertIntrospectText('A', r'''
mixin A
  superclassConstraints
    Object
  fields
    foo
      flags: hasFinal hasInitializer
      type: int
''');
  }

  test_mixin_field_metadata_identifier() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;

mixin A {
  @a
  int? foo;
}
''');

    await _assertIntrospectText('A', r'''
mixin A
  superclassConstraints
    Object
  fields
    foo
      metadata
        IdentifierMetadataAnnotation
          identifier: a
      type: int?
''');
  }

  test_mixin_field_metadata_identifier_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

mixin A {
  @a
  int? foo;
}
''');

    await _assertIntrospectText('A', uriStr: 'package:test/b.dart', r'''
mixin A
  superclassConstraints
    Object
  fields
    foo
      metadata
        IdentifierMetadataAnnotation
          identifier: a
      type: int?
''');
  }

  test_mixin_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  int get foo => 0;
}
''');

    await _assertIntrospectText('A', r'''
mixin A
  superclassConstraints
    Object
  methods
    foo
      flags: hasBody isGetter
      returnType: int
''');
  }

  test_mixin_metadata_augmented() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
const b = 1;

part 'b.dart';

@a
mixin A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';

@b
augment mixin A {}
''');

    await _assertIntrospectText('A', r'''
mixin A
  metadata
    IdentifierMetadataAnnotation
      identifier: a
    IdentifierMetadataAnnotation
      identifier: b
  superclassConstraints
    Object
''');
  }

  test_mixin_metadata_identifier() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;

@a
mixin A {}
''');

    await _assertIntrospectText('A', r'''
mixin A
  metadata
    IdentifierMetadataAnnotation
      identifier: a
  superclassConstraints
    Object
''');
  }

  test_mixin_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  void foo() {}
}
''');

    await _assertIntrospectText('A', r'''
mixin A
  superclassConstraints
    Object
  methods
    foo
      flags: hasBody
      returnType: void
''');
  }

  test_mixin_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  set foo(int value) {}
}
''');

    await _assertIntrospectText('A', r'''
mixin A
  superclassConstraints
    Object
  methods
    foo
      flags: hasBody isSetter
      positionalParameters
        value
          flags: isRequired
          type: int
      returnType: void
''');
  }

  test_unit_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo() {}
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasBody
  returnType: void
''');
  }

  test_unit_function_flags_hasExternal() async {
    newFile('$testPackageLibPath/a.dart', r'''
external void foo() {}
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasBody hasExternal
  returnType: void
''');
  }

  test_unit_function_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
@a1
@a2
void foo() {}

const a1 = 0;
const a2 = 0;
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasBody
  metadata
    IdentifierMetadataAnnotation
      identifier: a1
    IdentifierMetadataAnnotation
      identifier: a2
  returnType: void
''');
  }

  test_unit_function_namedParameters() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo({required int a, String? b}) {}
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasBody
  namedParameters
    a
      flags: isNamed isRequired
      type: int
    b
      flags: isNamed
      type: String?
  returnType: void
''');
  }

  test_unit_function_positionalParameters() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo(int a, [String? b]) {}
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasBody
  positionalParameters
    a
      flags: isRequired
      type: int
    b
      type: String?
  returnType: void
''');
  }

  test_unit_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
int get foo => 0;
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasBody isGetter
  returnType: int
''');
  }

  test_unit_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
set foo(int value) {}
''');

    await _assertIntrospectText('foo=', r'''
foo
  flags: hasBody isSetter
  positionalParameters
    value
      flags: isRequired
      type: int
  returnType: void
''');
  }

  test_unit_typeAlias() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef A = List<int>;
''');

    await _assertIntrospectText('A', r'''
typedef A
  aliasedType: List<int>
''');
  }

  test_unit_variable() async {
    newFile('$testPackageLibPath/a.dart', r'''
final foo = 0;
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasFinal hasInitializer
  type: int
''');
  }

  test_unit_variable_flags_hasConst_true() async {
    newFile('$testPackageLibPath/a.dart', r'''
const foo = 0;
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasConst hasInitializer
  type: int
''');
  }

  test_unit_variable_flags_hasExternal_true() async {
    newFile('$testPackageLibPath/a.dart', r'''
external int foo;
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasExternal
  type: int
''');
  }

  test_unit_variable_flags_hasFinal_false() async {
    newFile('$testPackageLibPath/a.dart', r'''
var foo = 0;
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasInitializer
  type: int
''');
  }

  test_unit_variable_flags_hasInitializer_false() async {
    newFile('$testPackageLibPath/a.dart', r'''
int? foo;
''');

    await _assertIntrospectText('foo', r'''
foo
  type: int?
''');
  }

  test_unit_variable_flags_hasLate_true() async {
    newFile('$testPackageLibPath/a.dart', r'''
late int foo;
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasLate
  type: int
''');
  }

  test_unit_variable_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
@a1
@a2
final foo = 0;

const a1 = 0;
const a2 = 0;
''');

    await _assertIntrospectText('foo', r'''
foo
  flags: hasFinal hasInitializer
  metadata
    IdentifierMetadataAnnotation
      identifier: a1
    IdentifierMetadataAnnotation
      identifier: a2
  type: int
''');
  }

  Future<void> _assertIntrospectText(
    String name,
    String expected, {
    String uriStr = 'package:test/a.dart',
    bool withUnnamedConstructor = false,
  }) async {
    newFile(
      '$testPackageLibPath/introspect.dart',
      _getMacroCode('introspect.dart'),
    );

    await _assertIntrospectDefinitionText(
      '''
import '$uriStr';
import 'introspect.dart';
''',
      expected,
      name: name,
      uriStr: uriStr,
      withUnnamedConstructor: withUnnamedConstructor,
    );
  }
}

@reflectiveTest
class MacroIntrospectNodeDefinitionsTest extends MacroElementsBaseTest {
  @override
  bool get keepLinkingLibraries => true;

  test_inferType_constructor_fieldFormalParameter() async {
    await _assertIntrospectText('A', r'''
class A {
  final int foo;
  A.named(this.foo);
}
''', r'''
class A
  constructors
    named
      flags: hasStatic
      positionalParameters
        foo
          flags: isRequired
          type: OmittedType
            inferred: int
      returnType: A
  fields
    foo
      flags: hasFinal
      type: int
''');
  }

  test_inferType_fieldInstance_fromInitializer() async {
    await _assertIntrospectText('X', r'''
class X {
  final foo = 0;
}
''', r'''
class X
  fields
    foo
      flags: hasFinal hasInitializer
      type: OmittedType
        inferred: int
''');
  }

  test_inferType_fieldInstance_fromSuper() async {
    await _assertIntrospectText('X', r'''
class A {
  int get foo => 0;
}

class X extends A {
  final foo = 0;
}
''', r'''
class X
  superclass: A
  fields
    foo
      flags: hasFinal hasInitializer
      type: OmittedType
        inferred: int
''');
  }

  test_inferType_fieldStatic() async {
    await _assertIntrospectText('A', r'''
class A {
  static final foo;
}
''', r'''
class A
  fields
    foo
      flags: hasFinal hasStatic
      type: OmittedType
        inferred: dynamic
''');
  }

  test_inferType_fieldStatic_fromInitializer() async {
    await _assertIntrospectText('A', r'''
class A {
  static final foo = 0;
}
''', r'''
class A
  fields
    foo
      flags: hasFinal hasInitializer hasStatic
      type: OmittedType
        inferred: int
''');
  }

  test_inferType_function_formalParameter() async {
    await _assertIntrospectText('foo', r'''
void foo(a) => 0;
''', r'''
foo
  flags: hasBody
  positionalParameters
    a
      flags: isRequired
      type: OmittedType
        inferred: dynamic
  returnType: void
''');
  }

  test_inferType_function_returnType() async {
    await _assertIntrospectText('foo', r'''
foo() => 0;
''', r'''
foo
  flags: hasBody
  returnType: OmittedType
    inferred: dynamic
''');
  }

  test_inferType_getterInstance_returnType_fromSuper() async {
    await _assertIntrospectText('X', r'''
class A {
  int get foo => 0;
}

class X extends A {
  get foo => 0;
}
''', r'''
class X
  superclass: A
  methods
    foo
      flags: hasBody isGetter
      returnType: OmittedType
        inferred: int
''');
  }

  test_inferType_getterStatic_returnType() async {
    await _assertIntrospectText('X', r'''
class X {
  static get foo => 0;
}
''', r'''
class X
  methods
    foo
      flags: hasBody hasStatic isGetter
      returnType: OmittedType
        inferred: dynamic
''');
  }

  test_inferType_methodInstance_formalParameter_fromSuper() async {
    await _assertIntrospectText('X', r'''
class A {
  void foo(int a) {}
}

class X extends A {
  void foo(a) {}
}
''', r'''
class X
  superclass: A
  methods
    foo
      flags: hasBody
      positionalParameters
        a
          flags: isRequired
          type: OmittedType
            inferred: int
      returnType: void
''');
  }

  test_inferType_methodInstance_returnType_fromSuper() async {
    await _assertIntrospectText('X', r'''
class A {
  int foo() => 0;
}

class X extends A {
  foo() => 0;
}
''', r'''
class X
  superclass: A
  methods
    foo
      flags: hasBody
      returnType: OmittedType
        inferred: int
''');
  }

  test_inferType_methodStatic_formalParameter() async {
    await _assertIntrospectText('X', r'''
class X {
  static void foo(a) {}
}
''', r'''
class X
  methods
    foo
      flags: hasBody hasStatic
      positionalParameters
        a
          flags: isRequired
          type: OmittedType
            inferred: dynamic
      returnType: void
''');
  }

  test_inferType_methodStatic_returnType() async {
    await _assertIntrospectText('X', r'''
class X {
  static foo() => 0;
}
''', r'''
class X
  methods
    foo
      flags: hasBody hasStatic
      returnType: OmittedType
        inferred: dynamic
''');
  }

  test_inferType_setterInstance_formalParameter_fromSuper() async {
    await _assertIntrospectText('X', r'''
abstract class A {
  set foo(int a);
}

class X extends A {
  void set foo(a) {}
}
''', r'''
class X
  superclass: A
  methods
    foo
      flags: hasBody isSetter
      positionalParameters
        a
          flags: isRequired
          type: OmittedType
            inferred: int
      returnType: void
''');
  }

  test_inferType_setterInstance_returnType() async {
    await _assertIntrospectText('X', r'''
class X {
  set foo(int a) {}
}
''', r'''
class X
  methods
    foo
      flags: hasBody isSetter
      positionalParameters
        a
          flags: isRequired
          type: int
      returnType: OmittedType
        inferred: void
''');
  }

  test_inferType_setterStatic_formalParameter() async {
    await _assertIntrospectText('X', r'''
class X {
  static void set foo(a) {}
}
''', r'''
class X
  methods
    foo
      flags: hasBody hasStatic isSetter
      positionalParameters
        a
          flags: isRequired
          type: OmittedType
            inferred: dynamic
      returnType: void
''');
  }

  test_inferType_setterStatic_returnType() async {
    await _assertIntrospectText('X', r'''
class X {
  static set foo(int a) {}
}
''', r'''
class X
  methods
    foo
      flags: hasBody hasStatic isSetter
      positionalParameters
        a
          flags: isRequired
          type: int
      returnType: OmittedType
        inferred: void
''');
  }

  test_inferType_topGetter_returnType() async {
    await _assertIntrospectText('foo', r'''
get foo => 0;
''', r'''
foo
  flags: hasBody isGetter
  returnType: OmittedType
    inferred: dynamic
''');
  }

  test_inferType_topSetter_formalParameter() async {
    await _assertIntrospectText('foo=', r'''
void set foo(value) {}
''', r'''
foo
  flags: hasBody isSetter
  positionalParameters
    value
      flags: isRequired
      type: OmittedType
        inferred: dynamic
  returnType: void
''');
  }

  test_inferType_topSetter_returnType() async {
    await _assertIntrospectText('foo=', r'''
set foo(int value) {}
''', r'''
foo
  flags: hasBody isSetter
  positionalParameters
    value
      flags: isRequired
      type: int
  returnType: OmittedType
    inferred: void
''');
  }

  test_inferType_topVariable_fromInitializer() async {
    await _assertIntrospectText('foo', r'''
final foo = 0;
''', r'''
foo
  flags: hasFinal hasInitializer
  type: OmittedType
    inferred: int
''');
  }

  test_topLevelDeclarationsOf_imported_class() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
class B {}
''');

    await _assertLibraryDefinitionsPhaseText(
      'A',
      uriStr: 'package:test/a.dart',
      r'''
import 'a.dart';
''',
      r'''
topLevelDeclarationsOf
  class A
    superclass: Object
  class B
    superclass: Object
''',
    );
  }

  test_topLevelDeclarationsOf_self_class() async {
    await _assertLibraryDefinitionsPhaseText('A', r'''
class A {}
class B {}
''', r'''
topLevelDeclarationsOf
  class A
  class B
''');
  }

  test_topLevelDeclarationsOf_self_enum() async {
    await _assertLibraryDefinitionsPhaseText('A', r'''
enum A {v1}
enum B {v2}
''', r'''
topLevelDeclarationsOf
  enum A
    values
      v1
  enum B
    values
      v2
''');
  }

  test_topLevelDeclarationsOf_self_extension() async {
    await _assertLibraryDefinitionsPhaseText('A', r'''
extension A on int {}
extension B on double {}
''', r'''
topLevelDeclarationsOf
  extension A
    onType: int
  extension B
    onType: double
''');
  }

  test_topLevelDeclarationsOf_self_function() async {
    await _assertLibraryDefinitionsPhaseText('foo', r'''
void foo() {}
void bar() {}
''', r'''
topLevelDeclarationsOf
  foo
    flags: hasBody
    returnType: void
  bar
    flags: hasBody
    returnType: void
''');
  }

  test_topLevelDeclarationsOf_self_getter() async {
    await _assertLibraryDefinitionsPhaseText('foo', r'''
int get foo => 0;
int get bar => 0;
''', r'''
topLevelDeclarationsOf
  foo
    flags: hasBody isGetter
    returnType: int
  bar
    flags: hasBody isGetter
    returnType: int
''');
  }

  test_topLevelDeclarationsOf_self_mixin() async {
    await _assertLibraryDefinitionsPhaseText('A', r'''
mixin A {}
mixin B {}
''', r'''
topLevelDeclarationsOf
  mixin A
  mixin B
''');
  }

  test_topLevelDeclarationsOf_self_setter() async {
    await _assertLibraryDefinitionsPhaseText('foo=', r'''
set foo(int value) {}
set bar(int value) {}
''', r'''
topLevelDeclarationsOf
  foo
    flags: hasBody isSetter
    positionalParameters
      value
        flags: isRequired
        type: int
    returnType: OmittedType
      inferred: void
  bar
    flags: hasBody isSetter
    positionalParameters
      value
        flags: isRequired
        type: int
    returnType: OmittedType
      inferred: void
''');
  }

  test_topLevelDeclarationsOf_self_variable() async {
    await _assertLibraryDefinitionsPhaseText('foo', r'''
final int foo = 0;
final int bar = 0;
''', r'''
topLevelDeclarationsOf
  foo
    flags: hasFinal hasInitializer
    type: int
  bar
    flags: hasFinal hasInitializer
    type: int
''');
  }

  /// The [name] should be the name of a declaration in [code].
  Future<void> _assertIntrospectText(
    String name,
    String code,
    String expected,
  ) async {
    newFile(
      '$testPackageLibPath/introspect.dart',
      _getMacroCode('introspect.dart'),
    );

    await _assertIntrospectDefinitionText(
      '''
import 'introspect.dart';
$code
''',
      expected,
      name: name,
      uriStr: 'package:test/test.dart',
      withUnnamedConstructor: false,
    );
  }

  /// We use [nameToFind] only because there is no API to get `Library` by
  /// its URI. So, we get the identifier, resolve it to the declaration,
  /// and then get its `Library`.
  Future<void> _assertLibraryDefinitionsPhaseText(
    String nameToFind,
    String code,
    String expected, {
    String uriStr = 'package:test/test.dart',
  }) async {
    newFile(
      '$testPackageLibPath/introspect.dart',
      _getMacroCode('introspect.dart'),
    );

    var library = await buildLibrary('''
import 'introspect.dart';
$code

@LibraryTopLevelDeclarations(
  uriStr: '$uriStr',
  nameToFind: '$nameToFind',
)
void _starter() {}
''');

    _assertDefinitionsPhaseText(library, expected);
  }
}

@reflectiveTest
class MacroIntrospectNodeTest extends MacroElementsBaseTest {
  @override
  bool get keepLinkingLibraries => true;

  test_class_appendInterfaces() async {
    await _assertIntrospectText(r'''
import 'append.dart';

class A {}

@Introspect()
@AppendInterface('{{package:test/test.dart@A}}')
class X {}
''', r'''
class X
  interfaces
    A
''');
  }

  test_class_appendMixins() async {
    await _assertIntrospectText(r'''
import 'append.dart';

mixin A {}

@Introspect()
@AppendMixin('{{package:test/test.dart@A}}')
class X {}
''', r'''
class X
  mixins
    A
''');
  }

  test_class_constructor_flags_isFactory() async {
    await _assertIntrospectText(r'''
class A {
  A();

  @Introspect()
  factory A.named() => A();
}
''', r'''
named
  flags: hasBody hasStatic isFactory
  returnType: A
''');
  }

  test_class_constructor_metadata() async {
    await _assertIntrospectText(r'''
class A {
  @Introspect(
    withMetadata: true,
    withUnnamedConstructor: true,
  )
  @a1
  @a2
  A();
}

const a1 = 0;
const a2 = 0;
''', r'''
<unnamed>
  flags: hasStatic
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    IdentifierMetadataAnnotation
      identifier: a1
    IdentifierMetadataAnnotation
      identifier: a2
  returnType: A
''');
  }

  test_class_constructor_named() async {
    await _assertIntrospectText(r'''
class A {
  @Introspect()
  A.named();
}
''', r'''
named
  flags: hasStatic
  returnType: A
''');
  }

  test_class_constructor_namedParameters() async {
    await _assertIntrospectText(r'''
class A {
  @Introspect()
  A({required int a, String? b});
}
''', r'''
<unnamed>
  flags: hasStatic
  namedParameters
    a
      flags: isNamed isRequired
      type: int
    b
      flags: isNamed
      type: String?
  returnType: A
''');
  }

  test_class_constructor_positionalParameters() async {
    await _assertIntrospectText(r'''
class A {
  @Introspect()
  A(int a, [String? b]);
}
''', r'''
<unnamed>
  flags: hasStatic
  positionalParameters
    a
      flags: isRequired
      type: int
    b
      type: String?
  returnType: A
''');
  }

  test_class_constructor_positionalParameters_super() async {
    await _assertIntrospectText(r'''
import 'package:json/json.dart';

class A {
  final int f1;
  Point(this.foo);
}

class B extends A {
  @Introspect()
  B(super.f1);
}
''', r'''
<unnamed>
  flags: hasStatic
  positionalParameters
    f1
      flags: isRequired
      type: OmittedType
  returnType: B
''');
  }

  test_class_constructor_positionalParameters_super_typed() async {
    await _assertIntrospectText(r'''
import 'package:json/json.dart';

class A {
  final int f1;
  Point(this.foo);
}

class B extends A {
  @Introspect()
  B(int super.f1);
}
''', r'''
<unnamed>
  flags: hasStatic
  positionalParameters
    f1
      flags: isRequired
      type: int
  returnType: B
''');
  }

  test_class_constructor_positionalParameters_this() async {
    await _assertIntrospectText(r'''
import 'package:json/json.dart';

class A {
  final int f1;
  @Introspect()
  Point(this.foo);
}
''', r'''
Point
  positionalParameters
    foo
      flags: isRequired
      type: OmittedType
  returnType: OmittedType
''');
  }

  test_class_constructor_unnamed() async {
    await _assertIntrospectText(r'''
class A {
  @Introspect()
  A();
}
''', r'''
<unnamed>
  flags: hasStatic
  returnType: A
''');
  }

  test_class_extendsType() async {
    await _assertIntrospectText(r'''
import 'append.dart';

class A<T> {}

@Introspect()
@SetExtendsType('{{package:test/test.dart@A}}', ['{{dart:core@int}}'])
class X {}
''', r'''
class X
  superclass: A<int>
''');
  }

  test_class_field_flags_hasConst_true() async {
    await _assertIntrospectText(r'''
class X {
  @Introspect()
  static const int foo = 0;
}
''', r'''
foo
  flags: hasConst hasInitializer hasStatic
  type: int
''');
  }

  test_class_field_flags_hasExternal() async {
    await _assertIntrospectText(r'''
class X {
  @Introspect()
  external int foo;
}
''', r'''
foo
  flags: hasExternal
  type: int
''');
  }

  test_class_field_flags_hasFinal_false() async {
    await _assertIntrospectText(r'''
class X {
  @Introspect()
  int foo = 0;
}
''', r'''
foo
  flags: hasInitializer
  type: int
''');
  }

  test_class_field_flags_hasFinal_true() async {
    await _assertIntrospectText(r'''
class X {
  @Introspect()
  final int foo = 0;
}
''', r'''
foo
  flags: hasFinal hasInitializer
  type: int
''');
  }

  test_class_field_flags_hasInitializer_false() async {
    await _assertIntrospectText(r'''
class X {
  @Introspect()
  int? foo;
}
''', r'''
foo
  type: int?
''');
  }

  test_class_field_flags_hasLate() async {
    await _assertIntrospectText(r'''
class X {
  @Introspect()
  late int foo;
}
''', r'''
foo
  flags: hasLate
  type: int
''');
  }

  test_class_field_flags_hasStatic() async {
    await _assertIntrospectText(r'''
class X {
  @Introspect()
  static int foo = 0;
}
''', r'''
foo
  flags: hasInitializer hasStatic
  type: int
''');
  }

  test_class_field_type_explicit() async {
    await _assertIntrospectText(r'''
class X {
  @Introspect()
  int foo = 0;
}
''', r'''
foo
  flags: hasInitializer
  type: int
''');
  }

  test_class_field_type_implicit() async {
    await _assertIntrospectText(r'''
class X {
  @Introspect()
  final foo = 0;
}
''', r'''
foo
  flags: hasFinal hasInitializer
  type: OmittedType
''');
  }

  test_class_fields() async {
    await _assertIntrospectText(r'''
@Introspect()
class X {
  final int foo = 0;
  String bar = '';
}
''', r'''
class X
  fields
    foo
      flags: hasFinal hasInitializer
      type: int
    bar
      flags: hasInitializer
      type: String
''');
  }

  test_class_flags_hasAbstract() async {
    await _assertIntrospectText(r'''
@Introspect()
abstract class A {}
''', r'''
class A
  flags: hasAbstract
''');
  }

  test_class_getter() async {
    await _assertIntrospectText(r'''
abstract class A {
  @Introspect()
  int get foo => 0;
}
''', r'''
foo
  flags: hasBody isGetter
  returnType: int
''');
  }

  test_class_interfaces() async {
    await _assertIntrospectText(r'''
@Introspect()
class A implements B, C<int, String> {}
''', r'''
class A
  interfaces
    B
      noDeclaration
    C<int, String>
      noDeclaration
''');
  }

  test_class_metadata_constructor_named() async {
    await _assertIntrospectText(r'''
@Introspect(withMetadata: true)
@A.named()
class X {}

class A {
  const A.named()
}
''', r'''
class X
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    ConstructorMetadataAnnotation
      type: A
      constructorName: named
''');
  }

  test_class_metadata_constructor_named_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A.named()
}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@Introspect(withMetadata: true)
@A.named()
class X {}

''', r'''
class X
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    ConstructorMetadataAnnotation
      type: A
      constructorName: named
''');
  }

  test_class_metadata_constructor_named_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A.named()
}
''');

    await _assertIntrospectText(r'''
import 'a.dart' as prefix;

@Introspect(withMetadata: true)
@prefix.A.named()
class X {}

''', r'''
class X
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    ConstructorMetadataAnnotation
      type: A
      constructorName: named
''');
  }

  test_class_metadata_constructor_namedArguments() async {
    await _assertIntrospectText(r'''
@Introspect(withMetadata: true)
@A(a: 42, b: 'foo')
class X {}

class A {
  const A({int? a, String? b});
}
''', r'''
class X
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    ConstructorMetadataAnnotation
      type: A
      namedArguments
        a: [42]
        b: ['foo']
''');
  }

  test_class_metadata_constructor_positionalArguments() async {
    await _assertIntrospectText(r'''
@Introspect(withMetadata: true)
@A(42, 'foo')
class X {}

class A {
  const A(int a, String b);
}
''', r'''
class X
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    ConstructorMetadataAnnotation
      type: A
      positionalArguments
        [42]
        ['foo']
''');
  }

  test_class_metadata_constructor_unnamed() async {
    await _assertIntrospectText(r'''
@Introspect(withMetadata: true)
@A()
class X {}

class A {
  const A()
}
''', r'''
class X
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    ConstructorMetadataAnnotation
      type: A
''');
  }

  test_class_metadata_constructor_unnamed_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A()
}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@Introspect(withMetadata: true)
@A()
class X {}

''', r'''
class X
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    ConstructorMetadataAnnotation
      type: A
''');
  }

  test_class_metadata_constructor_unnamed_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  const A()
}
''');

    await _assertIntrospectText(r'''
import 'a.dart' as prefix;

@Introspect(withMetadata: true)
@prefix.A()
class X {}

''', r'''
class X
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    ConstructorMetadataAnnotation
      type: A
''');
  }

  test_class_metadata_identifier() async {
    await _assertIntrospectText(r'''
@Introspect(withMetadata: true)
@a1
@a2
class X {}

const a1 = 0;
const a2 = 0;
''', r'''
class X
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    IdentifierMetadataAnnotation
      identifier: a1
    IdentifierMetadataAnnotation
      identifier: a2
''');
  }

  test_class_metadata_identifier_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a1 = 0;
const a2 = 0;
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@Introspect(withMetadata: true)
@a1
@a2
class X {}

''', r'''
class X
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    IdentifierMetadataAnnotation
      identifier: a1
    IdentifierMetadataAnnotation
      identifier: a2
''');
  }

  test_class_metadata_identifier_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a1 = 0;
const a2 = 0;
''');

    await _assertIntrospectText(r'''
import 'a.dart' as prefix;

@Introspect(withMetadata: true)
@prefix.a1
@prefix.a2
class X {}

''', r'''
class X
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    IdentifierMetadataAnnotation
      identifier: a1
    IdentifierMetadataAnnotation
      identifier: a2
''');
  }

  test_class_method_flags_hasBody_false() async {
    await _assertIntrospectText(r'''
abstract class A {
  @Introspect()
  void foo();
}
''', r'''
foo
  returnType: void
''');
  }

  test_class_method_flags_hasExternal() async {
    await _assertIntrospectText(r'''
abstract class A {
  @Introspect()
  external void foo();
}
''', r'''
foo
  flags: hasExternal
  returnType: void
''');
  }

  test_class_method_flags_hasStatic() async {
    await _assertIntrospectText(r'''
class A {
  @Introspect()
  static void foo() {}
}
''', r'''
foo
  flags: hasBody hasStatic
  returnType: void
''');
  }

  test_class_method_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    await _assertIntrospectText(r'''
import 'a.dart';

class X {
  @Introspect(withMetadata: true)
  @a
  void foo() {}
}

''', r'''
foo
  flags: hasBody
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    IdentifierMetadataAnnotation
      identifier: a
  returnType: void
''');
  }

  test_class_method_namedParameters() async {
    await _assertIntrospectText(r'''
abstract class A {
  @Introspect()
  void foo({required int a, String? b}) {}
}
''', r'''
foo
  flags: hasBody
  namedParameters
    a
      flags: isNamed isRequired
      type: int
    b
      flags: isNamed
      type: String?
  returnType: void
''');
  }

  test_class_method_namedParameters_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    await _assertIntrospectText(r'''
import 'a.dart';

abstract class A {
  @Introspect(withMetadata: true)
  void foo({@a required int x}) {}
}
''', r'''
foo
  flags: hasBody
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
  namedParameters
    x
      flags: isNamed isRequired
      metadata
        IdentifierMetadataAnnotation
          identifier: a
      type: int
  returnType: void
''');
  }

  test_class_method_positionalParameters() async {
    await _assertIntrospectText(r'''
abstract class A {
  @Introspect()
  void foo(int a, [String? b]) {}
}
''', r'''
foo
  flags: hasBody
  positionalParameters
    a
      flags: isRequired
      type: int
    b
      type: String?
  returnType: void
''');
  }

  test_class_method_positionalParameters_metadata() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    await _assertIntrospectText(r'''
import 'a.dart';

abstract class A {
  @Introspect(withMetadata: true)
  void foo(@a int x) {}
}
''', r'''
foo
  flags: hasBody
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
  positionalParameters
    x
      flags: isRequired
      metadata
        IdentifierMetadataAnnotation
          identifier: a
      type: int
  returnType: void
''');
  }

  test_class_mixins() async {
    await _assertIntrospectText(r'''
@Introspect()
class A with B, C<int, String> {}
''', r'''
class A
  mixins
    B
      noDeclaration
    C<int, String>
      noDeclaration
''');
  }

  test_class_setter() async {
    await _assertIntrospectText(r'''
abstract class A {
  @Introspect()
  set foo(int value) {}
}
''', r'''
foo
  flags: hasBody isSetter
  positionalParameters
    value
      flags: isRequired
      type: int
  returnType: OmittedType
''');
  }

  test_class_superclass() async {
    await _assertIntrospectText(r'''
@Introspect()
class A extends B {}
''', r'''
class A
  superclass: B
    noDeclaration
''');
  }

  test_class_superclass_nullable() async {
    await _assertIntrospectText(r'''
@Introspect()
class A extends B<int?> {}
''', r'''
class A
  superclass: B<int?>
    noDeclaration
''');
  }

  test_class_superclass_typeArguments() async {
    await _assertIntrospectText(r'''
@Introspect()
class A extends B<String, List<int>> {}
''', r'''
class A
  superclass: B<String, List<int>>
    noDeclaration
''');
  }

  test_class_superclassOf() async {
    await _assertIntrospectText(r'''
class A {}

@Introspect(
  withDetailsFor: {'A'},
)
class X extends A {}
''', r'''
class X
  superclass: A
    class A
''');
  }

  test_class_superclassOf_implicit() async {
    await _assertIntrospectText(r'''
@Introspect()
class X {}
''', r'''
class X
''');
  }

  test_class_superclassOf_unresolved() async {
    await _assertIntrospectText(r'''
@Introspect()
class X extends A {}
''', r'''
class X
  superclass: A
    noDeclaration
''');
  }

  test_class_typeParameter_metadata_identifier_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@Introspect(withMetadata: true)
class A<@a T> {}
''', r'''
class A
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
  typeParameters
    T
      metadata
        IdentifierMetadataAnnotation
          identifier: a
''');
  }

  test_class_typeParameters() async {
    await _assertIntrospectText(r'''
@Introspect()
class A<T, U extends List<T>> {}
''', r'''
class A
  typeParameters
    T
    U
      bound: List<T>
''');
  }

  test_classAlias_flags_hasAbstract() async {
    await _assertIntrospectText(r'''
class A {}
mixin M {}

@Introspect()
abstract class C = A with M;
''', r'''
class C
  flags: hasAbstract
  superclass: A
  mixins
    M
''');
  }

  test_classAlias_interfaces() async {
    await _assertIntrospectText(r'''
class A {}
mixin M {}
class I {}
class J {}

@Introspect()
class C = A with M implements I, J;
''', r'''
class C
  superclass: A
  mixins
    M
  interfaces
    I
    J
''');
  }

  test_classAlias_metadata_identifier() async {
    await _assertIntrospectText(r'''
class A {}
mixin M {}

@Introspect(withMetadata: true)
@a1
@a2
class C = A with M;

class X {}
''', r'''
class C
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    IdentifierMetadataAnnotation
      identifier: a1
    IdentifierMetadataAnnotation
      identifier: a2
  superclass: A
  mixins
    M
''');
  }

  test_classAlias_typeParameters() async {
    await _assertIntrospectText(r'''
class A<T1> {}
mixin M<U1> {}

@Introspect()
class C<T2, U2> = A<T2> with M<U2>;
''', r'''
class C
  superclass: A<T2>
  typeParameters
    T2
    U2
  mixins
    M<U2>
''');
  }

  test_enum_fields() async {
    await _assertIntrospectText(r'''
@Introspect()
enum A {
  v(0);
  final int foo;
  const A(this.foo);
}
''', r'''
enum A
  values
    v
  fields
    foo
      flags: hasFinal
      type: int
''');
  }

  test_enum_getters() async {
    await _assertIntrospectText(r'''
@Introspect()
enum A {
  v;
  int get foo => 0;
}
''', r'''
enum A
  values
    v
  methods
    foo
      flags: hasBody isGetter
      returnType: int
''');
  }

  test_enum_interfaces() async {
    await _assertIntrospectText(r'''
class A {}
class B {}

@Introspect()
enum X implements A, B {
  v
}
''', r'''
enum X
  interfaces
    A
    B
  values
    v
''');
  }

  test_enum_metadata_identifier_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@Introspect(withMetadata: true)
@a
enum X {
  v
}

''', r'''
enum X
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    IdentifierMetadataAnnotation
      identifier: a
  values
    v
''');
  }

  test_enum_method() async {
    await _assertIntrospectText(r'''
enum A {
  v;
  @Introspect()
  void foo() {}
}
''', r'''
foo
  flags: hasBody
  returnType: void
''');
  }

  test_enum_methods() async {
    await _assertIntrospectText(r'''
@Introspect()
enum A {
  v;
  void foo() {}
}
''', r'''
enum A
  values
    v
  methods
    foo
      flags: hasBody
      returnType: void
''');
  }

  test_enum_mixins() async {
    await _assertIntrospectText(r'''
mixin A {}
mixin B {}

@Introspect()
enum X with A, B {
  v
}
''', r'''
enum X
  mixins
    A
    B
  values
    v
''');
  }

  test_enum_setters() async {
    await _assertIntrospectText(r'''
@Introspect()
enum A {
  v;
  set foo(int value) {}
}
''', r'''
enum A
  values
    v
  methods
    foo
      flags: hasBody isSetter
      positionalParameters
        value
          flags: isRequired
          type: int
      returnType: OmittedType
''');
  }

  test_enum_typeParameters() async {
    await _assertIntrospectText(r'''
@Introspect()
enum E<T> {
  v
}
''', r'''
enum E
  typeParameters
    T
  values
    v
''');
  }

  test_enum_values() async {
    await _assertIntrospectText(r'''
@Introspect()
enum A {
  foo, bar
}
''', r'''
enum A
  values
    foo
    bar
''');
  }

  test_enumValue() async {
    await _assertIntrospectText(r'''
enum A {
  @Introspect()
  foo;
}
''', r'''
foo
''');
  }

  test_enumValue_metadata_identifier_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    await _assertIntrospectText(r'''
import 'a.dart';

enum X {
  @Introspect(withMetadata: true)
  @a
  v
}

''', r'''
v
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    IdentifierMetadataAnnotation
      identifier: a
''');
  }

  test_extension_getter() async {
    await _assertIntrospectText(r'''
extension A on int {
  @Introspect()
  int get foo => 0;
}
''', r'''
foo
  flags: hasBody isGetter
  returnType: int
''');
  }

  test_extension_getters() async {
    await _assertIntrospectText(r'''
@Introspect()
extension A on int {
  int get foo => 0;
}
''', r'''
extension A
  onType: int
  methods
    foo
      flags: hasBody isGetter
      returnType: int
''');
  }

  test_extension_metadata_identifier() async {
    await _assertIntrospectText(r'''
const a = 0;

@Introspect(withMetadata: true)
@a
extension A on int {}
''', r'''
extension A
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    IdentifierMetadataAnnotation
      identifier: a
  onType: int
''');
  }

  test_extension_method() async {
    await _assertIntrospectText(r'''
extension A on int {
  @Introspect()
  void foo() {}
}
''', r'''
foo
  flags: hasBody
  returnType: void
''');
  }

  test_extension_methods() async {
    await _assertIntrospectText(r'''
@Introspect()
extension A on int {
  void foo() {}
}
''', r'''
extension A
  onType: int
  methods
    foo
      flags: hasBody
      returnType: void
''');
  }

  test_extension_typeParameters() async {
    await _assertIntrospectText(r'''
@Introspect()
extension A<T> on int {}
''', r'''
extension A
  typeParameters
    T
  onType: int
''');
  }

  test_extensionType_getter() async {
    await _assertIntrospectText(r'''
extension type A(int it) {
  @Introspect()
  int get foo => 0;
}
''', r'''
foo
  flags: hasBody isGetter
  returnType: int
''');
  }

  test_extensionType_getters() async {
    await _assertIntrospectText(r'''
@Introspect()
extension type A(int it) {
  int get foo => 0;
}
''', r'''
extension type A
  representationType: int
  fields
    it
      flags: hasFinal
      type: int
  methods
    foo
      flags: hasBody isGetter
      returnType: int
''');
  }

  test_extensionType_metadata_identifier() async {
    await _assertIntrospectText(r'''
const a = 0;

@Introspect(withMetadata: true)
@a
extension type A(int it) {}
''', r'''
extension type A
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    IdentifierMetadataAnnotation
      identifier: a
  representationType: int
  fields
    it
      flags: hasFinal
      type: int
''');
  }

  test_extensionType_method() async {
    await _assertIntrospectText(r'''
extension type A(int it) {
  @Introspect()
  void foo() {}
}
''', r'''
foo
  flags: hasBody
  returnType: void
''');
  }

  test_extensionType_methods() async {
    await _assertIntrospectText(r'''
@Introspect()
extension type A(int it) {
  void foo() {}
}
''', r'''
extension type A
  representationType: int
  fields
    it
      flags: hasFinal
      type: int
  methods
    foo
      flags: hasBody
      returnType: void
''');
  }

  test_extensionType_typeParameters() async {
    await _assertIntrospectText(r'''
@Introspect()
extension type A<T>(int it) {}
''', r'''
extension type A
  typeParameters
    T
  representationType: int
  fields
    it
      flags: hasFinal
      type: int
''');
  }

  test_functionType_typeParameters() async {
    await _assertIntrospectText(r'''
@Introspect()
class A extends B<void Function<T, U extends num>()> {}
''', r'''
class A
  superclass: B<void Function<T, U extends num>()>
    noDeclaration
''');
  }

  test_functionTypeAnnotation_formalParameters_namedOptional_simpleFormalParameter() async {
    await _assertIntrospectText(r'''
@Introspect()
class A extends B<void Function(int a, {int? b, int? c})> {}
''', r'''
class A
  superclass: B<void Function(int a, {int? b}, {int? c})>
    noDeclaration
''');
  }

  test_functionTypeAnnotation_formalParameters_namedRequired_simpleFormalParameter() async {
    await _assertIntrospectText(r'''
@Introspect()
class A extends B<void Function(int a, {required int b, required int c})> {}
''', r'''
class A
  superclass: B<void Function(int a, {required int b}, {required int c})>
    noDeclaration
''');
  }

  test_functionTypeAnnotation_formalParameters_positionalOptional_simpleFormalParameter() async {
    await _assertIntrospectText(r'''
@Introspect()
class A extends B<void Function(int a, [int b, int c])> {}
''', r'''
class A
  superclass: B<void Function(int a, [int b], [int c])>
    noDeclaration
''');
  }

  test_functionTypeAnnotation_formalParameters_positionalOptional_simpleFormalParameter_noName() async {
    await _assertIntrospectText(r'''
@Introspect()
class A extends B<void Function(int a, [int, int])> {}
''', r'''
class A
  superclass: B<void Function(int a, [int], [int])>
    noDeclaration
''');
  }

  test_functionTypeAnnotation_formalParameters_positionalRequired_simpleFormalParameter() async {
    await _assertIntrospectText(r'''
@Introspect()
class A extends B<void Function(int a, double b)> {}
''', r'''
class A
  superclass: B<void Function(int a, double b)>
    noDeclaration
''');
  }

  test_functionTypeAnnotation_formalParameters_positionalRequired_simpleFormalParameter_noName() async {
    await _assertIntrospectText(r'''
@Introspect()
class A extends B<void Function(int, double)> {}
''', r'''
class A
  superclass: B<void Function(int, double)>
    noDeclaration
''');
  }

  test_functionTypeAnnotation_nullable() async {
    await _assertIntrospectText(r'''
@Introspect()
class A extends B<void Function()?> {}
''', r'''
class A
  superclass: B<void Function()?>
    noDeclaration
''');
  }

  test_functionTypeAnnotation_returnType() async {
    await _assertIntrospectText(r'''
@Introspect()
class A extends B<void Function()> {}
''', r'''
class A
  superclass: B<void Function()>
    noDeclaration
''');
  }

  test_functionTypeAnnotation_returnType_omitted() async {
    await _assertIntrospectText(r'''
@Introspect()
class A extends B<Function()> {}
''', r'''
class A
  superclass: B<OmittedType Function()>
    noDeclaration
''');
  }

  test_functionTypeAnnotation_typeParameters() async {
    await _assertIntrospectText(r'''
@Introspect()
class A extends B<void Function<T, U extends num>()> {}
''', r'''
class A
  superclass: B<void Function<T, U extends num>()>
    noDeclaration
''');
  }

  test_library_classes() async {
    await _assertIntrospectText(r'''
@Introspect()
library;

class A {
  void foo() {}
}

class B {
  void bar() {}
}
''', r'''
class A
  methods
    foo
      flags: hasBody
      returnType: void
class B
  methods
    bar
      flags: hasBody
      returnType: void
''');
  }

  test_library_extensions() async {
    await _assertIntrospectText(r'''
@Introspect()
library;

extension A on int {
  void foo() {}
}

extension B on int {
  void bar() {}
}
''', r'''
extension A
  onType: int
  methods
    foo
      flags: hasBody
      returnType: void
extension B
  onType: int
  methods
    bar
      flags: hasBody
      returnType: void
''');
  }

  test_library_extensionTypes() async {
    await _assertIntrospectText(r'''
@Introspect()
library;

extension type A(int it) {
  void foo() {}
}
''', r'''
extension type A
  representationType: int
  fields
    it
      flags: hasFinal
      type: int
  methods
    foo
      flags: hasBody
      returnType: void
''');
  }

  test_library_mixin() async {
    await _assertIntrospectText(r'''
@Introspect()
library;

mixin A {
  void foo() {}
}

mixin B {
  void bar() {}
}
''', r'''
mixin A
  methods
    foo
      flags: hasBody
      returnType: void
mixin B
  methods
    bar
      flags: hasBody
      returnType: void
''');
  }

  test_mixin_appendInterfaces() async {
    await _assertIntrospectText(r'''
import 'append.dart';

class A {}

@Introspect()
@AppendInterface('{{package:test/test.dart@A}}')
mixin X {}
''', r'''
mixin X
  interfaces
    A
''');
  }

  test_mixin_fields() async {
    await _assertIntrospectText(r'''
@Introspect()
mixin X {
  final int foo = 0;
  String bar = '';
}
''', r'''
mixin X
  fields
    foo
      flags: hasFinal hasInitializer
      type: int
    bar
      flags: hasInitializer
      type: String
''');
  }

  test_mixin_flags_hasBase() async {
    await _assertIntrospectText(r'''
@Introspect()
base mixin A {}
''', r'''
mixin A
  flags: hasBase
''');
  }

  test_mixin_getter() async {
    await _assertIntrospectText(r'''
mixin A {
  @Introspect()
  int get foo => 0;
}
''', r'''
foo
  flags: hasBody isGetter
  returnType: int
''');
  }

  test_mixin_interfaces() async {
    await _assertIntrospectText(r'''
@Introspect()
mixin A implements B, C {}
''', r'''
mixin A
  interfaces
    B
      noDeclaration
    C
      noDeclaration
''');
  }

  test_mixin_metadata_identifier_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@Introspect(withMetadata: true)
@a
mixin X {}

''', r'''
mixin X
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    IdentifierMetadataAnnotation
      identifier: a
''');
  }

  test_mixin_method() async {
    await _assertIntrospectText(r'''
mixin A {
  @Introspect()
  void foo() {}
}
''', r'''
foo
  flags: hasBody
  returnType: void
''');
  }

  test_mixin_setter() async {
    await _assertIntrospectText(r'''
mixin A {
  @Introspect()
  set foo(int value) {}
}
''', r'''
foo
  flags: hasBody isSetter
  positionalParameters
    value
      flags: isRequired
      type: int
  returnType: OmittedType
''');
  }

  test_mixin_superclassConstraints() async {
    await _assertIntrospectText(r'''
@Introspect()
mixin A on B, C {}
''', r'''
mixin A
  superclassConstraints
    B
      noDeclaration
    C
      noDeclaration
''');
  }

  test_mixin_typeParameters() async {
    await _assertIntrospectText(r'''
@Introspect()
mixin A<T, U extends List<T>> {}
''', r'''
mixin A
  typeParameters
    T
    U
      bound: List<T>
''');
  }

  test_namedTypeAnnotation_prefixed() async {
    await _assertIntrospectText(r'''
@Introspect()
class A extends prefix.B {}
''', r'''
class A
  superclass: B
    noDeclaration
''');
  }

  test_namedTypeAnnotation_typeArguments_absent() async {
    await _assertIntrospectText(r'''
@Introspect()
Map get foo => {};
''', r'''
foo
  flags: hasBody isGetter
  returnType: Map
''');
  }

  test_namedTypeAnnotation_typeArguments_wrongCount() async {
    await _assertIntrospectText(r'''
@Introspect()
Map<int> get foo => {};
''', r'''
foo
  flags: hasBody isGetter
  returnType: Map<int>
''');
  }

  test_typeAlias_namedType() async {
    await _assertIntrospectText(r'''
@Introspect()
typedef X = List<int>;
''', r'''
typedef X
  aliasedType: List<int>
''');
  }

  test_unit_function() async {
    await _assertIntrospectText(r'''
@Introspect()
void foo() {}
''', r'''
foo
  flags: hasBody
  returnType: void
''');
  }

  test_unit_function_flags_hasExternal() async {
    await _assertIntrospectText(r'''
@Introspect()
external void foo();
''', r'''
foo
  flags: hasExternal
  returnType: void
''');
  }

  test_unit_function_metadata() async {
    await _assertIntrospectText(r'''
@Introspect(withMetadata: true)
@a1
@a2
void foo() {}

const a1 = 0;
const a2 = 0;
''', r'''
foo
  flags: hasBody
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    IdentifierMetadataAnnotation
      identifier: a1
    IdentifierMetadataAnnotation
      identifier: a2
  returnType: void
''');
  }

  test_unit_function_namedParameters() async {
    await _assertIntrospectText(r'''
@Introspect()
void foo({required int a, String? b}) {}
''', r'''
foo
  flags: hasBody
  namedParameters
    a
      flags: isNamed isRequired
      type: int
    b
      flags: isNamed
      type: String?
  returnType: void
''');
  }

  test_unit_function_positionalParameters() async {
    await _assertIntrospectText(r'''
@Introspect()
void foo(int a, [String? b]) {}
''', r'''
foo
  flags: hasBody
  positionalParameters
    a
      flags: isRequired
      type: int
    b
      type: String?
  returnType: void
''');
  }

  test_unit_getter() async {
    await _assertIntrospectText(r'''
@Introspect()
int get foo => 0;
''', r'''
foo
  flags: hasBody isGetter
  returnType: int
''');
  }

  test_unit_setter() async {
    await _assertIntrospectText(r'''
@Introspect()
set foo(int value) {}
''', r'''
foo
  flags: hasBody isSetter
  positionalParameters
    value
      flags: isRequired
      type: int
  returnType: OmittedType
''');
  }

  test_unit_variable_flags_hasConst_true() async {
    await _assertIntrospectText(r'''
@Introspect()
const foo = 0;
''', r'''
foo
  flags: hasConst hasInitializer
  type: OmittedType
''');
  }

  test_unit_variable_flags_hasExternal_true() async {
    await _assertIntrospectText(r'''
@Introspect()
external int foo;
''', r'''
foo
  flags: hasExternal
  type: int
''');
  }

  test_unit_variable_flags_hasFinal_false() async {
    await _assertIntrospectText(r'''
@Introspect()
var foo = 0;
''', r'''
foo
  flags: hasInitializer
  type: OmittedType
''');
  }

  test_unit_variable_flags_hasFinal_true() async {
    await _assertIntrospectText(r'''
@Introspect()
final foo = 0;
''', r'''
foo
  flags: hasFinal hasInitializer
  type: OmittedType
''');
  }

  test_unit_variable_flags_hasLate_true() async {
    await _assertIntrospectText(r'''
@Introspect()
late int foo;
''', r'''
foo
  flags: hasLate
  type: int
''');
  }

  test_unit_variable_metadata() async {
    await _assertIntrospectText(r'''
@Introspect(withMetadata: true)
@a1
@a2
final foo = 0;

const a1 = 0;
const a2 = 0;
''', r'''
foo
  flags: hasFinal hasInitializer
  metadata
    ConstructorMetadataAnnotation
      type: Introspect
    IdentifierMetadataAnnotation
      identifier: a1
    IdentifierMetadataAnnotation
      identifier: a2
  type: OmittedType
''');
  }

  test_unit_variable_type_explicit() async {
    await _assertIntrospectText(r'''
@Introspect()
final num foo = 0;
''', r'''
foo
  flags: hasFinal hasInitializer
  type: num
''');
  }

  test_unit_variable_type_implicit() async {
    await _assertIntrospectText(r'''
@Introspect()
final foo = 0;
''', r'''
foo
  flags: hasFinal hasInitializer
  type: OmittedType
''');
  }

  /// Assert that the textual dump of the introspection information produced
  /// by `IntrospectTypesPhaseMacro` in [code], is the [expected].
  Future<void> _assertIntrospectText(
    String code,
    String expected,
  ) async {
    var actual = await _getIntrospectText(code);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      print('-------- Actual --------');
      print('$actual------------------------');
    }
    expect(actual, expected);
  }

  /// The [code] should have exactly one application of `IntrospectMacro`.
  /// It may contain arbitrary code otherwise.
  ///
  /// The macro generates a top-level constant `_introspect`, with a string
  /// literal initializer - the textual dump of the introspection.
  Future<String> _getIntrospectText(String code) async {
    newFile(
      '$testPackageLibPath/introspect.dart',
      _getMacroCode('introspect.dart'),
    );

    var library = await buildLibrary('''
import 'introspect.dart';
$code
''');

    if (library.allMacroDiagnostics.isNotEmpty) {
      failWithLibraryText(library);
    }

    return library.topLevelElements
        .whereType<ConstTopLevelVariableElementImpl>()
        .where((e) => e.name == '_introspect')
        .map((e) => (e.constantInitializer as SimpleStringLiteral).value)
        .join('\n');
  }
}

@reflectiveTest
class MacroStaticTypeTest extends MacroElementsBaseTest {
  @override
  bool get keepLinkingLibraries => true;

  @override
  Future<void> setUp() async {
    await super.setUp();

    newFile(
      '$testPackageLibPath/static_type.dart',
      _getMacroCode('static_type.dart'),
    );
  }

  @TestTimeout(Timeout(Duration(seconds: 60)))
  test_isExactly() async {
    const testCases = {
      ('double', 'double', true),
      ('double', 'int', false),
      ('int', 'double', false),
      ('int', 'int', true),
      ('int', 'void', false),
      ('void', 'void', true),
      // Object
      ('Object?', 'Object?', true),
      ('Object?', 'Object', false),
      ('Object?', 'dynamic', false),
      // InterfaceType, type arguments
      ('List<int>', 'List<double>', false),
      ('List<int>', 'List<int>', true),
      // FunctionType
      //   returnType
      ('void Function()', 'void Function()', true),
      ('void Function()', 'int Function()', false),
      //   typeParameters
      ('void Function<T>()', 'void Function<T>()', true),
      ('void Function<T>()', 'void Function()', false),
      //   positionalParameters
      ('void Function(int a)', 'void Function(int a)', true),
      ('void Function(int a)', 'void Function(double a)', false),
      ('void Function([int a])', 'void Function([int a])', true),
      ('void Function([int a])', 'void Function(int a)', false),
      //   namedParameters
      ('void Function({int a})', 'void Function({int a})', true),
      ('void Function({int a})', 'void Function({double a})', false),
      (
        'void Function({required int a})',
        'void Function({required int a})',
        true,
      ),
      ('void Function({int a})', 'void Function({required int a})', false),
      // RecordType
      ('(int,)', '(int,)', true),
      ('(int,)', '(double,)', false),
      ('({int a,})', '({int a,})', true),
      ('({int a,})', '({int b,})', false),
      ('({int a,})', '({double a,})', false),
      ('({int a,})', '({int a, int b})', false),
    };

    for (var testCase in testCases) {
      await disposeAnalysisContextCollection();
      await _assertIsExactly(
        firstTypeCode: testCase.$1,
        secondTypeCode: testCase.$2,
        isExactly: testCase.$3,
      );
    }
  }

  /// Verify what happens when we use `RawTypeAnnotationCode`.
  /// We don't see it, because it disappears after the types phase.
  test_isExactly_class_asRawCode_same() async {
    var library = await buildLibrary('''
import 'append.dart';
import 'static_type.dart';

@DeclareClassAppendInterfaceRawCode('A')
class X {
  @IsExactly_enclosingClassInterface_formalParameterType()
  void foo(A a) {}
}
''');

    var generated = _getMacroGeneratedCode(library);
    _assertIsExactlyValue(generated, true);
  }

  test_isExactly_enum_notSame() async {
    await _assertIsExactly(
      firstTypeCode: 'A',
      secondTypeCode: 'B',
      isExactly: false,
      additionalDeclarations: r'''
enum A { v }
enum B { v }
''',
    );
  }

  test_isExactly_enum_same() async {
    await _assertIsExactly(
      firstTypeCode: 'A',
      secondTypeCode: 'A',
      isExactly: true,
      additionalDeclarations: r'''
enum A { v }
''',
    );
  }

  test_isExactly_extensionType_notSame() async {
    await _assertIsExactly(
      firstTypeCode: 'A',
      secondTypeCode: 'B',
      isExactly: false,
      additionalDeclarations: r'''
extension type A(int it) {}
extension type B(int it) {}
''',
    );
  }

  test_isExactly_extensionType_same() async {
    await _assertIsExactly(
      firstTypeCode: 'A',
      secondTypeCode: 'A',
      isExactly: true,
      additionalDeclarations: r'''
extension type A(int it) {}
''',
    );
  }

  test_isExactly_mixin_notSame() async {
    await _assertIsExactly(
      firstTypeCode: 'A',
      secondTypeCode: 'B',
      isExactly: false,
      additionalDeclarations: r'''
mixin A {}
mixin B {}
''',
    );
  }

  test_isExactly_mixin_same() async {
    await _assertIsExactly(
      firstTypeCode: 'A',
      secondTypeCode: 'A',
      isExactly: true,
      additionalDeclarations: r'''
mixin A {}
''',
    );
  }

  test_isExactly_namedTypeAnnotation_typeArguments_absent() async {
    await _assertIsExactly(
      firstTypeCode: 'Map',
      secondTypeCode: 'Map<dynamic, dynamic>',
      isExactly: true,
    );
  }

  test_isExactly_omittedType_notSame() async {
    var library = await buildLibrary('''
import 'static_type.dart';

class A {
  void foo(int a, double b) {}
}

class B extends A {
  @IsExactly()
  void foo(a, b) {}
}
''');

    var generated = _getMacroGeneratedCode(library);
    _assertIsExactlyValue(generated, false);
  }

  test_isExactly_omittedType_same() async {
    var library = await buildLibrary('''
import 'static_type.dart';

class A {
  void foo(int a, int b) {}
}

class B extends A {
  @IsExactly()
  void foo(a, b) {}
}
''');

    var generated = _getMacroGeneratedCode(library);
    _assertIsExactlyValue(generated, true);
  }

  test_isExactly_typeParameter_notSame() async {
    var library = await buildLibrary('''
import 'static_type.dart';

@IsExactly()
void foo<T, U>(T a, U b) {}
''');

    var generated = _getMacroGeneratedCode(library);
    _assertIsExactlyValue(generated, false);
  }

  test_isExactly_typeParameter_same() async {
    var library = await buildLibrary('''
import 'static_type.dart';

@IsExactly()
void foo<T>(T a, T b) {}
''');

    var generated = _getMacroGeneratedCode(library);
    _assertIsExactlyValue(generated, true);
  }

  test_isSubtype() async {
    const testCases = {
      ('double', 'double', true),
      ('double', 'num', true),
      ('double', 'int', false),
      ('double', 'Object', true),
      ('int', 'double', false),
      ('int', 'num', true),
      ('int', 'int', true),
      ('int', 'Object', true),
      // Object
      ('Object?', 'Object?', true),
      ('Object?', 'Object', false),
      ('Object', 'Object?', true),
      ('Object', 'Object', true),
      // InterfaceType, type arguments
      ('List<int>', 'List<double>', false),
      ('List<int>', 'List<num>', true),
      ('List<int>', 'List<int>', true),
      // FunctionType
      //   returnType
      ('void Function()', 'void Function()', true),
      ('int Function()', 'double Function()', false),
      ('int Function()', 'num Function()', true),
      ('int Function()', 'int Function()', true),
      // RecordType
      ('(int,)', '(double,)', false),
      ('(int,)', '(num,)', true),
      ('(int,)', '(int,)', true),
      ('({int a,})', '({double a,})', false),
      ('({int a,})', '({num a,})', true),
      ('({int a,})', '({int a,})', true),
      ('({int a,})', '({int b,})', false),
    };

    for (var testCase in testCases) {
      await disposeAnalysisContextCollection();
      await _assertIsSubtype(
        firstTypeCode: testCase.$1,
        secondTypeCode: testCase.$2,
        isSubtype: testCase.$3,
      );
    }
  }

  Future<void> _assertIsExactly({
    required String firstTypeCode,
    required String secondTypeCode,
    required bool isExactly,
    String additionalDeclarations = '',
  }) async {
    var library = await buildLibrary('''
import 'static_type.dart';

$additionalDeclarations

@IsExactly()
void foo($firstTypeCode a, $secondTypeCode b) {}
''');

    var generated = _getMacroGeneratedCode(library);
    var expected = _isExactlyExpected(isExactly);
    if (!generated.contains(expected)) {
      fail(
        '`$firstTypeCode` isExactly `$secondTypeCode`'
        ' expected to be `$isExactly`, but is not.\n',
      );
    }
  }

  void _assertIsExactlyValue(String generated, bool isExactly) {
    var expected = _isExactlyExpected(isExactly);
    expect(generated, contains(expected));
  }

  Future<void> _assertIsSubtype({
    required String firstTypeCode,
    required String secondTypeCode,
    required bool isSubtype,
    String additionalDeclarations = '',
  }) async {
    var library = await buildLibrary('''
import 'static_type.dart';

$additionalDeclarations

@IsSubtype()
void foo($firstTypeCode a, $secondTypeCode b) {}
''');

    var generated = _getMacroGeneratedCode(library);
    var expected = _isSubtypeExpected(isSubtype);
    if (!generated.contains(expected)) {
      fail(
        '`$firstTypeCode` isSubtype `$secondTypeCode`'
        ' expected to be `$isSubtype`, but is not.\n',
      );
    }
  }

  String _isExactlyExpected(bool isExactly) {
    return '=> $isExactly; // isExactly';
  }

  String _isSubtypeExpected(bool isSubtype) {
    return '=> $isSubtype; // isSubtype';
  }
}

abstract class MacroTypesTest extends MacroElementsBaseTest {
  final List<io.Directory> _ioDirectoriesToDelete = [];

  @override
  bool get retainDataForTesting => true;

  @override
  Future<void> tearDown() async {
    for (var directory in _ioDirectoriesToDelete) {
      try {
        directory.deleteSync(
          recursive: true,
        );
      } catch (_) {}
    }

    return super.tearDown();
  }

  test_application_newInstance_withoutPrefix() async {
    var library = await buildLibrary(r'''
import 'append.dart';

@DeclareType('A', 'class MyClass {}')
class A {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @67
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

class MyClass {}
---
      classes
        class MyClass @41
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/append.dart
      classes
        class A @67
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class MyClass @41
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
          element: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
    class MyClass
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
''');
  }

  test_application_newInstance_withoutPrefix_namedConstructor() async {
    var library = await buildLibrary(r'''
import 'append.dart';

@DeclareType.named('A', 'class MyClass {}')
class A {}
''');

    configuration.withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @73
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

class MyClass {}
---
      classes
        class MyClass @41
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/append.dart
      classes
        class A @73
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class MyClass @41
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
          element: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass#element
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass::@constructor::new
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass::@constructor::new#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class MyClass
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass::@constructor::new
''');
  }

  test_application_newInstance_withPrefix() async {
    var library = await buildLibrary(r'''
import 'append.dart' as prefix;

@prefix.DeclareType('A', 'class MyClass {}')
class A {}
''');

    configuration.withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart as prefix @24
      enclosingElement3: <testLibraryFragment>
  prefixes
    prefix @24
      reference: <testLibraryFragment>::@prefix::prefix
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart as prefix @24
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        prefix @24
          reference: <testLibraryFragment>::@prefix::prefix
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @84
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

class MyClass {}
---
      classes
        class MyClass @41
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/append.dart as prefix @24
      prefixes
        <testLibraryFragment>::@prefix2::prefix
          fragments: @24
      classes
        class A @84
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class MyClass @41
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
          element: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass#element
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass::@constructor::new
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass::@constructor::new#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class MyClass
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass::@constructor::new
''');
  }

  test_application_newInstance_withPrefix_namedConstructor() async {
    var library = await buildLibrary(r'''
import 'append.dart' as prefix;

@prefix.DeclareType.named('A', 'class MyClass {}')
class A {}
''');

    configuration.withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart as prefix @24
      enclosingElement3: <testLibraryFragment>
  prefixes
    prefix @24
      reference: <testLibraryFragment>::@prefix::prefix
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart as prefix @24
          enclosingElement3: <testLibraryFragment>
      libraryImportPrefixes
        prefix @24
          reference: <testLibraryFragment>::@prefix::prefix
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @90
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
          constructors
            synthetic @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              enclosingElement3: <testLibraryFragment>::@class::A
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

class MyClass {}
---
      classes
        class MyClass @41
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          constructors
            synthetic @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass::@constructor::new
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/append.dart as prefix @24
      prefixes
        <testLibraryFragment>::@prefix2::prefix
          fragments: @24
      classes
        class A @90
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
          constructors
            synthetic new @-1
              reference: <testLibraryFragment>::@class::A::@constructor::new
              element: <testLibraryFragment>::@class::A::@constructor::new#element
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class MyClass @41
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
          element: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass#element
          constructors
            synthetic new @-1
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass::@constructor::new
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass::@constructor::new#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
      constructors
        synthetic new
          firstFragment: <testLibraryFragment>::@class::A::@constructor::new
    class MyClass
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
      constructors
        synthetic new
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass::@constructor::new
''');
  }

  test_declareType_exported() async {
    var library = await buildLibrary(r'''
import 'append.dart';

@DeclareType('B', 'class B {}')
class A {}
''');

    configuration
      ..withConstructors = false
      ..withExportScope = true
      ..withMetadata = false
      ..withPropertyLinking = true;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @61
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

class B {}
---
      classes
        class B @41
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
  exportedReferences
    declared <testLibraryFragment>::@class::A
    declared <testLibrary>::@fragment::package:test/test.macro.dart::@class::B
  exportNamespace
    A: <testLibraryFragment>::@class::A
    B: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/append.dart
      classes
        class A @61
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class B @41
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B
          element: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
    class B
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B
  exportedReferences
    declared <testLibraryFragment>::@class::A
    declared <testLibrary>::@fragment::package:test/test.macro.dart::@class::B
  exportNamespace
    A: <testLibraryFragment>::@class::A
    B: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B
''');
  }

  test_executable() async {
    // We use AOT executables only on Linux.
    if (resourceProvider.pathContext.style != package_path.Style.posix) {
      return;
    }

    // No need to verify reading elements for this test.
    if (!keepLinkingLibraries) {
      return;
    }

    const macroCode = r'''
import 'package:macros/macros.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) async {
    builder.declareType(
      'MyClass',
      DeclarationCode.fromString('class MyClass {}'),
    );
  }
}
''';

    // Compile the macro to executable.
    io.File macroExecutable;
    {
      var macroMainContent = macro.bootstrapMacroIsolate(
        {
          'package:test/a.dart': {
            'MyMacro': ['']
          },
        },
        macro.SerializationMode.byteData,
      );

      var tempCompileDirectory =
          io.Directory.systemTemp.createTempSync('dartAnalyzerMacro');
      _ioDirectoriesToDelete.add(tempCompileDirectory);

      var fileSystem = PhysicalResourceProvider.INSTANCE;
      var compileRoot = fileSystem.getFolder(tempCompileDirectory.path);

      var testRoot = compileRoot.getChildAssumingFolder('test');
      testRoot.newFile('lib/a.dart').writeAsStringSync(macroCode);

      var testBin = testRoot.getChildAssumingFolder('bin');
      var testMain = testBin.newFile('main.dart');
      testMain.writeAsStringSync(macroMainContent);

      MacrosEnvironment.instance.privateMacrosFolder.copyTo(compileRoot);
      MacrosEnvironment.instance.publicMacrosFolder.copyTo(compileRoot);

      compileRoot
          .newFile('.dart_tool/package_config.json')
          .writeAsStringSync(r'''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../test",
      "packageUri": "lib/"
    },
    {
      "name": "_macros",
      "rootUri": "../_macros",
      "packageUri": "lib/"
    },
    {
      "name": "macros",
      "rootUri": "../macros",
      "packageUri": "lib/"
    }
  ]
}
''');

      var process = await io.Process.start(
        io.Platform.executable,
        ['compile', 'exe', '--enable-experiment=macros', testMain.path],
      );

      var exitCode = await process.exitCode;
      if (exitCode == 255 || exitCode == 64) {
        markTestSkipped('Skip because cannot compile.');
        return;
      }
      expect(exitCode, isZero);

      var executable = testBin.getChildAssumingFile('main.exe');
      expect(executable.exists, isTrue);

      // Convert to io.File
      macroExecutable = io.File(executable.path);
    }

    // Build the summary for `a.dart`, with the macro.
    // We always have summaries for libraries with macro executable.
    Uint8List aBundleBytes;
    {
      var a = newFile('$testPackageLibPath/a.dart', macroCode);

      // Disable compilation to kernel.
      macroSupportFactory = ExecutableMacroSupportFactory(
        configure: (_) {},
      );

      var analysisDriver = driverFor(a);
      aBundleBytes = await analysisDriver.buildPackageBundle(
        uriList: [
          Uri.parse('package:_macros/src/api.dart'),
          Uri.parse('package:macros/macros.dart'),
          Uri.parse('package:test/a.dart'),
        ],
      );

      // We should not read the file anyway, but we make it explicit.
      a.delete();
    }

    await disposeAnalysisContextCollection();
    useEmptyByteStore();

    // Configure summaries.
    {
      sdkSummaryFile = await writeSdkSummary();

      var aBundleFile = getFile('/home/summaries/a.sum');
      aBundleFile.writeAsBytesSync(aBundleBytes);
      librarySummaryFiles = [aBundleFile];
    }

    // Configure the macro executor.
    macroSupportFactory = ExecutableMacroSupportFactory(
      configure: (macroSupport) {
        macroSupport.add(
          executable: macroExecutable,
          libraries: {
            Uri.parse('package:test/a.dart'),
          },
        );
      },
    );

    // Verify that we can use the executable to run the macro.
    {
      var library = await buildLibrary(r'''
import 'a.dart';

@MyMacro()
class A {}
''');
      configuration
        ..withConstructors = false
        ..withMetadata = false;
      checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @35
          reference: <testLibraryFragment>::@class::A
          enclosingElement3: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

class MyClass {}
---
      classes
        class MyClass @41
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/a.dart
      classes
        class A @35
          reference: <testLibraryFragment>::@class::A
          element: <testLibraryFragment>::@class::A#element
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class MyClass @41
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
          element: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass#element
  classes
    class A
      firstFragment: <testLibraryFragment>::@class::A
    class MyClass
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
''');
    }
  }

  test_imports_class() async {
    useEmptyByteStore();

    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'dart:async';
import 'package:macros/macros.dart';
import 'a.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, ClassTypeBuilder builder) async {
    final identifier = await builder.resolveIdentifier(
      Uri.parse('package:test/a.dart'),
      'A',
    );
    builder.declareType(
      'MyClass',
      DeclarationCode.fromParts([
        'class MyClass {\n  void foo(',
        identifier,
        ' _) {}\n}',
      ]),
    );
  }
}
''');

    var library = await buildLibrary(r'''
import 'b.dart';

@MyMacro()
class X {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/b.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/b.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class X @35
          reference: <testLibraryFragment>::@class::X
          enclosingElement3: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

class MyClass {
  void foo(prefix0.A _) {}
}
---
      libraryImports
        package:test/a.dart as prefix0 @67
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImportPrefixes
        prefix0 @67
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class MyClass @83
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
          methods
            foo @100
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass::@method::foo
              enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
              parameters
                requiredPositional _ @114
                  type: A
              returnType: void
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/b.dart
      classes
        class X @35
          reference: <testLibraryFragment>::@class::X
          element: <testLibraryFragment>::@class::X#element
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart as prefix0 @67
      prefixes
        <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
          fragments: @67
      classes
        class MyClass @83
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
          element: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass#element
          methods
            foo @100
              reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass::@method::foo
              element: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass::@method::foo#element
              formalParameters
                _ @114
                  element: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass::@method::foo::@parameter::_#element
  classes
    class X
      firstFragment: <testLibraryFragment>::@class::X
    class MyClass
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass
      methods
        foo
          firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::MyClass::@method::foo
          formalParameters
            requiredPositional _
              type: A
''');

    analyzerStatePrinterConfiguration.filesToPrintContent.add(
      getFile('$testPackageLibPath/test.macro.dart'),
    );

    if (keepLinkingLibraries) {
      assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_12 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_1
      referencingFiles: file_1 file_3
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_14 dart:async
          library_11 package:macros/macros.dart
          library_0
          library_12 dart:core synthetic
        fileKinds: library_1
        cycle_1
          dependencies: cycle_0 dart:core package:macros/macros.dart
          libraries: library_1
          apiSignature_1
          users: cycle_2
      referencingFiles: file_2
      unlinkedKey: k01
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_1
          library_12 dart:core synthetic
        partIncludes
          partOfUriKnown_3
        fileKinds: library_2 partOfUriKnown_3
        cycle_2
          dependencies: cycle_1 dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/test.macro.dart
    uri: package:test/test.macro.dart
    current
      id: file_3
      content
---
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

class MyClass {
  void foo(prefix0.A _) {}
}
---
      kind: partOfUriKnown_3
        uriFile: file_2
        library: library_2
        libraryImports
          library_0
      referencingFiles: file_2
      unlinkedKey: k03
libraryCycles
  /home/test/lib/a.dart
    current: cycle_0
      key: k04
    get: []
    put: [k04]
  /home/test/lib/b.dart
    current: cycle_1
      key: k05
    get: []
    put: [k05]
  /home/test/lib/test.dart
    current: cycle_2
      key: k06
    get: []
    put: [k06]
elementFactory
  hasElement
    package:test/a.dart
    package:test/b.dart
    package:test/test.dart
''');

      // When we discard the library, we keep its macro file.
      driverFor(testFile).changeFile(testFile.path);
      await driverFor(testFile).applyPendingFileChanges();
      assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_12 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_1
      referencingFiles: file_1 file_3
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_14 dart:async
          library_11 package:macros/macros.dart
          library_0
          library_12 dart:core synthetic
        fileKinds: library_1
        cycle_1
          dependencies: cycle_0 dart:core package:macros/macros.dart
          libraries: library_1
          apiSignature_1
          users: cycle_7
      referencingFiles: file_2
      unlinkedKey: k01
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_2
      kind: library_18
        libraryImports
          library_1
          library_12 dart:core synthetic
        fileKinds: library_18
        cycle_7
          dependencies: cycle_1 dart:core
          libraries: library_18
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/test.macro.dart
    uri: package:test/test.macro.dart
    current
      id: file_3
      content
---
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

class MyClass {
  void foo(prefix0.A _) {}
}
---
      kind: partOfUriKnown_3
        uriFile: file_2
        libraryImports
          library_0
      referencingFiles: file_2
      unlinkedKey: k03
libraryCycles
  /home/test/lib/a.dart
    current: cycle_0
      key: k04
    get: []
    put: [k04]
  /home/test/lib/b.dart
    current: cycle_1
      key: k05
    get: []
    put: [k05]
  /home/test/lib/test.dart
    get: []
    put: [k06]
elementFactory
  hasElement
    package:test/a.dart
    package:test/b.dart
''');
    } else {
      assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_12 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_1
      referencingFiles: file_1 file_3
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_14 dart:async
          library_11 package:macros/macros.dart
          library_0
          library_12 dart:core synthetic
        fileKinds: library_1
        cycle_1
          dependencies: cycle_0 dart:core package:macros/macros.dart
          libraries: library_1
          apiSignature_1
          users: cycle_2
      referencingFiles: file_2
      unlinkedKey: k01
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_2
      kind: library_2
        libraryImports
          library_1
          library_12 dart:core synthetic
        partIncludes
          partOfUriKnown_3
        fileKinds: library_2 partOfUriKnown_3
        cycle_2
          dependencies: cycle_1 dart:core
          libraries: library_2
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/test.macro.dart
    uri: package:test/test.macro.dart
    current
      id: file_3
      content
---
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

class MyClass {
  void foo(prefix0.A _) {}
}
---
      kind: partOfUriKnown_3
        uriFile: file_2
        library: library_2
        libraryImports
          library_0
      referencingFiles: file_2
      unlinkedKey: k03
libraryCycles
  /home/test/lib/a.dart
    current: cycle_0
      key: k04
    get: []
    put: [k04]
  /home/test/lib/b.dart
    current: cycle_1
      key: k05
    get: []
    put: [k05]
  /home/test/lib/test.dart
    current: cycle_2
      key: k06
    get: [k06]
    put: [k06]
elementFactory
  hasElement
    package:test/a.dart
    package:test/b.dart
    package:test/test.dart
  hasReader
    package:test/test.dart
''');
    }
  }

  test_iterate_merge() async {
    useEmptyByteStore();

    newFile('$testPackageLibPath/a.dart', r'''
import 'package:macros/macros.dart';

macro class AddClassA implements ClassTypesMacro {
  const AddClassA();

  buildTypesForClass(clazz, builder) async {
    final identifier = await builder.resolveIdentifier(
      Uri.parse('package:test/a.dart'),
      'AddClassB',
    );
    builder.declareType(
      'MyClass',
      DeclarationCode.fromParts([
        '@',
        identifier,
        '()\nclass A {}\n',
      ]),
    );
  }
}

macro class AddClassB implements ClassTypesMacro {
  const AddClassB();

  buildTypesForClass(clazz, builder) async {
    builder.declareType(
      'B',
      DeclarationCode.fromString('class B {}\n'),
    );
  }
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';

@AddClassA()
class X {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class X @37
          reference: <testLibraryFragment>::@class::X
          enclosingElement3: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

@prefix0.AddClassB()
class A {}

class B {}

---
      libraryImports
        package:test/a.dart as prefix0 @67
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImportPrefixes
        prefix0 @67
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@prefix::prefix0
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class A @104
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::A
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
        class B @116
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/a.dart
      classes
        class X @37
          reference: <testLibraryFragment>::@class::X
          element: <testLibraryFragment>::@class::X#element
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      libraryImports
        package:test/a.dart as prefix0 @67
      prefixes
        <testLibrary>::@fragment::package:test/test.macro.dart::@prefix2::prefix0
          fragments: @67
      classes
        class A @104
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::A
          element: <testLibrary>::@fragment::package:test/test.macro.dart::@class::A#element
        class B @116
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B
          element: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B#element
  classes
    class X
      firstFragment: <testLibraryFragment>::@class::X
    class A
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::A
    class B
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::B
''');

    analyzerStatePrinterConfiguration.filesToPrintContent.add(
      getFile('$testPackageLibPath/test.macro.dart'),
    );

    if (keepLinkingLibraries) {
      assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_10 package:macros/macros.dart
          library_11 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core package:macros/macros.dart
          libraries: library_0
          apiSignature_0
          users: cycle_1
      referencingFiles: file_1 file_2
      unlinkedKey: k00
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_0
          library_11 dart:core synthetic
        partIncludes
          partOfUriKnown_2
        fileKinds: library_1 partOfUriKnown_2
        cycle_1
          dependencies: cycle_0 dart:core
          libraries: library_1
          apiSignature_1
      unlinkedKey: k01
  /home/test/lib/test.macro.dart
    uri: package:test/test.macro.dart
    current
      id: file_2
      content
---
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

@prefix0.AddClassB()
class A {}

class B {}

---
      kind: partOfUriKnown_2
        uriFile: file_1
        library: library_1
        libraryImports
          library_0
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
  /home/test/lib/a.dart
    current: cycle_0
      key: k03
    get: []
    put: [k03]
  /home/test/lib/test.dart
    current: cycle_1
      key: k04
    get: []
    put: [k04]
elementFactory
  hasElement
    package:test/a.dart
    package:test/test.dart
''');
    } else {
      assertDriverStateString(testFile, r'''
files
  /home/test/lib/a.dart
    uri: package:test/a.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_10 package:macros/macros.dart
          library_11 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core package:macros/macros.dart
          libraries: library_0
          apiSignature_0
          users: cycle_1
      referencingFiles: file_1 file_2
      unlinkedKey: k00
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_0
          library_11 dart:core synthetic
        partIncludes
          partOfUriKnown_2
        fileKinds: library_1 partOfUriKnown_2
        cycle_1
          dependencies: cycle_0 dart:core
          libraries: library_1
          apiSignature_1
      unlinkedKey: k01
  /home/test/lib/test.macro.dart
    uri: package:test/test.macro.dart
    current
      id: file_2
      content
---
part of 'package:test/test.dart';

import 'package:test/a.dart' as prefix0;

@prefix0.AddClassB()
class A {}

class B {}

---
      kind: partOfUriKnown_2
        uriFile: file_1
        library: library_1
        libraryImports
          library_0
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
  /home/test/lib/a.dart
    current: cycle_0
      key: k03
    get: []
    put: [k03]
  /home/test/lib/test.dart
    current: cycle_1
      key: k04
    get: [k04]
    put: [k04]
elementFactory
  hasElement
    package:test/a.dart
    package:test/test.dart
  hasReader
    package:test/test.dart
''');
    }
  }

  test_libraryCycle_class_add() async {
    // Checks https://github.com/dart-lang/sdk/issues/55360
    newFile('$testPackageLibPath/a.dart', r'''
import 'append.dart';

// Just to make it a library cycle.
import 'test.dart';

@DeclareType('X', 'class X {}')
class A {}
''');

    var library = await buildLibrary(r'''
import 'append.dart';
import 'a.dart';

@DeclareType('X', 'class X {}')
class B {}
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: <testLibrary>
  libraryImports
    package:test/append.dart
      enclosingElement3: <testLibraryFragment>
    package:test/a.dart
      enclosingElement3: <testLibraryFragment>
  definingUnit: <testLibraryFragment>
  parts
    part_0
  units
    <testLibraryFragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: <testLibraryFragment>
        package:test/a.dart
          enclosingElement3: <testLibraryFragment>
      parts
        part_0
          uri: package:test/test.macro.dart
          enclosingElement3: <testLibraryFragment>
          unit: <testLibrary>::@fragment::package:test/test.macro.dart
      classes
        class B @78
          reference: <testLibraryFragment>::@class::B
          enclosingElement3: <testLibraryFragment>
    <testLibrary>::@fragment::package:test/test.macro.dart
      enclosingElement3: <testLibraryFragment>
      macroGeneratedCode
---
part of 'package:test/test.dart';

class X {}
---
      classes
        class X @41
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::X
          enclosingElement3: <testLibrary>::@fragment::package:test/test.macro.dart
----------------------------------------
library
  reference: <testLibrary>
  fragments
    <testLibraryFragment>
      element: <testLibrary>
      nextFragment: <testLibrary>::@fragment::package:test/test.macro.dart
      libraryImports
        package:test/append.dart
        package:test/a.dart
      classes
        class B @78
          reference: <testLibraryFragment>::@class::B
          element: <testLibraryFragment>::@class::B#element
    <testLibrary>::@fragment::package:test/test.macro.dart
      element: <testLibrary>
      previousFragment: <testLibraryFragment>
      classes
        class X @41
          reference: <testLibrary>::@fragment::package:test/test.macro.dart::@class::X
          element: <testLibrary>::@fragment::package:test/test.macro.dart::@class::X#element
  classes
    class B
      firstFragment: <testLibraryFragment>::@class::B
    class X
      firstFragment: <testLibrary>::@fragment::package:test/test.macro.dart::@class::X
''');
  }

  test_macroGeneratedFile_changeLibrary_noMacroApplication_restore() async {
    if (!keepLinkingLibraries) return;
    useEmptyByteStore();

    var library = await buildLibrary(r'''
import 'append.dart';

@DeclareTypesPhase('B', 'class B {}')
class A {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

class B {}
''');

    // Note that we have `test.macro.dart` file.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/append.dart
    uri: package:test/append.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_10 package:macros/macros.dart
          library_11 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core package:macros/macros.dart
          libraries: library_0
          apiSignature_0
          users: cycle_1
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_0
          library_11 dart:core synthetic
        partIncludes
          partOfUriKnown_2
        fileKinds: library_1 partOfUriKnown_2
        cycle_1
          dependencies: cycle_0 dart:core
          libraries: library_1
          apiSignature_1
      unlinkedKey: k01
  /home/test/lib/test.macro.dart
    uri: package:test/test.macro.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_1
        library: library_1
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
  /home/test/lib/append.dart
    current: cycle_0
      key: k03
    get: []
    put: [k03]
  /home/test/lib/test.dart
    current: cycle_1
      key: k04
    get: []
    put: [k04]
elementFactory
  hasElement
    package:test/append.dart
    package:test/test.dart
''');

    // Change the library content, no macro applications.
    modifyFile2(testFile, r'''
class A {}
''');
    driverFor(testFile).changeFile2(testFile);

    // Ask the library, will be relinked.
    await driverFor(testFile).getLibraryByUri('package:test/test.dart');

    // For `test.dart`.
    // This is the same `FileState` instance.
    // We refreshed it, it has different `unlinkedKey`, `kind`, `cycle`.
    // We linked new summary, and put it into the byte store.
    //
    // For `test.macro.dart`.
    // This is the same `FileState` instance.
    // We did not refresh it, same `unlinkedKey`, `kind`.
    // Its `kind.library` is empty, `test.dart` does not import it.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/append.dart
    uri: package:test/append.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_10 package:macros/macros.dart
          library_11 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core package:macros/macros.dart
          libraries: library_0
          apiSignature_0
      unlinkedKey: k00
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_1
      kind: library_17
        libraryImports
          library_11 dart:core synthetic
        fileKinds: library_17
        cycle_6
          dependencies: dart:core
          libraries: library_17
          apiSignature_2
      unlinkedKey: k05
  /home/test/lib/test.macro.dart
    uri: package:test/test.macro.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_1
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
  /home/test/lib/append.dart
    current: cycle_0
      key: k03
    get: []
    put: [k03]
  /home/test/lib/test.dart
    current: cycle_6
      key: k06
    get: []
    put: [k04, k06]
elementFactory
  hasElement
    package:test/append.dart
    package:test/test.dart
''');

    // Use the same library as initially.
    modifyFile2(testFile, r'''
import 'append.dart';

@DeclareTypesPhase('B', 'class B {}')
class A {}
''');
    driverFor(testFile).changeFile2(testFile);

    // Ask the library, will be relinked.
    await driverFor(testFile).getLibraryByUri('package:test/test.dart');

    // For `test.dart`.
    // This is the same `FileState` instance.
    // We refreshed it, it has different `unlinkedKey`, `kind`, `cycle`.
    // We read the linked summary, see `get`.
    //
    // For `test.macro.dart`.
    // This is the same `FileState` instance.
    // Its content is the same as it already was, so we did not `refresh()` it.
    // Its `kind.library` now points at the new `kind` of `test.dart`.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/append.dart
    uri: package:test/append.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_10 package:macros/macros.dart
          library_11 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core package:macros/macros.dart
          libraries: library_0
          apiSignature_0
          users: cycle_7
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_1
      kind: library_18
        libraryImports
          library_0
          library_11 dart:core synthetic
        partIncludes
          partOfUriKnown_2
        fileKinds: library_18 partOfUriKnown_2
        cycle_7
          dependencies: cycle_0 dart:core
          libraries: library_18
          apiSignature_1
      unlinkedKey: k01
  /home/test/lib/test.macro.dart
    uri: package:test/test.macro.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_1
        library: library_18
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
  /home/test/lib/append.dart
    current: cycle_0
      key: k03
    get: []
    put: [k03]
  /home/test/lib/test.dart
    current: cycle_7
      key: k04
    get: [k04]
    put: [k04, k06]
elementFactory
  hasElement
    package:test/append.dart
    package:test/test.dart
  hasReader
    package:test/test.dart
''');
  }

  test_macroGeneratedFile_changeLibrary_updateMacroApplication() async {
    if (!keepLinkingLibraries) return;
    useEmptyByteStore();

    var library = await buildLibrary(r'''
import 'append.dart';

@DeclareTypesPhase('B', 'class B {}')
class A {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

class B {}
''');

    // Note that we have `test.macro.dart` file.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/append.dart
    uri: package:test/append.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_10 package:macros/macros.dart
          library_11 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core package:macros/macros.dart
          libraries: library_0
          apiSignature_0
          users: cycle_1
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_0
          library_11 dart:core synthetic
        partIncludes
          partOfUriKnown_2
        fileKinds: library_1 partOfUriKnown_2
        cycle_1
          dependencies: cycle_0 dart:core
          libraries: library_1
          apiSignature_1
      unlinkedKey: k01
  /home/test/lib/test.macro.dart
    uri: package:test/test.macro.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_1
        library: library_1
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
  /home/test/lib/append.dart
    current: cycle_0
      key: k03
    get: []
    put: [k03]
  /home/test/lib/test.dart
    current: cycle_1
      key: k04
    get: []
    put: [k04]
elementFactory
  hasElement
    package:test/append.dart
    package:test/test.dart
''');

    // Change the library content.
    modifyFile2(testFile, r'''
import 'append.dart';

@DeclareTypesPhase('B2', 'class B2 {}')
class A {}
''');
    driverFor(testFile).changeFile2(testFile);

    // Ask the library, will be relinked.
    var result2 =
        await driverFor(testFile).getLibraryByUri('package:test/test.dart');

    // For `test.dart`.
    // This is the same `FileState` instance.
    // We refreshed it, it has different `unlinkedKey`, `kind`, `cycle`.
    // We linked new summary, and put it into the byte store.
    //
    // For `test.macro.dart`.
    // This is the same `FileState` instance.
    // We refreshed it, it has different `unlinkedKey`, `kind`.
    // Its `library` points at `test.dart` library.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/append.dart
    uri: package:test/append.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_10 package:macros/macros.dart
          library_11 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core package:macros/macros.dart
          libraries: library_0
          apiSignature_0
          users: cycle_6
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_1
      kind: library_17
        libraryImports
          library_0
          library_11 dart:core synthetic
        partIncludes
          partOfUriKnown_18
        fileKinds: library_17 partOfUriKnown_18
        cycle_6
          dependencies: cycle_0 dart:core
          libraries: library_17
          apiSignature_2
      unlinkedKey: k05
  /home/test/lib/test.macro.dart
    uri: package:test/test.macro.dart
    current
      id: file_2
      kind: partOfUriKnown_18
        uriFile: file_1
        library: library_17
      referencingFiles: file_1
      unlinkedKey: k06
libraryCycles
  /home/test/lib/append.dart
    current: cycle_0
      key: k03
    get: []
    put: [k03]
  /home/test/lib/test.dart
    current: cycle_6
      key: k07
    get: []
    put: [k04, k07]
elementFactory
  hasElement
    package:test/append.dart
    package:test/test.dart
''');

    // Check that it has `class B2 {}`, as requested.
    result2 as LibraryElementResultImpl;
    _assertMacroCode(result2.element as LibraryElementImpl, r'''
part of 'package:test/test.dart';

class B2 {}
''');
  }

  test_macroGeneratedFile_dispose_restore() async {
    if (!keepLinkingLibraries) return;
    useEmptyByteStore();

    var library = await buildLibrary(r'''
import 'append.dart';

@DeclareTypesPhase('B', 'class B {}')
class A {}
''');

    _assertMacroCode(library, r'''
part of 'package:test/test.dart';

class B {}
''');

    // Note that we have `test.macro.dart` file.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/append.dart
    uri: package:test/append.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_10 package:macros/macros.dart
          library_11 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core package:macros/macros.dart
          libraries: library_0
          apiSignature_0
          users: cycle_1
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_0
          library_11 dart:core synthetic
        partIncludes
          partOfUriKnown_2
        fileKinds: library_1 partOfUriKnown_2
        cycle_1
          dependencies: cycle_0 dart:core
          libraries: library_1
          apiSignature_1
      unlinkedKey: k01
  /home/test/lib/test.macro.dart
    uri: package:test/test.macro.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_1
        library: library_1
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
  /home/test/lib/append.dart
    current: cycle_0
      key: k03
    get: []
    put: [k03]
  /home/test/lib/test.dart
    current: cycle_1
      key: k04
    get: []
    put: [k04]
elementFactory
  hasElement
    package:test/append.dart
    package:test/test.dart
''');

    // "Touch" the library file, so dispose it.
    // But don't load the library yet.
    driverFor(testFile).changeFile2(testFile);
    await pumpEventQueue(times: 5000);

    // For `test.dart`.
    // No `current` in `libraryCycles`, it was disposed.
    // It has a new instance `cycle_X`.
    // Actually the cycle was also disposed, but the printer re-created it.
    //
    // For `test.macro.dart`.
    // It still has the same `current`.
    // No `current` library cycle.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/append.dart
    uri: package:test/append.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_10 package:macros/macros.dart
          library_11 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core package:macros/macros.dart
          libraries: library_0
          apiSignature_0
          users: cycle_6
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_1
      kind: library_17
        libraryImports
          library_0
          library_11 dart:core synthetic
        fileKinds: library_17
        cycle_6
          dependencies: cycle_0 dart:core
          libraries: library_17
          apiSignature_1
      unlinkedKey: k01
  /home/test/lib/test.macro.dart
    uri: package:test/test.macro.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_1
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
  /home/test/lib/append.dart
    current: cycle_0
      key: k03
    get: []
    put: [k03]
  /home/test/lib/test.dart
    get: []
    put: [k04]
elementFactory
  hasElement
    package:test/append.dart
''');

    // Load the library from bytes.
    await driverFor(testFile).getLibraryByUri('package:test/test.dart');

    // For `test.dart`.
    // It has `current` in `libraryCycles`.
    // This is a new instance.
    // It has `get` with the same id as was put before.
    //
    // For `test.macro.dart`.
    // The same instance of `kind` as before.
    // We read the `test.dart` linked summary from bytes, and added the
    // augmentation file `test.macro.dart` from the stored the code. The code
    // was the same as before, so we did not `refresh()` the file. So, we did
    // not change the existing `kind`.
    assertDriverStateString(testFile, r'''
files
  /home/test/lib/append.dart
    uri: package:test/append.dart
    current
      id: file_0
      kind: library_0
        libraryImports
          library_10 package:macros/macros.dart
          library_11 dart:core synthetic
        fileKinds: library_0
        cycle_0
          dependencies: dart:core package:macros/macros.dart
          libraries: library_0
          apiSignature_0
          users: cycle_6
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_1
      kind: library_17
        libraryImports
          library_0
          library_11 dart:core synthetic
        partIncludes
          partOfUriKnown_2
        fileKinds: library_17 partOfUriKnown_2
        cycle_6
          dependencies: cycle_0 dart:core
          libraries: library_17
          apiSignature_1
      unlinkedKey: k01
  /home/test/lib/test.macro.dart
    uri: package:test/test.macro.dart
    current
      id: file_2
      kind: partOfUriKnown_2
        uriFile: file_1
        library: library_17
      referencingFiles: file_1
      unlinkedKey: k02
libraryCycles
  /home/test/lib/append.dart
    current: cycle_0
      key: k03
    get: []
    put: [k03]
  /home/test/lib/test.dart
    current: cycle_6
      key: k04
    get: [k04]
    put: [k04]
elementFactory
  hasElement
    package:test/append.dart
    package:test/test.dart
  hasReader
    package:test/test.dart
''');
  }

  test_multipleAnalysisContexts() async {
    // No need to verify reading elements for this test.
    if (!keepLinkingLibraries) {
      return;
    }

    var otherRootPath = '$workspaceRootPath/other';
    var otherPackageConfig = PackageConfigFileBuilder()
      ..add(name: 'test', rootPath: testPackageRootPath)
      ..add(name: 'other', rootPath: otherRootPath);
    addMacrosEnvironment(
      otherPackageConfig,
      MacrosEnvironment.instance,
    );
    writePackageConfig(
      otherRootPath,
      otherPackageConfig,
    );

    newAnalysisOptionsYamlFile(
      otherRootPath,
      analysisOptionsContent(experiments: experiments),
    );

    var file = newFile('$otherRootPath/lib/other.dart', r'''
import 'package:test/append.dart';

@DeclareType('B', 'class B {}')
class A {}
''');

    // Load the macro itself, in `package:test` analysis context.
    await libraryElementForFile(
      getFile('$testPackageLibPath/append.dart'),
    );

    // Load the macro from dependency, in `package:other` analysis context.
    // It should not crash.
    var library = await libraryElementForFile(file);

    // ...but check it a little more.
    configuration
      ..withConstructors = false
      ..withMetadata = false;
    checkElementText(library, r'''
library
  reference: package:other/other.dart
  libraryImports
    package:test/append.dart
      enclosingElement3: package:other/other.dart::<fragment>
  definingUnit: package:other/other.dart::<fragment>
  parts
    part_0
  units
    package:other/other.dart::<fragment>
      enclosingElement3: <null>
      libraryImports
        package:test/append.dart
          enclosingElement3: package:other/other.dart::<fragment>
      parts
        part_0
          uri: package:other/other.macro.dart
          enclosingElement3: package:other/other.dart::<fragment>
          unit: package:other/other.dart::@fragment::package:other/other.macro.dart
      classes
        class A @74
          reference: package:other/other.dart::<fragment>::@class::A
          enclosingElement3: package:other/other.dart::<fragment>
    package:other/other.dart::@fragment::package:other/other.macro.dart
      enclosingElement3: package:other/other.dart::<fragment>
      macroGeneratedCode
---
part of 'package:other/other.dart';

class B {}
---
      classes
        class B @43
          reference: package:other/other.dart::@fragment::package:other/other.macro.dart::@class::B
          enclosingElement3: package:other/other.dart::@fragment::package:other/other.macro.dart
----------------------------------------
library
  reference: package:other/other.dart
  fragments
    package:other/other.dart::<fragment>
      element: package:other/other.dart
      nextFragment: package:other/other.dart::@fragment::package:other/other.macro.dart
      libraryImports
        package:test/append.dart
      classes
        class A @74
          reference: package:other/other.dart::<fragment>::@class::A
          element: package:other/other.dart::<fragment>::@class::A#element
    package:other/other.dart::@fragment::package:other/other.macro.dart
      element: package:other/other.dart
      previousFragment: package:other/other.dart::<fragment>
      classes
        class B @43
          reference: package:other/other.dart::@fragment::package:other/other.macro.dart::@class::B
          element: package:other/other.dart::@fragment::package:other/other.macro.dart::@class::B#element
  classes
    class A
      firstFragment: package:other/other.dart::<fragment>::@class::A
    class B
      firstFragment: package:other/other.dart::@fragment::package:other/other.macro.dart::@class::B
''');
  }
}

@reflectiveTest
class MacroTypesTest_fromBytes extends MacroTypesTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class MacroTypesTest_keepLinking extends MacroTypesTest {
  @override
  bool get keepLinkingLibraries => true;
}

class _MacroDiagnosticsCollector extends GeneralizingElementVisitor<void> {
  final List<AnalyzerMacroDiagnostic> diagnostics = [];

  @override
  void visitElement(Element element) {
    if (element case MacroTargetElement element) {
      diagnostics.addAll(element.macroDiagnostics);
    }

    super.visitElement(element);
  }
}

extension on LibraryElement {
  List<AnalyzerMacroDiagnostic> get allMacroDiagnostics {
    var collector = _MacroDiagnosticsCollector();
    accept(collector);
    return collector.diagnostics;
  }
}

extension on Folder {
  File newFile(String relPath) {
    var file = getChildAssumingFile(relPath);
    file.parent.create();
    return file;
  }
}

extension on ElementTextConfiguration {
  void forCodeOptimizer() {
    filter = (obj) {
      if (obj is CompilationUnitElement) {
        return false;
      }
      return true;
    };
    withConstructors = false;
    withMetadata = true;
  }
}
