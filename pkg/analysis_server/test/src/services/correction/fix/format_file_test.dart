// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveTests(FormatFileBulkTest);
}

@reflectiveTest
class FormatFileBulkTest extends BulkFixProcessorTest {
  Future<void> test_singleFile() async {
    await parseTestCode('''
void m(int f) {
if (f > 3) {
print('true');
}
else {
print('false');
  }
  }
''');
    await assertFormat('''
void m(int f) {
  if (f > 3) {
    print('true');
  } else {
    print('false');
  }
}
''');
  }
}
