// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinDeferredClassTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinDeferredClassTest extends PubPackageResolutionTest {
  test_classTypeAlias() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}
''');
    await resolveTestCodeWithDiagnostics('''
library root;
import 'lib1.dart' deferred as a;
class B {}
class C = B with a.A;
//               ^^^
// [diag.mixinDeferredClass] Classes can't mixin deferred classes.
// [diag.classUsedAsMixin] The class 'A' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_enum() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {}
''');
    await resolveTestCodeWithDiagnostics('''
import 'a.dart' deferred as a;
enum E with a.A {
//          ^^^
// [diag.mixinDeferredClass] Classes can't mixin deferred classes.
// [diag.classUsedAsMixin] The class 'A' can't be used as a mixin because it's neither a mixin class nor a mixin.
  v;
}
''');
  }

  test_mixin_deferred_class() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}
''');
    await resolveTestCodeWithDiagnostics('''
library root;
import 'lib1.dart' deferred as a;
class B extends Object with a.A {}
//                          ^^^
// [diag.mixinDeferredClass] Classes can't mixin deferred classes.
// [diag.classUsedAsMixin] The class 'A' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }
}
