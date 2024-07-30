// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseDecoratedBoxTest);
  });
}

@reflectiveTest
class UseDecoratedBoxTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get lintRule => 'use_decorated_box';

  test_containerWithAnotherArgument() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget containerWithAnotherArgument() {
  return Container(width: 20);
}
''');
  }

  test_containerWithChild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(child: SizedBox());
}
''');
  }

  test_containerWithDecoration() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(decoration: BoxDecoration());
}
''');
  }

  test_containerWithDecorationAndChild() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(
    decoration: BoxDecoration(),
    child: SizedBox(),
  );
}
''', [
      lint(61, 9),
    ]);
  }

  test_containerWithDecorationAndChildAndOtherArgument() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(
    decoration: BoxDecoration(),
    width: 20,
    child: SizedBox(),
  );
}
''');
  }

  test_containerWithDecorationAndOtherArgument() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(
    decoration: BoxDecoration(),
    width: 20,
  );
}
''');
  }

  test_containerWithKey() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(key: Key('abc'));
}
''');
  }

  test_containerWithKeyAndChild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(
    key: Key('abc'),
    child: SizedBox(),
  );
}
''');
  }

  test_containerWithKeyAndDecoration() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(
    key: Key('abc'),
    decoration: BoxDecoration(),
  );
}
''');
  }

  test_containerWithKeyAndDecorationAndChild() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(
    key: Key('abc'),
    decoration: BoxDecoration(),
    child: SizedBox(),
  );
}
''', [
      lint(61, 9),
    ]);
  }

  test_containerWithoutArguments() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container();
}
''');
  }
}
