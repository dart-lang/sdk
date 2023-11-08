// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseKeyInWidgetConstructorsTest);
  });
}

@reflectiveTest
class UseKeyInWidgetConstructorsTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get lintRule => 'use_key_in_widget_constructors';

  test_constNamedConstructor_missingKey() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract class MyWidget extends StatelessWidget {
  const MyWidget.named();
}
''', [
      lint(107, 5),
    ]);
  }

  test_constUnnamedConstructor_missingKey() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract class MyWidget extends StatelessWidget {
  const MyWidget();
}
''', [
      lint(98, 8),
    ]);
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

  test_missingConstructor() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract class NoConstructorWidget extends StatefulWidget {}
''', [
      lint(55, 19),
    ]);
  }

  test_missingKey() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract class MyWidget extends StatelessWidget {
  MyWidget();
}
''', [
      lint(92, 8),
    ]);
  }

  test_missingKey_keyPassedToSuper() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

abstract class MyWidget extends StatelessWidget {
  MyWidget.superCall() : super(key: Key(''));
}
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
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

abstract class MyWidget extends StatelessWidget {
  MyWidget.redirect() : this.withKey(key: Key(''));
  MyWidget.withKey({Key? key}) : super(key: key ?? Key(''));
}
''');
  }

  test_simpleFormalParameter_notPassedToSuper() async {
    await assertDiagnostics(r'''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

abstract class MyWidget extends StatelessWidget {
  MyWidget.withKey({Key? key});
}
''', [
      lint(143, 7),
    ]);
  }

  test_simpleFormalParameter_passedToSuper() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/foundation.dart';
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
}
