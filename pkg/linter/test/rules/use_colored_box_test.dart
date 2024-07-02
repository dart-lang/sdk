// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseColoredBoxTest);
  });
}

@reflectiveTest
class UseColoredBoxTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get lintRule => 'use_colored_box';

  test_childArgument() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget containerWithChild() {
  return Container(
    child: SizedBox(),
  );
}
''');
  }

  test_colorArgument() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return Container(
    color: Color(0xffffffff),
  );
}
''');
  }

  test_colorArgument_andChild() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget containerWithColorAndChild() {
  return Container(
    color: Color(0xffffffff),
    child: SizedBox(),
  );
}
''', [
      lint(87, 9),
    ]);
  }

  test_colorArgument_named_moreArguments() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return Container(
    color: Color(0xffffffff),
    width: 20,
  );
}
''');
  }

  test_colorArgument_nullableExpression() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f(Color? myColor) {
  return Container(color: myColor);
}
''');
  }

  test_keyArgument() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return Container(key: Key('abc'));
}
''');
  }

  test_noArgument() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return Container();
}
''');
  }
}
