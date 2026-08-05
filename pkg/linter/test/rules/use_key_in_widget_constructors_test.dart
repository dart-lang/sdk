// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseKeyInWidgetConstructorsTest);
  });
}

@reflectiveTest
class UseKeyInWidgetConstructorsTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => LintNames.use_key_in_widget_constructors;

  test_augmentedConstructor_noKey() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:flutter/widgets.dart';
part 'test.dart';

class W extends StatelessWidget {
  const W();

  @override
  Widget build(BuildContext context) => Container();
}
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment class W {
  augment const W();
}
''');
  }

  test_constNamedConstructor_missingKey() async {
    await assertDiagnosticsFromMarkup(r'''
import 'package:flutter/widgets.dart';

abstract class MyWidget extends StatelessWidget {
  const MyWidget.[!named!]();
}
''');
  }

  test_constructor_factory_withoutKey() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  MyWidget({super.key});
  factory fact() => MyWidget();
}
''');
  }

  test_constructor_new_withoutKey() async {
    await assertDiagnosticsFromMarkup(r'''
import 'package:flutter/widgets.dart';

abstract class MyWidget extends StatelessWidget {
  [!new!] ();
}
''');
  }

  test_constructorInAugmentedClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:flutter/widgets.dart';
part 'test.dart';

class W extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container();
}
''');

    await assertDiagnosticsFromMarkup(r'''
part of 'a.dart';

import 'package:flutter/widgets.dart';

augment class W { }

augment class W {
  const [!W!]({Key? key});
}
''');
  }

  test_constructorInAugmentedClass_noKeyParam() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:flutter/widgets.dart';
part 'test.dart';

class W extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container();
}
''');

    await assertDiagnosticsFromMarkup(r'''
part of 'a.dart';

augment class W {
  const [!W!]();
}
''');
  }

  test_constUnnamedConstructor_missingKey() async {
    await assertDiagnosticsFromMarkup(r'''
import 'package:flutter/widgets.dart';

abstract class MyWidget extends StatelessWidget {
  const [!MyWidget!]();
}
''');
  }

  test_factoryConstructor() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  MyWidget({super.key});
  factory MyWidget.fact() => MyWidget();
  @override
  Widget build(BuildContext context) => Container();
}
''');
  }

  test_implementsWidget() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract class AbstractWidget implements Widget {}
''');
  }

  test_key_keyPassedToSuper() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract class MyWidget extends StatelessWidget {
  MyWidget({Key? key}) : super(key: key ?? Key(''));
}
''');
  }

  test_keyUse_inAugmentedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

augment class W {
  const W({Key? key}) : super(key: key);
}
''');

    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
part 'a.dart';

class W extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container();
}
''');
  }

  test_missingConstructor() async {
    await assertDiagnosticsFromMarkup(r'''
import 'package:flutter/widgets.dart';

abstract class [!NoConstructorWidget!] extends StatefulWidget {}
''');
  }

  test_missingKey() async {
    await assertDiagnosticsFromMarkup(r'''
import 'package:flutter/widgets.dart';

abstract class MyWidget extends StatelessWidget {
  [!MyWidget!]();
}
''');
  }

  test_missingKey_keyPassedToSuper() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract class MyWidget extends StatelessWidget {
  MyWidget.superCall() : super(key: Key(''));
}
''');
  }

  test_primaryConstructor_withKey() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract class MyWidget({super.key}) extends StatelessWidget {}
''');
  }

  test_primaryConstructor_withoutKey() async {
    await assertDiagnosticsFromMarkup(r'''
import 'package:flutter/widgets.dart';

abstract class [!MyWidget!]() extends StatelessWidget {}
''');
  }

  test_privateClass() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

// ignore: unused_element
abstract class _PrivateWidget extends StatefulWidget {}
''');
  }

  test_privateConstructor() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract class MyWidget extends StatelessWidget {
  MyWidget._private();
}
''');
  }

  test_redirectingConstructor_withKey() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract class MyWidget extends StatelessWidget {
  MyWidget.redirect() : this.withKey(key: Key(''));
  MyWidget.withKey({Key? key}) : super(key: key ?? Key(''));
}
''');
  }

  test_simpleFormalParameter_notPassedToSuper() async {
    await assertDiagnosticsFromMarkup(r'''
import 'package:flutter/widgets.dart';

abstract class MyWidget extends StatelessWidget {
  MyWidget.[!withKey!]({Key? key});
}
''');
  }

  test_simpleFormalParameter_passedToSuper() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract class MyWidget extends StatelessWidget {
  MyWidget.withKey({Key? key}) : super(key: key ?? Key(''));
}
''');
  }

  test_superParameter() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class OtherWidget extends StatelessWidget {
  const OtherWidget({required super.key});

  @override
  Widget build(BuildContext context) => Container();
}
''');
  }

  test_visibleForTestingClass() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

@visibleForTesting
abstract class MyWidget extends StatefulWidget {}
''');
  }

  test_visibleForTestingConstructor() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract class MyWidget extends StatefulWidget {
  @visibleForTesting
  MyWidget();
}
''');
  }

  test_visibleForTestingConstructor_primary() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract class MyWidget() extends StatefulWidget {
  @visibleForTesting
  this;
}
''');
  }
}
