// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CommentResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class CommentResolutionTest extends PubPackageResolutionTest {
  test_associatedSetterAndGetter_setterInScope_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E1 on int {
  int get foo => 0;
}

/// [foo]
extension E2 on int {
  set foo(int value) {}
}
''');

    var node = result.findNode.commentReference('foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@extension::E2::@setter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E2::@setter::foo
    staticType: null
  element: <testLibrary>::@extension::E2::@setter::foo
''');
  }

  test_associatedSetterAndGetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
int get foo => 0;

set foo(int value) {}

/// [foo]
void f() {}
''');

    var node = result.findNode.commentReference('foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@getter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@getter::foo
    staticType: null
  element: <testLibrary>::@getter::foo
''');
  }

  test_beforeClass_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
/// [foo]
class A {
  foo() {}
}
''');

    var node = result.findNode.commentReference('foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@class::A::@method::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: null
  element: <testLibrary>::@class::A::@method::foo
''');
  }

  test_beforeConstructor_fieldParameter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int p;

  /// [p]
  A(this.p);
}
''');

    var node = result.findNode.commentReference('p]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: <testLibrary>::@class::A::@constructor::new::@formalParameter::p
  expression: SimpleIdentifier
    token: p
    element: <testLibrary>::@class::A::@constructor::new::@formalParameter::p
    staticType: null
  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::p
''');
  }

  test_beforeConstructor_normalParameter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  /// [p]
  A(int p);
}''');

    var node = result.findNode.commentReference('p]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: <testLibrary>::@class::A::@constructor::new::@formalParameter::p
  expression: SimpleIdentifier
    token: p
    element: <testLibrary>::@class::A::@constructor::new::@formalParameter::p
    staticType: null
  element: <testLibrary>::@class::A::@constructor::new::@formalParameter::p
''');
  }

  test_beforeConstructor_superParameter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int p);
}

class B extends A {
  /// [p]
  B(super.p);
}
''');

    var node = result.findNode.commentReference('p]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: <testLibrary>::@class::B::@constructor::new::@formalParameter::p
  expression: SimpleIdentifier
    token: p
    element: <testLibrary>::@class::B::@constructor::new::@formalParameter::p
    staticType: null
  element: <testLibrary>::@class::B::@constructor::new::@formalParameter::p
''');
  }

  test_beforeEnum_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
/// This is the [Samurai] kind.
enum Samurai {
  /// Use [int].
  WITH_SWORD,
  /// Like [WITH_SWORD], but only without one.
  WITHOUT_SWORD
}''');

    var node1 = result.findNode.commentReference('Samurai]');
    assertResolvedNodeText(node1, r'''
CommentReference
  components
    CommentReferenceComponent
      name: Samurai
      element: <testLibrary>::@enum::Samurai
  expression: SimpleIdentifier
    token: Samurai
    element: <testLibrary>::@enum::Samurai
    staticType: null
  element: <testLibrary>::@enum::Samurai
''');

    var node2 = result.findNode.commentReference('int]');
    assertResolvedNodeText(node2, r'''
CommentReference
  components
    CommentReferenceComponent
      name: int
      element: dart:core::@class::int
  expression: SimpleIdentifier
    token: int
    element: dart:core::@class::int
    staticType: null
  element: dart:core::@class::int
''');

    var node3 = result.findNode.commentReference('WITH_SWORD]');
    assertResolvedNodeText(node3, r'''
CommentReference
  components
    CommentReferenceComponent
      name: WITH_SWORD
      element: <testLibrary>::@enum::Samurai::@getter::WITH_SWORD
  expression: SimpleIdentifier
    token: WITH_SWORD
    element: <testLibrary>::@enum::Samurai::@getter::WITH_SWORD
    staticType: null
  element: <testLibrary>::@enum::Samurai::@getter::WITH_SWORD
''');
  }

  test_beforeFunction_blockBody_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
/// [p]
foo(int p) {}
''');

    var node = result.findNode.commentReference('p]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: <testLibrary>::@function::foo::@formalParameter::p
  expression: SimpleIdentifier
    token: p
    element: <testLibrary>::@function::foo::@formalParameter::p
    staticType: null
  element: <testLibrary>::@function::foo::@formalParameter::p
''');
  }

  test_beforeFunction_expressionBody_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
/// [p]
foo(int p) => null;
''');

    var node = result.findNode.commentReference('p]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: <testLibrary>::@function::foo::@formalParameter::p
  expression: SimpleIdentifier
    token: p
    element: <testLibrary>::@function::foo::@formalParameter::p
    staticType: null
  element: <testLibrary>::@function::foo::@formalParameter::p
''');
  }

  test_beforeFunctionTypeAlias_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
/// [p]
typedef Foo(int p);
''');

    var node = result.findNode.commentReference('p]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: p@24
  expression: SimpleIdentifier
    token: p
    element: p@24
    staticType: null
  element: p@24
''');
  }

  test_beforeGenericTypeAlias_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
/// Can resolve [T], [S], and [p].
typedef Foo<T> = Function<S>(int p);
''');

    var node1 = result.findNode.commentReference('T]');
    assertResolvedNodeText(node1, r'''
CommentReference
  components
    CommentReferenceComponent
      name: T
      element: #E0 T
  expression: SimpleIdentifier
    token: T
    element: #E0 T
    staticType: null
  element: #E0 T
''');

    var node2 = result.findNode.commentReference('S]');
    assertResolvedNodeText(node2, r'''
CommentReference
  components
    CommentReferenceComponent
      name: S
      element: #E0 S
  expression: SimpleIdentifier
    token: S
    element: #E0 S
    staticType: null
  element: #E0 S
''');

    var node3 = result.findNode.commentReference('p]');
    assertResolvedNodeText(node3, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: p@68
  expression: SimpleIdentifier
    token: p
    element: p@68
    staticType: null
  element: p@68
''');
  }

  test_beforeGetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
/// [int]
get g => null;
''');

    var node = result.findNode.commentReference('int]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: int
      element: dart:core::@class::int
  expression: SimpleIdentifier
    token: int
    element: dart:core::@class::int
    staticType: null
  element: dart:core::@class::int
''');
  }

  test_beforeMethod_unqualified() async {
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

    var node1 = result.findNode.commentReference('p1]');
    assertResolvedNodeText(node1, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p1
      element: <testLibrary>::@class::A::@method::ma::@formalParameter::p1
  expression: SimpleIdentifier
    token: p1
    element: <testLibrary>::@class::A::@method::ma::@formalParameter::p1
    staticType: null
  element: <testLibrary>::@class::A::@method::ma::@formalParameter::p1
''');

    var node2 = result.findNode.commentReference('p2]');
    assertResolvedNodeText(node2, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p2
      element: <testLibrary>::@class::A::@method::mb::@formalParameter::p2
  expression: SimpleIdentifier
    token: p2
    element: <testLibrary>::@class::A::@method::mb::@formalParameter::p2
    staticType: null
  element: <testLibrary>::@class::A::@method::mb::@formalParameter::p2
''');

    var node3 = result.findNode.commentReference('p3]');
    assertResolvedNodeText(node3, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p3
      element: <testLibrary>::@class::A::@method::mc::@formalParameter::p3
  expression: SimpleIdentifier
    token: p3
    element: <testLibrary>::@class::A::@method::mc::@formalParameter::p3
    staticType: null
  element: <testLibrary>::@class::A::@method::mc::@formalParameter::p3
''');

    var node4 = result.findNode.commentReference('p4]');
    assertResolvedNodeText(node4, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p4
      element: <testLibrary>::@class::A::@method::mc::@formalParameter::p4
  expression: SimpleIdentifier
    token: p4
    element: <testLibrary>::@class::A::@method::mc::@formalParameter::p4
    staticType: null
  element: <testLibrary>::@class::A::@method::mc::@formalParameter::p4
''');

    var node5 = result.findNode.commentReference('p5]');
    assertResolvedNodeText(node5, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p5
      element: <testLibrary>::@class::A::@method::md::@formalParameter::p5
  expression: SimpleIdentifier
    token: p5
    element: <testLibrary>::@class::A::@method::md::@formalParameter::p5
    staticType: null
  element: <testLibrary>::@class::A::@method::md::@formalParameter::p5
''');

    var node6 = result.findNode.commentReference('p6]');
    assertResolvedNodeText(node6, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p6
      element: <testLibrary>::@class::A::@method::md::@formalParameter::p6
  expression: SimpleIdentifier
    token: p6
    element: <testLibrary>::@class::A::@method::md::@formalParameter::p6
    staticType: null
  element: <testLibrary>::@class::A::@method::md::@formalParameter::p6
''');
  }

  test_class_constructor_named_qualified() async {
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

    var node = result.findNode.commentReference('A.named]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: named
      element: <testLibrary>::@class::A::@constructor::named
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
  element: <testLibrary>::@class::A::@constructor::named
''');
  }

  test_class_constructor_named_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  A.named();
}

/// [self.A.named]
void f() {}
''');

    // TODO(srawlins): Set the type of named, and test it, here and below.
    var node = result.findNode.commentReference('A.named]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: named
      element: <testLibrary>::@class::A::@constructor::named
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
  element: <testLibrary>::@class::A::@constructor::named
''');
  }

  test_class_constructor_named_qualified_importPrefix_otherLibrary() async {
    newFile('$testPackageLibPath/a.dart', 'class A { A.named(); }');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;

/// [p.A.named]
void f() {}
''');
    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: <testLibraryFragment>::@prefix::p
    CommentReferenceComponent
      period: .
      name: A
      element: package:test/a.dart::@class::A
    CommentReferenceComponent
      period: .
      name: named
      element: package:test/a.dart::@class::A::@constructor::named
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        element: <testLibraryFragment>::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: package:test/a.dart::@class::A
        staticType: null
      element: package:test/a.dart::@class::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: named
      element: package:test/a.dart::@class::A::@constructor::named
      staticType: null
    staticType: null
  element: package:test/a.dart::@class::A::@constructor::named
''');
  }

  test_class_constructor_named_qualified_importPrefix_preferredOverInheritedGetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as p;
class A {
  int get foo => 0;
}
class B extends A {
  B.foo();
}

/// [p.B.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: <testLibraryFragment>::@prefix::p
    CommentReferenceComponent
      period: .
      name: B
      element: <testLibrary>::@class::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::B::@constructor::foo
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        element: <testLibraryFragment>::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: B
        element: <testLibrary>::@class::B
        staticType: null
      element: <testLibrary>::@class::B
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::B::@constructor::foo
      staticType: null
    staticType: null
  element: <testLibrary>::@class::B::@constructor::foo
''');
  }

  test_class_constructor_named_qualified_importPrefix_preferredOverInheritedMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as p;
class A {
  void foo() {}
}
class B extends A {
  B.foo();
}

/// [p.B.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: <testLibraryFragment>::@prefix::p
    CommentReferenceComponent
      period: .
      name: B
      element: <testLibrary>::@class::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::B::@constructor::foo
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        element: <testLibraryFragment>::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: B
        element: <testLibrary>::@class::B
        staticType: null
      element: <testLibrary>::@class::B
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::B::@constructor::foo
      staticType: null
    staticType: null
  element: <testLibrary>::@class::B::@constructor::foo
''');
  }

  test_class_constructor_named_qualified_importPrefix_preferredOverInheritedSetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as p;
class A {
  set foo(int value) {}
}
class B extends A {
  B.foo();
}

/// [p.B.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: <testLibraryFragment>::@prefix::p
    CommentReferenceComponent
      period: .
      name: B
      element: <testLibrary>::@class::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::B::@constructor::foo
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        element: <testLibraryFragment>::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: B
        element: <testLibrary>::@class::B
        staticType: null
      element: <testLibrary>::@class::B
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::B::@constructor::foo
      staticType: null
    staticType: null
  element: <testLibrary>::@class::B::@constructor::foo
''');
  }

  test_class_constructor_named_qualified_preferredOverInheritedGetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}
class B extends A {
  B.foo();
}

/// [B.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: B
      element: <testLibrary>::@class::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::B::@constructor::foo
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      element: <testLibrary>::@class::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::B::@constructor::foo
      staticType: null
    element: <testLibrary>::@class::B::@constructor::foo
    staticType: null
  element: <testLibrary>::@class::B::@constructor::foo
''');
  }

  test_class_constructor_named_qualified_preferredOverInheritedMethod() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}
class B extends A {
  B.foo();
}

/// [B.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: B
      element: <testLibrary>::@class::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::B::@constructor::foo
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      element: <testLibrary>::@class::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::B::@constructor::foo
      staticType: null
    element: <testLibrary>::@class::B::@constructor::foo
    staticType: null
  element: <testLibrary>::@class::B::@constructor::foo
''');
  }

  test_class_constructor_named_qualified_preferredOverInheritedSetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(int value) {}
}
class B extends A {
  B.foo();
}

/// [B.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: B
      element: <testLibrary>::@class::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::B::@constructor::foo
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      element: <testLibrary>::@class::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::B::@constructor::foo
      staticType: null
    element: <testLibrary>::@class::B::@constructor::foo
    staticType: null
  element: <testLibrary>::@class::B::@constructor::foo
''');
  }

  test_class_constructor_named_unqualified_inMember() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A.named();

  /// [named]
  void foo() {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: named
      element: <null>
  expression: SimpleIdentifier
    token: named
    element: <null>
    staticType: null
  element: <null>
''');
  }

  test_class_constructor_unnamed_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A();
}

/// [A.new]
void f() {}
''');

    var node = result.findNode.commentReference('A.new]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: new
      element: <testLibrary>::@class::A::@constructor::new
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
  element: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_constructor_unnamed_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  A();
}

/// [self.A.new]
void f() {}
''');

    var node = result.findNode.commentReference('A.new]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: new
      element: <testLibrary>::@class::A::@constructor::new
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
  element: <testLibrary>::@class::A::@constructor::new
''');
  }

  test_class_extensionGetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
class A {}

extension E on A {
  int get foo => 0;
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@extension::E::@getter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@getter::foo
    staticType: null
  element: <testLibrary>::@extension::E::@getter::foo
''');
  }

  test_class_extensionMethod_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
class A {}

extension E on A {
  void foo() {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@extension::E::@method::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@method::foo
    staticType: null
  element: <testLibrary>::@extension::E::@method::foo
''');
  }

  test_class_extensionSetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
class A {}

extension E on A {
  set foo(int value) {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@extension::E::@setter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@setter::foo
    staticType: null
  element: <testLibrary>::@extension::E::@setter::foo
''');
  }

  test_class_instanceGetter_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

/// [A.foo]
void f() {}
''');

    var node = result.findNode.commentReference('A.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@getter::foo
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
  element: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_class_instanceGetter_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  int get foo => 0;
}

/// [self.A.foo]
void f() {}
''');

    var node = result.findNode.commentReference('A.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@getter::foo
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
  element: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_class_instanceGetter_qualified_importPrefix_inherited_preferredOverInheritedSetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as p;
class A {
  int get foo => 0;
  set foo(int value) {}
}
class B extends A {}

/// [p.B.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: <testLibraryFragment>::@prefix::p
    CommentReferenceComponent
      period: .
      name: B
      element: <testLibrary>::@class::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@getter::foo
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        element: <testLibraryFragment>::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: B
        element: <testLibrary>::@class::B
        staticType: null
      element: <testLibrary>::@class::B
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: null
    staticType: null
  element: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_class_instanceGetter_qualified_importPrefix_onTypedef() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  int get foo => 0;
}
typedef B = A;

/// [self.B.foo]
void f() {}
''');

    var node = result.findNode.commentReference('B.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: B
      element: <testLibrary>::@typeAlias::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@getter::foo
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
  element: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_class_instanceGetter_qualified_inherited_preferredOverInheritedSetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
  set foo(int value) {}
}
class B extends A {}

/// [B.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: B
      element: <testLibrary>::@class::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@getter::foo
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      element: <testLibrary>::@class::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: null
    element: <testLibrary>::@class::A::@getter::foo
    staticType: null
  element: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_class_instanceGetter_qualified_onTypedef() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}
typedef B = A;

/// [B.foo]
void f() {}
''');

    var node = result.findNode.commentReference('B.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: B
      element: <testLibrary>::@typeAlias::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@getter::foo
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
  element: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_class_instanceGetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
class A {
  int get foo => 0;
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@class::A::@getter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: null
  element: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_class_instanceMethod_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void foo() {}
}

/// [A.foo]
void f() {}
''');

    var node = result.findNode.commentReference('A.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@method::foo
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
  element: <testLibrary>::@class::A::@method::foo
''');
  }

  test_class_instanceMethod_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  void foo() {}
}

/// [self.A.foo]
void f() {}
''');

    var node = result.findNode.commentReference('A.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@method::foo
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
  element: <testLibrary>::@class::A::@method::foo
''');
  }

  test_class_instanceMethod_qualified_importPrefix_sameNameAsConstructor() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as p;
class A {
  A.foo();
  void foo() {}
}

/// [p.A.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: <testLibraryFragment>::@prefix::p
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@method::foo
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        element: <testLibraryFragment>::@prefix::p
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
  element: <testLibrary>::@class::A::@method::foo
''');
  }

  test_class_instanceMethod_qualified_sameNameAsConstructor() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A.foo();
  void foo() {}
}

/// [A.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@method::foo
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
  element: <testLibrary>::@class::A::@method::foo
''');
  }

  test_class_instanceMethod_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
class A {
  void foo() {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@class::A::@method::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: null
  element: <testLibrary>::@class::A::@method::foo
''');
  }

  test_class_instanceSetter_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(int _) {}
}

/// [A.foo]
void f() {}
''');

    var node = result.findNode.commentReference('A.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@setter::foo
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
  element: <testLibrary>::@class::A::@setter::foo
''');
  }

  test_class_instanceSetter_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  set foo(int value) {}
}

/// [self.A.foo]
void f() {}
''');

    var node = result.findNode.commentReference('A.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@setter::foo
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
  element: <testLibrary>::@class::A::@setter::foo
''');
  }

  test_class_instanceSetter_qualified_importPrefix_inherited() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as p;
class A {
  set foo(int value) {}
}
class B extends A {}

/// [p.B.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: <testLibraryFragment>::@prefix::p
    CommentReferenceComponent
      period: .
      name: B
      element: <testLibrary>::@class::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@setter::foo
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        element: <testLibraryFragment>::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: B
        element: <testLibrary>::@class::B
        staticType: null
      element: <testLibrary>::@class::B
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@setter::foo
      staticType: null
    staticType: null
  element: <testLibrary>::@class::A::@setter::foo
''');
  }

  test_class_instanceSetter_qualified_importPrefix_inherited_onTypedef() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as p;
class A {
  set foo(int value) {}
}
class B extends A {}
typedef C = B;

/// [p.C.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: <testLibraryFragment>::@prefix::p
    CommentReferenceComponent
      period: .
      name: C
      element: <testLibrary>::@typeAlias::C
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@setter::foo
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        element: <testLibraryFragment>::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: C
        element: <testLibrary>::@typeAlias::C
        staticType: null
      element: <testLibrary>::@typeAlias::C
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@setter::foo
      staticType: null
    staticType: null
  element: <testLibrary>::@class::A::@setter::foo
''');
  }

  test_class_instanceSetter_qualified_importPrefix_preferredOverInheritedGetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as p;
class A {
  int get foo => 0;
}
class B extends A {
  set foo(int value) {}
}

/// [p.B.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: <testLibraryFragment>::@prefix::p
    CommentReferenceComponent
      period: .
      name: B
      element: <testLibrary>::@class::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::B::@setter::foo
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        element: <testLibraryFragment>::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: B
        element: <testLibrary>::@class::B
        staticType: null
      element: <testLibrary>::@class::B
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::B::@setter::foo
      staticType: null
    staticType: null
  element: <testLibrary>::@class::B::@setter::foo
''');
  }

  test_class_instanceSetter_qualified_importPrefix_sameNameAsConstructor() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as p;
class A {
  A.foo();
  set foo(int value) {}
}

/// [p.A.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: <testLibraryFragment>::@prefix::p
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@setter::foo
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        element: <testLibraryFragment>::@prefix::p
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
  element: <testLibrary>::@class::A::@setter::foo
''');
  }

  test_class_instanceSetter_qualified_inherited() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(int value) {}
}
class B extends A {}

/// [B.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: B
      element: <testLibrary>::@class::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@setter::foo
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      element: <testLibrary>::@class::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@setter::foo
      staticType: null
    element: <testLibrary>::@class::A::@setter::foo
    staticType: null
  element: <testLibrary>::@class::A::@setter::foo
''');
  }

  test_class_instanceSetter_qualified_inherited_onTypedef() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set foo(int value) {}
}
class B extends A {}
typedef C = B;

/// [C.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: C
      element: <testLibrary>::@typeAlias::C
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@setter::foo
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: C
      element: <testLibrary>::@typeAlias::C
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@setter::foo
      staticType: null
    element: <testLibrary>::@class::A::@setter::foo
    staticType: null
  element: <testLibrary>::@class::A::@setter::foo
''');
  }

  test_class_instanceSetter_qualified_preferredOverInheritedGetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}
class B extends A {
  set foo(int value) {}
}

/// [B.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: B
      element: <testLibrary>::@class::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::B::@setter::foo
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      element: <testLibrary>::@class::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::B::@setter::foo
      staticType: null
    element: <testLibrary>::@class::B::@setter::foo
    staticType: null
  element: <testLibrary>::@class::B::@setter::foo
''');
  }

  test_class_instanceSetter_qualified_sameNameAsConstructor() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A.foo();
  set foo(int value) {}
}

/// [A.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@setter::foo
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
  element: <testLibrary>::@class::A::@setter::foo
''');
  }

  test_class_instanceSetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
class A {
  set foo(int value) {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@class::A::@setter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@setter::foo
    staticType: null
  element: <testLibrary>::@class::A::@setter::foo
''');
  }

  test_class_instanceSetter_unqualified_preferredOverInheritedGetter() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

/// [foo]
class B extends A {
  set foo(int value) {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@class::B::@setter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::B::@setter::foo
    staticType: null
  element: <testLibrary>::@class::B::@setter::foo
''');
  }

  test_class_invalid_ambiguousExtension_unqualified() async {
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

    var node = result.findNode.commentReference('foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <null>
  expression: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  element: <null>
''');
  }

  test_class_invalid_unresolved_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
class A {}
''');

    var node = result.findNode.commentReference('foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <null>
  expression: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  element: <null>
''');
  }

  test_class_staticGetter_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static int get foo => 0;
}

/// [A.foo]
void f() {}
''');

    var node = result.findNode.commentReference('A.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@getter::foo
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
  element: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_class_staticGetter_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  static int get foo => 0;
}

/// [self.A.foo]
void f() {}
''');

    var node = result.findNode.commentReference('A.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@getter::foo
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
  element: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_class_staticGetter_qualified_importPrefix_onTypedef() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  static int get foo => 0;
}
typedef B = A;

/// [self.B.foo]
void f() {}
''');

    var node = result.findNode.commentReference('B.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: B
      element: <testLibrary>::@typeAlias::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@getter::foo
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
  element: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_class_staticGetter_qualified_onTypedef() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static int get foo => 0;
}

typedef B = A;

/// [B.foo]
void f() {}
''');

    var node = result.findNode.commentReference('B.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: B
      element: <testLibrary>::@typeAlias::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@getter::foo
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
  element: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_class_staticGetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
class A {
  static int get foo => 0;
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@class::A::@getter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: null
  element: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_class_staticGetter_unqualified_superclass() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static int get foo => 0;
}

/// [foo]
class B extends A {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <null>
  expression: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  element: <null>
''');
  }

  test_class_staticMethod_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static void foo() {}
}

/// [A.foo]
void f() {}
''');

    var node = result.findNode.commentReference('A.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@method::foo
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
  element: <testLibrary>::@class::A::@method::foo
''');
  }

  test_class_staticMethod_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  static void foo() {}
}

/// [self.A.foo]
void f() {}
''');

    var node = result.findNode.commentReference('A.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@method::foo
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
  element: <testLibrary>::@class::A::@method::foo
''');
  }

  test_class_staticMethod_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
class A {
  static void foo() {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@class::A::@method::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@method::foo
    staticType: null
  element: <testLibrary>::@class::A::@method::foo
''');
  }

  test_class_staticMethod_unqualified_superclass() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static void foo() {}
}

/// [foo]
class B extends A {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <null>
  expression: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  element: <null>
''');
  }

  test_class_staticSetter_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static set foo(int _) {}
}

/// [A.foo]
void f() {}
''');

    var node = result.findNode.commentReference('A.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@setter::foo
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
  element: <testLibrary>::@class::A::@setter::foo
''');
  }

  test_class_staticSetter_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
class A {
  static set foo(int value) {}
}

/// [self.A.foo]
void f() {}
''');

    var node = result.findNode.commentReference('A.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@setter::foo
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
  element: <testLibrary>::@class::A::@setter::foo
''');
  }

  test_class_staticSetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
class A {
  static set foo(int value) {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@class::A::@setter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@setter::foo
    staticType: null
  element: <testLibrary>::@class::A::@setter::foo
''');
  }

  test_class_staticSetter_unqualified_superclass() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  static set foo(int value) {}
}

/// [foo]
class B extends A {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <null>
  expression: SimpleIdentifier
    token: foo
    element: <null>
    staticType: null
  element: <null>
''');
  }

  test_docImport_associatedSetterAndGetter_setterInScope_unqualified() async {
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

    var node = result.findNode.commentReference('foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@extension::E2::@setter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E2::@setter::foo
    staticType: null
  element: <testLibrary>::@extension::E2::@setter::foo
''');
  }

  test_docImport_associatedSetterAndGetter_unqualified() async {
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

    var node = result.findNode.commentReference('foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: package:test/foo.dart::@getter::foo
  expression: SimpleIdentifier
    token: foo
    element: package:test/foo.dart::@getter::foo
    staticType: null
  element: package:test/foo.dart::@getter::foo
''');
  }

  test_docImport_class_constructor_named_qualified() async {
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

    var node = result.findNode.commentReference('A.named]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: package:test/foo.dart::@class::A
    CommentReferenceComponent
      period: .
      name: named
      element: package:test/foo.dart::@class::A::@constructor::named
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
  element: package:test/foo.dart::@class::A::@constructor::named
''');
  }

  test_docImport_class_constructor_unnamed_qualified() async {
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

    var node = result.findNode.commentReference('A.new]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: package:test/foo.dart::@class::A
    CommentReferenceComponent
      period: .
      name: new
      element: package:test/foo.dart::@class::A::@constructor::new
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
  element: package:test/foo.dart::@class::A::@constructor::new
''');
  }

  test_docImport_class_instanceGetter_qualified() async {
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

    var node = result.findNode.commentReference('A.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: package:test/foo.dart::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: package:test/foo.dart::@class::A::@getter::foo
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
  element: package:test/foo.dart::@class::A::@getter::foo
''');
  }

  test_docImport_class_instanceMethod_qualified() async {
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

    var node = result.findNode.commentReference('A.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: package:test/foo.dart::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: package:test/foo.dart::@class::A::@method::foo
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
  element: package:test/foo.dart::@class::A::@method::foo
''');
  }

  test_docImport_class_staticGetter_qualified() async {
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

    var node = result.findNode.commentReference('A.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: package:test/foo.dart::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: package:test/foo.dart::@class::A::@getter::foo
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
  element: package:test/foo.dart::@class::A::@getter::foo
''');
  }

  test_docImport_class_staticMethod_qualified() async {
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

    var node = result.findNode.commentReference('A.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: package:test/foo.dart::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: package:test/foo.dart::@class::A::@method::foo
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
  element: package:test/foo.dart::@class::A::@method::foo
''');
  }

  test_docImport_class_staticSetter_qualified() async {
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

    var node = result.findNode.commentReference('A.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: package:test/foo.dart::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: package:test/foo.dart::@class::A::@setter::foo
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
  element: package:test/foo.dart::@class::A::@setter::foo
''');
  }

  test_docImport_extension_instanceGetter_qualified() async {
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

    var node = result.findNode.commentReference('E.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: E
      element: package:test/foo.dart::@extension::E
    CommentReferenceComponent
      period: .
      name: foo
      element: package:test/foo.dart::@extension::E::@getter::foo
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
  element: package:test/foo.dart::@extension::E::@getter::foo
''');
  }

  test_docImport_extension_instanceMethod_qualified() async {
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

    var node = result.findNode.commentReference('E.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: E
      element: package:test/foo.dart::@extension::E
    CommentReferenceComponent
      period: .
      name: foo
      element: package:test/foo.dart::@extension::E::@method::foo
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
  element: package:test/foo.dart::@extension::E::@method::foo
''');
  }

  test_docImport_extension_instanceSetter_qualified() async {
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

    var node = result.findNode.commentReference('E.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: E
      element: package:test/foo.dart::@extension::E
    CommentReferenceComponent
      period: .
      name: foo
      element: package:test/foo.dart::@extension::E::@setter::foo
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
  element: package:test/foo.dart::@extension::E::@setter::foo
''');
  }

  test_docImport_extension_staticGetter_qualified() async {
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

    var node = result.findNode.commentReference('E.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: E
      element: package:test/foo.dart::@extension::E
    CommentReferenceComponent
      period: .
      name: foo
      element: package:test/foo.dart::@extension::E::@getter::foo
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
  element: package:test/foo.dart::@extension::E::@getter::foo
''');
  }

  test_docImport_extension_staticMethod_qualified() async {
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

    var node = result.findNode.commentReference('E.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: E
      element: package:test/foo.dart::@extension::E
    CommentReferenceComponent
      period: .
      name: foo
      element: package:test/foo.dart::@extension::E::@method::foo
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
  element: package:test/foo.dart::@extension::E::@method::foo
''');
  }

  test_docImport_extension_staticSetter_qualified() async {
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

    var node = result.findNode.commentReference('E.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: E
      element: package:test/foo.dart::@extension::E
    CommentReferenceComponent
      period: .
      name: foo
      element: package:test/foo.dart::@extension::E::@setter::foo
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
  element: package:test/foo.dart::@extension::E::@setter::foo
''');
  }

  test_docImport_fromExport_unqualified() async {
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

    var node = result.findNode.commentReference('C]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: C
      element: package:test/one.dart::@class::C
  expression: SimpleIdentifier
    token: C
    element: package:test/one.dart::@class::C
    staticType: null
  element: package:test/one.dart::@class::C
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
main() {}
''');

    var node = result.findNode.comment('[new A]');
    assertResolvedNodeText(node, r'''
Comment
  tokens
    /// [new A] or [new A.named]
''');
  }

  test_docImport_onEnumValue_unqualified() async {
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

    var node = result.findNode.commentReference('foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: package:test/foo.dart::@function::foo
  expression: SimpleIdentifier
    token: foo
    element: package:test/foo.dart::@function::foo
    staticType: null
  element: package:test/foo.dart::@function::foo
''');
  }

  test_docImport_onExtensionType_unqualified() async {
    newFile('$testPackageLibPath/foo.dart', r'''
void foo() {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [foo].
extension type ET(int it) {}
''');

    var node = result.findNode.commentReference('foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: package:test/foo.dart::@function::foo
  expression: SimpleIdentifier
    token: foo
    element: package:test/foo.dart::@function::foo
    staticType: null
  element: package:test/foo.dart::@function::foo
''');
  }

  test_docImport_onField_unqualified() async {
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

    var node = result.findNode.commentReference('A]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: package:test/foo.dart::@class::A
  expression: SimpleIdentifier
    token: A
    element: package:test/foo.dart::@class::A
    staticType: null
  element: package:test/foo.dart::@class::A
''');
  }

  test_docImport_onLibrary_unqualified() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
///
/// Text [A].
library;
''');

    var node = result.findNode.commentReference('A]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: package:test/foo.dart::@class::A
  expression: SimpleIdentifier
    token: A
    element: package:test/foo.dart::@class::A
    staticType: null
  element: package:test/foo.dart::@class::A
''');
  }

  test_docImport_onTopLevelFunction_unqualified() async {
    newFile('$testPackageLibPath/foo.dart', r'''
void foo() {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [foo].
void f() {}
''');

    var node = result.findNode.commentReference('foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: package:test/foo.dart::@function::foo
  expression: SimpleIdentifier
    token: foo
    element: package:test/foo.dart::@function::foo
    staticType: null
  element: package:test/foo.dart::@function::foo
''');
  }

  test_docImport_onTopLevelVariable_unqualified() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class A {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;
/// Text [A].
int x = 1;
''');

    var node = result.findNode.commentReference('A]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: package:test/foo.dart::@class::A
  expression: SimpleIdentifier
    token: A
    element: package:test/foo.dart::@class::A
    staticType: null
  element: package:test/foo.dart::@class::A
''');
  }

  test_docImport_onTypedef_unqualified() async {
    newFile('$testPackageLibPath/foo.dart', r'''
void foo() {}
''');
    var result = await resolveTestCodeWithDiagnostics(r'''
/// @docImport 'foo.dart';
library;

/// [foo].
typedef T = int;
''');

    var node = result.findNode.commentReference('foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: package:test/foo.dart::@function::foo
  expression: SimpleIdentifier
    token: foo
    element: package:test/foo.dart::@function::foo
    staticType: null
  element: package:test/foo.dart::@function::foo
''');
  }

  test_enum_instanceGetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
enum E {
  v;

  int get foo => 0;
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@enum::E::@getter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@enum::E::@getter::foo
    staticType: null
  element: <testLibrary>::@enum::E::@getter::foo
''');
  }

  test_enum_instanceMethod_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
enum E {
  v;

  void foo() {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@enum::E::@method::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@enum::E::@method::foo
    staticType: null
  element: <testLibrary>::@enum::E::@method::foo
''');
  }

  test_enum_instanceSetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
enum E {
  v;

  set foo(int value) {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@enum::E::@setter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@enum::E::@setter::foo
    staticType: null
  element: <testLibrary>::@enum::E::@setter::foo
''');
  }

  test_enum_member_extensionGetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
enum E {
  v;

  /// [name]
  void foo() {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: name
      element: dart:core::@extension::EnumName::@getter::name
  expression: SimpleIdentifier
    token: name
    element: dart:core::@extension::EnumName::@getter::name
    staticType: null
  element: dart:core::@extension::EnumName::@getter::name
''');
  }

  test_enum_staticGetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
enum E {
  v;

  static int get foo => 0;
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@enum::E::@getter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@enum::E::@getter::foo
    staticType: null
  element: <testLibrary>::@enum::E::@getter::foo
''');
  }

  test_enum_staticMethod_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
enum E {
  v;

  static void foo() {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@enum::E::@method::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@enum::E::@method::foo
    staticType: null
  element: <testLibrary>::@enum::E::@method::foo
''');
  }

  test_enum_staticSetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
enum E {
  v;

  static set foo(int value) {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@enum::E::@setter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@enum::E::@setter::foo
    staticType: null
  element: <testLibrary>::@enum::E::@setter::foo
''');
  }

  test_extension_extendedType_instanceGetter_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

/// [A.foo]
extension E on A {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@class::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@class::A::@getter::foo
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
  element: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_extension_extendedType_instanceGetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

/// [foo]
extension E on A {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@class::A::@getter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: null
  element: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_extension_extendedTypeParameter_instanceGetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

/// [foo]
extension E<T extends A> on T {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@class::A::@getter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: null
  element: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_extension_instanceGetter_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on int {
  int get foo => 0;
}

/// [E.foo]
void f() {}
''');

    var node = result.findNode.commentReference('E.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: E
      element: <testLibrary>::@extension::E
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extension::E::@getter::foo
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
  element: <testLibrary>::@extension::E::@getter::foo
''');
  }

  test_extension_instanceGetter_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension E on int {
  int get foo => 0;
}

/// [self.E.foo]
void f() {}
''');

    var node = result.findNode.commentReference('foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: E
      element: <testLibrary>::@extension::E
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extension::E::@getter::foo
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
  element: <testLibrary>::@extension::E::@getter::foo
''');
  }

  test_extension_instanceGetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
extension E on int {
  int get foo => 0;
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@extension::E::@getter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@getter::foo
    staticType: null
  element: <testLibrary>::@extension::E::@getter::foo
''');
  }

  test_extension_instanceGetter_unqualified_preferredOverExtendedType() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

/// [foo]
extension E on A {
  int get foo => 0;
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@extension::E::@getter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@getter::foo
    staticType: null
  element: <testLibrary>::@extension::E::@getter::foo
''');
  }

  test_extension_instanceMethod_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on int {
  void foo() {}
}

/// [E.foo]
void f() {}
''');

    var node = result.findNode.commentReference('E.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: E
      element: <testLibrary>::@extension::E
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extension::E::@method::foo
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
  element: <testLibrary>::@extension::E::@method::foo
''');
  }

  test_extension_instanceMethod_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension E on int {
  void foo() {}
}

/// [self.E.foo]
void f() {}
''');

    var node = result.findNode.commentReference('E.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: E
      element: <testLibrary>::@extension::E
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extension::E::@method::foo
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
  element: <testLibrary>::@extension::E::@method::foo
''');
  }

  test_extension_instanceMethod_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
extension E on int {
  void foo() {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@extension::E::@method::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@method::foo
    staticType: null
  element: <testLibrary>::@extension::E::@method::foo
''');
  }

  test_extension_instanceSetter_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on int {
  set foo(int _) {}
}

/// [E.foo]
void f() {}
''');

    var node = result.findNode.commentReference('E.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: E
      element: <testLibrary>::@extension::E
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extension::E::@setter::foo
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
  element: <testLibrary>::@extension::E::@setter::foo
''');
  }

  test_extension_instanceSetter_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension E on int {
  set foo(int value) {}
}

/// [self.E.foo]
void f() {}
''');

    var node = result.findNode.commentReference('E.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: E
      element: <testLibrary>::@extension::E
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extension::E::@setter::foo
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
  element: <testLibrary>::@extension::E::@setter::foo
''');
  }

  test_extension_instanceSetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
extension E on int {
  set foo(int value) {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@extension::E::@setter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@setter::foo
    staticType: null
  element: <testLibrary>::@extension::E::@setter::foo
''');
  }

  test_extension_invalid_extendedFunctionType_instanceMethod_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [toString]
extension E on void Function() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: toString
      element: <null>
  expression: SimpleIdentifier
    token: toString
    element: <null>
    staticType: null
  element: <null>
''');
  }

  test_extension_member_extendedType_instanceGetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

extension E on A {
  /// [foo]
  void bar() {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@class::A::@getter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: null
  element: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_extension_member_extendedTypeParameter_instanceGetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  int get foo => 0;
}

extension E<T extends A> on T {
  /// [foo]
  void bar() {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@class::A::@getter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@class::A::@getter::foo
    staticType: null
  element: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_extension_staticGetter_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on int {
  static int get foo => 0;
}

/// [E.foo]
void f() {}
''');

    var node = result.findNode.commentReference('E.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: E
      element: <testLibrary>::@extension::E
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extension::E::@getter::foo
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
  element: <testLibrary>::@extension::E::@getter::foo
''');
  }

  test_extension_staticGetter_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension E on int {
  static int get foo => 0;
}

/// [self.E.foo]
void f() {}
''');

    var node = result.findNode.commentReference('E.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: E
      element: <testLibrary>::@extension::E
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extension::E::@getter::foo
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
  element: <testLibrary>::@extension::E::@getter::foo
''');
  }

  test_extension_staticGetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
extension E on int {
  static int get foo => 0;
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@extension::E::@getter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@getter::foo
    staticType: null
  element: <testLibrary>::@extension::E::@getter::foo
''');
  }

  test_extension_staticMethod_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on int {
  static void foo() {}
}

/// [E.foo]
void f() {}
''');

    var node = result.findNode.commentReference('E.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: E
      element: <testLibrary>::@extension::E
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extension::E::@method::foo
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
  element: <testLibrary>::@extension::E::@method::foo
''');
  }

  test_extension_staticMethod_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension E on int {
  static void foo() {}
}

/// [self.E.foo]
void f() {}
''');

    var node = result.findNode.commentReference('E.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: E
      element: <testLibrary>::@extension::E
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extension::E::@method::foo
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
  element: <testLibrary>::@extension::E::@method::foo
''');
  }

  test_extension_staticMethod_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
extension E on int {
  static void foo() {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@extension::E::@method::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@method::foo
    staticType: null
  element: <testLibrary>::@extension::E::@method::foo
''');
  }

  test_extension_staticSetter_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension E on int {
  static set foo(int _) {}
}

/// [E.foo]
void f() {}
''');

    var node = result.findNode.commentReference('E.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: E
      element: <testLibrary>::@extension::E
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extension::E::@setter::foo
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
  element: <testLibrary>::@extension::E::@setter::foo
''');
  }

  test_extension_staticSetter_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension E on int {
  static set foo(int value) {}
}

/// [self.E.foo]
void f() {}
''');

    var node = result.findNode.commentReference('E.foo]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: E
      element: <testLibrary>::@extension::E
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extension::E::@setter::foo
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
  element: <testLibrary>::@extension::E::@setter::foo
''');
  }

  test_extension_staticSetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
extension E on int {
  static set foo(int value) {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@extension::E::@setter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extension::E::@setter::foo
    staticType: null
  element: <testLibrary>::@extension::E::@setter::foo
''');
  }

  test_extensionType_constructor_named_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  A.named(this.it);
}

/// [A.named]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@extensionType::A
    CommentReferenceComponent
      period: .
      name: named
      element: <testLibrary>::@extensionType::A::@constructor::named
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@extensionType::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      element: <testLibrary>::@extensionType::A::@constructor::named
      staticType: null
    element: <testLibrary>::@extensionType::A::@constructor::named
    staticType: null
  element: <testLibrary>::@extensionType::A::@constructor::named
''');
  }

  test_extensionType_constructor_named_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension type A(int it) {
  A.named(this.it);
}

/// [self.A.named]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@extensionType::A
    CommentReferenceComponent
      period: .
      name: named
      element: <testLibrary>::@extensionType::A::@constructor::named
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: <testLibrary>::@extensionType::A
        staticType: null
      element: <testLibrary>::@extensionType::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: named
      element: <testLibrary>::@extensionType::A::@constructor::named
      staticType: null
    staticType: null
  element: <testLibrary>::@extensionType::A::@constructor::named
''');
  }

  test_extensionType_constructor_unnamed_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type A(int it) {}

/// [A.new]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@extensionType::A
    CommentReferenceComponent
      period: .
      name: new
      element: <testLibrary>::@extensionType::A::@constructor::new
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@extensionType::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: new
      element: <testLibrary>::@extensionType::A::@constructor::new
      staticType: null
    element: <testLibrary>::@extensionType::A::@constructor::new
    staticType: null
  element: <testLibrary>::@extensionType::A::@constructor::new
''');
  }

  test_extensionType_constructor_unnamed_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension type A(int it) {}

/// [self.A.new]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@extensionType::A
    CommentReferenceComponent
      period: .
      name: new
      element: <testLibrary>::@extensionType::A::@constructor::new
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: <testLibrary>::@extensionType::A
        staticType: null
      element: <testLibrary>::@extensionType::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: new
      element: <testLibrary>::@extensionType::A::@constructor::new
      staticType: null
    staticType: null
  element: <testLibrary>::@extensionType::A::@constructor::new
''');
  }

  test_extensionType_instanceGetter_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  int get foo => 0;
}

/// [A.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@extensionType::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extensionType::A::@getter::foo
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@extensionType::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extensionType::A::@getter::foo
      staticType: null
    element: <testLibrary>::@extensionType::A::@getter::foo
    staticType: null
  element: <testLibrary>::@extensionType::A::@getter::foo
''');
  }

  test_extensionType_instanceGetter_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension type A(int it) {
  int get foo => 0;
}

/// [self.A.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@extensionType::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extensionType::A::@getter::foo
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: <testLibrary>::@extensionType::A
        staticType: null
      element: <testLibrary>::@extensionType::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extensionType::A::@getter::foo
      staticType: null
    staticType: null
  element: <testLibrary>::@extensionType::A::@getter::foo
''');
  }

  test_extensionType_instanceGetter_qualified_importPrefix_onTypedef() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension type A(int it) {
  int get foo => 0;
}
typedef B = A;

/// [self.B.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: B
      element: <testLibrary>::@typeAlias::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extensionType::A::@getter::foo
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
      element: <testLibrary>::@extensionType::A::@getter::foo
      staticType: null
    staticType: null
  element: <testLibrary>::@extensionType::A::@getter::foo
''');
  }

  test_extensionType_instanceGetter_qualified_onTypedef() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  int get foo => 0;
}
typedef B = A;

/// [B.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: B
      element: <testLibrary>::@typeAlias::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extensionType::A::@getter::foo
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      element: <testLibrary>::@typeAlias::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extensionType::A::@getter::foo
      staticType: null
    element: <testLibrary>::@extensionType::A::@getter::foo
    staticType: null
  element: <testLibrary>::@extensionType::A::@getter::foo
''');
  }

  test_extensionType_instanceGetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
extension type A(int it) {
  int get foo => 0;
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@extensionType::A::@getter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@getter::foo
    staticType: null
  element: <testLibrary>::@extensionType::A::@getter::foo
''');
  }

  test_extensionType_instanceMethod_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  void foo() {}
}

/// [A.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@extensionType::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extensionType::A::@method::foo
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@extensionType::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extensionType::A::@method::foo
      staticType: null
    element: <testLibrary>::@extensionType::A::@method::foo
    staticType: null
  element: <testLibrary>::@extensionType::A::@method::foo
''');
  }

  test_extensionType_instanceMethod_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension type A(int it) {
  void foo() {}
}

/// [self.A.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@extensionType::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extensionType::A::@method::foo
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: <testLibrary>::@extensionType::A
        staticType: null
      element: <testLibrary>::@extensionType::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extensionType::A::@method::foo
      staticType: null
    staticType: null
  element: <testLibrary>::@extensionType::A::@method::foo
''');
  }

  test_extensionType_instanceMethod_qualified_inherited() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type A(int it) implements B {}
extension type B(int it) {
  void foo() {}
}

/// [A.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@extensionType::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extensionType::B::@method::foo
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@extensionType::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extensionType::B::@method::foo
      staticType: null
    element: <testLibrary>::@extensionType::B::@method::foo
    staticType: null
  element: <testLibrary>::@extensionType::B::@method::foo
''');
  }

  test_extensionType_instanceMethod_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
extension type A(int it) {
  void foo() {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@extensionType::A::@method::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@method::foo
    staticType: null
  element: <testLibrary>::@extensionType::A::@method::foo
''');
  }

  test_extensionType_instanceSetter_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  set foo(int value) {}
}

/// [A.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@extensionType::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extensionType::A::@setter::foo
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@extensionType::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extensionType::A::@setter::foo
      staticType: null
    element: <testLibrary>::@extensionType::A::@setter::foo
    staticType: null
  element: <testLibrary>::@extensionType::A::@setter::foo
''');
  }

  test_extensionType_instanceSetter_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension type A(int it) {
  set foo(int value) {}
}

/// [self.A.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@extensionType::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extensionType::A::@setter::foo
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: <testLibrary>::@extensionType::A
        staticType: null
      element: <testLibrary>::@extensionType::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extensionType::A::@setter::foo
      staticType: null
    staticType: null
  element: <testLibrary>::@extensionType::A::@setter::foo
''');
  }

  test_extensionType_instanceSetter_qualified_importPrefix_inherited() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as p;
extension type A(int it) {
  set foo(int value) {}
}
extension type B(int it) implements A {}

/// [p.B.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: <testLibraryFragment>::@prefix::p
    CommentReferenceComponent
      period: .
      name: B
      element: <testLibrary>::@extensionType::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extensionType::A::@setter::foo
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        element: <testLibraryFragment>::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: B
        element: <testLibrary>::@extensionType::B
        staticType: null
      element: <testLibrary>::@extensionType::B
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extensionType::A::@setter::foo
      staticType: null
    staticType: null
  element: <testLibrary>::@extensionType::A::@setter::foo
''');
  }

  test_extensionType_instanceSetter_qualified_inherited() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  set foo(int value) {}
}
extension type B(int it) implements A {}

/// [B.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: B
      element: <testLibrary>::@extensionType::B
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extensionType::A::@setter::foo
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      element: <testLibrary>::@extensionType::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extensionType::A::@setter::foo
      staticType: null
    element: <testLibrary>::@extensionType::A::@setter::foo
    staticType: null
  element: <testLibrary>::@extensionType::A::@setter::foo
''');
  }

  test_extensionType_instanceSetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
extension type A(int it) {
  set foo(int value) {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@extensionType::A::@setter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@setter::foo
    staticType: null
  element: <testLibrary>::@extensionType::A::@setter::foo
''');
  }

  test_extensionType_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension type A(int it) {}

/// [self.A]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@extensionType::A
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: self
      element: <testLibraryFragment>::@prefix::self
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: A
      element: <testLibrary>::@extensionType::A
      staticType: null
    element: <testLibrary>::@extensionType::A
    staticType: null
  element: <testLibrary>::@extensionType::A
''');
  }

  test_extensionType_representation_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type A(int it) {}

/// [A.it]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@extensionType::A
    CommentReferenceComponent
      period: .
      name: it
      element: <testLibrary>::@extensionType::A::@getter::it
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@extensionType::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: it
      element: <testLibrary>::@extensionType::A::@getter::it
      staticType: null
    element: <testLibrary>::@extensionType::A::@getter::it
    staticType: null
  element: <testLibrary>::@extensionType::A::@getter::it
''');
  }

  test_extensionType_representation_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension type A(int it) {}

/// [self.A.it]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@extensionType::A
    CommentReferenceComponent
      period: .
      name: it
      element: <testLibrary>::@extensionType::A::@getter::it
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: <testLibrary>::@extensionType::A
        staticType: null
      element: <testLibrary>::@extensionType::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: it
      element: <testLibrary>::@extensionType::A::@getter::it
      staticType: null
    staticType: null
  element: <testLibrary>::@extensionType::A::@getter::it
''');
  }

  test_extensionType_staticGetter_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  static int get foo => 0;
}

/// [A.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@extensionType::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extensionType::A::@getter::foo
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@extensionType::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extensionType::A::@getter::foo
      staticType: null
    element: <testLibrary>::@extensionType::A::@getter::foo
    staticType: null
  element: <testLibrary>::@extensionType::A::@getter::foo
''');
  }

  test_extensionType_staticGetter_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension type A(int it) {
  static int get foo => 0;
}

/// [self.A.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@extensionType::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extensionType::A::@getter::foo
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: <testLibrary>::@extensionType::A
        staticType: null
      element: <testLibrary>::@extensionType::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extensionType::A::@getter::foo
      staticType: null
    staticType: null
  element: <testLibrary>::@extensionType::A::@getter::foo
''');
  }

  test_extensionType_staticGetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
extension type A(int it) {
  static int get foo => 0;
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@extensionType::A::@getter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@getter::foo
    staticType: null
  element: <testLibrary>::@extensionType::A::@getter::foo
''');
  }

  test_extensionType_staticMethod_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  static void foo() {}
}

/// [A.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@extensionType::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extensionType::A::@method::foo
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@extensionType::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extensionType::A::@method::foo
      staticType: null
    element: <testLibrary>::@extensionType::A::@method::foo
    staticType: null
  element: <testLibrary>::@extensionType::A::@method::foo
''');
  }

  test_extensionType_staticMethod_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension type A(int it) {
  static void foo() {}
}

/// [self.A.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@extensionType::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extensionType::A::@method::foo
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: <testLibrary>::@extensionType::A
        staticType: null
      element: <testLibrary>::@extensionType::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extensionType::A::@method::foo
      staticType: null
    staticType: null
  element: <testLibrary>::@extensionType::A::@method::foo
''');
  }

  test_extensionType_staticMethod_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
extension type A(int it) {
  static void foo() {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@extensionType::A::@method::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@method::foo
    staticType: null
  element: <testLibrary>::@extensionType::A::@method::foo
''');
  }

  test_extensionType_staticSetter_qualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type A(int it) {
  static set foo(int value) {}
}

/// [A.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@extensionType::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extensionType::A::@setter::foo
  expression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@extensionType::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extensionType::A::@setter::foo
      staticType: null
    element: <testLibrary>::@extensionType::A::@setter::foo
    staticType: null
  element: <testLibrary>::@extensionType::A::@setter::foo
''');
  }

  test_extensionType_staticSetter_qualified_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics('''
import '' as self;
extension type A(int it) {
  static set foo(int value) {}
}

/// [self.A.foo]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: self
      element: <testLibraryFragment>::@prefix::self
    CommentReferenceComponent
      period: .
      name: A
      element: <testLibrary>::@extensionType::A
    CommentReferenceComponent
      period: .
      name: foo
      element: <testLibrary>::@extensionType::A::@setter::foo
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: self
        element: <testLibraryFragment>::@prefix::self
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: <testLibrary>::@extensionType::A
        staticType: null
      element: <testLibrary>::@extensionType::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <testLibrary>::@extensionType::A::@setter::foo
      staticType: null
    staticType: null
  element: <testLibrary>::@extensionType::A::@setter::foo
''');
  }

  test_extensionType_staticSetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
extension type A(int it) {
  static set foo(int value) {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@extensionType::A::@setter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@extensionType::A::@setter::foo
    staticType: null
  element: <testLibrary>::@extensionType::A::@setter::foo
''');
  }

  test_extensionType_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
extension type A(int it) {}

/// [A]
void f() {}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: A
      element: <testLibrary>::@extensionType::A
  expression: SimpleIdentifier
    token: A
    element: <testLibrary>::@extensionType::A
    staticType: null
  element: <testLibrary>::@extensionType::A
''');
  }

  test_mixin_instanceGetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
mixin M {
  int get foo => 0;
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@mixin::M::@getter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@mixin::M::@getter::foo
    staticType: null
  element: <testLibrary>::@mixin::M::@getter::foo
''');
  }

  test_mixin_instanceMethod_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
mixin M {
  void foo() {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@mixin::M::@method::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@mixin::M::@method::foo
    staticType: null
  element: <testLibrary>::@mixin::M::@method::foo
''');
  }

  test_mixin_instanceSetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
mixin M {
  set foo(int value) {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@mixin::M::@setter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@mixin::M::@setter::foo
    staticType: null
  element: <testLibrary>::@mixin::M::@setter::foo
''');
  }

  test_mixin_staticGetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
mixin M {
  static int get foo => 0;
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@mixin::M::@getter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@mixin::M::@getter::foo
    staticType: null
  element: <testLibrary>::@mixin::M::@getter::foo
''');
  }

  test_mixin_staticMethod_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
mixin M {
  static void foo() {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@mixin::M::@method::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@mixin::M::@method::foo
    staticType: null
  element: <testLibrary>::@mixin::M::@method::foo
''');
  }

  test_mixin_staticSetter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [foo]
mixin M {
  static set foo(int value) {}
}
''');

    var node = result.findNode.singleCommentReference;
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: foo
      element: <testLibrary>::@mixin::M::@setter::foo
  expression: SimpleIdentifier
    token: foo
    element: <testLibrary>::@mixin::M::@setter::foo
    staticType: null
  element: <testLibrary>::@mixin::M::@setter::foo
''');
  }

  test_newKeyword() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A();
  A.named();
}

/// [new A] or [new A.named]
main() {}
''');

    var node = result.findNode.comment('[new A]');
    assertResolvedNodeText(node, r'''
Comment
  tokens
    /// [new A] or [new A.named]
''');
  }

  test_newKeyword_missingConstructor() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A.named();
}

/// [new A]
void f() {}
''');
    var node = result.findNode.comment('[new A]');
    assertResolvedNodeText(node, r'''
Comment
  tokens
    /// [new A]
''');
  }

  test_newKeyword_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics('''
/// [new Missing]
void f() {}
''');
    var node = result.findNode.comment('[new Missing]');
    assertResolvedNodeText(node, r'''
Comment
  tokens
    /// [new Missing]
''');
  }

  test_onFieldFormalParameter_unqualified() async {
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
  components
    CommentReferenceComponent
      name: int
      element: dart:core::@class::int
  expression: SimpleIdentifier
    token: int
    element: dart:core::@class::int
    staticType: null
  element: dart:core::@class::int
''');
  }

  test_onFunctionTypedFormalParameter_self_unqualified() async {
    // TODO(scheglov): add tests for references to nested formal parameters
    var result = await resolveTestCodeWithDiagnostics(r'''
/// [bar]
void f(int bar()) {}
''');

    var node = result.findNode.commentReference('bar]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: bar
      element: <testLibrary>::@function::f::@formalParameter::bar
  expression: SimpleIdentifier
    token: bar
    element: <testLibrary>::@function::f::@formalParameter::bar
    staticType: null
  element: <testLibrary>::@function::f::@formalParameter::bar
''');
  }

  test_onFunctionTypedFormalParameter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(
  /// [int]
  void g(int a),
) {}
''');

    var node = result.findNode.commentReference('int]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: int
      element: dart:core::@class::int
  expression: SimpleIdentifier
    token: int
    element: dart:core::@class::int
    staticType: null
  element: dart:core::@class::int
''');
  }

  test_onSimpleFormalParameter_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(
  /// [int]
  int x,
) {}
''');

    var node = result.findNode.commentReference('int]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: int
      element: dart:core::@class::int
  expression: SimpleIdentifier
    token: int
    element: dart:core::@class::int
    staticType: null
  element: dart:core::@class::int
''');
  }

  test_onSuperFormalParameter_unqualified() async {
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
  components
    CommentReferenceComponent
      name: int
      element: dart:core::@class::int
  expression: SimpleIdentifier
    token: int
    element: dart:core::@class::int
    staticType: null
  element: dart:core::@class::int
''');
  }

  test_operator_qualified_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  A operator +(A other) => this;
}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;

/// [p.A.operator +]
void f() {}
''');
    var node = result.findNode.commentReference('p.A.operator +]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: <testLibraryFragment>::@prefix::p
    CommentReferenceComponent
      period: .
      name: A
      element: package:test/a.dart::@class::A
    CommentReferenceComponent
      period: .
      operatorKeyword: operator
      name: +
      element: package:test/a.dart::@class::A::@method::+
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        element: <testLibraryFragment>::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: package:test/a.dart::@class::A
        staticType: null
      element: package:test/a.dart::@class::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: +
      element: package:test/a.dart::@class::A::@method::+
      staticType: null
    staticType: null
  element: package:test/a.dart::@class::A::@method::+
''');
  }

  test_operator_unqualified() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  /// [operator +] and [+]
  A operator +(A other) => this;
}
''');
    var node = result.findNode.commentReference('operator +]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      operatorKeyword: operator
      name: +
      element: <testLibrary>::@class::A::@method::+
  expression: SimpleIdentifier
    token: +
    element: <testLibrary>::@class::A::@method::+
    staticType: null
  element: <testLibrary>::@class::A::@method::+
''');
    var bare = result.findNode.commentReference('+]\n');
    assertResolvedNodeText(bare, r'''
CommentReference
  components
    CommentReferenceComponent
      name: +
      element: <testLibrary>::@class::A::@method::+
  expression: SimpleIdentifier
    token: +
    element: <testLibrary>::@class::A::@method::+
    staticType: null
  element: <testLibrary>::@class::A::@method::+
''');
  }

  test_partialResolution_qualified_importPrefix() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;

/// [p.A.missing]
void f() {}
''');
    var node = result.findNode.commentReference('p.A.missing]');
    assertResolvedNodeText(node, r'''
CommentReference
  components
    CommentReferenceComponent
      name: p
      element: <testLibraryFragment>::@prefix::p
    CommentReferenceComponent
      period: .
      name: A
      element: package:test/a.dart::@class::A
    CommentReferenceComponent
      period: .
      name: missing
      element: <null>
  expression: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: p
        element: <testLibraryFragment>::@prefix::p
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: A
        element: package:test/a.dart::@class::A
        staticType: null
      element: package:test/a.dart::@class::A
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: missing
      element: <null>
      staticType: null
    staticType: null
  element: <null>
''');
  }

  test_setter_unqualified() async {
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

    var node1 = result.findNode.commentReference('x] in A');
    assertResolvedNodeText(node1, r'''
CommentReference
  components
    CommentReferenceComponent
      name: x
      element: <testLibrary>::@class::A::@setter::x
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@class::A::@setter::x
    staticType: null
  element: <testLibrary>::@class::A::@setter::x
''');

    var node2 = result.findNode.commentReference('x] in B');
    assertResolvedNodeText(node2, r'''
CommentReference
  components
    CommentReferenceComponent
      name: x
      element: <testLibrary>::@class::A::@setter::x
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@class::A::@setter::x
    staticType: null
  element: <testLibrary>::@class::A::@setter::x
''');
  }
}
