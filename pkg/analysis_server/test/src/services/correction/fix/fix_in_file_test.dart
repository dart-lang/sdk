// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    // defineReflectiveTests(MultiFixInFileTest);
    defineReflectiveTests(SingleFixInFileTest);
  });
}

//// todo (pq): update w/ a FixKind that we're sure we want to support as a file fix
// @reflectiveTest
// class MultiFixInFileTest extends FixInFileProcessorTest
//     with WithNullSafetyMixin {
//   Future<void> test_nullable() async {
//     await resolveTestCode('''
// class C {
//   String? s;
//   String? s2;
//   C({String this.s, String this.s2});
// }
// ''');
//
//     var fixes = await getFixes();
//     expect(fixes, hasLength(2));
//
//     var addRequired =
//         fixes.where((f) => f.kind == DartFixKind.ADD_REQUIRED).first;
//     assertProduces(addRequired, '''
// class C {
//   String? s;
//   String? s2;
//   C({required String this.s, required String this.s2});
// }
// ''');
//
//     var makeNullable =
//         fixes.where((f) => f.kind == DartFixKind.MAKE_VARIABLE_NULLABLE).first;
//     assertProduces(makeNullable, '''
// class C {
//   String? s;
//   String? s2;
//   C({String? this.s, String? this.s2});
// }
// ''');
//   }
// }

@reflectiveTest
class SingleFixInFileTest extends FixInFileProcessorTest {
  Future<void> test_isNull() async {
    await resolveTestCode('''
bool f(p, q) {
  return p is Null && q is Null;
}
''');

    var fixes = await getFixes();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, '''
bool f(p, q) {
  return p == null && q == null;
}
''');
  }
}

/// todo (pq): add negative tests
