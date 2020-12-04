// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddMissingHashOrEqualsTest);
  });
}

@reflectiveTest
class AddMissingHashOrEqualsTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.hash_and_equals;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class C {
  @override
  int get hashCode => 13;
}

class D {
  @override
  bool operator ==(Object other) => false;
}
''');
    await assertHasFix('''
class C {
  @override
  int get hashCode => 13;

  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
}

class D {
  @override
  bool operator ==(Object other) => false;

  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;

}
''');
  }
}
