// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddDiagnosticPropertyReferenceTest);
  });
}

@reflectiveTest
class AddDiagnosticPropertyReferenceTest extends BulkFixProcessorTest {
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
