// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithNullAwareTest);
  });
}

@reflectiveTest
class ReplaceWithNullAwareTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_NULL_AWARE;

  Future<void> test_chain() async {
    await resolveTestCode('''
main(x) {
  x?.a.b.c;
}
''');
    await assertHasFix('''
main(x) {
  x?.a?.b?.c;
}
''');
  }

  Future<void> test_methodInvocation() async {
    await resolveTestCode('''
main(x) {
  x?.a.b();
}
''');
    await assertHasFix('''
main(x) {
  x?.a?.b();
}
''');
  }

  Future<void> test_propertyAccess() async {
    await resolveTestCode('''
main(x) {
  x?.a().b;
}
''');
    await assertHasFix('''
main(x) {
  x?.a()?.b;
}
''');
  }
}
