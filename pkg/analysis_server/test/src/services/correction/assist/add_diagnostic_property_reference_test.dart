// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddDiagnosticPropertyReferenceTest);
  });
}

@reflectiveTest
class AddDiagnosticPropertyReferenceTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.ADD_DIAGNOSTIC_PROPERTY_REFERENCE;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  /// Full coverage in fix/add_diagnostic_property_reference_test.dart
  Future<void> test_boolField_debugFillProperties() async {
    await resolveTestCode('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class W extends Widget {
  bool /*caret*/property;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class W extends Widget {
  bool property;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('property', property));
  }
}
''');
  }

  Future<void> test_notAvailable_mixin() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
mixin MyMixin {
  String get foo/*caret*/() {}
}
''');
    await assertNoAssist();
  }

  Future<void> test_notAvailable_outsideDiagnosticable() async {
    await resolveTestCode('''
class C {
  String get f/*caret*/ => null;
}
''');
    await assertNoAssist();
  }
}
