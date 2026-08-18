// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/index.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/diff.dart';
import '../../../util/element_printer.dart';
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
    _assertIndexText(result, elements: {'': element}, expected: expected);
  }

  /// Asserts index relations for the elements in [elements].
  ///
  /// Each key in [elements] is a label for the corresponding element. The
  /// label is printed before the relation in [expected]. For example, given
  /// `{'getter': getter, 'setter': setter}`, the expected text can contain:
  /// ```
  ///   foo;
  ///   ^^^ getter IS_INVOKED_BY
  ///   foo = 0;
  ///   ^^^ setter IS_INVOKED_BY
  /// ```
  void assertElementsIndexText(
    _IndexResult result,
    Map<String, Element> elements,
    String expected,
  ) {
    if (elements.isEmpty) {
      throw ArgumentError.value(elements, 'elements', 'Must not be empty');
    }
    _assertIndexText(result, elements: elements, expected: expected);
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

  void assertNamesIndexText(
    _IndexResult result,
    Set<String> names,
    String expected,
  ) {
    if (names.isEmpty) {
      throw ArgumentError.value(names, 'names', 'Must not be empty');
    }
    _assertIndexText(result, names: names, expected: expected);
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

    await libraryElementForFile(diagnosticFile);

    var testFile = getFile('$analyzerPackageTestPath/test.dart');
    var result = await _indexFileWithDiagnostics(testFile, r'''
void f() {
  '// [diag.myDiagnosticCode] message';
}
''');

    var diagnosticLibrary = await libraryElementForFile(diagnosticFile);
    var element = diagnosticLibrary.topLevelVariables.firstWhere(
      (v) => v.name == 'myDiagnosticCode',
    );

    assertElementIndexText(result, element, r'''
void f() {
  '// [diag.myDiagnosticCode] message';
            ^^^^^^^^^^^^^^^^ IS_REFERENCED_BY qualified
}
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

    assertElementIndexText(result, result.findElement.class_('A'), r'''
import 'test.dart' as p;

class A {}

class B extends A {}
                ^ IS_EXTENDED_BY
                ^ IS_REFERENCED_BY
class B_q extends p.A {}
                    ^ IS_EXTENDED_BY qualified
                    ^ IS_REFERENCED_BY qualified
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_hierarchy_class_extends_implicitObject() async {
    var result = await _indexTestCode('''
class A {}
''');

    assertElementIndexText(
      result,
      result.resolvedUnit.typeProvider.objectElement,
      r'''
class A {}
      ^0 IS_EXTENDED_BY qualified
''',
    );
  }

  test_ClassElement_hierarchy_class_implements() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {}

class B implements A {}
class B_q implements p.A {}
''');

    assertElementIndexText(result, result.findElement.class_('A'), r'''
import 'test.dart' as p;

class A {}

class B implements A {}
                   ^ IS_IMPLEMENTED_BY
                   ^ IS_REFERENCED_BY
class B_q implements p.A {}
                       ^ IS_IMPLEMENTED_BY qualified
                       ^ IS_REFERENCED_BY qualified
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

    assertElementIndexText(result, result.findElement.class_('A'), r'''
import 'test.dart' as p;

class A {}

class D extends Object with A {}
                            ^ IS_MIXED_IN_BY
                            ^ IS_REFERENCED_BY
class D_q extends Object with p.A {}
                                ^ IS_MIXED_IN_BY qualified
                                ^ IS_REFERENCED_BY qualified
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

    assertElementIndexText(result, result.findElement.class_('A'), r'''
import 'test.dart' as p;

class A {}

class D2 = Object with A;
                       ^ IS_MIXED_IN_BY
                       ^ IS_REFERENCED_BY
class D2_q = Object with p.A;
                           ^ IS_MIXED_IN_BY qualified
                           ^ IS_REFERENCED_BY qualified
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

    assertElementIndexText(result, result.findElement.class_('A'), r'''
import 'test.dart' as p;

class A {}

enum E implements A { v }
                  ^ IS_IMPLEMENTED_BY
                  ^ IS_REFERENCED_BY
enum E_q implements p.A { v }
                      ^ IS_IMPLEMENTED_BY qualified
                      ^ IS_REFERENCED_BY qualified
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

    assertElementIndexText(result, result.findElement.class_('A'), r'''
import 'test.dart' as p;

class A {}

extension type E(A it) implements A {}
                 ^ IS_REFERENCED_BY
                                  ^ IS_IMPLEMENTED_BY
                                  ^ IS_REFERENCED_BY
extension type E_q(A it) implements p.A {}
                   ^ IS_REFERENCED_BY
                                      ^ IS_IMPLEMENTED_BY qualified
                                      ^ IS_REFERENCED_BY qualified
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

    assertElementIndexText(result, result.findElement.class_('A'), r'''
import 'test.dart' as p;

class A {}

mixin M implements A {}
                   ^ IS_IMPLEMENTED_BY
                   ^ IS_REFERENCED_BY
mixin M_q implements p.A {}
                       ^ IS_IMPLEMENTED_BY qualified
                       ^ IS_REFERENCED_BY qualified
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

    assertElementIndexText(result, result.findElement.class_('A'), r'''
import 'test.dart' as p;

class A {}

mixin M2 on A {}
            ^ CONSTRAINS
            ^ IS_REFERENCED_BY
mixin M2_q on p.A {}
                ^ CONSTRAINS qualified
                ^ IS_REFERENCED_BY qualified
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
import 'test.dart' as p;

class A {
  const A();
        ^ IS_REFERENCED_BY
  const A.named();
        ^ IS_REFERENCED_BY
  static const int myConstant = 0;
}

@A()
 ^ IS_REFERENCED_BY
@p.A()
   ^ IS_REFERENCED_BY qualified
@A.named()
 ^ IS_REFERENCED_BY
@p.A.named()
   ^ IS_REFERENCED_BY qualified
@A.myConstant
 ^ IS_REFERENCED_BY
@p.A.myConstant
   ^ IS_REFERENCED_BY qualified
void f() {}
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

    assertElementIndexText(result, result.findElement.class_('B'), r'''
import 'test.dart' as p;

class A<T> {
  const A.named();
}

class B {}

@A<B>.named()
   ^ IS_REFERENCED_BY
@p.A<B>.named()
     ^ IS_REFERENCED_BY
void f() {}
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

    assertElementIndexText(result, result.findElement.class_('B'), r'''
class A<T> {
  const A();
}

class B {}

@A<B>()
   ^ IS_REFERENCED_BY
void f() {}
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
class A {}
class B = Object with A;
void f(B p) {
       ^ IS_REFERENCED_BY
  B v;
  ^ IS_REFERENCED_BY
}
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
import 'test.dart' as p;

class A {}

/// [A] and [p.A].
     ^ IS_REFERENCED_BY
               ^ IS_REFERENCED_BY qualified
void f() {}
Prefixes: (unprefixed),p
''');
  }

  test_ClassElement_reference_constructorDeclaration() async {
    var result = await _indexTestCode(r'''
class A {
  A();
  A.named();
}
''');

    var element = result.findElement.class_('A');

    assertElementIndexText(result, element, r'''
class A {
  A();
  ^ IS_REFERENCED_BY
  A.named();
  ^ IS_REFERENCED_BY
}
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
import 'dart:math';
Random v1;
^^^^^^ IS_REFERENCED_BY
Random v2;
^^^^^^ IS_REFERENCED_BY
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
import 'lib.dart';

void f(A p) {
       ^ IS_REFERENCED_BY
  A v = p;
  ^ IS_REFERENCED_BY
}
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
import 'test.dart' as p;

class A {}

void f() {
  A();
  ^ IS_REFERENCED_BY
  p.A();
    ^ IS_REFERENCED_BY qualified
}
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
import 'test.dart' as p;

class A {
  static void foo() {}
}

void f() {
  A.foo();
  ^ IS_REFERENCED_BY
  p.A.foo();
    ^ IS_REFERENCED_BY qualified
}
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
import 'test.dart' as p;

class A {}

void f() {
  A v1;
  ^ IS_REFERENCED_BY
  p.A v2;
    ^ IS_REFERENCED_BY qualified
  List<A> v3;
       ^ IS_REFERENCED_BY
  List<p.A> v4;
         ^ IS_REFERENCED_BY qualified
}
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
class A {}

void f(({int foo, A bar}) r) {}
                  ^ IS_REFERENCED_BY
''');
  }

  test_ClassElement_reference_recordTypeAnnotation_positional() async {
    var result = await _indexTestCode(r'''
class A {}

void f((int, A) r) {}
''');

    var element = result.findElement.class_('A');

    assertElementIndexText(result, element, r'''
class A {}

void f((int, A) r) {}
             ^ IS_REFERENCED_BY
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
import 'test.dart' as p;

class A {}

var v = A;
        ^ IS_REFERENCED_BY
var v_p = p.A;
            ^ IS_REFERENCED_BY qualified
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

    assertElementsIndexText(
      result,
      {
        'new': result.findElement.unnamedConstructor('A'),
        'named': result.findElement.constructor('named', of: 'A'),
      },
      r'''
import 'test.dart' as p;

class A {
  const A();
  const A.named();
}

@A()
  ^0 new IS_INVOKED_BY qualified
@p.A()
    ^0 new IS_INVOKED_BY qualified
@A.named()
  ^^^^^^ named IS_INVOKED_BY qualified
@p.A.named()
    ^^^^^^ named IS_INVOKED_BY qualified
void f() {}
''',
    );
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

    var element = result.findElement.constructor('foo');

    assertElementIndexText(result, element, r'''
class A {
  A.foo() {
    foo();
  }

  A foo() => A.foo();
              ^^^^ IS_INVOKED_BY qualified
}
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
/// [new A.foo] and [A.foo]
          ^^^^ IS_REFERENCED_BY qualified
                      ^^^^ IS_REFERENCED_BY qualified
class A {
  new foo() {}
  new bar() : this.foo();
                  ^^^^ IS_INVOKED_BY qualified
  factory baz() = A.foo;
                   ^^^^ IS_REFERENCED_BY qualified
}
class B extends A {
  new () : super.foo();
                ^^^^ IS_INVOKED_BY qualified
}
void useConstructor() {
  A.foo();
   ^^^^ IS_INVOKED_BY qualified
  A.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .foo();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
/// [new A.foo] and [A.foo]
          ^^^^ IS_REFERENCED_BY qualified
                      ^^^^ IS_REFERENCED_BY qualified
class A.foo() {
  new bar() : this.foo();
                  ^^^^ IS_INVOKED_BY qualified
  factory baz() = A.foo;
                   ^^^^ IS_REFERENCED_BY qualified
}
class B() extends A {
  this : super.foo();
              ^^^^ IS_INVOKED_BY qualified
}
void useConstructor() {
  A.foo();
   ^^^^ IS_INVOKED_BY qualified
  A.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .foo();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
/// [new A.foo] and [A.foo]
          ^^^^ IS_REFERENCED_BY qualified
                      ^^^^ IS_REFERENCED_BY qualified
class A {
  A.foo() {}
  A.bar() : this.foo();
                ^^^^ IS_INVOKED_BY qualified
  factory A.baz() = A.foo;
                     ^^^^ IS_REFERENCED_BY qualified
}
class B extends A {
  B() : super.foo();
             ^^^^ IS_INVOKED_BY qualified
}
void useConstructor() {
  A.foo();
   ^^^^ IS_INVOKED_BY qualified
  A.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .foo();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
/// [new B.foo] and [B.foo]
          ^^^^ IS_REFERENCED_BY qualified
                      ^^^^ IS_REFERENCED_BY qualified
class A<T> {
  A.foo() {}
  A.bar() : this.foo();
                ^^^^ IS_INVOKED_BY qualified
  factory A.baz() = A.foo;
                     ^^^^ IS_REFERENCED_BY qualified
}
typedef B = A<int>;
class C extends B {
  C() : super.foo();
             ^^^^ IS_INVOKED_BY qualified
}
void useConstructor() {
  B.foo();
   ^^^^ IS_INVOKED_BY qualified
  B.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  B b = .foo();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
/// [new A] and [A.new]
          ^0 IS_REFERENCED_BY qualified
                  ^^^^ IS_REFERENCED_BY qualified
class B {
  B();
  factory B.baz() = A;
                     ^0 IS_REFERENCED_BY qualified
}
class A extends B {}
class C extends A {
  C() : super();
             ^0 IS_INVOKED_BY qualified
}
void useConstructor() {
  A();
   ^0 IS_INVOKED_BY qualified
  A.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
class A {
  A();
}

class B extends A {
  new ();
  ^^^ IS_INVOKED_BY qualified
  new bar();
  ^^^^^^^ IS_INVOKED_BY qualified
  factory new.baz() = A;
                       ^0 IS_REFERENCED_BY qualified
}
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
class A {
  A();
}

class B extends A {
  B();
  ^ IS_INVOKED_BY qualified
  B.bar();
  ^^^^^ IS_INVOKED_BY qualified
  factory B.baz() = A;
                     ^0 IS_REFERENCED_BY qualified
}

class C extends A {}
      ^ IS_INVOKED_BY qualified
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
/// [new A] and [A.new]
          ^0 IS_REFERENCED_BY qualified
                  ^^^^ IS_REFERENCED_BY qualified
class A {
  new () {}
  new bar() : this();
                  ^0 IS_INVOKED_BY qualified
  factory baz() = A;
                   ^0 IS_REFERENCED_BY qualified
}
class B extends A {
  new () : super();
                ^0 IS_INVOKED_BY qualified
}
void useConstructor() {
  A();
   ^0 IS_INVOKED_BY qualified
  A.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
''');
  }

  test_ConstructorElement_class_unnamed_otherFile() async {
    var otherFile = getFile('$testPackageLibPath/other.dart');

    var testResult = await resolveTestCodeWithDiagnostics('''
class A {
  A() {}
}
''');

    var result = await _indexFileWithDiagnostics(otherFile, '''
import 'test.dart';

void f() {
  A();
}
''');

    var element = testResult.findElement.unnamedConstructor('A');

    assertElementIndexText(result, element, r'''
import 'test.dart';

void f() {
  A();
   ^0 IS_INVOKED_BY qualified
}
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
/// [new A] and [A.new]
          ^0 IS_REFERENCED_BY qualified
                  ^^^^ IS_REFERENCED_BY qualified
class A() {
  new bar() : this();
                  ^0 IS_INVOKED_BY qualified
  factory baz() = A;
                   ^0 IS_REFERENCED_BY qualified
}
class B() extends A {
  this : super();
              ^0 IS_INVOKED_BY qualified
}
void useConstructor() {
  A();
   ^0 IS_INVOKED_BY qualified
  A.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
/// [new A] and [A.new]
          ^0 IS_REFERENCED_BY qualified
                  ^^^^ IS_REFERENCED_BY qualified
class A {
  A() {}
  A.bar() : this();
                ^0 IS_INVOKED_BY qualified
  factory A.baz() = A;
                     ^0 IS_REFERENCED_BY qualified
}
class B extends A {
  B() : super();
             ^0 IS_INVOKED_BY qualified
}
void useConstructor() {
  A();
   ^0 IS_INVOKED_BY qualified
  A.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
/// [new A] and [A.new]
          ^0 IS_REFERENCED_BY qualified
                  ^^^^ IS_REFERENCED_BY qualified
class A {
  A.new() {}
  A.bar() : this.new();
                ^^^^ IS_INVOKED_BY qualified
  factory A.baz() = A.new;
                     ^^^^ IS_REFERENCED_BY qualified
}
class B extends A {
  B() : super.new();
             ^^^^ IS_INVOKED_BY qualified
}
void useConstructor() {
  A.new();
   ^^^^ IS_INVOKED_BY qualified
  A.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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

    assertElementsIndexText(
      result,
      {
        'new': result.findElement.unnamedConstructor('A'),
        'named': result.findElement.constructor('named', of: 'A'),
      },
      r'''
class M {}
class A {
  A() {}
  A.named() {}
}
class B = A with M;
class C = B with M;
void useConstructor() {
  B();
   ^0 new IS_INVOKED_BY qualified
  B.named();
   ^^^^^^ named IS_INVOKED_BY qualified
  C();
   ^0 new IS_INVOKED_BY qualified
  C.named();
   ^^^^^^ named IS_INVOKED_BY qualified
}
''',
    );
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

    assertElementsIndexText(
      result,
      {
        'new': result.findElement.unnamedConstructor('E'),
        'named': result.findElement.constructor('named', of: 'E'),
      },
      r'''
import 'test.dart' as p;

enum E {
  v;
   ^0 new IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
  const E();
  const E.named();
}

@E()
  ^0 new IS_INVOKED_BY qualified
@p.E()
    ^0 new IS_INVOKED_BY qualified
@E.named()
  ^^^^^^ named IS_INVOKED_BY qualified
@p.E.named()
    ^^^^^^ named IS_INVOKED_BY qualified
void f() {}
''',
    );
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
/// [new E.foo] and [E.foo]
          ^^^^ IS_REFERENCED_BY qualified
                      ^^^^ IS_REFERENCED_BY qualified
enum E {
  v.foo();
   ^^^^ IS_INVOKED_BY qualified
  const new foo();
  const new bar() : this.foo();
                        ^^^^ IS_INVOKED_BY qualified
  const factory baz() = E.foo;
                         ^^^^ IS_REFERENCED_BY qualified
}
void useConstructor() {
  E.foo();
   ^^^^ IS_INVOKED_BY qualified
  E.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  E a = .foo();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
/// [new E.foo] and [E.foo]
          ^^^^ IS_REFERENCED_BY qualified
                      ^^^^ IS_REFERENCED_BY qualified
enum E.foo() {
  v.foo();
   ^^^^ IS_INVOKED_BY qualified
  const new bar() : this.foo();
                        ^^^^ IS_INVOKED_BY qualified
  const factory baz() = E.foo;
                         ^^^^ IS_REFERENCED_BY qualified
}
void useConstructor() {
  E.foo();
   ^^^^ IS_INVOKED_BY qualified
  E.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  E a = .foo();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
/// [new E.foo] and [E.foo]
          ^^^^ IS_REFERENCED_BY qualified
                      ^^^^ IS_REFERENCED_BY qualified
enum E {
  v.foo();
   ^^^^ IS_INVOKED_BY qualified
  const E.foo();
  const E.bar() : this.foo();
                      ^^^^ IS_INVOKED_BY qualified
  const factory E.baz() = E.foo;
                           ^^^^ IS_REFERENCED_BY qualified
}
void useConstructor() {
  E.foo();
   ^^^^ IS_INVOKED_BY qualified
  E.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  E a = .foo();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
/// [new E] and [E.new]
          ^0 IS_REFERENCED_BY qualified
                  ^^^^ IS_REFERENCED_BY qualified
enum E {
  v1,
    ^0 IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
  v2(),
    ^0 IS_INVOKED_BY qualified
  v3.new();
    ^^^^ IS_INVOKED_BY qualified
  const factory E.other() = E;
                             ^0 IS_REFERENCED_BY qualified
}
void useConstructor() {
  E();
   ^0 IS_INVOKED_BY qualified
  E.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  E a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
/// [new E] and [E.new]
          ^0 IS_REFERENCED_BY qualified
                  ^^^^ IS_REFERENCED_BY qualified
enum E {
  v1,
    ^0 IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
  v2(),
    ^0 IS_INVOKED_BY qualified
  v3.new();
    ^^^^ IS_INVOKED_BY qualified
  const new ();
  const factory other() = E.new;
                           ^^^^ IS_REFERENCED_BY qualified
}
void useConstructor() {
  E();
   ^0 IS_INVOKED_BY qualified
  E.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  E a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
/// [new E] and [E.new]
          ^0 IS_REFERENCED_BY qualified
                  ^^^^ IS_REFERENCED_BY qualified
enum E() {
  v1,
    ^0 IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
  v2(),
    ^0 IS_INVOKED_BY qualified
  v3.new();
    ^^^^ IS_INVOKED_BY qualified
  const factory other() = E.new;
                           ^^^^ IS_REFERENCED_BY qualified
}
void useConstructor() {
  E();
   ^0 IS_INVOKED_BY qualified
  E.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  E a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
/// [new E] and [E.new]
          ^0 IS_REFERENCED_BY qualified
                  ^^^^ IS_REFERENCED_BY qualified
enum E {
  v1,
    ^0 IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
  v2(),
    ^0 IS_INVOKED_BY qualified
  v3.new();
    ^^^^ IS_INVOKED_BY qualified
  const E();
  const factory E.other() = E;
                             ^0 IS_REFERENCED_BY qualified
}
void useConstructor() {
  E();
   ^0 IS_INVOKED_BY qualified
  E.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  E a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
/// [new E] and [E.new]
          ^0 IS_REFERENCED_BY qualified
                  ^^^^ IS_REFERENCED_BY qualified
enum E {
  v1,
    ^0 IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified
  v2(),
    ^0 IS_INVOKED_BY qualified
  v3.new();
    ^^^^ IS_INVOKED_BY qualified
  const E.new();
  const factory E.other() = E.new;
                             ^^^^ IS_REFERENCED_BY qualified
}
void useConstructor() {
  E();
   ^0 IS_INVOKED_BY qualified
  E.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  E a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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

    assertElementsIndexText(
      result,
      {
        'new': result.findElement.unnamedConstructor('A'),
        'named': result.findElement.constructor('named', of: 'A'),
      },
      r'''
import 'test.dart' as p;

extension type const A(int it) {
  const A.named(int it) : this(it);
                              ^0 new IS_INVOKED_BY qualified
}

@A(0)
  ^0 new IS_INVOKED_BY qualified
@p.A(0)
    ^0 new IS_INVOKED_BY qualified
@A.named(0)
  ^^^^^^ named IS_INVOKED_BY qualified
@p.A.named(0)
    ^^^^^^ named IS_INVOKED_BY qualified
void f() {}
''',
    );
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
/// [new A.foo] and [A.foo]
          ^^^^ IS_REFERENCED_BY qualified
                      ^^^^ IS_REFERENCED_BY qualified
extension type A(int it) {
  new foo(this.it);
  new bar() : this.foo(0);
                  ^^^^ IS_INVOKED_BY qualified
  factory baz(int it) = A.foo;
                         ^^^^ IS_REFERENCED_BY qualified
}
void useConstructor() {
  A.foo(0);
   ^^^^ IS_INVOKED_BY qualified
  A.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .foo(0);
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
/// [new A.foo] and [A.foo]
          ^^^^ IS_REFERENCED_BY qualified
                      ^^^^ IS_REFERENCED_BY qualified
extension type A.foo(int it) {
  new bar() : this.foo(0);
                  ^^^^ IS_INVOKED_BY qualified
  factory baz(int it) = A.foo;
                         ^^^^ IS_REFERENCED_BY qualified
}
void useConstructor() {
  A.foo(0);
   ^^^^ IS_INVOKED_BY qualified
  A.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .foo(0);
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
/// [new A.foo] and [A.foo]
          ^^^^ IS_REFERENCED_BY qualified
                      ^^^^ IS_REFERENCED_BY qualified
extension type A(int it) {
  A.foo(this.it);
  A.bar() : this.foo(0);
                ^^^^ IS_INVOKED_BY qualified
  factory A.baz(int it) = A.foo;
                           ^^^^ IS_REFERENCED_BY qualified
}
void useConstructor() {
  A.foo(0);
   ^^^^ IS_INVOKED_BY qualified
  A.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .foo(0);
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
/// [new A] and [A.new]
          ^0 IS_REFERENCED_BY qualified
                  ^^^^ IS_REFERENCED_BY qualified
extension type A.named(int it) {
  new (this.it);
  new bar() : this(0);
                  ^0 IS_INVOKED_BY qualified
  factory baz(int it) = A.new;
                         ^^^^ IS_REFERENCED_BY qualified
}
void useConstructor() {
  A(0);
   ^0 IS_INVOKED_BY qualified
  A.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .new(0);
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
/// [new A] and [A.new]
          ^0 IS_REFERENCED_BY qualified
                  ^^^^ IS_REFERENCED_BY qualified
extension type A(int it) {
  new bar() : this(0);
                  ^0 IS_INVOKED_BY qualified
  factory baz(int it) = A.new;
                         ^^^^ IS_REFERENCED_BY qualified
}
void useConstructor() {
  A(0);
   ^0 IS_INVOKED_BY qualified
  A.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .new(0);
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
/// [new A] and [A.new]
          ^0 IS_REFERENCED_BY qualified
                  ^^^^ IS_REFERENCED_BY qualified
extension type A.named(int it) {
  A(this.it);
  A.bar() : this(0);
                ^0 IS_INVOKED_BY qualified
  factory A.baz(int it) = A.new;
                           ^^^^ IS_REFERENCED_BY qualified
}
void useConstructor() {
  A(0);
   ^0 IS_INVOKED_BY qualified
  A.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .new(0);
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
/// [new A] and [A.new]
          ^0 IS_REFERENCED_BY qualified
                  ^^^^ IS_REFERENCED_BY qualified
extension type A.named(int it) {
  A.new(this.it);
  A.bar() : this.new(0);
                ^^^^ IS_INVOKED_BY qualified
  factory A.baz(int it) = A.new;
                           ^^^^ IS_REFERENCED_BY qualified
}
void useConstructor() {
  A.new(0);
   ^^^^ IS_INVOKED_BY qualified
  A.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified
  A a = .new(0);
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified
}
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
import 'test.dart' as p;

enum E {
  v;
  const E();
        ^ IS_REFERENCED_BY
  const E.named();
        ^ IS_REFERENCED_BY
  static const int myConstant = 0;
}

@E()
 ^ IS_REFERENCED_BY
@p.E()
   ^ IS_REFERENCED_BY qualified
@E.named()
 ^ IS_REFERENCED_BY
@p.E.named()
   ^ IS_REFERENCED_BY qualified
@E.myConstant
 ^ IS_REFERENCED_BY
@p.E.myConstant
   ^ IS_REFERENCED_BY qualified
void f() {}
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
import 'test.dart' as p;

enum E { v }

/// [E] and [p.E].
     ^ IS_REFERENCED_BY
               ^ IS_REFERENCED_BY qualified
void f() {}
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
import 'test.dart' as p;

enum E {
  v;
  const E();
        ^ IS_REFERENCED_BY
}

void f() {
  const E();
        ^ IS_REFERENCED_BY
  const p.E();
          ^ IS_REFERENCED_BY qualified
}
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
import 'test.dart' as p;

enum E {
  v;
  static void foo() {}
}

void f() {
  E.foo();
  ^ IS_REFERENCED_BY
  p.E.foo();
    ^ IS_REFERENCED_BY qualified
}
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
import 'test.dart' as p;

enum E { v }

void f() {
  E v1;
  ^ IS_REFERENCED_BY
  p.E v2;
    ^ IS_REFERENCED_BY qualified
}
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

    assertElementIndexText(result, result.findElement.extension_('E'), r'''
import 'test.dart' as p;

extension E on int {
  static void foo() {}
}

void f() {
  E.foo();
  ^ IS_REFERENCED_BY
  p.E.foo();
    ^ IS_REFERENCED_BY qualified
}
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
    var extension = result.findElement.extension_('E');

    assertElementIndexText(result, extension, r'''
import 'test.dart' as p;

extension E on int {
  void foo() {}
}

void f() {
  E(0).foo();
  ^ IS_REFERENCED_BY
  p.E(0).foo();
    ^ IS_REFERENCED_BY qualified
}
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

    assertElementIndexText(result, result.findElement.extensionType('A'), r'''
import 'test.dart' as p;

extension type A(int it) {}

extension type B(int it) implements A {}
                                    ^ IS_IMPLEMENTED_BY
                                    ^ IS_REFERENCED_BY
extension type B_q(int it) implements p.A {}
                                        ^ IS_IMPLEMENTED_BY qualified
                                        ^ IS_REFERENCED_BY qualified
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
import 'test.dart' as p;

extension type const A(int it) {}

@A(0)
 ^ IS_REFERENCED_BY
@p.A(0)
   ^ IS_REFERENCED_BY qualified
void f() {}
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
import 'test.dart' as p;

extension type A(int it) {}

/// [A] and [p.A].
     ^ IS_REFERENCED_BY
               ^ IS_REFERENCED_BY qualified
void f() {}
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
import 'test.dart' as p;

extension type A(int it) {}

void f() {
  A(0);
  ^ IS_REFERENCED_BY
  p.A(0);
    ^ IS_REFERENCED_BY qualified
}
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
import 'test.dart' as p;

extension type A(int it) {
  static void foo() {}
}

void f() {
  A.foo();
  ^ IS_REFERENCED_BY
  p.A.foo();
    ^ IS_REFERENCED_BY qualified
}
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
import 'test.dart' as p;

extension type A(int it) {}

void f() {
  A v1;
  ^ IS_REFERENCED_BY
  p.A v2;
    ^ IS_REFERENCED_BY qualified
}
Prefixes: (unprefixed),p
''');
  }

  test_FieldElement_ofClass_instance_fieldDeclaration() async {
    var result = await _indexTestCode('''
/// [foo] and [A.foo]
class A {
  int foo;
  A({this.foo = 0});
  A.foo() : foo = 0;

  void useField() {
    foo;
    foo = 0;
    foo += 1;
    foo ??= 2;
// [diag.deadCode][column 13][length 127] Dead code.
//          ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
    foo++;
    --foo;
    this.foo;
    this.foo = 0;
    this.foo += 1;
    this.foo ??= 2;
//               ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
    this.foo++;
    --this.foo;
  }
}

void useField(A a) {
  a.foo;
  a.foo = 0;
  a.foo += 1;
  a.foo ??= 2;
// [diag.deadCode][column 13][length 37] Dead code.
//          ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
  a.foo++;
  --a.foo;
  A(foo: 0);
}

class B extends A {
  void useSuper() {
    super.foo;
    super.foo = 0;
    super.foo += 1;
    super.foo ??= 2;
// [diag.deadCode][column 19][length 36] Dead code.
//                ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
    super.foo++;
    --super.foo;
  }
}
''');
    var field = result.findElement.field('foo');

    assertElementsIndexText(
      result,
      {
        'field': field,
        'getter': field.getter!,
        'setter': field.setter!,
        'num.+': result.resolvedUnit.typeProvider.numElement.getMethod('+')!,
        'num.-': result.resolvedUnit.typeProvider.numElement.getMethod('-')!,
      },
      r'''
/// [foo] and [A.foo]
     ^^^ getter IS_REFERENCED_BY
                 ^^^ getter IS_REFERENCED_BY qualified
class A {
  int foo;
  A({this.foo = 0});
          ^^^ field IS_WRITTEN_BY qualified
  A.foo() : foo = 0;
            ^^^ field IS_WRITTEN_BY qualified

  void useField() {
    foo;
    ^^^ getter IS_INVOKED_BY
    foo = 0;
    ^^^ setter IS_INVOKED_BY
    foo += 1;
    ^^^ getter IS_INVOKED_BY
    ^^^ setter IS_INVOKED_BY
        ^^ num.+ IS_INVOKED_BY qualified
    foo ??= 2;
    ^^^ getter IS_INVOKED_BY
    ^^^ setter IS_INVOKED_BY
    foo++;
    ^^^ getter IS_INVOKED_BY
    ^^^ setter IS_INVOKED_BY
       ^^ num.+ IS_INVOKED_BY qualified
    --foo;
    ^^ num.- IS_INVOKED_BY qualified
      ^^^ getter IS_INVOKED_BY
      ^^^ setter IS_INVOKED_BY
    this.foo;
         ^^^ getter IS_INVOKED_BY qualified
    this.foo = 0;
         ^^^ setter IS_INVOKED_BY qualified
    this.foo += 1;
         ^^^ getter IS_INVOKED_BY qualified
         ^^^ setter IS_INVOKED_BY qualified
             ^^ num.+ IS_INVOKED_BY qualified
    this.foo ??= 2;
         ^^^ getter IS_INVOKED_BY qualified
         ^^^ setter IS_INVOKED_BY qualified
    this.foo++;
         ^^^ getter IS_INVOKED_BY qualified
         ^^^ setter IS_INVOKED_BY qualified
            ^^ num.+ IS_INVOKED_BY qualified
    --this.foo;
    ^^ num.- IS_INVOKED_BY qualified
           ^^^ getter IS_INVOKED_BY qualified
           ^^^ setter IS_INVOKED_BY qualified
  }
}

void useField(A a) {
  a.foo;
    ^^^ getter IS_INVOKED_BY qualified
  a.foo = 0;
    ^^^ setter IS_INVOKED_BY qualified
  a.foo += 1;
    ^^^ getter IS_INVOKED_BY qualified
    ^^^ setter IS_INVOKED_BY qualified
        ^^ num.+ IS_INVOKED_BY qualified
  a.foo ??= 2;
    ^^^ getter IS_INVOKED_BY qualified
    ^^^ setter IS_INVOKED_BY qualified
  a.foo++;
    ^^^ getter IS_INVOKED_BY qualified
    ^^^ setter IS_INVOKED_BY qualified
       ^^ num.+ IS_INVOKED_BY qualified
  --a.foo;
  ^^ num.- IS_INVOKED_BY qualified
      ^^^ getter IS_INVOKED_BY qualified
      ^^^ setter IS_INVOKED_BY qualified
  A(foo: 0);
}

class B extends A {
  void useSuper() {
    super.foo;
          ^^^ getter IS_INVOKED_BY qualified
    super.foo = 0;
          ^^^ setter IS_INVOKED_BY qualified
    super.foo += 1;
          ^^^ getter IS_INVOKED_BY qualified
          ^^^ setter IS_INVOKED_BY qualified
              ^^ num.+ IS_INVOKED_BY qualified
    super.foo ??= 2;
          ^^^ getter IS_INVOKED_BY qualified
          ^^^ setter IS_INVOKED_BY qualified
    super.foo++;
          ^^^ getter IS_INVOKED_BY qualified
          ^^^ setter IS_INVOKED_BY qualified
             ^^ num.+ IS_INVOKED_BY qualified
    --super.foo;
    ^^ num.- IS_INVOKED_BY qualified
            ^^^ getter IS_INVOKED_BY qualified
            ^^^ setter IS_INVOKED_BY qualified
  }
}
''',
    );
  }

  test_FieldElement_ofClass_instance_getterDeclaration() async {
    var result = await _indexTestCode('''
class A {
  A() : foo = 0;
//      ^^^^^^^
// [diag.initializerForNonExistentField] 'foo' isn't a field in the enclosing class.
  int get foo => 0;

  void useGetter() {
    foo;
    this.foo;
  }
}

void useGetter(A a) {
  a.foo;
}

class B extends A {
  void useSuper() {
    super.foo;
  }
}
''');

    var field = result.findElement.field('foo');

    assertElementsIndexText(
      result,
      {'field': field, 'getter': field.getter!},
      r'''
class A {
  A() : foo = 0;
        ^^^ field IS_WRITTEN_BY qualified
  int get foo => 0;

  void useGetter() {
    foo;
    ^^^ getter IS_INVOKED_BY
    this.foo;
         ^^^ getter IS_INVOKED_BY qualified
  }
}

void useGetter(A a) {
  a.foo;
    ^^^ getter IS_INVOKED_BY qualified
}

class B extends A {
  void useSuper() {
    super.foo;
          ^^^ getter IS_INVOKED_BY qualified
  }
}
''',
    );
  }

  test_FieldElement_ofClass_instance_getterSetterDeclarations() async {
    var result = await _indexTestCode('''
/// [foo] and [A.foo]
class A {
  A() : foo = 0;
//      ^^^^^^^
// [diag.initializerForNonExistentField] 'foo' isn't a field in the enclosing class.
  int get foo => 0;
  set foo(int _) {}

  void useField() {
    foo;
    foo = 0;
    foo += 1;
    foo ??= 2;
// [diag.deadCode][column 13][length 127] Dead code.
//          ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
    foo++;
    --foo;
    this.foo;
    this.foo = 0;
    this.foo += 1;
    this.foo ??= 2;
//               ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
    this.foo++;
    --this.foo;
  }
}

void useField(A a) {
  a.foo;
  a.foo = 0;
  a.foo += 1;
  a.foo ??= 2;
// [diag.deadCode][column 13][length 24] Dead code.
//          ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
  a.foo++;
  --a.foo;
}

class B extends A {
  void useSuper() {
    super.foo;
    super.foo = 0;
    super.foo += 1;
    super.foo ??= 2;
// [diag.deadCode][column 19][length 36] Dead code.
//                ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
    super.foo++;
    --super.foo;
  }
}
''');

    var field = result.findElement.field('foo');

    assertElementsIndexText(
      result,
      {
        'field': field,
        'getter': field.getter!,
        'setter': field.setter!,
        'num.+': result.resolvedUnit.typeProvider.numElement.getMethod('+')!,
        'num.-': result.resolvedUnit.typeProvider.numElement.getMethod('-')!,
      },
      r'''
/// [foo] and [A.foo]
     ^^^ getter IS_REFERENCED_BY
                 ^^^ getter IS_REFERENCED_BY qualified
class A {
  A() : foo = 0;
        ^^^ field IS_WRITTEN_BY qualified
  int get foo => 0;
  set foo(int _) {}

  void useField() {
    foo;
    ^^^ getter IS_INVOKED_BY
    foo = 0;
    ^^^ setter IS_INVOKED_BY
    foo += 1;
    ^^^ getter IS_INVOKED_BY
    ^^^ setter IS_INVOKED_BY
        ^^ num.+ IS_INVOKED_BY qualified
    foo ??= 2;
    ^^^ getter IS_INVOKED_BY
    ^^^ setter IS_INVOKED_BY
    foo++;
    ^^^ getter IS_INVOKED_BY
    ^^^ setter IS_INVOKED_BY
       ^^ num.+ IS_INVOKED_BY qualified
    --foo;
    ^^ num.- IS_INVOKED_BY qualified
      ^^^ getter IS_INVOKED_BY
      ^^^ setter IS_INVOKED_BY
    this.foo;
         ^^^ getter IS_INVOKED_BY qualified
    this.foo = 0;
         ^^^ setter IS_INVOKED_BY qualified
    this.foo += 1;
         ^^^ getter IS_INVOKED_BY qualified
         ^^^ setter IS_INVOKED_BY qualified
             ^^ num.+ IS_INVOKED_BY qualified
    this.foo ??= 2;
         ^^^ getter IS_INVOKED_BY qualified
         ^^^ setter IS_INVOKED_BY qualified
    this.foo++;
         ^^^ getter IS_INVOKED_BY qualified
         ^^^ setter IS_INVOKED_BY qualified
            ^^ num.+ IS_INVOKED_BY qualified
    --this.foo;
    ^^ num.- IS_INVOKED_BY qualified
           ^^^ getter IS_INVOKED_BY qualified
           ^^^ setter IS_INVOKED_BY qualified
  }
}

void useField(A a) {
  a.foo;
    ^^^ getter IS_INVOKED_BY qualified
  a.foo = 0;
    ^^^ setter IS_INVOKED_BY qualified
  a.foo += 1;
    ^^^ getter IS_INVOKED_BY qualified
    ^^^ setter IS_INVOKED_BY qualified
        ^^ num.+ IS_INVOKED_BY qualified
  a.foo ??= 2;
    ^^^ getter IS_INVOKED_BY qualified
    ^^^ setter IS_INVOKED_BY qualified
  a.foo++;
    ^^^ getter IS_INVOKED_BY qualified
    ^^^ setter IS_INVOKED_BY qualified
       ^^ num.+ IS_INVOKED_BY qualified
  --a.foo;
  ^^ num.- IS_INVOKED_BY qualified
      ^^^ getter IS_INVOKED_BY qualified
      ^^^ setter IS_INVOKED_BY qualified
}

class B extends A {
  void useSuper() {
    super.foo;
          ^^^ getter IS_INVOKED_BY qualified
    super.foo = 0;
          ^^^ setter IS_INVOKED_BY qualified
    super.foo += 1;
          ^^^ getter IS_INVOKED_BY qualified
          ^^^ setter IS_INVOKED_BY qualified
              ^^ num.+ IS_INVOKED_BY qualified
    super.foo ??= 2;
          ^^^ getter IS_INVOKED_BY qualified
          ^^^ setter IS_INVOKED_BY qualified
    super.foo++;
          ^^^ getter IS_INVOKED_BY qualified
          ^^^ setter IS_INVOKED_BY qualified
             ^^ num.+ IS_INVOKED_BY qualified
    --super.foo;
    ^^ num.- IS_INVOKED_BY qualified
            ^^^ getter IS_INVOKED_BY qualified
            ^^^ setter IS_INVOKED_BY qualified
  }
}
''',
    );
  }

  test_FieldElement_ofClass_instance_propertyAssignmentTarget() async {
    var result = await _indexTestCode('''
class A {
  num x = 0;
}
class B {
  num? x;
}
void use(A a, A? nullableA, B b, B? nullableB) {
  (a).x = 1;
  (nullableA)?.x = 2;
  (a).x += 3;
  (nullableA)?.x += 4;
  (b).x ??= 5;
  (nullableB)?.x ??= 6;
}
''');

    assertElementsIndexText(
      result,
      {
        'aField': result.findElement.field('x', of: 'A'),
        'aGetter': result.findElement.getter('x', of: 'A'),
        'aSetter': result.findElement.setter('x', of: 'A'),
        'bField': result.findElement.field('x', of: 'B'),
        'bGetter': result.findElement.getter('x', of: 'B'),
        'bSetter': result.findElement.setter('x', of: 'B'),
        'num.+': result.resolvedUnit.typeProvider.numElement.getMethod('+')!,
      },
      r'''
class A {
  num x = 0;
}
class B {
  num? x;
}
void use(A a, A? nullableA, B b, B? nullableB) {
  (a).x = 1;
      ^ aSetter IS_INVOKED_BY qualified
  (nullableA)?.x = 2;
               ^ aSetter IS_INVOKED_BY qualified
  (a).x += 3;
      ^ aGetter IS_INVOKED_BY qualified
      ^ aSetter IS_INVOKED_BY qualified
        ^^ num.+ IS_INVOKED_BY qualified
  (nullableA)?.x += 4;
               ^ aGetter IS_INVOKED_BY qualified
               ^ aSetter IS_INVOKED_BY qualified
                 ^^ num.+ IS_INVOKED_BY qualified
  (b).x ??= 5;
      ^ bGetter IS_INVOKED_BY qualified
      ^ bSetter IS_INVOKED_BY qualified
  (nullableB)?.x ??= 6;
               ^ bGetter IS_INVOKED_BY qualified
               ^ bSetter IS_INVOKED_BY qualified
}
''',
    );
  }

  test_FieldElement_ofClass_instance_propertyExtraction() async {
    var result = await _indexTestCode('''
class A {
  num x = 0;
}
void use(A a, A? nullableA) {
  (a).x;
  (nullableA)?.x;
}
''');

    var getter = result.findElement.getter('x', of: 'A');
    assertElementIndexText(result, getter, r'''
class A {
  num x = 0;
}
void use(A a, A? nullableA) {
  (a).x;
      ^ IS_INVOKED_BY qualified
  (nullableA)?.x;
               ^ IS_INVOKED_BY qualified
}
''');
  }

  test_FieldElement_ofClass_instance_setterDeclaration() async {
    var result = await _indexTestCode('''
class A {
  A() : foo = 0;
//      ^^^^^^^
// [diag.initializerForNonExistentField] 'foo' isn't a field in the enclosing class.
  set foo(int _) {}

  void useSetter() {
    foo = 0;
    this.foo = 0;
  }
}

void useSetter(A a) {
  a.foo = 0;
}

class B extends A {
  void useSuper() {
    super.foo = 0;
  }
}
''');

    var field = result.findElement.field('foo');

    assertElementsIndexText(
      result,
      {'field': field, 'setter': field.setter!},
      r'''
class A {
  A() : foo = 0;
        ^^^ field IS_WRITTEN_BY qualified
  set foo(int _) {}

  void useSetter() {
    foo = 0;
    ^^^ setter IS_INVOKED_BY
    this.foo = 0;
         ^^^ setter IS_INVOKED_BY qualified
  }
}

void useSetter(A a) {
  a.foo = 0;
    ^^^ setter IS_INVOKED_BY qualified
}

class B extends A {
  void useSuper() {
    super.foo = 0;
          ^^^ setter IS_INVOKED_BY qualified
  }
}
''',
    );
  }

  test_FieldElement_ofClass_parenthesizedReceiver_compound() async {
    var result = await _indexTestCode('''
class A {
  int foo = 0;
}

void f(A a) {
  (a).foo += 2;
}
''');
    var field = result.findElement.field('foo');

    assertElementsIndexText(
      result,
      {
        'field': field,
        'getter': field.getter!,
        'setter': field.setter!,
        'num.+': result.resolvedUnit.typeProvider.numElement.getMethod('+')!,
      },
      r'''
class A {
  int foo = 0;
}

void f(A a) {
  (a).foo += 2;
      ^^^ getter IS_INVOKED_BY qualified
      ^^^ setter IS_INVOKED_BY qualified
          ^^ num.+ IS_INVOKED_BY qualified
}
''',
    );
  }

  test_FieldElement_ofClass_parenthesizedReceiver_ifNull() async {
    var result = await _indexTestCode('''
class A {
  int? foo;
}

void f(A a) {
  (a).foo ??= 2;
}
''');
    var field = result.findElement.field('foo');

    assertElementsIndexText(
      result,
      {'field': field, 'getter': field.getter!, 'setter': field.setter!},
      r'''
class A {
  int? foo;
}

void f(A a) {
  (a).foo ??= 2;
      ^^^ getter IS_INVOKED_BY qualified
      ^^^ setter IS_INVOKED_BY qualified
}
''',
    );
  }

  test_FieldElement_ofClass_static_fieldDeclaration() async {
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

    var field = result.findElement.field('foo');

    assertElementsIndexText(
      result,
      {'field': field, 'getter': field.getter!, 'setter': field.setter!},
      r'''
/// [foo] and [A.foo]
     ^^^ getter IS_REFERENCED_BY
                 ^^^ getter IS_REFERENCED_BY qualified
class A {
  static int foo = 0;
  static void useField() {
    foo;
    ^^^ getter IS_INVOKED_BY
    foo = 0;
    ^^^ setter IS_INVOKED_BY
    A.foo;
      ^^^ getter IS_INVOKED_BY qualified
    A.foo = 0;
      ^^^ setter IS_INVOKED_BY qualified
  }
}

void useField() {
  A.foo;
    ^^^ getter IS_INVOKED_BY qualified
  A.foo = 0;
    ^^^ setter IS_INVOKED_BY qualified
  A a = .foo;
         ^^^ getter IS_INVOKED_BY qualified
}
''',
    );
  }

  test_FieldElement_ofEnum_instance_fieldDeclaration() async {
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

    assertElementsIndexText(
      result,
      {'field': field, 'getter': field.getter!, 'setter': field.setter!},
      r'''
/// [foo] and [E.foo]
     ^^^ getter IS_REFERENCED_BY
                 ^^^ getter IS_REFERENCED_BY qualified
enum E {
  v;
  int? foo; // a compile-time error
  E({this.foo});
          ^^^ field IS_WRITTEN_BY qualified
  void useField() {
    foo;
    ^^^ getter IS_INVOKED_BY
    foo = 0;
    ^^^ setter IS_INVOKED_BY
  }
}
void useField(E e) {
  e.foo;
    ^^^ getter IS_INVOKED_BY qualified
  e.foo = 0;
    ^^^ setter IS_INVOKED_BY qualified
  E(foo: 0);
}
''',
    );
  }

  test_FieldElement_ofEnum_instance_getterDeclaration() async {
    var result = await _indexTestCode('''
enum E {
  v;
  E() : foo = 0;
//      ^^^^^^^
// [diag.initializerForNonExistentField] 'foo' isn't a field in the enclosing class.
  int get foo => 0;
}
''');

    var field = result.findElement.field('foo');

    assertElementsIndexText(
      result,
      {'field': field, 'getter': field.getter!},
      r'''
enum E {
  v;
  E() : foo = 0;
        ^^^ field IS_WRITTEN_BY qualified
  int get foo => 0;
}
''',
    );
  }

  test_FieldElement_ofEnum_instance_getterSetterDeclarations() async {
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

    var field = result.findElement.field('foo');

    assertElementsIndexText(
      result,
      {'field': field, 'getter': field.getter!, 'setter': field.setter!},
      r'''
enum E {
  v;
  E() : foo = 0;
        ^^^ field IS_WRITTEN_BY qualified
  int get foo => 0;
  set foo(_) {}
}
''',
    );
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

    var index = result.resolvedUnit.typeProvider.enumElement!.getField(
      'index',
    )!;

    assertElementsIndexText(
      result,
      {'field': index, 'getter': index.getter!},
      r'''
enum MyEnum {
  v1, v2, v3
}
void f() {
  MyEnum.values;
  MyEnum.v1.index;
            ^^^^^ getter IS_INVOKED_BY qualified
  MyEnum.v1;
  MyEnum.v2;
}
''',
    );
  }

  test_FieldElement_ofEnum_instance_setterDeclaration() async {
    var result = await _indexTestCode('''
enum E {
  v;
  E() : foo = 0;
//      ^^^^^^^
// [diag.initializerForNonExistentField] 'foo' isn't a field in the enclosing class.
  set foo(_) {}
}
''');

    var field = result.findElement.field('foo');

    assertElementsIndexText(
      result,
      {'field': field, 'setter': field.setter!},
      r'''
enum E {
  v;
  E() : foo = 0;
        ^^^ field IS_WRITTEN_BY qualified
  set foo(_) {}
}
''',
    );
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

    assertElementsIndexText(
      result,
      {
        'values.field': result.findElement.field('values'),
        'values.getter': result.findElement.field('values').getter!,
        'v1.field': result.findElement.field('v1'),
        'v1.getter': result.findElement.field('v1').getter!,
        'v2.field': result.findElement.field('v2'),
        'v2.getter': result.findElement.field('v2').getter!,
      },
      r'''
import 'test.dart' as p;

/// [v1], [MyEnum.v1], and [p.MyEnum.v1]
     ^^ v1.getter IS_REFERENCED_BY
                  ^^ v1.getter IS_REFERENCED_BY qualified
                                     ^^ v1.getter IS_REFERENCED_BY qualified
enum MyEnum {
  v1, v2, v3
}
void f() {
  MyEnum.values;
         ^^^^^^ values.getter IS_INVOKED_BY qualified
  MyEnum.v1.index;
         ^^ v1.getter IS_INVOKED_BY qualified
  MyEnum.v1;
         ^^ v1.getter IS_INVOKED_BY qualified
  MyEnum.v2;
         ^^ v2.getter IS_INVOKED_BY qualified
  p.MyEnum.v1;
           ^^ v1.getter IS_INVOKED_BY qualified
  p.MyEnum.values;
           ^^^^^^ values.getter IS_INVOKED_BY qualified
}
''',
    );
  }

  test_FieldElement_ofExtension_instance_getterSetterDeclarations() async {
    var result = await _indexTestCode('''
extension E on int {
  int get foo => 0;
  set foo(int _) {}
}

void useField(int a) {
  a.foo;
  a.foo = 0;
  a.foo += 1;
  a.foo ??= 2;
// [diag.deadCode][column 13][length 115] Dead code.
//          ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
  a.foo++;
  --a.foo;
  E(a).foo;
  E(a).foo = 0;
  E(a).foo += 1;
  E(a).foo ??= 2;
//             ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
  E(a).foo++;
  --E(a).foo;
}
''');

    var field = result.findElement.field('foo');

    assertElementsIndexText(
      result,
      {
        'field': field,
        'getter': field.getter!,
        'setter': field.setter!,
        'num.+': result.resolvedUnit.typeProvider.numElement.getMethod('+')!,
        'num.-': result.resolvedUnit.typeProvider.numElement.getMethod('-')!,
      },
      r'''
extension E on int {
  int get foo => 0;
  set foo(int _) {}
}

void useField(int a) {
  a.foo;
    ^^^ getter IS_INVOKED_BY qualified
  a.foo = 0;
    ^^^ setter IS_INVOKED_BY qualified
  a.foo += 1;
    ^^^ getter IS_INVOKED_BY qualified
    ^^^ setter IS_INVOKED_BY qualified
        ^^ num.+ IS_INVOKED_BY qualified
  a.foo ??= 2;
    ^^^ getter IS_INVOKED_BY qualified
    ^^^ setter IS_INVOKED_BY qualified
  a.foo++;
    ^^^ getter IS_INVOKED_BY qualified
    ^^^ setter IS_INVOKED_BY qualified
       ^^ num.+ IS_INVOKED_BY qualified
  --a.foo;
  ^^ num.- IS_INVOKED_BY qualified
      ^^^ getter IS_INVOKED_BY qualified
      ^^^ setter IS_INVOKED_BY qualified
  E(a).foo;
       ^^^ getter IS_INVOKED_BY qualified
  E(a).foo = 0;
       ^^^ setter IS_INVOKED_BY qualified
  E(a).foo += 1;
       ^^^ getter IS_INVOKED_BY qualified
       ^^^ setter IS_INVOKED_BY qualified
           ^^ num.+ IS_INVOKED_BY qualified
  E(a).foo ??= 2;
       ^^^ getter IS_INVOKED_BY qualified
       ^^^ setter IS_INVOKED_BY qualified
  E(a).foo++;
       ^^^ getter IS_INVOKED_BY qualified
       ^^^ setter IS_INVOKED_BY qualified
          ^^ num.+ IS_INVOKED_BY qualified
  --E(a).foo;
  ^^ num.- IS_INVOKED_BY qualified
         ^^^ getter IS_INVOKED_BY qualified
         ^^^ setter IS_INVOKED_BY qualified
}
''',
    );
  }

  test_FieldElement_ofExtensionType_static_fieldDeclaration() async {
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

    assertElementsIndexText(
      result,
      {'field': field, 'getter': field.getter!, 'setter': field.setter!},
      r'''
/// [foo] and [A.foo]
     ^^^ getter IS_REFERENCED_BY
                 ^^^ getter IS_REFERENCED_BY qualified
extension type A(int it) {
  static int foo = 0;
  void useField() {
    foo;
    ^^^ getter IS_INVOKED_BY
    foo = 0;
    ^^^ setter IS_INVOKED_BY
  }
}
void useField() {
  A.foo;
    ^^^ getter IS_INVOKED_BY qualified
  A.foo = 0;
    ^^^ setter IS_INVOKED_BY qualified
}
''',
    );
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

    assertElementsIndexText(
      result,
      {
        'field': result.findElement.field('test'),
        'parameter': result.findElement
            .unnamedConstructor('A')
            .parameter('test'),
      },
      r'''
class A {
  A({this.test}) : assert(test != null);
          ^^^^ field IS_WRITTEN_BY qualified
                          ^^^^ parameter IS_READ_BY
  int? test;
}
void foo() {
  A _ = .new(test: 0);
             ^^^^ parameter IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}
''',
    );
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
class A({int? test}) {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  this : assert(test != null) {
                ^^^^ IS_READ_BY
    test;
    ^^^^ IS_READ_BY
    test = 0;
    ^^^^ IS_WRITTEN_BY
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY
  }

  A.redirect({int? test}) : this(test: test);
                                 ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

class B extends A {
  B({super.test});
           ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

class C extends A {
  C({int? test}) : super(test: test);
                         ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

void f() {
  A(test: 0);
    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  A _ = .new(test: 0);
             ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}
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
class A<T>({T? test}) {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  this : assert(test != null) {
                ^^^^ IS_READ_BY
    test;
    ^^^^ IS_READ_BY
    test = null;
    ^^^^ IS_WRITTEN_BY
    (test,) = (null,);
     ^^^^ IS_WRITTEN_BY
    for (test in [null]) {}
         ^^^^ IS_WRITTEN_BY
  }

  A.redirect({T? test}) : this(test: test);
                               ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

class B<T> extends A<T> {
  B({super.test});
           ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

class C<T> extends A<T> {
  C({T? test}) : super(test: test);
                       ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

void f() {
  A(test: 0);
    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  A<int> _ = .new(test: 0);
                  ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}
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
class A([int? test]) {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  this : assert(test != null) {
                ^^^^ IS_READ_BY
    test;
    ^^^^ IS_READ_BY
    test = 0;
    ^^^^ IS_WRITTEN_BY
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY
  }

  A.redirect([int? test]) : this(test);
}

class B extends A {
  B([super.test]);
           ^^^^ IS_REFERENCED_BY qualified
}

class C extends A {
  C([int? test]) : super(test);
}

void f() {
  A(0);
  A _ = .new(0);
}
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
class A({required int test}) {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  this : assert(test != -1) {
                ^^^^ IS_READ_BY
    test;
    ^^^^ IS_READ_BY
    test = 0;
    ^^^^ IS_WRITTEN_BY
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY
  }

  A.redirect({required int test}) : this(test: test);
                                         ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

class B extends A {
  B({required super.test});
                    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

class C extends A {
  C({required int test}) : super(test: test);
                                 ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

void f() {
  A(test: 0);
    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  A _ = .new(test: 0);
             ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}
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
class A(int test) {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  this : assert(test != -1) {
                ^^^^ IS_READ_BY
    test;
    ^^^^ IS_READ_BY
    test = 0;
    ^^^^ IS_WRITTEN_BY
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY
  }

  A.redirect(int test) : this(test);
}

class B extends A {
  B(super.test);
          ^^^^ IS_REFERENCED_BY qualified
}

class C extends A {
  C(int test) : super(test);
}

void f() {
  A(0);
  A _ = .new(0);
}
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
class A {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  A({int? test}) : assert(test != null) {
                          ^^^^ IS_READ_BY
    test;
    ^^^^ IS_READ_BY
    test = 0;
    ^^^^ IS_WRITTEN_BY
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY
  }

  A.redirect({int? test}) : this(test: test);
                                 ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

class B extends A {
  B({super.test});
           ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

class C extends A {
  C({int? test}) : super(test: test);
                         ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

void f() {
  A(test: 0);
    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  A _ = .new(test: 0);
             ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}
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

    assertElementIndexText(
      result,
      result.findElement.unnamedConstructor('A').parameter('test'),
      r'''
import 'test.dart' as p;

class A {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  const A({int? test}) : assert(test != null);
                                ^^^^ IS_READ_BY
  const A.redirect({int? test}) : this(test: test);
                                       ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

class B extends A {
  const B({super.test});
                 ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

class C extends A {
  const C({int? test}) : super(test: test);
                               ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

@A(test: 0)
   ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
@p.A(test: 1)
     ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
void f() {
  const A(test: 2);
          ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  A _ = .new(test: 3);
             ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}
''',
    );
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
class A<T> {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  A({T? test}) : assert(test != null) {
                        ^^^^ IS_READ_BY
    test;
    ^^^^ IS_READ_BY
    test = null;
    ^^^^ IS_WRITTEN_BY
    (test,) = (null,);
     ^^^^ IS_WRITTEN_BY
    for (test in [null]) {}
         ^^^^ IS_WRITTEN_BY
  }

  A.redirect({T? test}) : this(test: test);
                               ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

class B<T> extends A<T> {
  B({super.test});
           ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

class C<T> extends A<T> {
  C({T? test}) : super(test: test);
                       ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

void f() {
  A(test: 0);
    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  A<int> _ = .new(test: 0);
                  ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}
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
class A {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  A([int? test]) : assert(test != null) {
                          ^^^^ IS_READ_BY
    test;
    ^^^^ IS_READ_BY
    test = 0;
    ^^^^ IS_WRITTEN_BY
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY
  }

  A.redirect([int? test]) : this(test);
}

class B extends A {
  B([super.test]);
           ^^^^ IS_REFERENCED_BY qualified
}

class C extends A {
  C([int? test]) : super(test);
}

void f() {
  A(0);
  A _ = .new(0);
}
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
class A {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  A({required int test}) : assert(test != -1) {
                                  ^^^^ IS_READ_BY
    test;
    ^^^^ IS_READ_BY
    test = 0;
    ^^^^ IS_WRITTEN_BY
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY
  }

  A.redirect({required int test}) : this(test: test);
                                         ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

class B extends A {
  B({required super.test});
                    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

class C extends A {
  C({required int test}) : super(test: test);
                                 ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}

void f() {
  A(test: 0);
    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  A _ = .new(test: 0);
             ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}
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
class A {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  A(int test) : assert(test != -1) {
                       ^^^^ IS_READ_BY
    test;
    ^^^^ IS_READ_BY
    test = 0;
    ^^^^ IS_WRITTEN_BY
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY
  }

  A.redirect(int test) : this(test);
}

class B extends A {
  B(super.test);
          ^^^^ IS_REFERENCED_BY qualified
}

class C extends A {
  C(int test) : super(test);
}

void f() {
  A(0);
  A _ = .new(0);
}
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
class A {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  void foo({int? test}) {
    test;
    ^^^^ IS_READ_BY
    test = 0;
    ^^^^ IS_WRITTEN_BY
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY
  }
}

void f(A a) {
  a.foo(test: 0);
        ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  a.foo.call(test: 1);
             ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  (a.foo)(test: 2);
          ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}
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
class A<T> {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  void foo({T? test}) {
    test;
    ^^^^ IS_READ_BY
    test = null;
    ^^^^ IS_WRITTEN_BY
    test = test;
    ^^^^ IS_WRITTEN_BY
           ^^^^ IS_READ_BY
    (test,) = (null,);
     ^^^^ IS_WRITTEN_BY
    for (test in [null]) {}
         ^^^^ IS_WRITTEN_BY
  }
}

void f(A<int> a) {
  a.foo(test: 0);
        ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  a.foo.call(test: 1);
  (a.foo)(test: 2);
}
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
class A {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  void foo([int? test]) {
    test;
    ^^^^ IS_READ_BY
    test = 0;
    ^^^^ IS_WRITTEN_BY
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY
  }
}

void f(A a) {
  a.foo(0);
  a.foo.call(1);
  (a.foo)(2);
}
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
class A {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  void foo({required int test}) {
    test;
    ^^^^ IS_READ_BY
    test = 0;
    ^^^^ IS_WRITTEN_BY
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY
  }
}

void f(A a) {
  a.foo(test: 0);
        ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  a.foo.call(test: 1);
             ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  (a.foo)(test: 2);
          ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}
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
class A {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  void foo(int test) {
    test;
    ^^^^ IS_READ_BY
    test = 0;
    ^^^^ IS_WRITTEN_BY
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY
  }
}

void f(A a) {
  a.foo(0);
  a.foo.call(1);
  (a.foo)(2);
}
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
/// [test]
     ^^^^ IS_REFERENCED_BY
void foo({int? test}) {
  test;
  ^^^^ IS_READ_BY
  test = 1;
  ^^^^ IS_WRITTEN_BY
  test += 2;
  ^^^^ IS_READ_WRITTEN_BY
  (test,) = (0,);
   ^^^^ IS_WRITTEN_BY
  for (test in [0]) {}
       ^^^^ IS_WRITTEN_BY
}
void f() {
  foo(test: 0);
      ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  foo.call(test: 1);
           ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  (foo)(test: 2);
        ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}
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
/// [test]
     ^^^^ IS_REFERENCED_BY
void foo(int a, int b, {int? test}) {
  test;
  ^^^^ IS_READ_BY
  test = 1;
  ^^^^ IS_WRITTEN_BY
  test += 2;
  ^^^^ IS_READ_WRITTEN_BY
  (test,) = (0,);
   ^^^^ IS_WRITTEN_BY
  for (test in [0]) {}
       ^^^^ IS_WRITTEN_BY
}

void f() {
  foo(0, test: 0, 0);
         ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  foo.call(0, test: 1, 0);
              ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  (foo)(0, test: 2, 0);
           ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}
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
/// [test]
     ^^^^ IS_REFERENCED_BY
void foo([int? test]) {
  test;
  ^^^^ IS_READ_BY
  test = 1;
  ^^^^ IS_WRITTEN_BY
  test += 2;
  ^^^^ IS_READ_WRITTEN_BY
  (test,) = (0,);
   ^^^^ IS_WRITTEN_BY
  for (test in [0]) {}
       ^^^^ IS_WRITTEN_BY
}
void f() {
  foo(0);
  foo.call(1);
  (foo)(2);
}
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
/// [test]
     ^^^^ IS_REFERENCED_BY
void foo({required int test}) {
  test;
  ^^^^ IS_READ_BY
  test = 1;
  ^^^^ IS_WRITTEN_BY
  test += 2;
  ^^^^ IS_READ_WRITTEN_BY
  (test,) = (0,);
   ^^^^ IS_WRITTEN_BY
  for (test in [0]) {}
       ^^^^ IS_WRITTEN_BY
}

void f() {
  foo(test: 0);
      ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  foo.call(test: 1);
           ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  (foo)(test: 2);
        ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}
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
/// [test]
     ^^^^ IS_REFERENCED_BY
void foo(int test) {
  test;
  ^^^^ IS_READ_BY
  test = 1;
  ^^^^ IS_WRITTEN_BY
  test += 2;
  ^^^^ IS_READ_WRITTEN_BY
  (test,) = (0,);
   ^^^^ IS_WRITTEN_BY
  for (test in [0]) {}
       ^^^^ IS_WRITTEN_BY
}

void f() {
  foo(0);
  foo.call(1);
  (foo)(2);
}
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
class A {
  get foo => null;
  void useGetter() {
    this.foo();
         ^^^ IS_INVOKED_BY qualified
    foo();
    ^^^ IS_INVOKED_BY
  }
}
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
class A {
  int get foo => 0;
}

void useGetter(Object? x) {
  if (x case A(foo: 0)) {}
               ^^^ IS_REFERENCED_BY_PATTERN_FIELD qualified
  if (x case A(: var foo)) {}
               ^0 IS_REFERENCED_BY_PATTERN_FIELD qualified
}
''');
  }

  test_GetterElement_ofClass_parenthesizedReceiver_read() async {
    var result = await _indexTestCode('''
class A {
  int get foo => 0;
  void useGetter() {
    (this).foo;
  }
}''');

    var element = result.findElement.getter('foo');

    assertElementIndexText(result, element, r'''
class A {
  int get foo => 0;
  void useGetter() {
    (this).foo;
           ^^^ IS_INVOKED_BY qualified
  }
}
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
import 'test.dart' as p;

/// [foo], [A.foo], [p.A.foo]
     ^^^ IS_REFERENCED_BY
              ^^^ IS_REFERENCED_BY qualified
                         ^^^ IS_REFERENCED_BY qualified
class A {
  static int get foo => 0;
  static void useGetter() {
    foo;
    ^^^ IS_INVOKED_BY
  }
}

void useGetter() {
  A.foo;
    ^^^ IS_INVOKED_BY qualified
  p.A.foo;
      ^^^ IS_INVOKED_BY qualified
}
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
/// [foo] and [A.foo]
     ^^^ IS_REFERENCED_BY
                 ^^^ IS_REFERENCED_BY qualified
class A {
  void foo() {}
  void useFoo(Object? x) {
    this.foo();
         ^^^ IS_INVOKED_BY qualified
    foo();
    ^^^ IS_INVOKED_BY
    this.foo;
         ^^^ IS_REFERENCED_BY qualified
    foo;
    ^^^ IS_REFERENCED_BY
    if (x case A(foo: _)) {}
                 ^^^ IS_REFERENCED_BY_PATTERN_FIELD qualified
    if (x case A(: var foo)) {}
                 ^0 IS_REFERENCED_BY_PATTERN_FIELD qualified
  }
}
void useFoo(A a) {
  a.foo();
    ^^^ IS_INVOKED_BY qualified
  a.foo;
    ^^^ IS_REFERENCED_BY qualified
}
''');
  }

  test_MethodElement_normal_ofClass_parenthesizedReceiver_ifNull() async {
    var result = await _indexTestCode('''
class A {
  void foo() {}
}

void f(A a) {
  (a).foo ??= () {};
//    ^^^
// [diag.assignmentToMethod] Methods can't be assigned a value.
//            ^^^^^
// [diag.deadCode] Dead code.
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');
    var element = result.findElement.method('foo');

    assertElementIndexText(result, element, r'''
class A {
  void foo() {}
}

void f(A a) {
  (a).foo ??= () {};
      ^^^ IS_REFERENCED_BY qualified
}
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
import 'test.dart' as p;

/// [foo], [A.foo], [p.A.foo]
     ^^^ IS_REFERENCED_BY
              ^^^ IS_REFERENCED_BY qualified
                         ^^^ IS_REFERENCED_BY qualified
class A {
  static A foo() => A();
  static void useFoo() {
    foo();
    ^^^ IS_INVOKED_BY
    foo;
    ^^^ IS_REFERENCED_BY
  }
}

void useFoo() {
  A.foo();
    ^^^ IS_INVOKED_BY qualified
  A.foo;
    ^^^ IS_REFERENCED_BY qualified
  A a = .foo();
         ^^^ IS_INVOKED_BY qualified
  p.A.foo();
      ^^^ IS_INVOKED_BY qualified
  p.A.foo;
      ^^^ IS_REFERENCED_BY qualified
}
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
/// [foo] and [E.foo]
     ^^^ IS_REFERENCED_BY
                 ^^^ IS_REFERENCED_BY qualified
enum E {
  v;
  void foo() {}
  void useFoo() {
    this.foo();
         ^^^ IS_INVOKED_BY qualified
    foo();
    ^^^ IS_INVOKED_BY
    this.foo;
         ^^^ IS_REFERENCED_BY qualified
    foo;
    ^^^ IS_REFERENCED_BY
  }
}
void useFoo(E e) {
  e.foo();
    ^^^ IS_INVOKED_BY qualified
  e.foo;
    ^^^ IS_REFERENCED_BY qualified
}
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
/// [foo] and [E.foo]
     ^^^ IS_REFERENCED_BY
                 ^^^ IS_REFERENCED_BY qualified
enum E {
  v;
  static void foo() {}
  static void useFoo() {
    foo();
    ^^^ IS_INVOKED_BY
    foo;
    ^^^ IS_REFERENCED_BY
  }
}
void useFoo() {
  E.foo();
    ^^^ IS_INVOKED_BY qualified
  E.foo;
    ^^^ IS_REFERENCED_BY qualified
}
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
/// [foo] and [E.foo]
     ^^^ IS_REFERENCED_BY
                 ^^^ IS_REFERENCED_BY qualified
extension E on int {
  void foo() {}
}

void useFoo() {
  0.foo();
    ^^^ IS_INVOKED_BY qualified
  0.foo;
    ^^^ IS_REFERENCED_BY qualified
}
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
/// [foo] and [E.foo]
     ^^^ IS_REFERENCED_BY
                 ^^^ IS_REFERENCED_BY qualified
extension E on int {
  static void foo() {}
}

void useFoo() {
  E.foo();
    ^^^ IS_INVOKED_BY qualified
  E.foo;
    ^^^ IS_REFERENCED_BY qualified
}
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
    var doubleMethod = result.resolvedUnit.findNode.methodDeclaration(
      'foo() {} // double',
    );

    assertElementsIndexText(
      result,
      {
        'int.foo': intMethod.declaredFragment!.element,
        'double.foo': doubleMethod.declaredFragment!.element,
      },
      r'''
/// [foo] and [int.foo]
     ^^^ int.foo IS_REFERENCED_BY
extension on int {
  void foo() {} // int
}

/// [foo] and [double.foo]
     ^^^ double.foo IS_REFERENCED_BY
extension on double {
  void foo() {} // double
}

void useFoo() {
  0.foo();
    ^^^ int.foo IS_INVOKED_BY qualified
  0.foo;
    ^^^ int.foo IS_REFERENCED_BY qualified
  (1.2).foo();
        ^^^ double.foo IS_INVOKED_BY qualified
  (1.2).foo;
        ^^^ double.foo IS_REFERENCED_BY qualified
}
''',
    );

    assertNamesIndexText(
      result,
      {'foo'},
      r'''
/// [foo] and [int.foo]
                   ^^^ IS_READ_BY qualified
extension on int {
  void foo() {} // int
}

/// [foo] and [double.foo]
                      ^^^ IS_READ_BY qualified
extension on double {
  void foo() {} // double
}

void useFoo() {
  0.foo();
  0.foo;
  (1.2).foo();
  (1.2).foo;
}
''',
    );
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
/// [foo] and [A.foo]
     ^^^ IS_REFERENCED_BY
                 ^^^ IS_REFERENCED_BY qualified
extension type A(int it) {
  void foo() {}
  void useFoo() {
    this.foo();
         ^^^ IS_INVOKED_BY qualified
    foo();
    ^^^ IS_INVOKED_BY
    this.foo;
         ^^^ IS_REFERENCED_BY qualified
    foo;
    ^^^ IS_REFERENCED_BY
  }
}
void useFoo() {
  var a = A(0);
  a.foo();
    ^^^ IS_INVOKED_BY qualified
  a.foo;
    ^^^ IS_REFERENCED_BY qualified
}
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
/// [foo] and [A.foo]
     ^^^ IS_REFERENCED_BY
                 ^^^ IS_REFERENCED_BY qualified
extension type A(int it) {
  static void foo() {}
  static void useFoo() {
    foo();
    ^^^ IS_INVOKED_BY
    foo;
    ^^^ IS_REFERENCED_BY
  }
}
void useFoo() {
  A.foo();
    ^^^ IS_INVOKED_BY qualified
  A.foo;
    ^^^ IS_REFERENCED_BY qualified
}
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
/// [foo] and [M.foo]
     ^^^ IS_REFERENCED_BY
                 ^^^ IS_REFERENCED_BY qualified
mixin M {
  void foo() {}
  void useFoo() {
    this.foo();
         ^^^ IS_INVOKED_BY qualified
    foo();
    ^^^ IS_INVOKED_BY
    this.foo;
         ^^^ IS_REFERENCED_BY qualified
    foo;
    ^^^ IS_REFERENCED_BY
  }
}
void useFoo(M m) {
  m.foo();
    ^^^ IS_INVOKED_BY qualified
  m.foo;
    ^^^ IS_REFERENCED_BY qualified
}
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
/// [foo] and [M.foo]
     ^^^ IS_REFERENCED_BY
                 ^^^ IS_REFERENCED_BY qualified
mixin M {
  static void foo() {}
  static void useFoo() {
    foo();
    ^^^ IS_INVOKED_BY
    foo;
    ^^^ IS_REFERENCED_BY
  }
}
void useFoo() {
  M.foo();
    ^^^ IS_INVOKED_BY qualified
  M.foo;
    ^^^ IS_REFERENCED_BY qualified
  M m = .foo();
         ^^^ IS_INVOKED_BY qualified
}
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
/// [operator +] and [A.operator +]
              ^ IS_REFERENCED_BY
                                 ^ IS_REFERENCED_BY qualified
class A {
  operator +(other) => this;
}
void useOperator(A a) {
  a + 1;
    ^ IS_INVOKED_BY qualified
  a += 2;
    ^^ IS_INVOKED_BY qualified
  ++a;
  ^^ IS_INVOKED_BY qualified
  a++;
   ^^ IS_INVOKED_BY qualified
}
''');
  }

  test_MethodElement_operator_ofClass_indexAssignmentTarget() async {
    var result = await _indexTestCode('''
class A {
  num operator [](int i) => 0;
  void operator []=(int i, num v) {}
}
class B {
  num? operator [](int i) => 0;
  void operator []=(int i, num v) {}
}
void useOperator(A a, A? nullableA, B b, B? nullableB) {
  a[0] = 1;
  nullableA?[1] = 2;
  a[2] += 3;
  nullableA?[3] += 4;
  b[4] ??= 5;
  nullableB?[5] ??= 6;
}
''');

    assertElementsIndexText(
      result,
      {
        'aRead': result.findElement.method('[]', of: 'A'),
        'aWrite': result.findElement.method('[]=', of: 'A'),
        'bRead': result.findElement.method('[]', of: 'B'),
        'bWrite': result.findElement.method('[]=', of: 'B'),
        'num.+': result.resolvedUnit.typeProvider.numElement.getMethod('+')!,
      },
      r'''
class A {
  num operator [](int i) => 0;
  void operator []=(int i, num v) {}
}
class B {
  num? operator [](int i) => 0;
  void operator []=(int i, num v) {}
}
void useOperator(A a, A? nullableA, B b, B? nullableB) {
  a[0] = 1;
   ^ aWrite IS_INVOKED_BY qualified
  nullableA?[1] = 2;
            ^ aWrite IS_INVOKED_BY qualified
  a[2] += 3;
   ^ aRead IS_INVOKED_BY qualified
   ^ aWrite IS_INVOKED_BY qualified
       ^^ num.+ IS_INVOKED_BY qualified
  nullableA?[3] += 4;
            ^ aRead IS_INVOKED_BY qualified
            ^ aWrite IS_INVOKED_BY qualified
                ^^ num.+ IS_INVOKED_BY qualified
  b[4] ??= 5;
   ^ bRead IS_INVOKED_BY qualified
   ^ bWrite IS_INVOKED_BY qualified
  nullableB?[5] ??= 6;
            ^ bRead IS_INVOKED_BY qualified
            ^ bWrite IS_INVOKED_BY qualified
}
''',
    );
  }

  test_MethodElement_operator_ofClass_indexCascadeSections() async {
    var result = await _indexTestCode('''
class A {
  num operator [](int i) => 0;
  void operator []=(int i, num v) {}
}
class B {
  num? operator [](int i) => 0;
  void operator []=(int i, num v) {}
}
void useOperator(A a, B b) {
  a..[0]..[1] = 2..[2] += 3;
  b..[4] ??= 5;
}
''');

    assertElementsIndexText(
      result,
      {
        'aRead': result.findElement.method('[]', of: 'A'),
        'aWrite': result.findElement.method('[]=', of: 'A'),
        'bRead': result.findElement.method('[]', of: 'B'),
        'bWrite': result.findElement.method('[]=', of: 'B'),
        'num.+': result.resolvedUnit.typeProvider.numElement.getMethod('+')!,
      },
      r'''
class A {
  num operator [](int i) => 0;
  void operator []=(int i, num v) {}
}
class B {
  num? operator [](int i) => 0;
  void operator []=(int i, num v) {}
}
void useOperator(A a, B b) {
  a..[0]..[1] = 2..[2] += 3;
     ^ aRead IS_INVOKED_BY qualified
          ^ aWrite IS_INVOKED_BY qualified
                   ^ aRead IS_INVOKED_BY qualified
                   ^ aWrite IS_INVOKED_BY qualified
                       ^^ num.+ IS_INVOKED_BY qualified
  b..[4] ??= 5;
     ^ bRead IS_INVOKED_BY qualified
     ^ bWrite IS_INVOKED_BY qualified
}
''',
    );
  }

  test_MethodElement_operator_ofClass_indexExpression() async {
    var result = await _indexTestCode('''
/// [operator []] and [A.operator []]
class A {
  num operator [](int i) => 0;
}
void useOperator(A a, A? b) {
  a[0];
  b?[1];
}
''');

    var element = result.findElement.method('[]');

    assertElementIndexText(result, element, r'''
/// [operator []] and [A.operator []]
class A {
  num operator [](int i) => 0;
}
void useOperator(A a, A? b) {
  a[0];
   ^ IS_INVOKED_BY qualified
  b?[1];
    ^ IS_INVOKED_BY qualified
}
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
/// [operator ~] and [A.operator ~]
              ^ IS_REFERENCED_BY
                                 ^ IS_REFERENCED_BY qualified
class A {
  A operator ~() => this;
}
void useOperator(A a) {
  ~a;
  ^ IS_INVOKED_BY qualified
}
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
/// [operator +] and [E.operator +]
              ^ IS_REFERENCED_BY
                                 ^ IS_REFERENCED_BY qualified
enum E {
  v;
  int operator +(other) => 0;
}
void useOperator(E e) {
  e + 1;
    ^ IS_INVOKED_BY qualified
  e += 2;
    ^^ IS_INVOKED_BY qualified
  ++e;
  ^^ IS_INVOKED_BY qualified
  e++;
   ^^ IS_INVOKED_BY qualified
}
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
/// [operator []] and [E.operator []]
enum E {
  v;
  int operator [](int index) => 0;
}
void useOperator(E e) {
  e[0];
   ^ IS_INVOKED_BY qualified
}
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
/// [operator []=] and [E.operator []=]
enum E {
  v;
  operator []=(int index, int value) {}
}
void useOperator(E e) {
  e[1] = 42;
   ^ IS_INVOKED_BY qualified
}
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
/// [operator ~] and [E.operator ~]
              ^ IS_REFERENCED_BY
                                 ^ IS_REFERENCED_BY qualified
enum E {
  e;
  int operator ~() => 0;
}
void useOperator(E e) {
  ~e;
  ^ IS_INVOKED_BY qualified
}
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
/// [operator +] and [E.operator +]
              ^ IS_REFERENCED_BY
                                 ^ IS_REFERENCED_BY qualified
extension E on int {
  int operator +(int other) => 0;
}
void useOperator(int e) {
  E(e) + 1;
       ^ IS_INVOKED_BY qualified
}
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
/// [operator []] and [E.operator []]
extension E on int {
  int operator [](int index) => 0;
}
void useOperator(int e) {
  E(e)[0];
      ^ IS_INVOKED_BY qualified
}
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
/// [operator []=] and [E.operator []=]
extension E on int {
  operator []=(int index, int value) {}
}
void useOperator(int e) {
  E(e)[1] = 42;
      ^ IS_INVOKED_BY qualified
}
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
/// [operator ~] and [E.operator ~]
              ^ IS_REFERENCED_BY
                                 ^ IS_REFERENCED_BY qualified
extension E on int {
  int operator ~() => 0;
}
void useOperator(int e) {
  ~E(e);
  ^ IS_INVOKED_BY qualified
}
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
/// [operator +] and [A.operator +]
              ^ IS_REFERENCED_BY
                                 ^ IS_REFERENCED_BY qualified
extension type A(int it) {
  int operator +(int other) => 0;
}
void useOperator(A a) {
  a + 1;
    ^ IS_INVOKED_BY qualified
  a += 2;
    ^^ IS_INVOKED_BY qualified
  ++a;
  ^^ IS_INVOKED_BY qualified
  a++;
   ^^ IS_INVOKED_BY qualified
}
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
/// [operator []] and [A.operator []]
extension type A(int it) {
  int operator [](int index) => 0;
}
void useOperator(A a) {
  a[0];
   ^ IS_INVOKED_BY qualified
}
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
/// [operator []=] and [A.operator []=]
extension type A(int it) {
  operator []=(int index, int value) {}
}
void useOperator(A a) {
  a[1] = 42;
   ^ IS_INVOKED_BY qualified
}
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
/// [operator ~] and [A.operator ~]
              ^ IS_REFERENCED_BY
                                 ^ IS_REFERENCED_BY qualified
extension type A(int it) {
  int operator ~() => 0;
}
void useOperator(A a) {
  ~a;
  ^ IS_INVOKED_BY qualified
}
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
/// [operator +] and [M.operator +]
              ^ IS_REFERENCED_BY
                                 ^ IS_REFERENCED_BY qualified
mixin M {
  int operator +(int other) => 0;
}
void useOperator(M m) {
  m + 1;
    ^ IS_INVOKED_BY qualified
  m += 2;
    ^^ IS_INVOKED_BY qualified
  ++m;
  ^^ IS_INVOKED_BY qualified
  m++;
   ^^ IS_INVOKED_BY qualified
}
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
/// [operator []] and [M.operator []]
mixin M {
  int operator [](int index) => 0;
}
void useOperator(M m) {
  m[0];
   ^ IS_INVOKED_BY qualified
}
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
/// [operator []=] and [M.operator []=]
mixin M {
  operator []=(int index, int value) {}
}
void useOperator(M m) {
  m[1] = 42;
   ^ IS_INVOKED_BY qualified
}
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
/// [operator ~] and [M.operator ~]
              ^ IS_REFERENCED_BY
                                 ^ IS_REFERENCED_BY qualified
mixin M {
  int operator ~() => 0;
}
void useOperator(M m) {
  ~m;
  ^ IS_INVOKED_BY qualified
}
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

    assertElementIndexText(result, result.findElement.mixin('A'), r'''
mixin A {}
class B implements A {}
                   ^ IS_IMPLEMENTED_BY
                   ^ IS_REFERENCED_BY
''');
  }

  test_MixinElement_hierarchy_class_with() async {
    var result = await _indexTestCode(r'''
mixin A {}
class B extends Object with A {}
''');

    assertElementIndexText(result, result.findElement.mixin('A'), r'''
mixin A {}
class B extends Object with A {}
                            ^ IS_MIXED_IN_BY
                            ^ IS_REFERENCED_BY
''');
  }

  test_MixinElement_hierarchy_classTypeAlias_with() async {
    var result = await _indexTestCode(r'''
mixin A {}
class B = Object with A;
''');

    assertElementIndexText(result, result.findElement.mixin('A'), r'''
mixin A {}
class B = Object with A;
                      ^ IS_MIXED_IN_BY
                      ^ IS_REFERENCED_BY
''');
  }

  test_MixinElement_hierarchy_enum_implements() async {
    var result = await _indexTestCode(r'''
mixin A {}
enum E implements A {
  v
}
''');

    assertElementIndexText(result, result.findElement.mixin('A'), r'''
mixin A {}
enum E implements A {
                  ^ IS_IMPLEMENTED_BY
                  ^ IS_REFERENCED_BY
  v
}
''');
  }

  test_MixinElement_hierarchy_enum_with() async {
    var result = await _indexTestCode(r'''
mixin A {}
enum E with A {
  v
}
''');

    assertElementIndexText(result, result.findElement.mixin('A'), r'''
mixin A {}
enum E with A {
            ^ IS_MIXED_IN_BY
            ^ IS_REFERENCED_BY
  v
}
''');
  }

  test_MixinElement_hierarchy_extensionType_implements() async {
    var result = await _indexTestCode(r'''
mixin A {}
extension type E(A it) implements A {}
''');

    assertElementIndexText(result, result.findElement.mixin('A'), r'''
mixin A {}
extension type E(A it) implements A {}
                 ^ IS_REFERENCED_BY
                                  ^ IS_IMPLEMENTED_BY
                                  ^ IS_REFERENCED_BY
''');
  }

  test_MixinElement_hierarchy_mixin_implements() async {
    var result = await _indexTestCode(r'''
mixin A {}
mixin M implements A {}
''');

    assertElementIndexText(result, result.findElement.mixin('A'), r'''
mixin A {}
mixin M implements A {}
                   ^ IS_IMPLEMENTED_BY
                   ^ IS_REFERENCED_BY
''');
  }

  test_MixinElement_hierarchy_mixin_on() async {
    var result = await _indexTestCode(r'''
mixin A {}
mixin M on A {}
''');

    assertElementIndexText(result, result.findElement.mixin('A'), r'''
mixin A {}
mixin M on A {}
           ^ CONSTRAINS
           ^ IS_REFERENCED_BY
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
import 'test.dart' as p;

mixin A {
  static const int myConstant = 0;
}

@A.myConstant
 ^ IS_REFERENCED_BY
@p.A.myConstant
   ^ IS_REFERENCED_BY qualified
void f() {}
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
import 'test.dart' as p;

mixin A {}

/// [A] and [p.A].
     ^ IS_REFERENCED_BY
               ^ IS_REFERENCED_BY qualified
void f() {}
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
import 'test.dart' as p;

mixin A {
  static void foo() {}
}

void f() {
  A.foo();
  ^ IS_REFERENCED_BY
  p.A.foo();
    ^ IS_REFERENCED_BY qualified
}
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
import 'test.dart' as p;

mixin A {}

void f(A v1, p.A v2) {}
       ^ IS_REFERENCED_BY
               ^ IS_REFERENCED_BY qualified
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
import 'test.dart' as p;

/// [foo], [A.foo], [p.A.foo]
     ^^^ IS_REFERENCED_BY
              ^^^ IS_REFERENCED_BY qualified
                         ^^^ IS_REFERENCED_BY qualified
class A {
  static set foo(int _) {}
  static void useSetter() {
    foo = 0;
    ^^^ IS_INVOKED_BY
  }
}

void useSetter() {
  A.foo = 0;
    ^^^ IS_INVOKED_BY qualified
  p.A.foo = 0;
      ^^^ IS_INVOKED_BY qualified
}
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
class A {
  A({int? test});
}

class B extends A {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  B({super.test}) : assert(test != null);
                           ^^^^ IS_READ_BY
}

void f() {
  B(test: 0);
    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  B _ = .new(test: 0);
             ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}
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
class A {
  A([int? test]);
}

class B extends A {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  B([super.test]) : assert(test != null);
                           ^^^^ IS_READ_BY
}

void f() {
  B(0);
  B _ = .new(0);
}
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
class A {
  A({required int test});
}

class B extends A {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  B({required super.test}) : assert(test != -1);
                                    ^^^^ IS_READ_BY
}

void f() {
  B(test: 0);
    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
  B _ = .new(test: 0);
             ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified
}
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
class A {
  A(int test);
}

class B extends A {
  /// [test]
       ^^^^ IS_REFERENCED_BY
  B(super.test) : assert(test != -1);
                         ^^^^ IS_READ_BY
}

void f() {
  B(0);
  B _ = .new(0);
}
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
import 'test.dart' as p;

void foo() {}

/// [foo] and [p.foo]
     ^^^ IS_REFERENCED_BY
                 ^^^ IS_REFERENCED_BY qualified
void f() {
  foo();
  ^^^ IS_INVOKED_BY
  p.foo();
    ^^^ IS_INVOKED_BY qualified
  foo;
  ^^^ IS_REFERENCED_BY
  p.foo;
    ^^^ IS_REFERENCED_BY qualified
}
Prefixes: (unprefixed),p
''');
  }

  test_TopLevelFunctionElement_invalidWrite() async {
    var result = await _indexTestCode(r'''
void foo() {}

void f() {
  foo = 0;
//^^^
// [diag.assignmentToFunction] Functions can't be assigned a value.
}
''');

    var element = result.findElement.topFunction('foo');

    assertElementIndexText(result, element, r'''
void foo() {}

void f() {
  foo = 0;
  ^^^ IS_REFERENCED_BY
}
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
import 'dart:math' deferred as math;

void f() {
  math.loadLibrary();
       ^^^^^^^^^^^ IS_INVOKED_BY qualified
}
''');
  }

  test_TopLevelFunctionElement_unqualified_ifNull() async {
    var result = await _indexTestCode('''
void foo() {}

void f() {
  foo ??= () {};
//^^^
// [diag.assignmentToFunction] Functions can't be assigned a value.
//        ^^^^^
// [diag.deadCode] Dead code.
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
}
''');
    var element = result.findElement.topFunction('foo');
    assertElementIndexText(result, element, r'''
void foo() {}

void f() {
  foo ??= () {};
  ^^^ IS_REFERENCED_BY
}
''');
  }

  test_TopLevelVariableElement_getterDeclaration() async {
    var result = await _indexTestCode('''
import 'test.dart' as p;

int get foo => 0;

/// [foo] and [p.foo].
void f() {
  foo;
  p.foo;
}
''');

    var variable = result.findElement.topVar('foo');

    assertElementsIndexText(
      result,
      {'variable': variable, 'getter': variable.getter!},
      r'''
import 'test.dart' as p;

int get foo => 0;

/// [foo] and [p.foo].
     ^^^ getter IS_REFERENCED_BY
                 ^^^ getter IS_REFERENCED_BY qualified
void f() {
  foo;
  ^^^ getter IS_INVOKED_BY
  p.foo;
    ^^^ getter IS_INVOKED_BY qualified
}
Prefixes:
  getter: (unprefixed),p
''',
    );
  }

  test_TopLevelVariableElement_getterDeclaration_invalidWrite() async {
    var result = await _indexTestCode(r'''
int get foo => 0;

void f() {
  foo = 1;
//^^^
// [diag.assignmentToFinal] 'foo' can't be used as a setter because it's final.
}
''');

    var getter = result.findElement.topVar('foo').getter!;

    assertElementIndexText(result, getter, r'''
int get foo => 0;

void f() {
  foo = 1;
  ^^^ IS_REFERENCED_BY
}
''');
  }

  test_TopLevelVariableElement_getterSetterDeclarations() async {
    var result = await _indexTestCode('''
import 'test.dart' as p;

int get foo => 0;
set foo(int _) {}

/// [foo] and [p.foo].
void f() {
  foo;
  foo = 0;
  foo += 1;
  foo ??= 2;
// [diag.deadCode][column 11][length 93] Dead code.
//        ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
  foo++;
  --foo;
  p.foo;
  p.foo = 0;
  p.foo += 1;
  p.foo ??= 2;
//          ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
  p.foo++;
  --p.foo;
}
''');

    var variable = result.findElement.topVar('foo');

    assertElementsIndexText(
      result,
      {
        'variable': variable,
        'getter': variable.getter!,
        'setter': variable.setter!,
        'num.+': result.resolvedUnit.typeProvider.numElement.getMethod('+')!,
        'num.-': result.resolvedUnit.typeProvider.numElement.getMethod('-')!,
      },
      r'''
import 'test.dart' as p;

int get foo => 0;
set foo(int _) {}

/// [foo] and [p.foo].
     ^^^ getter IS_REFERENCED_BY
                 ^^^ getter IS_REFERENCED_BY qualified
void f() {
  foo;
  ^^^ getter IS_INVOKED_BY
  foo = 0;
  ^^^ setter IS_INVOKED_BY
  foo += 1;
  ^^^ getter IS_INVOKED_BY
  ^^^ setter IS_INVOKED_BY
      ^^ num.+ IS_INVOKED_BY qualified
  foo ??= 2;
  ^^^ getter IS_INVOKED_BY
  ^^^ setter IS_INVOKED_BY
  foo++;
  ^^^ getter IS_INVOKED_BY
  ^^^ setter IS_INVOKED_BY
     ^^ num.+ IS_INVOKED_BY qualified
  --foo;
  ^^ num.- IS_INVOKED_BY qualified
    ^^^ getter IS_INVOKED_BY
    ^^^ setter IS_INVOKED_BY
  p.foo;
    ^^^ getter IS_INVOKED_BY qualified
  p.foo = 0;
    ^^^ setter IS_INVOKED_BY qualified
  p.foo += 1;
    ^^^ getter IS_INVOKED_BY qualified
    ^^^ setter IS_INVOKED_BY qualified
        ^^ num.+ IS_INVOKED_BY qualified
  p.foo ??= 2;
    ^^^ getter IS_INVOKED_BY qualified
    ^^^ setter IS_INVOKED_BY qualified
  p.foo++;
    ^^^ getter IS_INVOKED_BY qualified
    ^^^ setter IS_INVOKED_BY qualified
       ^^ num.+ IS_INVOKED_BY qualified
  --p.foo;
  ^^ num.- IS_INVOKED_BY qualified
      ^^^ getter IS_INVOKED_BY qualified
      ^^^ setter IS_INVOKED_BY qualified
}
Prefixes:
  getter: (unprefixed),p
''',
    );
  }

  test_TopLevelVariableElement_getterSetterDeclarations_importCombinator_show() async {
    var result = await _indexTestCode('''
import 'test.dart' show foo;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'test.dart'.

int get foo => 0;
void set foo(_) {}
''');

    var variable = result.findElement.topVar('foo');

    assertElementsIndexText(
      result,
      {
        'variable': variable,
        'getter': variable.getter!,
        'setter': variable.setter!,
      },
      r'''
import 'test.dart' show foo;
                        ^^^ getter IS_REFERENCED_BY qualified
                        ^^^ setter IS_REFERENCED_BY qualified

int get foo => 0;
void set foo(_) {}
''',
    );
  }

  test_TopLevelVariableElement_setterDeclaration() async {
    var result = await _indexTestCode('''
import 'test.dart' as p;

set foo(int _) {}

void f() {
  foo = 0;
  p.foo = 0;
}
''');

    var variable = result.findElement.topVar('foo');

    assertElementsIndexText(
      result,
      {'variable': variable, 'setter': variable.setter!},
      r'''
import 'test.dart' as p;

set foo(int _) {}

void f() {
  foo = 0;
  ^^^ setter IS_INVOKED_BY
  p.foo = 0;
    ^^^ setter IS_INVOKED_BY qualified
}
''',
    );
  }

  test_TopLevelVariableElement_setterDeclaration_importCombinator_show() async {
    var result = await _indexTestCode('''
import 'test.dart' show foo;
//     ^^^^^^^^^^^
// [diag.unusedImport] Unused import: 'test.dart'.

void set foo(_) {}
''');

    var variable = result.findElement.topVar('foo');

    assertElementsIndexText(
      result,
      {'variable': variable, 'setter': variable.setter!},
      r'''
import 'test.dart' show foo;
                        ^^^ setter IS_REFERENCED_BY qualified

void set foo(_) {}
''',
    );
  }

  test_TopLevelVariableElement_variableDeclaration() async {
    var result = await _indexTestCode('''
import 'test.dart' as p;

int foo = 0;

/// [foo] and [p.foo].
@foo
// [diag.invalidAnnotation][column 1][length 4] Annotation must be either a const variable reference or const constructor invocation.
@p.foo
// [diag.invalidAnnotation][column 1][length 6] Annotation must be either a const variable reference or const constructor invocation.
void f() {
  foo;
  foo = 0;
  foo += 1;
  foo ??= 2;
// [diag.deadCode][column 11][length 93] Dead code.
//        ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
  foo++;
  --foo;
  p.foo;
  p.foo = 0;
  p.foo += 1;
  p.foo ??= 2;
//          ^
// [diag.deadNullAwareExpression] The left operand can't be null, so the right operand is never executed.
  p.foo++;
  --p.foo;
}
''');

    var variable = result.findElement.topVar('foo');

    assertElementsIndexText(
      result,
      {
        'variable': variable,
        'getter': variable.getter!,
        'setter': variable.setter!,
        'num.+': result.resolvedUnit.typeProvider.numElement.getMethod('+')!,
        'num.-': result.resolvedUnit.typeProvider.numElement.getMethod('-')!,
      },
      r'''
import 'test.dart' as p;

int foo = 0;

/// [foo] and [p.foo].
     ^^^ getter IS_REFERENCED_BY
                 ^^^ getter IS_REFERENCED_BY qualified
@foo
 ^^^ getter IS_INVOKED_BY
@p.foo
   ^^^ getter IS_INVOKED_BY qualified
void f() {
  foo;
  ^^^ getter IS_INVOKED_BY
  foo = 0;
  ^^^ setter IS_INVOKED_BY
  foo += 1;
  ^^^ getter IS_INVOKED_BY
  ^^^ setter IS_INVOKED_BY
      ^^ num.+ IS_INVOKED_BY qualified
  foo ??= 2;
  ^^^ getter IS_INVOKED_BY
  ^^^ setter IS_INVOKED_BY
  foo++;
  ^^^ getter IS_INVOKED_BY
  ^^^ setter IS_INVOKED_BY
     ^^ num.+ IS_INVOKED_BY qualified
  --foo;
  ^^ num.- IS_INVOKED_BY qualified
    ^^^ getter IS_INVOKED_BY
    ^^^ setter IS_INVOKED_BY
  p.foo;
    ^^^ getter IS_INVOKED_BY qualified
  p.foo = 0;
    ^^^ setter IS_INVOKED_BY qualified
  p.foo += 1;
    ^^^ getter IS_INVOKED_BY qualified
    ^^^ setter IS_INVOKED_BY qualified
        ^^ num.+ IS_INVOKED_BY qualified
  p.foo ??= 2;
    ^^^ getter IS_INVOKED_BY qualified
    ^^^ setter IS_INVOKED_BY qualified
  p.foo++;
    ^^^ getter IS_INVOKED_BY qualified
    ^^^ setter IS_INVOKED_BY qualified
       ^^ num.+ IS_INVOKED_BY qualified
  --p.foo;
  ^^ num.- IS_INVOKED_BY qualified
      ^^^ getter IS_INVOKED_BY qualified
      ^^^ setter IS_INVOKED_BY qualified
}
Prefixes:
  getter: (unprefixed),p
''',
    );
  }

  test_TypeAliasElement_legacy_reference() async {
    var result = await _indexTestCode('''
typedef void A();
/// [A]
void f(A p) {}
''');

    var element = result.findElement.typeAlias('A');

    assertElementIndexText(result, element, r'''
typedef void A();
/// [A]
     ^ IS_REFERENCED_BY
void f(A p) {}
       ^ IS_REFERENCED_BY
''');
  }

  test_TypeAliasElement_modern_hierarchy_class_extends() async {
    var result = await _indexTestCode('''
class A<T> {}
typedef B = A<int>;
class C extends B {}
''');

    assertElementsIndexText(
      result,
      {
        'class': result.findElement.class_('A'),
        'alias': result.findElement.typeAlias('B'),
      },
      r'''
class A<T> {}
typedef B = A<int>;
            ^ class IS_REFERENCED_BY
class C extends B {}
                ^ alias IS_EXTENDED_BY
                ^ alias IS_REFERENCED_BY
''',
    );
  }

  test_TypeAliasElement_modern_hierarchy_class_implements() async {
    var result = await _indexTestCode('''
class A<T> {}
typedef B = A<int>;
class C implements B {}
''');

    assertElementsIndexText(
      result,
      {
        'class': result.findElement.class_('A'),
        'alias': result.findElement.typeAlias('B'),
      },
      r'''
class A<T> {}
typedef B = A<int>;
            ^ class IS_REFERENCED_BY
class C implements B {}
                   ^ alias IS_IMPLEMENTED_BY
                   ^ alias IS_REFERENCED_BY
''',
    );
  }

  test_TypeAliasElement_modern_hierarchy_class_with() async {
    var result = await _indexTestCode('''
class A<T> {}
typedef B = A<int>;
class C extends Object with B {}
//                          ^
// [diag.classUsedAsMixin] The class 'A' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');

    assertElementsIndexText(
      result,
      {
        'class': result.findElement.class_('A'),
        'alias': result.findElement.typeAlias('B'),
      },
      r'''
class A<T> {}
typedef B = A<int>;
            ^ class IS_REFERENCED_BY
class C extends Object with B {}
                            ^ alias IS_MIXED_IN_BY
                            ^ alias IS_REFERENCED_BY
''',
    );
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
class A<T> {
  static int field = 0;
  static void method() {}
}

typedef B = A<int>;

/// [B]
     ^ IS_REFERENCED_BY
void f(B p) {
       ^ IS_REFERENCED_BY
  B v;
  ^ IS_REFERENCED_BY
  B();
  ^ IS_REFERENCED_BY
  B.field;
  ^ IS_REFERENCED_BY
  B.field = 0;
  ^ IS_REFERENCED_BY
  B.method();
  ^ IS_REFERENCED_BY
}
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
import 'test.dart' as p;

class A<T> {}
typedef B = A<int>;

/// [B] and [p.B].
     ^ IS_REFERENCED_BY
               ^ IS_REFERENCED_BY qualified
void f() {}
Prefixes: (unprefixed),p
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
    assertNamesIndexText(
      result,
      {'bbb'},
      r'''
library aaa.bbb.ccc;
class C {
  var bbb;
}
void f(p) {
  p.bbb = 1;
    ^^^ IS_WRITTEN_BY qualified
}
''',
    );
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
    assertElementsIndexText(
      result,
      {
        'getter': result.findElement.field('x').getter!,
        'setter': result.findElement.field('x').setter!,
      },
      r'''
class C {
  var x;
}
void f(C c) {
  c.x; // 1
    ^ getter IS_INVOKED_BY qualified
  c.x = 1;
    ^ setter IS_INVOKED_BY qualified
  c.x += 2;
    ^ getter IS_INVOKED_BY qualified
    ^ setter IS_INVOKED_BY qualified
  c.x();
    ^ getter IS_INVOKED_BY qualified
}
''',
    );
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
    assertNamesIndexText(
      result,
      {'x', '+'},
      r'''
void f(p) {
  p.x;
    ^ x IS_READ_BY qualified
  p.x = 1;
    ^ x IS_WRITTEN_BY qualified
  p.x += 2;
    ^ x IS_READ_WRITTEN_BY qualified
  p.x();
    ^ x IS_INVOKED_BY qualified
}
''',
    );
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
    assertElementsIndexText(
      result,
      {
        'getter': result.findElement.field('x').getter!,
        'setter': result.findElement.field('x').setter!,
      },
      r'''
class C {
  var x;
  m() {
    x; // 1
    ^ getter IS_INVOKED_BY
    x = 1;
    ^ setter IS_INVOKED_BY
    x += 2;
    ^ getter IS_INVOKED_BY
    ^ setter IS_INVOKED_BY
    x();
    ^ getter IS_INVOKED_BY
  }
}
''',
    );
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
    assertNamesIndexText(
      result,
      {'x', '+'},
      r'''
void f() {
  x;
  ^ x IS_READ_BY
  x = 1;
  ^ x IS_WRITTEN_BY
  x += 2;
  ^ x IS_READ_WRITTEN_BY
  x();
  ^ x IS_INVOKED_BY
}
''',
    );
  }

  void _assertIndexText(
    _IndexResult result, {
    Map<String, Element> elements = const {},
    Set<String> names = const {},
    required String expected,
  }) {
    var actual = _IndexTextBuilder(
      result,
    ).indexText(elements: elements, names: names);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      if (NodeTextExpectationsCollector.shouldPrintFailureDetails) {
        printPrettyDiff(expected, actual);
      }
      fail('See the difference above.');
    }
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

final class _IndexAnnotation {
  final int offset;
  final int length;
  final int? labelOrder;
  final String text;

  _IndexAnnotation({
    required this.offset,
    required this.length,
    this.labelOrder,
    required this.text,
  });
}

final class _IndexElementToPrint {
  final Element element;
  final String? label;
  final int? order;

  _IndexElementToPrint({required this.element, this.label, this.order});
}

final class _IndexResult {
  final TestResolvedUnitResult resolvedUnit;
  final AnalysisDriverUnitIndex index;

  _IndexResult(this.resolvedUnit, this.index);

  FindElement get findElement => resolvedUnit.findElement;
}

final class _IndexTextBuilder {
  final _IndexResult result;

  final Map<int, Element> _elementById = {};

  _IndexTextBuilder(this.result);

  String indexText({
    required Map<String, Element> elements,
    required Set<String> names,
  }) {
    var index = result.index;
    var annotations = <_IndexAnnotation>[];
    var elementsWithPrefixes = <int, _IndexElementToPrint>{};

    var elementLabels = <int, ({String text, int order})>{};
    var nextLabelOrder = 0;
    for (var entry in elements.entries) {
      if (_findElementId(entry.value) case var elementId?) {
        if (elementLabels.containsKey(elementId)) {
          fail('The index element $elementId has more than one label.');
        }
        elementLabels[elementId] = (text: entry.key, order: nextLabelOrder++);
      }
    }

    expect(index.usedElements.length, index.usedElementKinds.length);
    expect(index.usedElements.length, index.usedElementOffsets.length);
    expect(index.usedElements.length, index.usedElementLengths.length);
    expect(index.usedElements.length, index.usedElementIsQualifiedFlags.length);
    expect(index.elementUnits.length, index.elementImportPrefixes.length);

    for (var i = 0; i < index.usedElements.length; i++) {
      var elementId = index.usedElements[i];
      var labelInfo = elementLabels[elementId];
      if (labelInfo == null) {
        continue;
      }
      var element = _elementForId(elementId);
      var labelText = labelInfo.text;
      var labelOrder = labelInfo.order;
      var kind = index.usedElementKinds[i];
      var isQualified = index.usedElementIsQualifiedFlags[i];

      annotations.add(
        _IndexAnnotation(
          offset: index.usedElementOffsets[i],
          length: index.usedElementLengths[i],
          labelOrder: labelOrder,
          text: [
            if (labelText.isNotEmpty) labelText,
            _relationText(kind, isQualified),
          ].join(' '),
        ),
      );
      if (index.elementImportPrefixes[elementId].isNotEmpty) {
        elementsWithPrefixes[elementId] = _IndexElementToPrint(
          element: element,
          label: labelText,
          order: labelOrder,
        );
      }
    }

    expect(index.usedNames.length, index.usedNameKinds.length);
    expect(index.usedNames.length, index.usedNameOffsets.length);
    expect(index.usedNames.length, index.usedNameIsQualifiedFlags.length);

    for (var i = 0; i < index.usedNames.length; i++) {
      var name = index.strings[index.usedNames[i]];
      if (!names.contains(name)) {
        continue;
      }
      var kind = index.usedNameKinds[i];
      var isQualified = index.usedNameIsQualifiedFlags[i];

      annotations.add(
        _IndexAnnotation(
          offset: index.usedNameOffsets[i],
          length: name.length,
          text: [
            if (names.length > 1) name,
            _relationText(kind, isQualified),
          ].join(' '),
        ),
      );
    }

    annotations.sort((first, second) {
      var result = first.offset.compareTo(second.offset);
      if (result != 0) return result;
      result = first.length.compareTo(second.length);
      if (result != 0) return result;
      result = switch ((first.labelOrder, second.labelOrder)) {
        (var first?, var second?) => first.compareTo(second),
        _ => 0,
      };
      if (result != 0) return result;
      return first.text.compareTo(second.text);
    });

    for (var i = 1; i < annotations.length; i++) {
      var previous = annotations[i - 1];
      var current = annotations[i];
      if (previous.offset == current.offset &&
          previous.length == current.length &&
          previous.text == current.text) {
        fail('Duplicate relation at ${current.offset}: ${current.text}');
      }
    }

    var annotationsByLine = annotations.groupListsBy((annotation) {
      return result.resolvedUnit.unit.lineInfo
          .getLocation(annotation.offset)
          .lineNumber;
    });

    var buffer = StringBuffer();
    var lines = result.resolvedUnit.content.split('\n');
    if (lines.isNotEmpty && lines.last.isEmpty) {
      lines.removeLast();
    }
    for (var i = 0; i < lines.length; i++) {
      buffer.writeln(lines[i]);
      for (var annotation
          in annotationsByLine[i + 1] ?? const <_IndexAnnotation>[]) {
        var location = result.resolvedUnit.unit.lineInfo.getLocation(
          annotation.offset,
        );
        buffer.write(' ' * (location.columnNumber - 1));
        if (annotation.length == 0) {
          buffer.write('^0');
        } else {
          buffer.write('^' * annotation.length);
        }
        buffer.write(' ${annotation.text}');
        buffer.writeln();
      }
    }

    if (elementsWithPrefixes.isNotEmpty) {
      var entries = elementsWithPrefixes.entries.sorted((first, second) {
        var firstOrder = first.value.order;
        var secondOrder = second.value.order;
        if (firstOrder != null && secondOrder != null) {
          return firstOrder.compareTo(secondOrder);
        }
        return _elementText(
          first.value.element,
        ).compareTo(_elementText(second.value.element));
      });

      String prefixesFor(int elementId) {
        return index.elementImportPrefixes[elementId]
            .split(',')
            .map((prefix) => prefix.isEmpty ? '(unprefixed)' : prefix)
            .join(',');
      }

      if (entries case [var entry] when entry.value.label == '') {
        buffer.writeln('Prefixes: ${prefixesFor(entry.key)}');
        return buffer.toString();
      }

      buffer.writeln('Prefixes:');
      for (var entry in entries) {
        var prefixes = prefixesFor(entry.key);
        var element = entry.value;
        var target = element.label ?? _elementText(element.element);
        buffer.writeln('  $target: $prefixes');
      }
    }

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

  Element _computeElementForId(int elementId) {
    var index = result.index;
    var unitId = index.elementUnits[elementId];
    var libraryPath = index.strings[index.unitLibraryPaths[unitId]];
    var unitPath = index.strings[index.unitUnitPaths[unitId]];

    var session = result.resolvedUnit.session as AnalysisSessionImpl;
    var libraryUri = session.uriConverter.pathToUri(libraryPath);
    if (libraryUri == null) {
      fail('No URI for library path $libraryPath');
    }

    var elementFactory = session.elementFactory;
    var libraryReference = elementFactory.rootReference.libraryIfExists(
      libraryUri,
    );
    if (libraryReference == null) {
      fail('No library reference for $libraryUri');
    }

    var library = elementFactory.elementOfReference3(libraryReference);
    library as LibraryElementImpl;

    var loadLibraryFunction = library.loadLibraryFunction;
    if (_findElementId(loadLibraryFunction) == elementId) {
      return loadLibraryFunction;
    }

    var unit = library.fragments.singleWhere(
      (fragment) => fragment.source.fullName == unitPath,
    );

    Element? found;
    void visit(Fragment fragment) {
      var element = fragment.element;
      if (_findElementId(element) == elementId) {
        if (found != null && !identical(found, element)) {
          fail('Multiple elements for index id $elementId: $found, $element');
        }
        found = element;
      }
      for (var child in fragment.children) {
        visit(child);
      }
    }

    visit(unit);
    return found ?? (throw StateError('No element for index id $elementId'));
  }

  Element _elementForId(int elementId) {
    return _elementById[elementId] ??= _computeElementForId(elementId);
  }

  String _elementText(Element element) {
    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '');
    var elementPrinter = ElementPrinter(
      sink: sink,
      configuration: ElementPrinterConfiguration(),
    );
    elementPrinter.writeElement2(element);
    return buffer.toString().trimRight();
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

  static String _relationText(IndexRelationKind kind, bool isQualified) {
    return '${kind.name}${isQualified ? ' qualified' : ''}';
  }
}
