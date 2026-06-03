// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinsSuperClassTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinsSuperClassTest extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
class B extends A with A {}
//                     ^
// [diag.mixinsSuperClass] 'mixin class A' can't be used in both the 'extends' and 'with' clauses.
''');
  }

  test_class_extendsThenAugmentsWith() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
class B extends A {}
augment class B with A {}
//                   ^
// [diag.mixinsSuperClass] 'mixin class A' can't be used in both the 'extends' and 'with' clauses.
''');
  }

  test_class_extendsThenAugmentsWith_part() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

mixin class A {}
class B extends A {}
''',
      b: r'''
part of 'a.dart';

augment class B with A {}
//                   ^
// [diag.mixinsSuperClass] 'mixin class A' can't be used in both the 'extends' and 'with' clauses.
''',
    });
  }

  test_class_viaTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
typedef B = A;
class C extends A with B {}
//                     ^
// [diag.mixinsSuperClass] 'mixin class A' can't be used in both the 'extends' and 'with' clauses.
''');
  }

  test_class_withThenAugmentsExtends() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
class B with A {}
//           ^
// [diag.mixinsSuperClass] 'mixin class A' can't be used in both the 'extends' and 'with' clauses.
augment class B extends A {}
''');
  }

  test_class_withThenAugmentsExtends_part() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

mixin class A {}
class B with A {}
//           ^
// [diag.mixinsSuperClass] 'mixin class A' can't be used in both the 'extends' and 'with' clauses.
''',
      b: r'''
part of 'a.dart';

augment class B extends A {}
''',
    });
  }

  test_classAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
class B = A with A;
//               ^
// [diag.mixinsSuperClass] 'mixin class A' can't be used in both the 'extends' and 'with' clauses.
''');
  }

  test_classAlias_viaTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
typedef B = A;
class C = A with B;
//               ^
// [diag.mixinsSuperClass] 'mixin class A' can't be used in both the 'extends' and 'with' clauses.
''');
  }
}
