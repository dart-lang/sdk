// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisHoverBlazeTest);
    defineReflectiveTests(AnalysisHoverTest);
  });
}

@reflectiveTest
class AnalysisHoverBlazeTest extends BlazeWorkspaceAnalysisServerTest {
  Future<void> test_blaze_notOwnedUri() async {
    newFile(
      '$workspaceRootPath/blaze-genfiles/dart/my/lib/test.dart',
      '// generated',
    );

    await setRoots(included: [workspaceRootPath], excluded: []);

    var testFile = newFile('$myPackageLibPath/test.dart', '''
class A {}
''');

    var request = AnalysisGetHoverParams(testFile.path, 0)
        .toRequest('0', clientUriConverter: server.uriConverter);
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.FILE_NOT_ANALYZED,
    );
  }
}

@reflectiveTest
class AnalysisHoverTest extends PubPackageAnalysisServerTest {
  Future<HoverInformation> prepareHover(String search, {File? inFile}) async {
    return (await prepareHoverOrNull(search, inFile: inFile))!;
  }

  Future<HoverInformation?> prepareHoverAt(int offset, {File? inFile}) async {
    inFile ??= testFile;
    await waitForTasksFinished();
    var request = AnalysisGetHoverParams(inFile.path, offset)
        .toRequest('0', clientUriConverter: server.uriConverter);
    var response = await handleSuccessfulRequest(request);
    var result = AnalysisGetHoverResult.fromResponse(response,
        clientUriConverter: server.uriConverter);
    return result.hovers.firstOrNull;
  }

  Future<HoverInformation?> prepareHoverOrNull(String search, {File? inFile}) {
    inFile ??= testFile;
    var offset = offsetInFile(inFile, search);
    return prepareHoverAt(offset, inFile: inFile);
  }

  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<void> test_class_constructor_named() async {
    newFile(testFilePath, '''
class A {
  /// my doc
  A.named() {}
}
void f() {
  new A.named();
}
''');
    void onConstructor(HoverInformation hover) {
      // range
      expect(hover.offset, findOffset('new A') + 'new '.length);
      expect(hover.length, 'A.named'.length);
      // element
      expect(hover.dartdoc, 'my doc');
      expect(hover.elementDescription, 'A A.named()');
      expect(hover.elementKind, 'constructor');
    }

    {
      var hover = await prepareHover('new A');
      onConstructor(hover);
    }
    {
      var hover = await prepareHover('named();');
      onConstructor(hover);
    }
  }

  Future<void> test_class_constructor_named_declaration() async {
    newFile(testFilePath, '''
class A {
  /// my doc
  A.named() {}
}
''');
    void onConstructor(HoverInformation hover) {
      // range
      expect(hover.offset, findOffset('A.named'));
      expect(hover.length, 'A.named'.length);
      // element
      expect(hover.dartdoc, 'my doc');
      expect(hover.elementDescription, 'A A.named()');
      expect(hover.elementKind, 'constructor');
    }

    {
      var hover = await prepareHover('A.');
      onConstructor(hover);
    }
    {
      var hover = await prepareHover('named()');
      onConstructor(hover);
    }
  }

  Future<void> test_class_constructor_noKeyword_const() async {
    newFile(testFilePath, '''
class A {
  const A(int i);
}
void f() {
  const a = A(0);
}
''');
    var hover = await prepareHover('A(0)');
    // range
    expect(hover.offset, findOffset('A(0)'));
    expect(hover.length, 'A'.length);
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.dartdoc, isNull);
    expect(hover.elementDescription, '(const) A A(int i)');
    expect(hover.elementKind, 'constructor');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_class_constructor_noKeyword_new() async {
    newFile(testFilePath, '''
class A {}
void f() {
  var a = A();
}
''');
    var hover = await prepareHover('A()');
    // range
    expect(hover.offset, findOffset('A()'));
    expect(hover.length, 'A'.length);
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.dartdoc, isNull);
    expect(hover.elementDescription, '(new) A A()');
    expect(hover.elementKind, 'constructor');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_class_constructor_synthetic() async {
    newFile(testFilePath, '''
class A {
}
void f() {
  new A();
}
''');
    var hover = await prepareHover('new A');
    // range
    expect(hover.offset, findOffset('new A') + 'new '.length);
    expect(hover.length, 'A'.length);
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.dartdoc, isNull);
    expect(hover.elementDescription, 'A A()');
    expect(hover.elementKind, 'constructor');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_class_constructor_synthetic_withTypeArgument() async {
    newFile(testFilePath, '''
class A<T> {}
void f() {
  new A<String>();
}
''');
    void onConstructor(HoverInformation hover) {
      // range
      expect(hover.offset, findOffset('A<String>'));
      expect(hover.length, 'A<String>'.length);
      // element
      expect(hover.containingLibraryName, 'package:test/test.dart');
      expect(hover.containingLibraryPath, testFile.path);
      expect(hover.dartdoc, isNull);
      expect(hover.elementDescription, 'A<String> A()');
      expect(hover.elementKind, 'constructor');
      // types
      expect(hover.staticType, isNull);
      expect(hover.propagatedType, isNull);
      // no parameter
      expect(hover.parameter, isNull);
    }

    {
      var hover = await prepareHover('new A');
      onConstructor(hover);
    }
    {
      var hover = await prepareHover('A<String>()');
      onConstructor(hover);
    }
    {
      var hover = await prepareHover('String>');
      expect(hover.containingLibraryName, 'dart:core');
      expect(hover.offset, findOffset('String>'));
      expect(hover.length, 'String'.length);
      expect(hover.elementKind, 'class');
    }
  }

  Future<void> test_class_constructorReference_named() async {
    newFile(testFilePath, '''
class A<T> {
  /// doc aaa
  /// doc bbb
  A.named();
}

void f() {
  A<double>.named;
}
''');
    var hover = await prepareHover('named;');
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, 'doc aaa\ndoc bbb');
    expect(hover.elementDescription, 'A<double> A.named()');
    expect(hover.elementKind, 'constructor');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_class_constructorReference_unnamed_declared() async {
    newFile(testFilePath, '''
class A<T> {
  /// doc aaa
  /// doc bbb
  A();
}

void f() {
  A<double>.new;
}
''');
    var hover = await prepareHover('new;');
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, 'doc aaa\ndoc bbb');
    expect(hover.elementDescription, 'A<double> A()');
    expect(hover.elementKind, 'constructor');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_class_constructorReference_unnamed_declared_new() async {
    newFile(testFilePath, '''
class A<T> {
  /// doc aaa
  /// doc bbb
  A.new();
}

void f() {
  A<double>.new;
}
''');
    var hover = await prepareHover('new;');
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, 'doc aaa\ndoc bbb');
    expect(hover.elementDescription, 'A<double> A()');
    expect(hover.elementKind, 'constructor');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_class_constructorReference_unnamed_synthetic() async {
    newFile(testFilePath, '''
class A<T> {}

void f() {
  A<double>.new;
}
''');
    var hover = await prepareHover('new;');
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, isNull);
    expect(hover.elementDescription, 'A<double> A()');
    expect(hover.elementKind, 'constructor');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_class_declaration() async {
    newFile(testFilePath, '''
class A<E> {}
class I1<K, V> {}
class I2<E> {}
class M1 {}
class M2<E> {}
class B<T> extends A<T> with M1, M2<int> implements I1<int, String>, I2 {}
''');
    var hover = await prepareHover('B<T>');
    expect(hover.containingClassDescription, null);
    expect(
        hover.elementDescription,
        'class B<T> extends A<T> with M1, M2<int> '
        'implements I1<int, String>, I2<dynamic>');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_class_declaration_abstract() async {
    newFile(testFilePath, '''
class A {}
abstract class B extends A {}
''');
    var hover = await prepareHover('B extends');
    expect(hover.containingClassDescription, null);
    expect(hover.elementDescription, 'abstract class B extends A');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_class_declaration_base() async {
    newFile(testFilePath, '''
base class A {}
''');
    var hover = await prepareHover('A');
    expect(hover.containingClassDescription, null);
    expect(hover.elementDescription, 'base class A');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_class_declaration_base_abstract() async {
    newFile(testFilePath, '''
abstract base class A {}
''');
    var hover = await prepareHover('A');
    expect(hover.containingClassDescription, null);
    expect(hover.elementDescription, 'abstract base class A');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_class_declaration_final() async {
    newFile(testFilePath, '''
final class A {}
''');
    var hover = await prepareHover('A');
    expect(hover.containingClassDescription, null);
    expect(hover.elementDescription, 'final class A');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_class_declaration_final_abstract() async {
    newFile(testFilePath, '''
abstract final class A {}
''');
    var hover = await prepareHover('A');
    expect(hover.containingClassDescription, null);
    expect(hover.elementDescription, 'abstract final class A');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_class_declaration_interface() async {
    newFile(testFilePath, '''
interface class A {}
''');
    var hover = await prepareHover('A');
    expect(hover.containingClassDescription, null);
    expect(hover.elementDescription, 'interface class A');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_class_declaration_interface_abstract() async {
    newFile(testFilePath, '''
abstract interface class A {}
''');
    var hover = await prepareHover('A');
    expect(hover.containingClassDescription, null);
    expect(hover.elementDescription, 'abstract interface class A');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_class_declaration_mixin() async {
    newFile(testFilePath, '''
mixin class A {}
''');
    var hover = await prepareHover('A');
    expect(hover.containingClassDescription, null);
    expect(hover.elementDescription, 'mixin class A');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_class_declaration_mixin_base() async {
    newFile(testFilePath, '''
base mixin class A {}
''');
    var hover = await prepareHover('A');
    expect(hover.containingClassDescription, null);
    expect(hover.elementDescription, 'base mixin class A');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_class_declaration_sealed() async {
    newFile(testFilePath, '''
sealed class A {}
''');
    var hover = await prepareHover('A');
    expect(hover.containingClassDescription, null);
    expect(hover.elementDescription, 'sealed class A');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_class_getter() async {
    newFile(testFilePath, '''
class A {
  /// doc aaa
  /// doc bbb
  String get fff => '';
}
void f(A a) {
  print(a.fff);
}
''');
    var hover = await prepareHover('fff);');
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    expect(hover.elementDescription, 'String get fff');
    expect(hover.elementKind, 'getter');
    // types
    expect(hover.staticType, 'String');
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_class_getter_generic() async {
    newFile(testFilePath, '''
class A<T> {
  /// doc aaa
  /// doc bbb
  T get fff => throw '';
}
void f(A<String> a) {
  print(a.fff);
}
''');
    var hover = await prepareHover('fff);');
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    expect(hover.elementDescription, 'T get fff');
    expect(hover.elementKind, 'getter');
    // types
    expect(hover.staticType, 'String');
  }

  Future<void> test_class_getter_synthetic() async {
    newFile(testFilePath, '''
class A {
  /// doc aaa
  /// doc bbb
  String fff;
}
void f(A a) {
  print(a.fff);
}
''');
    var hover = await prepareHover('fff);');
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    expect(hover.elementDescription, 'String fff');
    expect(hover.elementKind, 'field');
    // types
    expect(hover.staticType, 'String');
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_class_method_declaration() async {
    newFile(testFilePath, '''
class A {
  /// doc aaa
  /// doc bbb
  List<String> mmm(int a, String b) {
  }
}
''');
    var hover = await prepareHover('mmm(int a');
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    expect(hover.elementDescription, 'List<String> mmm(int a, String b)');
    expect(hover.elementKind, 'method');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_class_method_reference() async {
    newFile(testFilePath, '''
class A {
  List<String> mmm(int a, String b) {
  }
}
void f(A a) {
  a.mmm(42, 'foo');
}
''');
    var hover = await prepareHover('mm(42, ');
    // range
    expect(hover.offset, findOffset('mmm(42, '));
    expect(hover.length, 'mmm'.length);
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.elementDescription, 'List<String> mmm(int a, String b)');
    expect(hover.elementKind, 'method');
    expect(hover.isDeprecated, isFalse);
    // types
    expect(hover.staticType, 'List<String> Function(int, String)');
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_class_method_reference_deprecated() async {
    newFile(testFilePath, '''
class A {
  @deprecated
  static void test() {}
}
void f() {
  A.test();
}
''');
    var hover = await prepareHover('test();');
    // element
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.elementDescription, 'void test()');
    expect(hover.elementKind, 'method');
    expect(hover.isDeprecated, isTrue);
  }

  Future<void> test_class_method_reference_genericMethod() async {
    newFile(testFilePath, '''

abstract class Stream<T> {
  Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer);
}
abstract class StreamTransformer<T, S> {}

f(Stream<int> s) {
  s.transform(null);
}
''');
    var hover = await prepareHover('nsform(n');
    // range
    expect(hover.offset, findOffset('transform(n'));
    expect(hover.length, 'transform'.length);
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.elementDescription,
        'Stream<S> transform<S>(StreamTransformer<int, S> streamTransformer)');
    expect(hover.elementKind, 'method');
    expect(hover.isDeprecated, isFalse);
    // types
    expect(hover.staticType,
        'Stream<dynamic> Function(StreamTransformer<int, dynamic>)');
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_class_setter() async {
    newFile(testFilePath, '''
class A {
  /// doc aaa
  /// doc bbb
  set fff(String value) {}
}
void f(A a) {
  a.fff = '';
}
''');
    var hover = await prepareHover('fff =');
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    expect(hover.elementDescription, 'set fff(String value)');
    expect(hover.elementKind, 'setter');
    // types
    expect(hover.staticType, 'String');
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_class_setter_generic() async {
    newFile(testFilePath, '''
class A<T> {
  /// doc aaa
  /// doc bbb
  set fff(T value) {}
}
void f(A<String> a) {
  a.fff = '';
}
''');
    var hover = await prepareHover('fff =');
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    expect(hover.elementDescription, 'set fff(T value)');
    expect(hover.elementKind, 'setter');
    // types
    expect(hover.staticType, 'String');
  }

  Future<void> test_class_setter_hasDocumentation() async {
    newFile(testFilePath, '''
class A {
  /// getting
  int get foo => 42;
  /// setting
  set foo(int x) {}
}
void f(A a) {
  a.foo = 123;
}
''');
    var hover = await prepareHover('foo = 1');
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, 'setting');
    expect(hover.elementDescription, 'set foo(int x)');
    expect(hover.elementKind, 'setter');
  }

  Future<void> test_class_setter_noDocumentation() async {
    newFile(testFilePath, '''
class A {
  /// getting
  int get foo => 42;
  set foo(int x) {}
}
void f(A a) {
  a.foo = 123;
}
''');
    var hover = await prepareHover('foo = 1');
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, '''getting''');
    expect(hover.elementDescription, 'set foo(int x)');
    expect(hover.elementKind, 'setter');
  }

  Future<void> test_class_setter_super_hasDocumentation() async {
    newFile(testFilePath, '''
class A {
  /// pgetting
  int get foo => 42;
  /// psetting
  set foo(int x) {}
}
class B extends A {
  /// getting
  int get foo => 42;
  set foo(int x) {}
}
void f(B b) {
  b.foo = 123;
}
''');
    var hover = await prepareHover('foo = ');
    expect(hover.containingClassDescription, 'B');
    expect(hover.dartdoc, '''psetting\n\nCopied from `A`.''');
    expect(hover.elementDescription, 'set foo(int x)');
    expect(hover.elementKind, 'setter');
  }

  Future<void> test_class_setter_super_noDocumentation() async {
    newFile(testFilePath, '''
class A {
  /// pgetting
  int get foo => 42;
  set foo(int x) {}
}
class B extends A {
  int get foo => 42;
  set foo(int x) {}
}
void f(B b) {
  b.foo = 123;
}
''');
    var hover = await prepareHover('foo = ');
    expect(hover.containingClassDescription, 'B');
    expect(hover.dartdoc, '''pgetting\n\nCopied from `A`.''');
    expect(hover.elementDescription, 'set foo(int x)');
    expect(hover.elementKind, 'setter');
  }

  @failingTest
  Future<void> test_class_setter_super_noSetter() async {
    newFile(testFilePath, '''
class A {
  /// pgetting
  int get foo => 42;
}
class B extends A {
  set foo(int x) {}
}
void f(B b) {
  b.foo = 123;
}
''');
    var hover = await prepareHover('foo = ');
    expect(hover.containingClassDescription, 'B');
    expect(hover.dartdoc, '''pgetting''');
    expect(hover.elementDescription, 'set foo(int x)');
    expect(hover.elementKind, 'setter');
  }

  Future<void> test_class_setter_synthetic() async {
    newFile(testFilePath, '''
class A {
  /// doc aaa
  /// doc bbb
  String fff;
}
void f(A a) {
  a.fff = '';
}
''');
    var hover = await prepareHover('fff =');
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    expect(hover.elementDescription, 'String fff');
    expect(hover.elementKind, 'field');
    // types
    expect(hover.staticType, 'String');
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_constructorInvocation_macroGenerated_named() async {
    addMacros([declareInTypeMacro()]);
    newFile(testFilePath, '''
import 'macros.dart';

@DeclareInType('  /// named\\n  C.named();')
class C {}

C f() => C.named(); //
''');
    var hover = await prepareHover('med(); //');
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'C');
    expect(hover.dartdoc, 'named');
    expect(hover.elementDescription, '(new) C C.named()');
    expect(hover.elementKind, 'constructor');
    expect(hover.staticType, isNull);
  }

  Future<void>
      test_constructorInvocation_referenceFromAugmentation_default() async {
    var file = newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';

augment class C {
  void m() {
    C();
  }
}
''');
    newFile(testFilePath, '''
part 'a.dart';

class C {
  /// default
  C();
}
''');
    var hover = await prepareHover('C();', inFile: file);
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'C');
    expect(hover.dartdoc, 'default');
    expect(hover.elementDescription, '(new) C C()');
    expect(hover.elementKind, 'constructor');
    expect(hover.staticType, isNull);
  }

  Future<void>
      test_constructorInvocation_referenceFromAugmentation_named() async {
    var file = newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';

augment class C {
  void m() {
    C.named();
  }
}
''');
    newFile(testFilePath, '''
part 'a.dart';

class C {
  /// named
  C.named();
}
''');
    var hover = await prepareHover('C.named();', inFile: file);
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'C');
    expect(hover.dartdoc, 'named');
    expect(hover.elementDescription, '(new) C C.named()');
    expect(hover.elementKind, 'constructor');
    expect(hover.staticType, isNull);
  }

  Future<void> test_dartdoc_block() async {
    newFile(testFilePath, '''
/**
 * doc aaa
 * doc bbb
 */
void f() {
}
''');
    var hover = await prepareHover('f() {');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
  }

  Future<void> test_dartdoc_inherited_fromInterface() async {
    newFile(testFilePath, '''
class A {
  /// my doc
  m() {} // in A
}

class B implements A {
  m() {} // in B
}
''');
    var hover = await prepareHover('m() {} // in B');
    expect(hover.dartdoc, '''my doc\n\nCopied from `A`.''');
  }

  Future<void> test_dartdoc_inherited_fromSuper_direct() async {
    newFile(testFilePath, '''
class A {
  /// my doc
  m() {} // in A
}

class B extends A {
  m() {} // in B
}
''');
    var hover = await prepareHover('m() {} // in B');
    expect(hover.dartdoc, '''my doc\n\nCopied from `A`.''');
  }

  Future<void> test_dartdoc_inherited_fromSuper_indirect() async {
    newFile(testFilePath, '''
class A {
  /// my doc
  m() {}
}
class B extends A {
  m() {}
}
class C extends B {
  m() {} // in C
}''');
    var hover = await prepareHover('m() {} // in C');
    expect(hover.dartdoc, '''my doc\n\nCopied from `A`.''');
  }

  Future<void> test_dartdoc_inherited_preferSuper() async {
    newFile(testFilePath, '''
class A {
  /// my doc
  m() {}
}
class B extends A {
}
class I {
  // wrong doc
  m() {}
}
class C extends B implements I {
  m() {} // in C
}''');
    var hover = await prepareHover('m() {} // in C');
    expect(hover.dartdoc, '''my doc\n\nCopied from `A`.''');
  }

  Future<void> test_dartdoc_line() async {
    newFile(testFilePath, '''
/// doc aaa
/// doc bbb
void f() {
}
''');
    var hover = await prepareHover('f() {');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
  }

  Future<void> test_enum_declaration() async {
    newFile(testFilePath, '''
enum MyEnum {AAA, BBB, CCC}
''');
    var hover = await prepareHover('MyEnum');
    expect(hover.containingClassDescription, null);
    expect(hover.elementDescription, 'enum MyEnum');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_enum_getter() async {
    newFile(testFilePath, '''
enum E {
  v;
  /// doc aaa
  /// doc bbb
  int get foo => 0;
}
void f(E e) {
  print(e.foo);
}
''');
    var hover = await prepareHover('foo);');
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'E');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    expect(hover.elementDescription, 'int get foo');
    expect(hover.elementKind, 'getter');
  }

  Future<void> test_enum_getter_synthetic() async {
    newFile(testFilePath, '''
enum E {
  v;
  /// doc aaa
  /// doc bbb
  final String fff;
}
void f(E e) {
  print(e.fff);
}
''');
    var hover = await prepareHover('fff);');
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'E');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    expect(hover.elementDescription, 'String fff');
    expect(hover.elementKind, 'field');
    // types
    expect(hover.staticType, 'String');
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_enum_method_declaration() async {
    newFile(testFilePath, '''
enum E {
  v;
  /// doc aaa
  /// doc bbb
  List<String> mmm(int a, String b) {
  }
}
''');
    var hover = await prepareHover('mmm(int a');
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'E');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    expect(hover.elementDescription, 'List<String> mmm(int a, String b)');
    expect(hover.elementKind, 'method');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_enum_method_reference() async {
    newFile(testFilePath, '''
enum E {
  v;
  List<String> mmm(int a, String b) {
  }
}
void f(E e) {
  e.mmm(42, 'foo');
}
''');
    var hover = await prepareHover('mm(42, ');
    // range
    expect(hover.offset, findOffset('mmm(42, '));
    expect(hover.length, 'mmm'.length);
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'E');
    expect(hover.elementDescription, 'List<String> mmm(int a, String b)');
    expect(hover.elementKind, 'method');
    expect(hover.isDeprecated, isFalse);
    // types
    expect(hover.staticType, 'List<String> Function(int, String)');
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_enum_setter_hasDocumentation() async {
    newFile(testFilePath, '''
enum E {
  v;
  /// getting
  int get foo => 42;
  /// setting
  set foo(int x) {}
}
void f(E e) {
  e.foo = 123;
}
''');
    var hover = await prepareHover('foo = ');
    expect(hover.containingClassDescription, 'E');
    expect(hover.dartdoc, '''setting''');
    expect(hover.elementDescription, 'set foo(int x)');
    expect(hover.elementKind, 'setter');
  }

  Future<void> test_extensionDeclaration() async {
    newFile(testFilePath, '''
class A {}
/// Comment
extension E on A {}
''');
    var hover = await prepareHover('E');
    expect(hover.containingClassDescription, null);
    expect(hover.elementDescription, 'extension E on A');
    expect(hover.dartdoc, 'Comment');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_function_multilineElementDescription() async {
    // Functions with at least 3 params will have element descriptions formatted
    // across multiple lines.
    newFile(testFilePath, '''
List<String> fff(int a, [String b = 'b', String c = 'c']) {
}
''');
    var hover = await prepareHover('fff(int a');
    expect(hover.elementDescription, '''
List<String> fff(
  int a, [
  String b = 'b',
  String c = 'c',
])''');
  }

  Future<void> test_function_topLevel_declaration() async {
    newFile(testFilePath, '''
/// doc aaa
/// doc bbb
List<String> fff(int a, [String b = 'b']) {
}
''');
    var hover = await prepareHover('fff(int a');
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, isNull);
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    expect(
        hover.elementDescription, "List<String> fff(int a, [String b = 'b'])");
    expect(hover.elementKind, 'function');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_functionReference_classMethod_instance() async {
    newFile(testFilePath, '''
class A<T> {
  /// doc aaa
  /// doc bbb
  int foo<U>(T t, U u) => 0;
}

void f(A<int> a) {
  a.foo<double>;
}
''');
    var hover = await prepareHover('foo<double>');
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    expect(hover.elementDescription, 'int foo<U>(int t, U u)');
    expect(hover.elementKind, 'method');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_functionReference_classMethod_static() async {
    newFile(testFilePath, '''
class A<T> {
  /// doc aaa
  /// doc bbb
  static int foo<U>(U u) => 0;
}

void f() {
  A.foo<double>;
}
''');
    var hover = await prepareHover('foo<double>');
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    expect(hover.elementDescription, 'int foo<U>(U u)');
    expect(hover.elementKind, 'method');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_functionReference_topLevelFunction() async {
    newFile(testFilePath, '''
/// doc aaa
/// doc bbb
int foo<T>(T a) => 0;

void f() {
  foo<double>;
}
''');
    var hover = await prepareHover('foo<double>');
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, isNull);
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    expect(hover.elementDescription, 'int foo<T>(T a)');
    expect(hover.elementKind, 'function');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_integerLiteral() async {
    newFile(testFilePath, '''
void f() {
  foo(123);
}
foo(Object myParameter) {}
''');
    var hover = await prepareHover('123');
    // range
    expect(hover.offset, findOffset('123'));
    expect(hover.length, 3);
    // element
    expect(hover.containingClassDescription, isNull);
    expect(hover.containingLibraryName, isNull);
    expect(hover.containingLibraryPath, isNull);
    expect(hover.dartdoc, isNull);
    expect(hover.elementDescription, isNull);
    expect(hover.elementKind, isNull);
    // types
    expect(hover.staticType, 'int');
    expect(hover.propagatedType, isNull);
    // parameter
    expect(hover.parameter, 'Object myParameter');
  }

  Future<void> test_integerLiteral_promoted() async {
    newFile(testFilePath, '''
void f() {
  foo(123);
}
foo(double myParameter) {}
''');
    var hover = await prepareHover('123');
    // range
    expect(hover.offset, findOffset('123'));
    expect(hover.length, 3);
    // element
    expect(hover.containingClassDescription, isNull);
    expect(hover.containingLibraryName, isNull);
    expect(hover.containingLibraryPath, isNull);
    expect(hover.dartdoc, isNull);
    expect(hover.elementDescription, isNull);
    expect(hover.elementKind, isNull);
    // types
    expect(hover.staticType, 'double');
    expect(hover.propagatedType, isNull);
    // parameter
    expect(hover.parameter, 'double myParameter');
  }

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request = AnalysisGetHoverParams('test.dart', 0)
        .toRequest('0', clientUriConverter: server.uriConverter);
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request =
        AnalysisGetHoverParams(convertPath('/foo/../bar/test.dart'), 0)
            .toRequest('0', clientUriConverter: server.uriConverter);
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_localVariable_declaration() async {
    newFile(testFilePath, '''
class A {
  m() {
    num vvv = 42;
  }
}
''');
    var hover = await prepareHover('vvv = 42');
    // element
    expect(hover.containingLibraryName, isNull);
    expect(hover.containingLibraryPath, isNull);
    expect(hover.containingClassDescription, isNull);
    expect(hover.dartdoc, isNull);
    expect(hover.elementDescription, 'num vvv');
    expect(hover.elementKind, 'local variable');
    // types
    expect(hover.staticType, 'num');
    expect(hover.propagatedType, null);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_localVariable_reference_withPropagatedType() async {
    newFile(testFilePath, '''
void f() {
  var vvv = 123;
  print(vvv);
}
''');
    var hover = await prepareHover('vvv);');
    // element
    expect(hover.containingLibraryName, isNull);
    expect(hover.containingLibraryPath, isNull);
    expect(hover.containingClassDescription, isNull);
    expect(hover.dartdoc, isNull);
    expect(hover.elementDescription, 'int vvv');
    expect(hover.elementKind, 'local variable');
    // types
    expect(hover.staticType, 'int');
    expect(hover.propagatedType, null);
  }

  Future<void>
      test_methodInvocation_macroGenerated_referenceToGenerated() async {
    addMacros([declareInTypeMacro()]);
    newFile(testFilePath, '''
import 'macros.dart';

@DeclareInType(\'''
  /// method m
  void m() {}
\''')
class C {}

void f(C c) {
  c.m();
}
''');
    var hover = await prepareHover('m();');
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'C');
    expect(hover.dartdoc, 'method m');
    expect(hover.elementDescription, 'void m()');
    expect(hover.elementKind, 'method');
    expect(hover.staticType, 'void Function()');
  }

  Future<void> test_methodInvocation_recordType() async {
    newFile(testFilePath, '''
class C {
  List<int> m(int i, (int, String) r) => [];
}
void f(C c) {
  c.m((1, '1'));
}
''');
    var hover = await prepareHover('m((1');
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'C');
    expect(hover.dartdoc, isNull);
    expect(hover.elementDescription, 'List<int> m(int i, (int, String) r)');
    expect(hover.elementKind, 'method');
    expect(hover.staticType, 'List<int> Function(int, (int, String))');
  }

  Future<void> test_methodInvocation_referenceFromAugmentation() async {
    var file = newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';

augment class C {
  void m(C c) {
    c.n();
  }
}
''');
    newFile(testFilePath, '''
part 'a.dart';

class C {
  /// method n
  void n() {}
}
''');
    var hover = await prepareHover('n();', inFile: file);
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, 'C');
    expect(hover.dartdoc, 'method n');
    expect(hover.elementDescription, 'void n()');
    expect(hover.elementKind, 'method');
    expect(hover.staticType, 'void Function()');
  }

  Future<void> test_mixin_declaration() async {
    newFile(testFilePath, '''
mixin A on B, C implements D, E {}
class B {}
class C {}
class D {}
class E {}
''');
    var hover = await prepareHover('A');
    expect(hover.elementDescription, 'mixin A on B, C implements D, E');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_mixin_declaration_base() async {
    newFile(testFilePath, '''
base mixin A {}
''');
    var hover = await prepareHover('A');
    expect(hover.elementDescription, 'base mixin A on Object');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  @failingTest
  Future<void> test_mixin_reference() async {
    newFile(testFilePath, '''
mixin A {}
abstract class B {}
class C with A implements B {}
''');
    var hover = await prepareHover('A i');
    expect(hover.elementDescription, 'mixin A');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_noHoverInfo() async {
    newFile(testFilePath, '''
void f() {
  // nothing
}
''');
    var hover = await prepareHoverOrNull('nothing');
    expect(hover, isNull);
  }

  Future<void> test_nonNullable() async {
    newFile(testFilePath, '''
int? f(double? a) => null;

void f() {
  f(null);
}
''');
    var hover = await prepareHover('f(null)');
    expect(hover.elementDescription, 'int? f(double? a)');
    expect(hover.staticType, 'int? Function(double?)');
  }

  Future<void> test_parameter_declaration_fieldFormal() async {
    newFile(testFilePath, '''
class A {
  /// The field documentation.
  final int fff;
  A({this.fff});
}
void f() {
  new A(fff: 42);
}
''');
    var hover = await prepareHover('fff});');
    expect(hover.containingLibraryName, isNull);
    expect(hover.containingLibraryPath, isNull);
    expect(hover.containingClassDescription, isNull);
    expect(hover.dartdoc, 'The field documentation.');
    expect(hover.elementDescription, '{int fff}');
    expect(hover.elementKind, 'parameter');
    expect(hover.staticType, 'int');
  }

  Future<void> test_parameter_declaration_required() async {
    newFile(testFilePath, '''
class A {
  /// The method documentation.
  m(int p) {
  }
}
''');
    var hover = await prepareHover('p) {');
    // element
    expect(hover.containingLibraryName, isNull);
    expect(hover.containingLibraryPath, isNull);
    expect(hover.containingClassDescription, isNull);
    expect(hover.dartdoc, 'The method documentation.');
    expect(hover.elementDescription, 'int p');
    expect(hover.elementKind, 'parameter');
    // types
    expect(hover.staticType, 'int');
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_parameter_defaultValue() async {
    newFile(testFilePath, 'void b([int a=123]) { }');
    var hover = await prepareHover('a=');
    // element
    expect(hover.elementDescription, '[int a = 123]');
    expect(hover.elementKind, 'parameter');
  }

  Future<void>
      test_parameter_ofConstructor_optionalPositional_super_defaultValue_explicit() async {
    newFile(testFilePath, '''
class A {
  A([int a = 1]);
}
class B extends A {
  B([super.a = 2]);
}
''');
    var hover = await prepareHover('a = 2]');
    // element
    expect(hover.elementDescription, '[int a = 2]');
    expect(hover.elementKind, 'parameter');
  }

  Future<void>
      test_parameter_ofConstructor_optionalPositional_super_defaultValue_inherited() async {
    newFile(testFilePath, '''
class A {
  A([int a = 1]);
}
class B extends A {
  B([super.a]);
}
''');
    var hover = await prepareHover('a]');
    // element
    expect(hover.elementDescription, '[int a = 1]');
    expect(hover.elementKind, 'parameter');
  }

  Future<void>
      test_parameter_ofConstructor_optionalPositional_super_defaultValue_inherited2() async {
    newFile(testFilePath, '''
class A {
  A([num a = 1.2]);
}
class B extends A{
  B([int super.a]);
}
''');
    var hover = await prepareHover('a]');
    // element
    expect(hover.elementDescription, '[int a]');
    expect(hover.elementKind, 'parameter');
  }

  Future<void> test_parameter_reference_fieldFormal() async {
    newFile(testFilePath, '''
class A {
  /// The field documentation.
  final int fff;
  A({this.fff});
}
void f() {
  new A(fff: 42);
}
''');
    var hover = await prepareHover('fff: 42');
    expect(hover.containingLibraryName, isNull);
    expect(hover.containingLibraryPath, isNull);
    expect(hover.containingClassDescription, isNull);
    expect(hover.dartdoc, 'The field documentation.');
    expect(hover.elementDescription, '{int fff}');
    expect(hover.elementKind, 'parameter');
    expect(hover.staticType, 'int');
  }

  Future<void> test_parameter_reference_recordType() async {
    newFile(testFilePath, '''
void f((int, String) r) {
  print(r);
}
''');
    var hover = await prepareHover('r);');
    expect(hover.containingLibraryName, isNull);
    expect(hover.containingLibraryPath, isNull);
    expect(hover.containingClassDescription, isNull);
    expect(hover.dartdoc, isNull);
    expect(hover.elementDescription, '(int, String) r');
    expect(hover.elementKind, 'parameter');
    expect(hover.staticType, '(int, String)');
  }

  Future<void> test_recordLiteral() async {
    newFile(testFilePath, '''
Object f() {
  return ( 1, 'two', true );
}
''');
    var hover = await prepareHover('( 1');
    expect(hover.containingLibraryName, isNull);
    expect(hover.containingLibraryPath, isNull);
    expect(hover.containingClassDescription, isNull);
    expect(hover.dartdoc, isNull);
    expect(hover.elementDescription, isNull);
    expect(hover.elementKind, isNull);
    expect(hover.staticType, '(int, String, bool)');
  }

  Future<void> test_simpleIdentifier_typedef_functionType() async {
    newFile(testFilePath, '''
typedef A = void Function(int);
''');
    var hover = await prepareHover('A');
    _assertHover(
      hover,
      elementDescription: 'typedef A = void Function(int )',
      elementKind: 'type alias',
    );
  }

  Future<void> test_simpleIdentifier_typedef_interfaceType() async {
    newFile(testFilePath, '''
typedef A = Map<int, String>;
''');
    var hover = await prepareHover('A');
    _assertHover(
      hover,
      elementDescription: 'typedef A = Map<int, String>',
      elementKind: 'type alias',
    );
  }

  Future<void> test_simpleIdentifier_typedef_legacy() async {
    newFile(testFilePath, '''
typedef void A(int a);
''');
    var hover = await prepareHover('A');
    _assertHover(
      hover,
      elementDescription: 'typedef A = void Function(int a)',
      elementKind: 'type alias',
    );
  }

  Future<void> test_topLevel_setter() async {
    newFile(testFilePath, '''
/// doc aaa
/// doc bbb
set fff(String value) {}

void f(A a) {
  fff = '';
}
''');
    var hover = await prepareHover('fff =');
    // element
    expect(hover.containingLibraryName, 'package:test/test.dart');
    expect(hover.containingLibraryPath, testFile.path);
    expect(hover.containingClassDescription, isNull);
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    expect(hover.elementDescription, 'set fff(String value)');
    expect(hover.elementKind, 'setter');
    // types
    expect(hover.staticType, 'String');
    expect(hover.propagatedType, isNull);
  }

  void _assertHover(
    HoverInformation hover, {
    String? containingLibraryPath,
    String? containingLibraryName,
    required String elementDescription,
    required String elementKind,
    bool isDeprecated = false,
  }) {
    containingLibraryName ??= 'package:test/test.dart';
    expect(hover.containingLibraryName, containingLibraryName);

    containingLibraryPath ??= testFile.path;
    expect(hover.containingLibraryPath, containingLibraryPath);

    expect(hover.elementDescription, elementDescription);
    expect(hover.elementKind, elementKind);
    expect(hover.isDeprecated, isDeprecated);
  }
}
