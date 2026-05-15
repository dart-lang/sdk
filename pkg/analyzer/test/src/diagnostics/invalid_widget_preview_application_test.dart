// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/package_config_file_builder.dart';
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
    await resolveTestCodeWithDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

abstract class B extends StatelessWidget {
  @Preview()
// ^^^^^^^
// [diag.invalidWidgetPreviewApplication] The '@Preview(...)' annotation can only be applied to public, statically accessible constructors and functions.
  B();
}
''');
  }

  // @Preview application must invoke the `Preview` constructor.
  test_invalidAnnotationApplication() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class B extends StatelessWidget {
  @Preview
//^^^^^^^^
// [diag.noAnnotationConstructorArguments] Annotation creation must have arguments.
  B();
}
''');
  }

  // @Preview cannot be applied to external constructors.
  test_invalidExternalConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class B extends StatelessWidget {
  @Preview()
// ^^^^^^^
// [diag.invalidWidgetPreviewApplication] The '@Preview(...)' annotation can only be applied to public, statically accessible constructors and functions.
  external B();
}
''');
  }

  // @Preview cannot be applied to external functions.
  test_invalidExternalStaticFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class B extends StatelessWidget {
  @Preview()
// ^^^^^^^
// [diag.invalidWidgetPreviewApplication] The '@Preview(...)' annotation can only be applied to public, statically accessible constructors and functions.
  external static Widget foo();
}
''');
  }

  // @Preview cannot be applied to external top-level functions.
  test_invalidExternalTopLevelFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

@Preview()
// [diag.invalidWidgetPreviewApplication][column 2][length 7] The '@Preview(...)' annotation can only be applied to public, statically accessible constructors and functions.
external Widget foo();
''');
  }

  // @Preview cannot be applied to instance members of classes.
  test_invalidInstanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class B {
  @Preview()
// ^^^^^^^
// [diag.invalidWidgetPreviewApplication] The '@Preview(...)' annotation can only be applied to public, statically accessible constructors and functions.
  Widget foo() {
    return Text('Foo');
  }
}
''');
  }

  // @Preview cannot be applied to nested functions.
  test_invalidNestedFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

Widget foo() {
  @Preview()
// ^^^^^^^
// [diag.invalidWidgetPreviewApplication] The '@Preview(...)' annotation can only be applied to public, statically accessible constructors and functions.
  Widget nested() {
    return Text('Foo');
  }
  return nested();
}
''');
  }

  // @Preview cannot be applied to enum members.
  test_invalidParentContext_enumMember() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:flutter/widget_previews.dart';

enum B {
  a,
  b,
  c;

  @Preview()
// ^^^^^^^
// [diag.invalidWidgetPreviewApplication] The '@Preview(...)' annotation can only be applied to public, statically accessible constructors and functions.
  const B();
}
''');
  }

  // @Preview cannot be applied to extension methods.
  test_invalidParentContext_extensionMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class Foo extends StatelessWidget {
}

extension E on Foo {
  @Preview()
// ^^^^^^^
// [diag.invalidWidgetPreviewApplication] The '@Preview(...)' annotation can only be applied to public, statically accessible constructors and functions.
  Widget invalidExtensionPreview() => Text('Invalid');
}
''');
  }

  // @Preview cannot be applied to extension type members.
  test_invalidParentContext_extensionTypeMember() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class Foo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text('Foo');
}

extension type FooExtensionType(Foo foo) {
  @Preview()
// ^^^^^^^
// [diag.invalidWidgetPreviewApplication] The '@Preview(...)' annotation can only be applied to public, statically accessible constructors and functions.
  Widget invalidExtensionTypePreview() => Text('Invalid');
}
''');
  }

  // @Preview cannot be applied to extension type members.
  test_invalidParentContext_mixinMember() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class Foo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text('Foo');
}

mixin PreviewMixin {
  @Preview()
// ^^^^^^^
// [diag.invalidWidgetPreviewApplication] The '@Preview(...)' annotation can only be applied to public, statically accessible constructors and functions.
  Widget invalidMixinPreview() => Text('Invalid');
}
''');
  }

  // @Preview cannot be applied to constructors of private classes.
  test_invalidPrivateClass_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
// ignore_for_file: unused_element
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class _B extends StatelessWidget {
  @Preview()
// ^^^^^^^
// [diag.invalidWidgetPreviewApplication] The '@Preview(...)' annotation can only be applied to public, statically accessible constructors and functions.
  _B();
}
''');
  }

  // @Preview cannot be applied to factory constructors of private classes.
  test_invalidPrivateClass_factoryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
// ignore_for_file: unused_element
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class _B extends StatelessWidget {
  @Preview()
// ^^^^^^^
// [diag.invalidWidgetPreviewApplication] The '@Preview(...)' annotation can only be applied to public, statically accessible constructors and functions.
  factory _B.foo() => throw '';
}
''');
  }

  // @Preview cannot be applied to instance members of private classes.
  test_invalidPrivateClass_instanceMember() async {
    await resolveTestCodeWithDiagnostics(r'''
// ignore_for_file: unused_element
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class _B extends StatelessWidget {
  @Preview()
// ^^^^^^^
// [diag.invalidWidgetPreviewApplication] The '@Preview(...)' annotation can only be applied to public, statically accessible constructors and functions.
  static Widget bar() => Text('Bar');
}
''');
  }

  // @Preview cannot be applied to private static functions.
  test_invalidPrivateClassStatic() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class B extends StatelessWidget {
  @Preview()
// ^^^^^^^
// [diag.invalidWidgetPreviewApplication] The '@Preview(...)' annotation can only be applied to public, statically accessible constructors and functions.
  static Widget _foo() {
//              ^^^^
// [diag.unusedElement] The declaration '_foo' isn't referenced.
    return Text('Foo');
  }
}
''');
  }

  // @Preview cannot be applied to private factory constructors.
  test_invalidPrivateConstructor_factory() async {
    await resolveTestCodeWithDiagnostics(r'''
// ignore_for_file: unused_element
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class B extends StatelessWidget {
  @Preview()
// ^^^^^^^
// [diag.invalidWidgetPreviewApplication] The '@Preview(...)' annotation can only be applied to public, statically accessible constructors and functions.
  factory B._foo() => B();

  B();
}
''');
  }

  // @Preview cannot be applied to private generative constructors.
  test_invalidPrivateConstructor_generative() async {
    await resolveTestCodeWithDiagnostics(r'''
// ignore_for_file: unused_element
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class B extends StatelessWidget {
  @Preview()
// ^^^^^^^
// [diag.invalidWidgetPreviewApplication] The '@Preview(...)' annotation can only be applied to public, statically accessible constructors and functions.
  B._();
}
''');
  }

  // @Preview cannot be applied to private primary constructors.
  test_invalidPrivateConstructor_primary() async {
    await resolveTestCodeWithDiagnostics(r'''
// ignore_for_file: unused_element
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class B._() extends StatelessWidget {
  @Preview()
// ^^^^^^^
// [diag.invalidWidgetPreviewApplication] The '@Preview(...)' annotation can only be applied to public, statically accessible constructors and functions.
  this;
}
''');
  }

  // @Preview cannot be applied to private top-level functions.
  test_invalidPrivateTopLevel() async {
    await resolveTestCodeWithDiagnostics(r'''
// ignore_for_file: unused_element
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

@Preview()
// [diag.invalidWidgetPreviewApplication][column 2][length 7] The '@Preview(...)' annotation can only be applied to public, statically accessible constructors and functions.
Widget _foo() {
  return Text('Foo');
}
''');
  }

  // Ensure that @Preview can be applied to public factory constructors of
  // abstract Widget subtypes.
  test_validAbstractClassFactoryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
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
}
''');
  }

  // Ensure that constant instances of @Preview(...) can be applied.
  test_validAnnotationConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class B extends StatelessWidget {
  @Preview()
  factory B.foo({Key? key}) => B._(key: key);

  @Preview()
  factory B.bar() => B._();

  B._({super.key});
}
''');
  }

  // Ensure that @Preview can be applied to public constructors of Widget
  // subtypes, including those with optional parameters.
  test_validClassGenerativeConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class B extends StatelessWidget {
  @Preview()
  const B({super.key});

  @Preview()
  B.foo([String? _]);
}
''');
  }

  // Ensure that @Preview can be applied to public primary constructors of
  // Widget subtypes, including those with optional parameters.
  test_validClassPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';

class B({super.key}) extends StatelessWidget {
  @Preview()
  this;
}
''');
  }

  // Ensure that @Preview can be applied to public static functions that are
  // defined in public classes and that return Widget or WidgetBuilder.
  test_validClassStatic() async {
    await resolveTestCodeWithDiagnostics(r'''
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
}
''');
  }

  // Ensure that @Preview can be applied to public top-level functions that
  // return a Widget or WidgetBuilder.
  test_validTopLevel() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
