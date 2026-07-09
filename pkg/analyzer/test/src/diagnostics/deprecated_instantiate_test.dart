// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedInstantiateTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DeprecatedInstantiateTest extends PubPackageResolutionTest {
  test_annotatedClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.instantiate()
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
var x = Foo();
//      ^^^
// [diag.deprecatedInstantiate] Instantiating 'Foo' is deprecated.
''');
  }

  test_annotatedClass_dotShorthand() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.instantiate()
class Foo {}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
Foo x = .new();
//       ^^^
// [diag.deprecatedInstantiate] Instantiating 'Foo' is deprecated.
''');
  }

  test_annotatedClass_dotShorthand_named() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.instantiate()
class Foo {
  Foo.named();
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
Foo x = .named();
//       ^^^^^
// [diag.deprecatedInstantiate] Instantiating 'Foo' is deprecated.
''');
  }

  test_annotatedClass_redirectedFactory_named() async {
    newFile('$testPackageLibPath/foo.dart', r'''
import 'test.dart';
@Deprecated.instantiate()
class Foo extends Bar {
  Foo.two() : super();
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar {
  Bar();
  factory Bar.one() = Foo.two;
//                    ^^^^^^^
// [diag.deprecatedInstantiate] Instantiating 'Foo' is deprecated.
}
''');
  }

  test_annotatedClass_redirectedFactory_unnamed() async {
    newFile('$testPackageLibPath/foo.dart', r'''
import 'test.dart';
@Deprecated.instantiate()
class Foo extends Bar {
  Foo() : super();
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
class Bar {
  Bar();
  factory Bar.one() = Foo;
//                    ^^^
// [diag.deprecatedInstantiate] Instantiating 'Foo' is deprecated.
}
''');
  }

  test_annotatedClass_superInvocation_named() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.instantiate()
class Foo {
  Foo.named();
}
''');

    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
var x = Foo.new;
//      ^^^^^^^
// [diag.deprecatedInstantiate] Instantiating 'Foo' is deprecated.
''');
  }

  test_annotatedClass_typedef() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.instantiate()
class Foo {}
typedef Foo2 = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
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

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
Foo2 x = .new();
//        ^^^
// [diag.deprecatedInstantiate] Instantiating 'Foo' is deprecated.
''');
  }

  test_annotatedClass_typedef_tearoff() async {
    newFile('$testPackageLibPath/foo.dart', r'''
@Deprecated.instantiate()
class Foo {}
typedef Foo2 = Foo;
''');

    await resolveTestCodeWithDiagnostics(r'''
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

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
var x = Foo();
//      ^^^
// [diag.deprecatedInstantiate] Instantiating 'Foo' is deprecated.
''');
  }

  test_insideLibrary() async {
    await resolveTestCodeWithDiagnostics(r'''
@Deprecated.implement()
class Foo {}
var x = Foo();
''');
  }

  test_noAnnotation() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class Foo {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'foo.dart';
var x = Foo();
''');
  }
}
