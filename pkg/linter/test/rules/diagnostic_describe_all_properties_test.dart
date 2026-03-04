// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DiagnosticDescribeAllPropertiesTest);
  });
}

@reflectiveTest
class DiagnosticDescribeAllPropertiesTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get lintRule => LintNames.diagnostic_describe_all_properties;

  test_field() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/foundation.dart';
class MyWidget with Diagnosticable {
  bool p = false;
}
''',
      [lint(86, 1)],
    );
  }

  test_field_collectionOfWidgets() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
class MyWidget with Diagnosticable {
  List<Widget> p = [];
}
''');
  }

  test_field_coveredByDebugField() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/foundation.dart';
class MyWidget with Diagnosticable {
  String foo = '';
  String debugFoo = '';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    debugFoo;
  }
}
''');
  }

  test_field_inDebugDescribeChildren() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/foundation.dart';
class MyWidget extends DiagnosticableTree {
  String p = '';

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    p;
    return [];
  }
}
''');
  }

  test_field_inDebugFillProperties() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/foundation.dart';
class MyWidget with Diagnosticable {
  String p = '';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    p;
  }
}
''');
  }

  test_field_originPrimaryConstructor_default_string() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/foundation.dart';
class MyWidget([final String p = '']) with Diagnosticable {}
''',
      [lint(71, 1)],
    );
  }

  test_field_originPrimaryConstructor_privateNamed_string() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/foundation.dart';
// ignore: unused_field_from_primary_constructor
class MyWidget({final String? _p}) with Diagnosticable {}
''');
  }

  test_field_originPrimaryConstructor_string() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/foundation.dart';
class MyWidget(final String p) with Diagnosticable {}
''',
      [lint(70, 1)],
    );
  }

  test_field_originPrimaryConstructor_string_described() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/foundation.dart';
class MyWidget(final String p) with Diagnosticable {
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    p;
  }
}
''');
  }

  test_field_originPrimaryConstructor_string_describedInChildren() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/foundation.dart';
class MyWidget(final String p) extends DiagnosticableTree {
  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    p;
    return [];
  }
}
''');
  }

  test_field_private() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/foundation.dart';
class MyWidget with Diagnosticable {
  // ignore: unused_field
  String _p = '';
}
''');
  }

  test_field_string() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/foundation.dart';
class MyWidget with Diagnosticable {
  String p = '';
}
''',
      [lint(88, 1)],
    );
  }

  test_field_widget() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
class MyWidget with Diagnosticable {
  Widget? p;
}
''');
  }

  test_getter_string() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/foundation.dart';
class MyWidget with Diagnosticable {
  String get p => '';
}
''',
      [lint(92, 1)],
    );
  }

  test_getter_widget() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
class MyWidget with Diagnosticable {
  Widget? get p => null;
}
''');
  }

  test_nonDeclaringParameter() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/foundation.dart';
class MyWidget(String p) with Diagnosticable {}
''');
  }

  test_staticField_string() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/foundation.dart';
class MyWidget with Diagnosticable {
  static String p = '';
}
''');
  }
}
