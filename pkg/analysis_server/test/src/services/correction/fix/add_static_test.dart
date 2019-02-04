// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddStaticTest);
  });
}

@reflectiveTest
class AddStaticTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_STATIC;

  test_multipleFields() async {
    await resolveTestUnit('''
class C {
  const int x = 0, y = 0;
}
''');
    await assertHasFix('''
class C {
  static const int x = 0, y = 0;
}
''');
  }

  test_oneField() async {
    await resolveTestUnit('''
class C {
  const int x = 0;
}
''');
    await assertHasFix('''
class C {
  static const int x = 0;
}
''');
  }
}
