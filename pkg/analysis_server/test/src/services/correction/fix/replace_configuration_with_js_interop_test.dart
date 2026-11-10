// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceConfigurationWithJsInteropBulkTest);
    defineReflectiveTests(ReplaceConfigurationWithJsInteropMultiTest);
    defineReflectiveTests(ReplaceConfigurationWithJsInteropTest);
  });
}

@reflectiveTest
class ReplaceConfigurationWithJsInteropBulkTest extends BulkFixProcessorTest {
  Future<void> test_singleFile() async {
    await resolveTestCode('''
// ignore_for_file: uri_does_not_exist
import 'src/hw_none.dart'
    if (dart.library.html) 'src/hw_web.dart';
export 'src/hw_none.dart'
    if (dart.library.html) 'src/hw_web.dart';
''');
    await assertHasFix('''
// ignore_for_file: uri_does_not_exist
import 'src/hw_none.dart'
    if (dart.library.js_interop) 'src/hw_web.dart';
export 'src/hw_none.dart'
    if (dart.library.js_interop) 'src/hw_web.dart';
''');
  }
}

@reflectiveTest
class ReplaceConfigurationWithJsInteropMultiTest
    extends FixProcessorForBuiltInDiagnosticTest {
  @override
  FixKind get kind => DartFixKind.replaceConfigurationWithJsInteropMulti;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
// ignore_for_file: uri_does_not_exist
import 'src/hw_none.dart'
    if (dart.library.html) 'src/hw_web.dart';
export 'src/hw_none.dart'
    if (dart.library.html) 'src/hw_web.dart';
''');
    await assertHasFixAllFix(diag.deprecatedWebConfiguration, '''
// ignore_for_file: uri_does_not_exist
import 'src/hw_none.dart'
    if (dart.library.js_interop) 'src/hw_web.dart';
export 'src/hw_none.dart'
    if (dart.library.js_interop) 'src/hw_web.dart';
''');
  }
}

@reflectiveTest
class ReplaceConfigurationWithJsInteropTest
    extends FixProcessorForBuiltInDiagnosticTest {
  @override
  FixKind get kind => DartFixKind.replaceConfigurationWithJsInterop;

  Future<void> test_export() async {
    await resolveTestCode('''
// ignore_for_file: uri_does_not_exist
export 'src/hw_none.dart'
    if (dart.library.html) 'src/hw_web.dart';
''');
    await assertHasFix('''
// ignore_for_file: uri_does_not_exist
export 'src/hw_none.dart'
    if (dart.library.js_interop) 'src/hw_web.dart';
''');
  }

  Future<void> test_import() async {
    await resolveTestCode('''
// ignore_for_file: uri_does_not_exist
import 'src/hw_none.dart'
    if (dart.library.html) 'src/hw_web.dart';
''');
    await assertHasFix('''
// ignore_for_file: uri_does_not_exist
import 'src/hw_none.dart'
    if (dart.library.js_interop) 'src/hw_web.dart';
''');
  }
}
