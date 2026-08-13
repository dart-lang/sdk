// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PartOfNonPartTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PartOfNonPartTest extends PubPackageResolutionTest {
  test_noPartOf() async {
    newFile('$testPackageLibPath/l2.dart', '''
library l2;
''');
    await resolveTestCodeWithDiagnostics(r'''
library l1;
part 'l2.dart';
//   ^^^^^^^^^
// [diag.partOfNonPart] The included part 'package:test/l2.dart' must have a part-of directive.
''');
  }

  test_partOf_dotted() async {
    newFile('$testPackageLibPath/a.dart', '''
part of foo.bar;
''');

    // No error reported in the library, only in the part.
    await resolveTestCodeWithDiagnostics(r'''
library foo.bar;
part 'a.dart';
''');
  }

  test_self() async {
    await resolveTestCodeWithDiagnostics(r'''
library lib;
part 'test.dart';
//   ^^^^^^^^^^^
// [diag.partOfNonPart] The included part 'package:test/test.dart' must have a part-of directive.
''');
  }
}
