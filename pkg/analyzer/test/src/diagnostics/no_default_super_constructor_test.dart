// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoDefaultSuperConstructorTest);
  });
}

@reflectiveTest
class NoDefaultSuperConstructorTest extends PubPackageResolutionTest {
  test_super_implicit_subclass_explicit_constructor_newHead() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {
  new named();
}
''');
  }

  test_super_implicit_subclass_explicit_constructor_typeName() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {
  B.named();
}
''');
  }

  test_super_implicit_subclass_explicit_primaryConstructor_hasBody() async {
    await assertNoErrorsInCode(r'''
class A {}
class B() extends A {
  this;
}
''');
  }

  test_super_implicit_subclass_explicit_primaryConstructor_noBody() async {
    await assertNoErrorsInCode(r'''
class A {}
class B() extends A;
''');
  }

  test_super_implicit_subclass_implicit() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}
''');
  }

  test_super_noParameters() async {
    await assertNoErrorsInCode(r'''
class A {
  A();
}
class B extends A {
  B();
}
''');
  }

  test_super_optionalNamed_subclass_explicit_constructor_newHead() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? a});
}
class B extends A {
  new named();
}
''');
  }

  test_super_optionalNamed_subclass_explicit_constructor_typeName() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? a});
}
class B extends A {
  B.named();
}
''');
  }

  test_super_optionalNamed_subclass_explicit_primaryConstructor_hasBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? a});
}
class B() extends A {
  this;
}
''');
  }

  test_super_optionalNamed_subclass_explicit_primaryConstructor_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? a});
}
class B() extends A;
''');
  }

  test_super_optionalNamed_subclass_implicit() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? a});
}
class B extends A {}
''');
  }

  test_super_optionalNamed_subclass_superParameter_constructor() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? a});
}
class B extends A {
  B({super.a});
}
''');
  }

  test_super_optionalNamed_subclass_superParameter_primaryConstructor_hasBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? a});
}
class B({super.a}) extends A {
  this;
}
''');
  }

  test_super_optionalNamed_subclass_superParameter_primaryConstructor_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? a});
}
class B({super.a}) extends A;
''');
  }

  test_super_optionalPositional_subclass_explicit_constructor_newHead() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int? a]);
}
class B extends A {
  new named();
}
''');
  }

  test_super_optionalPositional_subclass_explicit_constructor_typeName() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int? a]);
}
class B extends A {
  B.named();
}
''');
  }

  test_super_optionalPositional_subclass_explicit_primaryConstructor_hasBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int? a]);
}
class B() extends A {
  this;
}
''');
  }

  test_super_optionalPositional_subclass_explicit_primaryConstructor_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int? a]);
}
class B() extends A;
''');
  }

  test_super_optionalPositional_subclass_implicit() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int? a]);
}
class B extends A {}
''');
  }

  test_super_optionalPositional_subclass_superParameter_constructor() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int? a]);
}
class B extends A {
  B(super.a);
}
''');
  }

  test_super_optionalPositional_subclass_superParameter_primaryConstructor_hasBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int? a]);
}
class B([super.a]) extends A {
  this;
}
''');
  }

  test_super_optionalPositional_subclass_superParameter_primaryConstructor_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int? a]);
}
class B([super.a]) extends A;
''');
  }

  test_super_requiredNamed_subclass_explicit_constructor_newHead() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int? a});
}
class B extends A {
  new named();
}
''',
      [error(diag.implicitSuperInitializerMissingArguments, 58, 9)],
    );
  }

  test_super_requiredNamed_subclass_explicit_constructor_typeName() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int? a});
}
class B extends A {
  B.named();
}
''',
      [error(diag.implicitSuperInitializerMissingArguments, 58, 7)],
    );
  }

  test_super_requiredNamed_subclass_explicit_primaryConstructor_hasBody() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int? a});
}
class B() extends A {
  this;
}
''',
      [error(diag.implicitSuperInitializerMissingArguments, 60, 4)],
    );
  }

  test_super_requiredNamed_subclass_explicit_primaryConstructor_noBody() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int? a});
}
class B() extends A;
''',
      [error(diag.implicitSuperInitializerMissingArguments, 42, 1)],
    );
  }

  test_super_requiredNamed_subclass_implicit() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int? a});
}
class B extends A {}
''',
      [error(diag.noDefaultSuperConstructorImplicit, 42, 1)],
    );
  }

  test_super_requiredNamed_subclass_superParameter_constructor() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int? a});
}
class B extends A {
  B({required super.a});
}
''');
  }

  test_super_requiredNamed_subclass_superParameter_oneLeft_constructor() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int? a, required int? b});
}
class B extends A {
  B({required super.a});
}
''',
      [error(diag.implicitSuperInitializerMissingArguments, 75, 1)],
    );
  }

  test_super_requiredNamed_subclass_superParameter_oneLeft_primaryConstructor_hasBody() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int? a, required int? b});
}
class B({required super.a}) extends A {
  this;
}
''',
      [error(diag.implicitSuperInitializerMissingArguments, 95, 4)],
    );
  }

  test_super_requiredNamed_subclass_superParameter_oneLeft_primaryConstructor_noBody() async {
    await assertErrorsInCode(
      r'''
class A {
  A({required int? a, required int? b});
}
class B({required super.a}) extends A;
''',
      [error(diag.implicitSuperInitializerMissingArguments, 59, 1)],
    );
  }

  test_super_requiredNamed_subclass_superParameter_optionalNamed_hasDefault_constructor() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int? a});
}
class B extends A {
  B({super.a = 0});
}
''');
  }

  test_super_requiredNamed_subclass_superParameter_optionalNamed_hasDefault_primaryConstructor_hasBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int? a});
}
class B({super.a = 0}) extends A {
  this;
}
''');
  }

  test_super_requiredNamed_subclass_superParameter_optionalNamed_hasDefault_primaryConstructor_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int? a});
}
class B({super.a = 0}) extends A;
''');
  }

  test_super_requiredNamed_subclass_superParameter_optionalNamed_noDefault_constructor() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int? a});
}
class B extends A {
  B({super.a});
}
''');
  }

  test_super_requiredNamed_subclass_superParameter_optionalNamed_noDefault_primaryConstructor_hasBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int? a});
}
class B({super.a}) extends A {
  this;
}
''');
  }

  test_super_requiredNamed_subclass_superParameter_optionalNamed_noDefault_primaryConstructor_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int? a});
}
class B({super.a}) extends A;
''');
  }

  test_super_requiredNamed_subclass_superParameter_primaryConstructor_hasBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int? a});
}
class B({required super.a}) extends A {
  this;
}
''');
  }

  test_super_requiredNamed_subclass_superParameter_primaryConstructor_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int? a});
}
class B({required super.a}) extends A;
''');
  }

  test_super_requiredPositional_subclass_explicit_constructor_newHead() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p);
}
class B extends A {
  new named();
}
''',
      [error(diag.implicitSuperInitializerMissingArguments, 46, 9)],
    );
  }

  test_super_requiredPositional_subclass_explicit_constructor_typeName() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p);
}
class B extends A {
  B.named();
}
''',
      [error(diag.implicitSuperInitializerMissingArguments, 46, 7)],
    );
  }

  test_super_requiredPositional_subclass_explicit_primaryConstructor_hasBody() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p);
}
class B() extends A {
  this;
}
''',
      [error(diag.implicitSuperInitializerMissingArguments, 48, 4)],
    );
  }

  test_super_requiredPositional_subclass_explicit_primaryConstructor_noBody() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p);
}
class B() extends A;
''',
      [error(diag.implicitSuperInitializerMissingArguments, 30, 1)],
    );
  }

  test_super_requiredPositional_subclass_external() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p);
}
class B extends A {
  external B();
}
''');
  }

  test_super_requiredPositional_subclass_implicit() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int p);
}
class B extends A {}
''',
      [error(diag.noDefaultSuperConstructorImplicit, 30, 1)],
    );
  }

  test_super_requiredPositional_subclass_superParameter_optionalPositional_withDefault_constructor() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int? a);
}
class B extends A {
  B([super.a = 0]);
}
''');
  }

  test_super_requiredPositional_subclass_superParameter_optionalPositional_withDefault_primaryConstructor_hasBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int? a);
}
class B([super.a = 0]) extends A {
  this;
}
''');
  }

  test_super_requiredPositional_subclass_superParameter_optionalPositional_withDefault_primaryConstructor_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int? a);
}
class B([super.a = 0]) extends A;
''');
  }

  test_super_requiredPositional_subclass_superParameter_optionalPositional_withoutDefault_constructor() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int? a);
}
class B extends A {
  B([super.a]);
}
''');
  }

  test_super_requiredPositional_subclass_superParameter_optionalPositional_withoutDefault_primaryConstructor_hasBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int? a);
}
class B([super.a]) extends A {
  this;
}
''');
  }

  test_super_requiredPositional_subclass_superParameter_optionalPositional_withoutDefault_primaryConstructor_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int? a);
}
class B([super.a]) extends A;
''');
  }

  test_super_requiredPositional_subclass_superParameter_requiredPositional_constructor() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int? a);
}
class B extends A {
  B(super.a);
}
''');
  }

  test_super_requiredPositional_subclass_superParameter_requiredPositional_primaryConstructor_hasBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int? a);
}
class B(super.a) extends A {
  this;
}
''');
  }

  test_super_requiredPositional_subclass_superParameter_requiredPositional_primaryConstructor_noBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int? a);
}
class B(super.a) extends A;
''');
  }
}
