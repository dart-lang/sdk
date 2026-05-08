// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertErrorsInCode(
      '''
mixin A {
  abstract int a;
}

class B with A {
  @override
  int a;
  const new(this.a);
}
''',
      [error(diag.constConstructorWithMixinWithField, 77, 3)],
    );
  }

  test_constructor_newHead_instance_abstract_final() async {
    await assertNoErrorsInCode('''
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
    await assertErrorsInCode(
      '''
mixin A {
  final a = 0;
}

class B extends Object with A {
  const new();
}
''',
      [error(diag.constConstructorWithMixinWithField, 68, 3)],
    );
  }

  test_constructor_newHead_instance_getter() async {
    await assertNoErrorsInCode('''
mixin A {
  int get a => 7;
}

class B extends Object with A {
  const new();
}
''');
  }

  test_constructor_newHead_instance_setter() async {
    await assertNoErrorsInCode('''
mixin A {
  set a(int x) {}
}

class B extends Object with A {
  const new();
}
''');
  }

  test_constructor_newHead_instanceField() async {
    await assertErrorsInCode(
      '''
mixin A {
  var a;
}

class B extends Object with A {
  const new();
}
''',
      [error(diag.constConstructorWithMixinWithField, 62, 3)],
    );
  }

  test_constructor_newHead_multipleInstanceFields() async {
    await assertErrorsInCode(
      '''
mixin A {
  var a;
  var b;
}

class B extends Object with A {
  const new();
}
''',
      [error(diag.constConstructorWithMixinWithFields, 71, 3)],
    );
  }

  test_constructor_newHead_noFields() async {
    await assertNoErrorsInCode('''
mixin M {}

class X extends Object with M {
  const new();
}
''');
  }

  test_constructor_newHead_static() async {
    await assertNoErrorsInCode('''
mixin M {
  static final a = 0;
}

class X extends Object with M {
  const new();
}
''');
  }

  test_constructor_typeName_instance_abstract() async {
    await assertErrorsInCode(
      '''
mixin A {
  abstract int a;
}

class B with A {
  @override
  int a;
  const B(this.a);
}
''',
      [error(diag.constConstructorWithMixinWithField, 77, 1)],
    );
  }

  test_constructor_typeName_instance_abstract_final() async {
    await assertNoErrorsInCode('''
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
    await assertErrorsInCode(
      '''
mixin A {
  final a = 0;
}

class B extends Object with A {
  const B();
}
''',
      [error(diag.constConstructorWithMixinWithField, 68, 1)],
    );
  }

  test_constructor_typeName_instance_getter() async {
    await assertNoErrorsInCode('''
mixin A {
  int get a => 7;
}

class B extends Object with A {
  const B();
}
''');
  }

  test_constructor_typeName_instance_setter() async {
    await assertNoErrorsInCode('''
mixin A {
  set a(int x) {}
}

class B extends Object with A {
  const B();
}
''');
  }

  test_constructor_typeName_instanceField() async {
    await assertErrorsInCode(
      '''
mixin A {
  var a;
}

class B extends Object with A {
  const B();
}
''',
      [error(diag.constConstructorWithMixinWithField, 62, 1)],
    );
  }

  test_constructor_typeName_multipleInstanceFields() async {
    await assertErrorsInCode(
      '''
mixin A {
  var a;
  var b;
}

class B extends Object with A {
  const B();
}
''',
      [error(diag.constConstructorWithMixinWithFields, 71, 1)],
    );
  }

  test_constructor_typeName_noFields() async {
    await assertNoErrorsInCode('''
mixin M {}

class X extends Object with M {
  const X();
}
''');
  }

  test_constructor_typeName_static() async {
    await assertNoErrorsInCode('''
mixin M {
  static final a = 0;
}

class X extends Object with M {
  const X();
}
''');
  }

  test_primaryConstructor_instance_abstract() async {
    await assertErrorsInCode(
      '''
mixin A {
  abstract int a;
}

class const B(this.a) with A {
  @override
  final int a;
  set a(int x) {}
}
''',
      [error(diag.constConstructorWithMixinWithField, 37, 5)],
    );
  }

  test_primaryConstructor_instance_abstract_final() async {
    await assertNoErrorsInCode('''
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
    await assertErrorsInCode(
      '''
mixin A {
  final a = 0;
}

class const B() extends Object with A {}
''',
      [error(diag.constConstructorWithMixinWithField, 34, 5)],
    );
  }

  test_primaryConstructor_instance_getter() async {
    await assertNoErrorsInCode('''
mixin A {
  int get a => 7;
}

class const B() extends Object with A {}
''');
  }

  test_primaryConstructor_instance_setter() async {
    await assertNoErrorsInCode('''
mixin A {
  set a(int x) {}
}

class const B() extends Object with A {}
''');
  }

  test_primaryConstructor_instanceField() async {
    await assertErrorsInCode(
      '''
mixin A {
  var a;
}

class const B() extends Object with A {}
''',
      [error(diag.constConstructorWithMixinWithField, 28, 5)],
    );
  }

  test_primaryConstructor_multipleInstanceFields() async {
    await assertErrorsInCode(
      '''
mixin A {
  var a;
  var b;
}

class const B() extends Object with A {}
''',
      [error(diag.constConstructorWithMixinWithFields, 37, 5)],
    );
  }

  test_primaryConstructor_noFields() async {
    await assertNoErrorsInCode('''
mixin M {}

class const X() extends Object with M {}
''');
  }

  test_primaryConstructor_static() async {
    await assertNoErrorsInCode('''
mixin M {
  static final a = 0;
}

class const X() extends Object with M {}
''');
  }
}
