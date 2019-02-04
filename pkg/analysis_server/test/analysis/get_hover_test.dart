// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';
import '../mocks.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisHoverTest);
  });
}

@reflectiveTest
class AnalysisHoverTest extends AbstractAnalysisTest {
  Future<HoverInformation> prepareHover(String search) {
    int offset = findOffset(search);
    return prepareHoverAt(offset);
  }

  Future<HoverInformation> prepareHoverAt(int offset) async {
    await waitForTasksFinished();
    Request request =
        new AnalysisGetHoverParams(testFile, offset).toRequest('0');
    Response response = await waitResponse(request);
    var result = new AnalysisGetHoverResult.fromResponse(response);
    List<HoverInformation> hovers = result.hovers;
    return hovers.isNotEmpty ? hovers.first : null;
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
  }

  test_class_declaration() async {
    addTestFile('''
class A<E> {}
class I1<K, V> {}
class I2<E> {}
class M1 {}
class M2<E> {}
class B<T> extends A<T> with M1, M2<int> implements I1<int, String>, I2 {}
''');
    HoverInformation hover = await prepareHover('B<T>');
    expect(
        hover.elementDescription,
        'class B<T> extends A<T> with M1, M2<int> '
        'implements I1<int, String>, I2');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  test_class_declaration_abstract() async {
    addTestFile('''
class A {}
abstract class B extends A {}
''');
    HoverInformation hover = await prepareHover('B extends');
    expect(hover.elementDescription, 'abstract class B extends A');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  test_constructor_named() async {
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
      expect(hover.offset, findOffset('new A'));
      expect(hover.length, 'new A.named()'.length);
      // element
      expect(hover.dartdoc, 'my doc');
      expect(hover.elementDescription, 'A.named() → A');
      expect(hover.elementKind, 'constructor');
    }

    {
      HoverInformation hover = await prepareHover('new A');
      onConstructor(hover);
    }
    {
      HoverInformation hover = await prepareHover('named();');
      onConstructor(hover);
    }
  }

  test_constructor_noKeyword_const() async {
    addTestFile('''
library my.library;
class A {
  const A(int i);
}
main() {
  const a = A(0);
}
''');
    HoverInformation hover = await prepareHover('A(0)');
    // range
    expect(hover.offset, findOffset('A(0)'));
    expect(hover.length, 'A(0)'.length);
    // element
    expect(hover.containingLibraryName, 'my.library');
    expect(hover.containingLibraryPath, testFile);
    expect(hover.dartdoc, isNull);
    expect(hover.elementDescription, '(const) A(int i) → A');
    expect(hover.elementKind, 'constructor');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  test_constructor_noKeyword_new() async {
    addTestFile('''
library my.library;
class A {}
main() {
  var a = A();
}
''');
    HoverInformation hover = await prepareHover('A()');
    // range
    expect(hover.offset, findOffset('A()'));
    expect(hover.length, 'A()'.length);
    // element
    expect(hover.containingLibraryName, 'my.library');
    expect(hover.containingLibraryPath, testFile);
    expect(hover.dartdoc, isNull);
    expect(hover.elementDescription, '(new) A() → A');
    expect(hover.elementKind, 'constructor');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  test_constructor_synthetic() async {
    addTestFile('''
library my.library;
class A {
}
main() {
  new A();
}
''');
    HoverInformation hover = await prepareHover('new A');
    // range
    expect(hover.offset, findOffset('new A'));
    expect(hover.length, 'new A()'.length);
    // element
    expect(hover.containingLibraryName, 'my.library');
    expect(hover.containingLibraryPath, testFile);
    expect(hover.dartdoc, isNull);
    expect(hover.elementDescription, 'A() → A');
    expect(hover.elementKind, 'constructor');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  test_constructor_synthetic_withTypeArgument() async {
    addTestFile('''
library my.library;
class A<T> {}
main() {
  new A<String>();
}
''');
    void onConstructor(HoverInformation hover) {
      // range
      expect(hover.offset, findOffset('new A<String>'));
      expect(hover.length, 'new A<String>()'.length);
      // element
      expect(hover.containingLibraryName, 'my.library');
      expect(hover.containingLibraryPath, testFile);
      expect(hover.dartdoc, isNull);
      expect(hover.elementDescription, 'A() → A<String>');
      expect(hover.elementKind, 'constructor');
      // types
      expect(hover.staticType, isNull);
      expect(hover.propagatedType, isNull);
      // no parameter
      expect(hover.parameter, isNull);
    }

    {
      HoverInformation hover = await prepareHover('new A');
      onConstructor(hover);
    }
    {
      HoverInformation hover = await prepareHover('A<String>()');
      onConstructor(hover);
    }
    {
      HoverInformation hover = await prepareHover('String>');
      expect(hover.offset, findOffset('String>'));
      expect(hover.length, 'String'.length);
      expect(hover.elementKind, 'class');
    }
  }

  test_dartdoc_block() async {
    addTestFile('''
/**
 * doc aaa
 * doc bbb
 */
main() {
}
''');
    HoverInformation hover = await prepareHover('main() {');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
  }

  test_dartdoc_inherited_fromInterface() async {
    addTestFile('''
class A {
  /// my doc
  m() {} // in A
}

class B implements A {
  m() {} // in B
}
''');
    HoverInformation hover = await prepareHover('m() {} // in B');
    expect(hover.dartdoc, '''my doc\n\nCopied from `A`.''');
  }

  test_dartdoc_inherited_fromSuper_direct() async {
    addTestFile('''
class A {
  /// my doc
  m() {} // in A
}

class B extends A {
  m() {} // in B
}
''');
    HoverInformation hover = await prepareHover('m() {} // in B');
    expect(hover.dartdoc, '''my doc\n\nCopied from `A`.''');
  }

  test_dartdoc_inherited_fromSuper_indirect() async {
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
    HoverInformation hover = await prepareHover('m() {} // in C');
    expect(hover.dartdoc, '''my doc\n\nCopied from `A`.''');
  }

  test_dartdoc_inherited_preferSuper() async {
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
    HoverInformation hover = await prepareHover('m() {} // in C');
    expect(hover.dartdoc, '''my doc\n\nCopied from `A`.''');
  }

  test_dartdoc_line() async {
    addTestFile('''
/// doc aaa
/// doc bbb
main() {
}
''');
    HoverInformation hover = await prepareHover('main() {');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
  }

  test_enum_declaration() async {
    addTestFile('''
enum MyEnum {AAA, BBB, CCC}
''');
    HoverInformation hover = await prepareHover('MyEnum');
    expect(hover.elementDescription, 'enum MyEnum');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  test_function_topLevel_declaration() async {
    addTestFile('''
library my.library;
/// doc aaa
/// doc bbb
List<String> fff(int a, String b) {
}
''');
    HoverInformation hover = await prepareHover('fff(int a');
    // element
    expect(hover.containingLibraryName, 'my.library');
    expect(hover.containingLibraryPath, testFile);
    expect(hover.containingClassDescription, isNull);
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    expect(hover.elementDescription, 'fff(int a, String b) → List<String>');
    expect(hover.elementKind, 'function');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  test_getter_synthetic() async {
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
    HoverInformation hover = await prepareHover('fff);');
    // element
    expect(hover.containingLibraryName, 'my.library');
    expect(hover.containingLibraryPath, testFile);
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    expect(hover.elementDescription, 'String fff');
    expect(hover.elementKind, 'field');
    // types
    expect(hover.staticType, 'String');
    expect(hover.propagatedType, isNull);
  }

  test_integerLiteral() async {
    addTestFile('''
main() {
  foo(123);
}
foo(Object myParameter) {}
''');
    HoverInformation hover = await prepareHover('123');
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

  test_integerLiteral_promoted() async {
    addTestFile('''
main() {
  foo(123);
}
foo(double myParameter) {}
''');
    HoverInformation hover = await prepareHover('123');
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

  test_invalidFilePathFormat_notAbsolute() async {
    var request = new AnalysisGetHoverParams('test.dart', 0).toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  test_invalidFilePathFormat_notNormalized() async {
    var request =
        new AnalysisGetHoverParams(convertPath('/foo/../bar/test.dart'), 0)
            .toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  test_localVariable_declaration() async {
    addTestFile('''
library my.library;
class A {
  m() {
    num vvv = 42;
  }
}
''');
    HoverInformation hover = await prepareHover('vvv = 42');
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

  test_localVariable_reference_withPropagatedType() async {
    addTestFile('''
library my.library;
main() {
  var vvv = 123;
  print(vvv);
}
''');
    HoverInformation hover = await prepareHover('vvv);');
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

  test_method_declaration() async {
    addTestFile('''
library my.library;
class A {
  /// doc aaa
  /// doc bbb
  List<String> mmm(int a, String b) {
  }
}
''');
    HoverInformation hover = await prepareHover('mmm(int a');
    // element
    expect(hover.containingLibraryName, 'my.library');
    expect(hover.containingLibraryPath, testFile);
    expect(hover.containingClassDescription, 'A');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    expect(hover.elementDescription, 'mmm(int a, String b) → List<String>');
    expect(hover.elementKind, 'method');
    // types
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  test_method_reference() async {
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
    HoverInformation hover = await prepareHover('mm(42, ');
    // range
    expect(hover.offset, findOffset('mmm(42, '));
    expect(hover.length, 'mmm'.length);
    // element
    expect(hover.containingLibraryName, 'my.library');
    expect(hover.containingLibraryPath, testFile);
    expect(hover.elementDescription, 'mmm(int a, String b) → List<String>');
    expect(hover.elementKind, 'method');
    expect(hover.isDeprecated, isFalse);
    // types
    expect(hover.staticType, '(int, String) → List<String>');
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  test_method_reference_deprecated() async {
    addTestFile('''
class A {
  @deprecated
  static void test() {}
}
main() {
  A.test();
}
''');
    HoverInformation hover = await prepareHover('test();');
    // element
    expect(hover.containingLibraryPath, testFile);
    expect(hover.elementDescription, 'test() → void');
    expect(hover.elementKind, 'method');
    expect(hover.isDeprecated, isTrue);
  }

  test_method_reference_genericMethod() async {
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
    HoverInformation hover = await prepareHover('nsform(n');
    // range
    expect(hover.offset, findOffset('transform(n'));
    expect(hover.length, 'transform'.length);
    // element
    expect(hover.containingLibraryName, 'my.library');
    expect(hover.containingLibraryPath, testFile);
    expect(hover.elementDescription,
        'Stream.transform<S>(StreamTransformer<int, S> streamTransformer) → Stream<S>');
    expect(hover.elementKind, 'method');
    expect(hover.isDeprecated, isFalse);
    // types
    expect(hover.staticType,
        '(StreamTransformer<int, dynamic>) → Stream<dynamic>');
    expect(hover.propagatedType, isNull);
    // no parameter
    expect(hover.parameter, isNull);
  }

  test_mixin_declaration() async {
    addTestFile('''
mixin A on B, C implements D, E {}
class B {}
class C {}
class D {}
class E {}
''');
    HoverInformation hover = await prepareHover('A');
    expect(hover.elementDescription, 'mixin A on B, C implements D, E');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  @failingTest
  test_mixin_reference() async {
    addTestFile('''
mixin A {}
abstract class B {}
class C with A implements B {}
''');
    HoverInformation hover = await prepareHover('A i');
    expect(hover.elementDescription, 'mixin A');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  test_noHoverInfo() async {
    addTestFile('''
library my.library;
main() {
  // nothing
}
''');
    HoverInformation hover = await prepareHover('nothing');
    expect(hover, isNull);
  }

  test_parameter_declaration_fieldFormal() async {
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
    HoverInformation hover = await prepareHover('fff});');
    expect(hover.containingLibraryName, isNull);
    expect(hover.containingLibraryPath, isNull);
    expect(hover.containingClassDescription, isNull);
    expect(hover.dartdoc, 'The field documentation.');
    expect(hover.elementDescription, '{int fff}');
    expect(hover.elementKind, 'parameter');
    expect(hover.staticType, 'int');
  }

  test_parameter_declaration_required() async {
    addTestFile('''
library my.library;
class A {
  /// The method documentation.
  m(int p) {
  }
}
''');
    HoverInformation hover = await prepareHover('p) {');
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

  test_parameter_reference_fieldFormal() async {
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
    HoverInformation hover = await prepareHover('fff: 42');
    expect(hover.containingLibraryName, isNull);
    expect(hover.containingLibraryPath, isNull);
    expect(hover.containingClassDescription, isNull);
    expect(hover.dartdoc, 'The field documentation.');
    expect(hover.elementDescription, '{int fff}');
    expect(hover.elementKind, 'parameter');
    expect(hover.staticType, 'int');
  }
}
