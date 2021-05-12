// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceCreationTest);
  });
}

@reflectiveTest
class InstanceCreationTest extends PubPackageResolutionTest
    with InstanceCreationTestCases {}

mixin InstanceCreationTestCases on PubPackageResolutionTest {
  test_class_generic_named_inferTypeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named(T t);
}

void f() {
  A.named(0);
}

''');

    var creation = findNode.instanceCreation('A.named(0)');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int>',
      constructorName: 'named',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
    );
  }

  test_class_generic_named_withTypeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named();
}

void f() {
  A<int>.named();
}

''');

    var creation = findNode.instanceCreation('A<int>');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int>',
      constructorName: 'named',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
    );
    assertTypeName(findNode.typeName('int>'), intElement, 'int');
  }

  test_class_generic_unnamed_inferTypeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A(T t);
}

void f() {
  A(0);
}

''');

    var creation = findNode.instanceCreation('A(0)');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int>',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
    );
  }

  test_class_generic_unnamed_withTypeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

void f() {
  A<int>();
}

''');

    var creation = findNode.instanceCreation('A<int>');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int>',
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
    );
    assertTypeName(findNode.typeName('int>'), intElement, 'int');
  }

  test_class_notGeneric() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int a);
}

void f() {
  A(0);
}

''');

    var creation = findNode.instanceCreation('A(0)');
    assertInstanceCreation(creation, findElement.class_('A'), 'A');
  }

  test_demoteType() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A(T t);
}

void f<S>(S s) {
  if (s is int) {
    A(s);
  }
}

''');

    assertType(
      findNode.instanceCreation('A(s)'),
      'A<S>',
    );
  }

  test_error_newWithInvalidTypeParameters_implicitNew_inference_top() async {
    await assertErrorsInCode(r'''
final foo = Map<int>();
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 12, 8),
    ]);

    var creation = findNode.instanceCreation('Map<int>');
    assertInstanceCreation(
      creation,
      mapElement,
      'Map<dynamic, dynamic>',
      expectedConstructorMember: true,
      expectedSubstitution: {'K': 'dynamic', 'V': 'dynamic'},
    );
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_explicitNew() async {
    await assertErrorsInCode(r'''
class Foo<X> {
  Foo.bar();
}

main() {
  new Foo.bar<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 53,
          5),
    ]);

    var creation = findNode.instanceCreation('Foo.bar<int>');
    assertInstanceCreation(
      creation,
      findElement.class_('Foo'),
      'Foo<dynamic>',
      constructorName: 'bar',
      expectedConstructorMember: true,
      expectedSubstitution: {'X': 'dynamic'},
    );
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_explicitNew_prefix() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class Foo<X> {
  Foo.bar();
}
''');
    await assertErrorsInCode('''
import 'a.dart' as p;

main() {
  new p.Foo.bar<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 44,
          3),
    ]);

    // TODO(brianwilkerson) Test this more carefully after we can re-write the
    // AST to reflect the expected structure.
//    var creation = findNode.instanceCreation('Foo.bar<int>');
//    var import = findElement.import('package:test/a.dart');
//    assertInstanceCreation(
//      creation,
//      import.importedLibrary.getType('Foo'),
//      'Foo',
//      constructorName: 'bar',
//      expectedPrefix: import.prefix,
//    );
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_implicitNew() async {
    await assertErrorsInCode(r'''
class Foo<X> {
  Foo.bar();
}

main() {
  Foo.bar<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 49,
          5),
    ]);

    var creation = findNode.instanceCreation('Foo.bar<int>');
    assertInstanceCreation(
      creation,
      findElement.class_('Foo'),
      // TODO(scheglov) Move type arguments
      'Foo<dynamic>',
//      'Foo<int>',
      constructorName: 'bar',
      expectedConstructorMember: true,
      // TODO(scheglov) Move type arguments
      expectedSubstitution: {'X': 'dynamic'},
//      expectedSubstitution: {'X': 'int'},
    );
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_implicitNew_prefix() async {
    newFile('$testPackageLibPath/a.dart', content: '''
class Foo<X> {
  Foo.bar();
}
''');
    await assertErrorsInCode('''
import 'a.dart' as p;

main() {
  p.Foo.bar<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR, 43,
          5),
    ]);

    var import = findElement.import('package:test/a.dart');

    var creation = findNode.instanceCreation('Foo.bar<int>');
    assertInstanceCreation(
      creation,
      import.importedLibrary!.getType('Foo')!,
      'Foo<int>',
      constructorName: 'bar',
      expectedConstructorMember: true,
      expectedPrefix: import.prefix,
      expectedSubstitution: {'X': 'int'},
    );
  }

  test_typeAlias_generic_class_generic_named_infer_all() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A.named(T t);
}

typedef B<U> = A<U>;

void f() {
  B.named(0);
}
''');

    var creation = findNode.instanceCreation('B.named(0)');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int>',
      constructorName: 'named',
      expectedTypeNameElement: findElement.typeAlias('B'),
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
    );
  }

  test_typeAlias_generic_class_generic_named_infer_partial() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  A.named(T t, U u);
}

typedef B<V> = A<V, String>;

void f() {
  B.named(0, '');
}
''');

    var creation = findNode.instanceCreation('B.named(0, ');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int, String>',
      constructorName: 'named',
      expectedTypeNameElement: findElement.typeAlias('B'),
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int', 'U': 'String'},
    );
  }

  test_typeAlias_generic_class_generic_unnamed_infer_all() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A(T t);
}

typedef B<U> = A<U>;

void f() {
  B(0);
}
''');

    var creation = findNode.instanceCreation('B(0)');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int>',
      expectedTypeNameElement: findElement.typeAlias('B'),
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int'},
    );
  }

  test_typeAlias_generic_class_generic_unnamed_infer_partial() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  A(T t, U u);
}

typedef B<V> = A<V, String>;

void f() {
  B(0, '');
}
''');

    var creation = findNode.instanceCreation('B(0, ');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<int, String>',
      expectedTypeNameElement: findElement.typeAlias('B'),
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'int', 'U': 'String'},
    );
  }

  test_typeAlias_notGeneric_class_generic_named_argumentTypeMismatch() async {
    await assertErrorsInCode(r'''
class A<T> {
  A.named(T t);
}

typedef B = A<String>;

void f() {
  B.named(0);
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 77, 1),
    ]);

    var creation = findNode.instanceCreation('B.named(0)');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<String>',
      constructorName: 'named',
      expectedTypeNameElement: findElement.typeAlias('B'),
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'String'},
    );
  }

  test_typeAlias_notGeneric_class_generic_unnamed_argumentTypeMismatch() async {
    await assertErrorsInCode(r'''
class A<T> {
  A(T t);
}

typedef B = A<String>;

void f() {
  B(0);
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 65, 1),
    ]);

    var creation = findNode.instanceCreation('B(0)');
    assertInstanceCreation(
      creation,
      findElement.class_('A'),
      'A<String>',
      expectedTypeNameElement: findElement.typeAlias('B'),
      expectedConstructorMember: true,
      expectedSubstitution: {'T': 'String'},
    );
  }
}
