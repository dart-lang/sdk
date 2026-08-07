// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/index.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/test_utilities/find_element2.dart';
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
  void assertIndexText(
    _IndexResult result, {
    required Set<String> names,
    required String expected,
  }) {
    if (names.isEmpty) {
      throw ArgumentError.value(names, 'names', 'Must not be empty');
    }

    var actual = _IndexTextBuilder(result).indexText(names);
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

    assertIndexText(
      result,
      names: {'myDiagnosticCode'},
      expected: r'''
void f() {
  '// [diag.myDiagnosticCode] message';
            ^^^^^^^^^^^^^^^^ IS_REFERENCED_BY qualified package:analyzer/src/diagnostic/diagnostic.dart::@topLevelVariable::myDiagnosticCode
}
''',
    );
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

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

class A {}

class B extends A {}
                ^ IS_EXTENDED_BY <testLibrary>::@class::A
                ^ IS_REFERENCED_BY <testLibrary>::@class::A
class B_q extends p.A {}
                    ^ IS_EXTENDED_BY qualified <testLibrary>::@class::A
                    ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A
Prefixes:
  <testLibrary>::@class::A: (unprefixed),p
''',
    );
  }

  test_ClassElement_hierarchy_class_extends_implicitObject() async {
    var result = await _indexTestCode('''
class A {}
''');

    assertIndexText(
      result,
      names: {'Object'},
      expected: r'''
class A {}
      ^ IS_EXTENDED_BY qualified dart:core::@class::Object
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

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

class A {}

class B implements A {}
                   ^ IS_IMPLEMENTED_BY <testLibrary>::@class::A
                   ^ IS_REFERENCED_BY <testLibrary>::@class::A
class B_q implements p.A {}
                       ^ IS_IMPLEMENTED_BY qualified <testLibrary>::@class::A
                       ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A
Prefixes:
  <testLibrary>::@class::A: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

class A {}

class D extends Object with A {}
                            ^ IS_MIXED_IN_BY <testLibrary>::@class::A
                            ^ IS_REFERENCED_BY <testLibrary>::@class::A
class D_q extends Object with p.A {}
                                ^ IS_MIXED_IN_BY qualified <testLibrary>::@class::A
                                ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A
Prefixes:
  <testLibrary>::@class::A: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

class A {}

class D2 = Object with A;
                       ^ IS_MIXED_IN_BY <testLibrary>::@class::A
                       ^ IS_REFERENCED_BY <testLibrary>::@class::A
class D2_q = Object with p.A;
                           ^ IS_MIXED_IN_BY qualified <testLibrary>::@class::A
                           ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A
Prefixes:
  <testLibrary>::@class::A: (unprefixed),p
''',
    );
  }

  test_ClassElement_hierarchy_enum_implements() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {}

enum E implements A { v }
enum E_q implements p.A { v }
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

class A {}

enum E implements A { v }
                  ^ IS_IMPLEMENTED_BY <testLibrary>::@class::A
                  ^ IS_REFERENCED_BY <testLibrary>::@class::A
enum E_q implements p.A { v }
                      ^ IS_IMPLEMENTED_BY qualified <testLibrary>::@class::A
                      ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A
Prefixes:
  <testLibrary>::@class::A: (unprefixed),p
''',
    );
  }

  test_ClassElement_hierarchy_extensionType_implements() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {}

extension type E(A it) implements A {}
extension type E_q(A it) implements p.A {}
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

class A {}

extension type E(A it) implements A {}
                 ^ IS_REFERENCED_BY <testLibrary>::@class::A
                                  ^ IS_IMPLEMENTED_BY <testLibrary>::@class::A
                                  ^ IS_REFERENCED_BY <testLibrary>::@class::A
extension type E_q(A it) implements p.A {}
                   ^ IS_REFERENCED_BY <testLibrary>::@class::A
                                      ^ IS_IMPLEMENTED_BY qualified <testLibrary>::@class::A
                                      ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A
Prefixes:
  <testLibrary>::@class::A: (unprefixed),p
''',
    );
  }

  test_ClassElement_hierarchy_mixin_implements() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {}

mixin M implements A {}
mixin M_q implements p.A {}
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

class A {}

mixin M implements A {}
                   ^ IS_IMPLEMENTED_BY <testLibrary>::@class::A
                   ^ IS_REFERENCED_BY <testLibrary>::@class::A
mixin M_q implements p.A {}
                       ^ IS_IMPLEMENTED_BY qualified <testLibrary>::@class::A
                       ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A
Prefixes:
  <testLibrary>::@class::A: (unprefixed),p
''',
    );
  }

  test_ClassElement_hierarchy_mixin_on() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {}

mixin M2 on A {}
mixin M2_q on p.A {}
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

class A {}

mixin M2 on A {}
            ^ CONSTRAINS <testLibrary>::@class::A
            ^ IS_REFERENCED_BY <testLibrary>::@class::A
mixin M2_q on p.A {}
                ^ CONSTRAINS qualified <testLibrary>::@class::A
                ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A
Prefixes:
  <testLibrary>::@class::A: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

class A {
  const A();
        ^ IS_REFERENCED_BY <testLibrary>::@class::A
  const A.named();
        ^ IS_REFERENCED_BY <testLibrary>::@class::A
  static const int myConstant = 0;
}

@A()
 ^ IS_REFERENCED_BY <testLibrary>::@class::A
@p.A()
   ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A
@A.named()
 ^ IS_REFERENCED_BY <testLibrary>::@class::A
@p.A.named()
   ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A
@A.myConstant
 ^ IS_REFERENCED_BY <testLibrary>::@class::A
@p.A.myConstant
   ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A
void f() {}
Prefixes:
  <testLibrary>::@class::A: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'B'},
      expected: r'''
import 'test.dart' as p;

class A<T> {
  const A.named();
}

class B {}

@A<B>.named()
   ^ IS_REFERENCED_BY <testLibrary>::@class::B
@p.A<B>.named()
     ^ IS_REFERENCED_BY <testLibrary>::@class::B
void f() {}
''',
    );
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

    assertIndexText(
      result,
      names: {'B'},
      expected: r'''
class A<T> {
  const A();
}

class B {}

@A<B>()
   ^ IS_REFERENCED_BY <testLibrary>::@class::B
void f() {}
''',
    );
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

    assertIndexText(
      result,
      names: {'B'},
      expected: r'''
class A {}
class B = Object with A;
void f(B p) {
       ^ IS_REFERENCED_BY <testLibrary>::@class::B
  B v;
  ^ IS_REFERENCED_BY <testLibrary>::@class::B
}
''',
    );
  }

  test_ClassElement_reference_comment() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {}

/// [A] and [p.A].
void f() {}
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

class A {}

/// [A] and [p.A].
     ^ IS_REFERENCED_BY <testLibrary>::@class::A
               ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A
void f() {}
Prefixes:
  <testLibrary>::@class::A: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'Random'},
      expected: r'''
import 'dart:math';
Random v1;
^^^^^^ IS_REFERENCED_BY dart:math::@class::Random
Random v2;
^^^^^^ IS_REFERENCED_BY dart:math::@class::Random
''',
    );
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

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'lib.dart';

void f(A p) {
       ^ IS_REFERENCED_BY package:test/lib.dart::@class::A
  A v = p;
  ^ IS_REFERENCED_BY package:test/lib.dart::@class::A
}
''',
    );
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

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

class A {}

void f() {
  A();
  ^ IS_REFERENCED_BY <testLibrary>::@class::A
  p.A();
    ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A
}
Prefixes:
  <testLibrary>::@class::A: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

class A {
  static void foo() {}
}

void f() {
  A.foo();
  ^ IS_REFERENCED_BY <testLibrary>::@class::A
  p.A.foo();
    ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A
}
Prefixes:
  <testLibrary>::@class::A: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

class A {}

void f() {
  A v1;
  ^ IS_REFERENCED_BY <testLibrary>::@class::A
  p.A v2;
    ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A
  List<A> v3;
       ^ IS_REFERENCED_BY <testLibrary>::@class::A
  List<p.A> v4;
         ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A
}
Prefixes:
  <testLibrary>::@class::A: (unprefixed),p
''',
    );
  }

  test_ClassElement_reference_recordTypeAnnotation_named() async {
    var result = await _indexTestCode(r'''
class A {}

void f(({int foo, A bar}) r) {}
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
class A {}

void f(({int foo, A bar}) r) {}
                  ^ IS_REFERENCED_BY <testLibrary>::@class::A
''',
    );
  }

  test_ClassElement_reference_recordTypeAnnotation_positional() async {
    var result = await _indexTestCode(r'''
class A {}

void f((int, A) r) {}
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
class A {}

void f((int, A) r) {}
             ^ IS_REFERENCED_BY <testLibrary>::@class::A
''',
    );
  }

  test_ClassElement_reference_typeLiteral() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A {}

var v = A;
var v_p = p.A;
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

class A {}

var v = A;
        ^ IS_REFERENCED_BY <testLibrary>::@class::A
var v_p = p.A;
            ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A
Prefixes:
  <testLibrary>::@class::A: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'named', 'new'},
      expected: r'''
import 'test.dart' as p;

class A {
  const A();
        ^ IS_INVOKED_BY qualified dart:core::@class::Object::@constructor::new
  const A.named();
        ^^^^^^^ IS_INVOKED_BY qualified dart:core::@class::Object::@constructor::new
}

@A()
  ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
@p.A()
    ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
@A.named()
  ^^^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::named
@p.A.named()
    ^^^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::named
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
class A {
  A.foo() {
    foo();
    ^^^ IS_INVOKED_BY <testLibrary>::@class::A::@method::foo
  }

  A foo() => A.foo();
              ^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [new A.foo] and [A.foo]
          ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::foo
                      ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::foo
class A {
  new foo() {}
  new bar() : this.foo();
                  ^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::foo
  factory baz() = A.foo;
                   ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::foo
}
class B extends A {
  new () : super.foo();
                ^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::foo
}
void useConstructor() {
  A.foo();
   ^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::foo
  A.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@class::A::@constructor::foo
  A a = .foo();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@class::A::@constructor::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [new A.foo] and [A.foo]
          ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::foo
                      ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::foo
class A.foo() {
  new bar() : this.foo();
                  ^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::foo
  factory baz() = A.foo;
                   ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::foo
}
class B() extends A {
  this : super.foo();
              ^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::foo
}
void useConstructor() {
  A.foo();
   ^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::foo
  A.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@class::A::@constructor::foo
  A a = .foo();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@class::A::@constructor::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [new A.foo] and [A.foo]
          ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::foo
                      ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::foo
class A {
  A.foo() {}
  A.bar() : this.foo();
                ^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::foo
  factory A.baz() = A.foo;
                     ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::foo
}
class B extends A {
  B() : super.foo();
             ^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::foo
}
void useConstructor() {
  A.foo();
   ^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::foo
  A.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@class::A::@constructor::foo
  A a = .foo();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@class::A::@constructor::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [new B.foo] and [B.foo]
          ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::foo
                      ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::foo
class A<T> {
  A.foo() {}
  A.bar() : this.foo();
                ^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::foo
  factory A.baz() = A.foo;
                     ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::foo
}
typedef B = A<int>;
class C extends B {
  C() : super.foo();
             ^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::foo
}
void useConstructor() {
  B.foo();
   ^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::foo
  B.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@class::A::@constructor::foo
  B b = .foo();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@class::A::@constructor::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'new'},
      expected: r'''
/// [new A] and [A.new]
          ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new
                  ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new
class B {
  B();
  ^ IS_INVOKED_BY qualified dart:core::@class::Object::@constructor::new
  factory B.baz() = A;
                     ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new
}
class A extends B {}
      ^ IS_INVOKED_BY qualified <testLibrary>::@class::B::@constructor::new
class C extends A {
  C() : super();
             ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
}
void useConstructor() {
  A();
   ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
  A.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@class::A::@constructor::new
  A a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@class::A::@constructor::new
}
''',
    );
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

    assertIndexText(
      result,
      names: {'new'},
      expected: r'''
class A {
  A();
  ^ IS_INVOKED_BY qualified dart:core::@class::Object::@constructor::new
}

class B extends A {
  new ();
  ^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
  new bar();
  ^^^^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
  factory new.baz() = A;
          ^^^ IS_READ_BY name: new
                       ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new
}
''',
    );
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

    assertIndexText(
      result,
      names: {'new'},
      expected: r'''
class A {
  A();
  ^ IS_INVOKED_BY qualified dart:core::@class::Object::@constructor::new
}

class B extends A {
  B();
  ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
  B.bar();
  ^^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
  factory B.baz() = A;
                     ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new
}

class C extends A {}
      ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
''',
    );
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

    assertIndexText(
      result,
      names: {'new'},
      expected: r'''
/// [new A] and [A.new]
          ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new
                  ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new
class A {
  new () {}
  ^^^ IS_INVOKED_BY qualified dart:core::@class::Object::@constructor::new
  new bar() : this();
                  ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
  factory baz() = A;
                   ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new
}
class B extends A {
  new () : super();
                ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
}
void useConstructor() {
  A();
   ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
  A.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@class::A::@constructor::new
  A a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@class::A::@constructor::new
}
''',
    );
  }

  test_ConstructorElement_class_unnamed_otherFile() async {
    var otherFile = getFile('$testPackageLibPath/other.dart');

    await resolveTestCodeWithDiagnostics('''
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

    assertIndexText(
      result,
      names: {'new'},
      expected: r'''
import 'test.dart';

void f() {
  A();
   ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
}
''',
    );
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

    assertIndexText(
      result,
      names: {'new'},
      expected: r'''
/// [new A] and [A.new]
          ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new
                  ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new
class A() {
  new bar() : this();
                  ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
  factory baz() = A;
                   ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new
}
class B() extends A {
  this : super();
              ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
}
void useConstructor() {
  A();
   ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
  A.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@class::A::@constructor::new
  A a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@class::A::@constructor::new
}
''',
    );
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

    assertIndexText(
      result,
      names: {'new'},
      expected: r'''
/// [new A] and [A.new]
          ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new
                  ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new
class A {
  A() {}
  ^ IS_INVOKED_BY qualified dart:core::@class::Object::@constructor::new
  A.bar() : this();
                ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
  factory A.baz() = A;
                     ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new
}
class B extends A {
  B() : super();
             ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
}
void useConstructor() {
  A();
   ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
  A.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@class::A::@constructor::new
  A a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@class::A::@constructor::new
}
''',
    );
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

    assertIndexText(
      result,
      names: {'new'},
      expected: r'''
/// [new A] and [A.new]
          ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new
                  ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new
class A {
  A.new() {}
  ^^^^^ IS_INVOKED_BY qualified dart:core::@class::Object::@constructor::new
  A.bar() : this.new();
                ^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
  factory A.baz() = A.new;
                     ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new
}
class B extends A {
  B() : super.new();
             ^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
}
void useConstructor() {
  A.new();
   ^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
  A.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@class::A::@constructor::new
  A a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@class::A::@constructor::new
}
''',
    );
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

    assertIndexText(
      result,
      names: {'named', 'new'},
      expected: r'''
class M {}
      ^ IS_INVOKED_BY qualified dart:core::@class::Object::@constructor::new
class A {
  A() {}
  ^ IS_INVOKED_BY qualified dart:core::@class::Object::@constructor::new
  A.named() {}
  ^^^^^^^ IS_INVOKED_BY qualified dart:core::@class::Object::@constructor::new
}
class B = A with M;
class C = B with M;
void useConstructor() {
  B();
   ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
  B.named();
   ^^^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::named
  C();
   ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::new
  C.named();
   ^^^^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@constructor::named
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

    assertIndexText(
      result,
      names: {'named', 'new'},
      expected: r'''
import 'test.dart' as p;

enum E {
  v;
   ^ IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified <testLibrary>::@enum::E::@constructor::new
  const E();
        ^ IS_INVOKED_BY qualified dart:core::@class::Enum::@constructor::new
  const E.named();
        ^^^^^^^ IS_INVOKED_BY qualified dart:core::@class::Enum::@constructor::new
}

@E()
  ^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::new
@p.E()
    ^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::new
@E.named()
  ^^^^^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::named
@p.E.named()
    ^^^^^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::named
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [new E.foo] and [E.foo]
          ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::foo
                      ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::foo
enum E {
  v.foo();
   ^^^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::foo
  const new foo();
  const new bar() : this.foo();
                        ^^^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::foo
  const factory baz() = E.foo;
                         ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::foo
}
void useConstructor() {
  E.foo();
   ^^^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::foo
  E.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@enum::E::@constructor::foo
  E a = .foo();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@enum::E::@constructor::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [new E.foo] and [E.foo]
          ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::foo
                      ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::foo
enum E.foo() {
  v.foo();
   ^^^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::foo
  const new bar() : this.foo();
                        ^^^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::foo
  const factory baz() = E.foo;
                         ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::foo
}
void useConstructor() {
  E.foo();
   ^^^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::foo
  E.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@enum::E::@constructor::foo
  E a = .foo();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@enum::E::@constructor::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [new E.foo] and [E.foo]
          ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::foo
                      ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::foo
enum E {
  v.foo();
   ^^^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::foo
  const E.foo();
  const E.bar() : this.foo();
                      ^^^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::foo
  const factory E.baz() = E.foo;
                           ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::foo
}
void useConstructor() {
  E.foo();
   ^^^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::foo
  E.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@enum::E::@constructor::foo
  E a = .foo();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@enum::E::@constructor::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'new'},
      expected: r'''
/// [new E] and [E.new]
          ^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::new
                  ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::new
enum E {
  v1,
    ^ IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified <testLibrary>::@enum::E::@constructor::new
  v2(),
    ^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::new
  v3.new();
    ^^^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::new
  const factory E.other() = E;
                             ^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::new
}
void useConstructor() {
  E();
   ^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::new
  E.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@enum::E::@constructor::new
  E a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@enum::E::@constructor::new
}
''',
    );
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

    assertIndexText(
      result,
      names: {'new'},
      expected: r'''
/// [new E] and [E.new]
          ^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::new
                  ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::new
enum E {
  v1,
    ^ IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified <testLibrary>::@enum::E::@constructor::new
  v2(),
    ^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::new
  v3.new();
    ^^^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::new
  const new ();
        ^^^ IS_INVOKED_BY qualified dart:core::@class::Enum::@constructor::new
  const factory other() = E.new;
                           ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::new
}
void useConstructor() {
  E();
   ^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::new
  E.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@enum::E::@constructor::new
  E a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@enum::E::@constructor::new
}
''',
    );
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

    assertIndexText(
      result,
      names: {'new'},
      expected: r'''
/// [new E] and [E.new]
          ^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::new
                  ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::new
enum E() {
  v1,
    ^ IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified <testLibrary>::@enum::E::@constructor::new
  v2(),
    ^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::new
  v3.new();
    ^^^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::new
  const factory other() = E.new;
                           ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::new
}
void useConstructor() {
  E();
   ^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::new
  E.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@enum::E::@constructor::new
  E a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@enum::E::@constructor::new
}
''',
    );
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

    assertIndexText(
      result,
      names: {'new'},
      expected: r'''
/// [new E] and [E.new]
          ^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::new
                  ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::new
enum E {
  v1,
    ^ IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified <testLibrary>::@enum::E::@constructor::new
  v2(),
    ^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::new
  v3.new();
    ^^^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::new
  const E();
        ^ IS_INVOKED_BY qualified dart:core::@class::Enum::@constructor::new
  const factory E.other() = E;
                             ^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::new
}
void useConstructor() {
  E();
   ^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::new
  E.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@enum::E::@constructor::new
  E a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@enum::E::@constructor::new
}
''',
    );
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

    assertIndexText(
      result,
      names: {'new'},
      expected: r'''
/// [new E] and [E.new]
          ^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::new
                  ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::new
enum E {
  v1,
    ^ IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS qualified <testLibrary>::@enum::E::@constructor::new
  v2(),
    ^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::new
  v3.new();
    ^^^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::new
  const E.new();
        ^^^^^ IS_INVOKED_BY qualified dart:core::@class::Enum::@constructor::new
  const factory E.other() = E.new;
                             ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@constructor::new
}
void useConstructor() {
  E();
   ^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@constructor::new
  E.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@enum::E::@constructor::new
  E a = .new();
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@enum::E::@constructor::new
}
''',
    );
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

    assertIndexText(
      result,
      names: {'named', 'new'},
      expected: r'''
import 'test.dart' as p;

extension type const A(int it) {
  const A.named(int it) : this(it);
                              ^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
}

@A(0)
  ^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
@p.A(0)
    ^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
@A.named(0)
  ^^^^^^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@constructor::named
@p.A.named(0)
    ^^^^^^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@constructor::named
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [new A.foo] and [A.foo]
          ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::foo
                      ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::foo
extension type A(int it) {
  new foo(this.it);
  new bar() : this.foo(0);
                  ^^^^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@constructor::foo
  factory baz(int it) = A.foo;
                         ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::foo
}
void useConstructor() {
  A.foo(0);
   ^^^^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@constructor::foo
  A.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@extensionType::A::@constructor::foo
  A a = .foo(0);
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@extensionType::A::@constructor::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [new A.foo] and [A.foo]
          ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::foo
                      ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::foo
extension type A.foo(int it) {
  new bar() : this.foo(0);
                  ^^^^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@constructor::foo
  factory baz(int it) = A.foo;
                         ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::foo
}
void useConstructor() {
  A.foo(0);
   ^^^^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@constructor::foo
  A.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@extensionType::A::@constructor::foo
  A a = .foo(0);
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@extensionType::A::@constructor::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [new A.foo] and [A.foo]
          ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::foo
                      ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::foo
extension type A(int it) {
  A.foo(this.it);
  A.bar() : this.foo(0);
                ^^^^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@constructor::foo
  factory A.baz(int it) = A.foo;
                           ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::foo
}
void useConstructor() {
  A.foo(0);
   ^^^^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@constructor::foo
  A.foo;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@extensionType::A::@constructor::foo
  A a = .foo(0);
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@extensionType::A::@constructor::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'new'},
      expected: r'''
/// [new A] and [A.new]
          ^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
                  ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
extension type A.named(int it) {
  new (this.it);
  new bar() : this(0);
                  ^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
  factory baz(int it) = A.new;
                         ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
}
void useConstructor() {
  A(0);
   ^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
  A.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@extensionType::A::@constructor::new
  A a = .new(0);
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@extensionType::A::@constructor::new
}
''',
    );
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

    assertIndexText(
      result,
      names: {'new'},
      expected: r'''
/// [new A] and [A.new]
          ^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
                  ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
extension type A(int it) {
  new bar() : this(0);
                  ^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
  factory baz(int it) = A.new;
                         ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
}
void useConstructor() {
  A(0);
   ^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
  A.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@extensionType::A::@constructor::new
  A a = .new(0);
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@extensionType::A::@constructor::new
}
''',
    );
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

    assertIndexText(
      result,
      names: {'new'},
      expected: r'''
/// [new A] and [A.new]
          ^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
                  ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
extension type A.named(int it) {
  A(this.it);
  A.bar() : this(0);
                ^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
  factory A.baz(int it) = A.new;
                           ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
}
void useConstructor() {
  A(0);
   ^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
  A.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@extensionType::A::@constructor::new
  A a = .new(0);
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@extensionType::A::@constructor::new
}
''',
    );
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

    assertIndexText(
      result,
      names: {'new'},
      expected: r'''
/// [new A] and [A.new]
          ^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
                  ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
extension type A.named(int it) {
  A.new(this.it);
  A.bar() : this.new(0);
                ^^^^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
  factory A.baz(int it) = A.new;
                           ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
}
void useConstructor() {
  A.new(0);
   ^^^^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@constructor::new
  A.new;
   ^^^^ IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF qualified <testLibrary>::@extensionType::A::@constructor::new
  A a = .new(0);
         ^^^ IS_INVOKED_BY_DOT_SHORTHANDS_CONSTRUCTOR qualified <testLibrary>::@extensionType::A::@constructor::new
}
''',
    );
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

    assertIndexText(
      result,
      names: {'E'},
      expected: r'''
import 'test.dart' as p;

enum E {
  v;
  const E();
        ^ IS_REFERENCED_BY <testLibrary>::@enum::E
  const E.named();
        ^ IS_REFERENCED_BY <testLibrary>::@enum::E
  static const int myConstant = 0;
}

@E()
 ^ IS_REFERENCED_BY <testLibrary>::@enum::E
@p.E()
   ^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E
@E.named()
 ^ IS_REFERENCED_BY <testLibrary>::@enum::E
@p.E.named()
   ^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E
@E.myConstant
 ^ IS_REFERENCED_BY <testLibrary>::@enum::E
@p.E.myConstant
   ^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E
void f() {}
Prefixes:
  <testLibrary>::@enum::E: (unprefixed),p
''',
    );
  }

  test_EnumElement_reference_comment() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

enum E { v }

/// [E] and [p.E].
void f() {}
''');

    assertIndexText(
      result,
      names: {'E'},
      expected: r'''
import 'test.dart' as p;

enum E { v }

/// [E] and [p.E].
     ^ IS_REFERENCED_BY <testLibrary>::@enum::E
               ^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E
void f() {}
Prefixes:
  <testLibrary>::@enum::E: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'E'},
      expected: r'''
import 'test.dart' as p;

enum E {
  v;
  const E();
        ^ IS_REFERENCED_BY <testLibrary>::@enum::E
}

void f() {
  const E();
        ^ IS_REFERENCED_BY <testLibrary>::@enum::E
  const p.E();
          ^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E
}
Prefixes:
  <testLibrary>::@enum::E: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'E'},
      expected: r'''
import 'test.dart' as p;

enum E {
  v;
  static void foo() {}
}

void f() {
  E.foo();
  ^ IS_REFERENCED_BY <testLibrary>::@enum::E
  p.E.foo();
    ^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E
}
Prefixes:
  <testLibrary>::@enum::E: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'E'},
      expected: r'''
import 'test.dart' as p;

enum E { v }

void f() {
  E v1;
  ^ IS_REFERENCED_BY <testLibrary>::@enum::E
  p.E v2;
    ^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E
}
Prefixes:
  <testLibrary>::@enum::E: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'E'},
      expected: r'''
import 'test.dart' as p;

extension E on int {
  static void foo() {}
}

void f() {
  E.foo();
  ^ IS_REFERENCED_BY <testLibrary>::@extension::E
  p.E.foo();
    ^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E
}
Prefixes:
  <testLibrary>::@extension::E: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'E'},
      expected: r'''
import 'test.dart' as p;

extension E on int {
  void foo() {}
}

void f() {
  E(0).foo();
  ^ IS_REFERENCED_BY <testLibrary>::@extension::E
  p.E(0).foo();
    ^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E
}
Prefixes:
  <testLibrary>::@extension::E: (unprefixed),p
''',
    );
  }

  test_ExtensionTypeElement_hierarchy_extensionType_implements() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

extension type A(int it) {}

extension type B(int it) implements A {}
extension type B_q(int it) implements p.A {}
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

extension type A(int it) {}

extension type B(int it) implements A {}
                                    ^ IS_IMPLEMENTED_BY <testLibrary>::@extensionType::A
                                    ^ IS_REFERENCED_BY <testLibrary>::@extensionType::A
extension type B_q(int it) implements p.A {}
                                        ^ IS_IMPLEMENTED_BY qualified <testLibrary>::@extensionType::A
                                        ^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A
Prefixes:
  <testLibrary>::@extensionType::A: (unprefixed),p
''',
    );
  }

  test_ExtensionTypeElement_reference_annotation() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

extension type const A(int it) {}

@A(0)
@p.A(0)
void f() {}
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

extension type const A(int it) {}

@A(0)
 ^ IS_REFERENCED_BY <testLibrary>::@extensionType::A
@p.A(0)
   ^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A
void f() {}
Prefixes:
  <testLibrary>::@extensionType::A: (unprefixed),p
''',
    );
  }

  test_ExtensionTypeElement_reference_comment() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

extension type A(int it) {}

/// [A] and [p.A].
void f() {}
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

extension type A(int it) {}

/// [A] and [p.A].
     ^ IS_REFERENCED_BY <testLibrary>::@extensionType::A
               ^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A
void f() {}
Prefixes:
  <testLibrary>::@extensionType::A: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

extension type A(int it) {}

void f() {
  A(0);
  ^ IS_REFERENCED_BY <testLibrary>::@extensionType::A
  p.A(0);
    ^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A
}
Prefixes:
  <testLibrary>::@extensionType::A: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

extension type A(int it) {
  static void foo() {}
}

void f() {
  A.foo();
  ^ IS_REFERENCED_BY <testLibrary>::@extensionType::A
  p.A.foo();
    ^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A
}
Prefixes:
  <testLibrary>::@extensionType::A: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

extension type A(int it) {}

void f() {
  A v1;
  ^ IS_REFERENCED_BY <testLibrary>::@extensionType::A
  p.A v2;
    ^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A
}
Prefixes:
  <testLibrary>::@extensionType::A: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'foo', '+', '-'},
      expected: r'''
/// [foo] and [A.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@getter::foo
                 ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
class A {
  int foo;
  A({this.foo = 0});
          ^^^ IS_WRITTEN_BY qualified <testLibrary>::@class::A::@field::foo
  A.foo() : foo = 0;
            ^^^ IS_WRITTEN_BY qualified <testLibrary>::@class::A::@field::foo

  void useField() {
    foo;
    ^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@getter::foo
    foo = 0;
    ^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@setter::foo
    foo += 1;
    ^^^ IS_READ_BY <testLibrary>::@class::A::@getter::foo
    ^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@setter::foo
        ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    foo ??= 2;
    ^^^ IS_READ_BY <testLibrary>::@class::A::@getter::foo
    ^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@setter::foo
    foo++;
    ^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@setter::foo
       ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    --foo;
    ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::-
      ^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@setter::foo
    this.foo;
         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
    this.foo = 0;
         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
    this.foo += 1;
         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
             ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    this.foo ??= 2;
         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
    this.foo++;
         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
            ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    --this.foo;
    ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::-
           ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
  }
}

void useField(A a) {
  a.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
  a.foo = 0;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
  a.foo += 1;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
        ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  a.foo ??= 2;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
  a.foo++;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
       ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  --a.foo;
  ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::-
      ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
  A(foo: 0);
    ^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::foo
}

class B extends A {
  void useSuper() {
    super.foo;
          ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
    super.foo = 0;
          ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
    super.foo += 1;
          ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
              ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    super.foo ??= 2;
          ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
    super.foo++;
          ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
             ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    --super.foo;
    ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::-
            ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
class A {
  A() : foo = 0;
        ^^^ IS_WRITTEN_BY qualified <testLibrary>::@class::A::@field::foo
  int get foo => 0;

  void useGetter() {
    foo;
    ^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@getter::foo
    this.foo;
         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
  }
}

void useGetter(A a) {
  a.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
}

class B extends A {
  void useSuper() {
    super.foo;
          ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
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

    assertIndexText(
      result,
      names: {'foo', '+', '-'},
      expected: r'''
/// [foo] and [A.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@getter::foo
                 ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
class A {
  A() : foo = 0;
        ^^^ IS_WRITTEN_BY qualified <testLibrary>::@class::A::@field::foo
  int get foo => 0;
  set foo(int _) {}

  void useField() {
    foo;
    ^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@getter::foo
    foo = 0;
    ^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@setter::foo
    foo += 1;
    ^^^ IS_READ_BY <testLibrary>::@class::A::@getter::foo
    ^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@setter::foo
        ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    foo ??= 2;
    ^^^ IS_READ_BY <testLibrary>::@class::A::@getter::foo
    ^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@setter::foo
    foo++;
    ^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@setter::foo
       ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    --foo;
    ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::-
      ^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@setter::foo
    this.foo;
         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
    this.foo = 0;
         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
    this.foo += 1;
         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
             ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    this.foo ??= 2;
         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
    this.foo++;
         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
            ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    --this.foo;
    ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::-
           ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
  }
}

void useField(A a) {
  a.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
  a.foo = 0;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
  a.foo += 1;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
        ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  a.foo ??= 2;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
  a.foo++;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
       ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  --a.foo;
  ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::-
      ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
}

class B extends A {
  void useSuper() {
    super.foo;
          ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
    super.foo = 0;
          ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
    super.foo += 1;
          ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
              ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    super.foo ??= 2;
          ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
    super.foo++;
          ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
             ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    --super.foo;
    ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::-
            ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
  }
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
class A {
  A() : foo = 0;
        ^^^ IS_WRITTEN_BY qualified <testLibrary>::@class::A::@field::foo
  set foo(int _) {}

  void useSetter() {
    foo = 0;
    ^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@setter::foo
    this.foo = 0;
         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
  }
}

void useSetter(A a) {
  a.foo = 0;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
}

class B extends A {
  void useSuper() {
    super.foo = 0;
          ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
  }
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [foo] and [A.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@getter::foo
                 ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
class A {
  static int foo = 0;
  static void useField() {
    foo;
    ^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@getter::foo
    foo = 0;
    ^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@setter::foo
    A.foo;
      ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
    A.foo = 0;
      ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
  }
}

void useField() {
  A.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
  A.foo = 0;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
  A a = .foo;
         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [foo] and [E.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@enum::E::@getter::foo
                 ^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@getter::foo
enum E {
  v;
  int? foo; // a compile-time error
  E({this.foo});
          ^^^ IS_WRITTEN_BY qualified <testLibrary>::@enum::E::@field::foo
  void useField() {
    foo;
    ^^^ IS_REFERENCED_BY <testLibrary>::@enum::E::@getter::foo
    foo = 0;
    ^^^ IS_WRITTEN_BY <testLibrary>::@enum::E::@setter::foo
  }
}
void useField(E e) {
  e.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@getter::foo
  e.foo = 0;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@setter::foo
  E(foo: 0);
    ^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@enum::E::@constructor::new::@formalParameter::foo
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
enum E {
  v;
  E() : foo = 0;
        ^^^ IS_WRITTEN_BY qualified <testLibrary>::@enum::E::@field::foo
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
enum E {
  v;
  E() : foo = 0;
        ^^^ IS_WRITTEN_BY qualified <testLibrary>::@enum::E::@field::foo
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

    assertIndexText(
      result,
      names: {'index'},
      expected: r'''
enum MyEnum {
  v1, v2, v3
}
void f() {
  MyEnum.values;
  MyEnum.v1.index;
            ^^^^^ IS_REFERENCED_BY qualified dart:core::@class::Enum::@getter::index
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
enum E {
  v;
  E() : foo = 0;
        ^^^ IS_WRITTEN_BY qualified <testLibrary>::@enum::E::@field::foo
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

    assertIndexText(
      result,
      names: {'v1', 'v2', 'values'},
      expected: r'''
import 'test.dart' as p;

/// [v1], [MyEnum.v1], and [p.MyEnum.v1]
     ^^ IS_REFERENCED_BY <testLibrary>::@enum::MyEnum::@getter::v1
                  ^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::MyEnum::@getter::v1
                                     ^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::MyEnum::@getter::v1
enum MyEnum {
  v1, v2, v3
}
void f() {
  MyEnum.values;
         ^^^^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::MyEnum::@getter::values
  MyEnum.v1.index;
         ^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::MyEnum::@getter::v1
  MyEnum.v1;
         ^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::MyEnum::@getter::v1
  MyEnum.v2;
         ^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::MyEnum::@getter::v2
  p.MyEnum.v1;
           ^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::MyEnum::@getter::v1
  p.MyEnum.values;
           ^^^^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::MyEnum::@getter::values
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

    assertIndexText(
      result,
      names: {'foo', '+', '-'},
      expected: r'''
extension E on int {
  int get foo => 0;
  set foo(int _) {}
}

void useField(int a) {
  a.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E::@getter::foo
  a.foo = 0;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E::@setter::foo
  a.foo += 1;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E::@setter::foo
        ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  a.foo ??= 2;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E::@setter::foo
  a.foo++;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E::@setter::foo
       ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  --a.foo;
  ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::-
      ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E::@setter::foo
  E(a).foo;
       ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E::@getter::foo
  E(a).foo = 0;
       ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E::@setter::foo
  E(a).foo += 1;
       ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E::@setter::foo
           ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  E(a).foo ??= 2;
       ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E::@setter::foo
  E(a).foo++;
       ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E::@setter::foo
          ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  --E(a).foo;
  ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::-
         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E::@setter::foo
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [foo] and [A.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@extensionType::A::@getter::foo
                 ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@getter::foo
extension type A(int it) {
  static int foo = 0;
  void useField() {
    foo;
    ^^^ IS_REFERENCED_BY <testLibrary>::@extensionType::A::@getter::foo
    foo = 0;
    ^^^ IS_WRITTEN_BY <testLibrary>::@extensionType::A::@setter::foo
  }
}
void useField() {
  A.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@getter::foo
  A.foo = 0;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@setter::foo
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

    assertIndexText(
      result,
      names: {'test'},
      expected: r'''
class A {
  A({this.test}) : assert(test != null);
          ^^^^ IS_WRITTEN_BY qualified <testLibrary>::@class::A::@field::test
                          ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  int? test;
}
void foo() {
  A _ = .new(test: 0);
             ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
class A({int? test}) {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  this : assert(test != null) {
                ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test;
    ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test = 0;
    ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
         ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  }

  A.redirect({int? test}) : this(test: test);
                                 ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
                                       ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::redirect::@formalParameter::test
}

class B extends A {
  B({super.test});
           ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
}

class C extends A {
  C({int? test}) : super(test: test);
                         ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
                               ^^^^ IS_READ_BY <testLibrary>::@class::C::@constructor::new::@formalParameter::test
}

void f() {
  A(test: 0);
    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  A _ = .new(test: 0);
             ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test'},
      expected: r'''
class A<T>({T? test}) {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  this : assert(test != null) {
                ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test;
    ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test = null;
    ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    (test,) = (null,);
     ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    for (test in [null]) {}
         ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  }

  A.redirect({T? test}) : this(test: test);
                               ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
                                     ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::redirect::@formalParameter::test
}

class B<T> extends A<T> {
  B({super.test});
           ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
}

class C<T> extends A<T> {
  C({T? test}) : super(test: test);
                       ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
                             ^^^^ IS_READ_BY <testLibrary>::@class::C::@constructor::new::@formalParameter::test
}

void f() {
  A(test: 0);
    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  A<int> _ = .new(test: 0);
                  ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
class A([int? test]) {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  this : assert(test != null) {
                ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test;
    ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test = 0;
    ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
         ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  }

  A.redirect([int? test]) : this(test);
                                 ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::redirect::@formalParameter::test
}

class B extends A {
  B([super.test]);
           ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
}

class C extends A {
  C([int? test]) : super(test);
                         ^^^^ IS_READ_BY <testLibrary>::@class::C::@constructor::new::@formalParameter::test
}

void f() {
  A(0);
  A _ = .new(0);
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
class A({required int test}) {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  this : assert(test != -1) {
                ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test;
    ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test = 0;
    ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
         ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  }

  A.redirect({required int test}) : this(test: test);
                                         ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
                                               ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::redirect::@formalParameter::test
}

class B extends A {
  B({required super.test});
                    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
}

class C extends A {
  C({required int test}) : super(test: test);
                                 ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
                                       ^^^^ IS_READ_BY <testLibrary>::@class::C::@constructor::new::@formalParameter::test
}

void f() {
  A(test: 0);
    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  A _ = .new(test: 0);
             ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
class A(int test) {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  this : assert(test != -1) {
                ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test;
    ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test = 0;
    ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
         ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  }

  A.redirect(int test) : this(test);
                              ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::redirect::@formalParameter::test
}

class B extends A {
  B(super.test);
          ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
}

class C extends A {
  C(int test) : super(test);
                      ^^^^ IS_READ_BY <testLibrary>::@class::C::@constructor::new::@formalParameter::test
}

void f() {
  A(0);
  A _ = .new(0);
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
class A {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  A({int? test}) : assert(test != null) {
                          ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test;
    ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test = 0;
    ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
         ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  }

  A.redirect({int? test}) : this(test: test);
                                 ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
                                       ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::redirect::@formalParameter::test
}

class B extends A {
  B({super.test});
           ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
}

class C extends A {
  C({int? test}) : super(test: test);
                         ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
                               ^^^^ IS_READ_BY <testLibrary>::@class::C::@constructor::new::@formalParameter::test
}

void f() {
  A(test: 0);
    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  A _ = .new(test: 0);
             ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test'},
      expected: r'''
import 'test.dart' as p;

class A {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  const A({int? test}) : assert(test != null);
                                ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  const A.redirect({int? test}) : this(test: test);
                                       ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
                                             ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::redirect::@formalParameter::test
}

class B extends A {
  const B({super.test});
                 ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
}

class C extends A {
  const C({int? test}) : super(test: test);
                               ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
                                     ^^^^ IS_READ_BY <testLibrary>::@class::C::@constructor::new::@formalParameter::test
}

@A(test: 0)
   ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
@p.A(test: 1)
     ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
void f() {
  const A(test: 2);
          ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  A _ = .new(test: 3);
             ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
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

    assertIndexText(
      result,
      names: {'test'},
      expected: r'''
class A<T> {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  A({T? test}) : assert(test != null) {
                        ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test;
    ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test = null;
    ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    (test,) = (null,);
     ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    for (test in [null]) {}
         ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  }

  A.redirect({T? test}) : this(test: test);
                               ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
                                     ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::redirect::@formalParameter::test
}

class B<T> extends A<T> {
  B({super.test});
           ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
}

class C<T> extends A<T> {
  C({T? test}) : super(test: test);
                       ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
                             ^^^^ IS_READ_BY <testLibrary>::@class::C::@constructor::new::@formalParameter::test
}

void f() {
  A(test: 0);
    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  A<int> _ = .new(test: 0);
                  ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
class A {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  A([int? test]) : assert(test != null) {
                          ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test;
    ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test = 0;
    ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
         ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  }

  A.redirect([int? test]) : this(test);
                                 ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::redirect::@formalParameter::test
}

class B extends A {
  B([super.test]);
           ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
}

class C extends A {
  C([int? test]) : super(test);
                         ^^^^ IS_READ_BY <testLibrary>::@class::C::@constructor::new::@formalParameter::test
}

void f() {
  A(0);
  A _ = .new(0);
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
class A {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  A({required int test}) : assert(test != -1) {
                                  ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test;
    ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test = 0;
    ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
         ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  }

  A.redirect({required int test}) : this(test: test);
                                         ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
                                               ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::redirect::@formalParameter::test
}

class B extends A {
  B({required super.test});
                    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
}

class C extends A {
  C({required int test}) : super(test: test);
                                 ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
                                       ^^^^ IS_READ_BY <testLibrary>::@class::C::@constructor::new::@formalParameter::test
}

void f() {
  A(test: 0);
    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  A _ = .new(test: 0);
             ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
class A {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  A(int test) : assert(test != -1) {
                       ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test;
    ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test = 0;
    ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
         ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@constructor::new::@formalParameter::test
  }

  A.redirect(int test) : this(test);
                              ^^^^ IS_READ_BY <testLibrary>::@class::A::@constructor::redirect::@formalParameter::test
}

class B extends A {
  B(super.test);
          ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
}

class C extends A {
  C(int test) : super(test);
                      ^^^^ IS_READ_BY <testLibrary>::@class::C::@constructor::new::@formalParameter::test
}

void f() {
  A(0);
  A _ = .new(0);
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
void f() {
  /// [test]
  void foo({int? test}) {
    test;
    test = 0;
    test += 0;
         ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    (test,) = (0,);
    for (test in [0]) {}
  }

  foo(test: 0);
  foo.call(test: 1);
  (foo)(test: 2);
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
void f() {
  /// [test]
  void foo([int? test]) {
    test;
    test = 0;
    test += 0;
         ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    (test,) = (0,);
    for (test in [0]) {}
  }

  foo(0);
  foo.call(1);
  (foo)(2);
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
void f() {
  /// [test]
  void foo({required int test}) {
    test;
    test = 0;
    test += 0;
         ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    (test,) = (0,);
    for (test in [0]) {}
  }

  foo(test: 0);
  foo.call(test: 1);
  (foo)(test: 2);
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
void f() {
  /// [test]
  void foo(int test) {
    test;
    test = 0;
    test += 0;
         ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    (test,) = (0,);
    for (test in [0]) {}
  }

  foo(0);
  foo.call(1);
  (foo)(2);
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
class A {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
  void foo({int? test}) {
    test;
    ^^^^ IS_READ_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
    test = 0;
    ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
         ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
  }
}

void f(A a) {
  a.foo(test: 0);
        ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@method::foo::@formalParameter::test
  a.foo.call(test: 1);
             ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@method::foo::@formalParameter::test
  (a.foo)(test: 2);
          ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@method::foo::@formalParameter::test
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test'},
      expected: r'''
class A<T> {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
  void foo({T? test}) {
    test;
    ^^^^ IS_READ_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
    test = null;
    ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
    test = test;
    ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
           ^^^^ IS_READ_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
    (test,) = (null,);
     ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
    for (test in [null]) {}
         ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
  }
}

void f(A<int> a) {
  a.foo(test: 0);
        ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@method::foo::@formalParameter::test
  a.foo.call(test: 1);
  (a.foo)(test: 2);
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
class A {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
  void foo([int? test]) {
    test;
    ^^^^ IS_READ_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
    test = 0;
    ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
         ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
  }
}

void f(A a) {
  a.foo(0);
  a.foo.call(1);
  (a.foo)(2);
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
class A {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
  void foo({required int test}) {
    test;
    ^^^^ IS_READ_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
    test = 0;
    ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
         ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
  }
}

void f(A a) {
  a.foo(test: 0);
        ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@method::foo::@formalParameter::test
  a.foo.call(test: 1);
             ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@method::foo::@formalParameter::test
  (a.foo)(test: 2);
          ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@method::foo::@formalParameter::test
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
class A {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
  void foo(int test) {
    test;
    ^^^^ IS_READ_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
    test = 0;
    ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
    test += 0;
    ^^^^ IS_READ_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
         ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
    (test,) = (0,);
     ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
    for (test in [0]) {}
         ^^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@method::foo::@formalParameter::test
  }
}

void f(A a) {
  a.foo(0);
  a.foo.call(1);
  (a.foo)(2);
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
/// [test]
     ^^^^ IS_REFERENCED_BY <testLibrary>::@function::foo::@formalParameter::test
void foo({int? test}) {
  test;
  ^^^^ IS_READ_BY <testLibrary>::@function::foo::@formalParameter::test
  test = 1;
  ^^^^ IS_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
  test += 2;
  ^^^^ IS_READ_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
       ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  (test,) = (0,);
   ^^^^ IS_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
  for (test in [0]) {}
       ^^^^ IS_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
}
void f() {
  foo(test: 0);
      ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@function::foo::@formalParameter::test
  foo.call(test: 1);
           ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@function::foo::@formalParameter::test
  (foo)(test: 2);
        ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@function::foo::@formalParameter::test
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
/// [test]
     ^^^^ IS_REFERENCED_BY <testLibrary>::@function::foo::@formalParameter::test
void foo(int a, int b, {int? test}) {
  test;
  ^^^^ IS_READ_BY <testLibrary>::@function::foo::@formalParameter::test
  test = 1;
  ^^^^ IS_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
  test += 2;
  ^^^^ IS_READ_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
       ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  (test,) = (0,);
   ^^^^ IS_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
  for (test in [0]) {}
       ^^^^ IS_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
}

void f() {
  foo(0, test: 0, 0);
         ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@function::foo::@formalParameter::test
  foo.call(0, test: 1, 0);
              ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@function::foo::@formalParameter::test
  (foo)(0, test: 2, 0);
           ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@function::foo::@formalParameter::test
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
/// [test]
     ^^^^ IS_REFERENCED_BY <testLibrary>::@function::foo::@formalParameter::test
void foo([int? test]) {
  test;
  ^^^^ IS_READ_BY <testLibrary>::@function::foo::@formalParameter::test
  test = 1;
  ^^^^ IS_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
  test += 2;
  ^^^^ IS_READ_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
       ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  (test,) = (0,);
   ^^^^ IS_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
  for (test in [0]) {}
       ^^^^ IS_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
}
void f() {
  foo(0);
  foo.call(1);
  (foo)(2);
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
/// [test]
     ^^^^ IS_REFERENCED_BY <testLibrary>::@function::foo::@formalParameter::test
void foo({required int test}) {
  test;
  ^^^^ IS_READ_BY <testLibrary>::@function::foo::@formalParameter::test
  test = 1;
  ^^^^ IS_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
  test += 2;
  ^^^^ IS_READ_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
       ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  (test,) = (0,);
   ^^^^ IS_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
  for (test in [0]) {}
       ^^^^ IS_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
}

void f() {
  foo(test: 0);
      ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@function::foo::@formalParameter::test
  foo.call(test: 1);
           ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@function::foo::@formalParameter::test
  (foo)(test: 2);
        ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@function::foo::@formalParameter::test
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test', '+'},
      expected: r'''
/// [test]
     ^^^^ IS_REFERENCED_BY <testLibrary>::@function::foo::@formalParameter::test
void foo(int test) {
  test;
  ^^^^ IS_READ_BY <testLibrary>::@function::foo::@formalParameter::test
  test = 1;
  ^^^^ IS_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
  test += 2;
  ^^^^ IS_READ_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
       ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  (test,) = (0,);
   ^^^^ IS_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
  for (test in [0]) {}
       ^^^^ IS_WRITTEN_BY <testLibrary>::@function::foo::@formalParameter::test
}

void f() {
  foo(0);
  foo.call(1);
  (foo)(2);
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
class A {
  get foo => null;
  void useGetter() {
    this.foo();
         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
    foo();
    ^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@getter::foo
  }
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
class A {
  int get foo => 0;
}

void useGetter(Object? x) {
  if (x case A(foo: 0)) {}
               ^^^ IS_REFERENCED_BY_PATTERN_FIELD qualified <testLibrary>::@class::A::@getter::foo
  if (x case A(: var foo)) {}
               ^ IS_REFERENCED_BY_PATTERN_FIELD qualified <testLibrary>::@class::A::@getter::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
import 'test.dart' as p;

/// [foo], [A.foo], [p.A.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@getter::foo
              ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
                         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
class A {
  static int get foo => 0;
  static void useGetter() {
    foo;
    ^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@getter::foo
  }
}

void useGetter() {
  A.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
  p.A.foo;
      ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@getter::foo
}
''',
    );
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
    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [foo] and [A.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@method::foo
                 ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@method::foo
class A {
  void foo() {}
  void useFoo(Object? x) {
    this.foo();
         ^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@method::foo
    foo();
    ^^^ IS_INVOKED_BY <testLibrary>::@class::A::@method::foo
    this.foo;
         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@method::foo
    foo;
    ^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@method::foo
    if (x case A(foo: _)) {}
                 ^^^ IS_REFERENCED_BY_PATTERN_FIELD qualified <testLibrary>::@class::A::@method::foo
    if (x case A(: var foo)) {}
                 ^ IS_REFERENCED_BY_PATTERN_FIELD qualified <testLibrary>::@class::A::@method::foo
  }
}
void useFoo(A a) {
  a.foo();
    ^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@method::foo
  a.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@method::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
import 'test.dart' as p;

/// [foo], [A.foo], [p.A.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@method::foo
              ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@method::foo
                         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@method::foo
class A {
  static A foo() => A();
  static void useFoo() {
    foo();
    ^^^ IS_INVOKED_BY <testLibrary>::@class::A::@method::foo
    foo;
    ^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@method::foo
  }
}

void useFoo() {
  A.foo();
    ^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@method::foo
  A.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@method::foo
  A a = .foo();
         ^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@method::foo
  p.A.foo();
      ^^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@method::foo
  p.A.foo;
      ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@method::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [foo] and [E.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@enum::E::@method::foo
                 ^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@method::foo
enum E {
  v;
  void foo() {}
  void useFoo() {
    this.foo();
         ^^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@method::foo
    foo();
    ^^^ IS_INVOKED_BY <testLibrary>::@enum::E::@method::foo
    this.foo;
         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@method::foo
    foo;
    ^^^ IS_REFERENCED_BY <testLibrary>::@enum::E::@method::foo
  }
}
void useFoo(E e) {
  e.foo();
    ^^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@method::foo
  e.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@method::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [foo] and [E.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@enum::E::@method::foo
                 ^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@method::foo
enum E {
  v;
  static void foo() {}
  static void useFoo() {
    foo();
    ^^^ IS_INVOKED_BY <testLibrary>::@enum::E::@method::foo
    foo;
    ^^^ IS_REFERENCED_BY <testLibrary>::@enum::E::@method::foo
  }
}
void useFoo() {
  E.foo();
    ^^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@method::foo
  E.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@method::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [foo] and [E.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@extension::E::@method::foo
                 ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E::@method::foo
extension E on int {
  void foo() {}
}

void useFoo() {
  0.foo();
    ^^^ IS_INVOKED_BY qualified <testLibrary>::@extension::E::@method::foo
  0.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E::@method::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [foo] and [E.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@extension::E::@method::foo
                 ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E::@method::foo
extension E on int {
  static void foo() {}
}

void useFoo() {
  E.foo();
    ^^^ IS_INVOKED_BY qualified <testLibrary>::@extension::E::@method::foo
  E.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E::@method::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [foo] and [int.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@extension::#0::@method::foo
                   ^^^ IS_READ_BY qualified name: foo
extension on int {
  void foo() {} // int
}

/// [foo] and [double.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@extension::#1::@method::foo
                      ^^^ IS_READ_BY qualified name: foo
extension on double {
  void foo() {} // double
}

void useFoo() {
  0.foo();
    ^^^ IS_INVOKED_BY qualified <testLibrary>::@extension::#0::@method::foo
  0.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extension::#0::@method::foo
  (1.2).foo();
        ^^^ IS_INVOKED_BY qualified <testLibrary>::@extension::#1::@method::foo
  (1.2).foo;
        ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extension::#1::@method::foo
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [foo] and [A.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@extensionType::A::@method::foo
                 ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@method::foo
extension type A(int it) {
  void foo() {}
  void useFoo() {
    this.foo();
         ^^^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@method::foo
    foo();
    ^^^ IS_INVOKED_BY <testLibrary>::@extensionType::A::@method::foo
    this.foo;
         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@method::foo
    foo;
    ^^^ IS_REFERENCED_BY <testLibrary>::@extensionType::A::@method::foo
  }
}
void useFoo() {
  var a = A(0);
  a.foo();
    ^^^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@method::foo
  a.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@method::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [foo] and [A.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@extensionType::A::@method::foo
                 ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@method::foo
extension type A(int it) {
  static void foo() {}
  static void useFoo() {
    foo();
    ^^^ IS_INVOKED_BY <testLibrary>::@extensionType::A::@method::foo
    foo;
    ^^^ IS_REFERENCED_BY <testLibrary>::@extensionType::A::@method::foo
  }
}
void useFoo() {
  A.foo();
    ^^^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@method::foo
  A.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@method::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [foo] and [M.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@mixin::M::@method::foo
                 ^^^ IS_REFERENCED_BY qualified <testLibrary>::@mixin::M::@method::foo
mixin M {
  void foo() {}
  void useFoo() {
    this.foo();
         ^^^ IS_INVOKED_BY qualified <testLibrary>::@mixin::M::@method::foo
    foo();
    ^^^ IS_INVOKED_BY <testLibrary>::@mixin::M::@method::foo
    this.foo;
         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@mixin::M::@method::foo
    foo;
    ^^^ IS_REFERENCED_BY <testLibrary>::@mixin::M::@method::foo
  }
}
void useFoo(M m) {
  m.foo();
    ^^^ IS_INVOKED_BY qualified <testLibrary>::@mixin::M::@method::foo
  m.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@mixin::M::@method::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
/// [foo] and [M.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@mixin::M::@method::foo
                 ^^^ IS_REFERENCED_BY qualified <testLibrary>::@mixin::M::@method::foo
mixin M {
  static void foo() {}
  static void useFoo() {
    foo();
    ^^^ IS_INVOKED_BY <testLibrary>::@mixin::M::@method::foo
    foo;
    ^^^ IS_REFERENCED_BY <testLibrary>::@mixin::M::@method::foo
  }
}
void useFoo() {
  M.foo();
    ^^^ IS_INVOKED_BY qualified <testLibrary>::@mixin::M::@method::foo
  M.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@mixin::M::@method::foo
  M m = .foo();
         ^^^ IS_INVOKED_BY qualified <testLibrary>::@mixin::M::@method::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'+'},
      expected: r'''
/// [operator +] and [A.operator +]
              ^ IS_REFERENCED_BY <testLibrary>::@class::A::@method::+
                                 ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@method::+
class A {
  operator +(other) => this;
}
void useOperator(A a) {
  a + 1;
    ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@method::+
  a += 2;
    ^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@method::+
  ++a;
  ^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@method::+
  a++;
   ^^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@method::+
}
''',
    );
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

    assertIndexText(
      result,
      names: {'[]'},
      expected: r'''
/// [operator []] and [A.operator []]
class A {
  operator [](i) => null;
}
void useOperator(A a) {
  a[0];
   ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@method::[]
}
''',
    );
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

    assertIndexText(
      result,
      names: {'[]='},
      expected: r'''
/// [operator []=] and [A.operator []=]
class A {
  operator []=(i, v) {}
}
void useOperator(A a) {
  a[1] = 42;
   ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@method::[]=
}
''',
    );
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

    assertIndexText(
      result,
      names: {'~'},
      expected: r'''
/// [operator ~] and [A.operator ~]
              ^ IS_REFERENCED_BY <testLibrary>::@class::A::@method::~
                                 ^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@method::~
class A {
  A operator ~() => this;
}
void useOperator(A a) {
  ~a;
  ^ IS_INVOKED_BY qualified <testLibrary>::@class::A::@method::~
}
''',
    );
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

    assertIndexText(
      result,
      names: {'+'},
      expected: r'''
/// [operator +] and [E.operator +]
              ^ IS_REFERENCED_BY <testLibrary>::@enum::E::@method::+
                                 ^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@method::+
enum E {
  v;
  int operator +(other) => 0;
}
void useOperator(E e) {
  e + 1;
    ^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@method::+
  e += 2;
    ^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@method::+
  ++e;
  ^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@method::+
  e++;
   ^^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@method::+
}
''',
    );
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

    assertIndexText(
      result,
      names: {'[]'},
      expected: r'''
/// [operator []] and [E.operator []]
enum E {
  v;
  int operator [](int index) => 0;
}
void useOperator(E e) {
  e[0];
   ^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@method::[]
}
''',
    );
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

    assertIndexText(
      result,
      names: {'[]='},
      expected: r'''
/// [operator []=] and [E.operator []=]
enum E {
  v;
  operator []=(int index, int value) {}
}
void useOperator(E e) {
  e[1] = 42;
   ^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@method::[]=
}
''',
    );
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

    assertIndexText(
      result,
      names: {'~'},
      expected: r'''
/// [operator ~] and [E.operator ~]
              ^ IS_REFERENCED_BY <testLibrary>::@enum::E::@method::~
                                 ^ IS_REFERENCED_BY qualified <testLibrary>::@enum::E::@method::~
enum E {
  e;
  int operator ~() => 0;
}
void useOperator(E e) {
  ~e;
  ^ IS_INVOKED_BY qualified <testLibrary>::@enum::E::@method::~
}
''',
    );
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

    assertIndexText(
      result,
      names: {'+'},
      expected: r'''
/// [operator +] and [E.operator +]
              ^ IS_REFERENCED_BY <testLibrary>::@extension::E::@method::+
                                 ^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E::@method::+
extension E on int {
  int operator +(int other) => 0;
}
void useOperator(int e) {
  E(e) + 1;
       ^ IS_INVOKED_BY qualified <testLibrary>::@extension::E::@method::+
}
''',
    );
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

    assertIndexText(
      result,
      names: {'[]'},
      expected: r'''
/// [operator []] and [E.operator []]
extension E on int {
  int operator [](int index) => 0;
}
void useOperator(int e) {
  E(e)[0];
      ^ IS_INVOKED_BY qualified <testLibrary>::@extension::E::@method::[]
}
''',
    );
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

    assertIndexText(
      result,
      names: {'[]='},
      expected: r'''
/// [operator []=] and [E.operator []=]
extension E on int {
  operator []=(int index, int value) {}
}
void useOperator(int e) {
  E(e)[1] = 42;
      ^ IS_INVOKED_BY qualified <testLibrary>::@extension::E::@method::[]=
}
''',
    );
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

    assertIndexText(
      result,
      names: {'~'},
      expected: r'''
/// [operator ~] and [E.operator ~]
              ^ IS_REFERENCED_BY <testLibrary>::@extension::E::@method::~
                                 ^ IS_REFERENCED_BY qualified <testLibrary>::@extension::E::@method::~
extension E on int {
  int operator ~() => 0;
}
void useOperator(int e) {
  ~E(e);
  ^ IS_INVOKED_BY qualified <testLibrary>::@extension::E::@method::~
}
''',
    );
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

    assertIndexText(
      result,
      names: {'+'},
      expected: r'''
/// [operator +] and [A.operator +]
              ^ IS_REFERENCED_BY <testLibrary>::@extensionType::A::@method::+
                                 ^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@method::+
extension type A(int it) {
  int operator +(int other) => 0;
}
void useOperator(A a) {
  a + 1;
    ^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@method::+
  a += 2;
    ^^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@method::+
  ++a;
  ^^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@method::+
  a++;
   ^^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@method::+
}
''',
    );
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

    assertIndexText(
      result,
      names: {'[]'},
      expected: r'''
/// [operator []] and [A.operator []]
extension type A(int it) {
  int operator [](int index) => 0;
}
void useOperator(A a) {
  a[0];
   ^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@method::[]
}
''',
    );
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

    assertIndexText(
      result,
      names: {'[]='},
      expected: r'''
/// [operator []=] and [A.operator []=]
extension type A(int it) {
  operator []=(int index, int value) {}
}
void useOperator(A a) {
  a[1] = 42;
   ^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@method::[]=
}
''',
    );
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

    assertIndexText(
      result,
      names: {'~'},
      expected: r'''
/// [operator ~] and [A.operator ~]
              ^ IS_REFERENCED_BY <testLibrary>::@extensionType::A::@method::~
                                 ^ IS_REFERENCED_BY qualified <testLibrary>::@extensionType::A::@method::~
extension type A(int it) {
  int operator ~() => 0;
}
void useOperator(A a) {
  ~a;
  ^ IS_INVOKED_BY qualified <testLibrary>::@extensionType::A::@method::~
}
''',
    );
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

    assertIndexText(
      result,
      names: {'+'},
      expected: r'''
/// [operator +] and [M.operator +]
              ^ IS_REFERENCED_BY <testLibrary>::@mixin::M::@method::+
                                 ^ IS_REFERENCED_BY qualified <testLibrary>::@mixin::M::@method::+
mixin M {
  int operator +(int other) => 0;
}
void useOperator(M m) {
  m + 1;
    ^ IS_INVOKED_BY qualified <testLibrary>::@mixin::M::@method::+
  m += 2;
    ^^ IS_INVOKED_BY qualified <testLibrary>::@mixin::M::@method::+
  ++m;
  ^^ IS_INVOKED_BY qualified <testLibrary>::@mixin::M::@method::+
  m++;
   ^^ IS_INVOKED_BY qualified <testLibrary>::@mixin::M::@method::+
}
''',
    );
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

    assertIndexText(
      result,
      names: {'[]'},
      expected: r'''
/// [operator []] and [M.operator []]
mixin M {
  int operator [](int index) => 0;
}
void useOperator(M m) {
  m[0];
   ^ IS_INVOKED_BY qualified <testLibrary>::@mixin::M::@method::[]
}
''',
    );
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

    assertIndexText(
      result,
      names: {'[]='},
      expected: r'''
/// [operator []=] and [M.operator []=]
mixin M {
  operator []=(int index, int value) {}
}
void useOperator(M m) {
  m[1] = 42;
   ^ IS_INVOKED_BY qualified <testLibrary>::@mixin::M::@method::[]=
}
''',
    );
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

    assertIndexText(
      result,
      names: {'~'},
      expected: r'''
/// [operator ~] and [M.operator ~]
              ^ IS_REFERENCED_BY <testLibrary>::@mixin::M::@method::~
                                 ^ IS_REFERENCED_BY qualified <testLibrary>::@mixin::M::@method::~
mixin M {
  int operator ~() => 0;
}
void useOperator(M m) {
  ~m;
  ^ IS_INVOKED_BY qualified <testLibrary>::@mixin::M::@method::~
}
''',
    );
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

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
mixin A {}
class B implements A {}
                   ^ IS_IMPLEMENTED_BY <testLibrary>::@mixin::A
                   ^ IS_REFERENCED_BY <testLibrary>::@mixin::A
''',
    );
  }

  test_MixinElement_hierarchy_class_with() async {
    var result = await _indexTestCode(r'''
mixin A {}
class B extends Object with A {}
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
mixin A {}
class B extends Object with A {}
                            ^ IS_MIXED_IN_BY <testLibrary>::@mixin::A
                            ^ IS_REFERENCED_BY <testLibrary>::@mixin::A
''',
    );
  }

  test_MixinElement_hierarchy_classTypeAlias_with() async {
    var result = await _indexTestCode(r'''
mixin A {}
class B = Object with A;
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
mixin A {}
class B = Object with A;
                      ^ IS_MIXED_IN_BY <testLibrary>::@mixin::A
                      ^ IS_REFERENCED_BY <testLibrary>::@mixin::A
''',
    );
  }

  test_MixinElement_hierarchy_enum_implements() async {
    var result = await _indexTestCode(r'''
mixin A {}
enum E implements A {
  v
}
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
mixin A {}
enum E implements A {
                  ^ IS_IMPLEMENTED_BY <testLibrary>::@mixin::A
                  ^ IS_REFERENCED_BY <testLibrary>::@mixin::A
  v
}
''',
    );
  }

  test_MixinElement_hierarchy_enum_with() async {
    var result = await _indexTestCode(r'''
mixin A {}
enum E with A {
  v
}
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
mixin A {}
enum E with A {
            ^ IS_MIXED_IN_BY <testLibrary>::@mixin::A
            ^ IS_REFERENCED_BY <testLibrary>::@mixin::A
  v
}
''',
    );
  }

  test_MixinElement_hierarchy_extensionType_implements() async {
    var result = await _indexTestCode(r'''
mixin A {}
extension type E(A it) implements A {}
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
mixin A {}
extension type E(A it) implements A {}
                 ^ IS_REFERENCED_BY <testLibrary>::@mixin::A
                                  ^ IS_IMPLEMENTED_BY <testLibrary>::@mixin::A
                                  ^ IS_REFERENCED_BY <testLibrary>::@mixin::A
''',
    );
  }

  test_MixinElement_hierarchy_mixin_implements() async {
    var result = await _indexTestCode(r'''
mixin A {}
mixin M implements A {}
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
mixin A {}
mixin M implements A {}
                   ^ IS_IMPLEMENTED_BY <testLibrary>::@mixin::A
                   ^ IS_REFERENCED_BY <testLibrary>::@mixin::A
''',
    );
  }

  test_MixinElement_hierarchy_mixin_on() async {
    var result = await _indexTestCode(r'''
mixin A {}
mixin M on A {}
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
mixin A {}
mixin M on A {}
           ^ CONSTRAINS <testLibrary>::@mixin::A
           ^ IS_REFERENCED_BY <testLibrary>::@mixin::A
''',
    );
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

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

mixin A {
  static const int myConstant = 0;
}

@A.myConstant
 ^ IS_REFERENCED_BY <testLibrary>::@mixin::A
@p.A.myConstant
   ^ IS_REFERENCED_BY qualified <testLibrary>::@mixin::A
void f() {}
Prefixes:
  <testLibrary>::@mixin::A: (unprefixed),p
''',
    );
  }

  test_MixinElement_reference_comment() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

mixin A {}

/// [A] and [p.A].
void f() {}
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

mixin A {}

/// [A] and [p.A].
     ^ IS_REFERENCED_BY <testLibrary>::@mixin::A
               ^ IS_REFERENCED_BY qualified <testLibrary>::@mixin::A
void f() {}
Prefixes:
  <testLibrary>::@mixin::A: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

mixin A {
  static void foo() {}
}

void f() {
  A.foo();
  ^ IS_REFERENCED_BY <testLibrary>::@mixin::A
  p.A.foo();
    ^ IS_REFERENCED_BY qualified <testLibrary>::@mixin::A
}
Prefixes:
  <testLibrary>::@mixin::A: (unprefixed),p
''',
    );
  }

  test_MixinElement_reference_namedType() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

mixin A {}

void f(A v1, p.A v2) {}
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
import 'test.dart' as p;

mixin A {}

void f(A v1, p.A v2) {}
       ^ IS_REFERENCED_BY <testLibrary>::@mixin::A
               ^ IS_REFERENCED_BY qualified <testLibrary>::@mixin::A
Prefixes:
  <testLibrary>::@mixin::A: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
import 'test.dart' as p;

/// [foo], [A.foo], [p.A.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@class::A::@setter::foo
              ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
                         ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
class A {
  static set foo(int _) {}
  static void useSetter() {
    foo = 0;
    ^^^ IS_WRITTEN_BY <testLibrary>::@class::A::@setter::foo
  }
}

void useSetter() {
  A.foo = 0;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
  p.A.foo = 0;
      ^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@setter::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test'},
      expected: r'''
class A {
  A({int? test});
}

class B extends A {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::B::@constructor::new::@formalParameter::test
  B({super.test}) : assert(test != null);
           ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
                           ^^^^ IS_READ_BY <testLibrary>::@class::B::@constructor::new::@formalParameter::test
}

void f() {
  B(test: 0);
    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::B::@constructor::new::@formalParameter::test
  B _ = .new(test: 0);
             ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::B::@constructor::new::@formalParameter::test
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test'},
      expected: r'''
class A {
  A([int? test]);
}

class B extends A {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::B::@constructor::new::@formalParameter::test
  B([super.test]) : assert(test != null);
           ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
                           ^^^^ IS_READ_BY <testLibrary>::@class::B::@constructor::new::@formalParameter::test
}

void f() {
  B(0);
  B _ = .new(0);
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test'},
      expected: r'''
class A {
  A({required int test});
}

class B extends A {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::B::@constructor::new::@formalParameter::test
  B({required super.test}) : assert(test != -1);
                    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
                                    ^^^^ IS_READ_BY <testLibrary>::@class::B::@constructor::new::@formalParameter::test
}

void f() {
  B(test: 0);
    ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::B::@constructor::new::@formalParameter::test
  B _ = .new(test: 0);
             ^^^^ IS_REFERENCED_BY_NAMED_ARGUMENT qualified <testLibrary>::@class::B::@constructor::new::@formalParameter::test
}
''',
    );
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

    assertIndexText(
      result,
      names: {'test'},
      expected: r'''
class A {
  A(int test);
}

class B extends A {
  /// [test]
       ^^^^ IS_REFERENCED_BY <testLibrary>::@class::B::@constructor::new::@formalParameter::test
  B(super.test) : assert(test != -1);
          ^^^^ IS_REFERENCED_BY qualified <testLibrary>::@class::A::@constructor::new::@formalParameter::test
                         ^^^^ IS_READ_BY <testLibrary>::@class::B::@constructor::new::@formalParameter::test
}

void f() {
  B(0);
  B _ = .new(0);
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
import 'test.dart' as p;

void foo() {}

/// [foo] and [p.foo]
     ^^^ IS_REFERENCED_BY <testLibrary>::@function::foo
                 ^^^ IS_REFERENCED_BY qualified <testLibrary>::@function::foo
void f() {
  foo();
  ^^^ IS_INVOKED_BY <testLibrary>::@function::foo
  p.foo();
    ^^^ IS_INVOKED_BY qualified <testLibrary>::@function::foo
  foo;
  ^^^ IS_REFERENCED_BY <testLibrary>::@function::foo
  p.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@function::foo
}
Prefixes:
  <testLibrary>::@function::foo: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
void foo() {}

void f() {
  foo = 0;
  ^^^ IS_REFERENCED_BY <testLibrary>::@function::foo
}
''',
    );
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

    assertIndexText(
      result,
      names: {'loadLibrary'},
      expected: r'''
import 'dart:math' deferred as math;

void f() {
  math.loadLibrary();
       ^^^^^^^^^^^ IS_INVOKED_BY qualified dart:math::@function::loadLibrary
}
''',
    );
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
import 'test.dart' as p;

int get foo => 0;

/// [foo] and [p.foo].
     ^^^ IS_REFERENCED_BY <testLibrary>::@getter::foo
                 ^^^ IS_REFERENCED_BY qualified <testLibrary>::@getter::foo
void f() {
  foo;
  ^^^ IS_REFERENCED_BY <testLibrary>::@getter::foo
  p.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@getter::foo
}
Prefixes:
  <testLibrary>::@getter::foo: (unprefixed),p
''',
    );
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

    assertIndexText(
      result,
      names: {'foo', '+', '-'},
      expected: r'''
import 'test.dart' as p;

int get foo => 0;
set foo(int _) {}

/// [foo] and [p.foo].
     ^^^ IS_REFERENCED_BY <testLibrary>::@getter::foo
                 ^^^ IS_REFERENCED_BY qualified <testLibrary>::@getter::foo
void f() {
  foo;
  ^^^ IS_REFERENCED_BY <testLibrary>::@getter::foo
  foo = 0;
  ^^^ IS_WRITTEN_BY <testLibrary>::@setter::foo
  foo += 1;
  ^^^ IS_READ_BY <testLibrary>::@getter::foo
  ^^^ IS_WRITTEN_BY <testLibrary>::@setter::foo
      ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  foo ??= 2;
  ^^^ IS_READ_BY <testLibrary>::@getter::foo
  ^^^ IS_WRITTEN_BY <testLibrary>::@setter::foo
  foo++;
  ^^^ IS_REFERENCED_BY <testLibrary>::@setter::foo
     ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  --foo;
  ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::-
    ^^^ IS_REFERENCED_BY <testLibrary>::@setter::foo
  p.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@getter::foo
  p.foo = 0;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@setter::foo
  p.foo += 1;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@setter::foo
        ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  p.foo ??= 2;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@setter::foo
  p.foo++;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@setter::foo
       ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  --p.foo;
  ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::-
      ^^^ IS_REFERENCED_BY qualified <testLibrary>::@setter::foo
}
Prefixes:
  <testLibrary>::@getter::foo: (unprefixed),p
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
import 'test.dart' show foo;
                        ^^^ IS_REFERENCED_BY qualified <testLibrary>::@getter::foo
                        ^^^ IS_REFERENCED_BY qualified <testLibrary>::@setter::foo

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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
import 'test.dart' as p;

set foo(int _) {}

void f() {
  foo = 0;
  ^^^ IS_WRITTEN_BY <testLibrary>::@setter::foo
  p.foo = 0;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@setter::foo
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

    assertIndexText(
      result,
      names: {'foo'},
      expected: r'''
import 'test.dart' show foo;
                        ^^^ IS_REFERENCED_BY qualified <testLibrary>::@setter::foo

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

    assertIndexText(
      result,
      names: {'foo', '+', '-'},
      expected: r'''
import 'test.dart' as p;

int foo = 0;

/// [foo] and [p.foo].
     ^^^ IS_REFERENCED_BY <testLibrary>::@getter::foo
                 ^^^ IS_REFERENCED_BY qualified <testLibrary>::@getter::foo
@foo
 ^^^ IS_REFERENCED_BY <testLibrary>::@getter::foo
@p.foo
   ^^^ IS_REFERENCED_BY qualified <testLibrary>::@getter::foo
void f() {
  foo;
  ^^^ IS_REFERENCED_BY <testLibrary>::@getter::foo
  foo = 0;
  ^^^ IS_WRITTEN_BY <testLibrary>::@setter::foo
  foo += 1;
  ^^^ IS_READ_BY <testLibrary>::@getter::foo
  ^^^ IS_WRITTEN_BY <testLibrary>::@setter::foo
      ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  foo ??= 2;
  ^^^ IS_READ_BY <testLibrary>::@getter::foo
  ^^^ IS_WRITTEN_BY <testLibrary>::@setter::foo
  foo++;
  ^^^ IS_REFERENCED_BY <testLibrary>::@setter::foo
     ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  --foo;
  ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::-
    ^^^ IS_REFERENCED_BY <testLibrary>::@setter::foo
  p.foo;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@getter::foo
  p.foo = 0;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@setter::foo
  p.foo += 1;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@setter::foo
        ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  p.foo ??= 2;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@setter::foo
  p.foo++;
    ^^^ IS_REFERENCED_BY qualified <testLibrary>::@setter::foo
       ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::+
  --p.foo;
  ^^ IS_INVOKED_BY qualified dart:core::@class::num::@method::-
      ^^^ IS_REFERENCED_BY qualified <testLibrary>::@setter::foo
}
Prefixes:
  <testLibrary>::@getter::foo: (unprefixed),p
''',
    );
  }

  test_TypeAliasElement_legacy_reference() async {
    var result = await _indexTestCode('''
typedef void A();
/// [A]
void f(A p) {}
''');

    assertIndexText(
      result,
      names: {'A'},
      expected: r'''
typedef void A();
/// [A]
     ^ IS_REFERENCED_BY <testLibrary>::@typeAlias::A
void f(A p) {}
       ^ IS_REFERENCED_BY <testLibrary>::@typeAlias::A
''',
    );
  }

  test_TypeAliasElement_modern_hierarchy_class_extends() async {
    var result = await _indexTestCode('''
class A<T> {}
typedef B = A<int>;
class C extends B {}
''');

    assertIndexText(
      result,
      names: {'A', 'B'},
      expected: r'''
class A<T> {}
typedef B = A<int>;
            ^ IS_REFERENCED_BY <testLibrary>::@class::A
class C extends B {}
                ^ IS_EXTENDED_BY <testLibrary>::@typeAlias::B
                ^ IS_REFERENCED_BY <testLibrary>::@typeAlias::B
''',
    );
  }

  test_TypeAliasElement_modern_hierarchy_class_implements() async {
    var result = await _indexTestCode('''
class A<T> {}
typedef B = A<int>;
class C implements B {}
''');

    assertIndexText(
      result,
      names: {'A', 'B'},
      expected: r'''
class A<T> {}
typedef B = A<int>;
            ^ IS_REFERENCED_BY <testLibrary>::@class::A
class C implements B {}
                   ^ IS_IMPLEMENTED_BY <testLibrary>::@typeAlias::B
                   ^ IS_REFERENCED_BY <testLibrary>::@typeAlias::B
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

    assertIndexText(
      result,
      names: {'A', 'B'},
      expected: r'''
class A<T> {}
typedef B = A<int>;
            ^ IS_REFERENCED_BY <testLibrary>::@class::A
class C extends Object with B {}
                            ^ IS_MIXED_IN_BY <testLibrary>::@typeAlias::B
                            ^ IS_REFERENCED_BY <testLibrary>::@typeAlias::B
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

    assertIndexText(
      result,
      names: {'A', 'B'},
      expected: r'''
class A<T> {
  static int field = 0;
  static void method() {}
}

typedef B = A<int>;
            ^ IS_REFERENCED_BY <testLibrary>::@class::A

/// [B]
     ^ IS_REFERENCED_BY <testLibrary>::@typeAlias::B
void f(B p) {
       ^ IS_REFERENCED_BY <testLibrary>::@typeAlias::B
  B v;
  ^ IS_REFERENCED_BY <testLibrary>::@typeAlias::B
  B();
  ^ IS_REFERENCED_BY <testLibrary>::@typeAlias::B
  B.field;
  ^ IS_REFERENCED_BY <testLibrary>::@typeAlias::B
  B.field = 0;
  ^ IS_REFERENCED_BY <testLibrary>::@typeAlias::B
  B.method();
  ^ IS_REFERENCED_BY <testLibrary>::@typeAlias::B
}
''',
    );
  }

  test_TypeAliasElement_modern_reference_comment() async {
    var result = await _indexTestCode(r'''
import 'test.dart' as p;

class A<T> {}
typedef B = A<int>;

/// [B] and [p.B].
void f() {}
''');

    assertIndexText(
      result,
      names: {'A', 'B'},
      expected: r'''
import 'test.dart' as p;

class A<T> {}
typedef B = A<int>;
            ^ IS_REFERENCED_BY <testLibrary>::@class::A

/// [B] and [p.B].
     ^ IS_REFERENCED_BY <testLibrary>::@typeAlias::B
               ^ IS_REFERENCED_BY qualified <testLibrary>::@typeAlias::B
void f() {}
Prefixes:
  <testLibrary>::@typeAlias::B: (unprefixed),p
''',
    );
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
    assertIndexText(
      result,
      names: {'bbb'},
      expected: r'''
library aaa.bbb.ccc;
class C {
  var bbb;
}
void f(p) {
  p.bbb = 1;
    ^^^ IS_WRITTEN_BY qualified name: bbb
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
    assertIndexText(
      result,
      names: {'x', '+'},
      expected: r'''
class C {
  var x;
}
void f(C c) {
  c.x; // 1
    ^ IS_REFERENCED_BY qualified <testLibrary>::@class::C::@getter::x
  c.x = 1;
    ^ IS_REFERENCED_BY qualified <testLibrary>::@class::C::@setter::x
  c.x += 2;
    ^ IS_REFERENCED_BY qualified <testLibrary>::@class::C::@setter::x
  c.x();
    ^ IS_REFERENCED_BY qualified <testLibrary>::@class::C::@getter::x
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
    assertIndexText(
      result,
      names: {'x', '+'},
      expected: r'''
void f(p) {
  p.x;
    ^ IS_READ_BY qualified name: x
  p.x = 1;
    ^ IS_WRITTEN_BY qualified name: x
  p.x += 2;
    ^ IS_READ_WRITTEN_BY qualified name: x
  p.x();
    ^ IS_INVOKED_BY qualified name: x
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
    assertIndexText(
      result,
      names: {'x', '+'},
      expected: r'''
class C {
  var x;
  m() {
    x; // 1
    ^ IS_REFERENCED_BY <testLibrary>::@class::C::@getter::x
    x = 1;
    ^ IS_WRITTEN_BY <testLibrary>::@class::C::@setter::x
    x += 2;
    ^ IS_READ_BY <testLibrary>::@class::C::@getter::x
    ^ IS_WRITTEN_BY <testLibrary>::@class::C::@setter::x
    x();
    ^ IS_REFERENCED_BY <testLibrary>::@class::C::@getter::x
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
    assertIndexText(
      result,
      names: {'x', '+'},
      expected: r'''
void f() {
  x;
  ^ IS_READ_BY name: x
  x = 1;
  ^ IS_WRITTEN_BY name: x
  x += 2;
  ^ IS_READ_WRITTEN_BY name: x
  x();
  ^ IS_INVOKED_BY name: x
}
''',
    );
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
  final IndexRelationKind kind;
  final bool isQualified;
  final String target;

  _IndexAnnotation({
    required this.offset,
    required this.length,
    required this.kind,
    required this.isQualified,
    required this.target,
  });
}

final class _IndexResult {
  final TestResolvedUnitResult resolvedUnit;
  final AnalysisDriverUnitIndex index;

  _IndexResult(this.resolvedUnit, this.index);

  FindElement2 get findElement => resolvedUnit.findElement;
}

final class _IndexTextBuilder {
  final _IndexResult result;

  final Map<int, Element> _elementById = {};

  _IndexTextBuilder(this.result);

  String indexText(Set<String> names) {
    var index = result.index;
    var annotations = <_IndexAnnotation>[];
    var elementsWithPrefixes = <int, Element>{};

    expect(index.usedElements.length, index.usedElementKinds.length);
    expect(index.usedElements.length, index.usedElementOffsets.length);
    expect(index.usedElements.length, index.usedElementLengths.length);
    expect(index.usedElements.length, index.usedElementIsQualifiedFlags.length);
    expect(index.elementUnits.length, index.elementImportPrefixes.length);

    for (var i = 0; i < index.usedElements.length; i++) {
      var elementId = index.usedElements[i];
      if (!names.contains(_nameForElementId(elementId))) {
        continue;
      }
      var element = _elementForId(elementId);

      annotations.add(
        _IndexAnnotation(
          offset: index.usedElementOffsets[i],
          length: index.usedElementLengths[i],
          kind: index.usedElementKinds[i],
          isQualified: index.usedElementIsQualifiedFlags[i],
          target: _elementText(element),
        ),
      );
      if (index.elementImportPrefixes[elementId].isNotEmpty) {
        elementsWithPrefixes[elementId] = element;
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

      annotations.add(
        _IndexAnnotation(
          offset: index.usedNameOffsets[i],
          length: name.length,
          kind: index.usedNameKinds[i],
          isQualified: index.usedNameIsQualifiedFlags[i],
          target: 'name: $name',
        ),
      );
    }

    annotations.sort((first, second) {
      var result = first.offset.compareTo(second.offset);
      if (result != 0) return result;
      result = first.length.compareTo(second.length);
      if (result != 0) return result;
      result = first.kind.name.compareTo(second.kind.name);
      if (result != 0) return result;
      result = first.isQualified.toString().compareTo(
        second.isQualified.toString(),
      );
      if (result != 0) return result;
      return first.target.compareTo(second.target);
    });

    for (var i = 1; i < annotations.length; i++) {
      var previous = annotations[i - 1];
      var current = annotations[i];
      if (previous.offset == current.offset &&
          previous.length == current.length &&
          previous.kind == current.kind &&
          previous.isQualified == current.isQualified &&
          previous.target == current.target) {
        fail(
          'Duplicate relation at ${current.offset}: '
          '${current.kind.name} ${current.target}',
        );
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
        var markerLength = annotation.length == 0 ? 1 : annotation.length;
        buffer.write('^' * markerLength);
        buffer.write(' ${annotation.kind.name}');
        if (annotation.isQualified) {
          buffer.write(' qualified');
        }
        buffer.writeln(' ${annotation.target}');
      }
    }

    if (elementsWithPrefixes.isNotEmpty) {
      buffer.writeln('Prefixes:');
      var entries = elementsWithPrefixes.entries.sortedBy((entry) {
        return _elementText(entry.value);
      });
      for (var entry in entries) {
        var prefixes = index.elementImportPrefixes[entry.key]
            .split(',')
            .map((prefix) => prefix.isEmpty ? '(unprefixed)' : prefix)
            .join(',');
        buffer.writeln('  ${_elementText(entry.value)}: $prefixes');
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

  /// Returns the lookup name of the element encoded by [elementId].
  ///
  /// An element is encoded as a path containing a unit member, optionally a
  /// class member, and optionally a named parameter. The innermost non-null
  /// component is the name matched by `assertIndexText`, so a parameter takes
  /// precedence over a class member, which takes precedence over a unit
  /// member.
  ///
  /// Constructor names have a leading `.` in the class-member component to
  /// distinguish them in the encoded path. The prefix is not part of the name
  /// used by `assertIndexText`, so it is removed here.
  String _nameForElementId(int elementId) {
    var index = result.index;
    var parameterNameId = index.elementNameParameterIds[elementId];
    if (parameterNameId != index.nullStringId) {
      return index.strings[parameterNameId];
    }

    var classMemberNameId = index.elementNameClassMemberIds[elementId];
    if (classMemberNameId != index.nullStringId) {
      var name = index.strings[classMemberNameId];
      return name.startsWith('.') ? name.substring(1) : name;
    }

    var unitMemberNameId = index.elementNameUnitMemberIds[elementId];
    return index.strings[unitMemberNameId];
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
