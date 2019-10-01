// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddDiagnosticPropertyReferenceTest);
  });
}

@reflectiveTest
class AddDiagnosticPropertyReferenceTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_DIAGNOSTIC_PROPERTY_REFERENCE;

  @override
  String get lintCode => LintNames.diagnostic_describe_all_properties;

  test_boolField_debugFillProperties() async {
    await resolveTestUnit('''
class Absorber extends Widget {
  bool get absorbing => _absorbing;
  bool _absorbing;
  bool /*LINT*/ignoringSemantics;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('absorbing', absorbing));
  }
}
''');
    await assertHasFix('''
class Absorber extends Widget {
  bool get absorbing => _absorbing;
  bool _absorbing;
  bool /*LINT*/ignoringSemantics;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('absorbing', absorbing));
    properties.add(DiagnosticsProperty<bool>('ignoringSemantics', ignoringSemantics));
  }
}
''');
  }

  test_boolField_debugFillProperties_empty() async {
    await resolveTestUnit('''
class Absorber extends Widget {
  bool /*LINT*/ignoringSemantics;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  }
}
''');
    await assertHasFix('''
class Absorber extends Widget {
  bool /*LINT*/ignoringSemantics;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties.add(DiagnosticsProperty<bool>('ignoringSemantics', ignoringSemantics));
  }
}
''');
  }

  test_boolField_debugFillProperties_empty_customParamName() async {
    await resolveTestUnit('''
class Absorber extends Widget {
  bool /*LINT*/ignoringSemantics;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder props) {
  }
}
''');
    await assertHasFix('''
class Absorber extends Widget {
  bool /*LINT*/ignoringSemantics;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder props) {
    props.add(DiagnosticsProperty<bool>('ignoringSemantics', ignoringSemantics));
  }
}
''');
  }

  // todo (pq): tests for no debugFillProperties method
  // todo (pq): tests for getters
  // todo (pq): consider a test for a body w/ no CR
  // todo (pq): support for ColorProperty -- for Color
  // todo (pq): support for EnumProperty -- for any enum class
  // todo (pq): support for IntProperty -- int
  // todo (pq): support for DoubleProperty -- double
  // todo (pq): support for IterableProperty -- any iterable
  // todo (pq): support for StringProperty -- string
  // todo (pq): support for TransformProperty -- Matrix4
  // todo (pq): support for DiagnosticsProperty for any T that doesn't match one of the other cases
}
