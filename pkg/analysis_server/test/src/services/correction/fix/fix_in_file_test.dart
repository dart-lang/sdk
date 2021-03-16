// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
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
  Future<void> test_fix_lint_annotate_overrides() async {
    createAnalysisOptionsFile(lints: [LintNames.annotate_overrides]);
    await resolveTestCode('''
class A {
  void a() {}
  void aa() {}
}

class B extends A {
  void a() {}
  void aa() {}
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, '''
class A {
  void a() {}
  void aa() {}
}

class B extends A {
  @override
  void a() {}
  @override
  void aa() {}
}
''');
  }

  Future<void> test_fix_nonLint_isNull() async {
    await resolveTestCode('''
bool f(p, q) {
  return p is Null && q is Null;
}
''');

    var fixes = await getFixesForFirstError();
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

    var fixes = await getFixesForFirstError();
    expect(fixes, isEmpty);
  }
}

class VerificationTests {
  static void defineTests() {
    verify_fixInFileFixesHaveBulkFixTests();
    verify_fixInFileFixKindsHaveMultiFixes();
    verify_fixInFileFixesHaveUniqueBulkFixes();
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

  static void verify_fixInFileFixesHaveUniqueBulkFixes() {
    group('VerificationTests | fixInFileFixesHaveUniqueBulkFixes | lint |', () {
      for (var fixEntry in FixProcessor.lintProducerMap2.entries) {
        var errorCode = fixEntry.key;
        for (var fixInfo in fixEntry.value) {
          if (fixInfo.canBeAppliedToFile) {
            test('$errorCode |', () {
              for (var generator in fixInfo.generators) {
                var g = generator();
                var multiFixKind = g.multiFixKind;
                var fixKind = g.fixKind;
                if (multiFixKind != null) {
                  expect(multiFixKind, isNot(equals(fixKind)));
                }
              }
              expect(fixInfo.canBeBulkApplied, isTrue);
            });
          }
        }
      }
    });
  }

  static void verify_fixInFileFixKindsHaveMultiFixes() {
    // todo (pq): find a better way to verify dynamic producers.
    var dynamicProducerTypes = ['ReplaceWithIsEmpty'];

    group('VerificationTests | fixInFileFixKindsHaveMultiFixes | lint |', () {
      for (var fixEntry in FixProcessor.lintProducerMap2.entries) {
        var errorCode = fixEntry.key;
        for (var fixInfo in fixEntry.value) {
          // At least one generator should have a multiFix.
          if (fixInfo.canBeAppliedToFile) {
            test('$errorCode |', () {
              var generators = fixInfo.generators;
              var foundMultiFix = false;
              for (var i = 0; i < generators.length && !foundMultiFix; ++i) {
                var generator = generators[i]();
                foundMultiFix = generator.multiFixKind != null ||
                    dynamicProducerTypes
                        .contains(generator.runtimeType.toString());
              }
              expect(foundMultiFix, isTrue);
            });
          }
        }
      }
    });
  }
}

/// todo (pq): add negative tests
