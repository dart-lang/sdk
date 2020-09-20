// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';
import '../mocks.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisHoverTest);
  });
}

@reflectiveTest
class AnalysisHoverTest extends AbstractAnalysisTest {
  Future<HoverInformation> prepareHover(String search) {
    var offset = findOffset(search);
    return prepareHoverAt(offset);
  }

  Future<HoverInformation> prepareHoverAt(int offset) async {
    await waitForTasksFinished();
    var request = AnalysisGetHoverParams(testFile, offset).toRequest('0');
    var response = await waitResponse(request);
    var result = AnalysisGetHoverResult.fromResponse(response);
    var hovers = result.hovers;
    return hovers.isNotEmpty ? hovers.first : null;
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
  }

  Future<void> test_class_declaration() async {
    addTestFile('''
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
    addTestFile('''
class A {}
abstract class B extends A {}
''');
    var hover = await prepareHover('B extends');
    expect(hover.containingClassDescription, null);
    expect(hover.elementDescription, 'abstract class B extends A');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_constructor_named() async {
    addTestFile('''
library my.library;
class A {
  /// my doc
  A.named() {}
}
main() {
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

  Future<void> test_constructor_noKeyword_const() async {
    addTestFile('''
library my.library;
class A {
  const A(int i);
}
main() {
  const a = A(0);
}
''');
    var hover = await prepareHover('A(0)');
    // range
    expect(hover.offset, findOffset('A(0)'));
    expect(hover.length, 'A'.length);
    // element
    expect(hover.containingLibraryName, 'bin/test.dart');
    expect(hover.containingLibraryPath, testFile);
    expect(hover.dartdoc, isNull);
    expect(hover.elementDescription, '(const) A A(int i)');
    expect(hover.elementKind, 'constructor');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_constructor_noKeyword_new() async {
    addTestFile('''
library my.library;
class A {}
main() {
  var a = A();
}
''');
    var hover = await prepareHover('A()');
    // range
    expect(hover.offset, findOffset('A()'));
    expect(hover.length, 'A'.length);
    // element
    expect(hover.containingLibraryName, 'bin/test.dart');
    expect(hover.containingLibraryPath, testFile);
    expect(hover.dartdoc, isNull);
    expect(hover.elementDescription, '(new) A A()');
    expect(hover.elementKind, 'constructor');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_constructor_synthetic() async {
    addTestFile('''
library my.library;
class A {
}
main() {
  new A();
}
''');
    var hover = await prepareHover('new A');
    // range
    expect(hover.offset, findOffset('new A') + 'new '.length);
    expect(hover.length, 'A'.length);
    // element
    expect(hover.containingLibraryName, 'bin/test.dart');
    expect(hover.containingLibraryPath, testFile);
    expect(hover.dartdoc, isNull);
    expect(hover.elementDescription, 'A A()');
    expect(hover.elementKind, 'constructor');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_constructor_synthetic_withTypeArgument() async {
    addTestFile('''
library my.library;
class A<T> {}
main() {
  new A<String>();
}
''');
    void onConstructor(HoverInformation hover) {
      // range
      expect(hover.offset, findOffset('A<String>'));
      expect(hover.length, 'A<String>'.length);
      // element
      expect(hover.containingLibraryName, 'bin/test.dart');
      expect(hover.containingLibraryPath, testFile);
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

  Future<void> test_dartdoc_block() async {
    addTestFile('''
/**
 * doc aaa
 * doc bbb
 */
main() {
}
''');
    var hover = await prepareHover('main() {');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
  }

  Future<void> test_dartdoc_inherited_fromInterface() async {
    addTestFile('''
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
    addTestFile('''
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
    addTestFile('''
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
    addTestFile('''
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
    addTestFile('''
/// doc aaa
/// doc bbb
main() {
}
''');
    var hover = await prepareHover('main() {');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
  }

  Future<void> test_enum_declaration() async {
    addTestFile('''
enum MyEnum {AAA, BBB, CCC}
''');
    var hover = await prepareHover('MyEnum');
    expect(hover.containingClassDescription, null);
    expect(hover.elementDescription, 'enum MyEnum');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_extensionDeclaration() async {
    addTestFile('''
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

  Future<void> test_function_topLevel_declaration() async {
    addTestFile('''
library my.library;
/// doc aaa
/// doc bbb
List<String> fff(int a, [String b = 'b']) {
}
''');
    var hover = await prepareHover('fff(int a');
    // element
    expect(hover.containingLibraryName, 'bin/test.dart');
    expect(hover.containingLibraryPath, testFile);
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

  Future<void> test_getter_synthetic() async {
    addTestFile('''
library my.library;
class A {
  /// doc aaa
  /// doc bbb
  String fff;
}
main(A a) {
  print(a.fff);
}
''');
    var hover = await prepareHover('fff);');
    // element
    expect(hover.containingLibraryName, 'bin/test.dart');
    expect(hover.containingLibraryPath, testFile);
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    expect(hover.elementDescription, 'String fff');
    expect(hover.elementKind, 'field');
    // types
    expect(hover.staticType, 'String');
    expect(hover.propagatedType, isNull);
  }

  Future<void> test_integerLiteral() async {
    addTestFile('''
main() {
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
    addTestFile('''
main() {
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
    var request = AnalysisGetHoverParams('test.dart', 0).toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request =
        AnalysisGetHoverParams(convertPath('/foo/../bar/test.dart'), 0)
            .toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_localVariable_declaration() async {
    addTestFile('''
library my.library;
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
    addTestFile('''
library my.library;
main() {
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

  Future<void> test_method_declaration() async {
    addTestFile('''
library my.library;
class A {
  /// doc aaa
  /// doc bbb
  List<String> mmm(int a, String b) {
  }
}
''');
    var hover = await prepareHover('mmm(int a');
    // element
    expect(hover.containingLibraryName, 'bin/test.dart');
    expect(hover.containingLibraryPath, testFile);
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

  Future<void> test_method_reference() async {
    addTestFile('''
library my.library;
class A {
  List<String> mmm(int a, String b) {
  }
}
main(A a) {
  a.mmm(42, 'foo');
}
''');
    var hover = await prepareHover('mm(42, ');
    // range
    expect(hover.offset, findOffset('mmm(42, '));
    expect(hover.length, 'mmm'.length);
    // element
    expect(hover.containingLibraryName, 'bin/test.dart');
    expect(hover.containingLibraryPath, testFile);
    expect(hover.elementDescription, 'List<String> mmm(int a, String b)');
    expect(hover.elementKind, 'method');
    expect(hover.isDeprecated, isFalse);
    // types
    expect(hover.staticType, 'List<String> Function(int, String)');
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  Future<void> test_method_reference_deprecated() async {
    addTestFile('''
class A {
  @deprecated
  static void test() {}
}
main() {
  A.test();
}
''');
    var hover = await prepareHover('test();');
    // element
    expect(hover.containingLibraryPath, testFile);
    expect(hover.elementDescription, 'void test()');
    expect(hover.elementKind, 'method');
    expect(hover.isDeprecated, isTrue);
  }

  Future<void> test_method_reference_genericMethod() async {
    addTestFile('''
library my.library;

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
    expect(hover.containingLibraryName, 'bin/test.dart');
    expect(hover.containingLibraryPath, testFile);
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

  Future<void> test_mixin_declaration() async {
    addTestFile('''
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

  @failingTest
  Future<void> test_mixin_reference() async {
    addTestFile('''
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
    addTestFile('''
library my.library;
main() {
  // nothing
}
''');
    var hover = await prepareHover('nothing');
    expect(hover, isNull);
  }

  Future<void> test_nonNullable() async {
    createAnalysisOptionsFile(experiments: ['non-nullable']);
    addTestFile('''
int? f(double? a) => null;

main() {
  f(null);
}
''');
    var hover = await prepareHover('f(null)');
    expect(hover.elementDescription, 'int? f(double? a)');
    expect(hover.staticType, 'int? Function(double?)');
  }

  Future<void> test_parameter_declaration_fieldFormal() async {
    addTestFile('''
class A {
  /// The field documentation.
  final int fff;
  A({this.fff});
}
main() {
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
    addTestFile('''
library my.library;
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
    addTestFile('void b([int a=123]) { }');
    var hover = await prepareHover('a=');
    // element
    expect(hover.elementDescription, '[int a = 123]');
    expect(hover.elementKind, 'parameter');
  }

  Future<void> test_parameter_reference_fieldFormal() async {
    addTestFile('''
class A {
  /// The field documentation.
  final int fff;
  A({this.fff});
}
main() {
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

  Future<void> test_setter_hasDocumentation() async {
    addTestFile('''
class A {
  /// getting
  int get foo => 42;
  /// setting
  set foo(int x) {}
}
main(A a) {
  a.foo = 123;
}
''');
    var hover = await prepareHover('foo = ');
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, '''setting''');
    expect(hover.elementDescription, 'void set foo(int x)');
    expect(hover.elementKind, 'setter');
  }

  Future<void> test_setter_noDocumentation() async {
    addTestFile('''
class A {
  /// getting
  int get foo => 42;
  set foo(int x) {}
}
main(A a) {
  a.foo = 123;
}
''');
    var hover = await prepareHover('foo = ');
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, '''getting''');
    expect(hover.elementDescription, 'void set foo(int x)');
    expect(hover.elementKind, 'setter');
  }

  Future<void> test_setter_super_hasDocumentation() async {
    addTestFile('''
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
main(B b) {
  b.foo = 123;
}
''');
    var hover = await prepareHover('foo = ');
    expect(hover.containingClassDescription, 'B');
    expect(hover.dartdoc, '''psetting\n\nCopied from `A`.''');
    expect(hover.elementDescription, 'void set foo(int x)');
    expect(hover.elementKind, 'setter');
  }

  Future<void> test_setter_super_noDocumentation() async {
    addTestFile('''
class A {
  /// pgetting
  int get foo => 42;
  set foo(int x) {}
}
class B extends A {
  int get foo => 42;
  set foo(int x) {}
}
main(B b) {
  b.foo = 123;
}
''');
    var hover = await prepareHover('foo = ');
    expect(hover.containingClassDescription, 'B');
    expect(hover.dartdoc, '''pgetting\n\nCopied from `A`.''');
    expect(hover.elementDescription, 'void set foo(int x)');
    expect(hover.elementKind, 'setter');
  }

  @failingTest
  Future<void> test_setter_super_noSetter() async {
    addTestFile('''
class A {
  /// pgetting
  int get foo => 42;
}
class B extends A {
  set foo(int x) {}
}
main(B b) {
  b.foo = 123;
}
''');
    var hover = await prepareHover('foo = ');
    expect(hover.containingClassDescription, 'B');
    expect(hover.dartdoc, '''pgetting''');
    expect(hover.elementDescription, 'void set foo(int x)');
    expect(hover.elementKind, 'setter');
  }
}
