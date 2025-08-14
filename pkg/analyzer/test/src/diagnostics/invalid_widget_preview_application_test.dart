// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidWidgetPreviewApplicationTest);
  });
}

@reflectiveTest
class InvalidWidgetPreviewApplicationTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(PackageConfigFileBuilder(), flutter: true);
  }

  // @Preview cannot be applied to constructors of abstract classes.
  test_invalidAbstractClassConstructors() async {
    await assertErrorsInCode(
      '''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

abstract class B extends StatelessWidget {
  @Preview()
  B();

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''',
      [error(WarningCode.invalidWidgetPreviewApplication, 133, 7)],
    );
  }

  // @Preview application must invoke the `Preview` constructor.
  test_invalidAnnotationApplication() async {
    await assertErrorsInCode(
      '''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class B extends StatelessWidget {
  @Preview
  B();
}
''',
      [error(CompileTimeErrorCode.noAnnotationConstructorArguments, 123, 8)],
    );
  }

  // @Preview cannot be applied to external functions.
  test_invalidExternalFunction() async {
    await assertErrorsInCode(
      '''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

@Preview()
external Widget foo();

class B extends StatelessWidget {
  @Preview()
  external B();

  @Preview()
  external static Widget foo();
}
''',
      [
        error(WarningCode.invalidWidgetPreviewApplication, 88, 7),
        error(WarningCode.invalidWidgetPreviewApplication, 159, 7),
        error(WarningCode.invalidWidgetPreviewApplication, 189, 7),
      ],
    );
  }

  // @Preview cannot be applied to instance members of classes.
  test_invalidInstanceMethod() async {
    await assertErrorsInCode(
      '''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class B {
  @Preview()
  Widget foo() {
    return Text('Foo');
  }
}
''',
      [error(WarningCode.invalidWidgetPreviewApplication, 100, 7)],
    );
  }

  // @Preview cannot be applied to nested functions.
  test_invalidNestedFunction() async {
    await assertErrorsInCode(
      '''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

Widget foo() {
  @Preview()
  Widget nested() {
    return Text('Foo');
  }
  return nested();
}

class B {
  static Widget foo() {
   @Preview()
    Widget nested() {
      return Text('Foo');
    } 
    return nested();
  }
}
''',
      [
        error(WarningCode.invalidWidgetPreviewApplication, 105, 7),
        error(WarningCode.invalidWidgetPreviewApplication, 223, 7),
      ],
    );
  }

  // @Preview cannot be applied to:
  //
  //  - Enums members
  //  - Extension methods
  //  - Extension type members
  //  - Mixin members
  test_invalidParentContext() async {
    await assertErrorsInCode(
      '''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class Foo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text('Foo');
}

enum B {
  a,
  b,
  c;

  @Preview()
  const B();
}

extension on Foo {
  @Preview()
  Widget invalidExtensionPreview() => Text('Invalid');
}

mixin PreviewMixin {
  @Preview()
  Widget invalidMixinPreview() => Text('Invalid');
}

extension type FooExtensionType(Foo foo) {
  @Preview()
  Widget invalidExtensionTypePreview() => Text('Invalid');
}
''',
      [
        error(WarningCode.invalidWidgetPreviewApplication, 219, 7),
        error(WarningCode.invalidWidgetPreviewApplication, 267, 7),
        error(WarningCode.unusedElement, 286, 23),
        error(WarningCode.invalidWidgetPreviewApplication, 359, 7),
        error(WarningCode.invalidWidgetPreviewApplication, 469, 7),
      ],
    );
  }

  // @Preview cannot be applied to members of private classes.
  test_invalidPrivateClass() async {
    await assertErrorsInCode(
      '''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class _B extends StatelessWidget {
  @Preview()
  _B();

  @Preview()
  factory _B.foo() => _B();

  @Preview()
  static Widget bar() => Text('Bar');

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''',
      [
        error(WarningCode.unusedElement, 93, 2),
        error(WarningCode.invalidWidgetPreviewApplication, 125, 7),
        error(WarningCode.invalidWidgetPreviewApplication, 147, 7),
        error(WarningCode.unusedElement, 170, 3),
        error(WarningCode.invalidWidgetPreviewApplication, 189, 7),
        error(WarningCode.unusedElement, 215, 3),
      ],
    );
  }

  // @Preview cannot be applied to private generative or factory constructors.
  test_invalidPrivateClassConstructors() async {
    await assertErrorsInCode(
      '''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class B extends StatelessWidget {
  @Preview()
  B._();

  @Preview()
  factory B._foo() => B();

  B();

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''',
      [
        error(WarningCode.invalidWidgetPreviewApplication, 124, 7),
        error(WarningCode.unusedElement, 138, 1),
        error(WarningCode.invalidWidgetPreviewApplication, 147, 7),
        error(WarningCode.unusedElement, 169, 4),
      ],
    );
  }

  // @Preview cannot be applied to private static functions.
  test_invalidPrivateClassStatic() async {
    await assertErrorsInCode(
      '''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class B extends StatelessWidget {
  @Preview()
  static Widget _foo() {
    return Text('Foo');
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''',
      [
        error(WarningCode.invalidWidgetPreviewApplication, 124, 7),
        error(WarningCode.unusedElement, 150, 4),
      ],
    );
  }

  // @Preview cannot be applied to private top-level functions.
  test_invalidPrivateTopLevel() async {
    await assertErrorsInCode(
      '''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

@Preview()
Widget _foo() {
  return Text('Foo');
}
''',
      [
        error(WarningCode.invalidWidgetPreviewApplication, 88, 7),
        error(WarningCode.unusedElement, 105, 4),
      ],
    );
  }

  // Ensure that @Preview can be applied to public factory constructors of
  // abstract Widget subtypes.
  test_validAbstractClassFactoryConstructor() async {
    await assertNoErrorsInCode('''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

abstract class B extends StatelessWidget {
  @Preview()
  factory B() => C();

  @Preview()
  factory B.named() => C.named();

  B._();
}

class C extends B {
  C() : super._();
  factory C.named() => C();

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''');
  }

  // Ensure that constant instances of @Preview(...) can be applied.
  test_validAnnotationConstant() async {
    await assertNoErrorsInCode('''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

const myPreview = Preview(name: 'Testing');

@myPreview
Widget bar() => Text('Bar');
''');
  }

  // Ensure that @Preview can be applied to public factory constructors of
  // Widget subtypes, including those with optional parameters.
  test_validClassFactoryConstructor() async {
    await assertNoErrorsInCode('''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class B extends StatelessWidget {
  @Preview()
  factory B.foo({Key? key}) => B._(key: key);

  @Preview()
  factory B.bar() => B._();

  B._({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''');
  }

  // Ensure that @Preview can be applied to public constructors of Widget
  // subtypes, including those with optional parameters.
  test_validClassGenerativeConstructor() async {
    await assertNoErrorsInCode('''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class B extends StatelessWidget {
  @Preview()
  const B({super.key});

  @Preview()
  B.foo([String? _]);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''');
  }

  // Ensure that @Preview can be applied to public static functions that are
  // defined in public classes and that return Widget or WidgetBuilder.
  test_validClassStatic() async {
    await assertNoErrorsInCode('''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class B extends StatelessWidget {
  @Preview()
  static Widget foo() {
    return Text('Foo');
  }

  @Preview()
  static WidgetBuilder bar() {
    return (BuildContext context) {
      return Text('Bar');
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''');
  }

  // Ensure that @Preview can be applied to public top-level functions that
  // return a Widget or WidgetBuilder.
  test_validTopLevel() async {
    await assertNoErrorsInCode('''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

@Preview(name: 'Widget')
Widget foo() => Text('Foo');

@Preview(name: 'WidgetBuilder')
WidgetBuilder bar() {
  return (BuildContext context) {
    return Text('Bar');
  };
}
''');
  }

  // Ensure that @Preview can be applied to functions that explicitly return a
  // subtype of Widget.
  test_validTopLevel_widgetSubtype() async {
    await assertNoErrorsInCode('''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

typedef MyWidget = Widget;

@Preview(name: 'Testing')
Text foo() => Text('Foo');

@Preview(name: 'Testing')
MyWidget bar() => Text('Bar');
''');
  }
}
