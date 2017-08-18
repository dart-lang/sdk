// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/sdk/patch.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkPatcherTest);
  });
}

@reflectiveTest
class SdkPatcherTest {
  MemoryResourceProvider provider = new MemoryResourceProvider();
  Folder sdkFolder;
  FolderBasedDartSdk sdk;

  SdkPatcher patcher = new SdkPatcher();
  RecordingErrorListener listener = new RecordingErrorListener();

  void setUp() {
    sdkFolder = provider.getFolder(_p('/sdk'));
  }

  test_class_constructor_append_fail_notPrivate_named() {
    expect(() {
      _doTopLevelPatching(r'''
class C {}
''', r'''
@patch
class C {
  C.named() {}
}
''');
    }, throwsArgumentError);
  }

  test_class_constructor_append_fail_notPrivate_unnamed() {
    expect(() {
      _doTopLevelPatching(r'''
class C {}
''', r'''
@patch
class C {
  C() {}
}
''');
    }, throwsArgumentError);
  }

  test_class_constructor_append_named() {
    CompilationUnit unit = _doTopLevelPatching(r'''
class C {
}
''', r'''
@patch
class C {
  C._named() {}
}
''');
    _assertUnitCode(unit, 'class C {C._named() {}}');
    ClassDeclaration clazz = unit.declarations[0];
    ConstructorDeclaration constructor = clazz.members[0];
    _assertPrevNextToken(clazz.leftBracket, constructor.beginToken);
    _assertPrevNextToken(constructor.endToken, clazz.rightBracket);
  }

  test_class_constructor_append_unnamed() {
    CompilationUnit unit = _doTopLevelPatching(r'''
class _C {
}
''', r'''
@patch
class _C {
  _C() {}
}
''');
    _assertUnitCode(unit, 'class _C {_C() {}}');
    ClassDeclaration clazz = unit.declarations[0];
    ConstructorDeclaration constructor = clazz.members[0];
    _assertPrevNextToken(clazz.leftBracket, constructor.beginToken);
    _assertPrevNextToken(constructor.endToken, clazz.rightBracket);
  }

  test_class_constructor_patch() {
    CompilationUnit unit = _doTopLevelPatching(r'''
class C {
  external C.named();
}
''', r'''
@patch
class C {
  @patch
  C.named() {
    print(42);
  }
}
''');
    _assertUnitCode(unit, 'class C {C.named() {print(42);}}');
    ClassDeclaration clazz = unit.declarations[0];
    ConstructorDeclaration constructor = clazz.members[0];
    expect(constructor.externalKeyword, isNull);
    _assertPrevNextToken(
        constructor.parameters.endToken, constructor.body.beginToken);
    _assertPrevNextToken(constructor.endToken, clazz.rightBracket);
  }

  test_class_constructor_patch_fail_baseFactory_patchGenerative() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  external factory C.named();
}
''', r'''
@patch
class C {
  @patch
  C.named() {}
}
''');
    }, throwsArgumentError);
  }

  test_class_constructor_patch_fail_baseGenerative_patchFactory() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  external C.named();
}
''', r'''
@patch
class C {
  @patch
  factory C.named() {}
}
''');
    }, throwsArgumentError);
  }

  test_class_constructor_patch_fail_fieldFormalParam_inBase() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  int f;
  external C.named(this.f);
}
''', r'''
@patch
class C {
  @patch
  C.named() : f = 2 {}
}
''');
    }, throwsArgumentError);
  }

  test_class_constructor_patch_fail_fieldFormalParam_inPatch() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  int f;
  external C.named(int f);
}
''', r'''
@patch
class C {
  @patch
  C.named(this.f) {}
}
''');
    }, throwsArgumentError);
  }

  test_class_constructor_patch_fail_fieldFormalParam_inPatchAndBase() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  int f;
  external C.named(this.f);
}
''', r'''
@patch
class C {
  @patch
  C.named(this.f) {}
}
''');
    }, throwsArgumentError);
  }

  test_class_constructor_patch_fail_hasInitializers() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  int f;
  external C.named() : f = 1;
}
''', r'''
@patch
class C {
  @patch
  C.named() : f = 2 {}
}
''');
    }, throwsArgumentError);
  }

  test_class_constructor_patch_fail_noExternalKeyword() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  C.named();
}
''', r'''
@patch
class C {
  @patch
  C.named() {}
}
''');
    }, throwsArgumentError);
  }

  test_class_constructor_patch_fail_signatureChange() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  external C.named(int x);
}
''', r'''
@patch
class C {
  @patch
  C.named(double x) {}
}
''');
    }, throwsArgumentError);
  }

  test_class_constructor_patch_fail_signatureChange_nameOnly() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  external C.named(int x);
}
''', r'''
@patch
class C {
  @patch
  C.named(int y) {}
}
''');
    }, throwsArgumentError);
  }

  test_class_constructor_patch_initializers() {
    CompilationUnit unit = _doTopLevelPatching(r'''
class C {
  int f;
  external C.named();
}
''', r'''
@patch
class C {
  @patch
  C.named() : f = 2 {
    print(42);
  }
}
''');
    _assertUnitCode(unit, 'class C {int f; C.named() : f = 2 {print(42);}}');
    ClassDeclaration clazz = unit.declarations[0];
    ConstructorDeclaration constructor = clazz.members[1];
    expect(constructor.externalKeyword, isNull);
    _assertPrevNextToken(constructor.parameters.endToken,
        constructor.initializers.beginToken.previous);
    _assertPrevNextToken(constructor.endToken, clazz.rightBracket);
  }

  test_class_field_append() {
    CompilationUnit unit = _doTopLevelPatching(r'''
class C {
  void a() {}
}
''', r'''
@patch
class C {
  int _b = 42;
}
''');
    _assertUnitCode(unit, 'class C {void a() {} int _b = 42;}');
    ClassDeclaration clazz = unit.declarations[0];
    MethodDeclaration a = clazz.members[0];
    FieldDeclaration b = clazz.members[1];
    _assertPrevNextToken(a.endToken, b.beginToken);
    _assertPrevNextToken(b.endToken, clazz.rightBracket);
  }

  test_class_field_append_fail_moreThanOne() {
    expect(() {
      _doTopLevelPatching(r'''
class A {}
''', r'''
@patch
class A {
  @patch
  int _f1, _f2;
}
''');
    }, throwsArgumentError);
  }

  test_class_field_append_fail_notPrivate() {
    expect(() {
      _doTopLevelPatching(r'''
class A {}
''', r'''
@patch
class A {
  @patch
  int b;
}
''');
    }, throwsArgumentError);
  }

  test_class_field_append_publicInPrivateClass() {
    CompilationUnit unit = _doTopLevelPatching(r'''
class _C {
  void a() {}
}
''', r'''
@patch
class _C {
  int b = 42;
}
''');
    _assertUnitCode(unit, 'class _C {void a() {} int b = 42;}');
    ClassDeclaration clazz = unit.declarations[0];
    MethodDeclaration a = clazz.members[0];
    FieldDeclaration b = clazz.members[1];
    _assertPrevNextToken(a.endToken, b.beginToken);
    _assertPrevNextToken(b.endToken, clazz.rightBracket);
  }

  test_class_field_patch_fail() {
    expect(() {
      _doTopLevelPatching(r'''
class A {}
''', r'''
@patch
class A {
  @patch
  int _f;
}
''');
    }, throwsArgumentError);
  }

  test_class_getter_append() {
    CompilationUnit unit = _doTopLevelPatching(r'''
class C {
  void a() {}
}
''', r'''
@patch
class C {
  int get _b => 2;
}
''');
    _assertUnitCode(unit, 'class C {void a() {} int get _b => 2;}');
  }

  test_class_method_append() {
    CompilationUnit unit = _doTopLevelPatching(r'''
class C {
  void a() {}
}
''', r'''
@patch
class C {
  void _b() {}
  void _c() {}
}
''');
    _assertUnitCode(unit, 'class C {void a() {} void _b() {} void _c() {}}');
    ClassDeclaration clazz = unit.declarations[0];
    MethodDeclaration a = clazz.members[0];
    MethodDeclaration b = clazz.members[1];
    MethodDeclaration c = clazz.members[2];
    _assertPrevNextToken(a.endToken, b.beginToken);
    _assertPrevNextToken(b.endToken, c.beginToken);
    _assertPrevNextToken(c.endToken, clazz.rightBracket);
  }

  test_class_method_fail_notPrivate() {
    expect(() {
      _doTopLevelPatching(r'''
class A {}
''', r'''
@patch
class A {
  void m() {}
}
''');
    }, throwsArgumentError);
  }

  test_class_method_patch() {
    CompilationUnit unit = _doTopLevelPatching(r'''
class C {
  external int m();
}
''', r'''
@patch
class C {
  @patch
  int m() => 42;
}
''');
    _assertUnitCode(unit, 'class C {int m() => 42;}');
    ClassDeclaration clazz = unit.declarations[0];
    MethodDeclaration m = clazz.members[0];
    expect(m.externalKeyword, isNull);
    _assertPrevNextToken(m.parameters.rightParenthesis, m.body.beginToken);
    _assertPrevNextToken(m.body.endToken, clazz.rightBracket);
  }

  test_class_method_patch_fail_noExternalKeyword() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  int m();
}
''', r'''
@patch
class C {
  @patch
  int m() => 42;
}
''');
    }, throwsArgumentError);
  }

  test_class_method_patch_fail_signatureChange() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  external void f(int x);
}
''', r'''
@patch
class C {
  @patch
  void f(double x) {}
}
''');
    }, throwsArgumentError);
  }

  test_class_method_patch_fail_signatureChange_extraArgument() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  external void f();
}
''', r'''
@patch
class C {
  @patch
  void f(int x) {}
}
''');
    }, throwsArgumentError);
  }

  test_class_method_patch_fail_signatureChange_extraTypeTokens() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  external List f();
}
''', r'''
@patch
class C {
  @patch
  List<int> f() => null;
}
''');
    }, throwsArgumentError);
  }

  test_class_method_patch_fail_signatureChange_functionTypedParam_paramType() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  external void f(void x(int y));
}
''', r'''
@patch
class C {
  @patch
  void f(void x(double y)) {}
}
''');
    }, throwsArgumentError);
  }

  test_class_method_patch_fail_signatureChange_functionTypedParam_returnType() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  external void f(int x());
}
''', r'''
@patch
class C {
  @patch
  void f(double x()) {}
}
''');
    }, throwsArgumentError);
  }

  test_class_method_patch_fail_signatureChange_makeReturnTypeExplicit() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  external f();
}
''', r'''
@patch
class C {
  @patch
  int f() => 0;
}
''');
    }, throwsArgumentError);
  }

  test_class_method_patch_fail_signatureChange_missingArgument() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  external void f(int x);
}
''', r'''
@patch
class C {
  @patch
  void f() {}
}
''');
    }, throwsArgumentError);
  }

  test_class_method_patch_fail_signatureChange_missingTypeTokens() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  external List<int> f();
}
''', r'''
@patch
class C {
  @patch
  List f() => null;
}
''');
    }, throwsArgumentError);
  }

  test_class_method_patch_fail_signatureChange_nameOnly() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  external void f(int x);
}
''', r'''
@patch
class C {
  @patch
  void f(int y) {}
}
''');
    }, throwsArgumentError);
  }

  test_class_method_patch_fail_signatureChange_returnTypeOnly() {
    expect(() {
      _doTopLevelPatching(r'''
class C {
  external void f(int x);
}
''', r'''
@patch
class C {
  @patch
  int f(int x) {}
}
''');
    }, throwsArgumentError);
  }

  test_class_method_patch_success_defaultFormalParameter() {
    CompilationUnit unit = _doTopLevelPatching(r'''
class C {
  external void f(int x = 0);
}
''', r'''
@patch
class C {
  @patch
  void f(int x) {}
}
''');
    ClassDeclaration cls = unit.declarations[0];
    MethodDeclaration method = cls.members[0];
    FormalParameter parameter = method.parameters.parameters[0];
    expect(parameter, new isInstanceOf<DefaultFormalParameter>());
  }

  test_class_method_patch_success_implicitReturnType() {
    _doTopLevelPatching(r'''
class C {
  external f();
}
''', r'''
@patch
class C {
  @patch
  f() => null;
}
''');
  }

  test_class_method_patch_success_multiTokenReturnType() {
    _doTopLevelPatching(r'''
class C {
  external List<int> f();
}
''', r'''
@patch
class C {
  @patch
  List<int> f() => null;
}
''');
  }

  test_class_method_patch_success_signatureChange_functionTypedParam_matching() {
    _doTopLevelPatching(r'''
class C {
  external void f(void x(int y));
}
''', r'''
@patch
class C {
  @patch
  void f(void x(int y)) {}
}
''');
  }

  test_class_setter_append() {
    CompilationUnit unit = _doTopLevelPatching(r'''
class C {
  void a() {}
}
''', r'''
@patch
class C {
  void set _b(_) {}
}
''');
    _assertUnitCode(unit, 'class C {void a() {} void set _b(_) {}}');
  }

  test_directive_fail_export() {
    expect(() {
      _doTopLevelPatching(r'''
import 'a.dart';
''', r'''
export 'c.dart';
''');
    }, throwsArgumentError);
  }

  test_directive_import() {
    CompilationUnit unit = _doTopLevelPatching(r'''
import 'a.dart';
part 'b.dart';
int bar() => 0;
''', r'''
import 'c.dart';
''');
    _assertUnitCode(unit,
        "import 'a.dart'; part 'b.dart'; import 'c.dart'; int bar() => 0;");
  }

  test_fail_patchFileDoesNotExist() {
    expect(() {
      _setSdkLibraries(r'''
final Map<String, LibraryInfo> LIBRARIES = const <String, LibraryInfo> {
  'test' : const LibraryInfo(
    'test/test.dart'),
};''');
      _createSdk();
      var patchPaths = {
        'dart:test': [_p('/sdk/lib/does_not_exist.dart')]
      };
      File file = provider.newFile(_p('/sdk/lib/test/test.dart'), '');
      Source source = file.createSource(Uri.parse('dart:test'));
      CompilationUnit unit = SdkPatcher.parse(source, true, listener);
      patcher.patch(provider, true, patchPaths, listener, source, unit);
    }, throwsArgumentError);
  }

  test_internal_allowNewPublicNames() {
    _setSdkLibraries(r'''
final Map<String, LibraryInfo> LIBRARIES = const <String, LibraryInfo> {
  '_internal' : const LibraryInfo(
    'internal/internal.dart'),
};''');
    var patchPaths = {
      'dart:_internal': [_p('/sdk/lib/internal/internal_patch.dart')]
    };
    File file = provider.newFile(_p('/sdk/lib/internal/internal.dart'), r'''
library dart._internal;
class A {}
class B {
  B();
}
''');
    provider.newFile(_p('/sdk/lib/internal/internal_patch.dart'), r'''
@patch
class B {
  int newField;
  B.newConstructor();
  int newMethod() => 1;
}
class NewClass {}
int newFunction() => 2;
''');

    _createSdk();

    Source source = file.createSource(Uri.parse('dart:_internal'));
    CompilationUnit unit = SdkPatcher.parse(source, true, listener);
    patcher.patch(provider, true, patchPaths, listener, source, unit);
    _assertUnitCode(
        unit,
        'library dart._internal; class A {} '
        'class B {B(); int newField; B.newConstructor(); int newMethod() => 1;} '
        'class NewClass {} int newFunction() => 2;');
  }

  test_part() {
    String baseLibCode = r'''
library test;
part 'test_part.dart';
class A {}
''';
    String basePartCode = r'''
part of test;
class B {}
''';
    _setSdkLibraries(r'''
final Map<String, LibraryInfo> LIBRARIES = const <String, LibraryInfo> {
  'test' : const LibraryInfo(
    'test/test.dart',
    patches: {VM_PLATFORM: ['test/test_patch.dart']}),
};''');
    var patchPaths = {
      'dart:test': [_p('/sdk/lib/test/test_patch.dart')]
    };
    File fileLib = provider.newFile(_p('/sdk/lib/test/test.dart'), baseLibCode);
    File filePart =
        provider.newFile(_p('/sdk/lib/test/test_part.dart'), basePartCode);
    provider.newFile(_p('/sdk/lib/test/test_patch.dart'), r'''
import 'foo.dart';

@patch
class A {
  int _a() => 1;
}

@patch
class B {
  int _b() => 1;
}

class _C {}
''');

    _createSdk();

    {
      Uri uri = Uri.parse('dart:test');
      Source source = fileLib.createSource(uri);
      CompilationUnit unit = SdkPatcher.parse(source, true, listener);
      patcher.patch(provider, true, patchPaths, listener, source, unit);
      _assertUnitCode(
          unit,
          "library test; part 'test_part.dart'; import 'foo.dart'; "
          "class A {int _a() => 1;} class _C {}");
    }

    {
      Uri uri = Uri.parse('dart:test/test_part.dart');
      Source source = filePart.createSource(uri);
      CompilationUnit unit = SdkPatcher.parse(source, true, listener);
      patcher.patch(provider, true, patchPaths, listener, source, unit);
      _assertUnitCode(unit, "part of test; class B {int _b() => 1;}");
    }
  }

  test_topLevel_class_append() {
    CompilationUnit unit = _doTopLevelPatching(r'''
class A {}
''', r'''
class _B {
  void mmm() {}
}
''');
    _assertUnitCode(unit, 'class A {} class _B {void mmm() {}}');
    ClassDeclaration a = unit.declarations[0];
    ClassDeclaration b = unit.declarations[1];
    _assertPrevNextToken(a.endToken, b.beginToken);
  }

  test_topLevel_class_fail_mixinApplication() {
    expect(() {
      _doTopLevelPatching(r'''
class A {}
''', r'''
class _B {}
class _C = Object with _B;
''');
    }, throwsArgumentError);
  }

  test_topLevel_class_fail_notPrivate() {
    expect(() {
      _doTopLevelPatching(r'''
class A {}
''', r'''
class B {}
''');
    }, throwsArgumentError);
  }

  test_topLevel_function_append() {
    CompilationUnit unit = _doTopLevelPatching(r'''
int foo() => 0;
''', r'''
int _bar1() => 1;
int _bar2() => 2;
''');
    _assertUnitCode(
        unit, 'int foo() => 0; int _bar1() => 1; int _bar2() => 2;');

    FunctionDeclaration foo = unit.declarations[0];
    FunctionDeclaration bar1 = unit.declarations[1];
    FunctionDeclaration bar2 = unit.declarations[2];

    _assertPrevNextToken(foo.endToken, bar1.beginToken);
    _assertPrevNextToken(bar1.endToken, bar2.beginToken);
  }

  test_topLevel_function_fail_noExternalKeyword() {
    expect(() {
      _doTopLevelPatching(r'''
int foo();
''', r'''
@patch
int foo() => 1;
''');
    }, throwsArgumentError);
  }

  test_topLevel_function_fail_notPrivate() {
    expect(() {
      _doTopLevelPatching(r'''
int foo() => 1;
''', r'''
int bar() => 2;
''');
    }, throwsArgumentError);
  }

  test_topLevel_functionTypeAlias_append() {
    CompilationUnit unit = _doTopLevelPatching(r'''
int foo() => 0;
''', r'''
typedef int _bar1();
typedef int _bar2();
''');
    _assertUnitCode(
        unit, 'int foo() => 0; typedef int _bar1(); typedef int _bar2();');

    FunctionDeclaration foo = unit.declarations[0];
    FunctionTypeAlias bar1 = unit.declarations[1];
    FunctionTypeAlias bar2 = unit.declarations[2];

    _assertPrevNextToken(foo.endToken, bar1.beginToken);
    _assertPrevNextToken(bar1.endToken, bar2.beginToken);
    expect(unit.endToken.type, TokenType.EOF);
    expect(bar2.endToken.next, same(unit.endToken));
  }

  test_topLevel_functionTypeAlias_fail_hasAnnotation() {
    expect(() {
      _doTopLevelPatching(r'''
int foo() => 0;
''', r'''
@patch
typedef int _bar();
''');
    }, throwsArgumentError);
  }

  test_topLevel_functionTypeAlias_fail_notPrivate() {
    expect(() {
      _doTopLevelPatching(r'''
int foo() => 0;
''', r'''
typedef int bar();
''');
    }, throwsArgumentError);
  }

  test_topLevel_patch_function() {
    CompilationUnit unit = _doTopLevelPatching(r'''
external int foo();
int bar() => 2;
''', r'''
@patch
int foo() => 1;
''');
    _assertUnitCode(unit, 'int foo() => 1; int bar() => 2;');

    // Prepare functions.
    FunctionDeclaration foo = unit.declarations[0];
    FunctionDeclaration bar = unit.declarations[1];

    // The "external" token is removed from the stream.
    {
      expect(foo.externalKeyword, isNull);
      Token token = foo.beginToken;
      expect(token.lexeme, 'int');
      expect(token.previous.type, TokenType.EOF);
    }

    // The body tokens are included into the patched token stream.
    {
      FunctionExpression fooExpr = foo.functionExpression;
      FunctionBody fooBody = fooExpr.body;
      expect(fooBody.beginToken.previous, same(fooExpr.parameters.endToken));
      expect(fooBody.endToken.next, same(bar.beginToken));
    }
  }

  test_topLevel_patch_function_blockBody() {
    CompilationUnit unit = _doTopLevelPatching(r'''
external int foo();
''', r'''
@patch
int foo() {int v = 1; return v + 2;}
''');
    _assertUnitCode(unit, 'int foo() {int v = 1; return v + 2;}');
  }

  test_topLevel_patch_function_fail_signatureChange() {
    expect(() {
      _doTopLevelPatching(r'''
external void f(int x);
''', r'''
@patch
void f(double x) {}
''');
    }, throwsArgumentError);
  }

  test_topLevel_patch_function_fail_signatureChange_nameOnly() {
    expect(() {
      _doTopLevelPatching(r'''
external void f(int x);
''', r'''
@patch
void f(int y) {}
''');
    }, throwsArgumentError);
  }

  test_topLevel_patch_function_fail_signatureChange_returnTypeOnly() {
    expect(() {
      _doTopLevelPatching(r'''
external void f(int x);
''', r'''
@patch
int f(int x) {}
''');
    }, throwsArgumentError);
  }

  test_topLevel_patch_getter() {
    CompilationUnit unit = _doTopLevelPatching(r'''
external int get foo;
int bar() => 2;
''', r'''
@patch
int get foo => 1;
''');
    _assertUnitCode(unit, 'int get foo => 1; int bar() => 2;');
  }

  test_topLevel_patch_setter() {
    CompilationUnit unit = _doTopLevelPatching(r'''
external void set foo(int val);
int bar() => 2;
''', r'''
@patch
void set foo(int val) {}
''');
    _assertUnitCode(unit, 'void set foo(int val) {} int bar() => 2;');
  }

  test_topLevel_topLevelVariable_append() {
    CompilationUnit unit = _doTopLevelPatching(r'''
int foo() => 0;
''', r'''
int _bar;
''');
    _assertUnitCode(unit, 'int foo() => 0; int _bar;');
    FunctionDeclaration a = unit.declarations[0];
    TopLevelVariableDeclaration b = unit.declarations[1];
    _assertPrevNextToken(a.endToken, b.beginToken);
  }

  void _assertUnitCode(CompilationUnit unit, String expectedCode) {
    expect(unit.toSource(), expectedCode);
  }

  void _createSdk() {
    sdk = new FolderBasedDartSdk(provider, sdkFolder);
    sdk.analysisOptions = new AnalysisOptionsImpl()..strongMode = true;
  }

  CompilationUnit _doTopLevelPatching(String baseCode, String patchCode) {
    _setSdkLibraries(r'''
final Map<String, LibraryInfo> LIBRARIES = const <String, LibraryInfo> {
  'test' : const LibraryInfo(
    'test/test.dart'),
};''');
    var patchPaths = {
      'dart:test': [_p('/sdk/lib/test/test_patch.dart')]
    };
    File file = provider.newFile(_p('/sdk/lib/test/test.dart'), baseCode);
    provider.newFile(_p('/sdk/lib/test/test_patch.dart'), patchCode);

    _createSdk();

    Source source = file.createSource(Uri.parse('dart:test'));
    CompilationUnit unit = SdkPatcher.parse(source, true, listener);
    patcher.patch(provider, true, patchPaths, listener, source, unit);
    return unit;
  }

  String _p(String path) => provider.convertPath(path);

  void _setSdkLibraries(String code) {
    provider.newFile(
        _p('/sdk/lib/_internal/sdk_library_metadata/lib/libraries.dart'), code);
  }

  static void _assertPrevNextToken(Token prev, Token next) {
    expect(prev.next, same(next));
    expect(next.previous, same(prev));
  }
}
