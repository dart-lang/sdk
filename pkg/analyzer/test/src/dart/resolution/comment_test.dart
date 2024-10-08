// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CommentResolutionTest_PrefixedIdentifier);
    defineReflectiveTests(CommentResolutionTest_PropertyAccess);
    defineReflectiveTests(CommentResolutionTest_SimpleIdentifier);
  });
}

@reflectiveTest
class CommentResolutionTest_PrefixedIdentifier
    extends PubPackageResolutionTest {
  test_class_constructor_named() async {
    // TODO(srawlins): improve coverage regarding constructors, operators, the
    // 'new' keyword, and members on an extension on a type variable
    // (`extension <T> on T`).
    await assertNoErrorsInCode('''
class A {
  A.named();
}

/// [A.named]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.named]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: <testLibraryFragment>::@class::A::@constructor::named
      element: <testLibraryFragment>::@class::A::@constructor::named#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@constructor::named
    element: <testLibraryFragment>::@class::A::@constructor::named#element
    staticType: null
''');
  }

  test_class_constructor_unnamedViaNew() async {
    await assertNoErrorsInCode('''
class A {
  A();
}

/// [A.new]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.new]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: new
      staticElement: <testLibraryFragment>::@class::A::@constructor::new
      element: <testLibraryFragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@constructor::new
    element: <testLibraryFragment>::@class::A::@constructor::new#element
    staticType: null
''');
  }

  test_class_instanceGetter() async {
    await assertNoErrorsInCode('''
class A {
  int get foo => 0;
}

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@getter::foo
      element: <testLibraryFragment>::@class::A::@getter::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
    staticType: null
''');
  }

  test_class_instanceMethod() async {
    await assertNoErrorsInCode('''
class A {
  void foo() {}
}

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@method::foo
      element: <testLibraryFragment>::@class::A::@method::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: null
''');
  }

  test_class_instanceSetter() async {
    await assertNoErrorsInCode('''
class A {
  set foo(int _) {}
}

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@setter::foo
      element: <testLibraryFragment>::@class::A::@setter::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@setter::foo
    element: <testLibraryFragment>::@class::A::@setter::foo#element
    staticType: null
''');
  }

  test_class_invalid_ambiguousExtension() async {
    await assertNoErrorsInCode('''
/// [foo]
class A {}

extension E1 on A {
  int get foo => 1;
}

extension E2 on A {
  int get foo => 2;
}
''');

    assertResolvedNodeText(findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    staticElement: <null>
    element: <null>
    staticType: null
''');
  }

  test_class_invalid_unresolved() async {
    await assertNoErrorsInCode('''
/// [foo]
class A {}
''');

    assertResolvedNodeText(findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    staticElement: <null>
    element: <null>
    staticType: null
''');
  }

  test_class_staticGetter() async {
    await assertNoErrorsInCode('''
class A {
  static int get foo => 0;
}

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@getter::foo
      element: <testLibraryFragment>::@class::A::@getter::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
    staticType: null
''');
  }

  test_class_staticMethod() async {
    await assertNoErrorsInCode('''
class A {
  static void foo() {}
}

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@method::foo
      element: <testLibraryFragment>::@class::A::@method::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: null
''');
  }

  test_class_staticSetter() async {
    await assertNoErrorsInCode('''
class A {
  static set foo(int _) {}
}

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@setter::foo
      element: <testLibraryFragment>::@class::A::@setter::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@setter::foo
    element: <testLibraryFragment>::@class::A::@setter::foo#element
    staticType: null
''');
  }

  test_docImport_class_constructor_named() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {
  A.named();
}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

/// [A.named]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.named]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: package:test/foo.dart::<fragment>::@class::A
      element: package:test/foo.dart::<fragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: package:test/foo.dart::<fragment>::@class::A::@constructor::named
      element: package:test/foo.dart::<fragment>::@class::A::@constructor::named#element
      staticType: null
    staticElement: package:test/foo.dart::<fragment>::@class::A::@constructor::named
    element: package:test/foo.dart::<fragment>::@class::A::@constructor::named#element
    staticType: null
''');
  }

  test_docImport_class_constructor_unnamedViaNew() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {
  A();
}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

/// [A.new]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.new]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: package:test/foo.dart::<fragment>::@class::A
      element: package:test/foo.dart::<fragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: new
      staticElement: package:test/foo.dart::<fragment>::@class::A::@constructor::new
      element: package:test/foo.dart::<fragment>::@class::A::@constructor::new#element
      staticType: null
    staticElement: package:test/foo.dart::<fragment>::@class::A::@constructor::new
    element: package:test/foo.dart::<fragment>::@class::A::@constructor::new#element
    staticType: null
''');
  }

  test_docImport_class_instanceGetter() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {
  int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: package:test/foo.dart::<fragment>::@class::A
      element: package:test/foo.dart::<fragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/foo.dart::<fragment>::@class::A::@getter::foo
      element: package:test/foo.dart::<fragment>::@class::A::@getter::foo#element
      staticType: null
    staticElement: package:test/foo.dart::<fragment>::@class::A::@getter::foo
    element: package:test/foo.dart::<fragment>::@class::A::@getter::foo#element
    staticType: null
''');
  }

  test_docImport_class_instanceMethod() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {
  void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: package:test/foo.dart::<fragment>::@class::A
      element: package:test/foo.dart::<fragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/foo.dart::<fragment>::@class::A::@method::foo
      element: package:test/foo.dart::<fragment>::@class::A::@method::foo#element
      staticType: null
    staticElement: package:test/foo.dart::<fragment>::@class::A::@method::foo
    element: package:test/foo.dart::<fragment>::@class::A::@method::foo#element
    staticType: null
''');
  }

  test_docImport_class_staticGetter() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {
  static int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: package:test/foo.dart::<fragment>::@class::A
      element: package:test/foo.dart::<fragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/foo.dart::<fragment>::@class::A::@getter::foo
      element: package:test/foo.dart::<fragment>::@class::A::@getter::foo#element
      staticType: null
    staticElement: package:test/foo.dart::<fragment>::@class::A::@getter::foo
    element: package:test/foo.dart::<fragment>::@class::A::@getter::foo#element
    staticType: null
''');
  }

  test_docImport_class_staticMethod() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {
  static void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: package:test/foo.dart::<fragment>::@class::A
      element: package:test/foo.dart::<fragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/foo.dart::<fragment>::@class::A::@method::foo
      element: package:test/foo.dart::<fragment>::@class::A::@method::foo#element
      staticType: null
    staticElement: package:test/foo.dart::<fragment>::@class::A::@method::foo
    element: package:test/foo.dart::<fragment>::@class::A::@method::foo#element
    staticType: null
''');
  }

  test_docImport_class_staticSetter() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {
  static set foo(int _) {}
}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: package:test/foo.dart::<fragment>::@class::A
      element: package:test/foo.dart::<fragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/foo.dart::<fragment>::@class::A::@setter::foo
      element: package:test/foo.dart::<fragment>::@class::A::@setter::foo#element
      staticType: null
    staticElement: package:test/foo.dart::<fragment>::@class::A::@setter::foo
    element: package:test/foo.dart::<fragment>::@class::A::@setter::foo#element
    staticType: null
''');
  }

  test_docImport_extension_instanceGetter() async {
    newFile('$testPackageLibPath/foo.dart', r'''
extension E on int {
  int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      staticElement: package:test/foo.dart::<fragment>::@extension::E
      element: package:test/foo.dart::<fragment>::@extension::E#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/foo.dart::<fragment>::@extension::E::@getter::foo
      element: package:test/foo.dart::<fragment>::@extension::E::@getter::foo#element
      staticType: null
    staticElement: package:test/foo.dart::<fragment>::@extension::E::@getter::foo
    element: package:test/foo.dart::<fragment>::@extension::E::@getter::foo#element
    staticType: null
''');
  }

  test_docImport_extension_instanceMethod() async {
    newFile('$testPackageLibPath/foo.dart', r'''
extension E on int {
  void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      staticElement: package:test/foo.dart::<fragment>::@extension::E
      element: package:test/foo.dart::<fragment>::@extension::E#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/foo.dart::<fragment>::@extension::E::@method::foo
      element: package:test/foo.dart::<fragment>::@extension::E::@method::foo#element
      staticType: null
    staticElement: package:test/foo.dart::<fragment>::@extension::E::@method::foo
    element: package:test/foo.dart::<fragment>::@extension::E::@method::foo#element
    staticType: null
''');
  }

  test_docImport_extension_instanceSetter() async {
    newFile('$testPackageLibPath/foo.dart', r'''
extension E on int {
  set foo(int _) {}
}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      staticElement: package:test/foo.dart::<fragment>::@extension::E
      element: package:test/foo.dart::<fragment>::@extension::E#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/foo.dart::<fragment>::@extension::E::@setter::foo
      element: package:test/foo.dart::<fragment>::@extension::E::@setter::foo#element
      staticType: null
    staticElement: package:test/foo.dart::<fragment>::@extension::E::@setter::foo
    element: package:test/foo.dart::<fragment>::@extension::E::@setter::foo#element
    staticType: null
''');
  }

  test_docImport_extension_staticGetter() async {
    newFile('$testPackageLibPath/foo.dart', r'''
extension E on int {
  static int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      staticElement: package:test/foo.dart::<fragment>::@extension::E
      element: package:test/foo.dart::<fragment>::@extension::E#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/foo.dart::<fragment>::@extension::E::@getter::foo
      element: package:test/foo.dart::<fragment>::@extension::E::@getter::foo#element
      staticType: null
    staticElement: package:test/foo.dart::<fragment>::@extension::E::@getter::foo
    element: package:test/foo.dart::<fragment>::@extension::E::@getter::foo#element
    staticType: null
''');
  }

  test_docImport_extension_staticMethod() async {
    newFile('$testPackageLibPath/foo.dart', r'''
extension E on int {
  static void foo() {}
}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      staticElement: package:test/foo.dart::<fragment>::@extension::E
      element: package:test/foo.dart::<fragment>::@extension::E#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/foo.dart::<fragment>::@extension::E::@method::foo
      element: package:test/foo.dart::<fragment>::@extension::E::@method::foo#element
      staticType: null
    staticElement: package:test/foo.dart::<fragment>::@extension::E::@method::foo
    element: package:test/foo.dart::<fragment>::@extension::E::@method::foo#element
    staticType: null
''');
  }

  test_docImport_extension_staticSetter() async {
    newFile('$testPackageLibPath/foo.dart', r'''
extension E on int {
  static set foo(int _) {}
}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      staticElement: package:test/foo.dart::<fragment>::@extension::E
      element: package:test/foo.dart::<fragment>::@extension::E#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/foo.dart::<fragment>::@extension::E::@setter::foo
      element: package:test/foo.dart::<fragment>::@extension::E::@setter::foo#element
      staticType: null
    staticElement: package:test/foo.dart::<fragment>::@extension::E::@setter::foo
    element: package:test/foo.dart::<fragment>::@extension::E::@setter::foo#element
    staticType: null
''');
  }

  test_extension_instanceGetter() async {
    await assertNoErrorsInCode('''
extension E on int {
  int get foo => 0;
}

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      staticElement: <testLibraryFragment>::@extension::E
      element: <testLibraryFragment>::@extension::E#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@extension::E::@getter::foo
      element: <testLibraryFragment>::@extension::E::@getter::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@extension::E::@getter::foo
    element: <testLibraryFragment>::@extension::E::@getter::foo#element
    staticType: null
''');
  }

  test_extension_instanceMethod() async {
    await assertNoErrorsInCode('''
extension E on int {
  void foo() {}
}

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      staticElement: <testLibraryFragment>::@extension::E
      element: <testLibraryFragment>::@extension::E#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@extension::E::@method::foo
      element: <testLibraryFragment>::@extension::E::@method::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@extension::E::@method::foo
    element: <testLibraryFragment>::@extension::E::@method::foo#element
    staticType: null
''');
  }

  test_extension_instanceSetter() async {
    await assertNoErrorsInCode('''
extension E on int {
  set foo(int _) {}
}

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      staticElement: <testLibraryFragment>::@extension::E
      element: <testLibraryFragment>::@extension::E#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@extension::E::@setter::foo
      element: <testLibraryFragment>::@extension::E::@setter::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@extension::E::@setter::foo
    element: <testLibraryFragment>::@extension::E::@setter::foo#element
    staticType: null
''');
  }

  test_extension_staticGetter() async {
    await assertNoErrorsInCode('''
extension E on int {
  static int get foo => 0;
}

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      staticElement: <testLibraryFragment>::@extension::E
      element: <testLibraryFragment>::@extension::E#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@extension::E::@getter::foo
      element: <testLibraryFragment>::@extension::E::@getter::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@extension::E::@getter::foo
    element: <testLibraryFragment>::@extension::E::@getter::foo#element
    staticType: null
''');
  }

  test_extension_staticMethod() async {
    await assertNoErrorsInCode('''
extension E on int {
  static void foo() {}
}

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      staticElement: <testLibraryFragment>::@extension::E
      element: <testLibraryFragment>::@extension::E#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@extension::E::@method::foo
      element: <testLibraryFragment>::@extension::E::@method::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@extension::E::@method::foo
    element: <testLibraryFragment>::@extension::E::@method::foo#element
    staticType: null
''');
  }

  test_extension_staticSetter() async {
    await assertNoErrorsInCode('''
extension E on int {
  static set foo(int _) {}
}

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      staticElement: <testLibraryFragment>::@extension::E
      element: <testLibraryFragment>::@extension::E#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@extension::E::@setter::foo
      element: <testLibraryFragment>::@extension::E::@setter::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@extension::E::@setter::foo
    element: <testLibraryFragment>::@extension::E::@setter::foo#element
    staticType: null
''');
  }
}

@reflectiveTest
class CommentResolutionTest_PropertyAccess extends PubPackageResolutionTest {
  test_class_constructor_named() async {
    await assertNoErrorsInCode('''
import '' as self;
class A {
  A.named();
}

/// [self.A.named]
void f() {}
''');

    // TODO(srawlins): Set the type of named, and test it, here and below.
    assertResolvedNodeText(findNode.commentReference('A.named]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        staticElement: <testLibraryFragment>::@prefix::self
        element: <testLibraryFragment>::@prefix2::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        staticElement: <testLibraryFragment>::@class::A
        element: <testLibraryFragment>::@class::A#element
        staticType: null
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: named
      staticElement: <testLibraryFragment>::@class::A::@constructor::named
      element: <testLibraryFragment>::@class::A::@constructor::named#element
      staticType: null
    staticType: null
''');
  }

  test_class_constructor_unnamedViaNew() async {
    await assertNoErrorsInCode('''
import '' as self;
class A {
  A();
}

/// [self.A.new]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.new]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        staticElement: <testLibraryFragment>::@prefix::self
        element: <testLibraryFragment>::@prefix2::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        staticElement: <testLibraryFragment>::@class::A
        element: <testLibraryFragment>::@class::A#element
        staticType: null
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: new
      staticElement: <testLibraryFragment>::@class::A::@constructor::new
      element: <testLibraryFragment>::@class::A::@constructor::new#element
      staticType: null
    staticType: null
''');
  }

  test_class_instanceGetter() async {
    await assertNoErrorsInCode('''
import '' as self;
class A {
  int get foo => 0;
}

/// [self.A.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        staticElement: <testLibraryFragment>::@prefix::self
        element: <testLibraryFragment>::@prefix2::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        staticElement: <testLibraryFragment>::@class::A
        element: <testLibraryFragment>::@class::A#element
        staticType: null
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@getter::foo
      element: <testLibraryFragment>::@class::A::@getter::foo#element
      staticType: null
    staticType: null
''');
  }

  test_class_instanceMethod() async {
    await assertNoErrorsInCode('''
import '' as self;
class A {
  void foo() {}
}

/// [self.A.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        staticElement: <testLibraryFragment>::@prefix::self
        element: <testLibraryFragment>::@prefix2::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        staticElement: <testLibraryFragment>::@class::A
        element: <testLibraryFragment>::@class::A#element
        staticType: null
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@method::foo
      element: <testLibraryFragment>::@class::A::@method::foo#element
      staticType: null
    staticType: null
''');
  }

  test_class_instanceSetter() async {
    await assertNoErrorsInCode('''
import '' as self;
class A {
  set foo(int value) {}
}

/// [self.A.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        staticElement: <testLibraryFragment>::@prefix::self
        element: <testLibraryFragment>::@prefix2::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        staticElement: <testLibraryFragment>::@class::A
        element: <testLibraryFragment>::@class::A#element
        staticType: null
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@setter::foo
      element: <testLibraryFragment>::@class::A::@setter::foo#element
      staticType: null
    staticType: null
''');
  }

  test_class_staticGetter() async {
    await assertNoErrorsInCode('''
import '' as self;
class A {
  static int get foo => 0;
}

/// [self.A.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        staticElement: <testLibraryFragment>::@prefix::self
        element: <testLibraryFragment>::@prefix2::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        staticElement: <testLibraryFragment>::@class::A
        element: <testLibraryFragment>::@class::A#element
        staticType: null
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@getter::foo
      element: <testLibraryFragment>::@class::A::@getter::foo#element
      staticType: null
    staticType: null
''');
  }

  test_class_staticMethod() async {
    await assertNoErrorsInCode('''
import '' as self;
class A {
  static void foo() {}
}

/// [self.A.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        staticElement: <testLibraryFragment>::@prefix::self
        element: <testLibraryFragment>::@prefix2::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        staticElement: <testLibraryFragment>::@class::A
        element: <testLibraryFragment>::@class::A#element
        staticType: null
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@method::foo
      element: <testLibraryFragment>::@class::A::@method::foo#element
      staticType: null
    staticType: null
''');
  }

  test_class_staticSetter() async {
    await assertNoErrorsInCode('''
import '' as self;
class A {
  static set foo(int value) {}
}

/// [self.A.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        staticElement: <testLibraryFragment>::@prefix::self
        element: <testLibraryFragment>::@prefix2::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        staticElement: <testLibraryFragment>::@class::A
        element: <testLibraryFragment>::@class::A#element
        staticType: null
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@setter::foo
      element: <testLibraryFragment>::@class::A::@setter::foo#element
      staticType: null
    staticType: null
''');
  }

  test_extension_instanceGetter() async {
    await assertNoErrorsInCode('''
import '' as self;
extension E on int {
  int get foo => 0;
}

/// [self.E.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        staticElement: <testLibraryFragment>::@prefix::self
        element: <testLibraryFragment>::@prefix2::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: <testLibraryFragment>::@extension::E
        element: <testLibraryFragment>::@extension::E#element
        staticType: null
      staticElement: <testLibraryFragment>::@extension::E
      element: <testLibraryFragment>::@extension::E#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@extension::E::@getter::foo
      element: <testLibraryFragment>::@extension::E::@getter::foo#element
      staticType: null
    staticType: null
''');
  }

  test_extension_instanceMethod() async {
    await assertNoErrorsInCode('''
import '' as self;
extension E on int {
  void foo() {}
}

/// [self.E.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        staticElement: <testLibraryFragment>::@prefix::self
        element: <testLibraryFragment>::@prefix2::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: <testLibraryFragment>::@extension::E
        element: <testLibraryFragment>::@extension::E#element
        staticType: null
      staticElement: <testLibraryFragment>::@extension::E
      element: <testLibraryFragment>::@extension::E#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@extension::E::@method::foo
      element: <testLibraryFragment>::@extension::E::@method::foo#element
      staticType: null
    staticType: null
''');
  }

  test_extension_instanceSetter() async {
    await assertNoErrorsInCode('''
import '' as self;
extension E on int {
  set foo(int value) {}
}

/// [self.E.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        staticElement: <testLibraryFragment>::@prefix::self
        element: <testLibraryFragment>::@prefix2::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: <testLibraryFragment>::@extension::E
        element: <testLibraryFragment>::@extension::E#element
        staticType: null
      staticElement: <testLibraryFragment>::@extension::E
      element: <testLibraryFragment>::@extension::E#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@extension::E::@setter::foo
      element: <testLibraryFragment>::@extension::E::@setter::foo#element
      staticType: null
    staticType: null
''');
  }

  test_extension_staticGetter() async {
    await assertNoErrorsInCode('''
import '' as self;
extension E on int {
  static int get foo => 0;
}

/// [self.E.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        staticElement: <testLibraryFragment>::@prefix::self
        element: <testLibraryFragment>::@prefix2::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: <testLibraryFragment>::@extension::E
        element: <testLibraryFragment>::@extension::E#element
        staticType: null
      staticElement: <testLibraryFragment>::@extension::E
      element: <testLibraryFragment>::@extension::E#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@extension::E::@getter::foo
      element: <testLibraryFragment>::@extension::E::@getter::foo#element
      staticType: null
    staticType: null
''');
  }

  test_extension_staticMethod() async {
    await assertNoErrorsInCode('''
import '' as self;
extension E on int {
  static void foo() {}
}

/// [self.E.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        staticElement: <testLibraryFragment>::@prefix::self
        element: <testLibraryFragment>::@prefix2::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: <testLibraryFragment>::@extension::E
        element: <testLibraryFragment>::@extension::E#element
        staticType: null
      staticElement: <testLibraryFragment>::@extension::E
      element: <testLibraryFragment>::@extension::E#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@extension::E::@method::foo
      element: <testLibraryFragment>::@extension::E::@method::foo#element
      staticType: null
    staticType: null
''');
  }

  test_extension_staticSetter() async {
    await assertNoErrorsInCode('''
import '' as self;
extension E on int {
  static set foo(int value) {}
}

/// [self.E.foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        staticElement: <testLibraryFragment>::@prefix::self
        element: <testLibraryFragment>::@prefix2::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        staticElement: <testLibraryFragment>::@extension::E
        element: <testLibraryFragment>::@extension::E#element
        staticType: null
      staticElement: <testLibraryFragment>::@extension::E
      element: <testLibraryFragment>::@extension::E#element
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@extension::E::@setter::foo
      element: <testLibraryFragment>::@extension::E::@setter::foo#element
      staticType: null
    staticType: null
''');
  }
}

@reflectiveTest
class CommentResolutionTest_SimpleIdentifier extends PubPackageResolutionTest {
  test_associatedSetterAndGetter() async {
    await assertNoErrorsInCode('''
int get foo => 0;

set foo(int value) {}

/// [foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@getter::foo
    element: <testLibraryFragment>::@getter::foo#element
    staticType: null
''');
  }

  test_associatedSetterAndGetter_setterInScope() async {
    await assertNoErrorsInCode('''
extension E1 on int {
  int get foo => 0;
}

/// [foo]
extension E2 on int {
  set foo(int value) {}
}
''');

    assertResolvedNodeText(findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::E2::@setter::foo
    element: <testLibraryFragment>::@extension::E2::@setter::foo#element
    staticType: null
''');
  }

  test_beforeClass() async {
    await assertNoErrorsInCode(r'''
/// [foo]
class A {
  foo() {}
}
''');

    assertResolvedNodeText(findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: null
''');
  }

  test_beforeConstructor_fieldParameter() async {
    await assertNoErrorsInCode(r'''
class A {
  final int p;

  /// [p]
  A(this.p);
}
''');

    assertResolvedNodeText(findNode.commentReference('p]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p
    staticElement: <testLibraryFragment>::@class::A::@constructor::new::@parameter::p
    element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::p#element
    staticType: null
''');
  }

  test_beforeConstructor_normalParameter() async {
    await assertNoErrorsInCode(r'''
class A {
  /// [p]
  A(int p);
}''');

    assertResolvedNodeText(findNode.commentReference('p]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p
    staticElement: <testLibraryFragment>::@class::A::@constructor::new::@parameter::p
    element: <testLibraryFragment>::@class::A::@constructor::new::@parameter::p#element
    staticType: null
''');
  }

  test_beforeConstructor_superParameter() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int p);
}

class B extends A {
  /// [p]
  B(super.p);
}
''');

    assertResolvedNodeText(findNode.commentReference('p]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p
    staticElement: <testLibraryFragment>::@class::B::@constructor::new::@parameter::p
    element: <testLibraryFragment>::@class::B::@constructor::new::@parameter::p#element
    staticType: null
''');
  }

  test_beforeEnum() async {
    await assertNoErrorsInCode(r'''
/// This is the [Samurai] kind.
enum Samurai {
  /// Use [int].
  WITH_SWORD,
  /// Like [WITH_SWORD], but only without one.
  WITHOUT_SWORD
}''');

    assertResolvedNodeText(findNode.commentReference('Samurai]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: Samurai
    staticElement: <testLibraryFragment>::@enum::Samurai
    element: <testLibraryFragment>::@enum::Samurai#element
    staticType: null
''');

    assertResolvedNodeText(findNode.commentReference('int]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: int
    staticElement: dart:core::<fragment>::@class::int
    element: dart:core::<fragment>::@class::int#element
    staticType: null
''');

    assertResolvedNodeText(findNode.commentReference('WITH_SWORD]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: WITH_SWORD
    staticElement: <testLibraryFragment>::@enum::Samurai::@getter::WITH_SWORD
    element: <testLibraryFragment>::@enum::Samurai::@getter::WITH_SWORD#element
    staticType: null
''');
  }

  test_beforeFunction_blockBody() async {
    await assertNoErrorsInCode(r'''
/// [p]
foo(int p) {}
''');

    assertElement(
      findNode.simple('p]'),
      findElement.parameter('p'),
    );
  }

  test_beforeFunction_expressionBody() async {
    await assertNoErrorsInCode(r'''
/// [p]
foo(int p) => null;
''');

    assertResolvedNodeText(findNode.commentReference('p]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p
    staticElement: <testLibraryFragment>::@function::foo::@parameter::p
    element: <testLibraryFragment>::@function::foo::@parameter::p#element
    staticType: null
''');
  }

  test_beforeFunctionTypeAlias() async {
    await assertNoErrorsInCode(r'''
/// [p]
typedef Foo(int p);
''');

    assertResolvedNodeText(findNode.commentReference('p]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p
    staticElement: p@24
    element: p@24#element
    staticType: null
''');
  }

  test_beforeGenericTypeAlias() async {
    await assertNoErrorsInCode(r'''
/// Can resolve [T], [S], and [p].
typedef Foo<T> = Function<S>(int p);
''');

    assertResolvedNodeText(findNode.commentReference('T]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: T
    staticElement: T@47
    element: <not-implemented>
    staticType: null
''');

    assertResolvedNodeText(findNode.commentReference('S]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: S
    staticElement: S@61
    element: <not-implemented>
    staticType: null
''');

    assertResolvedNodeText(findNode.commentReference('p]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p
    staticElement: p@68
    element: p@68#element
    staticType: null
''');
  }

  test_beforeGetter() async {
    await assertNoErrorsInCode(r'''
/// [int]
get g => null;
''');

    assertElement(findNode.simple('int]'), intElement);
  }

  test_beforeMethod() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  /// [p1]
  ma(int p1);

  /// [p2]
  mb(int p2);

  /// [p3] and [p4]
  mc(int p3, p4());

  /// [p5] and [p6]
  md(int p5, {int p6});
}
''');

    assertResolvedNodeText(findNode.commentReference('p1]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p1
    staticElement: <testLibraryFragment>::@class::A::@method::ma::@parameter::p1
    element: <testLibraryFragment>::@class::A::@method::ma::@parameter::p1#element
    staticType: null
''');

    assertResolvedNodeText(findNode.commentReference('p2]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p2
    staticElement: <testLibraryFragment>::@class::A::@method::mb::@parameter::p2
    element: <testLibraryFragment>::@class::A::@method::mb::@parameter::p2#element
    staticType: null
''');

    assertResolvedNodeText(findNode.commentReference('p3]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p3
    staticElement: <testLibraryFragment>::@class::A::@method::mc::@parameter::p3
    element: <testLibraryFragment>::@class::A::@method::mc::@parameter::p3#element
    staticType: null
''');

    assertResolvedNodeText(findNode.commentReference('p4]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p4
    staticElement: <testLibraryFragment>::@class::A::@method::mc::@parameter::p4
    element: <testLibraryFragment>::@class::A::@method::mc::@parameter::p4#element
    staticType: null
''');

    assertResolvedNodeText(findNode.commentReference('p5]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p5
    staticElement: <testLibraryFragment>::@class::A::@method::md::@parameter::p5
    element: <testLibraryFragment>::@class::A::@method::md::@parameter::p5#element
    staticType: null
''');

    assertResolvedNodeText(findNode.commentReference('p6]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p6
    staticElement: <testLibraryFragment>::@class::A::@method::md::@parameter::p6
    element: <testLibraryFragment>::@class::A::@method::md::@parameter::p6#element
    staticType: null
''');
  }

  test_docImport_associatedSetterAndGetter() async {
    newFile('$testPackageLibPath/foo.dart', r'''
int get foo => 0;

set foo(int value) {}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

/// [foo]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    staticElement: package:test/foo.dart::<fragment>::@getter::foo
    element: package:test/foo.dart::<fragment>::@getter::foo#element
    staticType: null
''');
  }

  test_docImport_associatedSetterAndGetter_setterInScope() async {
    newFile('$testPackageLibPath/foo.dart', r'''
extension E1 on int {
  int get foo => 0;
}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

/// [foo]
extension E2 on int {
  set foo(int value) {}
}
''');

    assertResolvedNodeText(findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@extension::E2::@setter::foo
    element: <testLibraryFragment>::@extension::E2::@setter::foo#element
    staticType: null
''');
  }

  test_docImport_fromExport() async {
    newFile('$testPackageLibPath/one.dart', r'''
class C {}
''');
    newFile('$testPackageLibPath/two.dart', r'''
export 'one.dart';
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'two.dart';
library;

/// [C]
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('C]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: C
    staticElement: package:test/one.dart::<fragment>::@class::C
    element: package:test/one.dart::<fragment>::@class::C#element
    staticType: null
''');
  }

  test_docImport_newKeyword() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {
  A();
  A.named();
}
''');
    await assertErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

/// [new A] or [new A.named]
main() {}
''', [
      error(WarningCode.DEPRECATED_NEW_IN_COMMENT_REFERENCE, 42, 3),
      error(WarningCode.DEPRECATED_NEW_IN_COMMENT_REFERENCE, 53, 3),
    ]);

    assertResolvedNodeText(findNode.commentReference('A]'), r'''
CommentReference
  newKeyword: new
  expression: SimpleIdentifier
    token: A
    staticElement: package:test/foo.dart::<fragment>::@class::A::@constructor::new
    element: package:test/foo.dart::<fragment>::@class::A::@constructor::new#element
    staticType: null
''');

    assertResolvedNodeText(findNode.commentReference('A.named]'), r'''
CommentReference
  newKeyword: new
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: package:test/foo.dart::<fragment>::@class::A
      element: package:test/foo.dart::<fragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: package:test/foo.dart::<fragment>::@class::A::@constructor::named
      element: package:test/foo.dart::<fragment>::@class::A::@constructor::named#element
      staticType: null
    staticElement: package:test/foo.dart::<fragment>::@class::A::@constructor::named
    element: package:test/foo.dart::<fragment>::@class::A::@constructor::named#element
    staticType: null
''');
  }

  test_docImport_onEnumValue() async {
    newFile('$testPackageLibPath/foo.dart', r'''
void foo() {}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

enum E {
  /// [foo].
  one,
  two;
}
''');

    assertResolvedNodeText(findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    staticElement: package:test/foo.dart::<fragment>::@function::foo
    element: package:test/foo.dart::<fragment>::@function::foo#element
    staticType: null
''');
  }

  test_docImport_onExtensionType() async {
    newFile('$testPackageLibPath/foo.dart', r'''
void foo() {}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

/// [foo].
extension type ET(int it) {}
''');

    assertResolvedNodeText(findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    staticElement: package:test/foo.dart::<fragment>::@function::foo
    element: package:test/foo.dart::<fragment>::@function::foo#element
    staticType: null
''');
  }

  test_docImport_onField() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;
class C {
  /// Text [A].
  int x = 1;
}
''');

    assertResolvedNodeText(findNode.commentReference('A]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: A
    staticElement: package:test/foo.dart::<fragment>::@class::A
    element: package:test/foo.dart::<fragment>::@class::A#element
    staticType: null
''');
  }

  test_docImport_onLibrary() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
///
/// Text [A].
library;
''');

    assertResolvedNodeText(findNode.commentReference('A]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: A
    staticElement: package:test/foo.dart::<fragment>::@class::A
    element: package:test/foo.dart::<fragment>::@class::A#element
    staticType: null
''');
  }

  test_docImport_onTopLevelFunction() async {
    newFile('$testPackageLibPath/foo.dart', r'''
void foo() {}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

/// [foo].
void f() {}
''');

    assertResolvedNodeText(findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    staticElement: package:test/foo.dart::<fragment>::@function::foo
    element: package:test/foo.dart::<fragment>::@function::foo#element
    staticType: null
''');
  }

  test_docImport_onTopLevelVariable() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;
/// Text [A].
int x = 1;
''');

    assertResolvedNodeText(findNode.commentReference('A]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: A
    staticElement: package:test/foo.dart::<fragment>::@class::A
    element: package:test/foo.dart::<fragment>::@class::A#element
    staticType: null
''');
  }

  test_docImport_onTypedef() async {
    newFile('$testPackageLibPath/foo.dart', r'''
void foo() {}
''');
    await assertNoErrorsInCode(r'''
/// @docImport 'foo.dart';
library;

/// [foo].
typedef T = int;
''');

    assertResolvedNodeText(findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    staticElement: package:test/foo.dart::<fragment>::@function::foo
    element: package:test/foo.dart::<fragment>::@function::foo#element
    staticType: null
''');
  }

  test_newKeyword() async {
    await assertErrorsInCode('''
class A {
  A();
  A.named();
}

/// [new A] or [new A.named]
main() {}
''', [
      error(WarningCode.DEPRECATED_NEW_IN_COMMENT_REFERENCE, 38, 3),
      error(WarningCode.DEPRECATED_NEW_IN_COMMENT_REFERENCE, 49, 3),
    ]);

    assertResolvedNodeText(findNode.commentReference('A]'), r'''
CommentReference
  newKeyword: new
  expression: SimpleIdentifier
    token: A
    staticElement: <testLibraryFragment>::@class::A::@constructor::new
    element: <testLibraryFragment>::@class::A::@constructor::new#element
    staticType: null
''');

    assertResolvedNodeText(findNode.commentReference('A.named]'), r'''
CommentReference
  newKeyword: new
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: <testLibraryFragment>::@class::A::@constructor::named
      element: <testLibraryFragment>::@class::A::@constructor::named#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@constructor::named
    element: <testLibraryFragment>::@class::A::@constructor::named#element
    staticType: null
''');
  }

  test_parameter_functionTyped() async {
    await assertNoErrorsInCode(r'''
/// [bar]
foo(int bar()) {}
''');

    assertResolvedNodeText(findNode.commentReference('bar]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: bar
    staticElement: <testLibraryFragment>::@function::foo::@parameter::bar
    element: <testLibraryFragment>::@function::foo::@parameter::bar#element
    staticType: null
''');
  }

  test_setter() async {
    await assertNoErrorsInCode(r'''
class A {
  /// [x] in A
  mA() {}
  set x(value) {}
}

class B extends A {
  /// [x] in B
  mB() {}
}
''');

    assertResolvedNodeText(findNode.commentReference('x] in A'), r'''
CommentReference
  expression: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@class::A::@setter::x
    element: <testLibraryFragment>::@class::A::@setter::x#element
    staticType: null
''');

    assertResolvedNodeText(findNode.commentReference('x] in B'), r'''
CommentReference
  expression: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@class::A::@setter::x
    element: <testLibraryFragment>::@class::A::@setter::x#element
    staticType: null
''');
  }

  test_unqualifiedReferenceToNonLocalStaticMember() async {
    await assertNoErrorsInCode('''
class A {
  static void foo() {}
}

/// [foo]
class B extends A {}
''');

    assertResolvedNodeText(findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    staticElement: <testLibraryFragment>::@class::A::@method::foo
    element: <testLibraryFragment>::@class::A::@method::foo#element
    staticType: null
''');
  }
}
