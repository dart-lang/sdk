// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementDisplayStringTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ElementDisplayStringTest extends PubPackageResolutionTest {
  test_class() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
abstract class B<T> extends A {}
''');

    var B = result.findElement.class_('B');
    var displayString = B.displayString();
    expect(displayString, 'abstract class B<T> extends A');
  }

  test_extension_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension StringExtension on String {}
''');

    var element = result.findElement.extension_('StringExtension');
    var displayString = element.displayString();
    expect(displayString, 'extension StringExtension on String');
  }

  test_extension_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension on String {}
''');

    var element = result.libraryElement.extensions.single;
    var displayString = element.displayString();
    expect(displayString, 'extension on String');
  }

  test_extensionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type MyString<T>(String it) implements String {}
''');

    var element = result.findElement.extensionType('MyString');
    var displayString = element.displayString();
    expect(
      displayString,
      'extension type MyString<T>(String it) implements String',
    );
  }

  test_longMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  String? longMethodName(String? aaa, [String? bbb = 'a', String? ccc]);
}
''');

    var methodElement = result.findElement.method('longMethodName');
    var singleLine = methodElement.displayString();
    expect(singleLine, '''
String? longMethodName(String? aaa, [String? bbb = 'a', String? ccc])''');

    var multiLine = methodElement.displayString(multiline: true);
    expect(multiLine, '''
String? longMethodName(
  String? aaa, [
  String? bbb = 'a',
  String? ccc,
])''');
  }

  test_longMethod_functionType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  String? longMethodName(
    String? aaa, 
    [String? Function(String?, String?, String?) bbb,
    String? ccc]
  );
}
''');

    var methodElement = result.findElement.method('longMethodName');
    var singleLine = methodElement.displayString();
    expect(
      singleLine,
      '''
String? longMethodName(String? aaa, [String? Function(String?, String?, String?) bbb, String? ccc])''',
    );

    var multiLine = methodElement.displayString(multiline: true);
    expect(multiLine, '''
String? longMethodName(
  String? aaa, [
  String? Function(String?, String?, String?) bbb,
  String? ccc,
])''');
  }

  test_maybeWriteTypeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = int;
A f() {
  throw 0;
}
''');
    var element = result.findElement.function('f');
    expect(element.displayString(preferTypeAlias: true), 'A f()');
  }

  test_maybeWriteTypeAlias_nullability_nonNullableAliasedType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = int;
A f1() {
  throw 0;
}
A? f2() {
  throw 0;
}
''');
    var f1 = result.findElement.function('f1');
    expect(f1.displayString(preferTypeAlias: true), 'A f1()');

    var f2 = result.findElement.function('f2');
    expect(f2.displayString(preferTypeAlias: true), 'A? f2()');
  }

  test_maybeWriteTypeAlias_nullability_nullableAliasedType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = int?;
A f1() {
  throw 0;
}
A? f2() {
  throw 0;
}
''');
    var f1 = result.findElement.function('f1');
    expect(f1.displayString(preferTypeAlias: true), 'A f1()');

    var f2 = result.findElement.function('f2');
    expect(f2.displayString(preferTypeAlias: true), 'A? f2()');
  }

  test_maybeWriteTypeAlias_typeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = List<T>;
A<int> f() {
  throw 0;
}
''');
    var element = result.findElement.function('f');
    expect(element.displayString(preferTypeAlias: true), 'A<int> f()');
  }

  test_property_getter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
String get a => '';
''');

    var element = result.findElement.topGet('a');
    expect(element.displayString(), 'String get a');
  }

  test_property_setter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
set a(String value) {}
''');

    var element = result.findElement.topSet('a');
    expect(element.displayString(), 'set a(String value)');
  }

  test_shortMethod() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  String? m(String? a, [String? b]);
}
''');

    var element = result.findElement.method('m');
    var singleLine = element.displayString();
    expect(singleLine, 'String? m(String? a, [String? b])');

    var multiLine = element.displayString(multiline: true);
    // The signature is short enough that it remains on one line even for
    // multiline: true.
    expect(multiLine, 'String? m(String? a, [String? b])');
  }

  test_writeClassElement_base() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
base class A {}
''');
    var element = result.findElement.class_('A');
    expect(element.displayString(), 'base class A');
  }

  test_writeClassElement_extends() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class B {}
class A extends B {}
''');
    var element = result.findElement.class_('A');
    expect(element.displayString(), 'class A extends B');
  }

  test_writeClassElement_final() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final class A {}
''');
    var element = result.findElement.class_('A');
    expect(element.displayString(), 'final class A');
  }

  test_writeClassElement_implements() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class B {}
class A implements B {}
''');
    var element = result.findElement.class_('A');
    expect(element.displayString(), 'class A implements B');
  }

  test_writeClassElement_interface() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
interface class A {}
''');
    var element = result.findElement.class_('A');
    expect(element.displayString(), 'interface class A');
  }

  test_writeClassElement_mixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
''');
    var element = result.findElement.class_('A');
    expect(element.displayString(), 'mixin class A');
  }

  test_writeClassElement_sealed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
sealed class A {}
''');
    var element = result.findElement.class_('A');
    expect(element.displayString(), 'sealed class A');
  }

  test_writeClassElement_superInterfaces() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class E {}
mixin W {}
class I {}
class A extends E with W implements I {}
''');
    var element = result.findElement.class_('A');
    expect(element.displayString(), 'class A extends E with W implements I');
  }

  test_writeClassElement_typeParameters() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T, S extends num>{}
''');
    var element = result.findElement.class_('A');
    expect(element.displayString(), 'class A<T, S extends num>');
  }

  test_writeClassElement_with() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin B {}
class A with B {}
''');
    var element = result.findElement.class_('A');
    expect(element.displayString(), 'class A with B');
  }

  test_writeConstructorElement_explicit_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final class A {
  A.named();
}
''');
    var element = result.findElement.constructor('named');
    expect(element.displayString(), 'A.named()');
  }

  test_writeConstructorElement_explicit_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final class A {
  A();
}
''');
    var element = result.findElement.unnamedConstructor('A');
    expect(element.displayString(), 'A()');
  }

  test_writeConstructorElement_formalParameters() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final class A {
  A(int a, bool b, {String? c});
}
''');
    var element = result.findElement.unnamedConstructor('A');
    expect(element.displayString(), 'A(int a, bool b, {String? c})');
  }

  test_writeConstructorElement_synthetic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final class A {}
''');
    var element = result.findElement.unnamedConstructor('A');
    expect(element.displayString(), 'A()');
  }

  test_writeDirectiveUri() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'src/f.dart';
//     ^^^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'src/f.dart'.
''');
    var import =
        result.findElement.libraryFragment.libraryImports[0]
            as LibraryImportImpl;
    expect(import.displayString(), "import package:test/src/f.dart");
  }

  test_writeDynamicElement() async {
    var element = DynamicElementImpl.instance;
    expect(element.displayString(), 'dynamic');
  }

  test_writeDynamicType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {}
''');
    var element = result.findElement.parameter('x');
    expect(element.displayString(), 'dynamic x');
  }

  test_writeEnumElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E {a, b}
''');
    var element = result.findElement.enum_('E');
    expect(element.displayString(), 'enum E');
  }

  test_writeEnumElement_implements() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
enum E implements A {a, b}
''');
    var element = result.findElement.enum_('E');
    expect(element.displayString(), 'enum E implements A');
  }

  test_writeEnumElement_mixin() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {}
enum E with M {a, b}
''');
    var element = result.findElement.enum_('E');
    expect(element.displayString(), 'enum E with M');
  }

  test_writeEnumElement_superInterfaces() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {}
class C {}
enum E with M implements C {a, b}
''');
    var element = result.findElement.enum_('E');
    expect(element.displayString(), 'enum E with M implements C');
  }

  test_writeEnumElement_typeParameters() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E<T> {a, b}
''');
    var element = result.findElement.enum_('E');
    expect(element.displayString(), 'enum E<T>');
  }

  test_writeFormalParameterElement_isNamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f({required int? a}){}
''');
    var element = result.findElement.parameter('a');
    expect(element.displayString(), '{required int? a}');
  }

  test_writeFormalParameterElement_isOptionalPositional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f([int? a]){}
''');
    var element = result.findElement.parameter('a');
    expect(element.displayString(), '[int? a]');
  }

  test_writeGenericFunctionTypeElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void Function(int a)? f;
''');
    var tf = result.findNode.singleGenericFunctionType.declaredFragment!;
    expect(tf.element.displayString(), 'void Function(int a)');
  }

  test_writeInvalidType() async {
    var result = await resolveTestCode(r'''
nonexistentType a;
''');
    var element = result.findElement.topVar('a');
    expect(element.displayString(), 'InvalidType a');
  }

  test_writeLabelElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  f: 0;
//^^
// [diag.unusedLabel] The label 'f' isn't used.
}
''');
    var element = result.findElement.label('f');
    expect(element.displayString(), 'f');
  }

  test_writeLibraryElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
library f;
''');
    var element = result.findElement.libraryElement;
    expect(element.displayString(), 'library package:test/test.dart');
  }

  test_writeLibraryExport() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
export 'src/f.dart';
//     ^^^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'src/f.dart'.
''');
    var export =
        result.findElement.libraryFragment.libraryExports.single
            as LibraryExportImpl;
    expect(export.displayString(), "export package:test/src/f.dart");
  }

  test_writeLibraryImport() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'src/f.dart';
//     ^^^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'src/f.dart'.
''');
    var import =
        result.findElement.libraryFragment.libraryImports[0]
            as LibraryImportImpl;
    expect(import.displayString(), "import package:test/src/f.dart");
  }

  test_writeLocalFunctionElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  void g() {}
//     ^
// [diag.unusedElement] The declaration 'g' isn't referenced.
}
''');
    var element = result.findElement.localFunction('g');
    expect(element.displayString(), "void g()");
  }

  test_writeLocalFunctionElement_formalParameters() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  void g(int a, bool b, {String? c}) {}
//     ^
// [diag.unusedElement] The declaration 'g' isn't referenced.
}
''');
    var element = result.findElement.localFunction('g');
    expect(element.displayString(), "void g(int a, bool b, {String? c})");
  }

  test_writeLocalFunctionElement_typeParameters() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  void g<T, S extends num>() {}
//     ^
// [diag.unusedElement] The declaration 'g' isn't referenced.
}
''');
    var element = result.findElement.localFunction('g');
    expect(element.displayString(), "void g<T, S extends num>()");
  }

  test_writeMixinElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M {}
''');
    var element = result.findElement.mixin('M');
    expect(element.displayString(), "mixin M on Object");
  }

  test_writeMixinElement_base() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
base mixin M {}
''');
    var element = result.findElement.mixin('M');
    expect(element.displayString(), "base mixin M on Object");
  }

  test_writeMixinElement_implements() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A{}
mixin M implements A {}
''');
    var element = result.findElement.mixin('M');
    expect(element.displayString(), "mixin M on Object implements A");
  }

  test_writeMixinElement_typeParameters() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M<T, S extends num> {}
''');
    var element = result.findElement.mixin('M');
    expect(element.displayString(), "mixin M<T, S extends num> on Object");
  }

  test_writeNeverElement() async {
    var element = NeverElementImpl.instance;
    expect(element.displayString(), "Never");
  }

  test_writeNeverType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
Never a;
//    ^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'a' must be initialized.
''');
    var element = result.findElement.topVar('a');
    expect(element.displayString(), "Never a");
  }

  test_writePartInclude() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
part 'src/f.dart';
//   ^^^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'package:test/src/f.dart'.
''');
    var element =
        result.findElement.libraryFragment.partIncludes.single
            as PartIncludeImpl;
    expect(element.displayString(), 'part package:test/src/f.dart');
  }

  test_writePrefixElement_multipleImports() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'src/f.dart' as a;
//     ^^^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'src/f.dart'.
import 'src/bar.dart' as a;
//     ^^^^^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'src/bar.dart'.
''');
    var prefix = result.findElement.prefix('a');
    expect(
      prefix.displayString(),
      "import 'src/f.dart' as a;\nimport 'src/bar.dart' as a;",
    );
  }

  test_writePrefixElement_singleImport() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'src/f.dart' as a;
//     ^^^^^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'src/f.dart'.
''');
    var prefix = result.findElement.prefix('a');
    expect(prefix.displayString(), "import 'src/f.dart' as a;");
  }

  test_writeRecordType_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = ({int a, String b});
''');
    var typeAlias = result.findElement.typeAlias('A');
    expect(typeAlias.displayString(), 'typedef A = ({int a, String b})');
  }

  test_writeRecordType_nullable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = (int, String)?;
''');
    var typeAlias = result.findElement.typeAlias('A');
    expect(typeAlias.displayString(), 'typedef A = (int, String)?');
  }

  test_writeRecordType_positional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = (int, String);
''');
    var typeAlias = result.findElement.typeAlias('A');
    expect(typeAlias.displayString(), 'typedef A = (int, String)');
  }

  test_writeRecordType_positionalAndNamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = (int, String, {bool flag});
''');
    var typeAlias = result.findElement.typeAlias('A');
    expect(typeAlias.displayString(), 'typedef A = (int, String, {bool flag})');
  }

  test_writeRecordType_singlePositional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = (int,);
''');
    var typeAlias = result.findElement.typeAlias('A');
    expect(typeAlias.displayString(), 'typedef A = (int,)');
  }

  test_writeSetterElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set f(int value) {}
}
''');
    var setter = result.findElement.setter('f');
    expect(setter.displayString(), 'set f(int value)');
  }

  test_writeTopLevelFunctionElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int f() => 0;
''');
    var function = result.findElement.topFunction('f');
    expect(function.displayString(), 'int f()');
  }

  test_writeTopLevelFunctionElement_formalParameters() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x, String y) {}
''');
    var function = result.findElement.topFunction('f');
    expect(function.displayString(), 'void f(int x, String y)');
  }

  test_writeTopLevelFunctionElement_typeParameters() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f<T, S extends num>() {}
''');
    var function = result.findElement.topFunction('f');
    expect(function.displayString(), 'void f<T, S extends num>()');
  }

  test_writeTypeAliasElement_withAliasedElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = int;
''');
    var typeAlias = result.findElement.typeAlias('A');
    expect(typeAlias.displayString(), 'typedef A = int');
  }

  test_writeTypeAliasElement_withAliasedElement_typeParameters() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = List<T>;
''');
    var typeAlias = result.findElement.typeAlias('A');
    expect(typeAlias.displayString(), 'typedef A<out T> = List<T>');
  }

  test_writeTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
Map<String, double> a = {'A': 1.5};
''');
    var element = result.findElement.topVar('a');
    expect(element.displayString(), 'Map<String, double> a');
  }

  test_writeTypeParameterElement() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f<T extends num>() {}
''');
    var element = result.findElement.typeParameter('T');
    expect(element.displayString(), 'T extends num');
  }

  test_writeTypeParameterElement_covariant() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<in T> {}
''');
    var elementA = result.findElement.typeParameter('T');
    expect(elementA.displayString(), 'in T');
  }

  test_writeTypeParameterType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f<T>(T t) {}
''');
    var typeAlias = result.findElement.parameter('t');
    expect(typeAlias.displayString(), 'T t');
  }

  test_writeTypeParameterType_promotedBound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f<T extends num>(T t) {
  if (t is int) {
    t;
  }
}
''');
    var type = result.findNode.simple('t;').staticType!;
    expect(type.getDisplayString(), 'T & int');
  }

  test_writeTypes() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
class C implements A, B {}
''');
    var element = result.findElement.class_('C');
    expect(element.displayString(), 'class C implements A, B');
  }
}
