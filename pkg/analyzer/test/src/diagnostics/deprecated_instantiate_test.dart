// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedInstantiateTest);
  });
}

@reflectiveTest
class DeprecatedInstantiateTest extends PubPackageResolutionTest {
  test_annotatedClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.instantiate()
class Foo {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
var x = Foo();
''',
      [error(WarningCode.deprecatedInstantiate, 27, 3)],
    );
  }

  test_annotatedClass_dotShorthand() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.instantiate()
class Foo {}
''');
    await assertErrorsInCode(
      r'''
import 'foo.dart';
Foo x = .new();
''',
      [error(WarningCode.deprecatedInstantiate, 28, 3)],
    );
  }

  test_annotatedClass_dotShorthand_named() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.instantiate()
class Foo {
  Foo.named();
}
''');
    await assertErrorsInCode(
      r'''
import 'foo.dart';
Foo x = .named();
''',
      [error(WarningCode.deprecatedInstantiate, 28, 5)],
    );
  }

  test_annotatedClass_redirectedFactory_named() async {
    newFile('$testPackageLibPath/foo.dart', r'''
import 'test.dart';
@Deprecated.instantiate()
class Foo extends Bar {
  Foo.two() : super();
}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
class Bar {
  Bar();
  factory Bar.one() = Foo.two;
}
''',
      [error(WarningCode.deprecatedInstantiate, 62, 7)],
    );
  }

  test_annotatedClass_redirectedFactory_unnamed() async {
    newFile('$testPackageLibPath/foo.dart', r'''
import 'test.dart';
@Deprecated.instantiate()
class Foo extends Bar {
  Foo() : super();
}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
class Bar {
  Bar();
  factory Bar.one() = Foo;
}
''',
      [error(WarningCode.deprecatedInstantiate, 62, 3)],
    );
  }

  test_annotatedClass_superInvocation_named() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.instantiate()
class Foo {
  Foo.named();
}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Bar extends Foo {
  Bar.named() : super.named();
}
''');
  }

  test_annotatedClass_superInvocation_unnamed() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.instantiate()
class Foo {}
''');
    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Bar extends Foo {
  Bar() : super();
}
''');
  }

  test_annotatedClass_tearoff() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.instantiate()
class Foo {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
var x = Foo.new;
''',
      [error(WarningCode.deprecatedInstantiate, 27, 7)],
    );
  }

  test_annotatedClass_typedef() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.instantiate()
class Foo {}
typedef Foo2 = Foo;
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
var x = Foo2();
''');
  }

  test_annotatedClass_typedef_dotShorthand() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.instantiate()
class Foo {}
typedef Foo2 = Foo;
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
Foo2 x = .new();
''',
      [error(WarningCode.deprecatedInstantiate, 29, 3)],
    );
  }

  test_annotatedClass_typedef_tearoff() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.instantiate()
class Foo {}
typedef Foo2 = Foo;
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
var x = Foo2.new;
''');
  }

  test_annotatedClassTypeAlias() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.instantiate()
class Foo = Object with M;
mixin M {}
''');

    await assertErrorsInCode(
      r'''
import 'foo.dart';
var x = Foo();
''',
      [error(WarningCode.deprecatedInstantiate, 27, 3)],
    );
  }

  test_insideLibrary() async {
    await assertNoErrorsInCode(r'''
@Deprecated.implement()
class Foo {}
var x = Foo();
''');
  }

  test_noAnnotation() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
var x = Foo();
''');
  }
}
