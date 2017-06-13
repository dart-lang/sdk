// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

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

  test_class() async {
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

  test_class_abstract() async {
    addTestFile('''
class A {}
abstract class B extends A {}
''');
    HoverInformation hover = await prepareHover('B extends');
    expect(hover.elementDescription, 'abstract class B extends A');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  test_dartdoc_clunky() async {
    addTestFile('''
library my.library;
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

  test_dartdoc_elegant() async {
    addTestFile('''
library my.library;
/// doc aaa
/// doc bbb
main() {
}
''');
    HoverInformation hover = await prepareHover('main() {');
    expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
  }

  test_dartdoc_inherited_methodByMethod_fromInterface() async {
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

  test_dartdoc_inherited_methodByMethod_fromSuper_direct() async {
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

  test_dartdoc_inherited_methodByMethod_fromSuper_indirect() async {
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

  test_dartdoc_inherited_methodByMethod_preferSuper() async {
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

  test_enum() async {
    addTestFile('''
enum MyEnum {AAA, BBB, CCC}
''');
    HoverInformation hover = await prepareHover('MyEnum');
    expect(hover.elementDescription, 'enum MyEnum');
    expect(hover.staticType, isNull);
    expect(hover.propagatedType, isNull);
  }

  test_expression_function() async {
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

  test_expression_literal_noElement() async {
    addTestFile('''
main() {
  foo(123);
}
foo(Object myParameter) {}
''');
    HoverInformation hover = await prepareHover('123');
    // literal, no Element
    expect(hover.containingClassDescription, isNull);
    expect(hover.elementDescription, isNull);
    expect(hover.elementKind, isNull);
    // types
    expect(hover.staticType, 'int');
    expect(hover.propagatedType, isNull);
    // parameter
    expect(hover.parameter, 'Object myParameter');
  }

  test_expression_method() async {
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

  test_expression_method_deprecated() async {
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

  test_expression_method_invocation() async {
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

  test_expression_method_invocation_genericMethod() async {
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

  test_expression_parameter() async {
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

  test_expression_parameter_fieldFormal_declaration() async {
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

  test_expression_parameter_fieldFormal_use() async {
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

  test_expression_syntheticGetter_invocation() async {
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

  test_expression_variable_hasPropagatedType() async {
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
    expect(hover.elementDescription, 'dynamic vvv');
    expect(hover.elementKind, 'local variable');
    // types
    expect(hover.staticType, 'dynamic');
    expect(hover.propagatedType, 'int');
  }

  test_expression_variable_inMethod() async {
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
    expect(hover.propagatedType, 'int');
    // no parameter
    expect(hover.parameter, isNull);
  }

  test_instanceCreation_implicit() async {
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

  test_instanceCreation_implicit_withTypeArgument() async {
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

  test_instanceCreation_named() async {
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
}
