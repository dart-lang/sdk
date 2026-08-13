// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstConstructorWithMixinWithFieldTest);
  });
}

@reflectiveTest
class ConstConstructorWithMixinWithFieldTest extends PubPackageResolutionTest {
  test_constructor_newHead_instance_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  abstract int a;
}

class B with A {
  @override
  int a;
  const new(this.a);
//      ^^^
// [diag.constConstructorWithMixinWithField] This constructor can't be declared 'const' because a mixin adds the instance field: 'A.a'.
}
''');
  }

  test_constructor_newHead_instance_abstract_final() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  abstract final int a;
}

class B with A {
  @override
  final int a;
  const new(this.a);
}
''');
  }

  test_constructor_newHead_instance_final() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  final a = 0;
}

class B extends Object with A {
  const new();
//      ^^^
// [diag.constConstructorWithMixinWithField] This constructor can't be declared 'const' because a mixin adds the instance field: 'A.a'.
}
''');
  }

  test_constructor_newHead_instance_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  int get a => 7;
}

class B extends Object with A {
  const new();
}
''');
  }

  test_constructor_newHead_instance_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  set a(int x) {}
}

class B extends Object with A {
  const new();
}
''');
  }

  test_constructor_newHead_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  var a;
}

class B extends Object with A {
  const new();
//      ^^^
// [diag.constConstructorWithMixinWithField] This constructor can't be declared 'const' because a mixin adds the instance field: 'A.a'.
}
''');
  }

  test_constructor_newHead_multipleInstanceFields() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  var a;
  var b;
}

class B extends Object with A {
  const new();
//      ^^^
// [diag.constConstructorWithMixinWithFields] This constructor can't be declared 'const' because the mixins add the instance fields: 'A.a', 'A.b'.
}
''');
  }

  test_constructor_newHead_noFields() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}

class X extends Object with M {
  const new();
}
''');
  }

  test_constructor_newHead_static() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static final a = 0;
}

class X extends Object with M {
  const new();
}
''');
  }

  test_constructor_typeName_instance_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  abstract int a;
}

class B with A {
  @override
  int a;
  const B(this.a);
//      ^
// [diag.constConstructorWithMixinWithField] This constructor can't be declared 'const' because a mixin adds the instance field: 'A.a'.
}
''');
  }

  test_constructor_typeName_instance_abstract_final() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  abstract final int a;
}

class B with A {
  @override
  final int a;
  const B(this.a);
}
''');
  }

  test_constructor_typeName_instance_final() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  final a = 0;
}

class B extends Object with A {
  const B();
//      ^
// [diag.constConstructorWithMixinWithField] This constructor can't be declared 'const' because a mixin adds the instance field: 'A.a'.
}
''');
  }

  test_constructor_typeName_instance_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  int get a => 7;
}

class B extends Object with A {
  const B();
}
''');
  }

  test_constructor_typeName_instance_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  set a(int x) {}
}

class B extends Object with A {
  const B();
}
''');
  }

  test_constructor_typeName_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  var a;
}

class B extends Object with A {
  const B();
//      ^
// [diag.constConstructorWithMixinWithField] This constructor can't be declared 'const' because a mixin adds the instance field: 'A.a'.
}
''');
  }

  test_constructor_typeName_multipleInstanceFields() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  var a;
  var b;
}

class B extends Object with A {
  const B();
//      ^
// [diag.constConstructorWithMixinWithFields] This constructor can't be declared 'const' because the mixins add the instance fields: 'A.a', 'A.b'.
}
''');
  }

  test_constructor_typeName_noFields() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}

class X extends Object with M {
  const X();
}
''');
  }

  test_constructor_typeName_static() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static final a = 0;
}

class X extends Object with M {
  const X();
}
''');
  }

  test_primaryConstructor_instance_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  abstract int a;
}

class const B(this.a) with A {
//    ^^^^^
// [diag.constConstructorWithMixinWithField] This constructor can't be declared 'const' because a mixin adds the instance field: 'A.a'.
  @override
  final int a;
  set a(int x) {}
}
''');
  }

  test_primaryConstructor_instance_abstract_final() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  abstract final int a;
}

class const B(this.a) with A {
  @override
  final int a;
}
''');
  }

  test_primaryConstructor_instance_final() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  final a = 0;
}

class const B() extends Object with A {}
//    ^^^^^
// [diag.constConstructorWithMixinWithField] This constructor can't be declared 'const' because a mixin adds the instance field: 'A.a'.
''');
  }

  test_primaryConstructor_instance_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  int get a => 7;
}

class const B() extends Object with A {}
''');
  }

  test_primaryConstructor_instance_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  set a(int x) {}
}

class const B() extends Object with A {}
''');
  }

  test_primaryConstructor_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  var a;
}

class const B() extends Object with A {}
//    ^^^^^
// [diag.constConstructorWithMixinWithField] This constructor can't be declared 'const' because a mixin adds the instance field: 'A.a'.
''');
  }

  test_primaryConstructor_multipleInstanceFields() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  var a;
  var b;
}

class const B() extends Object with A {}
//    ^^^^^
// [diag.constConstructorWithMixinWithFields] This constructor can't be declared 'const' because the mixins add the instance fields: 'A.a', 'A.b'.
''');
  }

  test_primaryConstructor_noFields() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}

class const X() extends Object with M {}
''');
  }

  test_primaryConstructor_static() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  static final a = 0;
}

class const X() extends Object with M {}
''');
  }
}
