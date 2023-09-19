// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SortChildPropertiesLastTest);
  });
}

@reflectiveTest
class SortChildPropertiesLastTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get lintRule => 'sort_child_properties_last';

  test_childArgumentBeforeKeyArgument() async {
    await assertDiagnostics(r'''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
void f() {
  SizedBox(
    child: Column(),
    key: Key(''),
  );
}
''', [
      lint(108, 15),
    ]);
  }

  test_childArgumentOnly() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
void f() {
  SizedBox(
    child: Column(),
  );
}
''');
  }

  test_childrenArgumentBeforeKeyArgument_insideOtherChildArgument() async {
    await assertDiagnostics(r'''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
void f() {
  SizedBox(
    key: Key(''),
    child: SizedBox(
      child: Column(
        children: [],
        key: Key(''),
      ),
    ),
  );
}
''', [
      lint(172, 12),
    ]);
  }

  test_keyArgumentBeforeChildArgument() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
void f() {
  SizedBox(
    key: Key(''),
    child: Column(),
  );
}
''');
  }

  test_keyArgumentBeforeChildrenArgument() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
void f() {
  SizedBox(
    key: Key(''),
    child: SizedBox(
      child: Column(
        key: Key(''),
        children: [],
      ),
    ),
  );
}
''');
  }

  test_keyArgumentThenChildArgumentThenClosureArgument() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
void f() {
  RawMaterialButton(
    key: Key(''),
    child: SizedBox(
      child: Column(
        key: Key(''),
        children: [],
      ),
    ),
    onPressed: () {},
  );
}
''');
  }

  test_nestedChildren() async {
    // See https://dart-review.googlesource.com/c/sdk/+/161624.
    await assertDiagnostics(r'''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
void f() {
  Column(
    children: [
      Column(
        children: [
          Text('a'),
        ],
        key: Key(''),
      ),
      Text('b'),
      Text('c'),
      Text('d'),
    ],
    key: Key(''),
  );
}
''', [
      lint(106, 165),
      lint(140, 42),
    ]);
  }
}
