// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidUnnecessaryContainersTest);
  });
}

@reflectiveTest
class AvoidUnnecessaryContainersTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get lintRule => 'avoid_unnecessary_containers';

  test_childOnly() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(child: Row());
}
''', [
      lint(61, 9),
    ]);
  }

  test_noArguments() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container();
}
''');
  }

  test_otherArguments() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() {
  return Container(
    child: Row(),
    width: 10,
    height: 10,
  );
}
''');
  }
}
