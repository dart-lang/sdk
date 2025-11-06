// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinApplicationNotImplementedInterfaceTest);
  });
}

@reflectiveTest
class MixinApplicationNotImplementedInterfaceTest
    extends PubPackageResolutionTest {
  test_class_matchingInterface() async {
    await assertNoErrorsInCode('''
abstract class A<T> {}
class B {}
mixin M<T> on A<T> {}
class C extends A<int> with M {}
''');
  }

  test_class_matchingInterface_inPreviousMixin() async {
    await assertNoErrorsInCode('''
abstract class A<T> {}
class B {}
mixin M1 implements A<B> {}
mixin M2<T> on A<T> {}
class C extends Object with M1, M2 {}
''');
  }

  test_class_noMatchingInterface() async {
    await assertErrorsInCode(
      '''
abstract class A<T> {}
class B {}
mixin M<T> on A<T> {}
class C extends Object with M {}
''',
      [
        error(
          CompileTimeErrorCode.mixinApplicationNotImplementedInterface,
          84,
          1,
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_noMatchingInterface_fromAugmentation() async {
    await assertErrorsInCode(
      '''
class B with M {}
mixin M {}
class A {}
augment mixin M on A {}
''',
      [
        error(
          CompileTimeErrorCode.mixinApplicationNotImplementedInterface,
          13,
          1,
        ),
      ],
    );
  }

  test_class_noMatchingInterface_withTypeArguments() async {
    await assertErrorsInCode(
      '''
abstract class A<T> {}
class B {}
mixin M<T> on A<T> {}
class C extends Object with M<int> {}
''',
      [
        error(
          CompileTimeErrorCode.mixinApplicationNotImplementedInterface,
          84,
          1,
        ),
      ],
    );
  }

  test_class_noMemberErrors() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}

mixin M on A {
  void bar() {
    super.foo();
  }
}

class C {
  noSuchMethod(_) {}
}

class X = C with M;
''',
      [
        error(
          CompileTimeErrorCode.mixinApplicationNotImplementedInterface,
          134,
          1,
        ),
      ],
    );
  }

  test_class_noSuperclassConstraint() async {
    await assertNoErrorsInCode('''
abstract class A<T> {}
class B {}
mixin M<T> {}
class C extends Object with M {}
''');
  }

  test_class_recursiveSubtypeCheck() async {
    // See dartbug.com/32353 for a detailed explanation.
    await assertErrorsInCode(
      '''
class ioDirectory implements ioFileSystemEntity {}

class ioFileSystemEntity {}

abstract class _LocalDirectory
    extends _LocalFileSystemEntity<_LocalDirectory, ioDirectory>
    with ForwardingDirectory, DirectoryAddOnsMixin {}

abstract class _LocalFileSystemEntity<T extends FileSystemEntity,
  D extends ioFileSystemEntity> extends ForwardingFileSystemEntity<T, D> {}

abstract class FileSystemEntity implements ioFileSystemEntity {}

abstract class ForwardingFileSystemEntity<T extends FileSystemEntity,
  D extends ioFileSystemEntity> implements FileSystemEntity {}


mixin ForwardingDirectory<T extends Directory>
    on ForwardingFileSystemEntity<T, ioDirectory>
    implements Directory {}

abstract class Directory implements FileSystemEntity, ioDirectory {}

mixin DirectoryAddOnsMixin implements Directory {}
''',
      [
        error(CompileTimeErrorCode.conflictingGenericInterfaces, 96, 15),
        error(WarningCode.unusedElement, 96, 15),
      ],
    );

    var mixins = findElement2.class_('_LocalDirectory').mixins;
    assertType(mixins[0], 'ForwardingDirectory<Directory>');
  }

  test_classTypeAlias_generic() async {
    await assertErrorsInCode(
      r'''
class A<T> {}

mixin M on A<int> {}

class X = A<double> with M;
''',
      [
        error(
          CompileTimeErrorCode.mixinApplicationNotImplementedInterface,
          62,
          1,
        ),
      ],
    );
  }

  test_classTypeAlias_noMatchingInterface() async {
    await assertErrorsInCode(
      '''
abstract class A<T> {}
class B {}
mixin M<T> on A<T> {}
class C = Object with M;
''',
      [
        error(
          CompileTimeErrorCode.mixinApplicationNotImplementedInterface,
          78,
          1,
        ),
      ],
    );
  }

  test_classTypeAlias_notGeneric() async {
    await assertErrorsInCode(
      r'''
class A {}

mixin M on A {}

class X = Object with M;
''',
      [
        error(
          CompileTimeErrorCode.mixinApplicationNotImplementedInterface,
          51,
          1,
        ),
      ],
    );
  }

  test_classTypeAlias_OK_0() async {
    await assertNoErrorsInCode(r'''
mixin M {}

class X = Object with M;
''');
  }

  test_classTypeAlias_OK_1() async {
    await assertNoErrorsInCode(r'''
class A {}

mixin M on A {}

class X = A with M;
''');
  }

  test_classTypeAlias_OK_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

mixin M<T> on A<T> {}

class B<T> implements A<T> {}

class C<T> = B<T> with M<T>;
''');
  }

  test_classTypeAlias_OK_previousMixin() async {
    await assertNoErrorsInCode(r'''
class A {}

mixin M1 implements A {}

mixin M2 on A {}

class X = Object with M1, M2;
''');
  }

  test_classTypeAlias_oneOfTwo() async {
    await assertErrorsInCode(
      r'''
class A {}
class B {}
class C {}

mixin M on A, B {}

class X = C with M;
''',
      [
        error(
          CompileTimeErrorCode.mixinApplicationNotImplementedInterface,
          71,
          1,
        ),
      ],
    );
  }

  test_enum_matchingInterface_inPreviousMixin() async {
    await assertNoErrorsInCode('''
abstract class A {}

mixin M1 implements A {}

mixin M2 on A {}

enum E with M1, M2 {
  v
}
''');
  }

  test_enum_noMatchingInterface() async {
    await assertErrorsInCode(
      '''
abstract class A {}

mixin M on A {}

enum E with M {
  v
}
''',
      [
        error(
          CompileTimeErrorCode.mixinApplicationNotImplementedInterface,
          50,
          1,
        ),
      ],
    );
  }

  test_enum_noSuperclassConstraint() async {
    await assertNoErrorsInCode('''
mixin M {}

enum E with M {
  v;
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_enum_noSuperclassConstraint_augmented() async {
    newFile(testFile.path, r'''
part 'a.dart';
mixin M {}
enum E {v}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
augment enum E with M {}
''');

    await resolveFile2(a);
    assertNoErrorsInResult();
  }
}
