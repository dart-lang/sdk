// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrivateCollisionInMixinApplicationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PrivateCollisionInMixinApplicationTest extends PubPackageResolutionTest {
  test_class_interfaceAndMixin_same() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C implements A {}
class D extends C with A {}
''');
  }

  test_class_interfaceAndMixin_same_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin class A {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C implements A {}
class D extends C with A {}
''');
  }

  test_class_mixinAndMixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C extends Object with A, B {}
//                             ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
''');
  }

  test_class_mixinAndMixin_indirect() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C extends Object with A {}
class D extends C with B {}
//                     ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
''');
  }

  test_class_mixinAndMixin_indirect_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin class A {
  void _foo() {}
}

mixin class B {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C extends Object with A {}
class D extends C with B {}
//                     ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
''');
  }

  test_class_mixinAndMixin_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin class A {
  void _foo() {}
}

mixin class B {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C extends Object with A, B {}
//                             ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
''');
  }

  test_class_mixinAndMixin_withoutExtends() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C with A, B {}
//              ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
''');
  }

  test_class_mixinAndMixin_withoutExtends_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin class A {
  void _foo() {}
}

mixin class B {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C with A, B {}
//              ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
''');
  }

  test_class_staticAndInstanceElement() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  static void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C extends Object with A, B {}
''');
  }

  test_class_staticAndInstanceElement_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin class A {
  static void _foo() {}
}

mixin class B {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C extends Object with A, B {}
''');
  }

  test_class_staticElements() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  static void _foo() {}
}

mixin B {
  static void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C extends Object with A, B {}
''');
  }

  test_class_staticElements_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin class A {
  static void _foo() {}
}

mixin class B {
  static void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C extends Object with A, B {}
''');
  }

  test_class_superclassAndMixin_getter2() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int get _foo => 0;
}

mixin B {
  int get _foo => 0;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C extends A with B {}
//                     ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
''');
  }

  test_class_superclassAndMixin_getter2_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int get _foo => 0;
}

mixin class B {
  int get _foo => 0;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C extends A with B {}
//                     ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
''');
  }

  test_class_superclassAndMixin_method2() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C extends A with B {}
//                     ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
''');
  }

  test_class_superclassAndMixin_method2_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void _foo() {}
}

mixin class B {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C extends A with B {}
//                     ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
''');
  }

  test_class_superclassAndMixin_sameLibrary() async {
    await resolveTestCodeWithDiagnostics('''
mixin A {
  void _foo() {}
//     ^^^^
// [diag.unusedElement] The declaration '_foo' isn't referenced.
}

mixin B {
  void _foo() {}
//     ^^^^
// [diag.unusedElement] The declaration '_foo' isn't referenced.
}

class C extends Object with A, B {}
''');
  }

  test_class_superclassAndMixin_sameLibrary_mixinClass() async {
    await resolveTestCodeWithDiagnostics('''
mixin class A {
  void _foo() {}
//     ^^^^
// [diag.unusedElement] The declaration '_foo' isn't referenced.
}

mixin class B {
  void _foo() {}
//     ^^^^
// [diag.unusedElement] The declaration '_foo' isn't referenced.
}

class C extends Object with A, B {}
''');
  }

  test_class_superclassAndMixin_setter2() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  set _foo(int _) {}
}

mixin B {
  set _foo(int _) {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C extends A with B {}
//                     ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
''');
  }

  test_class_superclassAndMixin_setter2_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  set _foo(int _) {}
}

mixin class B {
  set _foo(int _) {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C extends A with B {}
//                     ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
''');
  }

  test_classTypeAlias_mixinAndMixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C = Object with A, B;
//                       ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
''');
  }

  test_classTypeAlias_mixinAndMixin_indirect() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C = Object with A;
class D = C with B;
//               ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
''');
  }

  test_classTypeAlias_mixinAndMixin_indirect_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin class A {
  void _foo() {}
}

mixin class B {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C = Object with A;
class D = C with B;
//               ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
''');
  }

  test_classTypeAlias_mixinAndMixin_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin class A {
  void _foo() {}
}

mixin class B {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C = Object with A, B;
//                       ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
''');
  }

  test_classTypeAlias_superclassAndMixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C = A with B;
//               ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
''');
  }

  test_classTypeAlias_superclassAndMixin_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void _foo() {}
}

mixin class B {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

class C = A with B;
//               ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
''');
  }

  test_enum_getter_mixinAndMixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  int get _foo => 0;
}

mixin B {
  int get _foo => 0;
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

enum E with A, B {
//             ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
  v
}
''');
  }

  test_enum_method_interfaceAndMixin_same() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

mixin B implements A {}
enum E with B, A {
  v
}
''');
  }

  test_enum_method_mixinAndMixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

enum E with A, B {
//             ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
  v
}
''');
  }

  test_enum_method_staticAndInstanceElement() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  static void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

enum E with A, B {
  v
}
''');
  }

  test_enum_setter_mixinAndMixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  set _foo(int _) {}
}

mixin B {
  set _foo(int _) {}
}
''');

    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

enum E with A, B {
//             ^
// [diag.privateCollisionInMixinApplication] The private name '_foo', defined by 'B', conflicts with the same name defined by 'A'.
  v
}
''');
  }
}
