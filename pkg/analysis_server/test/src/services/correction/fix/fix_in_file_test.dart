// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    // defineReflectiveTests(MultiFixInFileTest);
    defineReflectiveTests(SingleFixInFileTest);
  });

  VerificationTests.defineTests();
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
  Future<void> test_fix_isNull() async {
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

  Future<void> test_noFixes() async {
    await resolveTestCode('''
bool f(p, q) {
  return p is Null;
}
''');

    var fixes = await getFixes();
    expect(fixes, isEmpty);
  }
}

@reflectiveTest
class VerificationTest extends FixInFileProcessorTest {
  Future<void> test_fixInFileTestsHaveApplyTogetherMessages() async {
    for (var fixInfos in FixProcessor.lintProducerMap2.values) {
      for (var fixInfo in fixInfos) {
        if (fixInfo.canBeBulkApplied) {
          for (var generator in fixInfo.generators) {
            test('', () {
              expect(generator().fixKind.canBeAppliedTogether(), isTrue);
            });
          }
        }
      }
    }
  }
}

class VerificationTests {
  static void defineTests() {
    verify_fixInFileFixesHaveBulkFixTests();
    verify_fixInFileFixKindsHaveApplyTogetherMessages();
  }

  static void verify_fixInFileFixesHaveBulkFixTests() {
    group('VerificationTests | fixInFileFixesHaveBulkFixTests |', () {
      for (var fixEntry in FixProcessor.lintProducerMap2.entries) {
        var errorCode = fixEntry.key;
        for (var fixInfo in fixEntry.value) {
          if (fixInfo.canBeAppliedToFile) {
            test(errorCode, () {
              expect(fixInfo.canBeBulkApplied, isTrue);
            });
          }
        }
      }
    });
  }

  static void verify_fixInFileFixKindsHaveApplyTogetherMessages() {
    group('VerificationTests | fixInFileFixKindsHaveApplyTogetherMessages |',
        () {
      for (var fixEntry in FixProcessor.lintProducerMap2.entries) {
        var errorCode = fixEntry.key;
        for (var fixInfo in fixEntry.value) {
          if (fixInfo.canBeAppliedToFile) {
            var generators = fixInfo.generators;
            for (var i = 0; i < generators.length; ++i) {
              var generator = generators[i];
              var fixKind = generator().fixKind;
              // Cases where fix kinds are determined by context are not verified here.
              if (fixKind != null) {
                test('$errorCode | generator ($i) | ${fixKind.id}', () {
                  expect(fixKind.canBeAppliedTogether(), isTrue);
                });
              }
            }
          }
        }
      }
    });
  }
}

/// todo (pq): add negative tests
