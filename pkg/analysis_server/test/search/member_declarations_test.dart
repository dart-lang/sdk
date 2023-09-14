// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_search_domain.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MemberDeclarationsTest);
  });
}

@reflectiveTest
class MemberDeclarationsTest extends AbstractSearchDomainTest {
  void assertHasDeclaration(ElementKind kind, String className) {
    var result = findTopLevelResult(kind, className);
    if (result == null) {
      fail('Not found: kind=$kind in="$className"\nin\n${results.join('\n')}');
    }
    this.result = result;
  }

  Future<void> findMemberDeclarations(String name) async {
    await waitForTasksFinished();
    var request = SearchFindMemberDeclarationsParams(name).toRequest('0');
    var response = await handleSuccessfulRequest(request);
    var result = SearchFindMemberDeclarationsResult.fromResponse(response);
    searchId = result.id;
    return waitForSearchResults();
  }

  SearchResult? findTopLevelResult(ElementKind kind, String enclosingClass) {
    for (var result in results) {
      var element = result.path[0];
      var clazz = result.path[1];
      if (element.kind == kind && clazz.name == enclosingClass) {
        return result;
      }
    }
    return null;
  }

  Future<void> test_class_methodField() async {
    addTestFile('''
class A {
  foo() {}
  bar() {}
}
class B {
  int foo;
}
''');
    await findMemberDeclarations('foo');
    expect(results, hasLength(2));
    assertHasDeclaration(ElementKind.METHOD, 'A');
    assertHasDeclaration(ElementKind.FIELD, 'B');
  }

  Future<void> test_class_methodGetter() async {
    addTestFile('''
class A {
  foo() {}
  bar() {}
}
class B {
  get foo => null;
}
''');
    await findMemberDeclarations('foo');
    expect(results, hasLength(2));
    assertHasDeclaration(ElementKind.METHOD, 'A');
    assertHasDeclaration(ElementKind.GETTER, 'B');
  }

  Future<void> test_class_methodGetterSetter() async {
    addTestFile('''
class A {
  foo() {}
  bar() {}
}
class B {
  get foo => null;
  set foo(x) {}
}
''');
    await findMemberDeclarations('foo');
    expect(results, hasLength(3));
    assertHasDeclaration(ElementKind.METHOD, 'A');
    assertHasDeclaration(ElementKind.GETTER, 'B');
    assertHasDeclaration(ElementKind.SETTER, 'B');
  }

  Future<void> test_class_methodMethod() async {
    addTestFile('''
class A {
  foo() {}
  bar() {}
}
class B {
  foo() {}
}
''');
    await findMemberDeclarations('foo');
    expect(results, hasLength(2));
    assertHasDeclaration(ElementKind.METHOD, 'A');
    assertHasDeclaration(ElementKind.METHOD, 'B');
  }

  Future<void> test_class_methodSetter() async {
    addTestFile('''
class A {
  foo() {}
  bar() {}
}
class B {
  set foo(x) {}
}
''');
    await findMemberDeclarations('foo');
    expect(results, hasLength(2));
    assertHasDeclaration(ElementKind.METHOD, 'A');
    assertHasDeclaration(ElementKind.SETTER, 'B');
  }

  Future<void> test_enum_methodField() async {
    addTestFile('''
enum A {
  v;
  void foo() {}
  void bar() {}
}

enum B {
  v;
  int foo;
}
''');
    await findMemberDeclarations('foo');
    expect(results, hasLength(2));
    assertHasDeclaration(ElementKind.METHOD, 'A');
    assertHasDeclaration(ElementKind.FIELD, 'B');
  }

  Future<void> test_enum_methodGetter() async {
    addTestFile('''
enum A {
  v;
  void foo() {}
  void bar() {}
}

enum B {
  v;
  int get foo => 0;
}
''');
    await findMemberDeclarations('foo');
    expect(results, hasLength(2));
    assertHasDeclaration(ElementKind.METHOD, 'A');
    assertHasDeclaration(ElementKind.GETTER, 'B');
  }

  Future<void> test_enum_methodGetterSetter() async {
    addTestFile('''
enum A {
  v;
  void foo() {}
  void bar() {}
}

enum B {
  v;
  int get foo => 0;
  set foo(int x) {}
}
''');
    await findMemberDeclarations('foo');
    expect(results, hasLength(3));
    assertHasDeclaration(ElementKind.METHOD, 'A');
    assertHasDeclaration(ElementKind.GETTER, 'B');
    assertHasDeclaration(ElementKind.SETTER, 'B');
  }

  Future<void> test_enum_methodMethod() async {
    addTestFile('''
enum A {
  v;
  void foo() {}
  void bar() {}
}

enum B {
  v;
  void foo() {}
}
''');
    await findMemberDeclarations('foo');
    expect(results, hasLength(2));
    assertHasDeclaration(ElementKind.METHOD, 'A');
    assertHasDeclaration(ElementKind.METHOD, 'B');
  }

  Future<void> test_enums_methodSetter() async {
    addTestFile('''
enum A {
  v;
  void foo() {}
  void bar() {}
}

enum B {
  v;
  set foo(int x) {}
}
''');
    await findMemberDeclarations('foo');
    expect(results, hasLength(2));
    assertHasDeclaration(ElementKind.METHOD, 'A');
    assertHasDeclaration(ElementKind.SETTER, 'B');
  }

  Future<void> test_extensionType_methodGetter() async {
    addTestFile('''
extension type A(int it) {
  void foo() {}
  void bar() {}
}
extension type B(int it) {
  int get foo => 0;
}
''');
    await findMemberDeclarations('foo');
    expect(results, hasLength(2));
    assertHasDeclaration(ElementKind.METHOD, 'A');
    assertHasDeclaration(ElementKind.GETTER, 'B');
  }

  Future<void> test_extensionType_methodGetterSetter() async {
    addTestFile('''
extension type A(int it) {
  void foo() {}
  void bar() {}
}
extension type B(int it) {
  int get foo => 0;
  set foo(int _) {}
}
''');
    await findMemberDeclarations('foo');
    expect(results, hasLength(3));
    assertHasDeclaration(ElementKind.METHOD, 'A');
    assertHasDeclaration(ElementKind.GETTER, 'B');
    assertHasDeclaration(ElementKind.SETTER, 'B');
  }

  Future<void> test_extensionType_methodMethod() async {
    addTestFile('''
extension type A(int it) {
  void foo() {}
  void bar() {}
}
extension type B(int it) {
  void foo() {}
}
''');
    await findMemberDeclarations('foo');
    expect(results, hasLength(2));
    assertHasDeclaration(ElementKind.METHOD, 'A');
    assertHasDeclaration(ElementKind.METHOD, 'B');
  }

  Future<void> test_extensionType_methodSetter() async {
    addTestFile('''
extension type A(int it) {
  void foo() {}
  void bar() {}
}
extension type B(int it) {
  set foo(int _) {}
}
''');
    await findMemberDeclarations('foo');
    expect(results, hasLength(2));
    assertHasDeclaration(ElementKind.METHOD, 'A');
    assertHasDeclaration(ElementKind.SETTER, 'B');
  }

  Future<void> test_localVariable() async {
    addTestFile('''
class A {
  void f() {
    var foo = 42;
  }
}
''');
    await findMemberDeclarations('foo');
    expect(results, isEmpty);
  }

  Future<void> test_localVariable_forIn() async {
    addTestFile('''
class A {
  void f() {
    for (int foo in []) {
    }
  }
}
''');
    await findMemberDeclarations('foo');
    expect(results, isEmpty);
  }
}
