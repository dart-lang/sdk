// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CommentResolutionTest_PrefixedIdentifier);
    defineReflectiveTests(CommentResolutionTest_PropertyAccess);
    defineReflectiveTests(CommentResolutionTest_SimpleIdentifier);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class CommentResolutionTest_PrefixedIdentifier
    extends PubPackageResolutionTest {
  test_class_constructor_named() async {
    // TODO(srawlins): improve coverage regarding constructors, operators, the
    // 'new' keyword, and members on an extension on a type variable
    // (`extension <T> on T`).
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A.named();
}

/// [A.named]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.named]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      element: <testLibrary>::@class::A::@constructor::named
      staticType: null
    element: <testLibrary>::@class::A::@constructor::named
    staticType: null
''');
  }

  test_class_constructor_unnamedViaNew() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A();
}

/// [A.new]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.new]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::A::@constructor::new
      staticType: null
    element: <testLibrary>::@class::A::@constructor::new
    staticType: null
''');
  }

  test_class_instanceGetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: null
    element: <testLibrary>::@class::A::@getter::foo
    staticType: null
''');
  }

  test_class_instanceGetter_onTypedef() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}
typedef B = A;

/// [B.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('B.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      element: <testLibrary>::@typeAlias::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: null
    element: <testLibrary>::@class::A::@getter::foo
    staticType: null
''');
  }

  test_class_instanceMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@method::foo
      staticType: null
    element: <testLibrary>::@class::A::@method::foo
    staticType: null
''');
  }

  test_class_instanceSetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(int _) {}
}

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@setter::foo
      staticType: null
    element: <testLibrary>::@class::A::@setter::foo
    staticType: null
''');
  }

  test_class_invalid_ambiguousExtension() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
class A {}

extension E1 on A {
  int get foo => 1;
}

extension E2 on A {
  int get foo => 2;
}
''');

    assertResolvedNodeText(result.findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
''');
  }

  test_class_invalid_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
class A {}
''');

    assertResolvedNodeText(result.findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
''');
  }

  test_class_staticGetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static int get foo => 0;
}

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: null
    element: <testLibrary>::@class::A::@getter::foo
    staticType: null
''');
  }

  test_class_staticGetter_onTypedef() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static int get foo => 0;
}

typedef B = A;

/// [B.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('B.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      element: <testLibrary>::@typeAlias::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: null
    element: <testLibrary>::@class::A::@getter::foo
    staticType: null
''');
  }

  test_class_staticMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static void foo() {}
}

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@method::foo
      staticType: null
    element: <testLibrary>::@class::A::@method::foo
    staticType: null
''');
  }

  test_class_staticSetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static set foo(int _) {}
}

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@setter::foo
      staticType: null
    element: <testLibrary>::@class::A::@setter::foo
    staticType: null
''');
  }

  test_docImport_class_constructor_named() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {
  A.named();
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [A.named]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.named]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: package:test/foo.dart::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      element: package:test/foo.dart::@class::A::@constructor::named
      staticType: null
    element: package:test/foo.dart::@class::A::@constructor::named
    staticType: null
''');
  }

  test_docImport_class_constructor_unnamedViaNew() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {
  A();
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [A.new]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.new]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: package:test/foo.dart::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: new
      element: package:test/foo.dart::@class::A::@constructor::new
      staticType: null
    element: package:test/foo.dart::@class::A::@constructor::new
    staticType: null
''');
  }

  test_docImport_class_instanceGetter() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {
  int get foo => 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: package:test/foo.dart::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/foo.dart::@class::A::@getter::foo
      staticType: null
    element: package:test/foo.dart::@class::A::@getter::foo
    staticType: null
''');
  }

  test_docImport_class_instanceMethod() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {
  void foo() {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: package:test/foo.dart::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/foo.dart::@class::A::@method::foo
      staticType: null
    element: package:test/foo.dart::@class::A::@method::foo
    staticType: null
''');
  }

  test_docImport_class_staticGetter() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {
  static int get foo => 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: package:test/foo.dart::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/foo.dart::@class::A::@getter::foo
      staticType: null
    element: package:test/foo.dart::@class::A::@getter::foo
    staticType: null
''');
  }

  test_docImport_class_staticMethod() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {
  static void foo() {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: package:test/foo.dart::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/foo.dart::@class::A::@method::foo
      staticType: null
    element: package:test/foo.dart::@class::A::@method::foo
    staticType: null
''');
  }

  test_docImport_class_staticSetter() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {
  static set foo(int _) {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [A.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: package:test/foo.dart::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/foo.dart::@class::A::@setter::foo
      staticType: null
    element: package:test/foo.dart::@class::A::@setter::foo
    staticType: null
''');
  }

  test_docImport_extension_instanceGetter() async {
    newFile('$testPackageLibPath/foo.dart', r'''
extension E on int {
  int get foo => 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      element: package:test/foo.dart::@extension::E
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/foo.dart::@extension::E::@getter::foo
      staticType: null
    element: package:test/foo.dart::@extension::E::@getter::foo
    staticType: null
''');
  }

  test_docImport_extension_instanceMethod() async {
    newFile('$testPackageLibPath/foo.dart', r'''
extension E on int {
  void foo() {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      element: package:test/foo.dart::@extension::E
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/foo.dart::@extension::E::@method::foo
      staticType: null
    element: package:test/foo.dart::@extension::E::@method::foo
    staticType: null
''');
  }

  test_docImport_extension_instanceSetter() async {
    newFile('$testPackageLibPath/foo.dart', r'''
extension E on int {
  set foo(int _) {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      element: package:test/foo.dart::@extension::E
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/foo.dart::@extension::E::@setter::foo
      staticType: null
    element: package:test/foo.dart::@extension::E::@setter::foo
    staticType: null
''');
  }

  test_docImport_extension_staticGetter() async {
    newFile('$testPackageLibPath/foo.dart', r'''
extension E on int {
  static int get foo => 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      element: package:test/foo.dart::@extension::E
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/foo.dart::@extension::E::@getter::foo
      staticType: null
    element: package:test/foo.dart::@extension::E::@getter::foo
    staticType: null
''');
  }

  test_docImport_extension_staticMethod() async {
    newFile('$testPackageLibPath/foo.dart', r'''
extension E on int {
  static void foo() {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      element: package:test/foo.dart::@extension::E
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/foo.dart::@extension::E::@method::foo
      staticType: null
    element: package:test/foo.dart::@extension::E::@method::foo
    staticType: null
''');
  }

  test_docImport_extension_staticSetter() async {
    newFile('$testPackageLibPath/foo.dart', r'''
extension E on int {
  static set foo(int _) {}
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      element: package:test/foo.dart::@extension::E
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/foo.dart::@extension::E::@setter::foo
      staticType: null
    element: package:test/foo.dart::@extension::E::@setter::foo
    staticType: null
''');
  }

  test_extension_instanceGetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on int {
  int get foo => 0;
}

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      element: <testLibrary>::@extension::E
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::E::@getter::foo
      staticType: null
    element: <testLibrary>::@extension::E::@getter::foo
    staticType: null
''');
  }

  test_extension_instanceMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on int {
  void foo() {}
}

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      element: <testLibrary>::@extension::E
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::E::@method::foo
      staticType: null
    element: <testLibrary>::@extension::E::@method::foo
    staticType: null
''');
  }

  test_extension_instanceSetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on int {
  set foo(int _) {}
}

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      element: <testLibrary>::@extension::E
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::E::@setter::foo
      staticType: null
    element: <testLibrary>::@extension::E::@setter::foo
    staticType: null
''');
  }

  test_extension_staticGetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on int {
  static int get foo => 0;
}

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      element: <testLibrary>::@extension::E
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::E::@getter::foo
      staticType: null
    element: <testLibrary>::@extension::E::@getter::foo
    staticType: null
''');
  }

  test_extension_staticMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on int {
  static void foo() {}
}

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      element: <testLibrary>::@extension::E
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::E::@method::foo
      staticType: null
    element: <testLibrary>::@extension::E::@method::foo
    staticType: null
''');
  }

  test_extension_staticSetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on int {
  static set foo(int _) {}
}

/// [E.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: E
      element: <testLibrary>::@extension::E
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::E::@setter::foo
      staticType: null
    element: <testLibrary>::@extension::E::@setter::foo
    staticType: null
''');
  }
}

@reflectiveTest
class CommentResolutionTest_PropertyAccess extends PubPackageResolutionTest {
  test_class_constructor_named() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  A.named();
}

/// [self.A.named]
void f() {}
''');

    // TODO(srawlins): Set the type of named, and test it, here and below.
    assertResolvedNodeText(result.findNode.commentReference('A.named]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: <testLibrary>::@class::A
        staticType: null
      element: <testLibrary>::@class::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: named
      element: <testLibrary>::@class::A::@constructor::named
      staticType: null
    staticType: null
''');
  }

  test_class_constructor_unnamedViaNew() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  A();
}

/// [self.A.new]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.new]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: <testLibrary>::@class::A
        staticType: null
      element: <testLibrary>::@class::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::A::@constructor::new
      staticType: null
    staticType: null
''');
  }

  test_class_instanceGetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  int get foo => 0;
}

/// [self.A.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: <testLibrary>::@class::A
        staticType: null
      element: <testLibrary>::@class::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: null
    staticType: null
''');
  }

  test_class_instanceGetter_onTypedef() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  int get foo => 0;
}
typedef B = A;

/// [self.B.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('B.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: B
        element: <testLibrary>::@typeAlias::B
        staticType: null
      element: <testLibrary>::@typeAlias::B
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: null
    staticType: null
''');
  }

  test_class_instanceMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  void foo() {}
}

/// [self.A.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: <testLibrary>::@class::A
        staticType: null
      element: <testLibrary>::@class::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@method::foo
      staticType: null
    staticType: null
''');
  }

  test_class_instanceSetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  set foo(int value) {}
}

/// [self.A.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: <testLibrary>::@class::A
        staticType: null
      element: <testLibrary>::@class::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@setter::foo
      staticType: null
    staticType: null
''');
  }

  test_class_staticGetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  static int get foo => 0;
}

/// [self.A.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: <testLibrary>::@class::A
        staticType: null
      element: <testLibrary>::@class::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: null
    staticType: null
''');
  }

  test_class_staticGetter_onTypedef() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  static int get foo => 0;
}
typedef B = A;

/// [self.B.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('B.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: B
        element: <testLibrary>::@typeAlias::B
        staticType: null
      element: <testLibrary>::@typeAlias::B
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: null
    staticType: null
''');
  }

  test_class_staticMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  static void foo() {}
}

/// [self.A.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: <testLibrary>::@class::A
        staticType: null
      element: <testLibrary>::@class::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@method::foo
      staticType: null
    staticType: null
''');
  }

  test_class_staticSetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  static set foo(int value) {}
}

/// [self.A.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: <testLibrary>::@class::A
        staticType: null
      element: <testLibrary>::@class::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@setter::foo
      staticType: null
    staticType: null
''');
  }

  test_extension_instanceGetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension E on int {
  int get foo => 0;
}

/// [self.E.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        element: <testLibrary>::@extension::E
        staticType: null
      element: <testLibrary>::@extension::E
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::E::@getter::foo
      staticType: null
    staticType: null
''');
  }

  test_extension_instanceMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension E on int {
  void foo() {}
}

/// [self.E.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        element: <testLibrary>::@extension::E
        staticType: null
      element: <testLibrary>::@extension::E
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::E::@method::foo
      staticType: null
    staticType: null
''');
  }

  test_extension_instanceSetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension E on int {
  set foo(int value) {}
}

/// [self.E.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        element: <testLibrary>::@extension::E
        staticType: null
      element: <testLibrary>::@extension::E
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::E::@setter::foo
      staticType: null
    staticType: null
''');
  }

  test_extension_staticGetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension E on int {
  static int get foo => 0;
}

/// [self.E.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        element: <testLibrary>::@extension::E
        staticType: null
      element: <testLibrary>::@extension::E
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::E::@getter::foo
      staticType: null
    staticType: null
''');
  }

  test_extension_staticMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension E on int {
  static void foo() {}
}

/// [self.E.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        element: <testLibrary>::@extension::E
        staticType: null
      element: <testLibrary>::@extension::E
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::E::@method::foo
      staticType: null
    staticType: null
''');
  }

  test_extension_staticSetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension E on int {
  static set foo(int value) {}
}

/// [self.E.foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('E.foo]'), r'''
CommentReference
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: E
        element: <testLibrary>::@extension::E
        staticType: null
      element: <testLibrary>::@extension::E
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extension::E::@setter::foo
      staticType: null
    staticType: null
''');
  }
}

@reflectiveTest
class CommentResolutionTest_SimpleIdentifier extends PubPackageResolutionTest {
  test_associatedSetterAndGetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
int get foo => 0;

set foo(int value) {}

/// [foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@getter::foo
    staticType: null
''');
  }

  test_associatedSetterAndGetter_setterInScope() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E1 on int {
  int get foo => 0;
}

/// [foo]
extension E2 on int {
  set foo(int value) {}
}
''');

    assertResolvedNodeText(result.findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E2::@setter::foo
    staticType: null
''');
  }

  test_beforeClass() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
/// [foo]
class A {
  foo() {}
}
''');

    assertResolvedNodeText(result.findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: null
''');
  }

  test_beforeConstructor_fieldParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int p;

  /// [p]
  A(this.p);
}
''');

    assertResolvedNodeText(result.findNode.commentReference('p]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p
    element: <testLibrary>::@class::A::@constructor::new::@formalParameter::p
    staticType: null
''');
  }

  test_beforeConstructor_normalParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  /// [p]
  A(int p);
}''');

    assertResolvedNodeText(result.findNode.commentReference('p]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p
    element: <testLibrary>::@class::A::@constructor::new::@formalParameter::p
    staticType: null
''');
  }

  test_beforeConstructor_superParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p);
}

class B extends A {
  /// [p]
  B(super.p);
}
''');

    assertResolvedNodeText(result.findNode.commentReference('p]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p
    element: <testLibrary>::@class::B::@constructor::new::@formalParameter::p
    staticType: null
''');
  }

  test_beforeEnum() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
/// This is the [Samurai] kind.
enum Samurai {
  /// Use [int].
  WITH_SWORD,
  /// Like [WITH_SWORD], but only without one.
  WITHOUT_SWORD
}''');

    assertResolvedNodeText(result.findNode.commentReference('Samurai]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: Samurai
    element: <testLibrary>::@enum::Samurai
    staticType: null
''');

    assertResolvedNodeText(result.findNode.commentReference('int]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: int
    element: dart:core::@class::int
    staticType: null
''');

    assertResolvedNodeText(result.findNode.commentReference('WITH_SWORD]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: WITH_SWORD
    element: <testLibrary>::@enum::Samurai::@getter::WITH_SWORD
    staticType: null
''');
  }

  test_beforeFunction_blockBody() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
/// [p]
foo(int p) {}
''');

    var node = result.findNode.simple('p]');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: p
  element: <testLibrary>::@function::foo::@formalParameter::p
  staticType: null
''');
  }

  test_beforeFunction_expressionBody() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
/// [p]
foo(int p) => null;
''');

    assertResolvedNodeText(result.findNode.commentReference('p]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p
    element: <testLibrary>::@function::foo::@formalParameter::p
    staticType: null
''');
  }

  test_beforeFunctionTypeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
/// [p]
typedef Foo(int p);
''');

    assertResolvedNodeText(result.findNode.commentReference('p]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p
    element: p@24
    staticType: null
''');
  }

  test_beforeGenericTypeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
/// Can resolve [T], [S], and [p].
typedef Foo<T> = Function<S>(int p);
''');

    assertResolvedNodeText(result.findNode.commentReference('T]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: T
    element: #E0 T
    staticType: null
''');

    assertResolvedNodeText(result.findNode.commentReference('S]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: S
    element: #E0 S
    staticType: null
''');

    assertResolvedNodeText(result.findNode.commentReference('p]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p
    element: p@68
    staticType: null
''');
  }

  test_beforeGetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
/// [int]
get g => null;
''');

    var node = result.findNode.simple('int]');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: int
  element: dart:core::@class::int
  staticType: null
''');
  }

  test_beforeMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    assertResolvedNodeText(result.findNode.commentReference('p1]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p1
    element: <testLibrary>::@class::A::@method::ma::@formalParameter::p1
    staticType: null
''');

    assertResolvedNodeText(result.findNode.commentReference('p2]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p2
    element: <testLibrary>::@class::A::@method::mb::@formalParameter::p2
    staticType: null
''');

    assertResolvedNodeText(result.findNode.commentReference('p3]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p3
    element: <testLibrary>::@class::A::@method::mc::@formalParameter::p3
    staticType: null
''');

    assertResolvedNodeText(result.findNode.commentReference('p4]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p4
    element: <testLibrary>::@class::A::@method::mc::@formalParameter::p4
    staticType: null
''');

    assertResolvedNodeText(result.findNode.commentReference('p5]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p5
    element: <testLibrary>::@class::A::@method::md::@formalParameter::p5
    staticType: null
''');

    assertResolvedNodeText(result.findNode.commentReference('p6]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: p6
    element: <testLibrary>::@class::A::@method::md::@formalParameter::p6
    staticType: null
''');
  }

  test_docImport_associatedSetterAndGetter() async {
    newFile('$testPackageLibPath/foo.dart', r'''
int get foo => 0;

set foo(int value) {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [foo]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    element: package:test/foo.dart::@getter::foo
    staticType: null
''');
  }

  test_docImport_associatedSetterAndGetter_setterInScope() async {
    newFile('$testPackageLibPath/foo.dart', r'''
extension E1 on int {
  int get foo => 0;
}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [foo]
extension E2 on int {
  set foo(int value) {}
}
''');

    assertResolvedNodeText(result.findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E2::@setter::foo
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
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'two.dart';
library;

/// [C]
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('C]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: C
    element: package:test/one.dart::@class::C
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
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [new A] or [new A.named]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
//              ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
main() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A]'), r'''
CommentReference
  newKeyword: new
  expression: SimpleIdentifier
    token: A
    element: package:test/foo.dart::@class::A::@constructor::new
    staticType: null
''');

    assertResolvedNodeText(result.findNode.commentReference('A.named]'), r'''
CommentReference
  newKeyword: new
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: package:test/foo.dart::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      element: package:test/foo.dart::@class::A::@constructor::named
      staticType: null
    element: package:test/foo.dart::@class::A::@constructor::named
    staticType: null
''');
  }

  test_docImport_onEnumValue() async {
    newFile('$testPackageLibPath/foo.dart', r'''
void foo() {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

enum E {
  /// [foo].
  one,
  two;
}
''');

    assertResolvedNodeText(result.findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    element: package:test/foo.dart::@function::foo
    staticType: null
''');
  }

  test_docImport_onExtensionType() async {
    newFile('$testPackageLibPath/foo.dart', r'''
void foo() {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [foo].
extension type ET(int it) {}
''');

    assertResolvedNodeText(result.findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    element: package:test/foo.dart::@function::foo
    staticType: null
''');
  }

  test_docImport_onField() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;
class C {
  /// Text [A].
  int x = 1;
}
''');

    assertResolvedNodeText(result.findNode.commentReference('A]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: A
    element: package:test/foo.dart::@class::A
    staticType: null
''');
  }

  test_docImport_onLibrary() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
///
/// Text [A].
library;
''');

    assertResolvedNodeText(result.findNode.commentReference('A]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: A
    element: package:test/foo.dart::@class::A
    staticType: null
''');
  }

  test_docImport_onTopLevelFunction() async {
    newFile('$testPackageLibPath/foo.dart', r'''
void foo() {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [foo].
void f() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    element: package:test/foo.dart::@function::foo
    staticType: null
''');
  }

  test_docImport_onTopLevelVariable() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;
/// Text [A].
int x = 1;
''');

    assertResolvedNodeText(result.findNode.commentReference('A]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: A
    element: package:test/foo.dart::@class::A
    staticType: null
''');
  }

  test_docImport_onTypedef() async {
    newFile('$testPackageLibPath/foo.dart', r'''
void foo() {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [foo].
typedef T = int;
''');

    assertResolvedNodeText(result.findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    element: package:test/foo.dart::@function::foo
    staticType: null
''');
  }

  test_newKeyword() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A();
  A.named();
}

/// [new A] or [new A.named]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
//              ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
main() {}
''');

    assertResolvedNodeText(result.findNode.commentReference('A]'), r'''
CommentReference
  newKeyword: new
  expression: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::A::@constructor::new
    staticType: null
''');

    assertResolvedNodeText(result.findNode.commentReference('A.named]'), r'''
CommentReference
  newKeyword: new
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      element: <testLibrary>::@class::A::@constructor::named
      staticType: null
    element: <testLibrary>::@class::A::@constructor::named
    staticType: null
''');
  }

  test_onFieldFormalParameter() async {
    // TODO(scheglov): add tests for references to nested formal parameters
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int f;
  A({
    /// [int]
    required this.f,
  });
}
''');

    var node = result.findNode.commentReference('int]');
    assertResolvedNodeText(node, r'''
CommentReference
  expression: SimpleIdentifier
    token: int
    element: dart:core::@class::int
    staticType: null
''');
  }

  test_onFunctionTypedFormalParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(
  /// [int]
  void g(int a),
) {}
''');

    var node = result.findNode.commentReference('int]');
    assertResolvedNodeText(node, r'''
CommentReference
  expression: SimpleIdentifier
    token: int
    element: dart:core::@class::int
    staticType: null
''');
  }

  test_onFunctionTypedFormalParameter_self() async {
    // TODO(scheglov): add tests for references to nested formal parameters
    var result = await resolveTestCodeWithDiagnostics(r'''
/// [bar]
void f(int bar()) {}
''');

    assertResolvedNodeText(result.findNode.commentReference('bar]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: bar
    element: <testLibrary>::@function::f::@formalParameter::bar
    staticType: null
''');
  }

  test_onSimpleFormalParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(
  /// [int]
  int x,
) {}
''');

    var node = result.findNode.commentReference('int]');
    assertResolvedNodeText(node, r'''
CommentReference
  expression: SimpleIdentifier
    token: int
    element: dart:core::@class::int
    staticType: null
''');
  }

  test_onSuperFormalParameter() async {
    // TODO(scheglov): add tests for references to nested formal parameters
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  A({required int f});
}

class B extends A {
  B({
    /// [int]
    required super.f,
  });
}
''');

    var node = result.findNode.commentReference('int]');
    assertResolvedNodeText(node, r'''
CommentReference
  expression: SimpleIdentifier
    token: int
    element: dart:core::@class::int
    staticType: null
''');
  }

  test_setter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    assertResolvedNodeText(result.findNode.commentReference('x] in A'), r'''
CommentReference
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@class::A::@setter::x
    staticType: null
''');

    assertResolvedNodeText(result.findNode.commentReference('x] in B'), r'''
CommentReference
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@class::A::@setter::x
    staticType: null
''');
  }

  test_unqualifiedReferenceToNonLocalStaticMember() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static void foo() {}
}

/// [foo]
class B extends A {}
''');

    assertResolvedNodeText(result.findNode.commentReference('foo]'), r'''
CommentReference
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: null
''');
  }
}
