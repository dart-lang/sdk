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

  /// Full coverage in fix/add_diagnostic_property_reference_test.dart
  Future<void> test_boolField_debugFillProperties() async {
    verifyNoTestUnitErrors = false;
    await resolveTestUnit('''
class W extends Widget {
  bool /*caret*/property;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
''');
    await assertHasAssist('''
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
}
