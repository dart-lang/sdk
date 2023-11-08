// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddDiagnosticPropertyReferenceBulkTest);
    defineReflectiveTests(AddDiagnosticPropertyReferenceTest);
  });
}

@reflectiveTest
class AddDiagnosticPropertyReferenceBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.diagnostic_describe_all_properties;

  Future<void> test_singleFile() async {
    writeTestPackageConfig(flutter: true);
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  bool get absorbing => _absorbing;
  bool _absorbing;
  bool ignoringSemantics;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('absorbing', absorbing));
  }
}

class D extends Widget with Diagnosticable {
  bool ignoringSemantics;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  }
}
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  bool get absorbing => _absorbing;
  bool _absorbing;
  bool ignoringSemantics;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('absorbing', absorbing));
    properties.add(DiagnosticsProperty<bool>('ignoringSemantics', ignoringSemantics));
  }
}

class D extends Widget with Diagnosticable {
  bool ignoringSemantics;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties.add(DiagnosticsProperty<bool>('ignoringSemantics', ignoringSemantics));
  }
}
''');
  }
}

@reflectiveTest
class AddDiagnosticPropertyReferenceTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_DIAGNOSTIC_PROPERTY_REFERENCE;

  @override
  String get lintCode => LintNames.diagnostic_describe_all_properties;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  Future<void> test_boolField() async {
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  bool get absorbing => _absorbing;
  bool _absorbing = false;
  bool ignoringSemantics = false;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('absorbing', absorbing));
  }
}
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  bool get absorbing => _absorbing;
  bool _absorbing = false;
  bool ignoringSemantics = false;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('absorbing', absorbing));
    properties.add(DiagnosticsProperty<bool>('ignoringSemantics', ignoringSemantics));
  }
}
''');
  }

  Future<void> test_boolField_empty() async {
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  bool ignoringSemantics = false;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  }
}
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  bool ignoringSemantics = false;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties.add(DiagnosticsProperty<bool>('ignoringSemantics', ignoringSemantics));
  }
}
''');
  }

  Future<void> test_boolField_empty_customParamName() async {
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  bool ignoringSemantics = false;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder props) {
  }
}
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  bool ignoringSemantics = false;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder props) {
    props.add(DiagnosticsProperty<bool>('ignoringSemantics', ignoringSemantics));
  }
}
''');
  }

  Future<void> test_boolGetter() async {
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  bool get absorbing => _absorbing;
  bool _absorbing = false;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  bool get absorbing => _absorbing;
  bool _absorbing = false;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('absorbing', absorbing));
  }
}
''');
  }

  Future<void> test_colorField() async {
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  Color field = Color(0);
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  Color field = Color(0);
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('field', field));
  }
}
''');
  }

  Future<void> test_doubleField() async {
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  double field = 4.2;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  double field = 4.2;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('field', field));
  }
}
''');
  }

  Future<void> test_dynamicField() async {
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  dynamic field;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  dynamic field;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('field', field));
  }
}
''');
  }

  Future<void> test_enumField() async {
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  Foo field = Foo.bar;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
enum Foo {bar}
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  Foo field = Foo.bar;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Foo>('field', field));
  }
}
enum Foo {bar}
''');
  }

  Future<void> test_functionField() async {
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  ValueChanged<double> onChanged = (d) {};
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
typedef ValueChanged<T> = void Function(T value);
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  ValueChanged<double> onChanged = (d) {};
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<ValueChanged<double>>.has('onChanged', onChanged));
  }
}
typedef ValueChanged<T> = void Function(T value);
''');
  }

  Future<void> test_intField() async {
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  int field = 0;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  int field = 0;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('field', field));
  }
}
''');
  }

  Future<void> test_iterableField() async {
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  Iterable<String> field = [];
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  Iterable<String> field = [];
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<String>('field', field));
  }
}
''');
  }

  Future<void> test_listField() async {
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  List<List<String>> field = [];
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  List<List<String>> field = [];
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<List<String>>('field', field));
  }
}
''');
  }

  Future<void> test_matrix4Field() async {
    writeTestPackageConfig(
      flutter: true,
      vector_math: true,
    );
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

class C extends Widget with Diagnosticable {
  Matrix4 field = Matrix4();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

class C extends Widget with Diagnosticable {
  Matrix4 field = Matrix4();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(TransformProperty('field', field));
  }
}
''');
  }

  Future<void> test_objectField() async {
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  Object field = '';
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  Object field = '';
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Object>('field', field));
  }
}
''');
  }

  Future<void> test_stringField() async {
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  String field = '';
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  String field = '';
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('field', field));
  }
}
''');
  }

  Future<void> test_stringField_noDebugFillProperties() async {
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  String field = '';
}
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  String field = '';
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('field', field));
  }
}
''');
  }

  Future<void> test_typeOutOfScopeField() async {
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  ClassNotInScope<bool> onChanged;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  ClassNotInScope<bool> onChanged;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ClassNotInScope<bool>>('onChanged', onChanged));
  }
}
''',
        errorFilter: (error) =>
            error.errorCode != CompileTimeErrorCode.UNDEFINED_CLASS);
  }

  Future<void> test_typeOutOfScopeGetter() async {
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  ClassNotInScope<bool> get onChanged => null;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  ClassNotInScope<bool> get onChanged => null;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ClassNotInScope<bool>>('onChanged', onChanged));
  }
}
''',
        errorFilter: (error) =>
            error.errorCode != CompileTimeErrorCode.UNDEFINED_CLASS);
  }

  Future<void> test_varField() async {
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  var field;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
''');
    await assertHasFix('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class C extends Widget with Diagnosticable {
  var field;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('field', field));
  }
}
''');
  }

  // todo (pq): consider a test for a body w/ no CR
}
