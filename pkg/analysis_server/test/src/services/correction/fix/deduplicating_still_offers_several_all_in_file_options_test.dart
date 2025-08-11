// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/lint_names.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeduplicatingStillOffersSeveralAllInFileOptionsTest);
  });
}

@reflectiveTest
class DeduplicatingStillOffersSeveralAllInFileOptionsTest
    extends FixInFileProcessorTest {
  Future<void> test_File() async {
    createAnalysisOptionsFile(
      lints: [LintNames.prefer_single_quotes, LintNames.unnecessary_new],
    );
    await resolveTestCode(r'''
void f() {
  print("abc");
  print("e" + "f" + "g");
  print(new Foo());
  print(new Foo());
}
class Foo {}
''');

    for (Set<String>? alreadyCalculated in [null, {}]) {
      // Whether we pass a set to deduplicate work or not,
      // we see the same fix kinds.
      var fixes = await getFixesForAllErrors(alreadyCalculated);
      var seenFixKinds = fixes.map((fix) => fix.kind.id).toSet();
      expect(seenFixKinds, {
        'dart.fix.convert.toSingleQuotedString.multi',
        'dart.fix.remove.unnecessaryNew.multi',
      });
    }
  }
}
