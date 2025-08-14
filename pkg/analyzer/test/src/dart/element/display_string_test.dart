// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementDisplayStringTest);
  });
}

@reflectiveTest
class ElementDisplayStringTest extends PubPackageResolutionTest {
  test_class() async {
    await assertNoErrorsInCode(r'''
class A {}
abstract class B<T> extends A {}
''');

    var B = findElement2.class_('B');
    var displayString = B.displayString();
    expect(displayString, 'abstract class B<T> extends A');
  }

  test_extension_named() async {
    await assertNoErrorsInCode(r'''
extension StringExtension on String {}
''');

    var element = findElement2.extension_('StringExtension');
    var displayString = element.displayString();
    expect(displayString, 'extension StringExtension on String');
  }

  test_extension_unnamed() async {
    await assertNoErrorsInCode(r'''
extension on String {}
''');

    var element = result.libraryElement.extensions.single;
    var displayString = element.displayString();
    expect(displayString, 'extension on String');
  }

  test_extensionType() async {
    await assertNoErrorsInCode(r'''
extension type MyString<T>(String it) implements String {}
''');

    var element = findElement2.extensionType('MyString');
    var displayString = element.displayString();
    expect(
      displayString,
      'extension type MyString<T>(String it) implements String',
    );
  }

  test_longMethod() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  String? longMethodName(String? aaa, [String? bbb = 'a', String? ccc]);
}
''');

    var methodElement = findElement2.method('longMethodName');
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
    await assertNoErrorsInCode(r'''
abstract class A {
  String? longMethodName(
    String? aaa, 
    [String? Function(String?, String?, String?) bbb,
    String? ccc]
  );
}
''');

    var methodElement = findElement2.method('longMethodName');
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
    await assertNoErrorsInCode(r'''
typedef A = int;
A f() {
  throw 0;
}
''');
    var element = findElement2.function('f');
    expect(element.displayString(preferTypeAlias: true), 'A f()');
  }

  test_maybeWriteTypeAlias_nullable() async {
    await assertNoErrorsInCode(r'''
typedef A = int;
A? f() {
  throw 0;
}
''');
    var element = findElement2.function('f');
    expect(element.displayString(preferTypeAlias: true), 'A? f()');
  }

  test_maybeWriteTypeAlias_typeArguments() async {
    await assertNoErrorsInCode(r'''
typedef A<T> = List<T>;
A<int> f() {
  throw 0;
}
''');
    var element = findElement2.function('f');
    expect(element.displayString(preferTypeAlias: true), 'A<int> f()');
  }

  test_property_getter() async {
    await assertNoErrorsInCode(r'''
String get a => '';
''');

    var element = findElement2.topGet('a');
    expect(element.displayString(), 'String get a');
  }

  test_property_setter() async {
    await assertNoErrorsInCode(r'''
set a(String value) {}
''');

    var element = findElement2.topSet('a');
    expect(element.displayString(), 'set a(String value)');
  }

  test_shortMethod() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  String? m(String? a, [String? b]);
}
''');

    var element = findElement2.method('m');
    var singleLine = element.displayString();
    expect(singleLine, 'String? m(String? a, [String? b])');

    var multiLine = element.displayString(multiline: true);
    // The signature is short enough that it remains on one line even for
    // multiline: true.
    expect(multiLine, 'String? m(String? a, [String? b])');
  }

  test_writeClassElement_base() async {
    await assertNoErrorsInCode(r'''
base class A {}
''');
    var element = findElement2.class_('A');
    expect(element.displayString(), 'base class A');
  }

  test_writeClassElement_extends() async {
    await assertNoErrorsInCode(r'''
class B {}
class A extends B {}
''');
    var element = findElement2.class_('A');
    expect(element.displayString(), 'class A extends B');
  }

  test_writeClassElement_final() async {
    await assertNoErrorsInCode(r'''
final class A {}
''');
    var element = findElement2.class_('A');
    expect(element.displayString(), 'final class A');
  }

  test_writeClassElement_implements() async {
    await assertNoErrorsInCode(r'''
class B {}
class A implements B {}
''');
    var element = findElement2.class_('A');
    expect(element.displayString(), 'class A implements B');
  }

  test_writeClassElement_interface() async {
    await assertNoErrorsInCode(r'''
interface class A {}
''');
    var element = findElement2.class_('A');
    expect(element.displayString(), 'interface class A');
  }

  test_writeClassElement_mixin() async {
    await assertNoErrorsInCode(r'''
mixin class A {}
''');
    var element = findElement2.class_('A');
    expect(element.displayString(), 'mixin class A');
  }

  test_writeClassElement_sealed() async {
    await assertNoErrorsInCode(r'''
sealed class A {}
''');
    var element = findElement2.class_('A');
    expect(element.displayString(), 'sealed class A');
  }

  test_writeClassElement_superInterfaces() async {
    await assertNoErrorsInCode(r'''
class E {}
mixin W {}
class I {}
class A extends E with W implements I {}
''');
    var element = findElement2.class_('A');
    expect(element.displayString(), 'class A extends E with W implements I');
  }

  test_writeClassElement_typeParameters() async {
    await assertNoErrorsInCode(r'''
class A<T, S extends num>{}
''');
    var element = findElement2.class_('A');
    expect(element.displayString(), 'class A<T, S extends num>');
  }

  test_writeClassElement_with() async {
    await assertNoErrorsInCode(r'''
mixin B {}
class A with B {}
''');
    var element = findElement2.class_('A');
    expect(element.displayString(), 'class A with B');
  }

  test_writeConstructorElement_explicit_named() async {
    await assertNoErrorsInCode(r'''
final class A {
  A.named();
}
''');
    var element = findElement2.constructor('named');
    expect(element.displayString(), 'A.named()');
  }

  test_writeConstructorElement_explicit_unnamed() async {
    await assertNoErrorsInCode(r'''
final class A {
  A();
}
''');
    var element = findElement2.unnamedConstructor('A');
    expect(element.displayString(), 'A()');
  }

  test_writeConstructorElement_formalParameters() async {
    await assertNoErrorsInCode(r'''
final class A {
  A(int a, bool b, {String? c});
}
''');
    var element = findElement2.unnamedConstructor('A');
    expect(element.displayString(), 'A(int a, bool b, {String? c})');
  }

  test_writeConstructorElement_synthetic() async {
    await assertNoErrorsInCode(r'''
final class A {}
''');
    var element = findElement2.unnamedConstructor('A');
    expect(element.displayString(), 'A()');
  }

  test_writeDirectiveUri() async {
    await assertErrorsInCode(
      r'''
import 'src/f.dart';
''',
      [error(CompileTimeErrorCode.uriDoesNotExist, 7, 12)],
    );
    var import =
        findElement2.libraryFragment.libraryImports[0] as LibraryImportImpl;
    expect(import.displayString(), "import package:test/src/f.dart");
  }

  test_writeDynamicElement() async {
    var element = DynamicElementImpl.instance;
    expect(element.displayString(), 'dynamic');
  }

  test_writeDynamicType() async {
    await assertNoErrorsInCode(r'''
void f(x) {}
''');
    var element = findElement2.parameter('x');
    expect(element.displayString(), 'dynamic x');
  }

  test_writeEnumElement() async {
    await assertNoErrorsInCode(r'''
enum E {a, b}
''');
    var element = findElement2.enum_('E');
    expect(element.displayString(), 'enum E');
  }

  test_writeEnumElement_implements() async {
    await assertNoErrorsInCode(r'''
class A {}
enum E implements A {a, b}
''');
    var element = findElement2.enum_('E');
    expect(element.displayString(), 'enum E implements A');
  }

  test_writeEnumElement_mixin() async {
    await assertNoErrorsInCode(r'''
mixin M {}
enum E with M {a, b}
''');
    var element = findElement2.enum_('E');
    expect(element.displayString(), 'enum E with M');
  }

  test_writeEnumElement_superInterfaces() async {
    await assertNoErrorsInCode(r'''
mixin M {}
class C {}
enum E with M implements C {a, b}
''');
    var element = findElement2.enum_('E');
    expect(element.displayString(), 'enum E with M implements C');
  }

  test_writeEnumElement_typeParameters() async {
    await assertNoErrorsInCode(r'''
enum E<T> {a, b}
''');
    var element = findElement2.enum_('E');
    expect(element.displayString(), 'enum E<T>');
  }

  test_writeFormalParameterElement_isNamed() async {
    await assertNoErrorsInCode(r'''
void f({required int? a}){}
''');
    var element = findElement2.parameter('a');
    expect(element.displayString(), '{required int? a}');
  }

  test_writeFormalParameterElement_isOptionalPositional() async {
    await assertNoErrorsInCode(r'''
void f([int? a]){}
''');
    var element = findElement2.parameter('a');
    expect(element.displayString(), '[int? a]');
  }

  test_writeGenericFunctionTypeElement() async {
    await assertNoErrorsInCode(r'''
void Function(int a)? f;
''');
    var tf = findNode.singleGenericFunctionType.declaredFragment!;
    expect(tf.element.displayString(), 'void Function(int a)');
  }

  test_writeInvalidType() async {
    await resolveTestCode(r'''
nonexistentType a;
''');
    var element = findElement2.topVar('a');
    expect(element.displayString(), 'InvalidType a');
  }

  test_writeLabelElement() async {
    await assertErrorsInCode(
      r'''
void f() {
  f: 0;
}
''',
      [error(WarningCode.unusedLabel, 13, 2)],
    );
    var element = findElement2.label('f');
    expect(element.displayString(), 'f');
  }

  test_writeLibraryElement() async {
    await assertNoErrorsInCode(r'''
library f;
''');
    var element = findElement2.libraryElement;
    expect(element.displayString(), 'library package:test/test.dart');
  }

  test_writeLibraryExport() async {
    await assertErrorsInCode(
      r'''
export 'src/f.dart';
''',
      [error(CompileTimeErrorCode.uriDoesNotExist, 7, 12)],
    );
    var export =
        findElement2.libraryFragment.libraryExports.single as LibraryExportImpl;
    expect(export.displayString(), "export package:test/src/f.dart");
  }

  test_writeLibraryImport() async {
    await assertErrorsInCode(
      r'''
import 'src/f.dart';
''',
      [error(CompileTimeErrorCode.uriDoesNotExist, 7, 12)],
    );
    var import =
        findElement2.libraryFragment.libraryImports[0] as LibraryImportImpl;
    expect(import.displayString(), "import package:test/src/f.dart");
  }

  test_writeLocalFunctionElement() async {
    await assertErrorsInCode(
      r'''
void f() {
  void g() {}
}
''',
      [error(WarningCode.unusedElement, 18, 1)],
    );
    var element = findElement2.localFunction('g');
    expect(element.displayString(), "void g()");
  }

  test_writeLocalFunctionElement_formalParameters() async {
    await assertErrorsInCode(
      r'''
void f() {
  void g(int a, bool b, {String? c}) {}
}
''',
      [error(WarningCode.unusedElement, 18, 1)],
    );
    var element = findElement2.localFunction('g');
    expect(element.displayString(), "void g(int a, bool b, {String? c})");
  }

  test_writeLocalFunctionElement_typeParameters() async {
    await assertErrorsInCode(
      r'''
void f() {
  void g<T, S extends num>() {}
}
''',
      [error(WarningCode.unusedElement, 18, 1)],
    );
    var element = findElement2.localFunction('g');
    expect(element.displayString(), "void g<T, S extends num>()");
  }

  test_writeMixinElement() async {
    await assertNoErrorsInCode(r'''
mixin M {}
''');
    var element = findElement2.mixin('M');
    expect(element.displayString(), "mixin M on Object");
  }

  test_writeMixinElement_base() async {
    await assertNoErrorsInCode(r'''
base mixin M {}
''');
    var element = findElement2.mixin('M');
    expect(element.displayString(), "base mixin M on Object");
  }

  test_writeMixinElement_implements() async {
    await assertNoErrorsInCode(r'''
class A{}
mixin M implements A {}
''');
    var element = findElement2.mixin('M');
    expect(element.displayString(), "mixin M on Object implements A");
  }

  test_writeMixinElement_typeParameters() async {
    await assertNoErrorsInCode(r'''
mixin M<T, S extends num> {}
''');
    var element = findElement2.mixin('M');
    expect(element.displayString(), "mixin M<T, S extends num> on Object");
  }

  test_writeNeverElement() async {
    var element = NeverElementImpl.instance;
    expect(element.displayString(), "Never");
  }

  test_writeNeverType() async {
    await assertErrorsInCode(
      r'''
Never a;
''',
      [error(CompileTimeErrorCode.notInitializedNonNullableVariable, 6, 1)],
    );
    var element = findElement2.topVar('a');
    expect(element.displayString(), "Never a");
  }

  test_writePartInclude() async {
    await assertErrorsInCode(
      r'''
part 'src/f.dart';
''',
      [error(CompileTimeErrorCode.uriDoesNotExist, 5, 12)],
    );
    var element =
        findElement2.libraryFragment.partIncludes.single as PartIncludeImpl;
    expect(element.displayString(), 'part package:test/src/f.dart');
  }

  test_writePrefixElement_multipleImports() async {
    await assertErrorsInCode(
      r'''
import 'src/f.dart' as a;
import 'src/bar.dart' as a;
''',
      [
        error(CompileTimeErrorCode.uriDoesNotExist, 7, 12),
        error(CompileTimeErrorCode.uriDoesNotExist, 33, 14),
      ],
    );
    var prefix = findElement2.prefix('a');
    expect(
      prefix.displayString(),
      "import 'src/f.dart' as a;\nimport 'src/bar.dart' as a;",
    );
  }

  test_writePrefixElement_singleImport() async {
    await assertErrorsInCode(
      r'''
import 'src/f.dart' as a;
''',
      [error(CompileTimeErrorCode.uriDoesNotExist, 7, 12)],
    );
    var prefix = findElement2.prefix('a');
    expect(prefix.displayString(), "import 'src/f.dart' as a;");
  }

  test_writeRecordType_named() async {
    await assertNoErrorsInCode(r'''
typedef A = ({int a, String b});
''');
    var typeAlias = findElement2.typeAlias('A');
    expect(typeAlias.displayString(), 'typedef A = ({int a, String b})');
  }

  test_writeRecordType_nullable() async {
    await assertNoErrorsInCode(r'''
typedef A = (int, String)?;
''');
    var typeAlias = findElement2.typeAlias('A');
    expect(typeAlias.displayString(), 'typedef A = (int, String)?');
  }

  test_writeRecordType_positional() async {
    await assertNoErrorsInCode(r'''
typedef A = (int, String);
''');
    var typeAlias = findElement2.typeAlias('A');
    expect(typeAlias.displayString(), 'typedef A = (int, String)');
  }

  test_writeRecordType_positionalAndNamed() async {
    await assertNoErrorsInCode(r'''
typedef A = (int, String, {bool flag});
''');
    var typeAlias = findElement2.typeAlias('A');
    expect(typeAlias.displayString(), 'typedef A = (int, String, {bool flag})');
  }

  test_writeRecordType_singlePositional() async {
    await assertNoErrorsInCode(r'''
typedef A = (int,);
''');
    var typeAlias = findElement2.typeAlias('A');
    expect(typeAlias.displayString(), 'typedef A = (int,)');
  }

  test_writeSetterElement() async {
    await assertNoErrorsInCode(r'''
class A {
  set f(int value) {}
}
''');
    var setter = findElement2.setter('f');
    expect(setter.displayString(), 'set f(int value)');
  }

  test_writeTopLevelFunctionElement() async {
    await assertNoErrorsInCode(r'''
int f() => 0;
''');
    var function = findElement2.topFunction('f');
    expect(function.displayString(), 'int f()');
  }

  test_writeTopLevelFunctionElement_formalParameters() async {
    await assertNoErrorsInCode(r'''
void f(int x, String y) {}
''');
    var function = findElement2.topFunction('f');
    expect(function.displayString(), 'void f(int x, String y)');
  }

  test_writeTopLevelFunctionElement_typeParameters() async {
    await assertNoErrorsInCode(r'''
void f<T, S extends num>() {}
''');
    var function = findElement2.topFunction('f');
    expect(function.displayString(), 'void f<T, S extends num>()');
  }

  test_writeTypeAliasElement_withAliasedElement() async {
    await assertNoErrorsInCode(r'''
typedef A = int;
''');
    var typeAlias = findElement2.typeAlias('A');
    expect(typeAlias.displayString(), 'typedef A = int');
  }

  test_writeTypeAliasElement_withAliasedElement_typeParameters() async {
    await assertNoErrorsInCode(r'''
typedef A<T> = List<T>;
''');
    var typeAlias = findElement2.typeAlias('A');
    expect(typeAlias.displayString(), 'typedef A<out T> = List<T>');
  }

  test_writeTypeArguments() async {
    await assertNoErrorsInCode(r'''
Map<String, double> a = {'A': 1.5};
''');
    var element = findElement2.topVar('a');
    expect(element.displayString(), 'Map<String, double> a');
  }

  test_writeTypeParameterElement() async {
    await assertNoErrorsInCode(r'''
void f<T extends num>() {}
''');
    var element = findElement2.typeParameter('T');
    expect(element.displayString(), 'T extends num');
  }

  test_writeTypeParameterElement_covariant() async {
    await assertNoErrorsInCode(r'''
class A<in T> {}
''');
    var elementA = findElement2.typeParameter('T');
    expect(elementA.displayString(), 'in T');
  }

  test_writeTypeParameterType() async {
    await assertNoErrorsInCode(r'''
void f<T>(T t) {}
''');
    var typeAlias = findElement2.parameter('t');
    expect(typeAlias.displayString(), 'T t');
  }

  test_writeTypeParameterType_promotedBound() async {
    await assertNoErrorsInCode(r'''
void f<T extends num>(T t) {
  if (t is int) {
    t;
  }
}
''');
    var type = findNode.simple('t;').staticType!;
    expect(type.getDisplayString(), 'T & int');
  }

  test_writeTypes() async {
    await assertNoErrorsInCode(r'''
class A {}
class B {}
class C implements A, B {}
''');
    var element = findElement2.class_('C');
    expect(element.displayString(), 'class C implements A, B');
  }
}
