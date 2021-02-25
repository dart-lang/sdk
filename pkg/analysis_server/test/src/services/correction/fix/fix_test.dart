// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FixTest);
  });
}

@reflectiveTest
class FixTest extends FixProcessorTest {
  @override
  FixKind get kind => fail('kind should not be requested');

  Future<void> test_malformedTypeTest() async {
    await resolveTestCode('''
main(p) {
  p i s Null;
}''');
    await assertNoExceptions();
  }
}
