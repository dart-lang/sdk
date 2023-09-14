// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_search_domain.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementReferencesTest);
  });
}

@reflectiveTest
class ElementReferencesTest extends AbstractSearchDomainTest {
  Element? searchElement;

  void assertHasRef(SearchResultKind kind, String search, bool isPotential) {
    assertHasResult(kind, search);
    expect(result.isPotential, isPotential);
  }

  Future<void> assertReferences(
    String content, {
    required ElementKind kind,
    required Map<int, SearchResultKind> resultKinds,
  }) async {
    final code = TestCode.parse(content);
    expect(
      resultKinds,
      hasLength(code.ranges.length),
      reason: "'resultsKinds' should have the same number of items as there "
          "are ranges in 'content'",
    );

    addTestFile(code.code);
    await findElementReferences(offset: code.position.offset, false);

    expect(searchElement!.kind, kind);
    final expected = resultKinds.entries.map((entry) {
      final index = entry.key;
      final kind = entry.value;
      final range = code.ranges[index].sourceRange;
      return {
        'kind': kind,
        'path': testFile.path,
        'range': range.offset,
        'length': range.length,
      };
    }).toSet();
    final actual = results
        .map((result) => {
              'kind': result.kind,
              'path': result.location.file,
              'range': result.location.offset,
              'length': result.location.length,
            })
        .toSet();
    expect(actual, equals(expected));
  }

  Future<void> findElementReferences(
    bool includePotential, {
    // TODO(dantup): Remove 'search' parameter and convert original tests to go
    //  through 'assertReferences' using parsed code.
    String? search,
    int? offset,
  }) async {
    assert(search != null || offset != null);
    offset ??= findOffset(search!);
    await waitForTasksFinished();
    var request = SearchFindElementReferencesParams(
            testFile.path, offset, includePotential)
        .toRequest('0');
    var response = await handleSuccessfulRequest(request);
    var result = SearchFindElementReferencesResult.fromResponse(response);
    searchId = result.id;
    searchElement = result.element;
    if (searchId != null) {
      await waitForSearchResults();
    }
  }

  Future<void> test_class_constructor_named() async {
    addTestFile('''
/// [new A.named] 1
class A {
  A.named() {}
  A.other() : this.named(); // 2
}

class B extends A {
  B() : super.named(); // 3
  factory B.other() = A.named; // 4
}

void f() {
  A.named(); // 5
  A.named; // 6
}
''');
    await findElementReferences(search: 'named() {}', false);
    expect(searchElement!.kind, ElementKind.CONSTRUCTOR);
    expect(results, hasLength(6));
    assertHasResult(SearchResultKind.REFERENCE, '.named] 1', 6);
    assertHasResult(SearchResultKind.INVOCATION, '.named(); // 2', 6);
    assertHasResult(SearchResultKind.INVOCATION, '.named(); // 3', 6);
    assertHasResult(SearchResultKind.REFERENCE, '.named; // 4', 6);
    assertHasResult(SearchResultKind.INVOCATION, '.named(); // 5', 6);
    assertHasResult(SearchResultKind.REFERENCE, '.named; // 6', 6);
  }

  Future<void> test_class_constructor_named_potential() async {
    // Constructors in other classes shouldn't be considered potential matches.
    // Unresolved method calls should also not be considered potential matches,
    // because constructor call sites are statically bound to their targets.
    addTestFile('''
class A {
  A.named(p); // A
}
class B {
  B.named(p);
}
f(x) {
  new A.named(1);
  new B.named(2);
  x.named(3);
}
''');
    await findElementReferences(search: 'named(p); // A', true);
    expect(searchElement!.kind, ElementKind.CONSTRUCTOR);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.INVOCATION, '.named(1)', 6);
  }

  Future<void> test_class_constructor_unnamed() async {
    addTestFile('''
/// [new A] 1
/// [A.new] 2
class A {
  A() {}
  A.other() : this(); // 3
}

class B extends A {
  B() : super(); // 4
  factory B.other() = A; // 5
}

void f() {
  A(); // 6
  A.new; // 7
}
''');
    await findElementReferences(search: 'A() {}', false);
    expect(searchElement!.kind, ElementKind.CONSTRUCTOR);
    expect(results, hasLength(7));
    assertHasResult(SearchResultKind.REFERENCE, '] 1', 0);
    assertHasResult(SearchResultKind.REFERENCE, '.new] 2', 4);
    assertHasResult(SearchResultKind.INVOCATION, '(); // 3', 0);
    assertHasResult(SearchResultKind.INVOCATION, '(); // 4', 0);
    assertHasResult(SearchResultKind.REFERENCE, '; // 5', 0);
    assertHasResult(SearchResultKind.INVOCATION, '(); // 6', 0);
    assertHasResult(SearchResultKind.REFERENCE, '.new; // 7', 4);
  }

  Future<void> test_class_constructor_unnamed_potential() async {
    // Constructors in other classes shouldn't be considered potential matches,
    // even if they are also unnamed (since constructor call sites are
    // statically bound to their targets).
    // Also, assignments to local variables shouldn't be considered potential
    // matches.
    addTestFile('''
class A {
  A(p); // A
}
class B {
  B(p);
  foo() {
    int k;
    k = 3;
  }
}
void f() {
  new A(1);
  new B(2);
}
''');
    await findElementReferences(search: 'A(p)', true);
    expect(searchElement!.kind, ElementKind.CONSTRUCTOR);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.INVOCATION, '(1)', 0);
  }

  Future<void> test_class_field_explicit() async {
    addTestFile('''
class A {
  var fff; // declaration
  A(this.fff); // in constructor
  A.named() : fff = 1;
  m() {
    fff = 2;
    fff += 3;
    print(fff); // in m()
    fff(); // in m()
  }
}
void f(A a) {
  a.fff = 20;
  a.fff += 30;
  print(a.fff); // in f()
  a.fff(); // in f()
}
''');
    await findElementReferences(search: 'fff; // declaration', false);
    expect(searchElement!.kind, ElementKind.FIELD);
    expect(results, hasLength(10));
    assertHasResult(SearchResultKind.WRITE, 'fff); // in constructor');
    assertHasResult(SearchResultKind.WRITE, 'fff = 1;');
    // m()
    assertHasResult(SearchResultKind.WRITE, 'fff = 2;');
    assertHasResult(SearchResultKind.WRITE, 'fff += 3;');
    assertHasResult(SearchResultKind.READ, 'fff); // in m()');
    assertHasResult(SearchResultKind.READ, 'fff(); // in m()');
    // f()
    assertHasResult(SearchResultKind.WRITE, 'fff = 20;');
    assertHasResult(SearchResultKind.WRITE, 'fff += 30;');
    assertHasResult(SearchResultKind.READ, 'fff); // in f()');
    assertHasResult(SearchResultKind.READ, 'fff(); // in f()');
  }

  Future<void> test_class_field_implicit() async {
    addTestFile('''
class A {
  var  get fff => null;
  void set fff(x) {}
  m() {
    print(fff); // in m()
    fff = 1;
  }
}
void f(A a) {
  print(a.fff); // in f()
  a.fff = 10;
}
''');
    {
      await findElementReferences(search: 'fff =>', false);
      expect(searchElement!.kind, ElementKind.FIELD);
      expect(results, hasLength(4));
      assertHasResult(SearchResultKind.READ, 'fff); // in m()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 1;');
      assertHasResult(SearchResultKind.READ, 'fff); // in f()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 10;');
    }
    {
      await findElementReferences(search: 'fff(x) {}', false);
      expect(results, hasLength(4));
      assertHasResult(SearchResultKind.READ, 'fff); // in m()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 1;');
      assertHasResult(SearchResultKind.READ, 'fff); // in f()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 10;');
    }
  }

  Future<void> test_class_field_inFormalParameter() async {
    addTestFile('''
class A {
  var fff; // declaration
  A(this.fff); // in constructor
  m() {
    fff = 2;
    print(fff); // in m()
  }
}
''');
    await findElementReferences(search: 'fff); // in constructor', false);
    expect(searchElement!.kind, ElementKind.FIELD);
    expect(results, hasLength(3));
    assertHasResult(SearchResultKind.WRITE, 'fff); // in constructor');
    assertHasResult(SearchResultKind.WRITE, 'fff = 2;');
    assertHasResult(SearchResultKind.READ, 'fff); // in m()');
  }

  Future<void> test_class_getter_in_objectPattern() async {
    addTestFile('''
void f(Object? x) {
  if (x case A(foo: 0)) {}
  if (x case A(: var foo)) {}
}

class A {
  int get foo => 0;
}
''');
    await findElementReferences(search: 'foo =>', false);
    expect(searchElement!.kind, ElementKind.FIELD);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.READ, 'foo: 0');
    assertHasResult(SearchResultKind.READ, ': var foo');
  }

  Future<void> test_class_method() async {
    addTestFile('''
class A {
  mmm(p) {}
  m() {
    mmm(1);
    print(mmm); // in m()
  }
}
void f(A a) {
  a.mmm(10);
  print(a.mmm); // in f()
}
''');
    await findElementReferences(search: 'mmm(p) {}', false);
    expect(searchElement!.kind, ElementKind.METHOD);
    expect(results, hasLength(4));
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(1);');
    assertHasResult(SearchResultKind.REFERENCE, 'mmm); // in m()');
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(10);');
    assertHasResult(SearchResultKind.REFERENCE, 'mmm); // in f()');
  }

  Future<void> test_class_method_propagatedType() async {
    addTestFile('''
class A {
  mmm(p) {}
}
void f() {
  var a = new A();
  a.mmm(10);
  print(a.mmm);
}
''');
    await findElementReferences(search: 'mmm(p) {}', false);
    expect(searchElement!.kind, ElementKind.METHOD);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(10);');
    assertHasResult(SearchResultKind.REFERENCE, 'mmm);');
  }

  Future<void> test_enum_constructor_named() async {
    addTestFile('''
/// [new E.named] 1
enum E {
  v.named(); // 2
  const E.named(); // 3
  const E.other() : this.named(); // 4
}
''');
    await findElementReferences(search: 'named(); // 3', false);
    expect(searchElement!.kind, ElementKind.CONSTRUCTOR);
    expect(results, hasLength(3));
    assertHasResult(SearchResultKind.REFERENCE, '.named] 1', 6);
    assertHasResult(SearchResultKind.INVOCATION, '.named(); // 2', 6);
    assertHasResult(SearchResultKind.INVOCATION, '.named(); // 4', 6);
  }

  Future<void> test_enum_constructor_unnamed() async {
    addTestFile('''
/// [new E] 1
enum E {
  v1, // 2
  v2(), // 3
  v3.new(); // 4
  const E(); // 5
  const E.other() : this(); // 6
}
''');
    await findElementReferences(search: 'E(); // 5', false);
    expect(searchElement!.kind, ElementKind.CONSTRUCTOR);
    expect(results, hasLength(5));
    assertHasResult(SearchResultKind.REFERENCE, '] 1', 0);
    assertHasResult(SearchResultKind.INVOCATION, ', // 2', 0);
    assertHasResult(SearchResultKind.INVOCATION, '(), // 3', 0);
    assertHasResult(SearchResultKind.INVOCATION, '.new(); // 4', 4);
    assertHasResult(SearchResultKind.INVOCATION, '(); // 6', 0);
  }

  Future<void> test_enum_field_explicit() async {
    addTestFile('''
enum E {
  v;
  var fff; // 01
  E(this.fff); // 02
  E.named() : fff = 0; // 03
  void foo() {
    fff = 0; // 04 
    fff += 0; // 05
    fff; // 06
    fff(); // 07
  }
}

void f(E e) {
  e.fff = 0; // 08
  e.fff += 0; // 09
  e.fff; // 10
  e.fff(); // 11
}
''');
    await findElementReferences(search: 'fff; // 01', false);
    expect(searchElement!.kind, ElementKind.FIELD);
    expect(results, hasLength(10));
    assertHasResult(SearchResultKind.WRITE, 'fff); // 02');
    assertHasResult(SearchResultKind.WRITE, 'fff = 0; // 03');
    // foo()
    assertHasResult(SearchResultKind.WRITE, 'fff = 0; // 04');
    assertHasResult(SearchResultKind.WRITE, 'fff += 0; // 05');
    assertHasResult(SearchResultKind.READ, 'fff; // 06');
    assertHasResult(SearchResultKind.READ, 'fff(); // 07');
    // f()
    assertHasResult(SearchResultKind.WRITE, 'fff = 0; // 08');
    assertHasResult(SearchResultKind.WRITE, 'fff += 0; // 09');
    assertHasResult(SearchResultKind.READ, 'fff; // 10');
    assertHasResult(SearchResultKind.READ, 'fff(); // 11');
  }

  Future<void> test_enum_field_implicit() async {
    addTestFile('''
enum E {
  v;
  int get fff => 0;
  void set fff(_) {}
  void foo() {
    fff; // 1
    fff = 0; // 2
  }
}

void f(E e) {
  e.fff; // 3
  e.fff = 0; // 4
}
''');
    {
      await findElementReferences(search: 'fff =>', false);
      expect(searchElement!.kind, ElementKind.FIELD);
      expect(results, hasLength(4));
      assertHasResult(SearchResultKind.READ, 'fff; // 1');
      assertHasResult(SearchResultKind.WRITE, 'fff = 0; // 2');
      assertHasResult(SearchResultKind.READ, 'fff; // 3');
      assertHasResult(SearchResultKind.WRITE, 'fff = 0; // 4');
    }
    {
      await findElementReferences(search: 'fff(_) {}', false);
      expect(results, hasLength(4));
      assertHasResult(SearchResultKind.READ, 'fff; // 1');
      assertHasResult(SearchResultKind.WRITE, 'fff = 0; // 2');
      assertHasResult(SearchResultKind.READ, 'fff; // 3');
      assertHasResult(SearchResultKind.WRITE, 'fff = 0; // 4');
    }
  }

  Future<void> test_enum_method() async {
    addTestFile('''
enum E {
  v;
  void foo() {}
  void bar() {
    foo(); // 1
    this.foo(); // 2
  }
}

void f(E e) {
  e.foo(); // 3
  e.foo; // 4
}
''');
    await findElementReferences(search: 'foo() {}', false);
    expect(searchElement!.kind, ElementKind.METHOD);
    expect(results, hasLength(4));
    assertHasResult(SearchResultKind.INVOCATION, 'foo(); // 1');
    assertHasResult(SearchResultKind.INVOCATION, 'foo(); // 2');
    assertHasResult(SearchResultKind.INVOCATION, 'foo(); // 3');
    assertHasResult(SearchResultKind.REFERENCE, 'foo; // 4');
  }

  Future<void> test_extension() async {
    addTestFile('''
extension E on int {
  static void foo() {}
  void bar() {}
}

void f() {
  E.foo();
  E(0).bar();
}
''');
    await findElementReferences(search: 'E on int', false);
    expect(searchElement!.kind, ElementKind.EXTENSION);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.REFERENCE, 'E.foo();');
    assertHasResult(SearchResultKind.REFERENCE, 'E(0)');
  }

  Future<void> test_extension_field_explicit_static() async {
    addTestFile('''
extension E on int {
  static var fff; // declaration

  void m() {
    fff = 2;
    fff += 3;
    print(fff); // in m()
    fff(); // in m()
  }
}

void f() {
  E.fff = 20;
  E.fff += 30;
  print(E.fff); // in f()
  E.fff(); // in f()
}
''');
    await findElementReferences(search: 'fff; // declaration', false);
    expect(searchElement!.kind, ElementKind.FIELD);
    expect(results, hasLength(8));
    // m()
    assertHasResult(SearchResultKind.WRITE, 'fff = 2;');
    assertHasResult(SearchResultKind.WRITE, 'fff += 3;');
    assertHasResult(SearchResultKind.READ, 'fff); // in m()');
    assertHasResult(SearchResultKind.READ, 'fff(); // in m()');
    // f()
    assertHasResult(SearchResultKind.WRITE, 'fff = 20;');
    assertHasResult(SearchResultKind.WRITE, 'fff += 30;');
    assertHasResult(SearchResultKind.READ, 'fff); // in f()');
    assertHasResult(SearchResultKind.READ, 'fff(); // in f()');
  }

  Future<void> test_extension_field_implicit_instance() async {
    addTestFile('''
extension E on int {
  var get fff => null;
  set fff(x) {}
  m() {
    print(fff); // in m()
    fff = 1;
  }
}
void f() {
  print(0.fff); // in f()
  0.fff = 10;
}
''');
    {
      await findElementReferences(search: 'fff =>', false);
      expect(searchElement!.kind, ElementKind.FIELD);
      expect(results, hasLength(4));
      assertHasResult(SearchResultKind.READ, 'fff); // in m()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 1;');
      assertHasResult(SearchResultKind.READ, 'fff); // in f()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 10;');
    }
    {
      await findElementReferences(search: 'fff(x) {}', false);
      expect(results, hasLength(4));
      assertHasResult(SearchResultKind.READ, 'fff); // in m()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 1;');
      assertHasResult(SearchResultKind.READ, 'fff); // in f()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 10;');
    }
  }

  Future<void> test_extension_field_implicit_static() async {
    addTestFile('''
extension E on int {
  static var get fff => null;
  static set fff(x) {}
  m() {
    print(fff); // in m()
    fff = 1;
  }
}
void f() {
  print(E.fff); // in f()
  E.fff = 10;
}
''');
    {
      await findElementReferences(search: 'fff =>', false);
      expect(searchElement!.kind, ElementKind.FIELD);
      expect(results, hasLength(4));
      assertHasResult(SearchResultKind.READ, 'fff); // in m()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 1;');
      assertHasResult(SearchResultKind.READ, 'fff); // in f()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 10;');
    }
    {
      await findElementReferences(search: 'fff(x) {}', false);
      expect(results, hasLength(4));
      assertHasResult(SearchResultKind.READ, 'fff); // in m()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 1;');
      assertHasResult(SearchResultKind.READ, 'fff); // in f()');
      assertHasResult(SearchResultKind.WRITE, 'fff = 10;');
    }
  }

  Future<void> test_extension_method() async {
    addTestFile('''
extension E on int {
  void foo() {}
}

void f() {
  E(0).foo(); // 1
  E(0).foo; // 2
  0.foo(); // 3
  0.foo; // 4
}
''');
    await findElementReferences(search: 'foo() {}', false);
    expect(searchElement!.kind, ElementKind.METHOD);
    expect(results, hasLength(4));
    assertHasResult(SearchResultKind.INVOCATION, 'foo(); // 1');
    assertHasResult(SearchResultKind.REFERENCE, 'foo; // 2');
    assertHasResult(SearchResultKind.INVOCATION, 'foo(); // 3');
    assertHasResult(SearchResultKind.REFERENCE, 'foo; // 4');
  }

  Future<void> test_extensionType_constructor_named() async {
    addTestFile('''
/// [new A.named] 1
extension type A(int it) {
  A.named() : this(0);
  A.other() : this.named(); // 2
}

void f() {
  A.named(); // 3
  A.named; // 4
}
''');
    await findElementReferences(search: 'named() :', false);
    expect(searchElement!.kind, ElementKind.CONSTRUCTOR);
    expect(results, hasLength(4));
    assertHasResult(SearchResultKind.REFERENCE, '.named] 1', 6);
    assertHasResult(SearchResultKind.INVOCATION, '.named(); // 2', 6);
    assertHasResult(SearchResultKind.INVOCATION, '.named(); // 3', 6);
    assertHasResult(SearchResultKind.REFERENCE, '.named; // 4', 6);
  }

  Future<void> test_extensionType_constructor_unnamed() async {
    addTestFile('''
/// [new A] 1
/// [A.new] 2
extension type A.named(int it) {
  A() : named(0);
  A.other() : this(); // 3
}

void f() {
  A(); // 4
  A.new; // 5
}
''');
    await findElementReferences(search: 'A() :', false);
    expect(searchElement!.kind, ElementKind.CONSTRUCTOR);
    expect(results, hasLength(5));
    assertHasResult(SearchResultKind.REFERENCE, '] 1', 0);
    assertHasResult(SearchResultKind.REFERENCE, '.new] 2', 4);
    assertHasResult(SearchResultKind.INVOCATION, '(); // 3', 0);
    assertHasResult(SearchResultKind.INVOCATION, '(); // 4', 0);
    assertHasResult(SearchResultKind.REFERENCE, '.new; // 5', 4);
  }

  Future<void> test_extensionType_field_explicit_static() async {
    addTestFile('''
extension E(int it) {
  static dynamic foo; // declaration

  void m() {
    foo; // in m()
    foo(); // in m()
    foo = 1;
    foo += 2;
  }
}

void f() {
  E.foo; // in f()
  E.foo(); // in f()
  E.foo = 10;
  E.foo += 20;
}
''');
    await findElementReferences(search: 'foo; // declaration', false);
    expect(searchElement!.kind, ElementKind.FIELD);
    expect(results, hasLength(8));
    // m()
    assertHasResult(SearchResultKind.READ, 'foo; // in m()');
    assertHasResult(SearchResultKind.READ, 'foo(); // in m()');
    assertHasResult(SearchResultKind.WRITE, 'foo = 1;');
    assertHasResult(SearchResultKind.WRITE, 'foo += 2;');
    // f()
    assertHasResult(SearchResultKind.READ, 'foo; // in f()');
    assertHasResult(SearchResultKind.READ, 'foo(); // in f()');
    assertHasResult(SearchResultKind.WRITE, 'foo = 10;');
    assertHasResult(SearchResultKind.WRITE, 'foo += 20;');
  }

  Future<void> test_extensionType_field_implicit() async {
    addTestFile('''
extension type A(int it) {
  int get foo => 0;
  set foo(int x) {}
  void m() {
    foo; // in m()
    foo = 1;
  }
}
void f(A a) {
  a.foo; // in f()
  a.foo = 10;
}
''');
    {
      await findElementReferences(search: 'foo =>', false);
      expect(searchElement!.kind, ElementKind.FIELD);
      expect(results, hasLength(4));
      assertHasResult(SearchResultKind.READ, 'foo; // in m()');
      assertHasResult(SearchResultKind.WRITE, 'foo = 1;');
      assertHasResult(SearchResultKind.READ, 'foo; // in f()');
      assertHasResult(SearchResultKind.WRITE, 'foo = 10;');
    }
    {
      await findElementReferences(search: 'foo(int x) {}', false);
      expect(results, hasLength(4));
      assertHasResult(SearchResultKind.READ, 'foo; // in m()');
      assertHasResult(SearchResultKind.WRITE, 'foo = 1;');
      assertHasResult(SearchResultKind.READ, 'foo; // in f()');
      assertHasResult(SearchResultKind.WRITE, 'foo = 10;');
    }
  }

  Future<void> test_extensionType_method() async {
    addTestFile('''
extension type E(int it) {
  void foo() {}
}

void f(E e) {
  e.foo(); // 1
  e.foo; // 2
}
''');
    await findElementReferences(search: 'foo() {}', false);
    expect(searchElement!.kind, ElementKind.METHOD);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.INVOCATION, 'foo(); // 1');
    assertHasResult(SearchResultKind.REFERENCE, 'foo; // 2');
  }

  Future<void> test_function() async {
    addTestFile('''
fff(p) {}
void f() {
  fff(1);
  print(fff);
}
''');
    await findElementReferences(search: 'fff(p) {}', false);
    expect(searchElement!.kind, ElementKind.FUNCTION);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.INVOCATION, 'fff(1)');
    assertHasResult(SearchResultKind.REFERENCE, 'fff);');
  }

  Future<void> test_hierarchy_field_explicit() async {
    addTestFile('''
  class A {
    int fff; // in A
  }
  class B extends A {
    int fff; // in B
  }
  class C extends B {
    int fff; // in C
  }
  void f(A a, B b, C c) {
    a.fff = 10;
    b.fff = 20;
    c.fff = 30;
  }
  ''');
    await findElementReferences(search: 'fff; // in B', false);
    expect(searchElement!.kind, ElementKind.FIELD);
    assertHasResult(SearchResultKind.WRITE, 'fff = 10;');
    assertHasResult(SearchResultKind.WRITE, 'fff = 20;');
    assertHasResult(SearchResultKind.WRITE, 'fff = 30;');
  }

  Future<void> test_hierarchy_method() async {
    addTestFile('''
class A {
  mmm(_) {} // in A
}
class B extends A {
  mmm(_) {} // in B
}
class C extends B {
  mmm(_) {} // in C
}
void f(A a, B b, C c) {
  a.mmm(10);
  b.mmm(20);
  c.mmm(30);
}
''');
    await findElementReferences(search: 'mmm(_) {} // in B', false);
    expect(searchElement!.kind, ElementKind.METHOD);
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(10)');
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(20)');
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(30)');
  }

  Future<void> test_hierarchy_method_static() async {
    addTestFile('''
class A {
  static void mmm(_) {} // in A
}
class B extends A {
  static void mmm(_) {} // in B
}
class C extends B {
  static void mmm(_) {} // in C
}
void f() {
  A.mmm(10);
  B.mmm(20);
  C.mmm(30);
}
''');
    await findElementReferences(search: 'mmm(_) {} // in B', false);
    expect(searchElement!.kind, ElementKind.METHOD);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.INVOCATION, 'mmm(20)');
  }

  Future<void> test_hierarchy_namedParameter() async {
    addTestFile('''
class A {
  m({p}) {} // in A
}
class B extends A {
  m({p}) {} // in B
}
class C extends B {
  m({p}) {} // in C
}
void f(A a, B b, C c) {
  a.m(p: 1);
  b.m(p: 2);
  c.m(p: 3);
}
''');
    await findElementReferences(search: 'p}) {} // in B', false);
    expect(searchElement!.kind, ElementKind.PARAMETER);
    assertHasResult(SearchResultKind.REFERENCE, 'p: 1');
    assertHasResult(SearchResultKind.REFERENCE, 'p: 2');
    assertHasResult(SearchResultKind.REFERENCE, 'p: 3');
  }

  Future<void> test_label() async {
    addTestFile('''
void f() {
myLabel:
  for (int i = 0; i < 10; i++) {
    if (i == 2) {
      continue myLabel; // continue
    }
    break myLabel; // break
  }
}
''');
    await findElementReferences(search: 'myLabel; // break', false);
    expect(searchElement!.kind, ElementKind.LABEL);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.REFERENCE, 'myLabel; // continue');
    assertHasResult(SearchResultKind.REFERENCE, 'myLabel; // break');
  }

  Future<void> test_localVariable() async {
    addTestFile('''
void f() {
  var vvv = 1;
  print(vvv);
  vvv += 3;
  vvv = 2;
  vvv();
}
''');
    await findElementReferences(search: 'vvv = 1', false);
    expect(searchElement!.kind, ElementKind.LOCAL_VARIABLE);
    expect(results, hasLength(4));
    assertHasResult(SearchResultKind.READ, 'vvv);');
    assertHasResult(SearchResultKind.READ_WRITE, 'vvv += 3');
    assertHasResult(SearchResultKind.WRITE, 'vvv = 2');
    assertHasResult(SearchResultKind.READ, 'vvv();');
  }

  Future<void> test_mixin() async {
    addTestFile('''
mixin A {}
class B extends Object with A {} // B
''');
    await findElementReferences(search: 'A {}', false);
    expect(searchElement!.kind, ElementKind.MIXIN);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.REFERENCE, 'A {} // B');
  }

  Future<void> test_noElement() async {
    addTestFile('''
void f() {
  print(noElement);
}
''');
    await findElementReferences(search: 'noElement', false);
    expect(searchId, isNull);
  }

  Future<void> test_oneUnit_zeroLibraries() async {
    addTestFile('''
part of lib;
fff(p) {}
void f() {
  fff(10);
}
''');
    await findElementReferences(search: 'fff(p) {}', false);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.INVOCATION, 'fff(10);');
  }

  Future<void> test_parameter() async {
    addTestFile('''
void f(ppp) {
  print(ppp);
  ppp += 3;
  ppp = 2;
  ppp();
}
''');
    await findElementReferences(search: 'ppp) {', false);
    expect(searchElement!.kind, ElementKind.PARAMETER);
    expect(results, hasLength(4));
    assertHasResult(SearchResultKind.READ, 'ppp);');
    assertHasResult(SearchResultKind.READ_WRITE, 'ppp += 3');
    assertHasResult(SearchResultKind.WRITE, 'ppp = 2');
    assertHasResult(SearchResultKind.READ, 'ppp();');
  }

  @failingTest
  Future<void> test_path_inConstructor_named() async {
    // The path does not contain the first expected element.
    addTestFile('''
library my_lib;
class A {}
class B {
  B.named() {
    A a = null;
  }
}
''');
    await findElementReferences(search: 'A {}', false);
    assertHasResult(SearchResultKind.REFERENCE, 'A a = null;');
    expect(getPathString(result.path), '''
LOCAL_VARIABLE a
CONSTRUCTOR named
CLASS B
COMPILATION_UNIT test.dart
LIBRARY my_lib''');
  }

  @failingTest
  Future<void> test_path_inConstructor_unnamed() async {
    // The path does not contain the first expected element.
    addTestFile('''
library my_lib;
class A {}
class B {
  B() {
    A a = null;
  }
}
''');
    await findElementReferences(search: 'A {}', false);
    assertHasResult(SearchResultKind.REFERENCE, 'A a = null;');
    expect(getPathString(result.path), '''
LOCAL_VARIABLE a
CONSTRUCTOR
CLASS B
COMPILATION_UNIT test.dart
LIBRARY my_lib''');
  }

  Future<void> test_path_inExtension_named() async {
    addTestFile('''
class A {
  void foo() {}
}

extension E on A {
  void bar() {
    foo();
  }
}
''');
    await findElementReferences(search: 'foo() {}', false);
    assertHasResult(SearchResultKind.INVOCATION, 'foo();');
    expect(getPathString(result.path), '''
METHOD bar
EXTENSION E
COMPILATION_UNIT test.dart
LIBRARY''');
  }

  Future<void> test_path_inExtension_unnamed() async {
    addTestFile('''
class A {
  void foo() {}
}

extension on A {
  void bar() {
    foo();
  }
}
''');
    await findElementReferences(search: 'foo() {}', false);
    assertHasResult(SearchResultKind.INVOCATION, 'foo();');
    expect(getPathString(result.path), '''
METHOD bar
EXTENSION
COMPILATION_UNIT test.dart
LIBRARY''');
  }

  @failingTest
  Future<void> test_path_inFunction() async {
    // The path does not contain the first expected element.
    addTestFile('''
library my_lib;
class A {}
void f() {
  A a = null;
}
''');
    await findElementReferences(search: 'A {}', false);
    assertHasResult(SearchResultKind.REFERENCE, 'A a = null;');
    expect(getPathString(result.path), '''
LOCAL_VARIABLE a
FUNCTION f
COMPILATION_UNIT test.dart
LIBRARY my_lib''');
  }

  Future<void> test_pattern_assignment() async {
    await assertReferences(
      kind: ElementKind.PARAMETER,
      resultKinds: {
        0: SearchResultKind.WRITE,
        1: SearchResultKind.READ,
      },
      '''
void f(String ^a, String b) {
  (b, /*[0*/a/*0]*/) = (/*[1*/a/*1]*/, b);
}
''',
    );
  }

  Future<void> test_pattern_assignment_list() async {
    await assertReferences(
      kind: ElementKind.PARAMETER,
      resultKinds: {
        0: SearchResultKind.WRITE,
      },
      '''
void f(List<int> x, num ^a) {
  [/*[0*/a/*0]*/] = x;
}
''',
    );
  }

  Future<void> test_pattern_cast_typeName() async {
    await assertReferences(
      kind: ElementKind.CLASS,
      resultKinds: {
        0: SearchResultKind.REFERENCE,
        1: SearchResultKind.REFERENCE,
      },
      '''
String f((num, /*[0*/My^Class/*0]*/) record) {
  var (i as int, s as /*[1*/MyClass/*1]*/) = record;
}

class MyClass {}
''',
    );
  }

  Future<void> test_pattern_cast_variable() async {
    await assertReferences(
      kind: ElementKind.LOCAL_VARIABLE,
      resultKinds: {
        0: SearchResultKind.READ,
      },
      '''
void f((num, String) record) {
  var (i as int, s^ as String) = record;
  print(/*[0*/s/*0]*/);
}
''',
    );
  }

  Future<void> test_pattern_map() async {
    await assertReferences(
      kind: ElementKind.LOCAL_VARIABLE,
      resultKinds: {
        0: SearchResultKind.READ,
      },
      '''
void f(x) {
  switch (x) {
    case {0: String ^a}:
      print(/*[0*/a/*0]*/);
      break;
  }
}
''',
    );
  }

  Future<void> test_pattern_map_typeArguments() async {
    await assertReferences(
      kind: ElementKind.CLASS,
      resultKinds: {
        0: SearchResultKind.REFERENCE,
        1: SearchResultKind.REFERENCE,
      },
      '''
/*[0*/A/*0]*/ f(x) {
  switch (x) {
    case <int, /*[1*/A/*1]*/>{0: var a}:
      return a;
      break;
  }
}

class ^A {}
''',
    );
  }

  Future<void> test_pattern_nullAssert() async {
    await assertReferences(
      kind: ElementKind.LOCAL_VARIABLE,
      resultKinds: {
        0: SearchResultKind.READ,
      },
      '''
void f((int?, int?) position) {
  var (x!, y^!) = position;
  print(/*[0*/y/*0]*/);
}
''',
    );
  }

  Future<void> test_pattern_nullCheck() async {
    await assertReferences(
      kind: ElementKind.LOCAL_VARIABLE,
      resultKinds: {
        0: SearchResultKind.READ,
      },
      '''
void f(String? maybeString) {
  switch (maybeString) {
    case var ^s?:
      print(/*[0*/s/*0]*/);
  }
}
''',
    );
  }

  Future<void> test_pattern_object_field() async {
    await assertReferences(
      kind: ElementKind.FIELD,
      resultKinds: {
        0: SearchResultKind.READ,
      },
      '''
double calculateArea(Shape shape) =>
  switch (shape) {
    Square(/*[0*/length/*0]*/: var l) => l * l,
  };

class Shape { }
class Square extends Shape {
  double get len^gth => 0;
}
''',
    );
  }

  Future<void> test_pattern_object_fieldName_explicit() async {
    await assertReferences(
      kind: ElementKind.FIELD,
      resultKinds: {
        0: SearchResultKind.READ,
      },
      '''
double calculateArea(Object a) =>
  switch (a) {
    Square(/*[0*/length/*0]*/: var l) => l * l,
  };

class Square {
  double len^gth = 0;
}
''',
    );
  }

  Future<void> test_pattern_object_fieldName_implicit() async {
    await assertReferences(
      kind: ElementKind.FIELD,
      resultKinds: {
        0: SearchResultKind.READ,
      },
      '''
double calculateArea(Object a) =>
  switch (a) {
    Square(/*[0*//*0]*/:var length) => length * length,
  };

class Square {
  double len^gth = 0;
}
''',
    );
  }

  Future<void> test_pattern_object_typeName() async {
    await assertReferences(
      kind: ElementKind.CLASS,
      resultKinds: {
        0: SearchResultKind.REFERENCE,
      },
      '''
double calculateArea(Object a) =>
  switch (a) {
    /*[0*/Square/*0]*/(length: var l) => l * l,
  };

class Sq^uare {
  double get length => 0;
}
''',
    );
  }

  Future<void> test_pattern_object_variable() async {
    await assertReferences(
      kind: ElementKind.LOCAL_VARIABLE,
      resultKinds: {
        0: SearchResultKind.READ,
        1: SearchResultKind.READ,
      },
      '''
double calculateArea(Shape shape) =>
  switch (shape) {
    Square(length: var ^l) => /*[0*/l/*0]*/ * /*[1*/l/*1]*/,
  };

class Shape { }
class Square extends Shape {
  double get length => 0;
}
''',
    );
  }

  Future<void> test_pattern_record_fieldAssignment() async {
    await assertReferences(
      kind: ElementKind.PARAMETER,
      resultKinds: {
        0: SearchResultKind.WRITE,
      },
      '''
void f(({int foo}) x, num ^a) {
  (foo: /*[0*/a/*0]*/,) = x;
}
''',
    );
  }

  Future<void> test_pattern_relational_variable() async {
    await assertReferences(
      kind: ElementKind.LOCAL_VARIABLE,
      resultKinds: {
        0: SearchResultKind.READ,
      },
      '''
String f(int char) {
  const ze^ro = 0;
  return switch (char) {
    == /*[0*/zero/*0]*/ => 'zero'
  };
}
''',
    );
  }

  Future<void> test_potential_disabled() async {
    addTestFile('''
class A {
  test(p) {}
}
void f(A a, p) {
  a.test(1);
  p.test(2);
}
''');
    await findElementReferences(search: 'test(p) {}', false);
    assertHasResult(SearchResultKind.INVOCATION, 'test(1);');
    assertNoResult(SearchResultKind.INVOCATION, 'test(2);');
  }

  Future<void> test_potential_field() async {
    addTestFile('''
class A {
  var test; // declaration
}
void f(A a, p) {
  a.test = 1;
  p.test = 2;
  print(p.test); // p
}
''');
    await findElementReferences(search: 'test; // declaration', true);
    {
      assertHasResult(SearchResultKind.WRITE, 'test = 1;');
      expect(result.isPotential, isFalse);
    }
    {
      assertHasResult(SearchResultKind.WRITE, 'test = 2;');
      expect(result.isPotential, isTrue);
    }
    {
      assertHasResult(SearchResultKind.READ, 'test); // p');
      expect(result.isPotential, isTrue);
    }
  }

  Future<void> test_potential_method() async {
    addTestFile('''
class A {
  test(p) {}
}
void f(A a, p) {
  a.test(1);
  p.test(2);
}
''');
    await findElementReferences(search: 'test(p) {}', true);
    {
      assertHasResult(SearchResultKind.INVOCATION, 'test(1);');
      expect(result.isPotential, isFalse);
    }
    {
      assertHasResult(SearchResultKind.INVOCATION, 'test(2);');
      expect(result.isPotential, isTrue);
    }
  }

  Future<void> test_potential_method_definedInSubclass() async {
    addTestFile('''
class Base {
  methodInBase() {
    test(1);
  }
}
class Derived extends Base {
  test(_) {} // of Derived
  methodInDerived() {
    test(2);
  }
}
globalFunction(Base b) {
  b.test(3);
}
''');
    await findElementReferences(search: 'test(_) {} // of Derived', true);
    assertHasRef(SearchResultKind.INVOCATION, 'test(1);', true);
    assertHasRef(SearchResultKind.INVOCATION, 'test(2);', false);
    assertHasRef(SearchResultKind.INVOCATION, 'test(3);', true);
  }

  Future<void> test_prefix() async {
    addTestFile('''
import 'dart:async' as ppp;
void f() {
  ppp.Future a;
  ppp.Stream b;
}
''');
    await findElementReferences(search: 'ppp;', false);
    final searchElement = this.searchElement!;
    expect(searchElement.kind, ElementKind.PREFIX);
    expect(searchElement.name, 'ppp');
    expect(searchElement.location!.startLine, 1);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.REFERENCE, 'ppp.Future');
    assertHasResult(SearchResultKind.REFERENCE, 'ppp.Stream');
  }

  Future<void> test_topFunction_parameter_optionalNamed_anywhere() async {
    addTestFile('''
void foo(int a, int b, {int? test}) {
  test;
}

void g() {
  foo(0, test: 2, 1);
}
''');
    await findElementReferences(search: 'test})', false);
    expect(searchElement!.kind, ElementKind.PARAMETER);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.READ, 'test;');
    assertHasResult(SearchResultKind.REFERENCE, 'test: 2');
  }

  Future<void> test_topLevelVariable_explicit() async {
    addTestFile('''
var vvv = 1;
void f() {
  print(vvv);
  vvv += 3;
  vvv = 2;
  vvv();
}
''');
    await findElementReferences(search: 'vvv = 1', false);
    expect(searchElement!.kind, ElementKind.TOP_LEVEL_VARIABLE);
    expect(results, hasLength(4));
    assertHasResult(SearchResultKind.READ, 'vvv);');
    assertHasResult(SearchResultKind.WRITE, 'vvv += 3');
    assertHasResult(SearchResultKind.WRITE, 'vvv = 2');
    assertHasResult(SearchResultKind.READ, 'vvv();');
  }

  Future<void> test_topLevelVariable_implicit() async {
    addTestFile('''
get vvv => null;
set vvv(x) {}
void f() {
  print(vvv);
  vvv = 1;
}
''');
    {
      await findElementReferences(search: 'vvv =>', false);
      expect(searchElement!.kind, ElementKind.TOP_LEVEL_VARIABLE);
      expect(results, hasLength(2));
      assertHasResult(SearchResultKind.READ, 'vvv);');
      assertHasResult(SearchResultKind.WRITE, 'vvv = 1;');
    }
    {
      await findElementReferences(search: 'vvv(x) {}', false);
      expect(results, hasLength(2));
      assertHasResult(SearchResultKind.READ, 'vvv);');
      assertHasResult(SearchResultKind.WRITE, 'vvv = 1;');
    }
  }

  Future<void> test_typeReference_class() async {
    addTestFile('''
void f() {
  int a = 1;
  int b = 2;
}
''');
    await findElementReferences(search: 'int a', false);
    expect(searchElement!.kind, ElementKind.CLASS);
    assertHasResult(SearchResultKind.REFERENCE, 'int a');
    assertHasResult(SearchResultKind.REFERENCE, 'int b');
  }

  Future<void> test_typeReference_extensionType() async {
    addTestFile('''
extension type A(int it) {}

extension type B(int it) implements A {}

void f(A a) {}
''');
    await findElementReferences(search: 'A(int it)', false);
    expect(searchElement!.kind, ElementKind.EXTENSION_TYPE);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.REFERENCE, 'A {}');
    assertHasResult(SearchResultKind.REFERENCE, 'A a) {}');
  }

  Future<void> test_typeReference_typeAlias_functionType() async {
    addTestFile('''
typedef F = Function();
void f(F f) {
}
''');
    await findElementReferences(search: 'F =', false);
    expect(searchElement!.kind, ElementKind.TYPE_ALIAS);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.REFERENCE, 'F f');
  }

  Future<void> test_typeReference_typeAlias_interfaceType() async {
    addTestFile('''
typedef A<T> = Map<int, T>;

void(A<String> a) {}
''');
    // Can find `A`.
    await findElementReferences(search: 'A<T> =', false);
    expect(searchElement!.kind, ElementKind.TYPE_ALIAS);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.REFERENCE, 'A<String>');

    // Can find in `A`.
    await findElementReferences(search: 'int,', false);
    expect(searchElement!.kind, ElementKind.CLASS);
    assertHasResult(SearchResultKind.REFERENCE, 'int,');
  }

  Future<void> test_typeReference_typeAlias_legacy() async {
    addTestFile('''
typedef F();
void f(F f) {
}
''');
    await findElementReferences(search: 'F()', false);
    expect(searchElement!.kind, ElementKind.TYPE_ALIAS);
    expect(results, hasLength(1));
    assertHasResult(SearchResultKind.REFERENCE, 'F f');
  }

  Future<void> test_typeReference_typeVariable() async {
    addTestFile('''
class A<T> {
  T f;
  T m() => null;
}
''');
    await findElementReferences(search: 'T> {', false);
    expect(searchElement!.kind, ElementKind.TYPE_PARAMETER);
    expect(results, hasLength(2));
    assertHasResult(SearchResultKind.REFERENCE, 'T f;');
    assertHasResult(SearchResultKind.REFERENCE, 'T m()');
  }
}
