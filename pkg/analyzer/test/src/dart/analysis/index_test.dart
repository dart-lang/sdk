// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/index.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/test_utilities/find_element2.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/diff.dart';
import '../resolution/context_collection_resolution.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IndexTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

class ExpectedLocation {
  final int offset;
  final int length;
  final bool isQualified;

  ExpectedLocation(this.offset, this.length, this.isQualified);

  @override
  String toString() {
    return '(offset=$offset; length=$length; isQualified=$isQualified)';
  }
}

@reflectiveTest
class IndexTest extends PubPackageResolutionTest with _IndexMixin {
  void assertElementIndexText(Element element, String expected) {
    var actual = _getRelationsText(element);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      printPrettyDiff(expected, actual);
      fail('See the difference above.');
    }
  }

  void assertLibraryFragmentIndexText(
    LibraryFragmentImpl fragment,
    String expected,
  ) {
    var actual = _getLibraryFragmentReferenceText(fragment);
    if (actual != expected) {
      print(actual);
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  test_ClassElement_hierarchy_class_extends() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

class A {}

class B extends A {}
class B_q extends p.A {}
''');
    assertErrorsInResult([]);

    var element = findElement2.class_('A');
    assertElementIndexText(element, r'''
54 5:17 |A| IS_EXTENDED_BY
54 5:17 |A| IS_REFERENCED_BY
79 6:21 |A| IS_EXTENDED_BY qualified
79 6:21 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_hierarchy_class_extends_implicitObject() async {
    await _indexTestUnit('''
class A {}
''');
    var element = typeProvider.objectType.element;
    assertElementIndexText(element, r'''
6 1:7 || IS_EXTENDED_BY qualified
''');
  }

  test_ClassElement_hierarchy_class_implements() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

class A {}

class B implements A {}
class B_q implements p.A {}
''');
    assertErrorsInResult([]);

    var element = findElement2.class_('A');
    assertElementIndexText(element, r'''
57 5:20 |A| IS_IMPLEMENTED_BY
57 5:20 |A| IS_REFERENCED_BY
85 6:24 |A| IS_IMPLEMENTED_BY qualified
85 6:24 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_hierarchy_class_with() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

class A {}

class D extends Object with A {}
class D_q extends Object with p.A {}
''');
    assertErrorsInResult([
      error(diag.classUsedAsMixin, 66, 1),
      error(diag.classUsedAsMixin, 101, 3),
    ]);

    var element = findElement2.class_('A');
    assertElementIndexText(element, r'''
66 5:29 |A| IS_MIXED_IN_BY
66 5:29 |A| IS_REFERENCED_BY
103 6:33 |A| IS_MIXED_IN_BY qualified
103 6:33 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_hierarchy_classTypeAlias_with() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

class A {}

class D2 = Object with A;
class D2_q = Object with p.A;
''');
    assertErrorsInResult([
      error(diag.classUsedAsMixin, 61, 1),
      error(diag.classUsedAsMixin, 89, 3),
    ]);

    var element = findElement2.class_('A');
    assertElementIndexText(element, r'''
61 5:24 |A| IS_MIXED_IN_BY
61 5:24 |A| IS_REFERENCED_BY
91 6:28 |A| IS_MIXED_IN_BY qualified
91 6:28 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_hierarchy_enum_implements() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

class A {}

enum E implements A { v }
enum E_q implements p.A { v }
''');
    assertErrorsInResult([]);

    var element = findElement2.class_('A');
    assertElementIndexText(element, r'''
56 5:19 |A| IS_IMPLEMENTED_BY
56 5:19 |A| IS_REFERENCED_BY
86 6:23 |A| IS_IMPLEMENTED_BY qualified
86 6:23 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_hierarchy_extensionType_implements() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

class A {}

extension type E(A it) implements A {}
extension type E_q(A it) implements p.A {}
''');
    assertErrorsInResult([]);

    var element = findElement2.class_('A');
    assertElementIndexText(element, r'''
55 5:18 |A| IS_REFERENCED_BY
72 5:35 |A| IS_IMPLEMENTED_BY
72 5:35 |A| IS_REFERENCED_BY
96 6:20 |A| IS_REFERENCED_BY
115 6:39 |A| IS_IMPLEMENTED_BY qualified
115 6:39 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_hierarchy_mixin_implements() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

class A {}

mixin M implements A {}
mixin M_q implements p.A {}
''');
    assertErrorsInResult([]);

    var element = findElement2.class_('A');
    assertElementIndexText(element, r'''
57 5:20 |A| IS_IMPLEMENTED_BY
57 5:20 |A| IS_REFERENCED_BY
85 6:24 |A| IS_IMPLEMENTED_BY qualified
85 6:24 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_hierarchy_mixin_on() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

class A {}

mixin M2 on A {}
mixin M2_q on p.A {}
''');
    assertErrorsInResult([]);

    var element = findElement2.class_('A');
    assertElementIndexText(element, r'''
50 5:13 |A| CONSTRAINS
50 5:13 |A| IS_REFERENCED_BY
71 6:17 |A| CONSTRAINS qualified
71 6:17 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_reference_annotation() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

class A {
  const A();
  const A.named();
  static const int myConstant = 0;
}

@A()
@p.A()
@A.named()
@p.A.named()
@A.myConstant
@p.A.myConstant
void f() {}
''');
    assertErrorsInResult([]);

    var element = findElement2.class_('A');
    assertElementIndexText(element, r'''
44 4:9 |A| IS_REFERENCED_BY
57 5:9 |A| IS_REFERENCED_BY
107 9:2 |A| IS_REFERENCED_BY
114 10:4 |A| IS_REFERENCED_BY qualified
119 11:2 |A| IS_REFERENCED_BY
132 12:4 |A| IS_REFERENCED_BY qualified
143 13:2 |A| IS_REFERENCED_BY
159 14:4 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_reference_annotation_typeArgument() async {
    await _indexTestUnit(r'''
class A<T> {
  const A();
}

class B {}

@A<B>()
void f() {}
''');
    var element = findElement2.class_('B');
    assertElementIndexText(element, r'''
44 7:4 |B| IS_REFERENCED_BY
''');
  }

  test_ClassElement_reference_classTypeAlias() async {
    await _indexTestUnit('''
class A {}
class B = Object with A;
void f(B p) {
  B v;
}
''');
    var element = findElement2.class_('B');
    assertElementIndexText(element, r'''
43 3:8 |B| IS_REFERENCED_BY
52 4:3 |B| IS_REFERENCED_BY
''');
  }

  test_ClassElement_reference_comment() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

class A {}

/// [A] and [p.A].
void f() {}
''');
    var element = findElement2.class_('A');
    assertElementIndexText(element, r'''
43 5:6 |A| IS_REFERENCED_BY
53 5:16 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_reference_definedInSdk() async {
    await _indexTestUnit(r'''
import 'dart:math';
Random v1;
Random v2;
''');
    var element = findElement2.importFind('dart:math').class_('Random');
    assertElementIndexText(element, r'''
20 2:1 |Random| IS_REFERENCED_BY
31 3:1 |Random| IS_REFERENCED_BY
''');
  }

  test_ClassElement_reference_definedOutside() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class A {}
''');
    await _indexTestUnit(r'''
import 'lib.dart';

void f(A p) {
  A v = p;
}
''');
    var element = findNode.namedType('A p').element!;
    assertElementIndexText(element, r'''
27 3:8 |A| IS_REFERENCED_BY
36 4:3 |A| IS_REFERENCED_BY
''');
  }

  test_ClassElement_reference_instanceCreation() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

class A {}

void f() {
  A();
  p.A();
}
''');
    assertErrorsInResult([]);

    var element = findElement2.class_('A');
    assertElementIndexText(element, r'''
51 6:3 |A| IS_REFERENCED_BY
60 7:5 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_reference_memberAccess() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

class A {
  static void foo() {}
}

void f() {
  A.foo();
  p.A.foo();
}
''');
    assertErrorsInResult([]);

    var element = findElement2.class_('A');
    assertElementIndexText(element, r'''
75 8:3 |A| IS_REFERENCED_BY
88 9:5 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_reference_namedType() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

class A {}

void f() {
  A v1;
  p.A v2;
  List<A> v3;
  List<p.A> v4;
}
''');
    assertErrorsInResult([
      error(diag.unusedLocalVariable, 53, 2),
      error(diag.unusedLocalVariable, 63, 2),
      error(diag.unusedLocalVariable, 77, 2),
      error(diag.unusedLocalVariable, 93, 2),
    ]);

    var element = findElement2.class_('A');
    assertElementIndexText(element, r'''
51 6:3 |A| IS_REFERENCED_BY
61 7:5 |A| IS_REFERENCED_BY qualified
74 8:8 |A| IS_REFERENCED_BY
90 9:10 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_reference_recordTypeAnnotation_named() async {
    await _indexTestUnit(r'''
class A {}

void f(({int foo, A bar}) r) {}
''');
    var element = findElement2.class_('A');
    assertElementIndexText(element, r'''
30 3:19 |A| IS_REFERENCED_BY
''');
  }

  test_ClassElement_reference_recordTypeAnnotation_positional() async {
    await _indexTestUnit(r'''
class A {}

void f((int, A) r) {}
''');
    var element = findElement2.class_('A');
    assertElementIndexText(element, r'''
25 3:14 |A| IS_REFERENCED_BY
''');
  }

  test_ClassElement_reference_typeLiteral() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

class A {}

var v = A;
var v_p = p.A;
''');
    var element = findElement2.class_('A');
    assertElementIndexText(element, r'''
46 5:9 |A| IS_REFERENCED_BY
61 6:13 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ConstructorElement_class_method_sameName() async {
    await _indexTestUnit('''
class A {
  A.foo() {
    foo();
  }

  A foo() => A.foo();
}
''');

    var constructor = findElement2.constructor('foo');
    assertElementIndexText(constructor, r'''
52 6:15 |.foo| IS_INVOKED_BY qualified
''');

    var method = findElement2.method('foo');
    assertElementIndexText(method, r'''
26 3:5 |foo| IS_INVOKED_BY
''');
  }

  test_ConstructorElement_class_named_newHead() async {
    await _indexTestUnit('''
/// [new A.foo] and [A.foo]
class A {
  new foo() {}
  new bar() : this.foo();
  factory baz() = A.foo;
}
class B extends A {
  new () : super.foo();
}
void useConstructor() {
  A.foo();
  A.foo;
  A a = .foo();
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.unusedLocalVariable, 200, 1),
    ]);
    var element = findElement2.constructor('foo');
    assertElementIndexText(element, r'''
10 1:11 |.foo| IS_REFERENCED_BY qualified
22 1:23 |.foo| IS_REFERENCED_BY qualified
71 4:19 |.foo| IS_INVOKED_BY qualified
98 5:20 |.foo| IS_REFERENCED_BY qualified
142 8:17 |.foo| IS_INVOKED_BY qualified
179 11:4 |.foo| IS_INVOKED_BY qualified
190 12:4 |.foo| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
205 13:10 |foo| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_class_named_primary() async {
    await _indexTestUnit('''
/// [new A.foo] and [A.foo]
class A.foo() {
  new bar() : this.foo();
  factory baz() = A.foo;
}
class B() extends A {
  this : super.foo();
}
void useConstructor() {
  A.foo();
  A.foo;
  A a = .foo();
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.unusedLocalVariable, 191, 1),
    ]);
    var element = findElement2.constructor('foo');
    assertElementIndexText(element, r'''
10 1:11 |.foo| IS_REFERENCED_BY qualified
22 1:23 |.foo| IS_REFERENCED_BY qualified
62 3:19 |.foo| IS_INVOKED_BY qualified
89 4:20 |.foo| IS_REFERENCED_BY qualified
133 7:15 |.foo| IS_INVOKED_BY qualified
170 10:4 |.foo| IS_INVOKED_BY qualified
181 11:4 |.foo| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
196 12:10 |foo| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_class_named_typeName() async {
    await _indexTestUnit('''
/// [new A.foo] and [A.foo]
class A {
  A.foo() {}
  A.bar() : this.foo();
  factory A.baz() = A.foo;
}
class B extends A {
  B() : super.foo();
}
void useConstructor() {
  A.foo();
  A.foo;
  A a = .foo();
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.unusedLocalVariable, 195, 1),
    ]);
    var element = findElement2.constructor('foo');
    assertElementIndexText(element, r'''
10 1:11 |.foo| IS_REFERENCED_BY qualified
22 1:23 |.foo| IS_REFERENCED_BY qualified
67 4:17 |.foo| IS_INVOKED_BY qualified
96 5:22 |.foo| IS_REFERENCED_BY qualified
137 8:14 |.foo| IS_INVOKED_BY qualified
174 11:4 |.foo| IS_INVOKED_BY qualified
185 12:4 |.foo| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
200 13:10 |foo| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_class_named_typeName_viaTypeAlias() async {
    await _indexTestUnit('''
/// [new B.foo] and [B.foo]
class A<T> {
  A.foo() {}
  A.bar() : this.foo();
  factory A.baz() = A.foo;
}
typedef B = A<int>;
class C extends B {
  C() : super.foo();
}
void useConstructor() {
  B.foo();
  B.foo;
  B b = .foo();
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.unusedLocalVariable, 218, 1),
    ]);
    var element = findElement2.constructor('foo');
    assertElementIndexText(element, r'''
10 1:11 |.foo| IS_REFERENCED_BY qualified
22 1:23 |.foo| IS_REFERENCED_BY qualified
70 4:17 |.foo| IS_INVOKED_BY qualified
99 5:22 |.foo| IS_REFERENCED_BY qualified
160 9:14 |.foo| IS_INVOKED_BY qualified
197 12:4 |.foo| IS_INVOKED_BY qualified
208 13:4 |.foo| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
223 14:10 |foo| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_class_unnamed_implicit() async {
    await _indexTestUnit('''
/// [new A] and [A.new]
class B {
  B();
  factory B.baz() = A;
}
class A extends B {}
class C extends A {
  C() : super();
}
void useConstructor() {
  A();
  A.new;
  A a = .new();
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.unusedLocalVariable, 170, 1),
    ]);
    var element = findElement2.unnamedConstructor('A');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
18 1:19 |.new| IS_REFERENCED_BY qualified
62 4:22 || IS_REFERENCED_BY qualified
120 8:14 || IS_INVOKED_BY qualified
153 11:4 || IS_INVOKED_BY qualified
160 12:4 |.new| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
175 13:10 |new| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_class_unnamed_implicitInvocation_fromNewHead() async {
    await _indexTestUnit('''
class A {
  A();
}

class B extends A {
  new ();
  new bar();
  factory new.baz() = A;
}
''');

    var element = findElement2.unnamedConstructor('A');
    assertElementIndexText(element, r'''
42 6:3 |new| IS_INVOKED_BY qualified
52 7:3 |new bar| IS_INVOKED_BY qualified
86 8:24 || IS_REFERENCED_BY qualified
''');
  }

  test_ConstructorElement_class_unnamed_implicitInvocation_fromTypeName() async {
    await _indexTestUnit('''
class A {
  A();
}

class B extends A {
  B();
  B.bar();
  factory B.baz() = A;
}

class C extends A {}
''');

    var element = findElement2.unnamedConstructor('A');
    assertElementIndexText(element, r'''
42 6:3 |B| IS_INVOKED_BY qualified
49 7:3 |B.bar| IS_INVOKED_BY qualified
79 8:22 || IS_REFERENCED_BY qualified
90 11:7 |C| IS_INVOKED_BY qualified
''');
  }

  test_ConstructorElement_class_unnamed_newHead() async {
    await _indexTestUnit('''
/// [new A] and [A.new]
class A {
  new () {}
  new bar() : this();
  factory baz() = A;
}
class B extends A {
  new () : super();
}
void useConstructor() {
  A();
  A.new;
  A a = .new();
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.unusedLocalVariable, 177, 1),
    ]);
    var element = findElement2.unnamedConstructor('A');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
18 1:19 |.new| IS_REFERENCED_BY qualified
64 4:19 || IS_INVOKED_BY qualified
87 5:20 || IS_REFERENCED_BY qualified
127 8:17 || IS_INVOKED_BY qualified
160 11:4 || IS_INVOKED_BY qualified
167 12:4 |.new| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
182 13:10 |new| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_class_unnamed_otherFile() async {
    var other = convertPath('$testPackageLibPath/other.dart');
    var otherFile = newFile(other, '''
import 'test.dart';

void f() {
  A();
}
''');

    await resolveTestCode('''
class A {
  A() {}
}
''');
    var element = findElement2.unnamedConstructor('A');

    await resolveFile2(otherFile);
    index = AnalysisDriverUnitIndex.fromBuffer(
      indexUnit(result.unit).toBuffer(),
    );

    assertErrorsInResult([]);
    assertElementIndexText(element, r'''
35 4:4 || IS_INVOKED_BY qualified
''');
  }

  test_ConstructorElement_class_unnamed_primary() async {
    await _indexTestUnit('''
/// [new A] and [A.new]
class A() {
  new bar() : this();
  factory baz() = A;
}
class B() extends A {
  this : super();
}
void useConstructor() {
  A();
  A.new;
  A a = .new();
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.unusedLocalVariable, 167, 1),
    ]);
    var element = findElement2.unnamedConstructor('A');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
18 1:19 |.new| IS_REFERENCED_BY qualified
54 3:19 || IS_INVOKED_BY qualified
77 4:20 || IS_REFERENCED_BY qualified
117 7:15 || IS_INVOKED_BY qualified
150 10:4 || IS_INVOKED_BY qualified
157 11:4 |.new| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
172 12:10 |new| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_class_unnamed_typeName() async {
    await _indexTestUnit('''
/// [new A] and [A.new]
class A {
  A() {}
  A.bar() : this();
  factory A.baz() = A;
}
class B extends A {
  B() : super();
}
void useConstructor() {
  A();
  A.new;
  A a = .new();
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.unusedLocalVariable, 171, 1),
    ]);
    var element = findElement2.unnamedConstructor('A');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
18 1:19 |.new| IS_REFERENCED_BY qualified
59 4:17 || IS_INVOKED_BY qualified
84 5:22 || IS_REFERENCED_BY qualified
121 8:14 || IS_INVOKED_BY qualified
154 11:4 || IS_INVOKED_BY qualified
161 12:4 |.new| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
176 13:10 |new| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_class_unnamed_typeName_explicitNew() async {
    await _indexTestUnit('''
/// [new A] and [A.new]
class A {
  A.new() {}
  A.bar() : this.new();
  factory A.baz() = A.new;
}
class B extends A {
  B() : super.new();
}
void useConstructor() {
  A.new();
  A.new;
  A a = .new();
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.unusedLocalVariable, 191, 1),
    ]);
    var element = findElement2.unnamedConstructor('A');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
18 1:19 |.new| IS_REFERENCED_BY qualified
63 4:17 |.new| IS_INVOKED_BY qualified
92 5:22 |.new| IS_REFERENCED_BY qualified
133 8:14 |.new| IS_INVOKED_BY qualified
170 11:4 |.new| IS_INVOKED_BY qualified
181 12:4 |.new| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
196 13:10 |new| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_classTypeAlias() async {
    await _indexTestUnit('''
class M {}
class A {
  A() {}
  A.named() {}
}
class B = A with M;
class C = B with M;
void useConstructor() {
  B();
  B.named();
  C();
  C.named();
}
''');
    assertErrorsInResult([
      error(diag.classUsedAsMixin, 64, 1),
      error(diag.classUsedAsMixin, 84, 1),
    ]);
    var constructor = findElement2.unnamedConstructor('A');
    assertElementIndexText(constructor, r'''
114 9:4 || IS_INVOKED_BY qualified
134 11:4 || IS_INVOKED_BY qualified
''');

    var constructorNamed = findElement2.constructor('named', of: 'A');
    assertElementIndexText(constructorNamed, r'''
121 10:4 |.named| IS_INVOKED_BY qualified
141 12:4 |.named| IS_INVOKED_BY qualified
''');
  }

  test_ConstructorElement_classTypeAlias_cycle() async {
    await _indexTestUnit('''
class M {}
class A = B with M;
class B = A with M;
void useConstructor() {
  A();
  B();
}
''');
    assertErrorsInResult([
      error(diag.recursiveInterfaceInheritance, 17, 1),
      error(diag.classUsedAsMixin, 28, 1),
      error(diag.recursiveInterfaceInheritance, 37, 1),
      error(diag.classUsedAsMixin, 48, 1),
    ]);
    // No additional validation, but it should not fail with stack overflow.
  }

  test_ConstructorElement_enum_named_newHead() async {
    await _indexTestUnit('''
/// [new E.foo] and [E.foo]
enum E {
  v.foo();
  const new foo();
  const new bar() : this.foo();
  const factory baz() = E.foo;
}
void useConstructor() {
  E.foo();
  E.foo;
  E a = .foo();
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.unusedElement, 79, 3),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 123, 5),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 158, 5),
      error(diag.invalidReferenceToGenerativeEnumConstructorTearoff, 169, 5),
      error(diag.unusedLocalVariable, 180, 1),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 185, 3),
    ]);
    var element = findElement2.constructor('foo');
    assertElementIndexText(element, r'''
10 1:11 |.foo| IS_REFERENCED_BY qualified
22 1:23 |.foo| IS_REFERENCED_BY qualified
40 3:4 |.foo| IS_INVOKED_BY qualified
91 5:25 |.foo| IS_INVOKED_BY qualified
124 6:26 |.foo| IS_REFERENCED_BY qualified
159 9:4 |.foo| IS_INVOKED_BY qualified
170 10:4 |.foo| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
185 11:10 |foo| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_enum_named_primary() async {
    await _indexTestUnit('''
/// [new E.foo] and [E.foo]
enum E.foo() {
  v.foo();
  const new bar() : this.foo();
  const factory baz() = E.foo;
}
void useConstructor() {
  E.foo();
  E.foo;
  E a = .foo();
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.unusedElement, 66, 3),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 110, 5),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 145, 5),
      error(diag.invalidReferenceToGenerativeEnumConstructorTearoff, 156, 5),
      error(diag.unusedLocalVariable, 167, 1),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 172, 3),
    ]);
    var element = findElement2.constructor('foo');
    assertElementIndexText(element, r'''
10 1:11 |.foo| IS_REFERENCED_BY qualified
22 1:23 |.foo| IS_REFERENCED_BY qualified
46 3:4 |.foo| IS_INVOKED_BY qualified
78 4:25 |.foo| IS_INVOKED_BY qualified
111 5:26 |.foo| IS_REFERENCED_BY qualified
146 8:4 |.foo| IS_INVOKED_BY qualified
157 9:4 |.foo| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
172 10:10 |foo| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_enum_named_typeName() async {
    await _indexTestUnit('''
/// [new E.foo] and [E.foo]
enum E {
  v.foo();
  const E.foo();
  const E.bar() : this.foo();
  const factory E.baz() = E.foo;
}
void useConstructor() {
  E.foo();
  E.foo;
  E a = .foo();
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.unusedElement, 75, 3),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 121, 5),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 156, 5),
      error(diag.invalidReferenceToGenerativeEnumConstructorTearoff, 167, 5),
      error(diag.unusedLocalVariable, 178, 1),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 183, 3),
    ]);
    var element = findElement2.constructor('foo');
    assertElementIndexText(element, r'''
10 1:11 |.foo| IS_REFERENCED_BY qualified
22 1:23 |.foo| IS_REFERENCED_BY qualified
40 3:4 |.foo| IS_INVOKED_BY qualified
87 5:23 |.foo| IS_INVOKED_BY qualified
122 6:28 |.foo| IS_REFERENCED_BY qualified
157 9:4 |.foo| IS_INVOKED_BY qualified
168 10:4 |.foo| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
183 11:10 |foo| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_enum_unnamed_implicit() async {
    await _indexTestUnit('''
/// [new E] and [E.new]
enum E {
  v1,
  v2(),
  v3.new();
  const factory E.other() = E;
}
void useConstructor() {
  E();
  E.new;
  E a = .new();
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 87, 1),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 118, 1),
      error(diag.invalidReferenceToGenerativeEnumConstructorTearoff, 125, 5),
      error(diag.unusedLocalVariable, 136, 1),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 141, 3),
    ]);
    var element = findElement2.unnamedConstructor('E');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
18 1:19 |.new| IS_REFERENCED_BY qualified
37 3:5 || IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
43 4:5 || IS_INVOKED_BY qualified
51 5:5 |.new| IS_INVOKED_BY qualified
88 6:30 || IS_REFERENCED_BY qualified
119 9:4 || IS_INVOKED_BY qualified
126 10:4 |.new| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
141 11:10 |new| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_enum_unnamed_newHead() async {
    await _indexTestUnit('''
/// [new E] and [E.new]
enum E {
  v1,
  v2(),
  v3.new();
  const new ();
  const factory other() = E.new;
}
void useConstructor() {
  E();
  E.new;
  E a = .new();
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 101, 5),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 136, 1),
      error(diag.invalidReferenceToGenerativeEnumConstructorTearoff, 143, 5),
      error(diag.unusedLocalVariable, 154, 1),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 159, 3),
    ]);
    var element = findElement2.unnamedConstructor('E');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
18 1:19 |.new| IS_REFERENCED_BY qualified
37 3:5 || IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
43 4:5 || IS_INVOKED_BY qualified
51 5:5 |.new| IS_INVOKED_BY qualified
102 7:28 |.new| IS_REFERENCED_BY qualified
137 10:4 || IS_INVOKED_BY qualified
144 11:4 |.new| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
159 12:10 |new| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_enum_unnamed_primary() async {
    await _indexTestUnit('''
/// [new E] and [E.new]
enum E() {
  v1,
  v2(),
  v3.new();
  const factory other() = E.new;
}
void useConstructor() {
  E();
  E.new;
  E a = .new();
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 87, 5),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 122, 1),
      error(diag.invalidReferenceToGenerativeEnumConstructorTearoff, 129, 5),
      error(diag.unusedLocalVariable, 140, 1),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 145, 3),
    ]);
    var element = findElement2.unnamedConstructor('E');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
18 1:19 |.new| IS_REFERENCED_BY qualified
39 3:5 || IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
45 4:5 || IS_INVOKED_BY qualified
53 5:5 |.new| IS_INVOKED_BY qualified
88 6:28 |.new| IS_REFERENCED_BY qualified
123 9:4 || IS_INVOKED_BY qualified
130 10:4 |.new| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
145 11:10 |new| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_enum_unnamed_typeName() async {
    await _indexTestUnit('''
/// [new E] and [E.new]
enum E {
  v1,
  v2(),
  v3.new();
  const E();
  const factory E.other() = E;
}
void useConstructor() {
  E();
  E.new;
  E a = .new();
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 100, 1),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 131, 1),
      error(diag.invalidReferenceToGenerativeEnumConstructorTearoff, 138, 5),
      error(diag.unusedLocalVariable, 149, 1),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 154, 3),
    ]);
    var element = findElement2.unnamedConstructor('E');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
18 1:19 |.new| IS_REFERENCED_BY qualified
37 3:5 || IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
43 4:5 || IS_INVOKED_BY qualified
51 5:5 |.new| IS_INVOKED_BY qualified
101 7:30 || IS_REFERENCED_BY qualified
132 10:4 || IS_INVOKED_BY qualified
139 11:4 |.new| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
154 12:10 |new| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_enum_unnamed_typeName_explicitNew() async {
    await _indexTestUnit('''
/// [new E] and [E.new]
enum E {
  v1,
  v2(),
  v3.new();
  const E.new();
  const factory E.other() = E.new;
}
void useConstructor() {
  E();
  E.new;
  E a = .new();
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 104, 5),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 139, 1),
      error(diag.invalidReferenceToGenerativeEnumConstructorTearoff, 146, 5),
      error(diag.unusedLocalVariable, 157, 1),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 162, 3),
    ]);
    var element = findElement2.unnamedConstructor('E');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
18 1:19 |.new| IS_REFERENCED_BY qualified
37 3:5 || IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
43 4:5 || IS_INVOKED_BY qualified
51 5:5 |.new| IS_INVOKED_BY qualified
105 7:30 |.new| IS_REFERENCED_BY qualified
140 10:4 || IS_INVOKED_BY qualified
147 11:4 |.new| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
162 12:10 |new| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_extensionType_named_newHead() async {
    await _indexTestUnit('''
/// [new A.foo] and [A.foo]
extension type A(int it) {
  new foo(this.it);
  new bar() : this.foo(0);
  factory baz(int it) = A.foo;
}
void useConstructor() {
  A.foo(0);
  A.foo;
  A a = .foo(0);
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.unusedLocalVariable, 184, 1),
    ]);
    var element = findElement2.constructor('foo');
    assertElementIndexText(element, r'''
10 1:11 |.foo| IS_REFERENCED_BY qualified
22 1:23 |.foo| IS_REFERENCED_BY qualified
93 4:19 |.foo| IS_INVOKED_BY qualified
127 5:26 |.foo| IS_REFERENCED_BY qualified
162 8:4 |.foo| IS_INVOKED_BY qualified
174 9:4 |.foo| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
189 10:10 |foo| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_extensionType_named_primary() async {
    await _indexTestUnit('''
/// [new A.foo] and [A.foo]
extension type A.foo(int it) {
  new bar() : this.foo(0);
  factory baz(int it) = A.foo;
}
void useConstructor() {
  A.foo(0);
  A.foo;
  A a = .foo(0);
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.unusedLocalVariable, 168, 1),
    ]);
    var element = findElement2.constructor('foo');
    assertElementIndexText(element, r'''
10 1:11 |.foo| IS_REFERENCED_BY qualified
22 1:23 |.foo| IS_REFERENCED_BY qualified
77 3:19 |.foo| IS_INVOKED_BY qualified
111 4:26 |.foo| IS_REFERENCED_BY qualified
146 7:4 |.foo| IS_INVOKED_BY qualified
158 8:4 |.foo| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
173 9:10 |foo| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_extensionType_named_typeName() async {
    await _indexTestUnit('''
/// [new A.foo] and [A.foo]
extension type A(int it) {
  A.foo(this.it);
  A.bar() : this.foo(0);
  factory A.baz(int it) = A.foo;
}
void useConstructor() {
  A.foo(0);
  A.foo;
  A a = .foo(0);
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.unusedLocalVariable, 182, 1),
    ]);
    var element = findElement2.constructor('foo');
    assertElementIndexText(element, r'''
10 1:11 |.foo| IS_REFERENCED_BY qualified
22 1:23 |.foo| IS_REFERENCED_BY qualified
89 4:17 |.foo| IS_INVOKED_BY qualified
125 5:28 |.foo| IS_REFERENCED_BY qualified
160 8:4 |.foo| IS_INVOKED_BY qualified
172 9:4 |.foo| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
187 10:10 |foo| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_extensionType_unnamed_newHead() async {
    await _indexTestUnit('''
/// [new A] and [A.new]
extension type A.named(int it) {
  new (this.it);
  new bar() : this(0);
  factory baz(int it) = A.new;
}
void useConstructor() {
  A(0);
  A.new;
  A a = .new(0);
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.unusedLocalVariable, 175, 1),
    ]);
    var element = findElement2.unnamedConstructor('A');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
18 1:19 |.new| IS_REFERENCED_BY qualified
92 4:19 || IS_INVOKED_BY qualified
122 5:26 |.new| IS_REFERENCED_BY qualified
157 8:4 || IS_INVOKED_BY qualified
165 9:4 |.new| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
180 10:10 |new| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_extensionType_unnamed_primary() async {
    await _indexTestUnit('''
/// [new A] and [A.new]
extension type A(int it) {
  new bar() : this(0);
  factory baz(int it) = A.new;
}
void useConstructor() {
  A(0);
  A.new;
  A a = .new(0);
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.unusedLocalVariable, 152, 1),
    ]);
    var element = findElement2.unnamedConstructor('A');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
18 1:19 |.new| IS_REFERENCED_BY qualified
69 3:19 || IS_INVOKED_BY qualified
99 4:26 |.new| IS_REFERENCED_BY qualified
134 7:4 || IS_INVOKED_BY qualified
142 8:4 |.new| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
157 9:10 |new| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_extensionType_unnamed_typeName() async {
    await _indexTestUnit('''
/// [new A] and [A.new]
extension type A.named(int it) {
  A(this.it);
  A.bar() : this(0);
  factory A.baz(int it) = A.new;
}
void useConstructor() {
  A(0);
  A.new;
  A a = .new(0);
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.unusedLocalVariable, 172, 1),
    ]);
    var element = findElement2.unnamedConstructor('A');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
18 1:19 |.new| IS_REFERENCED_BY qualified
87 4:17 || IS_INVOKED_BY qualified
119 5:28 |.new| IS_REFERENCED_BY qualified
154 8:4 || IS_INVOKED_BY qualified
162 9:4 |.new| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
177 10:10 |new| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_ConstructorElement_extensionType_unnamed_typeName_explicitNew() async {
    await _indexTestUnit('''
/// [new A] and [A.new]
extension type A.named(int it) {
  A.new(this.it);
  A.bar() : this.new(0);
  factory A.baz(int it) = A.new;
}
void useConstructor() {
  A.new(0);
  A.new;
  A a = .new(0);
}
''');
    assertErrorsInResult([
      error(diag.deprecatedNewInCommentReference, 5, 3),
      error(diag.unusedLocalVariable, 184, 1),
    ]);
    var element = findElement2.unnamedConstructor('A');
    assertElementIndexText(element, r'''
10 1:11 || IS_REFERENCED_BY qualified
18 1:19 |.new| IS_REFERENCED_BY qualified
91 4:17 |.new| IS_INVOKED_BY qualified
127 5:28 |.new| IS_REFERENCED_BY qualified
162 8:4 |.new| IS_INVOKED_BY qualified
174 9:4 |.new| IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
189 10:10 |new| IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
''');
  }

  test_DynamicElement() async {
    await _indexTestUnit('''
dynamic f() {}
''');
    expect(index.usedElementOffsets, isEmpty);
  }

  test_EnumElement_reference_annotation() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

enum E {
  v;
  const E();
  const E.named();
  static const int myConstant = 0;
}

@E()
@p.E()
@E.named()
@p.E.named()
@E.myConstant
@p.E.myConstant
void f() {}
''');
    assertErrorsInResult([]);

    var element = findElement2.enum_('E');
    assertElementIndexText(element, r'''
48 5:9 |E| IS_REFERENCED_BY
61 6:9 |E| IS_REFERENCED_BY
111 10:2 |E| IS_REFERENCED_BY
118 11:4 |E| IS_REFERENCED_BY qualified
123 12:2 |E| IS_REFERENCED_BY
136 13:4 |E| IS_REFERENCED_BY qualified
147 14:2 |E| IS_REFERENCED_BY
163 15:4 |E| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_EnumElement_reference_comment() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

enum E { v }

/// [E] and [p.E].
void f() {}
''');
    assertErrorsInResult([]);

    var element = findElement2.enum_('E');
    assertElementIndexText(element, r'''
45 5:6 |E| IS_REFERENCED_BY
55 5:16 |E| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_EnumElement_reference_instanceCreation() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

enum E {
  v;
  const E();
}

void f() {
  const E();
  const p.E();
}
''');
    assertErrorsInResult([
      error(diag.invalidReferenceToGenerativeEnumConstructor, 75, 1),
      error(diag.invalidReferenceToGenerativeEnumConstructor, 88, 3),
    ]);

    var element = findElement2.enum_('E');
    assertElementIndexText(element, r'''
48 5:9 |E| IS_REFERENCED_BY
75 9:9 |E| IS_REFERENCED_BY
90 10:11 |E| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_EnumElement_reference_memberAccess() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

enum E {
  v;
  static void foo() {}
}

void f() {
  E.foo();
  p.E.foo();
}
''');
    assertErrorsInResult([]);

    var element = findElement2.enum_('E');
    assertElementIndexText(element, r'''
79 9:3 |E| IS_REFERENCED_BY
92 10:5 |E| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_EnumElement_reference_namedType() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

enum E { v }

void f() {
  E v1;
  p.E v2;
}
''');
    assertErrorsInResult([
      error(diag.unusedLocalVariable, 55, 2),
      error(diag.unusedLocalVariable, 65, 2),
    ]);

    var element = findElement2.enum_('E');
    assertElementIndexText(element, r'''
53 6:3 |E| IS_REFERENCED_BY
63 7:5 |E| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ExtensionElement_reference_memberAccess() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

extension E on int {
  static void foo() {}
}

void f() {
  E.foo();
  p.E.foo();
}
''');
    assertErrorsInResult([]);

    var element = findElement2.extension_('E');
    assertElementIndexText(element, r'''
86 8:3 |E| IS_REFERENCED_BY
99 9:5 |E| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ExtensionElement_reference_override() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

extension E on int {
  void foo() {}
}

void f() {
  E(0).foo();
  p.E(0).foo();
}
''');
    assertErrorsInResult([]);

    var element = findElement2.extension_('E');
    assertElementIndexText(element, r'''
79 8:3 |E| IS_REFERENCED_BY
95 9:5 |E| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ExtensionTypeElement_hierarchy_extensionType_implements() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

extension type A(int it) {}

extension type B(int it) implements A {}
extension type B_q(int it) implements p.A {}
''');
    assertErrorsInResult([]);

    var element = findElement2.extensionType('A');
    assertElementIndexText(element, r'''
91 5:37 |A| IS_IMPLEMENTED_BY
91 5:37 |A| IS_REFERENCED_BY
136 6:41 |A| IS_IMPLEMENTED_BY qualified
136 6:41 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ExtensionTypeElement_reference_annotation() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

extension type const A(int it) {}

@A(0)
@p.A(0)
void f() {}
''');
    assertErrorsInResult([]);

    var element = findElement2.extensionType('A');
    assertElementIndexText(element, r'''
62 5:2 |A| IS_REFERENCED_BY
70 6:4 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ExtensionTypeElement_reference_comment() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

extension type A(int it) {}

/// [A] and [p.A].
void f() {}
''');
    assertErrorsInResult([]);

    var element = findElement2.extensionType('A');
    assertElementIndexText(element, r'''
60 5:6 |A| IS_REFERENCED_BY
70 5:16 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ExtensionTypeElement_reference_instanceCreation() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

extension type A(int it) {}

void f() {
  A(0);
  p.A(0);
}
''');
    assertErrorsInResult([]);

    var element = findElement2.extensionType('A');
    assertElementIndexText(element, r'''
68 6:3 |A| IS_REFERENCED_BY
78 7:5 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ExtensionTypeElement_reference_memberAccess() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

extension type A(int it) {
  static void foo() {}
}

void f() {
  A.foo();
  p.A.foo();
}
''');
    assertErrorsInResult([]);

    var element = findElement2.extensionType('A');
    assertElementIndexText(element, r'''
92 8:3 |A| IS_REFERENCED_BY
105 9:5 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ExtensionTypeElement_reference_namedType() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

extension type A(int it) {}

void f() {
  A v1;
  p.A v2;
}
''');
    assertErrorsInResult([
      error(diag.unusedLocalVariable, 70, 2),
      error(diag.unusedLocalVariable, 80, 2),
    ]);

    var element = findElement2.extensionType('A');
    assertElementIndexText(element, r'''
68 6:3 |A| IS_REFERENCED_BY
78 7:5 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_FieldElement_ofClass_instance() async {
    await _indexTestUnit('''
/// [foo] and [A.foo]
class A {
  int foo;
  A({this.foo});
  A.foo() : foo = 0;

  void useField() {
    foo;
    foo = 0;
    this.foo;
    this.foo = 0;
  }
}

void useField(A a) {
  a.foo;
  a.foo = 0;
  A(foo: 0);
}
''');

    var field = findElement2.class_('A').getField('foo')!;
    assertElementIndexText(field, r'''
53 4:11 |foo| IS_WRITTEN_BY qualified
72 5:13 |foo| IS_WRITTEN_BY qualified
''');

    assertElementIndexText(field.getter!, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
106 8:5 |foo| IS_REFERENCED_BY
133 10:10 |foo| IS_REFERENCED_BY qualified
188 16:5 |foo| IS_REFERENCED_BY qualified
''');

    assertElementIndexText(field.setter!, r'''
115 9:5 |foo| IS_REFERENCED_BY
147 11:10 |foo| IS_REFERENCED_BY qualified
197 17:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_FieldElement_ofClass_instance_synthetic_hasGetter() async {
    await _indexTestUnit('''
class A {
  A() : foo = 0;
  int get foo => 0;
}
''');
    var element = findElement2.field('foo');
    assertElementIndexText(element, r'''
18 2:9 |foo| IS_WRITTEN_BY qualified
''');
  }

  test_FieldElement_ofClass_instance_synthetic_hasGetterSetter() async {
    await _indexTestUnit('''
class A {
  A() : foo = 0;
  int get foo => 0;
  set foo(_) {}
}
''');
    var element = findElement2.field('foo');
    assertElementIndexText(element, r'''
18 2:9 |foo| IS_WRITTEN_BY qualified
''');
  }

  test_FieldElement_ofClass_instance_synthetic_hasSetter() async {
    await _indexTestUnit('''
class A {
  A() : foo = 0;
  set foo(_) {}
}
''');
    var element = findElement2.field('foo');
    assertElementIndexText(element, r'''
18 2:9 |foo| IS_WRITTEN_BY qualified
''');
  }

  test_FieldElement_ofClass_static() async {
    await _indexTestUnit('''
/// [foo] and [A.foo]
class A {
  static int foo = 0;
  static void useField() {
    foo;
    foo = 0;
    A.foo;
    A.foo = 0;
  }
}

void useField() {
  A.foo;
  A.foo = 0;
  A a = .foo;
}
''');

    var field = findElement2.class_('A').getField('foo')!;

    assertElementIndexText(field.getter!, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
85 5:5 |foo| IS_REFERENCED_BY
109 7:7 |foo| IS_REFERENCED_BY qualified
158 13:5 |foo| IS_REFERENCED_BY qualified
185 15:10 |foo| IS_REFERENCED_BY qualified
''');

    assertElementIndexText(field.setter!, r'''
94 6:5 |foo| IS_REFERENCED_BY
120 8:7 |foo| IS_REFERENCED_BY qualified
167 14:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_FieldElement_ofEnum_instance() async {
    await _indexTestUnit('''
/// [foo] and [E.foo]
enum E {
  v;
  int? foo; // a compile-time error
  E({this.foo});
  void useField() {
    foo;
    foo = 0;
  }
}
void useField(E e) {
  e.foo;
  e.foo = 0;
  E(foo: 0);
}
''');
    var field = findElement2.field('foo');
    var getter = field.getter!;
    var setter = field.setter!;

    assertElementIndexText(field, r'''
82 5:11 |foo| IS_WRITTEN_BY qualified
''');

    assertElementIndexText(getter, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
113 7:5 |foo| IS_REFERENCED_BY
162 12:5 |foo| IS_REFERENCED_BY qualified
''');

    assertElementIndexText(setter, r'''
122 8:5 |foo| IS_REFERENCED_BY
171 13:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_FieldElement_ofEnum_instance_index() async {
    await _indexTestUnit('''
enum MyEnum {
  v1, v2, v3
}
void f() {
  MyEnum.values;
  MyEnum.v1.index;
  MyEnum.v1;
  MyEnum.v2;
}
''');

    var index = typeProvider.enumElement!.getGetter('index')!;
    assertElementIndexText(index, r'''
69 6:13 |index| IS_REFERENCED_BY qualified
''');
  }

  test_FieldElement_ofEnum_instance_synthetic_hasGetter() async {
    await _indexTestUnit('''
enum E {
  v;
  E() : foo = 0;
  int get foo => 0;
}
''');
    var element = findElement2.field('foo');
    assertElementIndexText(element, r'''
22 3:9 |foo| IS_WRITTEN_BY qualified
''');
  }

  test_FieldElement_ofEnum_instance_synthetic_hasGetterSetter() async {
    await _indexTestUnit('''
enum E {
  v;
  E() : foo = 0;
  int get foo => 0;
  set foo(_) {}
}
''');
    var element = findElement2.field('foo');
    assertElementIndexText(element, r'''
22 3:9 |foo| IS_WRITTEN_BY qualified
''');
  }

  test_FieldElement_ofEnum_instance_synthetic_hasSetter() async {
    await _indexTestUnit('''
enum E {
  v;
  E() : foo = 0;
  set foo(_) {}
}
''');
    var element = findElement2.field('foo');
    assertElementIndexText(element, r'''
22 3:9 |foo| IS_WRITTEN_BY qualified
''');
  }

  test_FieldElement_ofEnum_static_constants() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

/// [v1], [MyEnum.v1], and [p.MyEnum.v1]
enum MyEnum {
  v1, v2, v3
}
void f() {
  MyEnum.values;
  MyEnum.v1.index;
  MyEnum.v1;
  MyEnum.v2;
  p.MyEnum.v1;
  p.MyEnum.values;
}
''');

    assertElementIndexText(findElement2.getter('values'), r'''
116 8:10 |values| IS_REFERENCED_BY qualified
195 13:12 |values| IS_REFERENCED_BY qualified
''');

    assertElementIndexText(findElement2.getter('v1'), r'''
31 3:6 |v1| IS_REFERENCED_BY
44 3:19 |v1| IS_REFERENCED_BY qualified
63 3:38 |v1| IS_REFERENCED_BY qualified
133 9:10 |v1| IS_REFERENCED_BY qualified
152 10:10 |v1| IS_REFERENCED_BY qualified
180 12:12 |v1| IS_REFERENCED_BY qualified
''');

    assertElementIndexText(findElement2.getter('v2'), r'''
165 11:10 |v2| IS_REFERENCED_BY qualified
''');
  }

  test_FieldElement_ofExtensionType_static() async {
    await _indexTestUnit('''
/// [foo] and [A.foo]
extension type A(int it) {
  static int foo = 0;
  void useField() {
    foo;
    foo = 0;
  }
}
void useField() {
  A.foo;
  A.foo = 0;
}
''');
    var field = findElement2.field('foo');
    var getter = field.getter!;
    var setter = field.setter!;

    assertElementIndexText(getter, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
95 5:5 |foo| IS_REFERENCED_BY
141 10:5 |foo| IS_REFERENCED_BY qualified
''');

    assertElementIndexText(setter, r'''
104 6:5 |foo| IS_REFERENCED_BY
150 11:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_fieldFormalParameter_noSuchField() async {
    await _indexTestUnit('''
class B<T> {
  B({this.x}) {}

  foo() {
    B<int>(x: 1);
  }
}
''');
    // No exceptions.
  }

  test_FieldFormalParameterElement_ofConstructor_optionalNamed_dotShorthand() async {
    await _indexTestUnit('''
class A {
  A({this.test}) : assert(test != null);
  int? test;
}
void foo() {
  A _ = .new(test: 0);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.fieldFormalParameter('test');
    assertElementIndexText(element, r'''
92 6:14 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_multiplyDefined_generic() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo<T>({T? test}) {}
''');
    newFile('$testPackageLibPath/b.dart', r'''
void foo<T>({T? test}) {}
''');
    await _indexTestUnit(r"""
import 'a.dart';
import 'b.dart';

void f() {
  foo(test: 0);
}
""");
    // No exceptions.
    assertErrorsInResult([error(diag.ambiguousImport, 48, 3)]);
  }

  test_FormalParameterElement_ofConstructor_primary_optionalNamed() async {
    await _indexTestUnit('''
/// [test]
class A({int? test}) {
  this : assert(test != null) {
    test;
  }

  A.redirect({int? test}) : this(test: test);
}

class B extends A {
  B({super.test});
}

class C extends A {
  C({int? test}) : super(test: test);
}

void f() {
  A(test: 0);
  A _ = .new(test: 0);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.unnamedConstructor('A').parameter('test');
    assertElementIndexText(element, r'''
114 7:34 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
161 11:12 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
217 15:26 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
248 19:5 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
271 20:14 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofConstructor_primary_optionalNamed_genericClass() async {
    await _indexTestUnit('''
/// [test]
class A<T>({T? test}) {
  this : assert(test != null) {
    test;
  }

  A.redirect({T? test}) : this(test: test);
}

class B<T> extends A<T> {
  B({super.test});
}

class C<T> extends A<T> {
  C({T? test}) : super(test: test);
}

void f() {
  A(test: 0);
  A<int> _ = .new(test: 0);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.unnamedConstructor('A').parameter('test');
    assertElementIndexText(element, r'''
113 7:32 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
166 11:12 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
226 15:24 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
257 19:5 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
285 20:19 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofConstructor_primary_optionalPositional() async {
    await _indexTestUnit('''
/// [test]
class A([int? test]) {
  this : assert(test != null) {
    test;
  }

  A.redirect([int? test]) : this(test);
}

class B extends A {
  B([super.test]);
}

class C extends A {
  C([int? test]) : super(test);
}

void f() {
  A(0);
  A _ = .new(0);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.unnamedConstructor('A').parameter('test');
    assertElementIndexText(element, r'''
155 11:12 |test| IS_REFERENCED_BY qualified
''');
  }

  test_FormalParameterElement_ofConstructor_primary_requiredNamed() async {
    await _indexTestUnit('''
/// [test]
class A({required int test}) {
  this : assert(test != -1) {
    test;
  }

  A.redirect({required int test}) : this(test: test);
}

class B extends A {
  B({required super.test});
}

class C extends A {
  C({required int test}) : super(test: test);
}

void f() {
  A(test: 0);
  A _ = .new(test: 0);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.unnamedConstructor('A').parameter('test');
    assertElementIndexText(element, r'''
128 7:42 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
184 11:21 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
248 15:34 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
279 19:5 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
302 20:14 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofConstructor_primary_requiredPositional() async {
    await _indexTestUnit('''
/// [test]
class A(int test) {
  this : assert(test != -1) {
    test;
  }

  A.redirect(int test) : this(test);
}

class B extends A {
  B(super.test);
}

class C extends A {
  C(int test) : super(test);
}

void f() {
  A(0);
  A _ = .new(0);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.unnamedConstructor('A').parameter('test');
    assertElementIndexText(element, r'''
146 11:11 |test| IS_REFERENCED_BY qualified
''');
  }

  test_FormalParameterElement_ofConstructor_typeName_optionalNamed() async {
    await _indexTestUnit('''
class A {
  /// [test]
  A({int? test}) : assert(test != null) {
    test;
  }

  A.redirect({int? test}) : this(test: test);
}

class B extends A {
  B({super.test});
}

class C extends A {
  C({int? test}) : super(test: test);
}

void f() {
  A(test: 0);
  A _ = .new(test: 0);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.unnamedConstructor('A').parameter('test');
    assertElementIndexText(element, r'''
113 7:34 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
160 11:12 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
216 15:26 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
247 19:5 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
270 20:14 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofConstructor_typeName_optionalNamed_genericClass() async {
    await _indexTestUnit('''
class A<T> {
  /// [test]
  A({T? test}) : assert(test != null) {
    test;
  }

  A.redirect({T? test}) : this(test: test);
}

class B<T> extends A<T> {
  B({super.test});
}

class C<T> extends A<T> {
  C({T? test}) : super(test: test);
}

void f() {
  A(test: 0);
  A<int> _ = .new(test: 0);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.unnamedConstructor('A').parameter('test');
    assertElementIndexText(element, r'''
112 7:32 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
165 11:12 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
225 15:24 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
256 19:5 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
284 20:19 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofConstructor_typeName_optionalPositional() async {
    await _indexTestUnit('''
class A {
  /// [test]
  A([int? test]) : assert(test != null) {
    test;
  }

  A.redirect([int? test]) : this(test);
}

class B extends A {
  B([super.test]);
}

class C extends A {
  C([int? test]) : super(test);
}

void f() {
  A(0);
  A _ = .new(0);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.unnamedConstructor('A').parameter('test');
    assertElementIndexText(element, r'''
154 11:12 |test| IS_REFERENCED_BY qualified
''');
  }

  test_FormalParameterElement_ofConstructor_typeName_requiredNamed() async {
    await _indexTestUnit('''
class A {
  /// [test]
  A({required int test}) : assert(test != -1) {
    test;
  }

  A.redirect({required int test}) : this(test: test);
}

class B extends A {
  B({required super.test});
}

class C extends A {
  C({required int test}) : super(test: test);
}

void f() {
  A(test: 0);
  A _ = .new(test: 0);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.unnamedConstructor('A').parameter('test');
    assertElementIndexText(element, r'''
127 7:42 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
183 11:21 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
247 15:34 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
278 19:5 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
301 20:14 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofConstructor_typeName_requiredPositional() async {
    await _indexTestUnit('''
class A {
  /// [test]
  A(int test) : assert(test != -1) {
    test;
  }

  A.redirect(int test) : this(test);
}

class B extends A {
  B(super.test);
}

class C extends A {
  C(int test) : super(test);
}

void f() {
  A(0);
  A _ = .new(0);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.unnamedConstructor('A').parameter('test');
    assertElementIndexText(element, r'''
145 11:11 |test| IS_REFERENCED_BY qualified
''');
  }

  test_FormalParameterElement_ofGenericFunctionType_optionalNamed() async {
    await _indexTestUnit('''
typedef F = void Function({int? test});

void g(F f) {
  f(test: 0);
}
''');
    // We should not crash because of reference to "test" - a named parameter
    // of a generic function type.
    assertErrorsInResult([]);
  }

  test_FormalParameterElement_ofGenericFunctionType_optionalNamed_call() async {
    await _indexTestUnit('''
typedef F<T> = void Function({T? test});

void g(F<int> f) {
  f.call(test: 0);
}
''');
    // No exceptions.
    assertErrorsInResult([]);
  }

  test_FormalParameterElement_ofLocalFunction_optionalNamed() async {
    await _indexTestUnit('''
void f() {
  void foo({int? test}) {
    test;
    test = 1;
    test += 2;
  }

  foo(test: 0);
  foo.call(test: 1);
  (foo)(test: 2);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.parameter('test');
    assertElementIndexText(element, r'''
''');
  }

  test_FormalParameterElement_ofLocalFunction_optionalPositional() async {
    await _indexTestUnit('''
void f() {
  void foo([int? test]) {
    test;
    test = 1;
    test += 2;
  }

  foo(0);
  foo.call(1);
  (foo)(2);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.parameter('test');
    assertElementIndexText(element, r'''
''');
  }

  test_FormalParameterElement_ofLocalFunction_requiredNamed() async {
    await _indexTestUnit('''
void f() {
  void foo({required int test}) {
    test;
    test = 1;
    test += 2;
  }

  foo(test: 0);
  foo.call(test: 1);
  (foo)(test: 2);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.parameter('test');
    assertElementIndexText(element, r'''
''');
  }

  test_FormalParameterElement_ofLocalFunction_requiredPositional() async {
    await _indexTestUnit('''
void f() {
  void foo(int test) {
    test;
    test = 1;
    test += 2;
  }

  foo(0);
  foo.call(1);
  (foo)(2);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.parameter('test');
    assertElementIndexText(element, r'''
''');
  }

  test_FormalParameterElement_ofMethod_optionalNamed() async {
    await _indexTestUnit('''
class A {
  /// [test]
  void foo({int? test}) {
    test;
    test = 1;
    test += 2;
  }
}

void f(A a) {
  a.foo(test: 0);
  a.foo.call(test: 1);
  (a.foo)(test: 2);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.parameter('test');
    assertElementIndexText(element, r'''
117 11:9 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
140 12:14 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
160 13:11 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofMethod_optionalNamed_genericClass() async {
    await _indexTestUnit('''
class A<T> {
  /// [test]
  void foo({T? test}) {
    test;
    test = null;
    test = test;
  }
}

void f(A<int> a) {
  a.foo(test: 0);
  a.foo.call(test: 1);
  (a.foo)(test: 2);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.parameter('test');
    assertElementIndexText(element, r'''
128 11:9 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofMethod_optionalPositional() async {
    await _indexTestUnit('''
class A {
  /// [test]
  void foo([int? test]) {
    test;
    test = 1;
    test += 2;
  }
}

void f(A a) {
  a.foo(0);
  a.foo.call(1);
  (a.foo)(2);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.parameter('test');
    assertElementIndexText(element, r'''
''');
  }

  test_FormalParameterElement_ofMethod_requiredNamed() async {
    await _indexTestUnit('''
class A {
  /// [test]
  void foo({required int test}) {
    test;
    test = 1;
    test += 2;
  }
}

void f(A a) {
  a.foo(test: 0);
  a.foo.call(test: 1);
  (a.foo)(test: 2);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.parameter('test');
    assertElementIndexText(element, r'''
125 11:9 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
148 12:14 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
168 13:11 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofMethod_requiredPositional() async {
    await _indexTestUnit('''
class A {
  /// [test]
  void foo(int test) {
    test;
    test = 1;
    test += 2;
  }
}

void f(A a) {
  a.foo(0);
  a.foo.call(1);
  (a.foo)(2);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.parameter('test');
    assertElementIndexText(element, r'''
''');
  }

  test_FormalParameterElement_ofTopLevelFunction_optionalNamed() async {
    await _indexTestUnit('''
/// [test]
void foo({int? test}) {
  test;
  test = 1;
  test += 2;
}
void f() {
  foo(test: 0);
  foo.call(test: 1);
  (foo)(test: 2);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.parameter('test');
    assertElementIndexText(element, r'''
87 8:7 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
108 9:12 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
126 10:9 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofTopLevelFunction_optionalNamed_argumentAnywhere() async {
    await _indexTestUnit('''
/// [test]
void foo(int a, int b, {int? test}) {
  test;
  test = 1;
  test += 2;
}

void f() {
  foo(0, test: 0, 0);
  foo.call(0, test: 1, 0);
  (foo)(0, test: 2, 0);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.parameter('test');
    assertElementIndexText(element, r'''
105 9:10 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
132 10:15 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
156 11:12 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofTopLevelFunction_optionalPositional() async {
    await _indexTestUnit('''
/// [test]
void foo([int? test]) {
  test;
  test = 1;
  test += 2;
}
void f() {
  foo(0);
  foo.call(1);
  (foo)(2);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.parameter('test');
    assertElementIndexText(element, r'''
''');
  }

  test_FormalParameterElement_ofTopLevelFunction_requiredNamed() async {
    await _indexTestUnit('''
/// [test]
void foo({required int test}) {
  test;
  test = 1;
  test += 2;
}

void f() {
  foo(test: 0);
  foo.call(test: 1);
  (foo)(test: 2);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.parameter('test');
    assertElementIndexText(element, r'''
96 9:7 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
117 10:12 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
135 11:9 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofTopLevelFunction_requiredPositional() async {
    await _indexTestUnit('''
/// [test]
void foo(int test) {
  test;
  test = 1;
  test += 2;
}

void f() {
  foo(0);
  foo.call(1);
  (foo)(2);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.parameter('test');
    assertElementIndexText(element, r'''
''');
  }

  test_FormalParameterElement_synthetic_leastUpperBound() async {
    await _indexTestUnit('''
int f1({int? test}) => 0;
int f2({int? test}) => 0;
void g(bool b) {
  var f = b ? f1 : f2;
  f(test: 0);
}''');
    // We should not crash because of reference to "test" - a named parameter
    // of a synthetic LUB FunctionElement created for "f".
    assertErrorsInResult([]);
  }

  test_GetterElement_ofClass_instance() async {
    await _indexTestUnit('''
/// [foo] and [A.foo]
class A {
  int get foo => 0;
  void useGetter() {
    foo;
    this.foo;
  }
}

void useGetter(A a) {
  a.foo;
}
''');
    var element = findElement2.getter('foo');
    assertElementIndexText(element, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
77 5:5 |foo| IS_REFERENCED_BY
91 6:10 |foo| IS_REFERENCED_BY qualified
129 11:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_GetterElement_ofClass_invocation() async {
    await _indexTestUnit('''
class A {
  get foo => null;
  void useGetter() {
    this.foo();
    foo();
  }
}''');
    var element = findElement2.getter('foo');
    assertElementIndexText(element, r'''
59 4:10 |foo| IS_REFERENCED_BY qualified
70 5:5 |foo| IS_REFERENCED_BY
''');
  }

  test_GetterElement_ofClass_objectPattern() async {
    await _indexTestUnit('''
class A {
  int get foo => 0;
}

void useGetter(Object? x) {
  if (x case A(foo: 0)) {}
  if (x case A(: var foo)) {}
}
''');
    var element = findElement2.getter('foo');
    assertElementIndexText(element, r'''
76 6:16 |foo| IS_REFERENCED_BY_PATTERN_FIELD qualified
103 7:16 || IS_REFERENCED_BY_PATTERN_FIELD qualified
''');
  }

  test_GetterElement_ofClass_static() async {
    await _indexTestUnit('''
import 'test.dart' as p;

/// [foo], [A.foo], [p.A.foo]
class A {
  static int get foo => 0;
  static void useGetter() {
    foo;
  }
}

void useGetter() {
  A.foo;
  p.A.foo;
}
''');
    var element = findElement2.getter('foo');
    assertElementIndexText(element, r'''
31 3:6 |foo| IS_REFERENCED_BY
40 3:15 |foo| IS_REFERENCED_BY qualified
51 3:26 |foo| IS_REFERENCED_BY qualified
125 7:5 |foo| IS_REFERENCED_BY
160 12:5 |foo| IS_REFERENCED_BY qualified
171 13:7 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_LibraryFragment_reference_export() async {
    newFile('$testPackageLibPath/lib.dart', '');
    await _indexTestUnit('''
export 'lib.dart';
''');
    var export = findElement2.export('package:test/lib.dart');
    var fragment = export.exportedLibrary!.firstFragment;
    assertLibraryFragmentIndexText(fragment, r'''
7 1:8 |'lib.dart'|
''');
  }

  test_LibraryFragment_reference_import() async {
    newFile('$testPackageLibPath/lib.dart', '');
    await _indexTestUnit('''
import 'lib.dart';
''');
    var import = findElement2.import('package:test/lib.dart');
    var fragment = import.importedLibrary!.firstFragment;
    assertLibraryFragmentIndexText(fragment, r'''
7 1:8 |'lib.dart'|
''');
  }

  test_LibraryFragment_reference_part() async {
    newFile('$testPackageLibPath/my_unit.dart', "part of 'test.dart';");
    await _indexTestUnit('''
part 'my_unit.dart';
''');
    var fragment = findElement2.part('package:test/my_unit.dart');
    assertLibraryFragmentIndexText(fragment, r'''
5 1:6 |'my_unit.dart'|
''');
  }

  test_LibraryFragment_reference_part_inPart() async {
    newFile('$testPackageLibPath/a.dart', '''
part of 'b.dart';
''');
    newFile('$testPackageLibPath/b.dart', '''
library lib;
part 'a.dart';
''');
    await _indexTestUnit('''
part 'b.dart';
''');
    // No exception, even though a.dart is a part of b.dart part.
  }

  test_MethodElement_normal_ofClass_instance() async {
    await _indexTestUnit('''
/// [foo] and [A.foo]
class A {
  void foo() {}
  void useFoo(Object? x) {
    this.foo();
    foo();
    this.foo;
    foo;
    if (x case A(foo: _)) {}
    if (x case A(: var foo)) {}
  }
}
void useFoo(A a) {
  a.foo();
  a.foo;
}
''');
    var element = findElement2.method('foo');
    assertElementIndexText(element, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
84 5:10 |foo| IS_INVOKED_BY qualified
95 6:5 |foo| IS_INVOKED_BY
111 7:10 |foo| IS_REFERENCED_BY qualified
120 8:5 |foo| IS_REFERENCED_BY
142 9:18 |foo| IS_REFERENCED_BY_PATTERN_FIELD qualified
171 10:18 || IS_REFERENCED_BY_PATTERN_FIELD qualified
215 14:5 |foo| IS_INVOKED_BY qualified
226 15:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_MethodElement_normal_ofClass_static() async {
    await _indexTestUnit('''
import 'test.dart' as p;

/// [foo], [A.foo], [p.A.foo]
class A {
  static A foo() => A();
  static void useFoo() {
    foo();
    foo;
  }
}

void useFoo() {
  A.foo();
  A.foo;
  A a = .foo();
  p.A.foo();
  p.A.foo;
}
''');
    var element = findElement2.method('foo');
    assertElementIndexText(element, r'''
31 3:6 |foo| IS_REFERENCED_BY
40 3:15 |foo| IS_REFERENCED_BY qualified
51 3:26 |foo| IS_REFERENCED_BY qualified
120 7:5 |foo| IS_INVOKED_BY
131 8:5 |foo| IS_REFERENCED_BY
163 13:5 |foo| IS_INVOKED_BY qualified
174 14:5 |foo| IS_REFERENCED_BY qualified
188 15:10 |foo| IS_INVOKED_BY qualified
201 16:7 |foo| IS_INVOKED_BY qualified
214 17:7 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_MethodElement_normal_ofEnum_instance() async {
    await _indexTestUnit('''
/// [foo] and [E.foo]
enum E {
  v;
  void foo() {}
  void useFoo() {
    this.foo();
    foo();
    this.foo;
    foo;
  }
}
void useFoo(E e) {
  e.foo();
  e.foo;
}
''');
    var element = findElement2.method('foo');
    assertElementIndexText(element, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
79 6:10 |foo| IS_INVOKED_BY qualified
90 7:5 |foo| IS_INVOKED_BY
106 8:10 |foo| IS_REFERENCED_BY qualified
115 9:5 |foo| IS_REFERENCED_BY
149 13:5 |foo| IS_INVOKED_BY qualified
160 14:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_MethodElement_normal_ofEnum_static() async {
    await _indexTestUnit('''
/// [foo] and [E.foo]
enum E {
  v;
  static void foo() {}
  static void useFoo() {
    foo();
    foo;
  }
}
void useFoo() {
  E.foo();
  E.foo;
}
''');
    var element = findElement2.method('foo');
    assertElementIndexText(element, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
88 6:5 |foo| IS_INVOKED_BY
99 7:5 |foo| IS_REFERENCED_BY
130 11:5 |foo| IS_INVOKED_BY qualified
141 12:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_MethodElement_normal_ofExtension_named_instance() async {
    await _indexTestUnit('''
/// [foo] and [E.foo]
extension E on int {
  void foo() {}
}

void useFoo() {
  0.foo();
  0.foo;
}
''');
    var element = findElement2.method('foo');
    assertElementIndexText(element, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
82 7:5 |foo| IS_INVOKED_BY qualified
93 8:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_MethodElement_normal_ofExtension_named_static() async {
    await _indexTestUnit('''
/// [foo] and [E.foo]
extension E on int {
  static void foo() {}
}

void useFoo() {
  E.foo();
  E.foo;
}
''');
    var element = findElement2.method('foo');
    assertElementIndexText(element, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
89 7:5 |foo| IS_INVOKED_BY qualified
100 8:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_MethodElement_normal_ofExtension_unnamed_instance() async {
    await _indexTestUnit('''
/// [foo] and [int.foo]
extension on int {
  void foo() {} // int
}

/// [foo] and [double.foo]
extension on double {
  void foo() {} // double
}

void useFoo() {
  0.foo();
  0.foo;
  (1.2).foo();
  (1.2).foo;
}
''');

    var intMethod = findNode.methodDeclaration('foo() {} // int');
    assertElementIndexText(intMethod.declaredFragment!.element, r'''
5 1:6 |foo| IS_REFERENCED_BY
167 12:5 |foo| IS_INVOKED_BY qualified
178 13:5 |foo| IS_REFERENCED_BY qualified
''');

    var doubleMethod = findNode.methodDeclaration('foo() {} // double');
    assertElementIndexText(doubleMethod.declaredFragment!.element, r'''
74 6:6 |foo| IS_REFERENCED_BY
191 14:9 |foo| IS_INVOKED_BY qualified
206 15:9 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_MethodElement_normal_ofExtensionType_instance() async {
    await _indexTestUnit('''
/// [foo] and [A.foo]
extension type A(int it) {
  void foo() {}
  void useFoo() {
    this.foo();
    foo();
    this.foo;
    foo;
  }
}
void useFoo() {
  var a = A(0);
  a.foo();
  a.foo;
}
''');
    var element = findElement2.method('foo');
    assertElementIndexText(element, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
92 5:10 |foo| IS_INVOKED_BY qualified
103 6:5 |foo| IS_INVOKED_BY
119 7:10 |foo| IS_REFERENCED_BY qualified
128 8:5 |foo| IS_REFERENCED_BY
175 13:5 |foo| IS_INVOKED_BY qualified
186 14:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_MethodElement_normal_ofExtensionType_static() async {
    await _indexTestUnit('''
/// [foo] and [A.foo]
extension type A(int it) {
  static void foo() {}
  static void useFoo() {
    foo();
    foo;
  }
}
void useFoo() {
  A.foo();
  A.foo;
}
''');
    var element = findElement2.method('foo');
    assertElementIndexText(element, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
101 5:5 |foo| IS_INVOKED_BY
112 6:5 |foo| IS_REFERENCED_BY
143 10:5 |foo| IS_INVOKED_BY qualified
154 11:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_MethodElement_normal_ofMixin_instance() async {
    await _indexTestUnit('''
/// [foo] and [M.foo]
mixin M {
  void foo() {}
  void useFoo() {
    this.foo();
    foo();
    this.foo;
    foo;
  }
}
void useFoo(M m) {
  m.foo();
  m.foo;
}
''');
    var element = findElement2.method('foo');
    assertElementIndexText(element, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
75 5:10 |foo| IS_INVOKED_BY qualified
86 6:5 |foo| IS_INVOKED_BY
102 7:10 |foo| IS_REFERENCED_BY qualified
111 8:5 |foo| IS_REFERENCED_BY
145 12:5 |foo| IS_INVOKED_BY qualified
156 13:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_MethodElement_normal_ofMixin_static() async {
    await _indexTestUnit('''
/// [foo] and [M.foo]
mixin M {
  static void foo() {}
  static void useFoo() {
    foo();
    foo;
  }
}
void useFoo() {
  M.foo();
  M.foo;
  M m = .foo();
}
''');
    var element = findElement2.method('foo');
    assertElementIndexText(element, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
84 5:5 |foo| IS_INVOKED_BY
95 6:5 |foo| IS_REFERENCED_BY
126 10:5 |foo| IS_INVOKED_BY qualified
137 11:5 |foo| IS_REFERENCED_BY qualified
151 12:10 |foo| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofClass_binary() async {
    await _indexTestUnit('''
/// [operator +] and [A.operator +]
class A {
  operator +(other) => this;
}
void useOperator(A a) {
  a + 1;
  a += 2;
  ++a;
  a++;
}
''');
    var element = findElement2.method('+');
    assertElementIndexText(element, r'''
14 1:15 |+| IS_REFERENCED_BY
33 1:34 |+| IS_REFERENCED_BY qualified
105 6:5 |+| IS_INVOKED_BY qualified
114 7:5 |+=| IS_INVOKED_BY qualified
122 8:3 |++| IS_INVOKED_BY qualified
130 9:4 |++| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofClass_index() async {
    await _indexTestUnit('''
/// [operator []] and [A.operator []]
class A {
  operator [](i) => null;
}
void useOperator(A a) {
  a[0];
}
''');
    var element = findElement2.method('[]');
    assertElementIndexText(element, r'''
103 6:4 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofClass_indexEq() async {
    await _indexTestUnit('''
/// [operator []=] and [A.operator []=]
class A {
  operator []=(i, v) {}
}
void useOperator(A a) {
  a[1] = 42;
}
''');
    var element = findElement2.method('[]=');
    assertElementIndexText(element, r'''
103 6:4 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofClass_prefix() async {
    await _indexTestUnit('''
/// [operator ~] and [A.operator ~]
class A {
  A operator ~() => this;
}
void useOperator(A a) {
  ~a;
}
''');
    var element = findElement2.method('~');
    assertElementIndexText(element, r'''
14 1:15 |~| IS_REFERENCED_BY
33 1:34 |~| IS_REFERENCED_BY qualified
100 6:3 |~| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofEnum_binary() async {
    await _indexTestUnit('''
/// [operator +] and [E.operator +]
enum E {
  v;
  int operator +(other) => 0;
}
void useOperator(E e) {
  e + 1;
  e += 2;
  ++e;
  e++;
}
''');
    var element = findElement2.method('+');
    assertElementIndexText(element, r'''
14 1:15 |+| IS_REFERENCED_BY
33 1:34 |+| IS_REFERENCED_BY qualified
110 7:5 |+| IS_INVOKED_BY qualified
119 8:5 |+=| IS_INVOKED_BY qualified
127 9:3 |++| IS_INVOKED_BY qualified
135 10:4 |++| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofEnum_index() async {
    await _indexTestUnit('''
/// [operator []] and [E.operator []]
enum E {
  v;
  int operator [](int index) => 0;
}
void useOperator(E e) {
  e[0];
}
''');
    var element = findElement2.method('[]');
    assertElementIndexText(element, r'''
116 7:4 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofEnum_indexEq() async {
    await _indexTestUnit('''
/// [operator []=] and [E.operator []=]
enum E {
  v;
  operator []=(int index, int value) {}
}
void useOperator(E e) {
  e[1] = 42;
}
''');
    var element = findElement2.method('[]=');
    assertElementIndexText(element, r'''
123 7:4 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofEnum_prefix() async {
    await _indexTestUnit('''
/// [operator ~] and [E.operator ~]
enum E {
  e;
  int operator ~() => 0;
}
void useOperator(E e) {
  ~e;
}
''');
    var element = findElement2.method('~');
    assertElementIndexText(element, r'''
14 1:15 |~| IS_REFERENCED_BY
33 1:34 |~| IS_REFERENCED_BY qualified
103 7:3 |~| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofExtension_binary() async {
    await _indexTestUnit('''
/// [operator +] and [E.operator +]
extension E on int {
  int operator +(int other) => 0;
}
void useOperator(int e) {
  E(e) + 1;
}
''');
    var element = findElement2.method('+');
    assertElementIndexText(element, r'''
14 1:15 |+| IS_REFERENCED_BY
33 1:34 |+| IS_REFERENCED_BY qualified
126 6:8 |+| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofExtension_index() async {
    await _indexTestUnit('''
/// [operator []] and [E.operator []]
extension E on int {
  int operator [](int index) => 0;
}
void useOperator(int e) {
  E(e)[0];
}
''');
    var element = findElement2.method('[]');
    assertElementIndexText(element, r'''
128 6:7 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofExtension_indexEq() async {
    await _indexTestUnit('''
/// [operator []=] and [E.operator []=]
extension E on int {
  operator []=(int index, int value) {}
}
void useOperator(int e) {
  E(e)[1] = 42;
}
''');
    var element = findElement2.method('[]=');
    assertElementIndexText(element, r'''
135 6:7 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofExtension_prefix() async {
    await _indexTestUnit('''
/// [operator ~] and [E.operator ~]
extension E on int {
  int operator ~() => 0;
}
void useOperator(int e) {
  ~E(e);
}
''');
    var element = findElement2.method('~');
    assertElementIndexText(element, r'''
14 1:15 |~| IS_REFERENCED_BY
33 1:34 |~| IS_REFERENCED_BY qualified
112 6:3 |~| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofExtensionType_binary() async {
    await _indexTestUnit('''
/// [operator +] and [A.operator +]
extension type A(int it) {
  int operator +(int other) => 0;
}
void useOperator(A a) {
  a + 1;
  a += 2;
  ++a;
  a++;
}
''');
    var element = findElement2.method('+');
    assertElementIndexText(element, r'''
14 1:15 |+| IS_REFERENCED_BY
33 1:34 |+| IS_REFERENCED_BY qualified
127 6:5 |+| IS_INVOKED_BY qualified
136 7:5 |+=| IS_INVOKED_BY qualified
144 8:3 |++| IS_INVOKED_BY qualified
152 9:4 |++| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofExtensionType_index() async {
    await _indexTestUnit('''
/// [operator []] and [A.operator []]
extension type A(int it) {
  int operator [](int index) => 0;
}
void useOperator(A a) {
  a[0];
}
''');
    var element = findElement2.method('[]');
    assertElementIndexText(element, r'''
129 6:4 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofExtensionType_indexEq() async {
    await _indexTestUnit('''
/// [operator []=] and [A.operator []=]
extension type A(int it) {
  operator []=(int index, int value) {}
}
void useOperator(A a) {
  a[1] = 42;
}
''');
    var element = findElement2.method('[]=');
    assertElementIndexText(element, r'''
136 6:4 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofExtensionType_prefix() async {
    await _indexTestUnit('''
/// [operator ~] and [A.operator ~]
extension type A(int it) {
  int operator ~() => 0;
}
void useOperator(A a) {
  ~a;
}
''');
    var element = findElement2.method('~');
    assertElementIndexText(element, r'''
14 1:15 |~| IS_REFERENCED_BY
33 1:34 |~| IS_REFERENCED_BY qualified
116 6:3 |~| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofMixin_binary() async {
    await _indexTestUnit('''
/// [operator +] and [M.operator +]
mixin M {
  int operator +(int other) => 0;
}
void useOperator(M m) {
  m + 1;
  m += 2;
  ++m;
  m++;
}
''');
    var element = findElement2.method('+');
    assertElementIndexText(element, r'''
14 1:15 |+| IS_REFERENCED_BY
33 1:34 |+| IS_REFERENCED_BY qualified
110 6:5 |+| IS_INVOKED_BY qualified
119 7:5 |+=| IS_INVOKED_BY qualified
127 8:3 |++| IS_INVOKED_BY qualified
135 9:4 |++| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofMixin_index() async {
    await _indexTestUnit('''
/// [operator []] and [M.operator []]
mixin M {
  int operator [](int index) => 0;
}
void useOperator(M m) {
  m[0];
}
''');
    var element = findElement2.method('[]');
    assertElementIndexText(element, r'''
112 6:4 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofMixin_indexEq() async {
    await _indexTestUnit('''
/// [operator []=] and [M.operator []=]
mixin M {
  operator []=(int index, int value) {}
}
void useOperator(M m) {
  m[1] = 42;
}
''');
    var element = findElement2.method('[]=');
    assertElementIndexText(element, r'''
119 6:4 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofMixin_prefix() async {
    await _indexTestUnit('''
/// [operator ~] and [M.operator ~]
mixin M {
  int operator ~() => 0;
}
void useOperator(M m) {
  ~m;
}
''');
    var element = findElement2.method('~');
    assertElementIndexText(element, r'''
14 1:15 |~| IS_REFERENCED_BY
33 1:34 |~| IS_REFERENCED_BY qualified
99 6:3 |~| IS_INVOKED_BY qualified
''');
  }

  test_MixinElement_hierarchy_class_implements() async {
    await _indexTestUnit(r'''
mixin A {}
class B implements A {}
''');
    assertErrorsInResult([]);

    var element = findElement2.mixin('A');
    assertElementIndexText(element, r'''
30 2:20 |A| IS_IMPLEMENTED_BY
30 2:20 |A| IS_REFERENCED_BY
''');
  }

  test_MixinElement_hierarchy_class_with() async {
    await _indexTestUnit(r'''
mixin A {}
class B extends Object with A {}
''');
    assertErrorsInResult([]);

    var element = findElement2.mixin('A');
    assertElementIndexText(element, r'''
39 2:29 |A| IS_MIXED_IN_BY
39 2:29 |A| IS_REFERENCED_BY
''');
  }

  test_MixinElement_hierarchy_classTypeAlias_with() async {
    await _indexTestUnit(r'''
mixin A {}
class B = Object with A;
''');
    assertErrorsInResult([]);

    var element = findElement2.mixin('A');
    assertElementIndexText(element, r'''
33 2:23 |A| IS_MIXED_IN_BY
33 2:23 |A| IS_REFERENCED_BY
''');
  }

  test_MixinElement_hierarchy_enum_implements() async {
    await _indexTestUnit(r'''
mixin A {}
enum E implements A {
  v
}
''');
    assertErrorsInResult([]);

    var element = findElement2.mixin('A');
    assertElementIndexText(element, r'''
29 2:19 |A| IS_IMPLEMENTED_BY
29 2:19 |A| IS_REFERENCED_BY
''');
  }

  test_MixinElement_hierarchy_enum_with() async {
    await _indexTestUnit(r'''
mixin A {}
enum E with A {
  v
}
''');
    assertErrorsInResult([]);

    var element = findElement2.mixin('A');
    assertElementIndexText(element, r'''
23 2:13 |A| IS_MIXED_IN_BY
23 2:13 |A| IS_REFERENCED_BY
''');
  }

  test_MixinElement_hierarchy_extensionType_implements() async {
    await _indexTestUnit(r'''
mixin A {}
extension type E(A it) implements A {}
''');
    assertErrorsInResult([]);

    var element = findElement2.mixin('A');
    assertElementIndexText(element, r'''
28 2:18 |A| IS_REFERENCED_BY
45 2:35 |A| IS_IMPLEMENTED_BY
45 2:35 |A| IS_REFERENCED_BY
''');
  }

  test_MixinElement_hierarchy_mixin_implements() async {
    await _indexTestUnit(r'''
mixin A {}
mixin M implements A {}
''');
    assertErrorsInResult([]);

    var element = findElement2.mixin('A');
    assertElementIndexText(element, r'''
30 2:20 |A| IS_IMPLEMENTED_BY
30 2:20 |A| IS_REFERENCED_BY
''');
  }

  test_MixinElement_hierarchy_mixin_on() async {
    await _indexTestUnit(r'''
mixin A {}
mixin M on A {}
''');
    assertErrorsInResult([]);

    var element = findElement2.mixin('A');
    assertElementIndexText(element, r'''
22 2:12 |A| CONSTRAINS
22 2:12 |A| IS_REFERENCED_BY
''');
  }

  test_MixinElement_reference_annotation() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

mixin A {
  static const int myConstant = 0;
}

@A.myConstant
@p.A.myConstant
void f() {}
''');
    assertErrorsInResult([]);

    var element = findElement2.mixin('A');
    assertElementIndexText(element, r'''
75 7:2 |A| IS_REFERENCED_BY
91 8:4 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_MixinElement_reference_comment() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

mixin A {}

/// [A] and [p.A].
void f() {}
''');
    assertErrorsInResult([]);

    var element = findElement2.mixin('A');
    assertElementIndexText(element, r'''
43 5:6 |A| IS_REFERENCED_BY
53 5:16 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_MixinElement_reference_memberAccess() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

mixin A {
  static void foo() {}
}

void f() {
  A.foo();
  p.A.foo();
}
''');
    assertErrorsInResult([]);

    var element = findElement2.mixin('A');
    assertElementIndexText(element, r'''
75 8:3 |A| IS_REFERENCED_BY
88 9:5 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_MixinElement_reference_namedType() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

mixin A {}

void f(A v1, p.A v2) {}
''');
    assertErrorsInResult([]);

    var element = findElement2.mixin('A');
    assertElementIndexText(element, r'''
45 5:8 |A| IS_REFERENCED_BY
53 5:16 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_MultiplyDefinedElement() async {
    newFile('$testPackageLibPath/a1.dart', 'class A {}');
    newFile('$testPackageLibPath/a2.dart', 'class A {}');
    await _indexTestUnit('''
import 'a1.dart';
import 'a2.dart';
A v = null;
''');
  }

  test_NeverElement() async {
    await _indexTestUnit('''
Never f() {}
''');
    expect(index.usedElementOffsets, isEmpty);
  }

  test_SetterElement_ofClass_instance() async {
    await _indexTestUnit('''
/// [foo] and [A.foo]
class A {
  set foo(int _) {}
  void useSetter() {
    foo = 0;
    this.foo = 0;
  }
}

void useSetter(A a) {
  a.foo = 0;
}
''');
    var element = findElement2.setter('foo');
    assertElementIndexText(element, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
77 5:5 |foo| IS_REFERENCED_BY
95 6:10 |foo| IS_REFERENCED_BY qualified
137 11:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_SetterElement_ofClass_static() async {
    await _indexTestUnit('''
import 'test.dart' as p;

/// [foo], [A.foo], [p.A.foo]
class A {
  static set foo(int _) {}
  static void useSetter() {
    foo = 0;
  }
}

void useSetter() {
  A.foo = 0;
  p.A.foo = 0;
}
''');
    var element = findElement2.setter('foo');
    assertElementIndexText(element, r'''
31 3:6 |foo| IS_REFERENCED_BY
40 3:15 |foo| IS_REFERENCED_BY qualified
51 3:26 |foo| IS_REFERENCED_BY qualified
125 7:5 |foo| IS_REFERENCED_BY
164 12:5 |foo| IS_REFERENCED_BY qualified
179 13:7 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_subtypes_classDeclaration() async {
    String libP = 'package:test/lib.dart;package:test/lib.dart';
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
class B {}
class C {}
class D {}
class E {}
''');
    await _indexTestUnit('''
import 'lib.dart';

class X extends A {
  X();
  X.namedConstructor();

  int field1, field2;
  int get getter1 => null;
  void set setter1(_) {}
  void method1() {}

  static int staticField;
  static void staticMethod() {}
}

class Y extends Object with B, C {
  void methodY() {}
}

class Z implements E, D {
  void methodZ() {}
}
''');

    expect(index.supertypes, hasLength(6));
    expect(index.subtypes, hasLength(6));

    _assertSubtype(0, 'dart:core;dart:core;Object', 'Y', ['methodY']);
    _assertSubtype(1, '$libP;A', 'X', [
      'field1',
      'field2',
      'getter1',
      'method1',
      'setter1',
    ]);
    _assertSubtype(2, '$libP;B', 'Y', ['methodY']);
    _assertSubtype(3, '$libP;C', 'Y', ['methodY']);
    _assertSubtype(4, '$libP;D', 'Z', ['methodZ']);
    _assertSubtype(5, '$libP;E', 'Z', ['methodZ']);
  }

  test_subtypes_classTypeAlias() async {
    String libP = 'package:test/lib.dart;package:test/lib.dart';
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
class B {}
class C {}
class D {}
''');
    await _indexTestUnit('''
import 'lib.dart';

class X = A with B, C;
class Y = A with B implements C, D;
''');

    expect(index.supertypes, hasLength(7));
    expect(index.subtypes, hasLength(7));

    _assertSubtype(0, '$libP;A', 'X', []);
    _assertSubtype(1, '$libP;A', 'Y', []);
    _assertSubtype(2, '$libP;B', 'X', []);
    _assertSubtype(3, '$libP;B', 'Y', []);
    _assertSubtype(4, '$libP;C', 'X', []);
    _assertSubtype(5, '$libP;C', 'Y', []);
    _assertSubtype(6, '$libP;D', 'Y', []);
  }

  test_subtypes_dynamic() async {
    await _indexTestUnit('''
class X extends dynamic {
  void foo() {}
}
''');

    expect(index.supertypes, isEmpty);
    expect(index.subtypes, isEmpty);
  }

  test_subtypes_enum_implements() async {
    String libP = 'package:test/test.dart;package:test/test.dart';
    await _indexTestUnit('''
class A {}

enum E implements A {
  v;
  void foo() {}
}
''');

    expect(index.subtypes, hasLength(1));
    _assertSubtype(0, '$libP;A', 'E', ['foo']);
  }

  test_subtypes_enum_with() async {
    String libP = 'package:test/test.dart;package:test/test.dart';
    await _indexTestUnit('''
mixin M {}

enum E with M {
  v;
  void foo() {}
}
''');

    expect(index.subtypes, hasLength(1));
    _assertSubtype(0, '$libP;M', 'E', ['foo']);
  }

  test_subtypes_extensionType_class() async {
    String libP = 'package:test/lib.dart;package:test/lib.dart';
    newFile('$testPackageLibPath/lib.dart', '''
class A {
  void method1() {}
  void method2() {}
}
''');
    await _indexTestUnit('''
import 'lib.dart';

extension type X(A it) implements A {
  void method1() {}
  void method3() {}
}
''');

    expect(index.supertypes, hasLength(1));
    expect(index.subtypes, hasLength(1));

    _assertSubtype(0, '$libP;A', 'X', ['method1', 'method3']);
  }

  test_subtypes_extensionType_extensionType() async {
    String libP = 'package:test/lib.dart;package:test/lib.dart';
    newFile('$testPackageLibPath/lib.dart', '''
extension type A(int it) {
  void method1() {}
  void method2() {}
}
''');
    await _indexTestUnit('''
import 'lib.dart';

extension type X(int it) implements A {
  void method1() {}
  void method3() {}
}
''');

    expect(index.supertypes, hasLength(1));
    expect(index.subtypes, hasLength(1));

    _assertSubtype(0, '$libP;A', 'X', ['method1', 'method3']);
  }

  test_subtypes_mixinDeclaration() async {
    String libP = 'package:test/lib.dart;package:test/lib.dart';
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
class B {}
class C {}
class D {}
class E {}
''');
    await _indexTestUnit('''
import 'lib.dart';

mixin X on A implements B, C {}
mixin Y on A, B implements C;
''');

    expect(index.supertypes, hasLength(6));
    expect(index.subtypes, hasLength(6));

    _assertSubtype(0, '$libP;A', 'X', []);
    _assertSubtype(1, '$libP;A', 'Y', []);
    _assertSubtype(2, '$libP;B', 'X', []);
    _assertSubtype(3, '$libP;B', 'Y', []);
    _assertSubtype(4, '$libP;C', 'X', []);
    _assertSubtype(5, '$libP;C', 'Y', []);
  }

  test_SuperFormalParameterElement_ofConstructor_optionalNamed() async {
    await _indexTestUnit('''
class A {
  A({int? test});
}

class B extends A {
  /// [test]
  B({super.test}) : assert(test != null);
}

void f() {
  B(test: 0);
  B _ = .new(test: 0);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.unnamedConstructor('B').parameter('test');
    assertElementIndexText(element, r'''
124 11:5 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
147 12:14 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_SuperFormalParameterElement_ofConstructor_optionalPositional() async {
    await _indexTestUnit('''
class A {
  A([int? test]);
}

class B extends A {
  /// [test]
  B([super.test]) : assert(test != null);
}

void f() {
  B(0);
  B _ = .new(0);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.unnamedConstructor('B').parameter('test');
    assertElementIndexText(element, r'''
''');
  }

  test_SuperFormalParameterElement_ofConstructor_requiredNamed() async {
    await _indexTestUnit('''
class A {
  A({required int test});
}

class B extends A {
  /// [test]
  B({required super.test}) : assert(test != -1);
}

void f() {
  B(test: 0);
  B _ = .new(test: 0);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.unnamedConstructor('B').parameter('test');
    assertElementIndexText(element, r'''
139 11:5 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
162 12:14 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_SuperFormalParameterElement_ofConstructor_requiredPositional() async {
    await _indexTestUnit('''
class A {
  A(int test);
}

class B extends A {
  /// [test]
  B(super.test) : assert(test != -1);
}

void f() {
  B(0);
  B _ = .new(0);
}
''');
    assertErrorsInResult([]);
    var element = findElement2.unnamedConstructor('B').parameter('test');
    assertElementIndexText(element, r'''
''');
  }

  test_TopLevelFunctionElement() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

void foo() {}

/// [foo] and [p.foo]
void f() {
  foo();
  p.foo();
  foo;
  p.foo;
}
''');
    assertErrorsInResult([]);

    var element = findElement2.topFunction('foo');
    assertElementIndexText(element, r'''
46 5:6 |foo| IS_REFERENCED_BY
58 5:18 |foo| IS_REFERENCED_BY qualified
76 7:3 |foo| IS_INVOKED_BY
87 8:5 |foo| IS_INVOKED_BY qualified
96 9:3 |foo| IS_REFERENCED_BY
105 10:5 |foo| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_TopLevelFunctionElement_loadLibrary() async {
    await _indexTestUnit('''
import 'dart:math' deferred as math;

void f() {
  math.loadLibrary();
}
''');
    var mathLib = findElement2.import('dart:math').importedLibrary!;
    var element = mathLib.loadLibraryFunction;
    assertElementIndexText(element, r'''
56 4:8 |loadLibrary| IS_INVOKED_BY qualified
''');
  }

  test_TopLevelVariableElement_reference() async {
    await _indexTestUnit('''
import 'test.dart' as p;

var foo = 0;

/// [foo] and [p.foo].
@foo
@p.foo
void f() {
  foo;
  foo = 0;
  p.foo;
  p.foo = 0;
}
''');

    var element = findElement2.topVar('foo');
    var getter = element.getter!;
    var setter = element.setter!;

    assertElementIndexText(getter, r'''
45 5:6 |foo| IS_REFERENCED_BY
57 5:18 |foo| IS_REFERENCED_BY qualified
64 6:2 |foo| IS_REFERENCED_BY
71 7:4 |foo| IS_REFERENCED_BY qualified
88 9:3 |foo| IS_REFERENCED_BY
108 11:5 |foo| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');

    assertElementIndexText(setter, r'''
95 10:3 |foo| IS_REFERENCED_BY
117 12:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_TopLevelVariableElement_reference_combinator_show_hasGetterSetter() async {
    await _indexTestUnit('''
import 'test.dart' show foo;

int get foo => 0;
void set foo(_) {}
''');
    var element = findElement2.topVar('foo');
    assertElementIndexText(element, r'''
24 1:25 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_TopLevelVariableElement_reference_combinator_show_hasSetter() async {
    await _indexTestUnit('''
import 'test.dart' show foo;

void set foo(_) {}
''');
    var element = findElement2.topVar('foo');
    assertElementIndexText(element, r'''
24 1:25 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_TypeAliasElement_legacy_reference() async {
    await _indexTestUnit('''
typedef void A();
/// [A]
void f(A p) {}
''');
    var element = findElement2.typeAlias('A');
    assertElementIndexText(element, r'''
23 2:6 |A| IS_REFERENCED_BY
33 3:8 |A| IS_REFERENCED_BY
''');
  }

  test_TypeAliasElement_modern_hierarchy_class_extends() async {
    await _indexTestUnit('''
class A<T> {}
typedef B = A<int>;
class C extends B {}
''');
    var element = findElement2.typeAlias('B');
    assertElementIndexText(element, r'''
50 3:17 |B| IS_EXTENDED_BY
50 3:17 |B| IS_REFERENCED_BY
''');

    var aliasedClass = findElement2.class_('A');
    assertElementIndexText(aliasedClass, r'''
26 2:13 |A| IS_REFERENCED_BY
''');
  }

  test_TypeAliasElement_modern_hierarchy_class_implements() async {
    await _indexTestUnit('''
class A<T> {}
typedef B = A<int>;
class C implements B {}
''');
    var element = findElement2.typeAlias('B');
    assertElementIndexText(element, r'''
53 3:20 |B| IS_IMPLEMENTED_BY
53 3:20 |B| IS_REFERENCED_BY
''');

    var aliasedClass = findElement2.class_('A');
    assertElementIndexText(aliasedClass, r'''
26 2:13 |A| IS_REFERENCED_BY
''');
  }

  test_TypeAliasElement_modern_hierarchy_class_with() async {
    await _indexTestUnit('''
class A<T> {}
typedef B = A<int>;
class C extends Object with B {}
''');
    var element = findElement2.typeAlias('B');
    assertElementIndexText(element, r'''
62 3:29 |B| IS_MIXED_IN_BY
62 3:29 |B| IS_REFERENCED_BY
''');

    var aliasedClass = findElement2.class_('A');
    assertElementIndexText(aliasedClass, r'''
26 2:13 |A| IS_REFERENCED_BY
''');
  }

  test_TypeAliasElement_modern_reference() async {
    await _indexTestUnit('''
class A<T> {
  static int field = 0;
  static void method() {}
}

typedef B = A<int>;

/// [B]
void f(B p) {
  B v;
  B();
  B.field;
  B.field = 0;
  B.method();
}
''');
    var element = findElement2.typeAlias('B');
    assertElementIndexText(element, r'''
92 8:6 |B| IS_REFERENCED_BY
102 9:8 |B| IS_REFERENCED_BY
111 10:3 |B| IS_REFERENCED_BY
118 11:3 |B| IS_REFERENCED_BY
125 12:3 |B| IS_REFERENCED_BY
136 13:3 |B| IS_REFERENCED_BY
151 14:3 |B| IS_REFERENCED_BY
''');

    var aliasedClass = findElement2.class_('A');
    assertElementIndexText(aliasedClass, r'''
78 6:13 |A| IS_REFERENCED_BY
''');
  }

  test_TypeAliasElement_modern_reference_comment() async {
    await _indexTestUnit(r'''
import 'test.dart' as p;

class A<T> {}
typedef B = A<int>;

/// [B] and [p.B].
void f() {}
''');
    assertErrorsInResult([]);
    var element = findElement2.typeAlias('B');
    assertElementIndexText(element, r'''
66 6:6 |B| IS_REFERENCED_BY
76 6:16 |B| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');

    var aliasedClass = findElement2.class_('A');
    assertElementIndexText(aliasedClass, r'''
52 4:13 |A| IS_REFERENCED_BY
''');
  }

  test_usedName_inLibraryIdentifier() async {
    await _indexTestUnit('''
library aaa.bbb.ccc;
class C {
  var bbb;
}
void f(p) {
  p.bbb = 1;
}
''');
    assertThatName('bbb')
      ..isNotUsed('bbb.ccc', IndexRelationKind.IS_READ_BY)
      ..isUsedQ('bbb = 1;', IndexRelationKind.IS_WRITTEN_BY);
  }

  test_usedName_qualified_resolved() async {
    await _indexTestUnit('''
class C {
  var x;
}
void f(C c) {
  c.x; // 1
  c.x = 1;
  c.x += 2;
  c.x();
}
''');
    assertThatName('x')
      ..isNotUsedQ('x; // 1', IndexRelationKind.IS_READ_BY)
      ..isNotUsedQ('x = 1;', IndexRelationKind.IS_WRITTEN_BY)
      ..isNotUsedQ('x += 2;', IndexRelationKind.IS_READ_WRITTEN_BY)
      ..isNotUsedQ('x();', IndexRelationKind.IS_INVOKED_BY);
  }

  test_usedName_qualified_unresolved() async {
    await _indexTestUnit('''
void f(p) {
  p.x;
  p.x = 1;
  p.x += 2;
  p.x();
}
''');
    assertThatName('x')
      ..isUsedQ('x;', IndexRelationKind.IS_READ_BY)
      ..isUsedQ('x = 1;', IndexRelationKind.IS_WRITTEN_BY)
      ..isUsedQ('x += 2;', IndexRelationKind.IS_READ_WRITTEN_BY)
      ..isUsedQ('x();', IndexRelationKind.IS_INVOKED_BY);
  }

  test_usedName_unqualified_resolved() async {
    await _indexTestUnit('''
class C {
  var x;
  m() {
    x; // 1
    x = 1;
    x += 2;
    x();
  }
}
''');
    assertThatName('x')
      ..isNotUsedQ('x; // 1', IndexRelationKind.IS_READ_BY)
      ..isNotUsedQ('x = 1;', IndexRelationKind.IS_WRITTEN_BY)
      ..isNotUsedQ('x += 2;', IndexRelationKind.IS_READ_WRITTEN_BY)
      ..isNotUsedQ('x();', IndexRelationKind.IS_INVOKED_BY);
  }

  test_usedName_unqualified_unresolved() async {
    await _indexTestUnit('''
void f() {
  x;
  x = 1;
  x += 2;
  x();
}
''');
    assertThatName('x')
      ..isUsed('x;', IndexRelationKind.IS_READ_BY)
      ..isUsed('x = 1;', IndexRelationKind.IS_WRITTEN_BY)
      ..isUsed('x += 2;', IndexRelationKind.IS_READ_WRITTEN_BY)
      ..isUsed('x();', IndexRelationKind.IS_INVOKED_BY);
  }

  String _getLibraryFragmentReferenceText(LibraryFragmentImpl target) {
    var lineInfo = result.lineInfo;
    var targetId = index.getLibraryFragmentId(target);

    expect(
      index.libFragmentRefTargets.length,
      index.libFragmentRefUriOffsets.length,
    );

    expect(
      index.libFragmentRefTargets.length,
      index.libFragmentRefUriLengths.length,
    );

    var buffer = StringBuffer();
    for (var i = 0; i < index.libFragmentRefTargets.length; i++) {
      if (index.libFragmentRefTargets[i] == targetId) {
        var offset = index.libFragmentRefUriOffsets[i];
        var length = index.libFragmentRefUriLengths[i];
        var location = lineInfo.getLocation(offset);
        var snippet = result.content.substring(offset, offset + length);
        buffer.write(offset);
        buffer.write(' ');
        buffer.write(location.lineNumber);
        buffer.write(':');
        buffer.write(location.columnNumber);
        buffer.write(' ');
        buffer.write('|$snippet|');
        buffer.writeln();
      }
    }
    return buffer.toString();
  }

  String _getRelationsText(Element element) {
    var lineInfo = result.lineInfo;
    var elementId = _findElementId(element);
    if (elementId == null) {
      return '';
    }

    var relations = <_Relation>[];
    for (var i = 0; i < index.usedElementOffsets.length; i++) {
      if (index.usedElements[i] == elementId) {
        relations.add(
          _Relation(
            kind: index.usedElementKinds[i],
            offset: index.usedElementOffsets[i],
            length: index.usedElementLengths[i],
            isQualified: index.usedElementIsQualifiedFlags[i],
          ),
        );
      }
    }

    var sortedRelations = relations.sorted((a, b) {
      var byOffset = a.offset - b.offset;
      if (byOffset != 0) {
        return byOffset;
      }
      return a.kind.name.compareTo(b.kind.name);
    });

    // Verify that there are no duplicate relations.
    var lastOffset = -1;
    var lastLength = -1;
    IndexRelationKind? lastKind;
    for (var relation in sortedRelations) {
      if (relation.offset == lastOffset &&
          relation.length == lastLength &&
          relation.kind == lastKind) {
        fail('Duplicate relation: $relation');
      }
      lastOffset = relation.offset;
      lastLength = relation.length;
      lastKind = relation.kind;
    }

    var buffer = StringBuffer();
    for (var relation in sortedRelations) {
      var offset = relation.offset;
      var length = relation.length;
      var location = lineInfo.getLocation(offset);
      var snippet = result.content.substring(offset, offset + length);
      buffer.write(offset);
      buffer.write(' ');
      buffer.write(location.lineNumber);
      buffer.write(':');
      buffer.write(location.columnNumber);
      buffer.write(' ');
      buffer.write('|$snippet|');
      buffer.write(' ');
      buffer.write(relation.kind.name);
      if (relation.isQualified) {
        buffer.write(' qualified');
      }
      buffer.writeln();
    }

    var prefixString = index.elementImportPrefixes[elementId];
    // If the only access is unprefixed, omit the line
    if (prefixString.isNotEmpty) {
      // Otherwise, use some marker text for unprefixed so it's clearer in the
      // output than an empty string.
      var prefixes = prefixString
          .split(',')
          .map((prefix) => prefix.isEmpty ? '(unprefixed)' : prefix)
          .join(',');

      buffer.writeln('Prefixes: $prefixes');
    }

    return buffer.toString();
  }
}

mixin _IndexMixin on PubPackageResolutionTest {
  late AnalysisDriverUnitIndex index;

  _NameIndexAssert assertThatName(String name) {
    return _NameIndexAssert(this, name);
  }

  /// Return [ImportFindElement] for 'package:test/lib.dart' import.
  ImportFindElement importFindLib() {
    return findElement2.importFind(
      'package:test/lib.dart',
      mustBeUnique: false,
    );
  }

  void _assertSubtype(
    int i,
    String superEncoded,
    String subName,
    List<String> members,
  ) {
    expect(index.strings[index.supertypes[i]], superEncoded);
    var subtype = index.subtypes[i];
    expect(index.strings[subtype.name], subName);
    expect(_decodeStringList(subtype.members), members);
  }

  void _assertUsedName(
    String name,
    IndexRelationKind kind,
    ExpectedLocation expectedLocation,
    bool isNot,
  ) {
    int nameId = index.getStringId(name);
    for (int i = 0; i < index.usedNames.length; i++) {
      if (index.usedNames[i] == nameId &&
          index.usedNameKinds[i] == kind &&
          index.usedNameOffsets[i] == expectedLocation.offset &&
          index.usedNameIsQualifiedFlags[i] == expectedLocation.isQualified) {
        if (isNot) {
          _failWithIndexDump('Unexpected $name $kind at $expectedLocation');
        }
        return;
      }
    }
    if (isNot) {
      return;
    }
    _failWithIndexDump('Not found $name $kind at $expectedLocation');
  }

  List<String> _decodeStringList(List<int> stringIds) {
    return stringIds.map((i) => index.strings[i]).toList();
  }

  ExpectedLocation _expectedLocation(
    String search,
    bool isQualified, {
    int? length,
  }) {
    int offset = findNode.offset(search);
    length ??= findNode.simple(search).length;
    return ExpectedLocation(offset, length, isQualified);
  }

  void _failWithIndexDump(String msg) {
    var buffer = StringBuffer();
    for (int i = 0; i < index.usedElementOffsets.length; i++) {
      buffer.write('  id = ');
      buffer.write(index.usedElements[i]);
      buffer.write(' kind = ');
      buffer.write(index.usedElementKinds[i]);
      buffer.write(' offset = ');
      buffer.write(index.usedElementOffsets[i]);
      buffer.write(' length = ');
      buffer.write(index.usedElementLengths[i]);
      buffer.write(' isQualified = ');
      buffer.writeln(index.usedElementIsQualifiedFlags[i]);
    }
    fail('$msg in\n${buffer.toString()}');
  }

  /// Return the [element] identifier in [index], or `null`.
  int? _findElementId(Element element) {
    var unitId = _getUnitId(element);

    // Prepare the element that was put into the index.
    IndexElementInfo info = IndexElementInfo(element);
    element = info.element;

    // Prepare element's name components.
    var components = ElementNameComponents(element);
    var unitMemberId = index.getStringId(components.unitMemberName);
    var classMemberId = index.getStringId(components.classMemberName);
    var parameterId = index.getStringId(components.parameterName);

    // Find the element's id.
    for (
      int elementId = 0;
      elementId < index.elementUnits.length;
      elementId++
    ) {
      if (index.elementUnits[elementId] == unitId &&
          index.elementNameUnitMemberIds[elementId] == unitMemberId &&
          index.elementNameClassMemberIds[elementId] == classMemberId &&
          index.elementNameParameterIds[elementId] == parameterId &&
          index.elementKinds[elementId] == info.kind) {
        return elementId;
      }
    }

    return null;
  }

  int _getUnitId(Element element) {
    var unitElement = getUnitElement(element);
    return index.getLibraryFragmentId(unitElement);
  }

  Future<void> _indexTestUnit(String code) async {
    await resolveTestCode(code);

    var indexBuilder = indexUnit(result.unit);
    var indexBytes = indexBuilder.toBuffer();
    index = AnalysisDriverUnitIndex.fromBuffer(indexBytes);
  }
}

class _NameIndexAssert {
  final _IndexMixin test;
  final String name;

  _NameIndexAssert(this.test, this.name);

  void isNotUsed(String search, IndexRelationKind kind) {
    test._assertUsedName(
      name,
      kind,
      test._expectedLocation(search, false),
      true,
    );
  }

  void isNotUsedQ(String search, IndexRelationKind kind) {
    test._assertUsedName(
      name,
      kind,
      test._expectedLocation(search, true),
      true,
    );
  }

  void isUsed(String search, IndexRelationKind kind) {
    test._assertUsedName(
      name,
      kind,
      test._expectedLocation(search, false),
      false,
    );
  }

  void isUsedQ(String search, IndexRelationKind kind) {
    test._assertUsedName(
      name,
      kind,
      test._expectedLocation(search, true),
      false,
    );
  }
}

class _Relation {
  final IndexRelationKind kind;
  final int offset;
  final int length;
  final bool isQualified;

  _Relation({
    required this.kind,
    required this.offset,
    required this.length,
    required this.isQualified,
  });

  @override
  String toString() {
    return '_Relation{kind: $kind, offset: $offset, length: $length, '
        'isQualified: $isQualified})';
  }
}
