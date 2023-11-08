// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/macros/bootstrap.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/serialization.dart'
    as macro;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/macro.dart';
import 'package:analyzer/src/summary2/macro_application_error.dart';
import 'package:analyzer/src/test_utilities/mock_packages.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:path/path.dart' as package_path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

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
    defineReflectiveTests(MacroTypesIntrospectTest);
    defineReflectiveTests(MacroTypesTest_keepLinking);
    defineReflectiveTests(MacroTypesTest_fromBytes);
    defineReflectiveTests(MacroDeclarationsIntrospectTest);
    defineReflectiveTests(MacroDeclarationsTest_keepLinking);
    defineReflectiveTests(MacroDeclarationsTest_fromBytes);
    defineReflectiveTests(MacroElementsTest_keepLinking);
    defineReflectiveTests(MacroElementsTest_fromBytes);
    defineReflectiveTests(MacroApplicationOrderTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MacroApplicationOrderTest extends MacroElementsBaseTest {
  @override
  bool get keepLinkingLibraries => true;

  String get _orderCode {
    var code = MacrosEnvironment.instance.packageAnalyzerFolder
        .getChildAssumingFile('test/src/summary/macro/order.dart')
        .readAsStringSync();
    return code.replaceAll('/*macro*/', 'macro');
  }

  test_declarations_class_interfaces_backward() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddFunction('f31')
@AddFunction('f32')
class X3 {}

@AddFunction('f21')
@AddFunction('f22')
class X2 {}

@AddFunction('f11')
@AddFunction('f12')
class X1 implements X2, X3 {}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

void f32() {}
void f31() {}
void f22() {}
void f21() {}
void f12() {}
void f11() {}
---
''');
  }

  test_declarations_class_interfaces_forward() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddFunction('f11')
@AddFunction('f12')
class X1 implements X2, X3 {}

@AddFunction('f21')
@AddFunction('f22')
class X2 {}

@AddFunction('f31')
@AddFunction('f32')
class X3 {}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

void f22() {}
void f21() {}
void f32() {}
void f31() {}
void f12() {}
void f11() {}
---
''');
  }

  test_declarations_class_interfaces_forward2() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddFunction('f11')
@AddFunction('f12')
class X1 implements X3, X4 {}

@AddFunction('f21')
@AddFunction('f22')
class X2 implements X3, X4 {}

@AddFunction('f31')
@AddFunction('f32')
class X3 {}

@AddFunction('f41')
@AddFunction('f42')
class X4 {}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

void f32() {}
void f31() {}
void f42() {}
void f41() {}
void f12() {}
void f11() {}
void f22() {}
void f21() {}
---
''');
  }

  test_declarations_class_interfaces_forward3() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddFunction('f11')
@AddFunction('f12')
class X1 implements X2, X4 {}

@AddFunction('f21')
@AddFunction('f22')
class X2 implements X3 {}

@AddFunction('f31')
@AddFunction('f32')
class X3 {}

@AddFunction('f41')
@AddFunction('f42')
class X4 {}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

void f32() {}
void f31() {}
void f22() {}
void f21() {}
void f42() {}
void f41() {}
void f12() {}
void f11() {}
---
''');
  }

  test_declarations_class_mixins_backward() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddFunction('f31')
@AddFunction('f32')
mixin X3 {}

@AddFunction('f21')
@AddFunction('f22')
mixin X2 {}

@AddFunction('f11')
@AddFunction('f12')
class X1 with X2, X3 {}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

void f32() {}
void f31() {}
void f22() {}
void f21() {}
void f12() {}
void f11() {}
---
''');
  }

  test_declarations_class_mixins_forward() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddFunction('f11')
@AddFunction('f12')
class X1 with X2, X3 {}

@AddFunction('f21')
@AddFunction('f22')
mixin X2 {}

@AddFunction('f31')
@AddFunction('f32')
mixin X3 {}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

void f22() {}
void f21() {}
void f32() {}
void f31() {}
void f12() {}
void f11() {}
---
''');
  }

  test_declarations_class_superclass_backward() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddFunction('f3')
class X3 extends X2 {
  @AddFunction('f31')
  void foo() {}

  @AddFunction('f32')
  void bar() {}
}

@AddFunction('f2')
class X2 extends X1 {
  @AddFunction('f21')
  void foo() {}

  @AddFunction('f22')
  void bar() {}
}

@AddFunction('f1')
class X1 {
  @AddFunction('f11')
  void foo() {}

  @AddFunction('f12')
  void bar() {}
}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

void f11() {}
void f12() {}
void f1() {}
void f21() {}
void f22() {}
void f2() {}
void f31() {}
void f32() {}
void f3() {}
---
''');
  }

  test_declarations_class_superclass_forward() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddFunction('f1')
class X1 {
  @AddFunction('f11')
  void foo() {}

  @AddFunction('f12')
  void bar() {}
}

@AddFunction('f2')
class X2 extends X1 {
  @AddFunction('f21')
  void foo() {}

  @AddFunction('f22')
  void bar() {}
}

@AddFunction('f3')
class X3 extends X2 {
  @AddFunction('f31')
  void foo() {}

  @AddFunction('f32')
  void bar() {}
}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

void f11() {}
void f12() {}
void f1() {}
void f21() {}
void f22() {}
void f2() {}
void f31() {}
void f32() {}
void f3() {}
---
''');
  }

  test_declarations_class_superClass_mixins_interfaces_backward() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddFunction('f41')
@AddFunction('f42')
class X4 {}

@AddFunction('f31')
@AddFunction('f32')
mixin X3 {}

@AddFunction('f21')
@AddFunction('f22')
class X2 {}

@AddFunction('f11')
@AddFunction('f12')
class X1 extends X2 with X3 implements X4 {}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

void f42() {}
void f41() {}
void f32() {}
void f31() {}
void f22() {}
void f21() {}
void f12() {}
void f11() {}
---
''');
  }

  test_declarations_class_superClass_mixins_interfaces_forward() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddFunction('f11')
@AddFunction('f12')
class X1 extends X2 with X3 implements X4 {}

@AddFunction('f21')
@AddFunction('f22')
class X2 {}

@AddFunction('f31')
@AddFunction('f32')
mixin X3 {}

@AddFunction('f41')
@AddFunction('f42')
class X4 {}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

void f22() {}
void f21() {}
void f32() {}
void f31() {}
void f42() {}
void f41() {}
void f12() {}
void f11() {}
---
''');
  }

  test_declarations_libraryCycle_class_interfaces() async {
    useEmptyByteStore();
    _newOrderMacrosFile();

    newFile('$testPackageLibPath/x2.dart', r'''
import 'test.dart';
import 'order.dart';

@AddHierarchyMethod('f211')
@AddHierarchyMethod('f212')
class X21 {}

@AddHierarchyMethod('f221')
@AddHierarchyMethod('f222')
class X22 {}
''');

    final testLibrary = await buildLibrary(r'''
import 'order.dart';
import 'x2.dart';

@AddHierarchyMethod('f11')
@AddHierarchyMethod('f12')
class X1 implements X22 {}
''');

    // When we process `X1`, we see macro generated methods of `X22`.
    // This shows that we processed `X22` before `X1`.
    configuration.forOrder();
    checkElementText(testLibrary, r'''
library
  imports
    package:test/order.dart
    package:test/x2.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

augment class X1 {
  void f222_f221_f12() {}
  void f222_f221_f11() {}
}
---
''');

    // There are no dependencies between `X21` and `X22`, so they are
    // processed in the source order.
    // We see `f212` before `f211`, this shows that we process annotations
    // from right to left.
    final x2Library = await testContextLibrary('package:test/x2.dart');
    checkElementText(x2Library, r'''
library
  imports
    package:test/test.dart
    package:test/order.dart
  augmentationImports
    package:test/x2.macro.dart
      macroGeneratedCode
---
library augment 'x2.dart';

augment class X21 {
  void f212() {}
  void f211() {}
}
augment class X22 {
  void f222() {}
  void f221() {}
}
---
''');
  }

  test_declarations_mixin_interfaces_backward() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddFunction('f31')
@AddFunction('f32')
class X3 {}

@AddFunction('f21')
@AddFunction('f22')
class X2 {}

@AddFunction('f11')
@AddFunction('f12')
mixin X1 implements X2, X3 {}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

void f32() {}
void f31() {}
void f22() {}
void f21() {}
void f12() {}
void f11() {}
---
''');
  }

  test_declarations_mixin_interfaces_forward() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddFunction('f11')
@AddFunction('f12')
mixin X1 implements X2, X3 {}

@AddFunction('f21')
@AddFunction('f22')
class X2 {}

@AddFunction('f31')
@AddFunction('f32')
class X3 {}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

void f22() {}
void f21() {}
void f32() {}
void f31() {}
void f12() {}
void f11() {}
---
''');
  }

  test_declarations_mixin_superclassConstraints_backward() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddFunction('f31')
@AddFunction('f32')
class X3 {}

@AddFunction('f21')
@AddFunction('f22')
class X2 {}

@AddFunction('f11')
@AddFunction('f12')
mixin X1 on X2, X3 {}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

void f32() {}
void f31() {}
void f22() {}
void f21() {}
void f12() {}
void f11() {}
---
''');
  }

  test_declarations_mixin_superclassConstraints_forward() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddFunction('f11')
@AddFunction('f12')
mixin X1 on X2, X3 {}

@AddFunction('f21')
@AddFunction('f22')
class X2 {}

@AddFunction('f31')
@AddFunction('f32')
class X3 {}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

void f22() {}
void f21() {}
void f32() {}
void f31() {}
void f12() {}
void f11() {}
---
''');
  }

  test_declarations_mixin_superclassConstraints_interfaces_backward() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddFunction('f31')
@AddFunction('f32')
class X3 {}

@AddFunction('f21')
@AddFunction('f22')
class X2 {}

@AddFunction('f11')
@AddFunction('f12')
mixin X1 on X2 implements X3 {}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

void f32() {}
void f31() {}
void f22() {}
void f21() {}
void f12() {}
void f11() {}
---
''');
  }

  test_declarations_mixin_superclassConstraints_interfaces_forward() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddFunction('f11')
@AddFunction('f12')
mixin X1 on X2 implements X3 {}

@AddFunction('f21')
@AddFunction('f22')
class X2 {}

@AddFunction('f31')
@AddFunction('f32')
class X3 {}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

void f22() {}
void f21() {}
void f32() {}
void f31() {}
void f12() {}
void f11() {}
---
''');
  }

  test_phases_class_types_declarations() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddClass('A1')
@AddFunction('f1')
class X {}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class A1 {}
void f1() {}
---
''');
  }

  test_types_class_method_rightToLeft() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

class X {
  @AddClass('A1')
  @AddClass('A2')
  void foo() {}
}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class A2 {}
class A1 {}
---
''');
  }

  test_types_class_method_sourceOrder() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

class X {
  @AddClass('A1')
  void foo() {}

  @AddClass('A2')
  void bar() {}
}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class A1 {}
class A2 {}
---
''');
  }

  test_types_class_rightToLeft() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddClass('A1')
@AddClass('A2')
class X {}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class A2 {}
class A1 {}
---
''');
  }

  test_types_class_sourceOrder() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddClass('A1')
class X1 {}

@AddClass('A2')
class X2 {}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class A1 {}
class A2 {}
---
''');
  }

  test_types_innerBeforeOuter_class_method() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddClass('A1')
class X {
  @AddClass('A2')
  void foo() {}
}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class A2 {}
class A1 {}
---
''');
  }

  test_types_innerBeforeOuter_mixin_method() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddClass('A1')
mixin X {
  @AddClass('A2')
  void foo() {}
}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class A2 {}
class A1 {}
---
''');
  }

  test_types_mixin_method_rightToLeft() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

mixin X {
  @AddClass('A1')
  @AddClass('A2')
  void foo() {}
}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class A2 {}
class A1 {}
---
''');
  }

  test_types_mixin_method_sourceOrder() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

mixin X {
  @AddClass('A1')
  void foo() {}

  @AddClass('A2')
  void bar() {}
}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class A1 {}
class A2 {}
---
''');
  }

  test_types_mixin_rightToLeft() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddClass('A1')
@AddClass('A2')
mixin X {}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class A2 {}
class A1 {}
---
''');
  }

  test_types_mixin_sourceOrder() async {
    _newOrderMacrosFile();

    var library = await buildLibrary(r'''
import 'order.dart';

@AddClass('A1')
mixin X1 {}

@AddClass('A2')
mixin X2 {}
''');

    configuration.forOrder();
    checkElementText(library, r'''
library
  imports
    package:test/order.dart
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class A1 {}
class A2 {}
---
''');
  }

  void _newOrderMacrosFile() {
    newFile('$testPackageLibPath/order.dart', _orderCode);
  }
}

@reflectiveTest
class MacroArgumentsTest extends MacroElementsBaseTest {
  @override
  bool get keepLinkingLibraries => true;

  test_error() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'Object',
        'bar': 'Object',
      },
      constructorParametersCode: '(this.foo, this.bar)',
      argumentsCode: '(0, const Object())',
      expectedErrors: 'Argument(annotation: 0, argument: 1, '
          'message: Not supported: InstanceCreationExpressionImpl)',
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
foo: 1
bar: -2
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
foo: 1
bar: -2
''',
    );
  }

  test_kind_requiredNamed() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'int'},
      constructorParametersCode: '({required this.foo})',
      argumentsCode: '(foo: 42)',
      expected: r'''
foo: 42
''',
    );
  }

  test_kind_requiredPositional() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'int'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(42)',
      expected: r'''
foo: 42
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
foo: true
bar: false
''',
    );
  }

  test_type_double() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'double'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(1.2)',
      expected: r'''
foo: 1.2
''',
    );
  }

  test_type_double_negative() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'double'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(-1.2)',
      expected: r'''
foo: -1.2
''',
    );
  }

  test_type_int() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'int'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(42)',
      expected: r'''
foo: 42
''',
    );
  }

  test_type_int_negative() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'int'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(-42)',
      expected: r'''
foo: -42
''',
    );
  }

  test_type_list() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'List<Object?>',
      },
      constructorParametersCode: '(this.foo)',
      argumentsCode: '([1, 2, true, 3, 4.2])',
      expected: r'''
foo: [1, 2, true, 3, 4.2]
''',
    );
  }

  test_type_map() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'Map<Object?, Object?>',
      },
      constructorParametersCode: '(this.foo)',
      argumentsCode: '({1: true, "abc": 2.3})',
      expected: r'''
foo: {1: true, abc: 2.3}
''',
    );
  }

  test_type_null() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'Object?'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: '(null)',
      expected: r'''
foo: null
''',
    );
  }

  test_type_set() async {
    await _assertTypesPhaseArgumentsText(
      fields: {
        'foo': 'Set<Object?>',
      },
      constructorParametersCode: '(this.foo)',
      argumentsCode: '({1, 2, 3})',
      expected: r'''
foo: {1, 2, 3}
''',
    );
  }

  test_type_string() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'String'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: "('aaa')",
      expected: r'''
foo: aaa
''',
    );
  }

  test_type_string_adjacent() async {
    await _assertTypesPhaseArgumentsText(
      fields: {'foo': 'String'},
      constructorParametersCode: '(this.foo)',
      argumentsCode: "('aaa' 'bbb' 'ccc')",
      expected: r'''
foo: aaabbbccc
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
    String? expected,
    String? expectedErrors,
  }) async {
    final dumpCode = fields.keys.map((name) {
      return "$name: \$$name\\\\n";
    }).join('');

    newFile('$testPackageLibPath/arguments_text.dart', '''
import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

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

    final library = await buildLibrary('''
import 'arguments_text.dart';

@ArgumentsTextMacro$argumentsCode
class A {}
''');

    if (expectedErrors != null) {
      expect(library.macroErrorsStr, expectedErrors);
      return;
    } else {
      library.assertNoMacroErrors();
    }

    if (expected != null) {
      final macroAugmentation = library.augmentations.first;
      final macroUnit = macroAugmentation.definingCompilationUnit;
      final x = macroUnit.topLevelVariables.single;
      expect(x.name, 'x');
      x as ConstTopLevelVariableElementImpl;
      final actual = (x.constantInitializer as SimpleStringLiteral).value;

      if (actual != expected) {
        print(actual);
      }
      expect(actual, expected);
    } else {
      fail("Either 'expected' or 'expectedErrors' must be provided.");
    }
  }
}

@reflectiveTest
class MacroDeclarationsIntrospectTest extends MacroElementsBaseTest {
  @override
  bool get keepLinkingLibraries => true;

  String get _appendMacrosCode {
    var code = MacrosEnvironment.instance.packageAnalyzerFolder
        .getChildAssumingFile('test/src/summary/macro/append.dart')
        .readAsStringSync();
    return code.replaceAll('/*macro*/', 'macro');
  }

  /// Return the code for `IntrospectDeclarationsPhaseMacro`.
  String get _introspectDeclarationsCode {
    final code = MacrosEnvironment.instance.packageAnalyzerFolder
        .getChildAssumingFolder('test/src/summary/macro')
        .getChildAssumingFile('introspect_declarations_phase.dart')
        .readAsStringSync();
    return code.replaceAll('/*macro*/', 'macro');
  }

  test_element_class_field_flag_hasExternal() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  external int foo;
}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'A'},
)
class X extends A {}
''', r'''
class X
  superclass: A
    class A
      superclass: Object
      fields
        foo
          flags: hasExternal
          type: int
''');
  }

  test_element_class_field_flag_hasFinal() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int foo = 0;
}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'A'},
)
class X extends A {}
''', r'''
class X
  superclass: A
    class A
      superclass: Object
      fields
        foo
          flags: hasFinal
          type: int
''');
  }

  test_element_class_field_flag_hasLate() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  late int foo;
}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'A'},
)
class X extends A {}
''', r'''
class X
  superclass: A
    class A
      superclass: Object
      fields
        foo
          flags: hasLate
          type: int
''');
  }

  test_element_class_field_flag_isStatic() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static int foo = 0;
}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'A'},
)
class X extends A {}
''', r'''
class X
  superclass: A
    class A
      superclass: Object
      fields
        foo
          flags: isStatic
          type: int
''');
  }

  test_element_class_field_metadata_identifier() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;

class A {
  @a
  int? foo;
}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'A'},
)
class X extends A {}
''', r'''
class X
  superclass: A
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

  test_element_class_field_metadata_identifier_imported() async {
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

    await _assertIntrospectText(r'''
import 'b.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'A'},
)
class X extends A {}
''', r'''
class X
  superclass: A
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

  test_element_class_flags_hasAbstract() async {
    newFile('$testPackageLibPath/a.dart', r'''
abstract class A {}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'A'},
)
class X extends A {}
''', r'''
class X
  superclass: A
    class A
      flags: hasAbstract
      superclass: Object
''');
  }

  test_element_class_interfaces() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
class B {}
class C implements A, B {}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'C'},
)
class X extends C {}
''', r'''
class X
  superclass: C
    class C
      superclass: Object
      interfaces
        A
        B
''');
  }

  test_element_class_metadata_augmented() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
const b = 1;

import augment 'b.dart';

@a
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';

@b
augment class A {}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'A'},
)
class X extends A {}
''', r'''
class X
  superclass: A
    class A
      metadata
        IdentifierMetadataAnnotation
          identifier: a
        IdentifierMetadataAnnotation
          identifier: b
      superclass: Object
''');
  }

  test_element_class_metadata_constructor_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int f;
  const A.named(this.f)
}

@A.named(42)
class B {}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'B'},
)
class X extends B {}
''', r'''
class X
  superclass: B
    class B
      metadata
        ConstructorMetadataAnnotation
          type: A
          constructorName: named
      superclass: Object
''');
  }

  test_element_class_metadata_constructor_named_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int f;
  const A.named(this.f)
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

@A.named(42)
class B {}
''');

    await _assertIntrospectText(r'''
import 'b.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'B'},
)
class X extends B {}
''', r'''
class X
  superclass: B
    class B
      metadata
        ConstructorMetadataAnnotation
          type: A
          constructorName: named
      superclass: Object
''');
  }

  test_element_class_metadata_constructor_named_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int f;
  const A.named(this.f)
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart' as prefix;

@prefix.A.named(42)
class B {}
''');

    await _assertIntrospectText(r'''
import 'b.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'B'},
)
class X extends B {}
''', r'''
class X
  superclass: B
    class B
      metadata
        ConstructorMetadataAnnotation
          type: A
          constructorName: named
      superclass: Object
''');
  }

  test_element_class_metadata_constructor_unnamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int f;
  const A(this.f)
}

@A(42)
class B {}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'B'},
)
class X extends B {}
''', r'''
class X
  superclass: B
    class B
      metadata
        ConstructorMetadataAnnotation
          type: A
      superclass: Object
''');
  }

  test_element_class_metadata_constructor_unnamed_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int f;
  const A(this.f)
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

@A(42)
class B {}
''');

    await _assertIntrospectText(r'''
import 'b.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'B'},
)
class X extends B {}
''', r'''
class X
  superclass: B
    class B
      metadata
        ConstructorMetadataAnnotation
          type: A
      superclass: Object
''');
  }

  test_element_class_metadata_constructor_unnamed_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int f;
  const A(this.f)
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart' as prefix;

@prefix.A(42)
class B {}
''');

    await _assertIntrospectText(r'''
import 'b.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'B'},
)
class X extends B {}
''', r'''
class X
  superclass: B
    class B
      metadata
        ConstructorMetadataAnnotation
          type: A
      superclass: Object
''');
  }

  test_element_class_metadata_identifier() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;

@a
class A {}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'A'},
)
class X extends A {}
''', r'''
class X
  superclass: A
    class A
      metadata
        IdentifierMetadataAnnotation
          identifier: a
      superclass: Object
''');
  }

  test_element_class_metadata_identifier_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

@a
class A {}
''');

    await _assertIntrospectText(r'''
import 'b.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'A'},
)
class X extends A {}
''', r'''
class X
  superclass: A
    class A
      metadata
        IdentifierMetadataAnnotation
          identifier: a
      superclass: Object
''');
  }

  test_element_class_metadata_identifier_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart' as prefix;

@prefix.a
class A {}
''');

    await _assertIntrospectText(r'''
import 'b.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'A'},
)
class X extends A {}
''', r'''
class X
  superclass: A
    class A
      metadata
        IdentifierMetadataAnnotation
          identifier: a
      superclass: Object
''');
  }

  test_element_class_mixins() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin M1 {}
mixin M2 {}
class C with M1, M2 {}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'C'},
)
class X extends C {}
''', r'''
class X
  superclass: C
    class C
      superclass: Object
      mixins
        M1
        M2
''');
  }

  test_element_class_superclass() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {}
class B<U> extends A<U> {}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'A', 'B'},
)
class X extends B<int> {}
''', r'''
class X
  superclass: B<int>
    class B
      superclass: A<U>
        class A
          superclass: Object
          typeParameters
            T
      typeParameters
        U
''');
  }

  test_element_class_typeParameters() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T, U extends List<T>> {}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'A'},
)
class X extends A {}
''', r'''
class X
  superclass: A
    class A
      superclass: Object
      typeParameters
        T
        U
          bound: List<T>
''');
  }

  test_element_mixin_field_metadata_identifier() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;

mixin A {
  @a
  int? foo;
}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'A'},
)
class X with A {}
''', r'''
class X
  mixins
    A
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

  test_element_mixin_field_metadata_identifier_imported() async {
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

    await _assertIntrospectText(r'''
import 'b.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'A'},
)
class X with A {}
''', r'''
class X
  mixins
    A
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

  test_element_mixin_metadata_augmented() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
const b = 1;

import augment 'b.dart';

@a
mixin A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';

@b
augment mixin A {}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'A'},
)
class X extends A {}
''', r'''
class X
  superclass: A
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

  test_element_mixin_metadata_identifier() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;

@a
mixin A {}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'A'},
)
class X with A {}
''', r'''
class X
  mixins
    A
      mixin A
        metadata
          IdentifierMetadataAnnotation
            identifier: a
        superclassConstraints
          Object
''');
  }

  test_node_class_appendInterfaces() async {
    _newAppendMacrosFile();

    await _assertIntrospectText(r'''
import 'append.dart';

@IntrospectDeclarationsPhaseMacro()
@AppendInterfaceA()
class X {}
''', r'''
class X
  interfaces
    A
''');
  }

  test_node_class_appendMixins() async {
    _newAppendMacrosFile();

    await _assertIntrospectText(r'''
import 'append.dart';

@IntrospectDeclarationsPhaseMacro()
@AppendMixinA()
class X {}
''', r'''
class X
  mixins
    A
''');
  }

  test_node_class_field_flags_hasExternal() async {
    await _assertIntrospectText(r'''
@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'X'},
)
class X {
  external int a;
  int b = 0;
}
''', r'''
class X
  fields
    a
      flags: hasExternal
      type: int
    b
      type: int
''');
  }

  test_node_class_field_flags_hasFinal() async {
    await _assertIntrospectText(r'''
@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'X'},
)
class X {
  final int a = 0;
  int b = 0;
}
''', r'''
class X
  fields
    a
      flags: hasFinal
      type: int
    b
      type: int
''');
  }

  test_node_class_field_flags_hasLate() async {
    await _assertIntrospectText(r'''
@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'X'},
)
class X {
  late final int a;
  final int b = 0;
}
''', r'''
class X
  fields
    a
      flags: hasFinal hasLate
      type: int
    b
      flags: hasFinal
      type: int
''');
  }

  test_node_class_field_flags_isStatic() async {
    await _assertIntrospectText(r'''
@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'X'},
)
class X {
  static int a = 0;
  int b = 0;
}
''', r'''
class X
  fields
    a
      flags: isStatic
      type: int
    b
      type: int
''');
  }

  test_node_class_field_type_explicit() async {
    await _assertIntrospectText(r'''
@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'X'},
)
class X {
  int a = 0;
  List<String> b = [];
}
''', r'''
class X
  fields
    a
      type: int
    b
      type: List<String>
''');
  }

  test_node_class_superclassOf() async {
    await _assertIntrospectText(r'''
class A {}

@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'A'},
)
class X extends A {}
''', r'''
class X
  superclass: A
    class A
      superclass: Object
''');
  }

  test_node_class_superclassOf_implicit() async {
    await _assertIntrospectText(r'''
@IntrospectDeclarationsPhaseMacro()
class X {}
''', r'''
class X
''');
  }

  test_node_class_superclassOf_unresolved() async {
    await _assertIntrospectText(r'''
@IntrospectDeclarationsPhaseMacro()
class X extends A {}
''', r'''
class X
  superclass: A
    noDeclaration
''');
  }

  test_node_mixin_appendInterfaces() async {
    _newAppendMacrosFile();

    await _assertIntrospectText(r'''
import 'append.dart';

@IntrospectDeclarationsPhaseMacro()
@AppendInterfaceA()
mixin X {}
''', r'''
mixin X
  interfaces
    A
''');
  }

  test_node_mixin_field_flags_hasFinal() async {
    await _assertIntrospectText(r'''
@IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'X'},
)
mixin X {
  final int a = 0;
  int b = 0;
}
''', r'''
mixin X
  fields
    a
      flags: hasFinal
      type: int
    b
      type: int
''');
  }

  /// Assert that the textual dump of the introspection information produced
  /// by `IntrospectDeclarationsPhaseMacro` in [code], is the [expected].
  Future<void> _assertIntrospectText(String code, String expected) async {
    var actual = await _getIntrospectText(code);
    if (actual != expected) {
      print(actual);
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  /// The [code] is expected to have exactly one application of
  /// `IntrospectDeclarationsPhaseMacro`. It may contain arbitrary code otherwise.
  ///
  /// The macro generates a top-level constant `x`, with a string literal
  /// initializer - the textual dump of the introspection.
  Future<String> _getIntrospectText(String code) async {
    newFile(
      '$testPackageLibPath/introspect_shared.dart',
      _introspectSharedCode,
    );

    newFile(
      '$testPackageLibPath/introspect_declarations_phase.dart',
      _introspectDeclarationsCode,
    );

    var library = await buildLibrary('''
import 'introspect_declarations_phase.dart';
$code
''');

    library.assertNoMacroErrors();

    return library.topLevelElements
        .whereType<ConstTopLevelVariableElementImpl>()
        .where((e) => e.name.startsWith('introspect_'))
        .map((e) => (e.constantInitializer as SimpleStringLiteral).value)
        .join('\n');
  }

  void _newAppendMacrosFile() {
    newFile(
      '$testPackageLibPath/append.dart',
      _appendMacrosCode,
    );
  }
}

abstract class MacroDeclarationsTest extends MacroElementsBaseTest {
  test_addClass_addMethod_addMethod() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class AddClassB implements ClassTypesMacro {
  const AddClassB();

  FutureOr<void> buildTypesForClass(clazz, builder) async {
    final identifier = await builder.resolveIdentifier(
      Uri.parse('package:test/a.dart'),
      'AddMethodFoo',
    );
    builder.declareType(
      'MyClass',
      DeclarationCode.fromParts([
        '@',
        identifier,
        '()\nclass B {}\n',
      ]),
    );
  }
}

macro class AddMethodFoo implements ClassDeclarationsMacro {
  const AddMethodFoo();

  buildDeclarationsForClass(clazz, builder) async {
    final identifier = await builder.resolveIdentifier(
      Uri.parse('package:test/a.dart'),
      'AddMethodBar',
    );
    builder.declareInType(
      DeclarationCode.fromParts([
        '  @',
        identifier,
        '()\n  void foo() {}',
      ]),
    );
  }
}

macro class AddMethodBar implements MethodDeclarationsMacro {
  const AddMethodBar();

  buildDeclarationsForMethod(method, builder) async {
    builder.declareInType(
      DeclarationCode.fromString('  void bar() {}'),
    );
  }
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';

@AddClassB()
class A {}
''');

    configuration
      ..withConstructors = false
      ..withReferences = true;
    checkElementText(library, r'''
library
  reference: self
  imports
    package:test/a.dart
  definingUnit
    reference: self
    classes
      class A @37
        reference: self::@class::A
        metadata
          Annotation
            atSign: @ @18
            name: SimpleIdentifier
              token: AddClassB @19
              staticElement: package:test/a.dart::@class::AddClassB
              staticType: null
            arguments: ArgumentList
              leftParenthesis: ( @28
              rightParenthesis: ) @29
            element: package:test/a.dart::@class::AddClassB::@constructor::new
  augmentationImports
    package:test/test.macro.dart
      reference: self::@augmentation::package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

import 'package:test/a.dart' as prefix0;

@prefix0.AddMethodFoo()
class B {}

augment class B {
  @prefix0.AddMethodBar()
  void foo() {}
  void bar() {}
}
---
      imports
        package:test/a.dart as prefix0 @62
      definingUnit
        reference: self::@augmentation::package:test/test.macro.dart
        classes
          class B @102
            reference: self::@augmentation::package:test/test.macro.dart::@class::B
            metadata
              Annotation
                atSign: @ @72
                name: PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: prefix0 @73
                    staticElement: <null>
                    staticType: null
                  period: . @80
                  identifier: SimpleIdentifier
                    token: AddMethodFoo @81
                    staticElement: <null>
                    staticType: null
                  staticElement: <null>
                  staticType: null
                arguments: ArgumentList
                  leftParenthesis: ( @93
                  rightParenthesis: ) @94
                element: <null>
            augmentation: self::@augmentation::package:test/test.macro.dart::@classAugmentation::B
            augmented
              constructors
                self::@augmentation::package:test/test.macro.dart::@class::B::@constructor::new
              methods
                self::@augmentation::package:test/test.macro.dart::@classAugmentation::B::@method::bar
                self::@augmentation::package:test/test.macro.dart::@classAugmentation::B::@method::foo
          augment class B @122
            reference: self::@augmentation::package:test/test.macro.dart::@classAugmentation::B
            augmentationTarget: self::@augmentation::package:test/test.macro.dart::@class::B
            methods
              foo @159
                reference: self::@augmentation::package:test/test.macro.dart::@classAugmentation::B::@method::foo
                metadata
                  Annotation
                    atSign: @ @128
                    name: PrefixedIdentifier
                      prefix: SimpleIdentifier
                        token: prefix0 @129
                        staticElement: self::@augmentation::package:test/test.macro.dart::@prefix::prefix0
                        staticType: null
                      period: . @136
                      identifier: SimpleIdentifier
                        token: AddMethodBar @137
                        staticElement: package:test/a.dart::@class::AddMethodBar
                        staticType: null
                      staticElement: package:test/a.dart::@class::AddMethodBar
                      staticType: null
                    arguments: ArgumentList
                      leftParenthesis: ( @149
                      rightParenthesis: ) @150
                    element: package:test/a.dart::@class::AddMethodBar::@constructor::new
                returnType: void
              bar @175
                reference: self::@augmentation::package:test/test.macro.dart::@classAugmentation::B::@method::bar
                returnType: void
''');
  }

  /// TODO(scheglov) Not quite correct - we should not add a synthetic one.
  test_class_constructor_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassDeclarationsMacro {
  const MyMacro();

  buildDeclarationsForClass(clazz, builder) async {
    builder.declareInType(
      DeclarationCode.fromString('  A.named(int a);'),
    );
  }
}
''');

    var library = await buildLibrary(r'''
import 'a.dart';

@MyMacro()
class A {}
''');

    configuration
      ..withMetadata = false
      ..withReferences = true;
    checkElementText(library, r'''
library
  reference: self
  imports
    package:test/a.dart
  definingUnit
    reference: self
    classes
      class A @35
        reference: self::@class::A
        augmentation: self::@augmentation::package:test/test.macro.dart::@classAugmentation::A
        constructors
          synthetic @-1
            reference: self::@class::A::@constructor::new
        augmented
          constructors
            self::@class::A::@constructor::new
            self::@augmentation::package:test/test.macro.dart::@classAugmentation::A::@constructor::named
  augmentationImports
    package:test/test.macro.dart
      reference: self::@augmentation::package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

augment class A {
  A.named(int a);
}
---
      definingUnit
        reference: self::@augmentation::package:test/test.macro.dart
        classes
          augment class A @44
            reference: self::@augmentation::package:test/test.macro.dart::@classAugmentation::A
            augmentationTarget: self::@class::A
            constructors
              named @52
                reference: self::@augmentation::package:test/test.macro.dart::@classAugmentation::A::@constructor::named
                periodOffset: 51
                nameEnd: 57
                parameters
                  requiredPositional a @62
                    type: int
''');
  }

  test_class_field_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassDeclarationsMacro {
  const MyMacro();

  buildDeclarationsForClass(clazz, builder) async {
    builder.declareInType(
      DeclarationCode.fromString('  int foo = 0;'),
    );
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
      ..withReferences = true;
    checkElementText(library, r'''
library
  reference: self
  imports
    package:test/a.dart
  definingUnit
    reference: self
    classes
      class A @35
        reference: self::@class::A
        augmentation: self::@augmentation::package:test/test.macro.dart::@classAugmentation::A
        augmented
          fields
            self::@augmentation::package:test/test.macro.dart::@classAugmentation::A::@field::foo
          constructors
            self::@class::A::@constructor::new
          accessors
            self::@augmentation::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
            self::@augmentation::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
  augmentationImports
    package:test/test.macro.dart
      reference: self::@augmentation::package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

augment class A {
  int foo = 0;
}
---
      definingUnit
        reference: self::@augmentation::package:test/test.macro.dart
        classes
          augment class A @44
            reference: self::@augmentation::package:test/test.macro.dart::@classAugmentation::A
            augmentationTarget: self::@class::A
            fields
              foo @54
                reference: self::@augmentation::package:test/test.macro.dart::@classAugmentation::A::@field::foo
                type: int
                shouldUseTypeForInitializerInference: true
            accessors
              synthetic get foo @-1
                reference: self::@augmentation::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
                returnType: int
              synthetic set foo= @-1
                reference: self::@augmentation::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
                parameters
                  requiredPositional _foo @-1
                    type: int
                returnType: void
''');
  }

  test_class_getter_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassDeclarationsMacro {
  const MyMacro();

  buildDeclarationsForClass(clazz, builder) async {
    builder.declareInType(
      DeclarationCode.fromString('  int get foo => 0;'),
    );
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
      ..withReferences = true;
    checkElementText(library, r'''
library
  reference: self
  imports
    package:test/a.dart
  definingUnit
    reference: self
    classes
      class A @35
        reference: self::@class::A
        augmentation: self::@augmentation::package:test/test.macro.dart::@classAugmentation::A
        augmented
          fields
            self::@augmentation::package:test/test.macro.dart::@classAugmentation::A::@field::foo
          constructors
            self::@class::A::@constructor::new
          accessors
            self::@augmentation::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
  augmentationImports
    package:test/test.macro.dart
      reference: self::@augmentation::package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

augment class A {
  int get foo => 0;
}
---
      definingUnit
        reference: self::@augmentation::package:test/test.macro.dart
        classes
          augment class A @44
            reference: self::@augmentation::package:test/test.macro.dart::@classAugmentation::A
            augmentationTarget: self::@class::A
            fields
              synthetic foo @-1
                reference: self::@augmentation::package:test/test.macro.dart::@classAugmentation::A::@field::foo
                type: int
            accessors
              get foo @58
                reference: self::@augmentation::package:test/test.macro.dart::@classAugmentation::A::@getter::foo
                returnType: int
''');
  }

  test_class_method_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassDeclarationsMacro {
  const MyMacro();

  buildDeclarationsForClass(clazz, builder) async {
    builder.declareInType(
      DeclarationCode.fromString('  int foo(double a) => 0;'),
    );
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
      ..withReferences = true;
    checkElementText(library, r'''
library
  reference: self
  imports
    package:test/a.dart
  definingUnit
    reference: self
    classes
      class A @35
        reference: self::@class::A
        augmentation: self::@augmentation::package:test/test.macro.dart::@classAugmentation::A
        augmented
          constructors
            self::@class::A::@constructor::new
          methods
            self::@augmentation::package:test/test.macro.dart::@classAugmentation::A::@method::foo
  augmentationImports
    package:test/test.macro.dart
      reference: self::@augmentation::package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

augment class A {
  int foo(double a) => 0;
}
---
      definingUnit
        reference: self::@augmentation::package:test/test.macro.dart
        classes
          augment class A @44
            reference: self::@augmentation::package:test/test.macro.dart::@classAugmentation::A
            augmentationTarget: self::@class::A
            methods
              foo @54
                reference: self::@augmentation::package:test/test.macro.dart::@classAugmentation::A::@method::foo
                parameters
                  requiredPositional a @65
                    type: double
                returnType: int
''');
  }

  test_class_setter_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassDeclarationsMacro {
  const MyMacro();

  buildDeclarationsForClass(clazz, builder) async {
    builder.declareInType(
      DeclarationCode.fromString('  set foo(int a) {}'),
    );
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
      ..withReferences = true;
    checkElementText(library, r'''
library
  reference: self
  imports
    package:test/a.dart
  definingUnit
    reference: self
    classes
      class A @35
        reference: self::@class::A
        augmentation: self::@augmentation::package:test/test.macro.dart::@classAugmentation::A
        augmented
          fields
            self::@augmentation::package:test/test.macro.dart::@classAugmentation::A::@field::foo
          constructors
            self::@class::A::@constructor::new
          accessors
            self::@augmentation::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
  augmentationImports
    package:test/test.macro.dart
      reference: self::@augmentation::package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

augment class A {
  set foo(int a) {}
}
---
      definingUnit
        reference: self::@augmentation::package:test/test.macro.dart
        classes
          augment class A @44
            reference: self::@augmentation::package:test/test.macro.dart::@classAugmentation::A
            augmentationTarget: self::@class::A
            fields
              synthetic foo @-1
                reference: self::@augmentation::package:test/test.macro.dart::@classAugmentation::A::@field::foo
                type: int
            accessors
              set foo= @54
                reference: self::@augmentation::package:test/test.macro.dart::@classAugmentation::A::@setter::foo
                parameters
                  requiredPositional a @62
                    type: int
                returnType: void
''');
  }

  test_unit_variable_add() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassDeclarationsMacro {
  const MyMacro();

  buildDeclarationsForClass(clazz, builder) async {
    builder.declareInLibrary(
      DeclarationCode.fromString('final x = 42;'),
    );
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
      ..withPropertyLinking = true
      ..withReferences = true;
    checkElementText(library, r'''
library
  reference: self
  imports
    package:test/a.dart
  definingUnit
    reference: self
    classes
      class A @35
        reference: self::@class::A
  augmentationImports
    package:test/test.macro.dart
      reference: self::@augmentation::package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

final x = 42;
---
      definingUnit
        reference: self::@augmentation::package:test/test.macro.dart
        topLevelVariables
          static final x @36
            reference: self::@augmentation::package:test/test.macro.dart::@topLevelVariable::x
            type: int
            shouldUseTypeForInitializerInference: false
            id: variable_0
            getter: getter_0
        accessors
          synthetic static get x @-1
            reference: self::@augmentation::package:test/test.macro.dart::@accessor::x
            returnType: int
            id: getter_0
            variable: variable_0
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

abstract class MacroElementsBaseTest extends ElementsBaseTest {
  String get _introspectSharedCode {
    return MacrosEnvironment.instance.packageAnalyzerFolder
        .getChildAssumingFile('test/src/summary/macro/introspect_shared.dart')
        .readAsStringSync();
  }

  @override
  Future<void> setUp() async {
    super.setUp();

    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      macrosEnvironment: MacrosEnvironment.instance,
    );
  }
}

abstract class MacroElementsTest extends MacroElementsBaseTest {
  @FailingTest(reason: 'Fails because exceptions are reported as diagnostics')
  test_macroApplicationErrors_declarationsPhase_throwsException() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassDeclarationsMacro {
  const MyMacro();

  buildDeclarationsForClass(clazz, builder) async {
    throw 'foo bar';
  }
}
''');

    final library = await buildLibrary(r'''
import 'a.dart';

@MyMacro()
class A {}
''');

    final A = library.getClass('A') as ClassElementImpl;
    final error = A.macroApplicationErrors.single;
    error as UnknownMacroApplicationError;

    expect(error.annotationIndex, 0);
    expect(error.message, 'foo bar');
    expect(error.stackTrace, contains('MyMacro.buildDeclarationsForClass'));
  }

  @FailingTest(reason: 'Fails because exceptions are reported as diagnostics')
  test_macroApplicationErrors_typesPhase_compileTimeError() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    unresolved;
  }
}
''');

    final library = await buildLibrary(r'''
import 'a.dart';

@MyMacro()
class A {}
''');

    final A = library.getClass('A') as ClassElementImpl;
    final error = A.macroApplicationErrors.single;
    error as UnknownMacroApplicationError;

    expect(error.annotationIndex, 0);
    expect(error.message, contains('unresolved'));
    expect(error.stackTrace, contains('executeTypesMacro'));
  }

  @FailingTest(reason: 'Fails because exceptions are reported as diagnostics')
  test_macroApplicationErrors_typesPhase_throwsException() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    throw 'foo bar';
  }
}
''');

    final library = await buildLibrary(r'''
import 'a.dart';

@MyMacro()
class A {}
''');

    final A = library.getClass('A') as ClassElementImpl;
    final error = A.macroApplicationErrors.single;
    error as UnknownMacroApplicationError;

    expect(error.annotationIndex, 0);
    expect(error.message, 'foo bar');
    expect(error.stackTrace, contains('MyMacro.buildTypesForClass'));
  }

  test_macroFlag_class() async {
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

  test_macroFlag_classAlias() async {
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
                staticElement: dart:core::@class::Object::@constructor::new
    mixins
      mixin M @6
        superclassConstraints
          Object
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
class MacroTypesIntrospectTest extends MacroElementsBaseTest {
  @override
  bool get keepLinkingLibraries => true;

  /// Return the code for `IntrospectTypesPhaseMacro`.
  String get _introspectTypesCode {
    final code = MacrosEnvironment.instance.packageAnalyzerFolder
        .getChildAssumingFolder('test/src/summary/macro')
        .getChildAssumingFile('introspect_types_phase.dart')
        .readAsStringSync();
    return code.replaceAll('/*macro*/', 'macro');
  }

  test_class_flags_hasAbstract() async {
    await _assertIntrospectText(r'''
@IntrospectTypesPhaseMacro()
abstract class A {}
''', r'''
class A
  flags: hasAbstract
''');
  }

  test_class_getter() async {
    await _assertIntrospectText(r'''
abstract class A {
  @IntrospectTypesPhaseMacro()
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
@IntrospectTypesPhaseMacro()
class A implements B, C<int, String> {}
''', r'''
class A
  interfaces
    B
    C<int, String>
''');
  }

  test_class_metadata_constructor_named() async {
    await _assertIntrospectText(r'''
@IntrospectTypesPhaseMacro()
@A.named(42)
class X {}

class A {
  final int f;
  const A.named(this.f)
}
''', r'''
class X
  metadata
    ConstructorMetadataAnnotation
      type: A
      constructorName: named
''');
  }

  test_class_metadata_constructor_named_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int f;
  const A.named(this.f)
}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectTypesPhaseMacro()
@A.named(42)
class X {}

''', r'''
class X
  metadata
    ConstructorMetadataAnnotation
      type: A
      constructorName: named
''');
  }

  test_class_metadata_constructor_named_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int f;
  const A.named(this.f)
}
''');

    await _assertIntrospectText(r'''
import 'a.dart' as prefix;

@IntrospectTypesPhaseMacro()
@prefix.A.named(42)
class X {}

''', r'''
class X
  metadata
    ConstructorMetadataAnnotation
      type: A
      constructorName: named
''');
  }

  test_class_metadata_constructor_unnamed() async {
    await _assertIntrospectText(r'''
@IntrospectTypesPhaseMacro()
@A(42)
class X {}

class A {
  final int f;
  const A(this.f)
}
''', r'''
class X
  metadata
    ConstructorMetadataAnnotation
      type: A
''');
  }

  test_class_metadata_constructor_unnamed_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int f;
  const A(this.f)
}
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectTypesPhaseMacro()
@A(42)
class X {}

''', r'''
class X
  metadata
    ConstructorMetadataAnnotation
      type: A
''');
  }

  test_class_metadata_constructor_unnamed_imported_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int f;
  const A(this.f)
}
''');

    await _assertIntrospectText(r'''
import 'a.dart' as prefix;

@IntrospectTypesPhaseMacro()
@prefix.A(42)
class X {}

''', r'''
class X
  metadata
    ConstructorMetadataAnnotation
      type: A
''');
  }

  test_class_metadata_identifier() async {
    await _assertIntrospectText(r'''
@IntrospectTypesPhaseMacro()
@a1
@a2
class X {}

const a1 = 0;
const a2 = 0;
''', r'''
class X
  metadata
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

@IntrospectTypesPhaseMacro()
@a1
@a2
class X {}

''', r'''
class X
  metadata
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

@IntrospectTypesPhaseMacro()
@prefix.a1
@prefix.a2
class X {}

''', r'''
class X
  metadata
    IdentifierMetadataAnnotation
      identifier: a1
    IdentifierMetadataAnnotation
      identifier: a2
''');
  }

  test_class_method_flags_hasBody_false() async {
    await _assertIntrospectText(r'''
abstract class A {
  @IntrospectTypesPhaseMacro()
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
  @IntrospectTypesPhaseMacro()
  external void foo();
}
''', r'''
foo
  flags: hasExternal
  returnType: void
''');
  }

  test_class_method_flags_isStatic() async {
    await _assertIntrospectText(r'''
class A {
  @IntrospectTypesPhaseMacro()
  static void foo() {}
}
''', r'''
foo
  flags: hasBody isStatic
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
  @IntrospectTypesPhaseMacro()
  @a
  void foo() {}
}

''', r'''
foo
  flags: hasBody
  metadata
    IdentifierMetadataAnnotation
      identifier: a
  returnType: void
''');
  }

  test_class_method_namedParameters() async {
    await _assertIntrospectText(r'''
abstract class A {
  @IntrospectTypesPhaseMacro()
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
  @IntrospectTypesPhaseMacro()
  void foo({@a required int x}) {}
}
''', r'''
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
    await _assertIntrospectText(r'''
abstract class A {
  @IntrospectTypesPhaseMacro()
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
  @IntrospectTypesPhaseMacro()
  void foo(@a int x) {}
}
''', r'''
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

  test_class_mixin_method() async {
    await _assertIntrospectText(r'''
mixin A {
  @IntrospectTypesPhaseMacro()
  void foo() {}
}
''', r'''
foo
  flags: hasBody
  returnType: void
''');
  }

  test_class_mixins() async {
    await _assertIntrospectText(r'''
@IntrospectTypesPhaseMacro()
class A with B, C<int, String> {}
''', r'''
class A
  mixins
    B
    C<int, String>
''');
  }

  test_class_setter() async {
    await _assertIntrospectText(r'''
abstract class A {
  @IntrospectTypesPhaseMacro()
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
@IntrospectTypesPhaseMacro()
class A extends B {}
''', r'''
class A
  superclass: B
''');
  }

  test_class_superclass_nullable() async {
    await _assertIntrospectText(r'''
@IntrospectTypesPhaseMacro()
class A extends B<int?> {}
''', r'''
class A
  superclass: B<int?>
''');
  }

  test_class_superclass_typeArguments() async {
    await _assertIntrospectText(r'''
@IntrospectTypesPhaseMacro()
class A extends B<String, List<int>> {}
''', r'''
class A
  superclass: B<String, List<int>>
''');
  }

  test_class_typeParameter_metadata_identifier_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectTypesPhaseMacro()
class A<@a T> {}
''', r'''
class A
  typeParameters
    T
      metadata
        IdentifierMetadataAnnotation
          identifier: a
''');
  }

  test_class_typeParameters() async {
    await _assertIntrospectText(r'''
@IntrospectTypesPhaseMacro()
class A<T, U extends List<T>> {}
''', r'''
class A
  typeParameters
    T
    U
      bound: List<T>
''');
  }

  test_functionTypeAnnotation_formalParameters_namedOptional_simpleFormalParameter() async {
    await _assertIntrospectText(r'''
@IntrospectTypesPhaseMacro()
class A extends B<void Function(int a, {int? b, int? c})> {}
''', r'''
class A
  superclass: B<void Function(int a, {int? b}, {int? c})>
''');
  }

  test_functionTypeAnnotation_formalParameters_namedRequired_simpleFormalParameter() async {
    await _assertIntrospectText(r'''
@IntrospectTypesPhaseMacro()
class A extends B<void Function(int a, {required int b, required int c})> {}
''', r'''
class A
  superclass: B<void Function(int a, {required int b}, {required int c})>
''');
  }

  test_functionTypeAnnotation_formalParameters_positionalOptional_simpleFormalParameter() async {
    await _assertIntrospectText(r'''
@IntrospectTypesPhaseMacro()
class A extends B<void Function(int a, [int b, int c])> {}
''', r'''
class A
  superclass: B<void Function(int a, [int b], [int c])>
''');
  }

  /// TODO(scheglov) Tests for unnamed positional formal parameters.
  test_functionTypeAnnotation_formalParameters_positionalRequired_simpleFormalParameter() async {
    await _assertIntrospectText(r'''
@IntrospectTypesPhaseMacro()
class A extends B<void Function(int a, double b)> {}
''', r'''
class A
  superclass: B<void Function(int a, double b)>
''');
  }

  test_functionTypeAnnotation_nullable() async {
    await _assertIntrospectText(r'''
@IntrospectTypesPhaseMacro()
class A extends B<void Function()?> {}
''', r'''
class A
  superclass: B<void Function()?>
''');
  }

  test_functionTypeAnnotation_returnType() async {
    await _assertIntrospectText(r'''
@IntrospectTypesPhaseMacro()
class A extends B<void Function()> {}
''', r'''
class A
  superclass: B<void Function()>
''');
  }

  test_functionTypeAnnotation_returnType_omitted() async {
    await _assertIntrospectText(r'''
@IntrospectTypesPhaseMacro()
class A extends B<Function()> {}
''', r'''
class A
  superclass: B<OmittedType Function()>
''');
  }

  test_functionTypeAnnotation_typeParameters() async {
    await _assertIntrospectText(r'''
@IntrospectTypesPhaseMacro()
class A extends B<void Function<T, U extends num>()> {}
''', r'''
class A
  superclass: B<void Function<T, U extends num>()>
''');
  }

  test_mixin_flags_hasBase() async {
    await _assertIntrospectText(r'''
@IntrospectTypesPhaseMacro()
base mixin A {}
''', r'''
mixin A
  flags: hasBase
''');
  }

  test_mixin_getter() async {
    await _assertIntrospectText(r'''
mixin A {
  @IntrospectTypesPhaseMacro()
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
@IntrospectTypesPhaseMacro()
mixin A implements B, C {}
''', r'''
mixin A
  interfaces
    B
    C
''');
  }

  test_mixin_metadata_identifier_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');

    await _assertIntrospectText(r'''
import 'a.dart';

@IntrospectTypesPhaseMacro()
@a
mixin X {}

''', r'''
mixin X
  metadata
    IdentifierMetadataAnnotation
      identifier: a
''');
  }

  test_mixin_method() async {
    await _assertIntrospectText(r'''
mixin A {
  @IntrospectTypesPhaseMacro()
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
  @IntrospectTypesPhaseMacro()
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
@IntrospectTypesPhaseMacro()
mixin A on B, C {}
''', r'''
mixin A
  superclassConstraints
    B
    C
''');
  }

  test_mixin_typeParameters() async {
    await _assertIntrospectText(r'''
@IntrospectTypesPhaseMacro()
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
@IntrospectTypesPhaseMacro()
class A extends prefix.B {}
''', r'''
class A
  superclass: B
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
      print(actual);
    }
    expect(actual, expected);
  }

  /// The [code] is expected to have exactly one application of
  /// `IntrospectTypesPhaseMacro`. It may contain arbitrary code otherwise.
  ///
  /// The macro generates a top-level constant `x`, with a string literal
  /// initializer - the textual dump of the introspection.
  Future<String> _getIntrospectText(String code) async {
    newFile(
      '$testPackageLibPath/introspect_shared.dart',
      _introspectSharedCode,
    );

    newFile(
      '$testPackageLibPath/introspect_types_phase.dart',
      _introspectTypesCode,
    );

    var library = await buildLibrary('''
import 'introspect_types_phase.dart';

$code
''');

    library.assertNoMacroErrors();

    final macroAugmentation = library.augmentations.first;
    final macroUnit = macroAugmentation.definingCompilationUnit;
    final x = macroUnit.topLevelVariables.single;
    expect(x.name, 'x');
    x as ConstTopLevelVariableElementImpl;
    var x_literal = x.constantInitializer as SimpleStringLiteral;
    return x_literal.value;
  }
}

abstract class MacroTypesTest extends MacroElementsBaseTest {
  final List<io.Directory> _ioDirectoriesToDelete = [];

  @override
  bool get retainDataForTesting => true;

  @override
  Future<void> tearDown() async {
    for (final directory in _ioDirectoriesToDelete) {
      try {
        directory.deleteSync(
          recursive: true,
        );
      } catch (_) {}
    }

    return super.tearDown();
  }

  test_application_newInstance_withoutPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

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
''');

    configuration
      ..withConstructors = false
      ..withMetadata = false
      ..withReferences = true;
    checkElementText(library, r'''
library
  reference: self
  imports
    package:test/a.dart
  definingUnit
    reference: self
    classes
      class A @35
        reference: self::@class::A
  augmentationImports
    package:test/test.macro.dart
      reference: self::@augmentation::package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class MyClass {}
---
      definingUnit
        reference: self::@augmentation::package:test/test.macro.dart
        classes
          class MyClass @36
            reference: self::@augmentation::package:test/test.macro.dart::@class::MyClass
''');
  }

  test_application_newInstance_withoutPrefix_namedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro.named();

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

@MyMacro.named()
class A {}
''');

    configuration.withMetadata = false;
    checkElementText(library, r'''
library
  imports
    package:test/a.dart
  definingUnit
    classes
      class A @41
        constructors
          synthetic @-1
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class MyClass {}
---
      definingUnit
        classes
          class MyClass @36
            constructors
              synthetic @-1
''');
  }

  test_application_newInstance_withPrefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    builder.declareType(
      'MyClass',
      DeclarationCode.fromString('class MyClass {}'),
    );
  }
}
''');

    var library = await buildLibrary(r'''
import 'a.dart' as prefix;

@prefix.MyMacro()
class A {}
''');

    configuration.withMetadata = false;
    checkElementText(library, r'''
library
  imports
    package:test/a.dart as prefix @19
  definingUnit
    classes
      class A @52
        constructors
          synthetic @-1
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class MyClass {}
---
      definingUnit
        classes
          class MyClass @36
            constructors
              synthetic @-1
''');
  }

  test_application_newInstance_withPrefix_namedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro.named();

  buildTypesForClass(clazz, builder) {
    builder.declareType(
      'MyClass',
      DeclarationCode.fromString('class MyClass {}'),
    );
  }
}
''');

    var library = await buildLibrary(r'''
import 'a.dart' as prefix;

@prefix.MyMacro.named()
class A {}
''');

    configuration.withMetadata = false;
    checkElementText(library, r'''
library
  imports
    package:test/a.dart as prefix @19
  definingUnit
    classes
      class A @58
        constructors
          synthetic @-1
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class MyClass {}
---
      definingUnit
        classes
          class MyClass @36
            constructors
              synthetic @-1
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
import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  FutureOr<void> buildTypesForClass(clazz, builder) {
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
      final macroMainContent = macro.bootstrapMacroIsolate(
        {
          'package:test/a.dart': {
            'MyMacro': ['']
          },
        },
        macro.SerializationMode.byteData,
      );

      final tempCompileDirectory =
          io.Directory.systemTemp.createTempSync('dartAnalyzerMacro');
      _ioDirectoriesToDelete.add(tempCompileDirectory);

      final fileSystem = PhysicalResourceProvider.INSTANCE;
      final compileRoot = fileSystem.getFolder(tempCompileDirectory.path);

      final testRoot = compileRoot.getChildAssumingFolder('test');
      testRoot.newFile('lib/a.dart').writeAsStringSync(macroCode);

      final testBin = testRoot.getChildAssumingFolder('bin');
      final testMain = testBin.newFile('main.dart');
      testMain.writeAsStringSync(macroMainContent);

      final metaDir = compileRoot.getChildAssumingFolder('meta');
      MockPackages.addMetaPackageFiles(metaDir);

      MacrosEnvironment.instance.packageSharedFolder.copyTo(compileRoot);

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
      "name": "_fe_analyzer_shared",
      "rootUri": "../_fe_analyzer_shared",
      "packageUri": "lib/"
    },
    {
      "name": "meta",
      "rootUri": "../meta",
      "packageUri": "lib/"
    }
  ]
}
''');

      final process = await io.Process.start(
        io.Platform.executable,
        ['compile', 'exe', '--enable-experiment=macros', testMain.path],
      );

      final exitCode = await process.exitCode;
      if (exitCode == 255) {
        markTestSkipped('Skip because cannot compile.');
        return;
      }
      expect(exitCode, isZero);

      final executable = testBin.getChildAssumingFile('main.exe');
      expect(executable.exists, isTrue);

      // Convert to io.File
      macroExecutable = io.File(executable.path);
    }

    // Build the summary for `a.dart`, with the macro.
    // We always have summaries for libraries with macro executable.
    final Uint8List aBundleBytes;
    {
      final a = newFile('$testPackageLibPath/a.dart', macroCode);

      // Disable compilation to kernel.
      macroSupport = ExecutableMacroSupport();

      final analysisDriver = driverFor(a);
      aBundleBytes = await analysisDriver.buildPackageBundle(
        uriList: [
          Uri.parse('package:_fe_analyzer_shared/src/macros/api.dart'),
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

      final aBundleFile = getFile('/home/summaries/a.sum');
      aBundleFile.writeAsBytesSync(aBundleBytes);
      librarySummaryFiles = [aBundleFile];
    }

    // Configure the macro executor.
    macroSupport = ExecutableMacroSupport()
      ..add(
        executable: macroExecutable,
        libraries: {
          Uri.parse('package:test/a.dart'),
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
        ..withMetadata = false
        ..withReferences = true;
      checkElementText(library, r'''
library
  reference: self
  imports
    package:test/a.dart
  definingUnit
    reference: self
    classes
      class A @35
        reference: self::@class::A
  augmentationImports
    package:test/test.macro.dart
      reference: self::@augmentation::package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

class MyClass {}
---
      definingUnit
        reference: self::@augmentation::package:test/test.macro.dart
        classes
          class MyClass @36
            reference: self::@augmentation::package:test/test.macro.dart::@class::MyClass
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
import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'a.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  FutureOr<void> buildTypesForClass(clazz, ClassTypeBuilder builder) async {
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
  imports
    package:test/b.dart
  definingUnit
    classes
      class X @35
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

import 'package:test/a.dart' as prefix0;

class MyClass {
  void foo(prefix0.A _) {}
}
---
      imports
        package:test/a.dart as prefix0 @62
      definingUnit
        classes
          class MyClass @78
            methods
              foo @95
                parameters
                  requiredPositional _ @109
                    type: A
                returnType: void
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
          library_10 dart:core synthetic
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
          library_12 dart:async
          library_4 package:macro/api.dart
          library_0
          library_10 dart:core synthetic
        cycle_1
          dependencies: cycle_0 dart:core package:macro/api.dart
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
          library_10 dart:core synthetic
        augmentationImports
          augmentation_3
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
library augment 'test.dart';

import 'package:test/a.dart' as prefix0;

class MyClass {
  void foo(prefix0.A _) {}
}
---
      kind: augmentation_3
        augmented: library_2
        library: library_2
        libraryImports
          library_0
          library_10 dart:core synthetic
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

      // When we discard the library, we remove its macro file.
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
          library_10 dart:core synthetic
        cycle_0
          dependencies: dart:core
          libraries: library_0
          apiSignature_0
          users: cycle_1
      referencingFiles: file_1
      unlinkedKey: k00
  /home/test/lib/b.dart
    uri: package:test/b.dart
    current
      id: file_1
      kind: library_1
        libraryImports
          library_12 dart:async
          library_4 package:macro/api.dart
          library_0
          library_10 dart:core synthetic
        cycle_1
          dependencies: cycle_0 dart:core package:macro/api.dart
          libraries: library_1
          apiSignature_1
          users: cycle_6
      referencingFiles: file_2
      unlinkedKey: k01
  /home/test/lib/test.dart
    uri: package:test/test.dart
    current
      id: file_2
      kind: library_16
        libraryImports
          library_1
          library_10 dart:core synthetic
        cycle_6
          dependencies: cycle_1 dart:core
          libraries: library_16
          apiSignature_2
      unlinkedKey: k02
  /home/test/lib/test.macro.dart
    uri: package:test/test.macro.dart
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
          library_10 dart:core synthetic
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
          library_12 dart:async
          library_4 package:macro/api.dart
          library_0
          library_10 dart:core synthetic
        cycle_1
          dependencies: cycle_0 dart:core package:macro/api.dart
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
          library_10 dart:core synthetic
        augmentationImports
          augmentation_3
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
library augment 'test.dart';

import 'package:test/a.dart' as prefix0;

class MyClass {
  void foo(prefix0.A _) {}
}
---
      kind: augmentation_3
        augmented: library_2
        library: library_2
        libraryImports
          library_0
          library_10 dart:core synthetic
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
import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class AddClassA implements ClassTypesMacro {
  const AddClassA();

  FutureOr<void> buildTypesForClass(clazz, builder) async {
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

  FutureOr<void> buildTypesForClass(clazz, builder) async {
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
  imports
    package:test/a.dart
  definingUnit
    classes
      class X @37
  augmentationImports
    package:test/test.macro.dart
      macroGeneratedCode
---
library augment 'test.dart';

import 'package:test/a.dart' as prefix0;

@prefix0.AddClassB()
class A {}

class B {}
---
      imports
        package:test/a.dart as prefix0 @62
      definingUnit
        classes
          class A @99
          class B @111
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
          library_11 dart:async
          library_3 package:macro/api.dart
          library_9 dart:core synthetic
        cycle_0
          dependencies: dart:core package:macro/api.dart
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
          library_9 dart:core synthetic
        augmentationImports
          augmentation_2
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
library augment 'test.dart';

import 'package:test/a.dart' as prefix0;

@prefix0.AddClassB()
class A {}

class B {}
---
      kind: augmentation_2
        augmented: library_1
        library: library_1
        libraryImports
          library_0
          library_9 dart:core synthetic
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
          library_11 dart:async
          library_3 package:macro/api.dart
          library_9 dart:core synthetic
        cycle_0
          dependencies: dart:core package:macro/api.dart
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
          library_9 dart:core synthetic
        augmentationImports
          augmentation_2
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
library augment 'test.dart';

import 'package:test/a.dart' as prefix0;

@prefix0.AddClassB()
class A {}

class B {}
---
      kind: augmentation_2
        augmented: library_1
        library: library_1
        libraryImports
          library_0
          library_9 dart:core synthetic
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

class _MacroApplicationErrorsCollector
    extends GeneralizingElementVisitor<void> {
  final List<MacroApplicationError> errors = [];

  @override
  void visitElement(Element element) {
    if (element case final MacroTargetElement element) {
      errors.addAll(element.macroApplicationErrors);
    }

    super.visitElement(element);
  }
}

extension on LibraryElement {
  List<MacroApplicationError> get macroErrors {
    final collector = _MacroApplicationErrorsCollector();
    accept(collector);
    return collector.errors;
  }

  String get macroErrorsStr {
    return macroErrors.map((e) {
      return e.toStringForTest();
    }).join('\n');
  }

  void assertNoMacroErrors() {
    expect(macroErrorsStr, isEmpty);
  }
}

extension on Folder {
  File newFile(String relPath) {
    final file = getChildAssumingFile(relPath);
    file.parent.create();
    return file;
  }
}

extension on ElementTextConfiguration {
  void forOrder() {
    filter = (element) {
      if (element is CompilationUnitElement) {
        return false;
        // return element.source.uri != Uri.parse('package:test/test.dart');
      }
      return true;
    };
    withConstructors = false;
    withMetadata = false;
    withReturnType = false;
  }
}
