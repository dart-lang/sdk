// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoDefaultSuperConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NoDefaultSuperConstructorTest extends PubPackageResolutionTest {
  test_super_implicit_subclass_explicit_constructor_newHead() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  new named();
}
''');
  }

  test_super_implicit_subclass_explicit_constructor_typeName() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {
  B.named();
}
''');
  }

  test_super_implicit_subclass_explicit_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B() extends A {
  this;
}
''');
  }

  test_super_implicit_subclass_explicit_primaryConstructor_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B() extends A;
''');
  }

  test_super_implicit_subclass_implicit() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}
''');
  }

  test_super_noParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A();
}
class B extends A {
  B();
}
''');
  }

  test_super_optionalNamed_subclass_explicit_constructor_newHead() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? a});
}
class B extends A {
  new named();
}
''');
  }

  test_super_optionalNamed_subclass_explicit_constructor_typeName() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? a});
}
class B extends A {
  B.named();
}
''');
  }

  test_super_optionalNamed_subclass_explicit_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? a});
}
class B() extends A {
  this;
}
''');
  }

  test_super_optionalNamed_subclass_explicit_primaryConstructor_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? a});
}
class B() extends A;
''');
  }

  test_super_optionalNamed_subclass_implicit() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? a});
}
class B extends A {}
''');
  }

  test_super_optionalNamed_subclass_superParameter_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? a});
}
class B extends A {
  B({super.a});
}
''');
  }

  test_super_optionalNamed_subclass_superParameter_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? a});
}
class B({super.a}) extends A {
  this;
}
''');
  }

  test_super_optionalNamed_subclass_superParameter_primaryConstructor_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({int? a});
}
class B({super.a}) extends A;
''');
  }

  test_super_optionalPositional_subclass_explicit_constructor_newHead() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? a]);
}
class B extends A {
  new named();
}
''');
  }

  test_super_optionalPositional_subclass_explicit_constructor_typeName() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? a]);
}
class B extends A {
  B.named();
}
''');
  }

  test_super_optionalPositional_subclass_explicit_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? a]);
}
class B() extends A {
  this;
}
''');
  }

  test_super_optionalPositional_subclass_explicit_primaryConstructor_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? a]);
}
class B() extends A;
''');
  }

  test_super_optionalPositional_subclass_implicit() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? a]);
}
class B extends A {}
''');
  }

  test_super_optionalPositional_subclass_superParameter_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? a]);
}
class B extends A {
  B(super.a);
}
''');
  }

  test_super_optionalPositional_subclass_superParameter_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? a]);
}
class B([super.a]) extends A {
  this;
}
''');
  }

  test_super_optionalPositional_subclass_superParameter_primaryConstructor_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A([int? a]);
}
class B([super.a]) extends A;
''');
  }

  test_super_requiredNamed_subclass_explicit_constructor_newHead() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int? a});
}
class B extends A {
  new named();
//^^^^^^^^^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
}
''');
  }

  test_super_requiredNamed_subclass_explicit_constructor_typeName() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int? a});
}
class B extends A {
  B.named();
//^^^^^^^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
}
''');
  }

  test_super_requiredNamed_subclass_explicit_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int? a});
}
class B() extends A {
  this;
//^^^^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
}
''');
  }

  test_super_requiredNamed_subclass_explicit_primaryConstructor_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int? a});
}
class B() extends A;
//    ^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
''');
  }

  test_super_requiredNamed_subclass_implicit() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int? a});
}
class B extends A {}
//    ^
// [diag.noDefaultSuperConstructorImplicit] The superclass 'A' doesn't have a zero argument constructor.
''');
  }

  test_super_requiredNamed_subclass_superParameter_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int? a});
}
class B extends A {
  B({required super.a});
}
''');
  }

  test_super_requiredNamed_subclass_superParameter_oneLeft_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int? a, required int? b});
}
class B extends A {
  B({required super.a});
//^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
}
''');
  }

  test_super_requiredNamed_subclass_superParameter_oneLeft_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int? a, required int? b});
}
class B({required super.a}) extends A {
  this;
//^^^^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
}
''');
  }

  test_super_requiredNamed_subclass_superParameter_oneLeft_primaryConstructor_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int? a, required int? b});
}
class B({required super.a}) extends A;
//    ^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
''');
  }

  test_super_requiredNamed_subclass_superParameter_optionalNamed_hasDefault_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int? a});
}
class B extends A {
  B({super.a = 0});
}
''');
  }

  test_super_requiredNamed_subclass_superParameter_optionalNamed_hasDefault_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int? a});
}
class B({super.a = 0}) extends A {
  this;
}
''');
  }

  test_super_requiredNamed_subclass_superParameter_optionalNamed_hasDefault_primaryConstructor_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int? a});
}
class B({super.a = 0}) extends A;
''');
  }

  test_super_requiredNamed_subclass_superParameter_optionalNamed_noDefault_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int? a});
}
class B extends A {
  B({super.a});
}
''');
  }

  test_super_requiredNamed_subclass_superParameter_optionalNamed_noDefault_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int? a});
}
class B({super.a}) extends A {
  this;
}
''');
  }

  test_super_requiredNamed_subclass_superParameter_optionalNamed_noDefault_primaryConstructor_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int? a});
}
class B({super.a}) extends A;
''');
  }

  test_super_requiredNamed_subclass_superParameter_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int? a});
}
class B({required super.a}) extends A {
  this;
}
''');
  }

  test_super_requiredNamed_subclass_superParameter_primaryConstructor_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int? a});
}
class B({required super.a}) extends A;
''');
  }

  test_super_requiredPositional_subclass_explicit_constructor_newHead() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p);
}
class B extends A {
  new named();
//^^^^^^^^^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
}
''');
  }

  test_super_requiredPositional_subclass_explicit_constructor_typeName() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p);
}
class B extends A {
  B.named();
//^^^^^^^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
}
''');
  }

  test_super_requiredPositional_subclass_explicit_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p);
}
class B() extends A {
  this;
//^^^^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
}
''');
  }

  test_super_requiredPositional_subclass_explicit_primaryConstructor_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p);
}
class B() extends A;
//    ^
// [diag.implicitSuperInitializerMissingArguments] The implicitly invoked unnamed constructor from 'A' has required parameters.
''');
  }

  test_super_requiredPositional_subclass_external() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p);
}
class B extends A {
  external B();
}
''');
  }

  test_super_requiredPositional_subclass_implicit() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p);
}
class B extends A {}
//    ^
// [diag.noDefaultSuperConstructorImplicit] The superclass 'A' doesn't have a zero argument constructor.
''');
  }

  test_super_requiredPositional_subclass_superParameter_optionalPositional_withDefault_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int? a);
}
class B extends A {
  B([super.a = 0]);
}
''');
  }

  test_super_requiredPositional_subclass_superParameter_optionalPositional_withDefault_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int? a);
}
class B([super.a = 0]) extends A {
  this;
}
''');
  }

  test_super_requiredPositional_subclass_superParameter_optionalPositional_withDefault_primaryConstructor_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int? a);
}
class B([super.a = 0]) extends A;
''');
  }

  test_super_requiredPositional_subclass_superParameter_optionalPositional_withoutDefault_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int? a);
}
class B extends A {
  B([super.a]);
}
''');
  }

  test_super_requiredPositional_subclass_superParameter_optionalPositional_withoutDefault_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int? a);
}
class B([super.a]) extends A {
  this;
}
''');
  }

  test_super_requiredPositional_subclass_superParameter_optionalPositional_withoutDefault_primaryConstructor_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int? a);
}
class B([super.a]) extends A;
''');
  }

  test_super_requiredPositional_subclass_superParameter_requiredPositional_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int? a);
}
class B extends A {
  B(super.a);
}
''');
  }

  test_super_requiredPositional_subclass_superParameter_requiredPositional_primaryConstructor_hasBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int? a);
}
class B(super.a) extends A {
  this;
}
''');
  }

  test_super_requiredPositional_subclass_superParameter_requiredPositional_primaryConstructor_noBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int? a);
}
class B(super.a) extends A;
''');
  }
}
