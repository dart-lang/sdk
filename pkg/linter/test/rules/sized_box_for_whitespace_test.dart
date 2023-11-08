// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SizedBoxForWhitespaceTest);
  });
}

@reflectiveTest
class SizedBoxForWhitespaceTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get lintRule => 'sized_box_for_whitespace';

  test_hasChild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return Container(
    child: Row(),
  );
}
''');
  }

  test_hasHeight_andChild() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return Container(
    height: 10,
    child: Row(),
  );
}
''', [
      lint(62, 9),
    ]);
  }

  test_hasHeight_noChild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return Container(
    height:10,
  );
}
''');
  }

  test_hasWidth_andChild() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return Container(
    width: 10,
    child: Row(),
  );
}
''', [
      lint(62, 9),
    ]);
  }

  test_hasWidth_noChild() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return Container(
    width: 10,
  );
}
''');
  }

  test_hasWidthAndHeight_andChild() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return Container(
    width: 10,
    height: 10,
    child: Row(),
  );
}
''', [
      lint(62, 9),
    ]);
  }

  test_hasWidthAndHeight_andKey_noChild() async {
    await assertDiagnostics(r'''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

Widget f() {
  return Container(
    key: Key(''),
    width: 10,
    height: 10,
  );
}
''', [
      lint(104, 9),
    ]);
  }

  test_hasWidthAndHeight_noChild() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget f() {
  return Container(
    width: 10,
    height: 10,
  );
}
''', [
      lint(62, 9),
    ]);
  }

  test_noArguments() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget emptyContainer() {
  return Container();
}
''');
  }
}
