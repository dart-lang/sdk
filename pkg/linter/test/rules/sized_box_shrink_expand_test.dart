// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SizedBoxShrinkExpandTest);
  });
}

@reflectiveTest
class SizedBoxShrinkExpandTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get lintRule => 'sized_box_shrink_expand';

  test_infiniteHeight_noWidth() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(height: double.infinity, child: Container());
}
''');
  }

  test_infiniteWidth_infiniteHeight() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(
    height: double.infinity,
    width: double.infinity,
    child: Container(),
  );
}
''', [
      lint(61, 8),
    ]);
  }

  test_infiniteWidth_noHeight() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(width: double.infinity, child: Container());
}
''');
  }

  test_infiniteWidth_zeroHeight() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(
    height: 0,
    width: double.infinity,
    child: Container(),
  );
}
''');
  }

  test_mixedWidth_mixedHeight() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(
    height: 26,
    width: 42,
    child: Container(),
  );
}
''');
  }

  test_zeroHeight_noWidth() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(height: 0, child: Container());
}
''');
  }

  test_zeroWidth_infiniteHeight() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(
    height: double.infinity,
    width: 0,
    child: Container(),
  );
}
''');
  }

  test_zeroWidth_noHeight() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(width: 0, child: Container());
}
''');
  }

  test_zeroWidth_zeroHeight() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return SizedBox(height: 0, width: 0,child: Container());
}
''', [
      lint(61, 8),
    ]);
  }
}
