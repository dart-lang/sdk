// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedPrefixedNameTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UndefinedPrefixedNameTest extends PubPackageResolutionTest {
  test_getterContext() async {
    newFile('$testPackageLibPath/lib.dart', '');
    await resolveTestCodeWithDiagnostics('''
import 'lib.dart' as p;
f() => p.c;
//       ^
// [diag.undefinedPrefixedName] The name 'c' is being referenced through the prefix 'p', but it isn't defined in any of the libraries imported using that prefix.
''');
  }

  test_new() async {
    newFile('$testPackageLibPath/lib.dart', '');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib.dart' as p;
void f() {
  p.new;
//  ^^^
// [diag.undefinedPrefixedName] The name 'new' is being referenced through the prefix 'p', but it isn't defined in any of the libraries imported using that prefix.
}
''');
  }

  test_setterContext() async {
    newFile('$testPackageLibPath/lib.dart', '');
    await resolveTestCodeWithDiagnostics('''
import 'lib.dart' as p;
f() {
  p.c = 0;
//  ^
// [diag.undefinedPrefixedName] The name 'c' is being referenced through the prefix 'p', but it isn't defined in any of the libraries imported using that prefix.
}
''');
  }
}
