// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/index.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/test_utilities/find_element2.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
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

@reflectiveTest
class IndexTest extends PubPackageResolutionTest {
  void assertElementIndexText(
    _IndexResult result,
    Element element,
    String expected,
  ) {
    var actual = _IndexTextBuilder(result).elementRelations(element);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
  }

  void assertLibraryFragmentIndexText(
    _IndexResult result,
    LibraryFragmentImpl fragment,
    String expected,
  ) {
    var actual = _IndexTextBuilder(result).libraryFragmentReferences(fragment);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
  }

  void assertNameIndexText(_IndexResult result, String name, String expected) {
    var actual = _IndexTextBuilder(result).nameRelations(name);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
  }

  void assertSubtypeIndexText(_IndexResult result, String expected) {
    var actual = _toPosixPaths(_IndexTextBuilder(result).subtypes());
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
  }

  test_analyzer_diagnosticCode() async {
    var analyzerPackageRootPath = '$workspaceRootPath/pkg/analyzer';
    writePackageConfig(
      analyzerPackageRootPath,
      PackageConfigFileBuilder()
        ..add(name: 'analyzer', rootFolder: getFolder(analyzerPackageRootPath)),
    );

    var analyzerPackageLibPath = '$analyzerPackageRootPath/lib';
    var analyzerPackageTestPath = '$analyzerPackageRootPath/test';
    var diagnosticFile = newFile(
      '$analyzerPackageLibPath/src/diagnostic/diagnostic.dart',
      r'''
const myDiagnosticCode = 0;
''',
    );

    var diagnosticLibrary = await libraryElementForFile(diagnosticFile);
    var element = diagnosticLibrary.topLevelVariables.firstWhere(
      (v) => v.name == 'myDiagnosticCode',
    );

    var testFile = getFile('$analyzerPackageTestPath/test.dart');
    var result = await _indexFileWithDiagnostics(testFile, r'''
void f() {
  '// [diag.myDiagnosticCode] message';
}
''');

    assertElementIndexText(result, element, r'''
23 2:13 |myDiagnosticCode| IS_REFERENCED_BY qualified
''');
  }

  test_ClassElement_emptyBody() async {
    await _indexTestCode(r'''
class C;
''');
  }

  test_ClassElement_hierarchy_class_extends() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {}

class B extends A {}
class B_q extends p.A {}
''');

    var element = result.findElement.class_('A');
    assertElementIndexText(result, element, r'''
54 5:17 |A| IS_EXTENDED_BY
54 5:17 |A| IS_REFERENCED_BY
79 6:21 |A| IS_EXTENDED_BY qualified
79 6:21 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_hierarchy_class_extends_implicitObject() async {
    var result = await _indexTestCode('''
class A {}
''');
    var element = result.resolvedUnit.typeProvider.objectElement;
    assertElementIndexText(result, element, r'''
6 1:7 || IS_EXTENDED_BY qualified
''');
  }

  test_ClassElement_hierarchy_class_implements() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {}

class B implements A {}
class B_q implements p.A {}
''');

    var element = result.findElement.class_('A');
    assertElementIndexText(result, element, r'''
57 5:20 |A| IS_IMPLEMENTED_BY
57 5:20 |A| IS_REFERENCED_BY
85 6:24 |A| IS_IMPLEMENTED_BY qualified
85 6:24 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_hierarchy_class_with() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {}

class D extends Object with A {}
//                          ^
// [diag.classUsedAsMixin] The class 'A' can't be used as a mixin because it's neither a mixin class nor a mixin.
class D_q extends Object with p.A {}
//                            ^^^
// [diag.classUsedAsMixin] The class 'A' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');

    var element = result.findElement.class_('A');
    assertElementIndexText(result, element, r'''
66 5:29 |A| IS_MIXED_IN_BY
66 5:29 |A| IS_REFERENCED_BY
103 6:33 |A| IS_MIXED_IN_BY qualified
103 6:33 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_hierarchy_classTypeAlias_with() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {}

class D2 = Object with A;
//                     ^
// [diag.classUsedAsMixin] The class 'A' can't be used as a mixin because it's neither a mixin class nor a mixin.
class D2_q = Object with p.A;
//                       ^^^
// [diag.classUsedAsMixin] The class 'A' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');

    var element = result.findElement.class_('A');
    assertElementIndexText(result, element, r'''
61 5:24 |A| IS_MIXED_IN_BY
61 5:24 |A| IS_REFERENCED_BY
91 6:28 |A| IS_MIXED_IN_BY qualified
91 6:28 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_hierarchy_enum_implements() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {}

enum E implements A { v }
enum E_q implements p.A { v }
''');

    var element = result.findElement.class_('A');
    assertElementIndexText(result, element, r'''
56 5:19 |A| IS_IMPLEMENTED_BY
56 5:19 |A| IS_REFERENCED_BY
86 6:23 |A| IS_IMPLEMENTED_BY qualified
86 6:23 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_hierarchy_extensionType_implements() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {}

extension type E(A it) implements A {}
extension type E_q(A it) implements p.A {}
''');

    var element = result.findElement.class_('A');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {}

mixin M implements A {}
mixin M_q implements p.A {}
''');

    var element = result.findElement.class_('A');
    assertElementIndexText(result, element, r'''
57 5:20 |A| IS_IMPLEMENTED_BY
57 5:20 |A| IS_REFERENCED_BY
85 6:24 |A| IS_IMPLEMENTED_BY qualified
85 6:24 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_hierarchy_mixin_on() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {}

mixin M2 on A {}
mixin M2_q on p.A {}
''');

    var element = result.findElement.class_('A');
    assertElementIndexText(result, element, r'''
50 5:13 |A| CONSTRAINS
50 5:13 |A| IS_REFERENCED_BY
71 6:17 |A| CONSTRAINS qualified
71 6:17 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_reference_annotation() async {
    var result = await _indexTestCode(r'''
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

    var element = result.findElement.class_('A');
    assertElementIndexText(result, element, r'''
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

  test_ClassElement_reference_annotation_typeArgument_namedConstructor() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A<T> {
  const A.named();
}

class B {}

@A<B>.named()
@p.A<B>.named()
void f() {}
''');
    var element = result.findElement.class_('B');
    assertElementIndexText(result, element, r'''
76 9:4 |B| IS_REFERENCED_BY
92 10:6 |B| IS_REFERENCED_BY
''');
  }

  test_ClassElement_reference_annotation_typeArgument_unnamedConstructor() async {
    var result = await _indexTestCode(r'''
class A<T> {
  const A();
}

class B {}

@A<B>()
void f() {}
''');
    var element = result.findElement.class_('B');
    assertElementIndexText(result, element, r'''
44 7:4 |B| IS_REFERENCED_BY
''');
  }

  test_ClassElement_reference_classTypeAlias() async {
    var result = await _indexTestCode('''
class A {}
class B = Object with A;
//                    ^
// [diag.classUsedAsMixin] The class 'A' can't be used as a mixin because it's neither a mixin class nor a mixin.
void f(B p) {
  B v;
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');
    var element = result.findElement.class_('B');
    assertElementIndexText(result, element, r'''
43 3:8 |B| IS_REFERENCED_BY
52 4:3 |B| IS_REFERENCED_BY
''');
  }

  test_ClassElement_reference_comment() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {}

/// [A] and [p.A].
void f() {}
''');
    var element = result.findElement.class_('A');
    assertElementIndexText(result, element, r'''
43 5:6 |A| IS_REFERENCED_BY
53 5:16 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_reference_definedInSdk() async {
    var result = await _indexTestCode(r'''
import 'dart:math';
Random v1;
//     ^^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'v1' must be initialized.
Random v2;
//     ^^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'v2' must be initialized.
''');
    var element = result.findElement.importFind('dart:math').class_('Random');
    assertElementIndexText(result, element, r'''
20 2:1 |Random| IS_REFERENCED_BY
31 3:1 |Random| IS_REFERENCED_BY
''');
  }

  test_ClassElement_reference_definedOutside() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class A {}
''');
    var result = await _indexTestCode(r'''
import 'lib.dart';

void f(A p) {
  A v = p;
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');
    var element = result.resolvedUnit.findNode.namedType('A p').element!;
    assertElementIndexText(result, element, r'''
27 3:8 |A| IS_REFERENCED_BY
36 4:3 |A| IS_REFERENCED_BY
''');
  }

  test_ClassElement_reference_instanceCreation() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {}

void f() {
  A();
  p.A();
}
''');

    var element = result.findElement.class_('A');
    assertElementIndexText(result, element, r'''
51 6:3 |A| IS_REFERENCED_BY
60 7:5 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_reference_memberAccess() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {
  static void foo() {}
}

void f() {
  A.foo();
  p.A.foo();
}
''');

    var element = result.findElement.class_('A');
    assertElementIndexText(result, element, r'''
75 8:3 |A| IS_REFERENCED_BY
88 9:5 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_reference_namedType() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {}

void f() {
  A v1;
//  ^^
// [diag.unusedLocalVariable] The value of the local variable 'v1' isn't used.
  p.A v2;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 'v2' isn't used.
  List<A> v3;
//        ^^
// [diag.unusedLocalVariable] The value of the local variable 'v3' isn't used.
  List<p.A> v4;
//          ^^
// [diag.unusedLocalVariable] The value of the local variable 'v4' isn't used.
}
''');

    var element = result.findElement.class_('A');
    assertElementIndexText(result, element, r'''
51 6:3 |A| IS_REFERENCED_BY
61 7:5 |A| IS_REFERENCED_BY qualified
74 8:8 |A| IS_REFERENCED_BY
90 9:10 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_reference_recordTypeAnnotation_named() async {
    var result = await _indexTestCode(r'''
class A {}

void f(({int foo, A bar}) r) {}
''');
    var element = result.findElement.class_('A');
    assertElementIndexText(result, element, r'''
30 3:19 |A| IS_REFERENCED_BY
''');
  }

  test_ClassElement_reference_recordTypeAnnotation_positional() async {
    var result = await _indexTestCode(r'''
class A {}

void f((int, A) r) {}
''');
    var element = result.findElement.class_('A');
    assertElementIndexText(result, element, r'''
25 3:14 |A| IS_REFERENCED_BY
''');
  }

  test_ClassElement_reference_typeLiteral() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {}

var v = A;
var v_p = p.A;
''');
    var element = result.findElement.class_('A');
    assertElementIndexText(result, element, r'''
46 5:9 |A| IS_REFERENCED_BY
61 6:13 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ConstructorElement_class_annotation() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {
  const A();
  const A.named();
}

@A()
@p.A()
@A.named()
@p.A.named()
void f() {}
''');

    var unnamed = result.findElement.unnamedConstructor('A');
    assertElementIndexText(result, unnamed, r'''
73 8:3 || IS_INVOKED_BY qualified
80 9:5 || IS_INVOKED_BY qualified
''');

    var named = result.findElement.constructor('named', of: 'A');
    assertElementIndexText(result, named, r'''
85 10:3 |.named| IS_INVOKED_BY qualified
98 11:5 |.named| IS_INVOKED_BY qualified
''');
  }

  test_ConstructorElement_class_method_sameName() async {
    var result = await _indexTestCode('''
class A {
  A.foo() {
    foo();
  }

  A foo() => A.foo();
}
''');

    var constructor = result.findElement.constructor('foo');
    assertElementIndexText(result, constructor, r'''
52 6:15 |.foo| IS_INVOKED_BY qualified
''');

    var method = result.findElement.method('foo');
    assertElementIndexText(result, method, r'''
26 3:5 |foo| IS_INVOKED_BY
''');
  }

  test_ConstructorElement_class_named_newHead() async {
    var result = await _indexTestCode('''
/// [new A.foo] and [A.foo]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
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
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var element = result.findElement.constructor('foo');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
/// [new A.foo] and [A.foo]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
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
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var element = result.findElement.constructor('foo');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
/// [new A.foo] and [A.foo]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
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
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var element = result.findElement.constructor('foo');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
/// [new B.foo] and [B.foo]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
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
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
}
''');
    var element = result.findElement.constructor('foo');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
/// [new A] and [A.new]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
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
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var element = result.findElement.unnamedConstructor('A');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
class A {
  A();
}

class B extends A {
  new ();
  new bar();
  factory new.baz() = A;
//        ^^^
// [diag.expectedIdentifierButGotKeyword] 'new' can't be used as an identifier because it's a keyword.
// [diag.invalidFactoryNameNotAClass] The name of a factory constructor must be the same as the name of the immediately enclosing class.
//                    ^
// [diag.redirectToInvalidReturnType] The return type 'A' of the redirected constructor isn't a subtype of 'B'.
}
''');

    var element = result.findElement.unnamedConstructor('A');
    assertElementIndexText(result, element, r'''
42 6:3 |new| IS_INVOKED_BY qualified
52 7:3 |new bar| IS_INVOKED_BY qualified
86 8:24 || IS_REFERENCED_BY qualified
''');
  }

  test_ConstructorElement_class_unnamed_implicitInvocation_fromTypeName() async {
    var result = await _indexTestCode('''
class A {
  A();
}

class B extends A {
  B();
  B.bar();
  factory B.baz() = A;
//                  ^
// [diag.redirectToInvalidReturnType] The return type 'A' of the redirected constructor isn't a subtype of 'B'.
}

class C extends A {}
''');

    var element = result.findElement.unnamedConstructor('A');
    assertElementIndexText(result, element, r'''
42 6:3 |B| IS_INVOKED_BY qualified
49 7:3 |B.bar| IS_INVOKED_BY qualified
79 8:22 || IS_REFERENCED_BY qualified
90 11:7 |C| IS_INVOKED_BY qualified
''');
  }

  test_ConstructorElement_class_unnamed_newHead() async {
    var result = await _indexTestCode('''
/// [new A] and [A.new]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
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
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var element = result.findElement.unnamedConstructor('A');
    assertElementIndexText(result, element, r'''
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
    var otherFile = getFile('$testPackageLibPath/other.dart');

    var unitResult = await resolveTestCodeWithDiagnostics('''
class A {
  A() {}
}
''');
    var element = unitResult.findElement.unnamedConstructor('A');

    var result = await _indexFileWithDiagnostics(otherFile, '''
import 'test.dart';

void f() {
  A();
}
''');

    assertElementIndexText(result, element, r'''
35 4:4 || IS_INVOKED_BY qualified
''');
  }

  test_ConstructorElement_class_unnamed_primary() async {
    var result = await _indexTestCode('''
/// [new A] and [A.new]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
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
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var element = result.findElement.unnamedConstructor('A');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
/// [new A] and [A.new]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
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
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var element = result.findElement.unnamedConstructor('A');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
/// [new A] and [A.new]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
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
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var element = result.findElement.unnamedConstructor('A');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
class M {}
class A {
  A() {}
  A.named() {}
}
class B = A with M;
//               ^
// [diag.classUsedAsMixin] The class 'M' can't be used as a mixin because it's neither a mixin class nor a mixin.
class C = B with M;
//               ^
// [diag.classUsedAsMixin] The class 'M' can't be used as a mixin because it's neither a mixin class nor a mixin.
void useConstructor() {
  B();
  B.named();
  C();
  C.named();
}
''');
    var constructor = result.findElement.unnamedConstructor('A');
    assertElementIndexText(result, constructor, r'''
114 9:4 || IS_INVOKED_BY qualified
134 11:4 || IS_INVOKED_BY qualified
''');

    var constructorNamed = result.findElement.constructor('named', of: 'A');
    assertElementIndexText(result, constructorNamed, r'''
121 10:4 |.named| IS_INVOKED_BY qualified
141 12:4 |.named| IS_INVOKED_BY qualified
''');
  }

  test_ConstructorElement_classTypeAlias_cycle() async {
    await _indexTestCode('''
class M {}
class A = B with M;
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: B, A.
//               ^
// [diag.classUsedAsMixin] The class 'M' can't be used as a mixin because it's neither a mixin class nor a mixin.
class B = A with M;
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, A.
//               ^
// [diag.classUsedAsMixin] The class 'M' can't be used as a mixin because it's neither a mixin class nor a mixin.
void useConstructor() {
  A();
  B();
}
''');
    // No additional validation, but it should not fail with stack overflow.
  }

  test_ConstructorElement_enum_annotation() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

enum E {
  v;
  const E();
  const E.named();
}

@E()
@p.E()
@E.named()
@p.E.named()
void f() {}
''');

    var unnamed = result.findElement.unnamedConstructor('E');
    assertElementIndexText(result, unnamed, r'''
38 4:4 || IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
77 9:3 || IS_INVOKED_BY qualified
84 10:5 || IS_INVOKED_BY qualified
''');

    var named = result.findElement.constructor('named');
    assertElementIndexText(result, named, r'''
89 11:3 |.named| IS_INVOKED_BY qualified
102 12:5 |.named| IS_INVOKED_BY qualified
''');
  }

  test_ConstructorElement_enum_named_newHead() async {
    var result = await _indexTestCode('''
/// [new E.foo] and [E.foo]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
enum E {
  v.foo();
  const new foo();
  const new bar() : this.foo();
//          ^^^
// [diag.unusedElement] The declaration 'E.bar' isn't referenced.
  const factory baz() = E.foo;
//                      ^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
void useConstructor() {
  E.foo();
//^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
  E.foo;
//^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructorTearoff] Generative enum constructors can't be torn off.
  E a = .foo();
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//       ^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
''');
    var element = result.findElement.constructor('foo');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
/// [new E.foo] and [E.foo]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
enum E.foo() {
  v.foo();
  const new bar() : this.foo();
//          ^^^
// [diag.unusedElement] The declaration 'E.bar' isn't referenced.
  const factory baz() = E.foo;
//                      ^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
void useConstructor() {
  E.foo();
//^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
  E.foo;
//^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructorTearoff] Generative enum constructors can't be torn off.
  E a = .foo();
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//       ^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
''');
    var element = result.findElement.constructor('foo');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
/// [new E.foo] and [E.foo]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
enum E {
  v.foo();
  const E.foo();
  const E.bar() : this.foo();
//        ^^^
// [diag.unusedElement] The declaration 'E.bar' isn't referenced.
  const factory E.baz() = E.foo;
//                        ^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
void useConstructor() {
  E.foo();
//^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
  E.foo;
//^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructorTearoff] Generative enum constructors can't be torn off.
  E a = .foo();
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//       ^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
''');
    var element = result.findElement.constructor('foo');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
/// [new E] and [E.new]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
enum E {
  v1,
  v2(),
  v3.new();
  const factory E.other() = E;
//                          ^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
void useConstructor() {
  E();
//^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
  E.new;
//^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructorTearoff] Generative enum constructors can't be torn off.
  E a = .new();
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//       ^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
''');
    var element = result.findElement.unnamedConstructor('E');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
/// [new E] and [E.new]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
enum E {
  v1,
  v2(),
  v3.new();
  const new ();
  const factory other() = E.new;
//                        ^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
void useConstructor() {
  E();
//^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
  E.new;
//^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructorTearoff] Generative enum constructors can't be torn off.
  E a = .new();
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//       ^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
''');
    var element = result.findElement.unnamedConstructor('E');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
/// [new E] and [E.new]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
enum E() {
  v1,
  v2(),
  v3.new();
  const factory other() = E.new;
//                        ^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
void useConstructor() {
  E();
//^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
  E.new;
//^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructorTearoff] Generative enum constructors can't be torn off.
  E a = .new();
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//       ^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
''');
    var element = result.findElement.unnamedConstructor('E');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
/// [new E] and [E.new]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
enum E {
  v1,
  v2(),
  v3.new();
  const E();
  const factory E.other() = E;
//                          ^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
void useConstructor() {
  E();
//^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
  E.new;
//^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructorTearoff] Generative enum constructors can't be torn off.
  E a = .new();
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//       ^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
''');
    var element = result.findElement.unnamedConstructor('E');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
/// [new E] and [E.new]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
enum E {
  v1,
  v2(),
  v3.new();
  const E.new();
  const factory E.other() = E.new;
//                          ^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
void useConstructor() {
  E();
//^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
  E.new;
//^^^^^
// [diag.invalidReferenceToGenerativeEnumConstructorTearoff] Generative enum constructors can't be torn off.
  E a = .new();
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//       ^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
''');
    var element = result.findElement.unnamedConstructor('E');
    assertElementIndexText(result, element, r'''
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

  test_ConstructorElement_extensionType_annotation() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

extension type const A(int it) {
  const A.named(int it) : this(it);
}

@A(0)
@p.A(0)
@A.named(0)
@p.A.named(0)
void f() {}
''');

    var unnamed = result.findElement.unnamedConstructor('A');
    assertElementIndexText(result, unnamed, r'''
89 4:31 || IS_INVOKED_BY qualified
100 7:3 || IS_INVOKED_BY qualified
108 8:5 || IS_INVOKED_BY qualified
''');

    var named = result.findElement.constructor('named');
    assertElementIndexText(result, named, r'''
114 9:3 |.named| IS_INVOKED_BY qualified
128 10:5 |.named| IS_INVOKED_BY qualified
''');
  }

  test_ConstructorElement_extensionType_named_newHead() async {
    var result = await _indexTestCode('''
/// [new A.foo] and [A.foo]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
extension type A(int it) {
  new foo(this.it);
  new bar() : this.foo(0);
  factory baz(int it) = A.foo;
}
void useConstructor() {
  A.foo(0);
  A.foo;
  A a = .foo(0);
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var element = result.findElement.constructor('foo');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
/// [new A.foo] and [A.foo]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
extension type A.foo(int it) {
  new bar() : this.foo(0);
  factory baz(int it) = A.foo;
}
void useConstructor() {
  A.foo(0);
  A.foo;
  A a = .foo(0);
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var element = result.findElement.constructor('foo');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
/// [new A.foo] and [A.foo]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
extension type A(int it) {
  A.foo(this.it);
  A.bar() : this.foo(0);
  factory A.baz(int it) = A.foo;
}
void useConstructor() {
  A.foo(0);
  A.foo;
  A a = .foo(0);
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var element = result.findElement.constructor('foo');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
/// [new A] and [A.new]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
extension type A.named(int it) {
  new (this.it);
  new bar() : this(0);
  factory baz(int it) = A.new;
}
void useConstructor() {
  A(0);
  A.new;
  A a = .new(0);
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var element = result.findElement.unnamedConstructor('A');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
/// [new A] and [A.new]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
extension type A(int it) {
  new bar() : this(0);
  factory baz(int it) = A.new;
}
void useConstructor() {
  A(0);
  A.new;
  A a = .new(0);
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var element = result.findElement.unnamedConstructor('A');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
/// [new A] and [A.new]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
extension type A.named(int it) {
  A(this.it);
  A.bar() : this(0);
  factory A.baz(int it) = A.new;
}
void useConstructor() {
  A(0);
  A.new;
  A a = .new(0);
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var element = result.findElement.unnamedConstructor('A');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
/// [new A] and [A.new]
//   ^^^
// [diag.deprecatedNewInCommentReference] Using the 'new' keyword in a comment reference is deprecated.
extension type A.named(int it) {
  A.new(this.it);
  A.bar() : this.new(0);
  factory A.baz(int it) = A.new;
}
void useConstructor() {
  A.new(0);
  A.new;
  A a = .new(0);
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var element = result.findElement.unnamedConstructor('A');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
dynamic f() {}
''');
    expect(result.index.usedElementOffsets, isEmpty);
  }

  test_EnumElement_emptyBody() async {
    await _indexTestCode(r'''
enum E;
//   ^
// [diag.enumWithoutConstants] The enum must have at least one enum constant.
''');
  }

  test_EnumElement_reference_annotation() async {
    var result = await _indexTestCode(r'''
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

    var element = result.findElement.enum_('E');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

enum E { v }

/// [E] and [p.E].
void f() {}
''');

    var element = result.findElement.enum_('E');
    assertElementIndexText(result, element, r'''
45 5:6 |E| IS_REFERENCED_BY
55 5:16 |E| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_EnumElement_reference_instanceCreation() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

enum E {
  v;
  const E();
}

void f() {
  const E();
//      ^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
  const p.E();
//      ^^^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
''');

    var element = result.findElement.enum_('E');
    assertElementIndexText(result, element, r'''
48 5:9 |E| IS_REFERENCED_BY
75 9:9 |E| IS_REFERENCED_BY
90 10:11 |E| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_EnumElement_reference_memberAccess() async {
    var result = await _indexTestCode(r'''
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

    var element = result.findElement.enum_('E');
    assertElementIndexText(result, element, r'''
79 9:3 |E| IS_REFERENCED_BY
92 10:5 |E| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_EnumElement_reference_namedType() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

enum E { v }

void f() {
  E v1;
//  ^^
// [diag.unusedLocalVariable] The value of the local variable 'v1' isn't used.
  p.E v2;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 'v2' isn't used.
}
''');

    var element = result.findElement.enum_('E');
    assertElementIndexText(result, element, r'''
53 6:3 |E| IS_REFERENCED_BY
63 7:5 |E| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ExtensionElement_emptyBody() async {
    await _indexTestCode(r'''
extension E on int;
''');
  }

  test_ExtensionElement_reference_memberAccess() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

extension E on int {
  static void foo() {}
}

void f() {
  E.foo();
  p.E.foo();
}
''');

    var element = result.findElement.extension_('E');
    assertElementIndexText(result, element, r'''
86 8:3 |E| IS_REFERENCED_BY
99 9:5 |E| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ExtensionElement_reference_override() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

extension E on int {
  void foo() {}
}

void f() {
  E(0).foo();
  p.E(0).foo();
}
''');

    var element = result.findElement.extension_('E');
    assertElementIndexText(result, element, r'''
79 8:3 |E| IS_REFERENCED_BY
95 9:5 |E| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ExtensionTypeElement_hierarchy_extensionType_implements() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

extension type A(int it) {}

extension type B(int it) implements A {}
extension type B_q(int it) implements p.A {}
''');

    var element = result.findElement.extensionType('A');
    assertElementIndexText(result, element, r'''
91 5:37 |A| IS_IMPLEMENTED_BY
91 5:37 |A| IS_REFERENCED_BY
136 6:41 |A| IS_IMPLEMENTED_BY qualified
136 6:41 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ExtensionTypeElement_reference_annotation() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

extension type const A(int it) {}

@A(0)
@p.A(0)
void f() {}
''');

    var element = result.findElement.extensionType('A');
    assertElementIndexText(result, element, r'''
62 5:2 |A| IS_REFERENCED_BY
70 6:4 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ExtensionTypeElement_reference_comment() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

extension type A(int it) {}

/// [A] and [p.A].
void f() {}
''');

    var element = result.findElement.extensionType('A');
    assertElementIndexText(result, element, r'''
60 5:6 |A| IS_REFERENCED_BY
70 5:16 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ExtensionTypeElement_reference_instanceCreation() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

extension type A(int it) {}

void f() {
  A(0);
  p.A(0);
}
''');

    var element = result.findElement.extensionType('A');
    assertElementIndexText(result, element, r'''
68 6:3 |A| IS_REFERENCED_BY
78 7:5 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ExtensionTypeElement_reference_memberAccess() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

extension type A(int it) {
  static void foo() {}
}

void f() {
  A.foo();
  p.A.foo();
}
''');

    var element = result.findElement.extensionType('A');
    assertElementIndexText(result, element, r'''
92 8:3 |A| IS_REFERENCED_BY
105 9:5 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ExtensionTypeElement_reference_namedType() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

extension type A(int it) {}

void f() {
  A v1;
//  ^^
// [diag.unusedLocalVariable] The value of the local variable 'v1' isn't used.
  p.A v2;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable 'v2' isn't used.
}
''');

    var element = result.findElement.extensionType('A');
    assertElementIndexText(result, element, r'''
68 6:3 |A| IS_REFERENCED_BY
78 7:5 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_FieldElement_ofClass_instance() async {
    var result = await _indexTestCode('''
/// [foo] and [A.foo]
class A {
  int foo;
  A({this.foo});
//        ^^^
// [diag.missingDefaultValueForParameter] The parameter 'foo' can't have a value of 'null' because of its type, but the implicit default value is 'null'.
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

    var field = result.findElement.class_('A').getField('foo')!;
    assertElementIndexText(result, field, r'''
53 4:11 |foo| IS_WRITTEN_BY qualified
72 5:13 |foo| IS_WRITTEN_BY qualified
''');

    assertElementIndexText(result, field.getter!, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
106 8:5 |foo| IS_REFERENCED_BY
133 10:10 |foo| IS_REFERENCED_BY qualified
188 16:5 |foo| IS_REFERENCED_BY qualified
''');

    assertElementIndexText(result, field.setter!, r'''
115 9:5 |foo| IS_REFERENCED_BY
147 11:10 |foo| IS_REFERENCED_BY qualified
197 17:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_FieldElement_ofClass_instance_synthetic_hasGetter() async {
    var result = await _indexTestCode('''
class A {
  A() : foo = 0;
//      ^^^^^^^
// [diag.initializerForNonExistentField] 'foo' isn't a field in the enclosing class.
  int get foo => 0;
}
''');
    var element = result.findElement.field('foo');
    assertElementIndexText(result, element, r'''
18 2:9 |foo| IS_WRITTEN_BY qualified
''');
  }

  test_FieldElement_ofClass_instance_synthetic_hasGetterSetter() async {
    var result = await _indexTestCode('''
class A {
  A() : foo = 0;
//      ^^^^^^^
// [diag.initializerForNonExistentField] 'foo' isn't a field in the enclosing class.
  int get foo => 0;
  set foo(_) {}
}
''');
    var element = result.findElement.field('foo');
    assertElementIndexText(result, element, r'''
18 2:9 |foo| IS_WRITTEN_BY qualified
''');
  }

  test_FieldElement_ofClass_instance_synthetic_hasSetter() async {
    var result = await _indexTestCode('''
class A {
  A() : foo = 0;
//      ^^^^^^^
// [diag.initializerForNonExistentField] 'foo' isn't a field in the enclosing class.
  set foo(_) {}
}
''');
    var element = result.findElement.field('foo');
    assertElementIndexText(result, element, r'''
18 2:9 |foo| IS_WRITTEN_BY qualified
''');
  }

  test_FieldElement_ofClass_static() async {
    var result = await _indexTestCode('''
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
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//      ^^^^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'A'.
}
''');

    var field = result.findElement.class_('A').getField('foo')!;

    assertElementIndexText(result, field.getter!, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
85 5:5 |foo| IS_REFERENCED_BY
109 7:7 |foo| IS_REFERENCED_BY qualified
158 13:5 |foo| IS_REFERENCED_BY qualified
185 15:10 |foo| IS_REFERENCED_BY qualified
''');

    assertElementIndexText(result, field.setter!, r'''
94 6:5 |foo| IS_REFERENCED_BY
120 8:7 |foo| IS_REFERENCED_BY qualified
167 14:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_FieldElement_ofEnum_instance() async {
    var result = await _indexTestCode('''
/// [foo] and [E.foo]
enum E {
  v;
  int? foo; // a compile-time error
//     ^^^
// [diag.nonFinalFieldInEnum] Enums can only declare final fields.
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
//^
// [diag.invalidReferenceToGenerativeEnumConstructor] Generative enum constructors can only be used to create an enum constant.
}
''');
    var field = result.findElement.field('foo');
    var getter = field.getter!;
    var setter = field.setter!;

    assertElementIndexText(result, field, r'''
82 5:11 |foo| IS_WRITTEN_BY qualified
''');

    assertElementIndexText(result, getter, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
113 7:5 |foo| IS_REFERENCED_BY
162 12:5 |foo| IS_REFERENCED_BY qualified
''');

    assertElementIndexText(result, setter, r'''
122 8:5 |foo| IS_REFERENCED_BY
171 13:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_FieldElement_ofEnum_instance_index() async {
    var result = await _indexTestCode('''
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

    var index = result.resolvedUnit.typeProvider.enumElement!.getGetter(
      'index',
    )!;
    assertElementIndexText(result, index, r'''
69 6:13 |index| IS_REFERENCED_BY qualified
''');
  }

  test_FieldElement_ofEnum_instance_synthetic_hasGetter() async {
    var result = await _indexTestCode('''
enum E {
  v;
  E() : foo = 0;
//      ^^^^^^^
// [diag.initializerForNonExistentField] 'foo' isn't a field in the enclosing class.
  int get foo => 0;
}
''');
    var element = result.findElement.field('foo');
    assertElementIndexText(result, element, r'''
22 3:9 |foo| IS_WRITTEN_BY qualified
''');
  }

  test_FieldElement_ofEnum_instance_synthetic_hasGetterSetter() async {
    var result = await _indexTestCode('''
enum E {
  v;
  E() : foo = 0;
//      ^^^^^^^
// [diag.initializerForNonExistentField] 'foo' isn't a field in the enclosing class.
  int get foo => 0;
  set foo(_) {}
}
''');
    var element = result.findElement.field('foo');
    assertElementIndexText(result, element, r'''
22 3:9 |foo| IS_WRITTEN_BY qualified
''');
  }

  test_FieldElement_ofEnum_instance_synthetic_hasSetter() async {
    var result = await _indexTestCode('''
enum E {
  v;
  E() : foo = 0;
//      ^^^^^^^
// [diag.initializerForNonExistentField] 'foo' isn't a field in the enclosing class.
  set foo(_) {}
}
''');
    var element = result.findElement.field('foo');
    assertElementIndexText(result, element, r'''
22 3:9 |foo| IS_WRITTEN_BY qualified
''');
  }

  test_FieldElement_ofEnum_static_constants() async {
    var result = await _indexTestCode(r'''
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

    assertElementIndexText(result, result.findElement.getter('values'), r'''
116 8:10 |values| IS_REFERENCED_BY qualified
195 13:12 |values| IS_REFERENCED_BY qualified
''');

    assertElementIndexText(result, result.findElement.getter('v1'), r'''
31 3:6 |v1| IS_REFERENCED_BY
44 3:19 |v1| IS_REFERENCED_BY qualified
63 3:38 |v1| IS_REFERENCED_BY qualified
133 9:10 |v1| IS_REFERENCED_BY qualified
152 10:10 |v1| IS_REFERENCED_BY qualified
180 12:12 |v1| IS_REFERENCED_BY qualified
''');

    assertElementIndexText(result, result.findElement.getter('v2'), r'''
165 11:10 |v2| IS_REFERENCED_BY qualified
''');
  }

  test_FieldElement_ofExtensionType_static() async {
    var result = await _indexTestCode('''
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
    var field = result.findElement.field('foo');
    var getter = field.getter!;
    var setter = field.setter!;

    assertElementIndexText(result, getter, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
95 5:5 |foo| IS_REFERENCED_BY
141 10:5 |foo| IS_REFERENCED_BY qualified
''');

    assertElementIndexText(result, setter, r'''
104 6:5 |foo| IS_REFERENCED_BY
150 11:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_fieldFormalParameter_noSuchField() async {
    await _indexTestCode('''
class B<T> {
  B({this.x}) {}
//   ^^^^^^
// [diag.initializingFormalForNonExistentField] 'x' isn't a field in the enclosing class.

  foo() {
    B<int>(x: 1);
  }
}
''');
    // No exceptions.
  }

  test_FieldFormalParameterElement_ofConstructor_optionalNamed_dotShorthand() async {
    var result = await _indexTestCode('''
class A {
  A({this.test}) : assert(test != null);
  int? test;
}
void foo() {
  A _ = .new(test: 0);
}
''');
    var element = result.findElement.fieldFormalParameter('test');
    assertElementIndexText(result, element, r'''
36 2:27 |test| IS_READ_BY
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
    await _indexTestCode(r"""
import 'a.dart';
import 'b.dart';

void f() {
  foo(test: 0);
//^^^
// [diag.ambiguousImport] The name 'foo' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
""");
    // No exceptions.
  }

  test_FormalParameterElement_ofConstructor_primary_optionalNamed() async {
    var result = await _indexTestCode('''
class A({int? test}) {
  /// [test]
  this : assert(test != null) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
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
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    assertElementIndexText(result, element, r'''
30 2:8 |test| IS_REFERENCED_BY
52 3:17 |test| IS_READ_BY
72 4:5 |test| IS_READ_BY
82 5:5 |test| IS_WRITTEN_BY
96 6:5 |test| IS_READ_WRITTEN_BY
112 7:6 |test| IS_WRITTEN_BY
136 8:10 |test| IS_WRITTEN_BY
190 11:34 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
237 15:12 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
293 19:26 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
324 23:5 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
347 24:14 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofConstructor_primary_optionalNamed_genericClass() async {
    var result = await _indexTestCode('''
class A<T>({T? test}) {
  /// [test]
  this : assert(test != null) {
    test;
    test = null;
    (test,) = (null,);
    for (test in [null]) {}
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
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    assertElementIndexText(result, element, r'''
31 2:8 |test| IS_REFERENCED_BY
53 3:17 |test| IS_READ_BY
73 4:5 |test| IS_READ_BY
83 5:5 |test| IS_WRITTEN_BY
101 6:6 |test| IS_WRITTEN_BY
128 7:10 |test| IS_WRITTEN_BY
183 10:32 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
236 14:12 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
296 18:24 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
327 22:5 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
355 23:19 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofConstructor_primary_optionalPositional() async {
    var result = await _indexTestCode('''
class A([int? test]) {
  /// [test]
  this : assert(test != null) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
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
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    assertElementIndexText(result, element, r'''
30 2:8 |test| IS_REFERENCED_BY
52 3:17 |test| IS_READ_BY
72 4:5 |test| IS_READ_BY
82 5:5 |test| IS_WRITTEN_BY
96 6:5 |test| IS_READ_WRITTEN_BY
112 7:6 |test| IS_WRITTEN_BY
136 8:10 |test| IS_WRITTEN_BY
231 15:12 |test| IS_REFERENCED_BY qualified
''');
  }

  test_FormalParameterElement_ofConstructor_primary_requiredNamed() async {
    var result = await _indexTestCode('''
class A({required int test}) {
  /// [test]
  this : assert(test != -1) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
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
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    assertElementIndexText(result, element, r'''
38 2:8 |test| IS_REFERENCED_BY
60 3:17 |test| IS_READ_BY
78 4:5 |test| IS_READ_BY
88 5:5 |test| IS_WRITTEN_BY
102 6:5 |test| IS_READ_WRITTEN_BY
118 7:6 |test| IS_WRITTEN_BY
142 8:10 |test| IS_WRITTEN_BY
204 11:42 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
260 15:21 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
324 19:34 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
355 23:5 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
378 24:14 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofConstructor_primary_requiredPositional() async {
    var result = await _indexTestCode('''
class A(int test) {
  /// [test]
  this : assert(test != -1) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
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
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    assertElementIndexText(result, element, r'''
27 2:8 |test| IS_REFERENCED_BY
49 3:17 |test| IS_READ_BY
67 4:5 |test| IS_READ_BY
77 5:5 |test| IS_WRITTEN_BY
91 6:5 |test| IS_READ_WRITTEN_BY
107 7:6 |test| IS_WRITTEN_BY
131 8:10 |test| IS_WRITTEN_BY
222 15:11 |test| IS_REFERENCED_BY qualified
''');
  }

  test_FormalParameterElement_ofConstructor_typeName_optionalNamed() async {
    var result = await _indexTestCode('''
class A {
  /// [test]
  A({int? test}) : assert(test != null) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
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
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    assertElementIndexText(result, element, r'''
17 2:8 |test| IS_REFERENCED_BY
49 3:27 |test| IS_READ_BY
69 4:5 |test| IS_READ_BY
79 5:5 |test| IS_WRITTEN_BY
93 6:5 |test| IS_READ_WRITTEN_BY
109 7:6 |test| IS_WRITTEN_BY
133 8:10 |test| IS_WRITTEN_BY
187 11:34 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
234 15:12 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
290 19:26 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
321 23:5 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
344 24:14 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofConstructor_typeName_optionalNamed_const() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {
  /// [test]
  const A({int? test}) : assert(test != null);
  const A.redirect({int? test}) : this(test: test);
}

class B extends A {
  const B({super.test});
}

class C extends A {
  const C({int? test}) : super(test: test);
}

@A(test: 0)
@p.A(test: 1)
void f() {
  const A(test: 2);
  A _ = .new(test: 3);
}
''');
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    assertElementIndexText(result, element, r'''
43 4:8 |test| IS_REFERENCED_BY
81 5:33 |test| IS_READ_BY
135 6:40 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
188 10:18 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
250 14:32 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
269 17:4 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
283 18:6 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
313 20:11 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
336 21:14 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofConstructor_typeName_optionalNamed_genericClass() async {
    var result = await _indexTestCode('''
class A<T> {
  /// [test]
  A({T? test}) : assert(test != null) {
    test;
    test = null;
    (test,) = (null,);
    for (test in [null]) {}
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
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    assertElementIndexText(result, element, r'''
20 2:8 |test| IS_REFERENCED_BY
50 3:25 |test| IS_READ_BY
70 4:5 |test| IS_READ_BY
80 5:5 |test| IS_WRITTEN_BY
98 6:6 |test| IS_WRITTEN_BY
125 7:10 |test| IS_WRITTEN_BY
180 10:32 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
233 14:12 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
293 18:24 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
324 22:5 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
352 23:19 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofConstructor_typeName_optionalPositional() async {
    var result = await _indexTestCode('''
class A {
  /// [test]
  A([int? test]) : assert(test != null) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
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
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    assertElementIndexText(result, element, r'''
17 2:8 |test| IS_REFERENCED_BY
49 3:27 |test| IS_READ_BY
69 4:5 |test| IS_READ_BY
79 5:5 |test| IS_WRITTEN_BY
93 6:5 |test| IS_READ_WRITTEN_BY
109 7:6 |test| IS_WRITTEN_BY
133 8:10 |test| IS_WRITTEN_BY
228 15:12 |test| IS_REFERENCED_BY qualified
''');
  }

  test_FormalParameterElement_ofConstructor_typeName_requiredNamed() async {
    var result = await _indexTestCode('''
class A {
  /// [test]
  A({required int test}) : assert(test != -1) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
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
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    assertElementIndexText(result, element, r'''
17 2:8 |test| IS_REFERENCED_BY
57 3:35 |test| IS_READ_BY
75 4:5 |test| IS_READ_BY
85 5:5 |test| IS_WRITTEN_BY
99 6:5 |test| IS_READ_WRITTEN_BY
115 7:6 |test| IS_WRITTEN_BY
139 8:10 |test| IS_WRITTEN_BY
201 11:42 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
257 15:21 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
321 19:34 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
352 23:5 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
375 24:14 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofConstructor_typeName_requiredPositional() async {
    var result = await _indexTestCode('''
class A {
  /// [test]
  A(int test) : assert(test != -1) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
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
    var element = result.findElement.unnamedConstructor('A').parameter('test');
    assertElementIndexText(result, element, r'''
17 2:8 |test| IS_REFERENCED_BY
46 3:24 |test| IS_READ_BY
64 4:5 |test| IS_READ_BY
74 5:5 |test| IS_WRITTEN_BY
88 6:5 |test| IS_READ_WRITTEN_BY
104 7:6 |test| IS_WRITTEN_BY
128 8:10 |test| IS_WRITTEN_BY
219 15:11 |test| IS_REFERENCED_BY qualified
''');
  }

  test_FormalParameterElement_ofGenericFunctionType_optionalNamed() async {
    await _indexTestCode('''
typedef F = void Function({int? test});

void g(F f) {
  f(test: 0);
}
''');
    // We should not crash because of reference to "test" - a named parameter
    // of a generic function type.
  }

  test_FormalParameterElement_ofGenericFunctionType_optionalNamed_call() async {
    await _indexTestCode('''
typedef F<T> = void Function({T? test});

void g(F<int> f) {
  f.call(test: 0);
}
''');
    // No exceptions.
  }

  test_FormalParameterElement_ofLocalFunction_optionalNamed() async {
    var result = await _indexTestCode('''
void f() {
  /// [test]
  void foo({int? test}) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }

  foo(test: 0);
  foo.call(test: 1);
  (foo)(test: 2);
}
''');
    var element = result.findElement.parameter('test');
    assertElementIndexText(result, element, r'''
''');
  }

  test_FormalParameterElement_ofLocalFunction_optionalPositional() async {
    var result = await _indexTestCode('''
void f() {
  /// [test]
  void foo([int? test]) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }

  foo(0);
  foo.call(1);
  (foo)(2);
}
''');
    var element = result.findElement.parameter('test');
    assertElementIndexText(result, element, r'''
''');
  }

  test_FormalParameterElement_ofLocalFunction_requiredNamed() async {
    var result = await _indexTestCode('''
void f() {
  /// [test]
  void foo({required int test}) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }

  foo(test: 0);
  foo.call(test: 1);
  (foo)(test: 2);
}
''');
    var element = result.findElement.parameter('test');
    assertElementIndexText(result, element, r'''
''');
  }

  test_FormalParameterElement_ofLocalFunction_requiredPositional() async {
    var result = await _indexTestCode('''
void f() {
  /// [test]
  void foo(int test) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }

  foo(0);
  foo.call(1);
  (foo)(2);
}
''');
    var element = result.findElement.parameter('test');
    assertElementIndexText(result, element, r'''
''');
  }

  test_FormalParameterElement_ofMethod_optionalNamed() async {
    var result = await _indexTestCode('''
class A {
  /// [test]
  void foo({int? test}) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }
}

void f(A a) {
  a.foo(test: 0);
  a.foo.call(test: 1);
  (a.foo)(test: 2);
}
''');
    var element = result.findElement.parameter('test');
    assertElementIndexText(result, element, r'''
17 2:8 |test| IS_REFERENCED_BY
53 4:5 |test| IS_READ_BY
63 5:5 |test| IS_WRITTEN_BY
77 6:5 |test| IS_READ_WRITTEN_BY
93 7:6 |test| IS_WRITTEN_BY
117 8:10 |test| IS_WRITTEN_BY
162 13:9 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
185 14:14 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
205 15:11 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofMethod_optionalNamed_genericClass() async {
    var result = await _indexTestCode('''
class A<T> {
  /// [test]
  void foo({T? test}) {
    test;
    test = null;
    test = test;
    (test,) = (null,);
    for (test in [null]) {}
  }
}

void f(A<int> a) {
  a.foo(test: 0);
  a.foo.call(test: 1);
  (a.foo)(test: 2);
}
''');
    var element = result.findElement.parameter('test');
    assertElementIndexText(result, element, r'''
20 2:8 |test| IS_REFERENCED_BY
54 4:5 |test| IS_READ_BY
64 5:5 |test| IS_WRITTEN_BY
81 6:5 |test| IS_WRITTEN_BY
88 6:12 |test| IS_READ_BY
99 7:6 |test| IS_WRITTEN_BY
126 8:10 |test| IS_WRITTEN_BY
179 13:9 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofMethod_optionalPositional() async {
    var result = await _indexTestCode('''
class A {
  /// [test]
  void foo([int? test]) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }
}

void f(A a) {
  a.foo(0);
  a.foo.call(1);
  (a.foo)(2);
}
''');
    var element = result.findElement.parameter('test');
    assertElementIndexText(result, element, r'''
17 2:8 |test| IS_REFERENCED_BY
53 4:5 |test| IS_READ_BY
63 5:5 |test| IS_WRITTEN_BY
77 6:5 |test| IS_READ_WRITTEN_BY
93 7:6 |test| IS_WRITTEN_BY
117 8:10 |test| IS_WRITTEN_BY
''');
  }

  test_FormalParameterElement_ofMethod_requiredNamed() async {
    var result = await _indexTestCode('''
class A {
  /// [test]
  void foo({required int test}) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }
}

void f(A a) {
  a.foo(test: 0);
  a.foo.call(test: 1);
  (a.foo)(test: 2);
}
''');
    var element = result.findElement.parameter('test');
    assertElementIndexText(result, element, r'''
17 2:8 |test| IS_REFERENCED_BY
61 4:5 |test| IS_READ_BY
71 5:5 |test| IS_WRITTEN_BY
85 6:5 |test| IS_READ_WRITTEN_BY
101 7:6 |test| IS_WRITTEN_BY
125 8:10 |test| IS_WRITTEN_BY
170 13:9 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
193 14:14 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
213 15:11 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofMethod_requiredPositional() async {
    var result = await _indexTestCode('''
class A {
  /// [test]
  void foo(int test) {
    test;
    test = 0;
    test += 0;
    (test,) = (0,);
    for (test in [0]) {}
  }
}

void f(A a) {
  a.foo(0);
  a.foo.call(1);
  (a.foo)(2);
}
''');
    var element = result.findElement.parameter('test');
    assertElementIndexText(result, element, r'''
17 2:8 |test| IS_REFERENCED_BY
50 4:5 |test| IS_READ_BY
60 5:5 |test| IS_WRITTEN_BY
74 6:5 |test| IS_READ_WRITTEN_BY
90 7:6 |test| IS_WRITTEN_BY
114 8:10 |test| IS_WRITTEN_BY
''');
  }

  test_FormalParameterElement_ofTopLevelFunction_optionalNamed() async {
    var result = await _indexTestCode('''
/// [test]
void foo({int? test}) {
  test;
  test = 1;
  test += 2;
  (test,) = (0,);
  for (test in [0]) {}
}
void f() {
  foo(test: 0);
  foo.call(test: 1);
  (foo)(test: 2);
}
''');
    var element = result.findElement.parameter('test');
    assertElementIndexText(result, element, r'''
5 1:6 |test| IS_REFERENCED_BY
37 3:3 |test| IS_READ_BY
45 4:3 |test| IS_WRITTEN_BY
57 5:3 |test| IS_READ_WRITTEN_BY
71 6:4 |test| IS_WRITTEN_BY
93 7:8 |test| IS_WRITTEN_BY
128 10:7 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
149 11:12 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
167 12:9 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofTopLevelFunction_optionalNamed_argumentAnywhere() async {
    var result = await _indexTestCode('''
/// [test]
void foo(int a, int b, {int? test}) {
  test;
  test = 1;
  test += 2;
  (test,) = (0,);
  for (test in [0]) {}
}

void f() {
  foo(0, test: 0, 0);
  foo.call(0, test: 1, 0);
  (foo)(0, test: 2, 0);
}
''');
    var element = result.findElement.parameter('test');
    assertElementIndexText(result, element, r'''
5 1:6 |test| IS_REFERENCED_BY
51 3:3 |test| IS_READ_BY
59 4:3 |test| IS_WRITTEN_BY
71 5:3 |test| IS_READ_WRITTEN_BY
85 6:4 |test| IS_WRITTEN_BY
107 7:8 |test| IS_WRITTEN_BY
146 11:10 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
173 12:15 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
197 13:12 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofTopLevelFunction_optionalPositional() async {
    var result = await _indexTestCode('''
/// [test]
void foo([int? test]) {
  test;
  test = 1;
  test += 2;
  (test,) = (0,);
  for (test in [0]) {}
}
void f() {
  foo(0);
  foo.call(1);
  (foo)(2);
}
''');
    var element = result.findElement.parameter('test');
    assertElementIndexText(result, element, r'''
5 1:6 |test| IS_REFERENCED_BY
37 3:3 |test| IS_READ_BY
45 4:3 |test| IS_WRITTEN_BY
57 5:3 |test| IS_READ_WRITTEN_BY
71 6:4 |test| IS_WRITTEN_BY
93 7:8 |test| IS_WRITTEN_BY
''');
  }

  test_FormalParameterElement_ofTopLevelFunction_requiredNamed() async {
    var result = await _indexTestCode('''
/// [test]
void foo({required int test}) {
  test;
  test = 1;
  test += 2;
  (test,) = (0,);
  for (test in [0]) {}
}

void f() {
  foo(test: 0);
  foo.call(test: 1);
  (foo)(test: 2);
}
''');
    var element = result.findElement.parameter('test');
    assertElementIndexText(result, element, r'''
5 1:6 |test| IS_REFERENCED_BY
45 3:3 |test| IS_READ_BY
53 4:3 |test| IS_WRITTEN_BY
65 5:3 |test| IS_READ_WRITTEN_BY
79 6:4 |test| IS_WRITTEN_BY
101 7:8 |test| IS_WRITTEN_BY
137 11:7 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
158 12:12 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
176 13:9 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_FormalParameterElement_ofTopLevelFunction_requiredPositional() async {
    var result = await _indexTestCode('''
/// [test]
void foo(int test) {
  test;
  test = 1;
  test += 2;
  (test,) = (0,);
  for (test in [0]) {}
}

void f() {
  foo(0);
  foo.call(1);
  (foo)(2);
}
''');
    var element = result.findElement.parameter('test');
    assertElementIndexText(result, element, r'''
5 1:6 |test| IS_REFERENCED_BY
34 3:3 |test| IS_READ_BY
42 4:3 |test| IS_WRITTEN_BY
54 5:3 |test| IS_READ_WRITTEN_BY
68 6:4 |test| IS_WRITTEN_BY
90 7:8 |test| IS_WRITTEN_BY
''');
  }

  test_FormalParameterElement_synthetic_leastUpperBound() async {
    await _indexTestCode('''
int f1({int? test}) => 0;
int f2({int? test}) => 0;
void g(bool b) {
  var f = b ? f1 : f2;
  f(test: 0);
}''');
    // We should not crash because of reference to "test" - a named parameter
    // of a synthetic LUB FunctionElement created for "f".
  }

  test_GetterElement_ofClass_instance() async {
    var result = await _indexTestCode('''
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
    var element = result.findElement.getter('foo');
    assertElementIndexText(result, element, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
77 5:5 |foo| IS_REFERENCED_BY
91 6:10 |foo| IS_REFERENCED_BY qualified
129 11:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_GetterElement_ofClass_invocation() async {
    var result = await _indexTestCode('''
class A {
  get foo => null;
  void useGetter() {
    this.foo();
    foo();
  }
}''');
    var element = result.findElement.getter('foo');
    assertElementIndexText(result, element, r'''
59 4:10 |foo| IS_REFERENCED_BY qualified
70 5:5 |foo| IS_REFERENCED_BY
''');
  }

  test_GetterElement_ofClass_objectPattern() async {
    var result = await _indexTestCode('''
class A {
  int get foo => 0;
}

void useGetter(Object? x) {
  if (x case A(foo: 0)) {}
  if (x case A(: var foo)) {}
//                   ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
}
''');
    var element = result.findElement.getter('foo');
    assertElementIndexText(result, element, r'''
76 6:16 |foo| IS_REFERENCED_BY_PATTERN_FIELD qualified
103 7:16 || IS_REFERENCED_BY_PATTERN_FIELD qualified
''');
  }

  test_GetterElement_ofClass_static() async {
    var result = await _indexTestCode('''
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
    var element = result.findElement.getter('foo');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
export 'lib.dart';
''');
    var export = result.findElement.export('package:test/lib.dart');
    var fragment = export.exportedLibrary!.firstFragment;
    assertLibraryFragmentIndexText(result, fragment, r'''
7 1:8 |'lib.dart'|
''');
  }

  test_LibraryFragment_reference_import() async {
    newFile('$testPackageLibPath/lib.dart', '');
    var result = await _indexTestCode('''
import 'lib.dart';
//     ^^^^^^^^^^
// [diag.unusedImport] Unused import: 'lib.dart'.
''');
    var import = result.findElement.import('package:test/lib.dart');
    var fragment = import.importedLibrary!.firstFragment;
    assertLibraryFragmentIndexText(result, fragment, r'''
7 1:8 |'lib.dart'|
''');
  }

  test_LibraryFragment_reference_part() async {
    newFile('$testPackageLibPath/my_unit.dart', "part of 'test.dart';");
    var result = await _indexTestCode('''
part 'my_unit.dart';
''');
    var fragment = result.findElement.part('package:test/my_unit.dart');
    assertLibraryFragmentIndexText(result, fragment, r'''
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
    await _indexTestCode('''
part 'b.dart';
//   ^^^^^^^^
// [diag.partOfNonPart] The included part 'package:test/b.dart' must have a part-of directive.
''');
    // No exception, even though a.dart is a part of b.dart part.
  }

  test_MethodElement_normal_ofClass_instance() async {
    var result = await _indexTestCode('''
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
//                     ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
  }
}
void useFoo(A a) {
  a.foo();
  a.foo;
}
''');
    var element = result.findElement.method('foo');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
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
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  p.A.foo();
  p.A.foo;
}
''');
    var element = result.findElement.method('foo');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
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
    var element = result.findElement.method('foo');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
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
    var element = result.findElement.method('foo');
    assertElementIndexText(result, element, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
88 6:5 |foo| IS_INVOKED_BY
99 7:5 |foo| IS_REFERENCED_BY
130 11:5 |foo| IS_INVOKED_BY qualified
141 12:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_MethodElement_normal_ofExtension_named_instance() async {
    var result = await _indexTestCode('''
/// [foo] and [E.foo]
extension E on int {
  void foo() {}
}

void useFoo() {
  0.foo();
  0.foo;
}
''');
    var element = result.findElement.method('foo');
    assertElementIndexText(result, element, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
82 7:5 |foo| IS_INVOKED_BY qualified
93 8:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_MethodElement_normal_ofExtension_named_static() async {
    var result = await _indexTestCode('''
/// [foo] and [E.foo]
extension E on int {
  static void foo() {}
}

void useFoo() {
  E.foo();
  E.foo;
}
''');
    var element = result.findElement.method('foo');
    assertElementIndexText(result, element, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
89 7:5 |foo| IS_INVOKED_BY qualified
100 8:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_MethodElement_normal_ofExtension_unnamed_instance() async {
    var result = await _indexTestCode('''
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

    var intMethod = result.resolvedUnit.findNode.methodDeclaration(
      'foo() {} // int',
    );
    assertElementIndexText(result, intMethod.declaredFragment!.element, r'''
5 1:6 |foo| IS_REFERENCED_BY
167 12:5 |foo| IS_INVOKED_BY qualified
178 13:5 |foo| IS_REFERENCED_BY qualified
''');

    var doubleMethod = result.resolvedUnit.findNode.methodDeclaration(
      'foo() {} // double',
    );
    assertElementIndexText(result, doubleMethod.declaredFragment!.element, r'''
74 6:6 |foo| IS_REFERENCED_BY
191 14:9 |foo| IS_INVOKED_BY qualified
206 15:9 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_MethodElement_normal_ofExtensionType_instance() async {
    var result = await _indexTestCode('''
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
    var element = result.findElement.method('foo');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
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
    var element = result.findElement.method('foo');
    assertElementIndexText(result, element, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
101 5:5 |foo| IS_INVOKED_BY
112 6:5 |foo| IS_REFERENCED_BY
143 10:5 |foo| IS_INVOKED_BY qualified
154 11:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_MethodElement_normal_ofMixin_instance() async {
    var result = await _indexTestCode('''
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
    var element = result.findElement.method('foo');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
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
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'm' isn't used.
//      ^^^^^^
// [diag.useOfVoidResult] This expression has a type of 'void' so its value can't be used.
}
''');
    var element = result.findElement.method('foo');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
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
    var element = result.findElement.method('+');
    assertElementIndexText(result, element, r'''
14 1:15 |+| IS_REFERENCED_BY
33 1:34 |+| IS_REFERENCED_BY qualified
105 6:5 |+| IS_INVOKED_BY qualified
114 7:5 |+=| IS_INVOKED_BY qualified
122 8:3 |++| IS_INVOKED_BY qualified
130 9:4 |++| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofClass_index() async {
    var result = await _indexTestCode('''
/// [operator []] and [A.operator []]
class A {
  operator [](i) => null;
}
void useOperator(A a) {
  a[0];
}
''');
    var element = result.findElement.method('[]');
    assertElementIndexText(result, element, r'''
103 6:4 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofClass_indexEq() async {
    var result = await _indexTestCode('''
/// [operator []=] and [A.operator []=]
class A {
  operator []=(i, v) {}
}
void useOperator(A a) {
  a[1] = 42;
}
''');
    var element = result.findElement.method('[]=');
    assertElementIndexText(result, element, r'''
103 6:4 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofClass_prefix() async {
    var result = await _indexTestCode('''
/// [operator ~] and [A.operator ~]
class A {
  A operator ~() => this;
}
void useOperator(A a) {
  ~a;
}
''');
    var element = result.findElement.method('~');
    assertElementIndexText(result, element, r'''
14 1:15 |~| IS_REFERENCED_BY
33 1:34 |~| IS_REFERENCED_BY qualified
100 6:3 |~| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofEnum_binary() async {
    var result = await _indexTestCode('''
/// [operator +] and [E.operator +]
enum E {
  v;
  int operator +(other) => 0;
}
void useOperator(E e) {
  e + 1;
  e += 2;
//     ^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'E'.
  ++e;
//^^^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'E'.
  e++;
//^^^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'E'.
}
''');
    var element = result.findElement.method('+');
    assertElementIndexText(result, element, r'''
14 1:15 |+| IS_REFERENCED_BY
33 1:34 |+| IS_REFERENCED_BY qualified
110 7:5 |+| IS_INVOKED_BY qualified
119 8:5 |+=| IS_INVOKED_BY qualified
127 9:3 |++| IS_INVOKED_BY qualified
135 10:4 |++| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofEnum_index() async {
    var result = await _indexTestCode('''
/// [operator []] and [E.operator []]
enum E {
  v;
  int operator [](int index) => 0;
}
void useOperator(E e) {
  e[0];
}
''');
    var element = result.findElement.method('[]');
    assertElementIndexText(result, element, r'''
116 7:4 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofEnum_indexEq() async {
    var result = await _indexTestCode('''
/// [operator []=] and [E.operator []=]
enum E {
  v;
  operator []=(int index, int value) {}
}
void useOperator(E e) {
  e[1] = 42;
}
''');
    var element = result.findElement.method('[]=');
    assertElementIndexText(result, element, r'''
123 7:4 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofEnum_prefix() async {
    var result = await _indexTestCode('''
/// [operator ~] and [E.operator ~]
enum E {
  e;
  int operator ~() => 0;
}
void useOperator(E e) {
  ~e;
}
''');
    var element = result.findElement.method('~');
    assertElementIndexText(result, element, r'''
14 1:15 |~| IS_REFERENCED_BY
33 1:34 |~| IS_REFERENCED_BY qualified
103 7:3 |~| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofExtension_binary() async {
    var result = await _indexTestCode('''
/// [operator +] and [E.operator +]
extension E on int {
  int operator +(int other) => 0;
}
void useOperator(int e) {
  E(e) + 1;
}
''');
    var element = result.findElement.method('+');
    assertElementIndexText(result, element, r'''
14 1:15 |+| IS_REFERENCED_BY
33 1:34 |+| IS_REFERENCED_BY qualified
126 6:8 |+| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofExtension_index() async {
    var result = await _indexTestCode('''
/// [operator []] and [E.operator []]
extension E on int {
  int operator [](int index) => 0;
}
void useOperator(int e) {
  E(e)[0];
}
''');
    var element = result.findElement.method('[]');
    assertElementIndexText(result, element, r'''
128 6:7 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofExtension_indexEq() async {
    var result = await _indexTestCode('''
/// [operator []=] and [E.operator []=]
extension E on int {
  operator []=(int index, int value) {}
}
void useOperator(int e) {
  E(e)[1] = 42;
}
''');
    var element = result.findElement.method('[]=');
    assertElementIndexText(result, element, r'''
135 6:7 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofExtension_prefix() async {
    var result = await _indexTestCode('''
/// [operator ~] and [E.operator ~]
extension E on int {
  int operator ~() => 0;
}
void useOperator(int e) {
  ~E(e);
}
''');
    var element = result.findElement.method('~');
    assertElementIndexText(result, element, r'''
14 1:15 |~| IS_REFERENCED_BY
33 1:34 |~| IS_REFERENCED_BY qualified
112 6:3 |~| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofExtensionType_binary() async {
    var result = await _indexTestCode('''
/// [operator +] and [A.operator +]
extension type A(int it) {
  int operator +(int other) => 0;
}
void useOperator(A a) {
  a + 1;
  a += 2;
//     ^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'A'.
  ++a;
//^^^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'A'.
  a++;
//^^^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'A'.
}
''');
    var element = result.findElement.method('+');
    assertElementIndexText(result, element, r'''
14 1:15 |+| IS_REFERENCED_BY
33 1:34 |+| IS_REFERENCED_BY qualified
127 6:5 |+| IS_INVOKED_BY qualified
136 7:5 |+=| IS_INVOKED_BY qualified
144 8:3 |++| IS_INVOKED_BY qualified
152 9:4 |++| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofExtensionType_index() async {
    var result = await _indexTestCode('''
/// [operator []] and [A.operator []]
extension type A(int it) {
  int operator [](int index) => 0;
}
void useOperator(A a) {
  a[0];
}
''');
    var element = result.findElement.method('[]');
    assertElementIndexText(result, element, r'''
129 6:4 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofExtensionType_indexEq() async {
    var result = await _indexTestCode('''
/// [operator []=] and [A.operator []=]
extension type A(int it) {
  operator []=(int index, int value) {}
}
void useOperator(A a) {
  a[1] = 42;
}
''');
    var element = result.findElement.method('[]=');
    assertElementIndexText(result, element, r'''
136 6:4 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofExtensionType_prefix() async {
    var result = await _indexTestCode('''
/// [operator ~] and [A.operator ~]
extension type A(int it) {
  int operator ~() => 0;
}
void useOperator(A a) {
  ~a;
}
''');
    var element = result.findElement.method('~');
    assertElementIndexText(result, element, r'''
14 1:15 |~| IS_REFERENCED_BY
33 1:34 |~| IS_REFERENCED_BY qualified
116 6:3 |~| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofMixin_binary() async {
    var result = await _indexTestCode('''
/// [operator +] and [M.operator +]
mixin M {
  int operator +(int other) => 0;
}
void useOperator(M m) {
  m + 1;
  m += 2;
//     ^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'M'.
  ++m;
//^^^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'M'.
  m++;
//^^^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'M'.
}
''');
    var element = result.findElement.method('+');
    assertElementIndexText(result, element, r'''
14 1:15 |+| IS_REFERENCED_BY
33 1:34 |+| IS_REFERENCED_BY qualified
110 6:5 |+| IS_INVOKED_BY qualified
119 7:5 |+=| IS_INVOKED_BY qualified
127 8:3 |++| IS_INVOKED_BY qualified
135 9:4 |++| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofMixin_index() async {
    var result = await _indexTestCode('''
/// [operator []] and [M.operator []]
mixin M {
  int operator [](int index) => 0;
}
void useOperator(M m) {
  m[0];
}
''');
    var element = result.findElement.method('[]');
    assertElementIndexText(result, element, r'''
112 6:4 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofMixin_indexEq() async {
    var result = await _indexTestCode('''
/// [operator []=] and [M.operator []=]
mixin M {
  operator []=(int index, int value) {}
}
void useOperator(M m) {
  m[1] = 42;
}
''');
    var element = result.findElement.method('[]=');
    assertElementIndexText(result, element, r'''
119 6:4 |[| IS_INVOKED_BY qualified
''');
  }

  test_MethodElement_operator_ofMixin_prefix() async {
    var result = await _indexTestCode('''
/// [operator ~] and [M.operator ~]
mixin M {
  int operator ~() => 0;
}
void useOperator(M m) {
  ~m;
}
''');
    var element = result.findElement.method('~');
    assertElementIndexText(result, element, r'''
14 1:15 |~| IS_REFERENCED_BY
33 1:34 |~| IS_REFERENCED_BY qualified
99 6:3 |~| IS_INVOKED_BY qualified
''');
  }

  test_MixinElement_emptyBody() async {
    await _indexTestCode(r'''
mixin M;
''');
  }

  test_MixinElement_hierarchy_class_implements() async {
    var result = await _indexTestCode(r'''
mixin A {}
class B implements A {}
''');

    var element = result.findElement.mixin('A');
    assertElementIndexText(result, element, r'''
30 2:20 |A| IS_IMPLEMENTED_BY
30 2:20 |A| IS_REFERENCED_BY
''');
  }

  test_MixinElement_hierarchy_class_with() async {
    var result = await _indexTestCode(r'''
mixin A {}
class B extends Object with A {}
''');

    var element = result.findElement.mixin('A');
    assertElementIndexText(result, element, r'''
39 2:29 |A| IS_MIXED_IN_BY
39 2:29 |A| IS_REFERENCED_BY
''');
  }

  test_MixinElement_hierarchy_classTypeAlias_with() async {
    var result = await _indexTestCode(r'''
mixin A {}
class B = Object with A;
''');

    var element = result.findElement.mixin('A');
    assertElementIndexText(result, element, r'''
33 2:23 |A| IS_MIXED_IN_BY
33 2:23 |A| IS_REFERENCED_BY
''');
  }

  test_MixinElement_hierarchy_enum_implements() async {
    var result = await _indexTestCode(r'''
mixin A {}
enum E implements A {
  v
}
''');

    var element = result.findElement.mixin('A');
    assertElementIndexText(result, element, r'''
29 2:19 |A| IS_IMPLEMENTED_BY
29 2:19 |A| IS_REFERENCED_BY
''');
  }

  test_MixinElement_hierarchy_enum_with() async {
    var result = await _indexTestCode(r'''
mixin A {}
enum E with A {
  v
}
''');

    var element = result.findElement.mixin('A');
    assertElementIndexText(result, element, r'''
23 2:13 |A| IS_MIXED_IN_BY
23 2:13 |A| IS_REFERENCED_BY
''');
  }

  test_MixinElement_hierarchy_extensionType_implements() async {
    var result = await _indexTestCode(r'''
mixin A {}
extension type E(A it) implements A {}
''');

    var element = result.findElement.mixin('A');
    assertElementIndexText(result, element, r'''
28 2:18 |A| IS_REFERENCED_BY
45 2:35 |A| IS_IMPLEMENTED_BY
45 2:35 |A| IS_REFERENCED_BY
''');
  }

  test_MixinElement_hierarchy_mixin_implements() async {
    var result = await _indexTestCode(r'''
mixin A {}
mixin M implements A {}
''');

    var element = result.findElement.mixin('A');
    assertElementIndexText(result, element, r'''
30 2:20 |A| IS_IMPLEMENTED_BY
30 2:20 |A| IS_REFERENCED_BY
''');
  }

  test_MixinElement_hierarchy_mixin_on() async {
    var result = await _indexTestCode(r'''
mixin A {}
mixin M on A {}
''');

    var element = result.findElement.mixin('A');
    assertElementIndexText(result, element, r'''
22 2:12 |A| CONSTRAINS
22 2:12 |A| IS_REFERENCED_BY
''');
  }

  test_MixinElement_reference_annotation() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

mixin A {
  static const int myConstant = 0;
}

@A.myConstant
@p.A.myConstant
void f() {}
''');

    var element = result.findElement.mixin('A');
    assertElementIndexText(result, element, r'''
75 7:2 |A| IS_REFERENCED_BY
91 8:4 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_MixinElement_reference_comment() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

mixin A {}

/// [A] and [p.A].
void f() {}
''');

    var element = result.findElement.mixin('A');
    assertElementIndexText(result, element, r'''
43 5:6 |A| IS_REFERENCED_BY
53 5:16 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_MixinElement_reference_memberAccess() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

mixin A {
  static void foo() {}
}

void f() {
  A.foo();
  p.A.foo();
}
''');

    var element = result.findElement.mixin('A');
    assertElementIndexText(result, element, r'''
75 8:3 |A| IS_REFERENCED_BY
88 9:5 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_MixinElement_reference_namedType() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

mixin A {}

void f(A v1, p.A v2) {}
''');

    var element = result.findElement.mixin('A');
    assertElementIndexText(result, element, r'''
45 5:8 |A| IS_REFERENCED_BY
53 5:16 |A| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_MultiplyDefinedElement() async {
    newFile('$testPackageLibPath/a1.dart', 'class A {}');
    newFile('$testPackageLibPath/a2.dart', 'class A {}');
    await _indexTestCode('''
import 'a1.dart';
import 'a2.dart';
A v = null;
// [diag.ambiguousImport][column 1][length 1] The name 'A' is defined in the libraries 'package:test/a1.dart' and 'package:test/a2.dart'.
''');
  }

  test_NeverElement() async {
    var result = await _indexTestCode('''
Never f() {}
//    ^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'Never', is a potentially non-nullable type.
''');
    expect(result.index.usedElementOffsets, isEmpty);
  }

  test_SetterElement_ofClass_instance() async {
    var result = await _indexTestCode('''
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
    var element = result.findElement.setter('foo');
    assertElementIndexText(result, element, r'''
5 1:6 |foo| IS_REFERENCED_BY
17 1:18 |foo| IS_REFERENCED_BY qualified
77 5:5 |foo| IS_REFERENCED_BY
95 6:10 |foo| IS_REFERENCED_BY qualified
137 11:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_SetterElement_ofClass_static() async {
    var result = await _indexTestCode('''
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
    var element = result.findElement.setter('foo');
    assertElementIndexText(result, element, r'''
31 3:6 |foo| IS_REFERENCED_BY
40 3:15 |foo| IS_REFERENCED_BY qualified
51 3:26 |foo| IS_REFERENCED_BY qualified
125 7:5 |foo| IS_REFERENCED_BY
164 12:5 |foo| IS_REFERENCED_BY qualified
179 13:7 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_subtypes_classDeclaration() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {}
class B {}
class C {}
class D {}
class E {}
''');
    var result = await _indexTestCode('''
import 'a.dart';

class X extends A {
  X();
//^
// [diag.notInitializedNonNullableInstanceFieldConstructor] Non-nullable instance field 'field1' must be initialized.
// [diag.notInitializedNonNullableInstanceFieldConstructor] Non-nullable instance field 'field2' must be initialized.
  X.namedConstructor();
//^^^^^^^^^^^^^^^^^^
// [diag.notInitializedNonNullableInstanceFieldConstructor] Non-nullable instance field 'field1' must be initialized.
// [diag.notInitializedNonNullableInstanceFieldConstructor] Non-nullable instance field 'field2' must be initialized.

  int field1, field2;
  int get getter1 => null;
//                   ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'Null' can't be returned from the function 'getter1' because it has a return type of 'int'.
  void set setter1(_) {}
  void method1() {}

  static int staticField;
//           ^^^^^^^^^^^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'staticField' must be initialized.
  static void staticMethod() {}
}

class Y extends Object with B, C {
//                          ^
// [diag.classUsedAsMixin] The class 'B' can't be used as a mixin because it's neither a mixin class nor a mixin.
//                             ^
// [diag.classUsedAsMixin] The class 'C' can't be used as a mixin because it's neither a mixin class nor a mixin.
  void methodY() {}
}

class Z implements E, D {
  void methodZ() {}
}
''');

    assertSubtypeIndexText(result, r'''
/home/test/lib/a.dart;/home/test/lib/a.dart;A -> X
  field1
  field2
  getter1
  method1
  setter1
/home/test/lib/a.dart;/home/test/lib/a.dart;B -> Y
  methodY
/home/test/lib/a.dart;/home/test/lib/a.dart;C -> Y
  methodY
/home/test/lib/a.dart;/home/test/lib/a.dart;D -> Z
  methodZ
/home/test/lib/a.dart;/home/test/lib/a.dart;E -> Z
  methodZ
/sdk/lib/core/core.dart;/sdk/lib/core/core.dart;Object -> Y
  methodY
''');
  }

  test_subtypes_classDeclaration_supertypeInPart() async {
    newFile('$testPackageLibPath/a.dart', '''
part 'b.dart';
''');

    newFile('$testPackageLibPath/b.dart', '''
part of 'a.dart';

class A {}
''');

    var result = await _indexTestCode('''
import 'a.dart';

class X extends A {
  void methodX() {}
}
''');

    assertSubtypeIndexText(result, r'''
/home/test/lib/a.dart;/home/test/lib/b.dart;A -> X
  methodX
''');
  }

  test_subtypes_classTypeAlias() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {}
class B {}
class C {}
class D {}
''');
    var result = await _indexTestCode('''
import 'a.dart';

class X = A with B, C;
//               ^
// [diag.classUsedAsMixin] The class 'B' can't be used as a mixin because it's neither a mixin class nor a mixin.
//                  ^
// [diag.classUsedAsMixin] The class 'C' can't be used as a mixin because it's neither a mixin class nor a mixin.
class Y = A with B implements C, D;
//               ^
// [diag.classUsedAsMixin] The class 'B' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');

    assertSubtypeIndexText(result, r'''
/home/test/lib/a.dart;/home/test/lib/a.dart;A -> X
/home/test/lib/a.dart;/home/test/lib/a.dart;A -> Y
/home/test/lib/a.dart;/home/test/lib/a.dart;B -> X
/home/test/lib/a.dart;/home/test/lib/a.dart;B -> Y
/home/test/lib/a.dart;/home/test/lib/a.dart;C -> X
/home/test/lib/a.dart;/home/test/lib/a.dart;C -> Y
/home/test/lib/a.dart;/home/test/lib/a.dart;D -> Y
''');
  }

  test_subtypes_dynamic() async {
    var result = await _indexTestCode('''
class X extends dynamic {
//              ^^^^^^^
// [diag.extendsNonClass] Classes can only extend other classes.
  void foo() {}
}
''');

    assertSubtypeIndexText(result, r'''
''');
  }

  test_subtypes_enum_implements() async {
    var result = await _indexTestCode('''
class A {}

enum E implements A {
  v;
  void foo() {}
}
''');

    assertSubtypeIndexText(result, r'''
/home/test/lib/test.dart;/home/test/lib/test.dart;A -> E
  foo
''');
  }

  test_subtypes_enum_with() async {
    var result = await _indexTestCode('''
mixin M {}

enum E with M {
  v;
  void foo() {}
}
''');

    assertSubtypeIndexText(result, r'''
/home/test/lib/test.dart;/home/test/lib/test.dart;M -> E
  foo
''');
  }

  test_subtypes_extensionType_class() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  void method1() {}
  void method2() {}
}
''');
    var result = await _indexTestCode('''
import 'a.dart';

extension type X(A it) implements A {
  void method1() {}
  void method3() {}
}
''');

    assertSubtypeIndexText(result, r'''
/home/test/lib/a.dart;/home/test/lib/a.dart;A -> X
  method1
  method3
''');
  }

  test_subtypes_extensionType_extensionType() async {
    newFile('$testPackageLibPath/a.dart', '''
extension type A(int it) {
  void method1() {}
  void method2() {}
}
''');
    var result = await _indexTestCode('''
import 'a.dart';

extension type X(int it) implements A {
  void method1() {}
  void method3() {}
}
''');

    assertSubtypeIndexText(result, r'''
/home/test/lib/a.dart;/home/test/lib/a.dart;A -> X
  method1
  method3
''');
  }

  test_subtypes_mixinDeclaration() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {}
class B {}
class C {}
class D {}
class E {}
''');
    var result = await _indexTestCode('''
import 'a.dart';

mixin X on A implements B, C {}
mixin Y on A, B implements C;
''');

    assertSubtypeIndexText(result, r'''
/home/test/lib/a.dart;/home/test/lib/a.dart;A -> X
/home/test/lib/a.dart;/home/test/lib/a.dart;A -> Y
/home/test/lib/a.dart;/home/test/lib/a.dart;B -> X
/home/test/lib/a.dart;/home/test/lib/a.dart;B -> Y
/home/test/lib/a.dart;/home/test/lib/a.dart;C -> X
/home/test/lib/a.dart;/home/test/lib/a.dart;C -> Y
''');
  }

  test_SuperFormalParameterElement_ofConstructor_optionalNamed() async {
    var result = await _indexTestCode('''
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
    var element = result.findElement.unnamedConstructor('B').parameter('test');
    assertElementIndexText(result, element, r'''
58 6:8 |test| IS_REFERENCED_BY
91 7:28 |test| IS_READ_BY
124 11:5 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
147 12:14 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_SuperFormalParameterElement_ofConstructor_optionalPositional() async {
    var result = await _indexTestCode('''
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
    var element = result.findElement.unnamedConstructor('B').parameter('test');
    assertElementIndexText(result, element, r'''
58 6:8 |test| IS_REFERENCED_BY
91 7:28 |test| IS_READ_BY
''');
  }

  test_SuperFormalParameterElement_ofConstructor_requiredNamed() async {
    var result = await _indexTestCode('''
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
    var element = result.findElement.unnamedConstructor('B').parameter('test');
    assertElementIndexText(result, element, r'''
66 6:8 |test| IS_REFERENCED_BY
108 7:37 |test| IS_READ_BY
139 11:5 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
162 12:14 |test| IS_REFERENCED_BY_NAMED_ARGUMENT qualified
''');
  }

  test_SuperFormalParameterElement_ofConstructor_requiredPositional() async {
    var result = await _indexTestCode('''
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
    var element = result.findElement.unnamedConstructor('B').parameter('test');
    assertElementIndexText(result, element, r'''
55 6:8 |test| IS_REFERENCED_BY
86 7:26 |test| IS_READ_BY
''');
  }

  test_TopLevelFunctionElement() async {
    var result = await _indexTestCode(r'''
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

    var element = result.findElement.topFunction('foo');
    assertElementIndexText(result, element, r'''
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
    var result = await _indexTestCode('''
import 'dart:math' deferred as math;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'dart:math'.

void f() {
  math.loadLibrary();
}
''');
    var mathLib = result.findElement.import('dart:math').importedLibrary!;
    var element = mathLib.loadLibraryFunction;
    assertElementIndexText(result, element, r'''
56 4:8 |loadLibrary| IS_INVOKED_BY qualified
''');
  }

  test_TopLevelVariableElement_reference() async {
    var result = await _indexTestCode('''
import 'test.dart' as p;

var foo = 0;

/// [foo] and [p.foo].
@foo
// [diag.invalidAnnotation][column 1][length 4] Annotation must be either a const variable reference or const constructor invocation.
@p.foo
// [diag.invalidAnnotation][column 1][length 6] Annotation must be either a const variable reference or const constructor invocation.
void f() {
  foo;
  foo = 0;
  p.foo;
  p.foo = 0;
}
''');

    var element = result.findElement.topVar('foo');
    var getter = element.getter!;
    var setter = element.setter!;

    assertElementIndexText(result, getter, r'''
45 5:6 |foo| IS_REFERENCED_BY
57 5:18 |foo| IS_REFERENCED_BY qualified
64 6:2 |foo| IS_REFERENCED_BY
71 7:4 |foo| IS_REFERENCED_BY qualified
88 9:3 |foo| IS_REFERENCED_BY
108 11:5 |foo| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');

    assertElementIndexText(result, setter, r'''
95 10:3 |foo| IS_REFERENCED_BY
117 12:5 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_TopLevelVariableElement_reference_combinator_show_hasGetterSetter() async {
    var result = await _indexTestCode('''
import 'test.dart' show foo;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'test.dart'.

int get foo => 0;
void set foo(_) {}
''');
    var element = result.findElement.topVar('foo');
    assertElementIndexText(result, element, r'''
24 1:25 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_TopLevelVariableElement_reference_combinator_show_hasSetter() async {
    var result = await _indexTestCode('''
import 'test.dart' show foo;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'test.dart'.

void set foo(_) {}
''');
    var element = result.findElement.topVar('foo');
    assertElementIndexText(result, element, r'''
24 1:25 |foo| IS_REFERENCED_BY qualified
''');
  }

  test_TypeAliasElement_legacy_reference() async {
    var result = await _indexTestCode('''
typedef void A();
/// [A]
void f(A p) {}
''');
    var element = result.findElement.typeAlias('A');
    assertElementIndexText(result, element, r'''
23 2:6 |A| IS_REFERENCED_BY
33 3:8 |A| IS_REFERENCED_BY
''');
  }

  test_TypeAliasElement_modern_hierarchy_class_extends() async {
    var result = await _indexTestCode('''
class A<T> {}
typedef B = A<int>;
class C extends B {}
''');
    var element = result.findElement.typeAlias('B');
    assertElementIndexText(result, element, r'''
50 3:17 |B| IS_EXTENDED_BY
50 3:17 |B| IS_REFERENCED_BY
''');

    var aliasedClass = result.findElement.class_('A');
    assertElementIndexText(result, aliasedClass, r'''
26 2:13 |A| IS_REFERENCED_BY
''');
  }

  test_TypeAliasElement_modern_hierarchy_class_implements() async {
    var result = await _indexTestCode('''
class A<T> {}
typedef B = A<int>;
class C implements B {}
''');
    var element = result.findElement.typeAlias('B');
    assertElementIndexText(result, element, r'''
53 3:20 |B| IS_IMPLEMENTED_BY
53 3:20 |B| IS_REFERENCED_BY
''');

    var aliasedClass = result.findElement.class_('A');
    assertElementIndexText(result, aliasedClass, r'''
26 2:13 |A| IS_REFERENCED_BY
''');
  }

  test_TypeAliasElement_modern_hierarchy_class_with() async {
    var result = await _indexTestCode('''
class A<T> {}
typedef B = A<int>;
class C extends Object with B {}
//                          ^
// [diag.classUsedAsMixin] The class 'A' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
    var element = result.findElement.typeAlias('B');
    assertElementIndexText(result, element, r'''
62 3:29 |B| IS_MIXED_IN_BY
62 3:29 |B| IS_REFERENCED_BY
''');

    var aliasedClass = result.findElement.class_('A');
    assertElementIndexText(result, aliasedClass, r'''
26 2:13 |A| IS_REFERENCED_BY
''');
  }

  test_TypeAliasElement_modern_reference() async {
    var result = await _indexTestCode('''
class A<T> {
  static int field = 0;
  static void method() {}
}

typedef B = A<int>;

/// [B]
void f(B p) {
  B v;
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
  B();
  B.field;
  B.field = 0;
  B.method();
}
''');
    var element = result.findElement.typeAlias('B');
    assertElementIndexText(result, element, r'''
92 8:6 |B| IS_REFERENCED_BY
102 9:8 |B| IS_REFERENCED_BY
111 10:3 |B| IS_REFERENCED_BY
118 11:3 |B| IS_REFERENCED_BY
125 12:3 |B| IS_REFERENCED_BY
136 13:3 |B| IS_REFERENCED_BY
151 14:3 |B| IS_REFERENCED_BY
''');

    var aliasedClass = result.findElement.class_('A');
    assertElementIndexText(result, aliasedClass, r'''
78 6:13 |A| IS_REFERENCED_BY
''');
  }

  test_TypeAliasElement_modern_reference_comment() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A<T> {}
typedef B = A<int>;

/// [B] and [p.B].
void f() {}
''');
    var element = result.findElement.typeAlias('B');
    assertElementIndexText(result, element, r'''
66 6:6 |B| IS_REFERENCED_BY
76 6:16 |B| IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');

    var aliasedClass = result.findElement.class_('A');
    assertElementIndexText(result, aliasedClass, r'''
52 4:13 |A| IS_REFERENCED_BY
''');
  }

  test_usedName_inLibraryIdentifier() async {
    var result = await _indexTestCode('''
library aaa.bbb.ccc;
class C {
  var bbb;
}
void f(p) {
  p.bbb = 1;
}
''');
    assertNameIndexText(result, 'bbb', r'''
60 6:5 |bbb| IS_WRITTEN_BY qualified
''');
  }

  test_usedName_qualified_resolved() async {
    var result = await _indexTestCode('''
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
    assertNameIndexText(result, 'x', r'''
''');
  }

  test_usedName_qualified_unresolved() async {
    var result = await _indexTestCode('''
void f(p) {
  p.x;
  p.x = 1;
  p.x += 2;
  p.x();
}
''');
    assertNameIndexText(result, 'x', r'''
16 2:5 |x| IS_READ_BY qualified
23 3:5 |x| IS_WRITTEN_BY qualified
34 4:5 |x| IS_READ_WRITTEN_BY qualified
46 5:5 |x| IS_INVOKED_BY qualified
''');
  }

  test_usedName_unqualified_resolved() async {
    var result = await _indexTestCode('''
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
    assertNameIndexText(result, 'x', r'''
''');
  }

  test_usedName_unqualified_unresolved() async {
    var result = await _indexTestCode('''
void f() {
  x;
//^
// [diag.undefinedIdentifier] Undefined name 'x'.
  x = 1;
//^
// [diag.undefinedIdentifier] Undefined name 'x'.
  x += 2;
//^
// [diag.undefinedIdentifier] Undefined name 'x'.
  x();
//^
// [diag.undefinedFunction] The function 'x' isn't defined.
}
''');
    assertNameIndexText(result, 'x', r'''
13 2:3 |x| IS_READ_BY
18 3:3 |x| IS_WRITTEN_BY
27 4:3 |x| IS_READ_WRITTEN_BY
37 5:3 |x| IS_INVOKED_BY
''');
  }

  Future<_IndexResult> _indexFileWithDiagnostics(File file, String code) async {
    var unitResult = await resolveFileWithDiagnostics(file, code);
    var indexBuilder = indexUnit(unitResult.unit);
    var indexBytes = indexBuilder.toBuffer();
    var index = AnalysisDriverUnitIndex.fromBuffer(indexBytes);
    return _IndexResult(unitResult, index);
  }

  Future<_IndexResult> _indexTestCode(String code) {
    return _indexFileWithDiagnostics(testFile, code);
  }

  static String _toPosixPaths(String text) {
    return text.replaceAllMapped(RegExp(r'C:\\([a-zA-Z0-9_.\\]+)'), (match) {
      var path = match.group(1)!;
      var posixPath = path.replaceAll(r'\', '/');
      return '/$posixPath';
    });
  }
}

final class _IndexRelation {
  final IndexRelationKind kind;
  final int offset;
  final int length;
  final bool isQualified;

  _IndexRelation({
    required this.kind,
    required this.offset,
    required this.length,
    required this.isQualified,
  });

  @override
  String toString() {
    return '_IndexRelation{kind: $kind, offset: $offset, length: $length, '
        'isQualified: $isQualified})';
  }
}

final class _IndexResult {
  final TestResolvedUnitResult resolvedUnit;
  final AnalysisDriverUnitIndex index;

  _IndexResult(this.resolvedUnit, this.index);

  FindElement2 get findElement => resolvedUnit.findElement;
}

final class _IndexTextBuilder {
  final _IndexResult result;

  _IndexTextBuilder(this.result);

  String elementRelations(Element element) {
    var index = result.index;
    var elementId = _findElementId(element);
    if (elementId == null) {
      return '';
    }

    var relations = <_IndexRelation>[];
    for (var i = 0; i < index.usedElementOffsets.length; i++) {
      if (index.usedElements[i] == elementId) {
        relations.add(
          _IndexRelation(
            kind: index.usedElementKinds[i],
            offset: index.usedElementOffsets[i],
            length: index.usedElementLengths[i],
            isQualified: index.usedElementIsQualifiedFlags[i],
          ),
        );
      }
    }

    var buffer = StringBuffer();
    _writeRelationsText(buffer, relations);
    _writeImportPrefixesText(buffer, index.elementImportPrefixes[elementId]);
    return buffer.toString();
  }

  String libraryFragmentReferences(LibraryFragmentImpl target) {
    var index = result.index;
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
        _writeSourceSpanText(
          buffer,
          index.libFragmentRefUriOffsets[i],
          index.libFragmentRefUriLengths[i],
        );
        buffer.writeln();
      }
    }
    return buffer.toString();
  }

  String nameRelations(String name) {
    var index = result.index;
    var nameId = index.getStringId(name);
    if (nameId == -1) {
      return '';
    }

    var relations = <_IndexRelation>[];
    for (var i = 0; i < index.usedNameOffsets.length; i++) {
      if (index.usedNames[i] == nameId) {
        relations.add(
          _IndexRelation(
            kind: index.usedNameKinds[i],
            offset: index.usedNameOffsets[i],
            length: name.length,
            isQualified: index.usedNameIsQualifiedFlags[i],
          ),
        );
      }
    }

    var buffer = StringBuffer();
    _writeRelationsText(buffer, relations);
    return buffer.toString();
  }

  String subtypes() {
    var index = result.index;
    expect(index.supertypes.length, index.subtypes.length);

    var buffer = StringBuffer();
    for (var i = 0; i < index.supertypes.length; i++) {
      var supertypeId = index.strings[index.supertypes[i]];
      var subtype = index.subtypes[i];
      var subtypeName = index.strings[subtype.name];
      buffer.writeln('$supertypeId -> $subtypeName');
      for (var member in subtype.members) {
        buffer.writeln('  ${index.strings[member]}');
      }
    }
    return buffer.toString();
  }

  /// Return the [element] identifier in the result index, or `null`.
  int? _findElementId(Element element) {
    var index = result.index;
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
    return result.index.getLibraryFragmentId(unitElement);
  }

  void _writeImportPrefixesText(StringBuffer buffer, String prefixString) {
    // If the only access is unprefixed, omit the line.
    if (prefixString.isNotEmpty) {
      // Otherwise, use some marker text for unprefixed so it's clearer in the
      // output than an empty string.
      var prefixes = prefixString
          .split(',')
          .map((prefix) => prefix.isEmpty ? '(unprefixed)' : prefix)
          .join(',');

      buffer.writeln('Prefixes: $prefixes');
    }
  }

  void _writeRelationsText(
    StringBuffer buffer,
    List<_IndexRelation> relations,
  ) {
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

    for (var relation in sortedRelations) {
      _writeSourceSpanText(buffer, relation.offset, relation.length);
      buffer.write(' ');
      buffer.write(relation.kind.name);
      if (relation.isQualified) {
        buffer.write(' qualified');
      }
      buffer.writeln();
    }
  }

  void _writeSourceSpanText(StringBuffer buffer, int offset, int length) {
    var lineInfo = result.resolvedUnit.unit.lineInfo;
    var location = lineInfo.getLocation(offset);
    var snippet = result.resolvedUnit.content.substring(
      offset,
      offset + length,
    );
    buffer.write(offset);
    buffer.write(' ');
    buffer.write(location.lineNumber);
    buffer.write(':');
    buffer.write(location.columnNumber);
    buffer.write(' ');
    buffer.write('|$snippet|');
  }
}
