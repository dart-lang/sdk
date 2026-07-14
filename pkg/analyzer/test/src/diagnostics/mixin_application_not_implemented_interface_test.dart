// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinApplicationNotImplementedInterfaceTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinApplicationNotImplementedInterfaceTest
    extends PubPackageResolutionTest {
  test_class_hasRecursion() async {
    // https://github.com/dart-lang/sdk/issues/61829
    await resolveTestCodeWithDiagnostics('''
class A {}
abstract class X with Unresolved, M, CycleWithX {}
//             ^
// [diag.recursiveInterfaceInheritance] 'X' can't be a superinterface of itself: CycleWithX, X.
//                    ^^^^^^^^^^
// [diag.mixinOfNonClass] Classes can only mix in mixins and classes.
//                                ^
// [diag.mixinApplicationNotImplementedInterface] 'M' can't be mixed onto 'Object' because 'Object' doesn't implement 'A'.
mixin M on A {}
mixin CycleWithX on X {}
//    ^^^^^^^^^^
// [diag.recursiveInterfaceInheritance] 'CycleWithX' can't be a superinterface of itself: CycleWithX, X.
''');
  }

  test_class_matchingInterface() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A<T> {}
class B {}
mixin M<T> on A<T> {}
class C extends A<int> with M {}
''');
  }

  test_class_matchingInterface_inPreviousMixin() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A<T> {}
class B {}
mixin M1 implements A<B> {}
mixin M2<T> on A<T> {}
class C extends Object with M1, M2 {}
''');
  }

  test_class_matchingInterface_inPreviousMixin_fromAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M1 {}
mixin M2 on M1 {}

class A with M1 {}
augment class A with M2 {}
''');
  }

  test_class_matchingInterface_inPreviousMixin_fromAugmentation_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
class B<T> {}

mixin M1<T> implements B<T> {}
mixin M2<T> on B<T> {}

class A<T> with M1<T> {}
augment class A<T> with M2 {}
''');
  }

  test_class_matchingInterface_inPreviousMixin_fromAugmentation_part() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

mixin M1 {}
mixin M2 on M1 {}

class A with M1 {}
''',
      b: r'''
part of 'a.dart';

augment class A with M2 {}
''',
    });
  }

  test_class_noMatchingInterface() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A<T> {}
class B {}
mixin M<T> on A<T> {}
class C extends Object with M {}
//                          ^
// [diag.mixinApplicationNotImplementedInterface] 'M<dynamic>' can't be mixed onto 'Object' because 'Object' doesn't implement 'A<dynamic>'.
''');
  }

  test_class_noMatchingInterface_fromAugmentation() async {
    await resolveTestCodeWithDiagnostics('''
class B with M {}
//           ^
// [diag.mixinApplicationNotImplementedInterface] 'M' can't be mixed onto 'Object' because 'Object' doesn't implement 'A'.
mixin M {}
class A {}
augment mixin M on A {}
''');
  }

  test_class_noMatchingInterface_fromAugmentation_part() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';

class B with M {}
//           ^
// [diag.mixinApplicationNotImplementedInterface] 'M' can't be mixed onto 'Object' because 'Object' doesn't implement 'A'.
mixin M {}
class A {}
''',
      b: r'''
part of 'a.dart';

augment mixin M on A {}
''',
    });
  }

  test_class_noMatchingInterface_withTypeArguments() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A<T> {}
class B {}
mixin M<T> on A<T> {}
class C extends Object with M<int> {}
//                          ^
// [diag.mixinApplicationNotImplementedInterface] 'M<int>' can't be mixed onto 'Object' because 'Object' doesn't implement 'A<int>'.
''');
  }

  test_class_noMemberErrors() async {
    await resolveTestCodeWithDiagnostics(r'''
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
//               ^
// [diag.mixinApplicationNotImplementedInterface] 'M' can't be mixed onto 'C' because 'C' doesn't implement 'A'.
''');
  }

  test_class_noSuperclassConstraint() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A<T> {}
class B {}
mixin M<T> {}
class C extends Object with M {}
''');
  }

  test_class_recursiveSubtypeCheck() async {
    // See dartbug.com/32353 for a detailed explanation.
    var result = await resolveTestCodeWithDiagnostics('''
class ioDirectory implements ioFileSystemEntity {}

class ioFileSystemEntity {}

abstract class _LocalDirectory
//             ^^^^^^^^^^^^^^^
// [diag.conflictingGenericInterfaces] The class '_LocalDirectory' can't implement both 'ForwardingFileSystemEntity<_LocalDirectory, ioDirectory>' and 'ForwardingFileSystemEntity<Directory, ioDirectory>' because the type arguments are different.
// [diag.unusedElement] The declaration '_LocalDirectory' isn't referenced.
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
''');

    var mixins = result.findElement.class_('_LocalDirectory').mixins;
    assertType(mixins[0], 'ForwardingDirectory<Directory>');
  }

  test_classTypeAlias_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {}

mixin M on A<int> {}

class X = A<double> with M;
//                       ^
// [diag.mixinApplicationNotImplementedInterface] 'M' can't be mixed onto 'A<double>' because 'A<double>' doesn't implement 'A<int>'.
''');
  }

  test_classTypeAlias_noMatchingInterface() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A<T> {}
class B {}
mixin M<T> on A<T> {}
class C = Object with M;
//                    ^
// [diag.mixinApplicationNotImplementedInterface] 'M<dynamic>' can't be mixed onto 'Object' because 'Object' doesn't implement 'A<dynamic>'.
''');
  }

  test_classTypeAlias_notGeneric() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

mixin M on A {}

class X = Object with M;
//                    ^
// [diag.mixinApplicationNotImplementedInterface] 'M' can't be mixed onto 'Object' because 'Object' doesn't implement 'A'.
''');
  }

  test_classTypeAlias_OK_0() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}

class X = Object with M;
''');
  }

  test_classTypeAlias_OK_1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

mixin M on A {}

class X = A with M;
''');
  }

  test_classTypeAlias_OK_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {}

mixin M<T> on A<T> {}

class B<T> implements A<T> {}

class C<T> = B<T> with M<T>;
''');
  }

  test_classTypeAlias_OK_previousMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

mixin M1 implements A {}

mixin M2 on A {}

class X = Object with M1, M2;
''');
  }

  test_classTypeAlias_oneOfTwo() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class C {}

mixin M on A, B {}

class X = C with M;
//               ^
// [diag.mixinApplicationNotImplementedInterface] 'M' can't be mixed onto 'C' because 'C' doesn't implement 'A'.
''');
  }

  test_enum_matchingInterface_inPreviousMixin() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {}

mixin M1 implements A {}

mixin M2 on A {}

enum E with M1, M2 {
  v
}
''');
  }

  test_enum_matchingInterface_inPreviousMixin_fromAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M1 {}
mixin M2 on M1 {}

enum E with M1 {
  v
}
augment enum E with M2 {}
''');
  }

  test_enum_noMatchingInterface() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {}

mixin M on A {}

enum E with M {
//          ^
// [diag.mixinApplicationNotImplementedInterface] 'M' can't be mixed onto 'Enum' because 'Enum' doesn't implement 'A'.
  v
}
''');
  }

  test_enum_noSuperclassConstraint() async {
    await resolveTestCodeWithDiagnostics('''
mixin M {}

enum E with M {
  v;
}
''');
  }

  test_enum_noSuperclassConstraint_augmented() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {}
enum E {v}
augment enum E with M {}
''');
  }
}
