// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/local_reference_contributor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalReferenceContributorTest);
  });
}

@reflectiveTest
class LocalReferenceContributorTest extends DartCompletionContributorTest {
  @override
  bool get isNullExpectedReturnTypeConsideredDynamic => false;

  @override
  DartCompletionContributor createContributor() {
    return LocalReferenceContributor();
  }

  Future<void> test_ArgDefaults_function() async {
    addTestSource('''
bool hasLength(int a, bool b) => false;
void main() {h^}''');
    await computeSuggestions();

    assertSuggestFunction('hasLength', 'bool',
        defaultArgListString: 'a, b',
        defaultArgumentListTextRanges: [0, 1, 3, 1]);
  }

  Future<void> test_ArgDefaults_function_none() async {
    addTestSource('''
bool hasLength() => false;
void main() {h^}''');
    await computeSuggestions();

    assertSuggestFunction('hasLength', 'bool',
        defaultArgListString: null, defaultArgumentListTextRanges: null);
  }

  Future<void> test_ArgDefaults_function_with_optional_positional() async {
    writeTestPackageConfig(meta: true);
    addTestSource('''
import 'package:meta/meta.dart';

bool foo(int bar, [bool boo, int baz]) => false;
void main() {h^}''');
    await computeSuggestions();

    assertSuggestFunction('foo', 'bool',
        defaultArgListString: 'bar', defaultArgumentListTextRanges: [0, 3]);
  }

  Future<void> test_ArgDefaults_function_with_required_named() async {
    writeTestPackageConfig(meta: true);
    addTestSource('''
import 'package:meta/meta.dart';

bool foo(int bar, {bool boo, @required int baz}) => false;
void main() {h^}''');
    await computeSuggestions();

    assertSuggestFunction('foo', 'bool',
        defaultArgListString: 'bar, baz: baz',
        defaultArgumentListTextRanges: [0, 3, 10, 3]);
  }

  Future<void> test_ArgDefaults_inherited_method_with_required_named() async {
    writeTestPackageConfig(meta: true);
    resolveSource('/home/test/lib/b.dart', '''
import 'package:meta/meta.dart';

lib libB;
class A {
   bool foo(int bar, {bool boo, @required int baz}) => false;
}''');
    addTestSource('''
import "b.dart";
class B extends A {
  b() => f^
}
''');
    await computeSuggestions();

    assertSuggestMethod('foo', 'A', 'bool',
        defaultArgListString: 'bar, baz: baz');
  }

  Future<void> test_ArgDefaults_method_with_required_named() async {
    writeTestPackageConfig(meta: true);
    addTestSource('''
import 'package:meta/meta.dart';

class A {
  bool foo(int bar, {bool boo, @required int baz}) => false;
  baz() {
    f^
  }
}''');
    await computeSuggestions();

    assertSuggestMethod('foo', 'A', 'bool',
        defaultArgListString: 'bar, baz: baz',
        defaultArgumentListTextRanges: [0, 3, 10, 3]);
  }

  Future<void> test_ArgumentList() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/home/test/lib/a.dart', '''
library A;
bool hasLength(int expected) { }
void baz() { }''');
    addTestSource('''
import 'a.dart';;
class B { }
String bar() => true;
void main() {expect(^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestFunction('bar', 'String');
    assertNotSuggested('hasLength');
    assertNotSuggested('identical');
    assertSuggestClass('B');
    assertNotSuggested('Object');
    assertNotSuggested('main');
    assertNotSuggested('baz');
    assertNotSuggested('print');
  }

  Future<void> test_ArgumentList_imported_function() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/home/test/lib/a.dart', '''
library A;
bool hasLength(int expected) { }
expect(arg) { }
void baz() { }''');
    addTestSource('''
import 'a.dart';
class B { }
String bar() => true;
void main() {expect(^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestFunction('bar', 'String');
    assertNotSuggested('hasLength');
    assertNotSuggested('identical');
    assertSuggestClass('B');
    assertNotSuggested('Object');
    assertNotSuggested('main');
    assertNotSuggested('baz');
    assertNotSuggested('print');
  }

  Future<void>
      test_ArgumentList_InstanceCreationExpression_functionalArg() async {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement  Block
    addSource('/home/test/lib/a.dart', '''
library A;
class A { A(f()) { } }
bool hasLength(int expected) { }
void baz() { }''');
    addTestSource('''
import 'dart:async';
import 'a.dart';;
class B { }
String bar() => true;
void main() {new A(^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestFunction('bar', 'String',
        kind: CompletionSuggestionKind.IDENTIFIER);
    assertNotSuggested('hasLength');
    assertNotSuggested('identical');
    assertSuggestClass('B', kind: CompletionSuggestionKind.IDENTIFIER);
    assertNotSuggested('A');
    assertNotSuggested('Object');
    assertNotSuggested('main');
    assertNotSuggested('baz');
    assertNotSuggested('print');
  }

  Future<void> test_ArgumentList_InstanceCreationExpression_typedefArg() async {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement  Block
    addSource('/home/test/lib/a.dart', '''
library A;
typedef Funct();
class A { A(Funct f) { } }
bool hasLength(int expected) { }
void baz() { }''');
    addTestSource('''
import 'dart:async';
import 'a.dart';;
class B { }
String bar() => true;
void main() {new A(^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestFunction('bar', 'String',
        kind: CompletionSuggestionKind.IDENTIFIER);
    assertNotSuggested('hasLength');
    assertNotSuggested('identical');
    assertSuggestClass('B', kind: CompletionSuggestionKind.IDENTIFIER);
    assertNotSuggested('A');
    assertNotSuggested('Object');
    assertNotSuggested('main');
    assertNotSuggested('baz');
    assertNotSuggested('print');
  }

  Future<void> test_ArgumentList_local_function() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/home/test/lib/a.dart', '''
library A;
bool hasLength(int expected) { }
void baz() { }''');
    addTestSource('''
import 'a.dart';
expect(arg) { }
class B { }
String bar() => true;
void main() {expect(^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestFunction('bar', 'String');
    assertNotSuggested('hasLength');
    assertNotSuggested('identical');
    assertSuggestClass('B');
    assertNotSuggested('Object');
    assertNotSuggested('main');
    assertNotSuggested('baz');
    assertNotSuggested('print');
  }

  Future<void> test_ArgumentList_local_method() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/home/test/lib/a.dart', '''
library A;
bool hasLength(int expected) { }
void baz() { }''');
    addTestSource('''
import 'a.dart';
class B {
  expect(arg) { }
  void foo() {expect(^)}}
String bar() => true;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestFunction('bar', 'String');
    assertNotSuggested('hasLength');
    assertNotSuggested('identical');
    assertSuggestClass('B');
    assertNotSuggested('Object');
    assertNotSuggested('main');
    assertNotSuggested('baz');
    assertNotSuggested('print');
  }

  Future<void> test_ArgumentList_MethodInvocation_functionalArg() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/home/test/lib/a.dart', '''
library A;
class A { A(f()) { } }
bool hasLength(int expected) { }
void baz() { }''');
    addTestSource('''
import 'dart:async';
import 'a.dart';;
class B { }
String bar(f()) => true;
void main() {boo(){} bar(^);}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestFunction('bar', 'String',
        kind: CompletionSuggestionKind.IDENTIFIER);
    assertSuggestFunction('boo', 'Null',
        kind: CompletionSuggestionKind.IDENTIFIER);
    assertNotSuggested('hasLength');
    assertNotSuggested('identical');
    assertSuggestClass('B', kind: CompletionSuggestionKind.IDENTIFIER);
    assertNotSuggested('A');
    assertNotSuggested('Object');
    assertNotSuggested('main');
    assertNotSuggested('baz');
    assertNotSuggested('print');
  }

  Future<void> test_ArgumentList_MethodInvocation_functionalArg2() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/home/test/lib/a.dart', '''
library A;
class A { A(f()) { } }
bool hasLength(int expected) { }
void baz() { }''');
    addTestSource('''
import 'dart:async';
import 'a.dart';;
class B { }
String bar({inc()}) => true;
void main() {boo(){} bar(inc: ^);}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestFunction(
      'bar',
      'String',
      kind: CompletionSuggestionKind.IDENTIFIER,
    );
    assertSuggestFunction(
      'boo',
      'Null',
      kind: CompletionSuggestionKind.IDENTIFIER,
    );
    assertNotSuggested('hasLength');
    assertNotSuggested('identical');
    assertSuggestClass('B', kind: CompletionSuggestionKind.IDENTIFIER);
    assertNotSuggested('A');
    assertNotSuggested('Object');
    assertNotSuggested('main');
    assertNotSuggested('baz');
    assertNotSuggested('print');
  }

  Future<void> test_ArgumentList_MethodInvocation_methodArg() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/home/test/lib/a.dart', '''
library A;
class A { A(f()) { } }
bool hasLength(int expected) { }
void baz() { }''');
    addTestSource('''
import 'dart:async';
import 'a.dart';;
class B { String bar(f()) => true; }
void main() {new B().bar(^);}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('hasLength');
    assertNotSuggested('identical');
    assertSuggestClass('B', kind: CompletionSuggestionKind.IDENTIFIER);
    assertNotSuggested('A');
    assertNotSuggested('Object');
    assertNotSuggested('main');
    assertNotSuggested('baz');
    assertNotSuggested('print');
  }

  Future<void> test_ArgumentList_namedFieldParam_tear_off() async {
    addSource('/home/test/lib/a.dart', '''
typedef void VoidCallback();
        
class Button {
  final VoidCallback onPressed;
  Button({this.onPressed});
}
''');
    addTestSource('''
import 'a.dart';;

class PageState {
  void _incrementCounter() { }
  build() =>
    new Button(
      onPressed: ^
    );  
}    
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);

    assertSuggest('_incrementCounter',
        csKind: CompletionSuggestionKind.IDENTIFIER);
  }

  Future<void> test_ArgumentList_namedParam() async {
    // SimpleIdentifier  NamedExpression  ArgumentList  MethodInvocation
    // ExpressionStatement
    addSource('/home/test/lib/a.dart', '''
library A;
bool hasLength(int expected) { }''');
    addTestSource('''
import 'a.dart';
String bar() => true;
void main() {expect(foo: ^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestFunction('bar', 'String');
    assertNotSuggested('hasLength');
    assertNotSuggested('main');
  }

  Future<void> test_ArgumentList_namedParam_filter() async {
    // SimpleIdentifier  NamedExpression  ArgumentList
    // InstanceCreationExpression
    addTestSource('''
        class A {}
        class B extends A {}
        class C implements A {}
        class D {}
        class E {
          A a;
          E({A someA});
        }
        A a = new A();
        B b = new B();
        C c = new C();
        D d = new D();
        E e = new E(someA: ^);
  ''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestTopLevelVar('a', 'A');
    assertSuggestTopLevelVar('b', 'B');
    assertSuggestTopLevelVar('c', 'C');
    assertSuggestTopLevelVar('d', 'D');
    assertSuggestTopLevelVar('e', 'E');
  }

  Future<void> test_ArgumentList_namedParam_tear_off() async {
    addSource('/home/test/lib/a.dart', '''
typedef void VoidCallback();
        
class Button {
  Button({VoidCallback onPressed});
}
''');
    addTestSource('''
import 'a.dart';;

class PageState {
  void _incrementCounter() { }
  build() =>
    new Button(
      onPressed: ^
    );  
}    
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);

    assertSuggest('_incrementCounter',
        csKind: CompletionSuggestionKind.IDENTIFIER);
  }

  Future<void> test_ArgumentList_namedParam_tear_off_1() async {
    addSource('/home/test/lib/a.dart', '''
typedef void VoidCallback();
        
class Button {
  Button({VoidCallback onPressed, int x});
}
''');
    addTestSource('''
import 'a.dart';;

class PageState {
  void _incrementCounter() { }
  build() =>
    new Button(
      onPressed: ^
    );  
}    
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);

    assertSuggest('_incrementCounter',
        csKind: CompletionSuggestionKind.IDENTIFIER);
  }

  Future<void> test_ArgumentList_namedParam_tear_off_2() async {
    addSource('/home/test/lib/a.dart', '''
typedef void VoidCallback();
        
class Button {
  Button({ int x, VoidCallback onPressed);
}
''');
    addTestSource('''
import 'a.dart';;

class PageState {
  void _incrementCounter() { }
  build() =>
    new Button(
      onPressed: ^
    );  
}    
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);

    assertSuggest('_incrementCounter',
        csKind: CompletionSuggestionKind.IDENTIFIER);
  }

  Future<void> test_AsExpression_type() async {
    // SimpleIdentifier  TypeName  AsExpression
    addTestSource('''
        class A {var b; X _c; foo() {var a; (a as ^).foo();}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('b');
    assertNotSuggested('_c');
    assertNotSuggested('Object');
    assertSuggestClass('A');
    assertNotSuggested('==');
  }

  @failingTest
  Future<void> test_AsExpression_type_filter_extends() async {
    // This test fails because we are not filtering out the class `A` when
    // suggesting types. We ought to do so because there's no reason to cast a
    // value to the type it already has.

    // SimpleIdentifier  TypeName  AsExpression
    addTestSource('''
class A {} class B extends A {} class C extends A {} class D {}
f(A a){ (a as ^) }''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('B');
    assertSuggestClass('C');
    assertNotSuggested('A');
    assertNotSuggested('D');
    assertNotSuggested('Object');
  }

  @failingTest
  Future<void> test_AsExpression_type_filter_implements() async {
    // This test fails because we are not filtering out the class `A` when
    // suggesting types. We ought to do so because there's no reason to cast a
    // value to the type it already has.

    // SimpleIdentifier  TypeName  AsExpression
    addTestSource('''
class A {} class B implements A {} class C implements A {} class D {}
f(A a){ (a as ^) }''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('B');
    assertSuggestClass('C');
    assertNotSuggested('A');
    assertNotSuggested('D');
    assertNotSuggested('Object');
  }

  Future<void> test_AsExpression_type_filter_undefined_type() async {
    // SimpleIdentifier  TypeName  AsExpression
    addTestSource('''
class A {}
f(U u){ (u as ^) }''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('A');
  }

  Future<void> test_AssignmentExpression_name() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('class A {} main() {int a; int ^b = 1;}');
    await computeSuggestions();

    assertNoSuggestions();
  }

  Future<void> test_AssignmentExpression_RHS() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('class A {} main() {int a; int b = ^}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLocalVariable('a', 'int');
    assertSuggestFunction('main', null);
    assertSuggestClass('A');
    assertNotSuggested('Object');
  }

  Future<void> test_AssignmentExpression_type() async {
    // SimpleIdentifier  TypeName  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('''
class A {} main() {
  int a;
  ^ b = 1;
}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('A');
    assertNotSuggested('int');
    // TODO (danrubel) When entering 1st of 2 identifiers on assignment LHS
    // the user may be either (1) entering a type for the assignment
    // or (2) starting a new statement.
    // Consider suggesting only types
    // if only spaces separates the 1st and 2nd identifiers.
    //assertNotSuggested('a');
    //assertNotSuggested('main');
    //assertNotSuggested('identical');
  }

  Future<void> test_AssignmentExpression_type_newline() async {
    // SimpleIdentifier  TypeName  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('''
class A {} main() {
  int a;
  ^
  b = 1;
}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('A');
    assertNotSuggested('int');
    // Allow non-types preceding an identifier on LHS of assignment
    // if newline follows first identifier
    // because user is probably starting a new statement
    assertSuggestLocalVariable('a', 'int');
    assertSuggestFunction('main', null);
    assertNotSuggested('identical');
  }

  Future<void> test_AssignmentExpression_type_partial() async {
    // SimpleIdentifier  TypeName  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('''
class A {} main() {
  int a;
  int^ b = 1;
}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 3);
    expect(replacementLength, 3);
    assertSuggestClass('A');
    assertNotSuggested('int');
    // TODO (danrubel) When entering 1st of 2 identifiers on assignment LHS
    // the user may be either (1) entering a type for the assignment
    // or (2) starting a new statement.
    // Consider suggesting only types
    // if only spaces separates the 1st and 2nd identifiers.
    //assertNotSuggested('a');
    //assertNotSuggested('main');
    //assertNotSuggested('identical');
  }

  Future<void> test_AssignmentExpression_type_partial_newline() async {
    // SimpleIdentifier  TypeName  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('''
class A {} main() {
  int a;
  i^
  b = 1;
}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestClass('A');
    assertNotSuggested('int');
    // Allow non-types preceding an identifier on LHS of assignment
    // if newline follows first identifier
    // because user is probably starting a new statement
    assertSuggestLocalVariable('a', 'int');
    assertSuggestFunction('main', null);
    assertNotSuggested('identical');
  }

  Future<void> test_AwaitExpression() async {
    // SimpleIdentifier  AwaitExpression  ExpressionStatement
    addTestSource('''
class A {int x; int y() => 0;}
main() async {A a; await ^}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLocalVariable('a', 'A');
    assertSuggestFunction('main', null);
    assertSuggestClass('A');
    assertNotSuggested('Object');
  }

  Future<void> test_AwaitExpression2() async {
    // SimpleIdentifier  AwaitExpression  ExpressionStatement
    addTestSource('''
        class A {
          int x;
          Future y() async {return 0;}
          foo() async {await ^ await y();}
        }
        ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestMethod('y', 'A', 'Future<dynamic>');
    assertSuggestClass('A');
    assertNotSuggested('Object');
  }

  Future<void> test_AwaitExpression_inherited() async {
    // SimpleIdentifier  AwaitExpression  ExpressionStatement
    resolveSource('/home/test/lib/b.dart', '''
lib libB;
class A {
  Future y() async {return 0;}
}''');
    addTestSource('''
import "b.dart";
class B extends A {
  Future a() async {return 0;}
  foo() async {await ^}
}
''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggest('a', elemKind: ElementKind.METHOD);
    assertSuggest('foo', elemKind: ElementKind.METHOD);
    assertSuggest('B', elemKind: ElementKind.CLASS);
    assertNotSuggested('A');
    assertNotSuggested('Object');
    assertSuggestMethod('y', 'A', 'Future<dynamic>');
  }

  Future<void> test_BinaryExpression_LHS() async {
    // SimpleIdentifier  BinaryExpression  VariableDeclaration
    // VariableDeclarationList  VariableDeclarationStatement
    addTestSource('main() {int a = 1, b = ^ + 2;}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    // We should not have the type boost, but we do.
    // The reason is that coveringNode is VariableDeclaration, and the
    // entity is BinaryExpression, so the expected type is int.
    // It would be more correct to use BinaryExpression as coveringNode.
    assertSuggestLocalVariable('a', 'int');
    assertNotSuggested('Object');
    assertNotSuggested('b');
  }

  Future<void> test_BinaryExpression_RHS() async {
    // SimpleIdentifier  BinaryExpression  VariableDeclaration
    // VariableDeclarationList  VariableDeclarationStatement
    addTestSource('main() {int a = 1, b = 2 + ^;}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLocalVariable('a', 'int');
    assertNotSuggested('Object');
    assertNotSuggested('b');
    assertNotSuggested('==');
  }

  Future<void> test_Block() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addSource('/home/test/lib/ab.dart', '''
export "dart:math" hide max;
class A {int x;}
@deprecated D1() {int x;}
class _B {boo() { partBoo() {}} }''');
    addSource('/home/test/lib/cd.dart', '''
String T1;
var _T2;
class C { }
class D { }''');
    addSource('/home/test/lib/eef.dart', '''
class EE { }
class F { }''');
    addSource('/home/test/lib/g.dart', 'class G { }');
    addSource('/home/test/lib/h.dart', '''
class H { }
int T3;
var _T4;'''); // not imported
    addTestSource('''
import "ab.dart";
import "cd.dart" hide D;
import "eef.dart" show EE;
import "g.dart" as g;
int T5;
var _T6;
String get T7 => 'hello';
set T8(int value) { partT8() {} }
Z D2() {int x;}
class X {
  int get clog => 8;
  set blog(value) { }
  a() {
    var f;
    localF(int arg1) { }
    {var x;}
    ^ var r;
  }
  void b() { }}
class Z { }''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);

    assertSuggestClass('X', elemFile: testFile);
    assertSuggestClass('Z');
    assertSuggestMethod('a', 'X', null);
    assertSuggestMethod('b', 'X', 'void');
    assertSuggestFunction('localF', 'Null');
    assertSuggestLocalVariable('f', null);
    // Don't suggest locals out of scope
    assertNotSuggested('r');
    assertNotSuggested('x');
    assertNotSuggested('partT8');

    assertNotSuggested('A');
    assertNotSuggested('_B');
    assertNotSuggested('C');
    assertNotSuggested('partBoo');
    // hidden element suggested as low relevance
    // but imported results are partially filtered
    //assertNotSuggested('D');
    //assertNotSuggested(
    //    'D1', null, true, COMPLETION_RELEVANCE_LOW);
    assertSuggestFunction('D2', 'Z');
    assertNotSuggested('EE');
    // hidden element suggested as low relevance
    //assertNotSuggested('F');
    // Suggested by LibraryPrefixContributor
    assertNotSuggested('g');
    assertNotSuggested('G');
    //assertNotSuggested('H');
    assertNotSuggested('Object');
    assertNotSuggested('min');
    assertNotSuggested('_T2');
    //assertNotSuggested('T3');
    assertNotSuggested('_T4');
    assertSuggestTopLevelVar('T5', 'int');
    assertSuggestTopLevelVar('_T6', null);
    assertNotSuggested('==');
    assertSuggestGetter('T7', 'String');
    assertSuggestSetter('T8');
    assertSuggestGetter('clog', 'int');
    assertSuggestSetter('blog');
    // TODO (danrubel) suggest HtmlElement as low relevance
    assertNotSuggested('HtmlElement');
    assertNotSuggested('Uri');
    assertNotSuggested('parseIPv6Address');
    assertNotSuggested('parseHex');
  }

  Future<void> test_Block_final() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addSource('/home/test/lib/ab.dart', '''
export "dart:math" hide max;
class A {int x;}
@deprecated D1() {int x;}
class _B {boo() { partBoo() {}} }''');
    addSource('/home/test/lib/cd.dart', '''
String T1;
var _T2;
class C { }
class D { }''');
    addSource('/home/test/lib/eef.dart', '''
class EE { }
class F { }''');
    addSource('/home/test/lib/g.dart', 'class G { }');
    addSource('/home/test/lib/h.dart', '''
class H { }
int T3;
var _T4;'''); // not imported
    addTestSource('''
import "ab.dart";
import "cd.dart" hide D;
import "eef.dart" show EE;
import "g.dart" as g;
int T5;
var _T6;
String get T7 => 'hello';
set T8(int value) { partT8() {} }
Z D2() {int x;}
class X {
  int get clog => 8;
  set blog(value) { }
  a() {
    var f;
    localF(int arg1) { }
    {var x;}
    final ^
  }
  void b() { }}
class Z { }''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);

    assertSuggestClass('X');
    assertSuggestClass('Z');
    assertNotSuggested('a');
    assertNotSuggested('b');
    assertNotSuggested('localF');
    assertNotSuggested('f');
    // Don't suggest locals out of scope
    assertNotSuggested('r');
    assertNotSuggested('x');
    assertNotSuggested('partT8');

    assertNotSuggested('A');
    assertNotSuggested('_B');
    assertNotSuggested('C');
    assertNotSuggested('partBoo');
    // hidden element suggested as low relevance
    // but imported results are partially filtered
    //assertNotSuggested('D');
    //assertNotSuggested(
    //    'D1', null, true, COMPLETION_RELEVANCE_LOW);
    assertNotSuggested('D2');
    assertNotSuggested('EE');
    // hidden element suggested as low relevance
    //assertNotSuggested('F');
    // Suggested by LibraryPrefixContributor
    assertNotSuggested('g');
    assertNotSuggested('G');
    //assertNotSuggested('H');
    assertNotSuggested('Object');
    assertNotSuggested('min');
    //assertNotSuggested(
    //    'max',
    //    'num',
    //    false,
    //    COMPLETION_RELEVANCE_LOW);
    assertNotSuggested('T1');
    assertNotSuggested('_T2');
    //assertNotSuggested('T3');
    assertNotSuggested('_T4');
    assertNotSuggested('T5');
    assertNotSuggested('_T6');
    assertNotSuggested('==');
    assertNotSuggested('T7');
    assertNotSuggested('T8');
    assertNotSuggested('clog');
    assertNotSuggested('blog');
    // TODO (danrubel) suggest HtmlElement as low relevance
    assertNotSuggested('HtmlElement');
    assertNotSuggested('Uri');
    assertNotSuggested('parseIPv6Address');
    assertNotSuggested('parseHex');
  }

  Future<void> test_Block_final2() async {
    addTestSource('main() {final S^ v;}');
    await computeSuggestions();

    assertNotSuggested('String');
  }

  Future<void> test_Block_final3() async {
    addTestSource('main() {final ^ v;}');
    await computeSuggestions();

    assertNotSuggested('String');
  }

  Future<void> test_Block_final_final() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addSource('/home/test/lib/ab.dart', '''
export "dart:math" hide max;
class A {int x;}
@deprecated D1() {int x;}
class _B {boo() { partBoo() {}} }''');
    addSource('/home/test/lib/cd.dart', '''
String T1;
var _T2;
class C { }
class D { }''');
    addSource('/home/test/lib/eef.dart', '''
class EE { }
class F { }''');
    addSource('/home/test/lib/g.dart', 'class G { }');
    addSource('/home/test/lib/h.dart', '''
class H { }
int T3;
var _T4;'''); // not imported
    addTestSource('''
import "ab.dart";
import "cd.dart" hide D;
import "eef.dart" show EE;
import "g.dart" as g;
int T5;
var _T6;
String get T7 => 'hello';
set T8(int value) { partT8() {} }
Z D2() {int x;}
class X {
  int get clog => 8;
  set blog(value) { }
  a() {
    final ^
    final var f;
    localF(int arg1) { }
    {var x;}
  }
  void b() { }}
class Z { }''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);

    assertSuggestClass('X');
    assertSuggestClass('Z');
    assertNotSuggested('a');
    assertNotSuggested('b');
    assertNotSuggested('localF');
    assertNotSuggested('f');
    // Don't suggest locals out of scope
    assertNotSuggested('r');
    assertNotSuggested('x');
    assertNotSuggested('partT8');

    assertNotSuggested('A');
    assertNotSuggested('_B');
    assertNotSuggested('C');
    assertNotSuggested('partBoo');
    // hidden element suggested as low relevance
    // but imported results are partially filtered
    //assertNotSuggested('D');
    //assertNotSuggested(
    //    'D1', null, true, COMPLETION_RELEVANCE_LOW);
    assertNotSuggested('D2');
    assertNotSuggested('EE');
    // hidden element suggested as low relevance
    //assertNotSuggested('F');
    // Suggested by LibraryPrefixContributor
    assertNotSuggested('g');
    assertNotSuggested('G');
    //assertNotSuggested('H');
    assertNotSuggested('Object');
    assertNotSuggested('min');
    //assertNotSuggested(
    //    'max',
    //    'num',
    //    false,
    //    COMPLETION_RELEVANCE_LOW);
    assertNotSuggested('T1');
    assertNotSuggested('_T2');
    //assertNotSuggested('T3');
    assertNotSuggested('_T4');
    assertNotSuggested('T5');
    assertNotSuggested('_T6');
    assertNotSuggested('==');
    assertNotSuggested('T7');
    assertNotSuggested('T8');
    assertNotSuggested('clog');
    assertNotSuggested('blog');
    // TODO (danrubel) suggest HtmlElement as low relevance
    assertNotSuggested('HtmlElement');
    assertNotSuggested('Uri');
    assertNotSuggested('parseIPv6Address');
    assertNotSuggested('parseHex');
  }

  Future<void> test_Block_final_var() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addSource('/home/test/lib/ab.dart', '''
export "dart:math" hide max;
class A {int x;}
@deprecated D1() {int x;}
class _B {boo() { partBoo() {}} }''');
    addSource('/home/test/lib/cd.dart', '''
String T1;
var _T2;
class C { }
class D { }''');
    addSource('/home/test/lib/eef.dart', '''
class EE { }
class F { }''');
    addSource('/home/test/lib/g.dart', 'class G { }');
    addSource('/home/test/lib/h.dart', '''
class H { }
int T3;
var _T4;'''); // not imported
    addTestSource('''
import "ab.dart";
import "cd.dart" hide D;
import "eef.dart" show EE;
import "g.dart" as g;
int T5;
var _T6;
String get T7 => 'hello';
set T8(int value) { partT8() {} }
Z D2() {int x;}
class X {
  int get clog => 8;
  set blog(value) { }
  a() {
    final ^
    var f;
    localF(int arg1) { }
    {var x;}
  }
  void b() { }}
class Z { }''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);

    assertSuggestClass('X');
    assertSuggestClass('Z');
    assertNotSuggested('a');
    assertNotSuggested('b');
    assertNotSuggested('localF');
    assertNotSuggested('f');
    // Don't suggest locals out of scope
    assertNotSuggested('r');
    assertNotSuggested('x');
    assertNotSuggested('partT8');

    assertNotSuggested('A');
    assertNotSuggested('_B');
    assertNotSuggested('C');
    assertNotSuggested('partBoo');
    // hidden element suggested as low relevance
    // but imported results are partially filtered
    //assertNotSuggested('D');
    //assertNotSuggested(
    //    'D1', null, true, COMPLETION_RELEVANCE_LOW);
    assertNotSuggested('D2');
    assertNotSuggested('EE');
    // hidden element suggested as low relevance
    //assertNotSuggested('F');
    // Suggested by LibraryPrefixContributor
    assertNotSuggested('g');
    assertNotSuggested('G');
    //assertNotSuggested('H');
    assertNotSuggested('Object');
    assertNotSuggested('min');
    //assertNotSuggested(
    //    'max',
    //    'num',
    //    false,
    //    COMPLETION_RELEVANCE_LOW);
    assertNotSuggested('T1');
    assertNotSuggested('_T2');
    //assertNotSuggested('T3');
    assertNotSuggested('_T4');
    assertNotSuggested('T5');
    assertNotSuggested('_T6');
    assertNotSuggested('==');
    assertNotSuggested('T7');
    assertNotSuggested('T8');
    assertNotSuggested('clog');
    assertNotSuggested('blog');
    // TODO (danrubel) suggest HtmlElement as low relevance
    assertNotSuggested('HtmlElement');
    assertNotSuggested('Uri');
    assertNotSuggested('parseIPv6Address');
    assertNotSuggested('parseHex');
  }

  Future<void> test_Block_identifier_partial() async {
    addSource('/home/test/lib/ab.dart', '''
export "dart:math" hide max;
class A {int x;}
@deprecated D1() {int x;}
class _B { }''');
    addSource('/home/test/lib/cd.dart', '''
String T1;
var _T2;
class C { }
class D { }''');
    addSource('/home/test/lib/eef.dart', '''
class EE { }
class F { }''');
    addSource('/home/test/lib/g.dart', 'class G { }');
    addSource('/home/test/lib/h.dart', '''
class H { }
class D3 { }
int T3;
var _T4;'''); // not imported
    addTestSource('''
import "ab.dart";
import "cd.dart" hide D;
import "eef.dart" show EE;
import "g.dart" as g;
int T5;
var _T6;
Z D2() {int x;}
class X {a() {var f; {var x;} D^ var r;} void b() { }}
class Z { }''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);

    assertSuggestClass('X');
    assertSuggestClass('Z');
    assertSuggestMethod('a', 'X', null);
    assertSuggestMethod('b', 'X', 'void');
    assertSuggestLocalVariable('f', null);
    // Don't suggest locals out of scope
    assertNotSuggested('r');
    assertNotSuggested('x');

    // imported elements are portially filtered
    //assertNotSuggested('A');
    assertNotSuggested('_B');
    //assertNotSuggested('C');
    // hidden element suggested as low relevance
    assertNotSuggested('D');
    assertNotSuggested('D1');
    assertSuggestFunction('D2', 'Z');
    // unimported elements suggested with low relevance
    assertNotSuggested('D3');
    //assertNotSuggested('EE');
    // hidden element suggested as low relevance
    //assertNotSuggested('F');
    //assertSuggestLibraryPrefix('g');
    assertNotSuggested('G');
    //assertNotSuggested('H');
    //assertNotSuggested('Object');
    //assertNotSuggested('min');
    //assertNotSuggested(
    //    'max',
    //    'num',
    //    false,
    //    COMPLETION_RELEVANCE_LOW);
    //assertSuggestTopLevelVarGetterSetter('T1', 'String');
    assertNotSuggested('_T2');
    //assertNotSuggested('T3');
    assertNotSuggested('_T4');
    //assertSuggestTopLevelVar('T5', 'int', relevance: DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE);
    //assertSuggestTopLevelVar('_T6', null);
    assertNotSuggested('==');
    // TODO (danrubel) suggest HtmlElement as low relevance
    assertNotSuggested('HtmlElement');
  }

  Future<void> test_Block_inherited_imported() async {
    // Block  BlockFunctionBody  MethodDeclaration  ClassDeclaration
    resolveSource('/home/test/lib/b.dart', '''
lib B;
class F { var f1; f2() { } get f3 => 0; set f4(fx) { } var _pf; }
class E extends F { var e1; e2() { } }
class I { int i1; i2() { } }
class M { var m1; int m2() { } }''');
    addTestSource('''
import "b.dart";
class A extends E implements I with M {a() {^}}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggest('e1', elemKind: ElementKind.FIELD);
    assertSuggest('f1', elemKind: ElementKind.FIELD);
    assertSuggest('i1', elemKind: ElementKind.FIELD);
    assertSuggest('m1', elemKind: ElementKind.FIELD);
    assertSuggest('f3', elemKind: ElementKind.GETTER);
    assertSuggest('f4', elemKind: ElementKind.SETTER);
    assertSuggest('e2', elemKind: ElementKind.METHOD);
    assertSuggest('f2', elemKind: ElementKind.METHOD);
    assertSuggest('i2', elemKind: ElementKind.METHOD);
    assertSuggest('m2', elemKind: ElementKind.METHOD);
    assertSuggest('toString', elemKind: ElementKind.METHOD);
  }

  Future<void> test_Block_inherited_imported_from_constructor() async {
    // Block  BlockFunctionBody  ConstructorDeclaration  ClassDeclaration
    resolveSource('/home/test/lib/b.dart', '''
      lib B;
      class F { var f1; f2() { } get f3 => 0; set f4(fx) { } var _pf; }
      class E extends F { var e1; e2() { } }
      class I { int i1; i2() { } }
      class M { var m1; int m2() { } }''');
    addTestSource('''
      import "b.dart";
      class A extends E implements I with M {const A() {^}}''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestField('e1', null);
    assertSuggestField('f1', null);
    assertSuggestField('i1', 'int');
    assertSuggestField('m1', null);
    assertSuggestGetter('f3', null);
    assertSuggestSetter('f4');
    assertSuggestMethod('e2', 'E', null);
    assertSuggestMethod('f2', 'F', null);
    assertSuggestMethod('i2', 'I', null);
    assertSuggestMethod('m2', 'M', 'int');
    assertNotSuggested('==');
  }

  Future<void> test_Block_inherited_imported_from_method() async {
    // Block  BlockFunctionBody  MethodDeclaration  ClassDeclaration
    resolveSource('/home/test/lib/b.dart', '''
      lib B;
      class F { var f1; f2() { } get f3 => 0; set f4(fx) { } var _pf; }
      class E extends F { var e1; e2() { } }
      class I { int i1; i2() { } }
      class M { var m1; int m2() { } }''');
    addTestSource('''
      import "b.dart";
      class A extends E implements I with M {a() {^}}''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestField('e1', null);
    assertSuggestField('f1', null);
    assertSuggestField('i1', 'int');
    assertSuggestField('m1', null);
    assertSuggestGetter('f3', null);
    assertSuggestSetter('f4');
    assertSuggestMethod('e2', 'E', null);
    assertSuggestMethod('f2', 'F', null);
    assertSuggestMethod('i2', 'I', null);
    assertSuggestMethod('m2', 'M', 'int');
    assertNotSuggested('==');
  }

  Future<void> test_Block_inherited_local() async {
    // Block  BlockFunctionBody  MethodDeclaration  ClassDeclaration
    addTestSource('''
class F { var f1; f2() { } get f3 => 0; set f4(fx) { } }
class E extends F { var e1; e2() { } }
class I { int i1; i2() { } }
class M { var m1; int m2() { } }
class A extends E implements I with M {a() {^}}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggest('e1', elemKind: ElementKind.FIELD);
    assertSuggest('f1', elemKind: ElementKind.FIELD);
    assertSuggest('i1', elemKind: ElementKind.FIELD);
    assertSuggest('m1', elemKind: ElementKind.FIELD);
    assertSuggest('f3', elemKind: ElementKind.GETTER);
    assertSuggest('f4', elemKind: ElementKind.SETTER);
    assertSuggest('e2', elemKind: ElementKind.METHOD);
    assertSuggest('f2', elemKind: ElementKind.METHOD);
    assertSuggest('i2', elemKind: ElementKind.METHOD);
    assertSuggest('m2', elemKind: ElementKind.METHOD);
    assertSuggest('toString', elemKind: ElementKind.METHOD);
  }

  Future<void> test_Block_inherited_local_from_constructor() async {
    // Block  BlockFunctionBody  ConstructorDeclaration  ClassDeclaration
    addTestSource('''
class F { var f1; f2() { } get f3 => 0; set f4(fx) { } }
class E extends F { var e1; e2() { } }
class I { int i1; i2() { } }
class M { var m1; int m2() { } }
class A extends E implements I with M {const A() {^}}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestField('e1', null);
    assertSuggestField('f1', null);
    assertSuggestField('i1', 'int');
    assertSuggestField('m1', null);
    assertSuggestGetter('f3', null);
    assertSuggestSetter('f4');
    assertSuggestMethod('e2', 'E', null);
    assertSuggestMethod('f2', 'F', null);
    assertSuggestMethod('i2', 'I', null);
    assertSuggestMethod('m2', 'M', 'int');
  }

  Future<void> test_Block_inherited_local_from_method() async {
    // Block  BlockFunctionBody  MethodDeclaration  ClassDeclaration
    addTestSource('''
class F { var f1; f2() { } get f3 => 0; set f4(fx) { } }
class E extends F { var e1; e2() { } }
class I { int i1; i2() { } }
class M { var m1; int m2() { } }
class A extends E implements I with M {a() {^}}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestField('e1', null);
    assertSuggestField('f1', null);
    assertSuggestField('i1', 'int');
    assertSuggestField('m1', null);
    assertSuggestGetter('f3', null);
    assertSuggestSetter('f4');
    assertSuggestMethod('e2', 'E', null);
    assertSuggestMethod('f2', 'F', null);
    assertSuggestMethod('i2', 'I', null);
    assertSuggestMethod('m2', 'M', 'int');
  }

  Future<void> test_Block_local_function() async {
    addSource('/home/test/lib/ab.dart', '''
export "dart:math" hide max;
class A {int x;}
@deprecated D1() {int x;}
class _B {boo() { partBoo() {}} }''');
    addSource('/home/test/lib/cd.dart', '''
String T1;
var _T2;
class C { }
class D { }''');
    addSource('/home/test/lib/eef.dart', '''
class EE { }
class F { }''');
    addSource('/home/test/lib/g.dart', 'class G { }');
    addSource('/home/test/lib/h.dart', '''
class H { }
int T3;
var _T4;'''); // not imported
    addTestSource('''
import "ab.dart";
import "cd.dart" hide D;
import "eef.dart" show EE;
import "g.dart" as g;
int T5;
var _T6;
String get T7 => 'hello';
set T8(int value) { partT8() {} }
Z D2() {int x;}
class X {
  int get clog => 8;
  set blog(value) { }
  a() {
    var f;
    localF(int arg1) { }
    {var x;}
    p^ var r;
  }
  void b() { }}
class Z { }''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);

    assertNotSuggested('partT8');
    assertNotSuggested('partBoo');
    assertNotSuggested('parseIPv6Address');
    assertNotSuggested('parseHex');
  }

  Future<void> test_Block_setterWithoutParameters() async {
    addTestSource('''
set foo() {}

void main() {
  ^
}
''');
    await computeSuggestions();

    assertSuggestSetter('foo');
  }

  Future<void> test_Block_unimported() async {
    newFile('$testPackageLibPath/a.dart', content: 'class A {}');
    addTestSource('main() { ^ }');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);

    // Not imported, so not suggested
    assertNotSuggested('A');
    assertNotSuggested('Future');
  }

  Future<void> test_CascadeExpression_selector1() async {
    // PropertyAccess  CascadeExpression  ExpressionStatement  Block
    addSource('/home/test/lib/b.dart', '''
class B { }''');
    addTestSource('''
import "b.dart";
class A {var b; X _c;}
class X{}
// looks like a cascade to the parser
// but the user is trying to get completions for a non-cascade
main() {A a; a.^.z}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('b');
    assertNotSuggested('_c');
    assertNotSuggested('Object');
    assertNotSuggested('A');
    assertNotSuggested('B');
    assertNotSuggested('X');
    assertNotSuggested('z');
    assertNotSuggested('==');
  }

  Future<void> test_CascadeExpression_selector2() async {
    // SimpleIdentifier  PropertyAccess  CascadeExpression  ExpressionStatement
    addSource('/home/test/lib/b.dart', '''
class B { }''');
    addTestSource('''
import "b.dart";
class A {var b; X _c;}
class X{}
main() {A a; a..^z}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 1);
    assertNotSuggested('b');
    assertNotSuggested('_c');
    assertNotSuggested('Object');
    assertNotSuggested('A');
    assertNotSuggested('B');
    assertNotSuggested('X');
    assertNotSuggested('z');
    assertNotSuggested('==');
  }

  Future<void> test_CascadeExpression_selector2_withTrailingReturn() async {
    // PropertyAccess  CascadeExpression  ExpressionStatement  Block
    addSource('/home/test/lib/b.dart', '''
class B { }''');
    addTestSource('''
import "b.dart";
class A {var b; X _c;}
class X{}
main() {A a; a..^ return}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('b');
    assertNotSuggested('_c');
    assertNotSuggested('Object');
    assertNotSuggested('A');
    assertNotSuggested('B');
    assertNotSuggested('X');
    assertNotSuggested('z');
    assertNotSuggested('==');
  }

  Future<void> test_CascadeExpression_target() async {
    // SimpleIdentifier  CascadeExpression  ExpressionStatement
    addTestSource('''
class A {var b; X _c;}
class X{}
main() {A a; a^..b}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('b');
    assertNotSuggested('_c');
    assertSuggestLocalVariable('a', 'A');
    assertSuggestClass('A');
    assertSuggestClass('X');
    // top level results are partially filtered
    //assertNotSuggested('Object');
    assertNotSuggested('==');
  }

  Future<void> test_CatchClause_onType() async {
    // TypeName  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} on ^ {}}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('A');
    assertNotSuggested('Object');
    assertNotSuggested('a');
    assertNotSuggested('x');
  }

  Future<void> test_CatchClause_onType_noBrackets() async {
    // TypeName  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} on ^}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('A', elemOffset: 6);
    assertNotSuggested('Object');
    assertNotSuggested('x');
  }

  Future<void> test_CatchClause_typed() async {
    // Block  CatchClause  TryStatement
    addTestSource('''
class A {
  a() {
    try {
      var x;
    } on E catch (e) {
      ^
    }
  }
}
class E {}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestParameter('e', 'E');
    assertSuggestMethod('a', 'A', null);
    assertNotSuggested('Object');
    assertNotSuggested('x');
  }

  Future<void> test_CatchClause_untyped() async {
    // Block  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} catch (e, s) {^}}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestParameter('e', null);
    assertSuggestParameter('s', 'StackTrace');
    assertSuggestMethod('a', 'A', null);
    assertNotSuggested('Object');
    assertNotSuggested('x');
  }

  Future<void> test_ClassDeclaration_body() async {
    // ClassDeclaration  CompilationUnit
    addSource('/home/test/lib/b.dart', '''
class B { }''');
    addTestSource('''
import "b.dart" as x;
@deprecated class A {^}
class _B {}
A T;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    var suggestionA = assertSuggestClass('A', isDeprecated: true);
    if (suggestionA != null) {
      expect(suggestionA.element.isDeprecated, isTrue);
      expect(suggestionA.element.isPrivate, isFalse);
    }
    var suggestionB = assertSuggestClass('_B');
    if (suggestionB != null) {
      expect(suggestionB.element.isDeprecated, isFalse);
      expect(suggestionB.element.isPrivate, isTrue);
    }
    assertNotSuggested('Object');
    assertNotSuggested('T');
    // Suggested by LibraryPrefixContributor
    assertNotSuggested('x');
  }

  Future<void> test_ClassDeclaration_body_final() async {
    // ClassDeclaration  CompilationUnit
    addSource('/home/test/lib/b.dart', '''
class B { }''');
    addTestSource('''
import "b.dart" as x;
class A {final ^}
class _B {}
A T;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('A');
    assertSuggestClass('_B');
    assertNotSuggested('Object');
    assertNotSuggested('T');
    // Suggested by LibraryPrefixContributor
    assertNotSuggested('x');
  }

  Future<void> test_ClassDeclaration_body_final_field() async {
    // ClassDeclaration  CompilationUnit
    addSource('/home/test/lib/b.dart', '''
class B { }''');
    addTestSource('''
import "b.dart" as x;
class A {final ^ A(){}}
class _B {}
A T;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('A');
    assertSuggestClass('_B');
    assertNotSuggested('String');
    assertNotSuggested('T');
    // Suggested by LibraryPrefixContributor
    assertNotSuggested('x');
  }

  Future<void> test_ClassDeclaration_body_final_field2() async {
    // ClassDeclaration  CompilationUnit
    addSource('/home/test/lib/b.dart', '''
class B { }''');
    addTestSource('''
import "b.dart" as Soo;
class A {final S^ A();}
class _B {}
A Sew;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestClass('A');
    assertSuggestClass('_B');
    assertNotSuggested('String');
    assertNotSuggested('Sew');
    // Suggested by LibraryPrefixContributor
    assertNotSuggested('Soo');
  }

  Future<void> test_ClassDeclaration_body_final_final() async {
    // ClassDeclaration  CompilationUnit
    addSource('/home/test/lib/b.dart', '''
class B { }''');
    addTestSource('''
import "b.dart" as x;
class A {final ^ final foo;}
class _B {}
A T;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('A');
    assertSuggestClass('_B');
    assertNotSuggested('Object');
    assertNotSuggested('T');
    // Suggested by LibraryPrefixContributor
    assertNotSuggested('x');
  }

  Future<void> test_ClassDeclaration_body_final_var() async {
    // ClassDeclaration  CompilationUnit
    addSource('/home/test/lib/b.dart', '''
class B { }''');
    addTestSource('''
import "b.dart" as x;
class A {final ^ var foo;}
class _B {}
A T;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('A');
    assertSuggestClass('_B');
    assertNotSuggested('Object');
    assertNotSuggested('T');
    // Suggested by LibraryPrefixContributor
    assertNotSuggested('x');
  }

  Future<void> test_classReference_in_comment() async {
    addTestSource(r'''
class Abc { }
class Abcd { }

// A^
class Foo {  }
''');
    await computeSuggestions();
    assertNotSuggested('Abc');
    assertNotSuggested('Abcd');
  }

  /// see: https://github.com/dart-lang/sdk/issues/36037
  @failingTest
  Future<void> test_classReference_in_comment_eof() async {
    addTestSource(r'''
class Abc { }
class Abcd { }

// A^
''');
    await computeSuggestions();
    assertNotSuggested('Abc');
    assertNotSuggested('Abcd');
  }

  Future<void> test_Combinator_hide() async {
    // SimpleIdentifier  HideCombinator  ImportDirective
    addSource('/home/test/lib/ab.dart', '''
library libAB;
part 'partAB.dart';
class A { }
class B { }''');
    addSource('/partAB.dart', '''
part of libAB;
var T1;
PB F1() => new PB();
class PB { }''');
    addSource('/home/test/lib/cd.dart', '''
class C { }
class D { }''');
    addTestSource('''
import "ab.dart" hide ^;
import "cd.dart";
class X {}''');
    await computeSuggestions();

    assertNoSuggestions();
  }

  Future<void> test_Combinator_show() async {
    // SimpleIdentifier  HideCombinator  ImportDirective
    addSource('/home/test/lib/ab.dart', '''
library libAB;
part 'partAB.dart';
class A { }
class B { }''');
    addSource('/partAB.dart', '''
part of libAB;
var T1;
PB F1() => new PB();
typedef PB2 F2(int blat);
class Clz = Object with Object;
class PB { }''');
    addSource('/home/test/lib/cd.dart', '''
class C { }
class D { }''');
    addTestSource('''
import "ab.dart" show ^;
import "cd.dart";
class X {}''');
    await computeSuggestions();

    assertNoSuggestions();
  }

  Future<void> test_ConditionalExpression_elseExpression() async {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addSource('/home/test/lib/a.dart', '''
int T1;
F1() { }
class A {int x;}''');
    addTestSource('''
import "a.dart";
int T2;
F2() { }
class B {int x;}
class C {foo(){var f; {var x;} return a ? T1 : T^}}''');
    await computeSuggestions();

    // top level results are partially filtered based on first char
    assertSuggestTopLevelVar('T2', 'int');
    // TODO (danrubel) getter is being suggested instead of top level var
    //assertNotSuggested('T1');
  }

  Future<void> test_ConditionalExpression_elseExpression_empty() async {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addSource('/home/test/lib/a.dart', '''
int T1;
F1() { }
class A {int x;}''');
    addTestSource('''
import "a.dart";
int T2;
F2() { }
class B {int x;}
class C {foo(){var f; {var x;} return a ? T1 : ^}}''');
    await computeSuggestions();

    assertNotSuggested('x');
    assertSuggestLocalVariable('f', null);
    assertSuggestMethod('foo', 'C', null);
    assertSuggestClass('C');
    assertSuggestFunction('F2', null);
    assertSuggestTopLevelVar('T2', 'int');
    assertNotSuggested('A');
    assertNotSuggested('F1');
    // TODO (danrubel) getter is being suggested instead of top level var
    //assertNotSuggested('T1');
  }

  Future<void> test_ConditionalExpression_partial_thenExpression() async {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addSource('/home/test/lib/a.dart', '''
int T1;
F1() { }
class A {int x;}''');
    addTestSource('''
import "a.dart";
int T2;
F2() { }
class B {int x;}
class C {foo(){var f; {var x;} return a ? T^}}''');
    await computeSuggestions();

    // top level results are partially filtered based on first char
    assertSuggestTopLevelVar('T2', 'int');
    // TODO (danrubel) getter is being suggested instead of top level var
    //assertNotSuggested('T1');
  }

  Future<void> test_ConditionalExpression_partial_thenExpression_empty() async {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addSource('/home/test/lib/a.dart', '''
int T1;
F1() { }
class A {int x;}''');
    addTestSource('''
import "a.dart";
int T2;
F2() { }
class B {int x;}
class C {foo(){var f; {var x;} return a ? ^}}''');
    await computeSuggestions();

    assertNotSuggested('x');
    assertSuggestLocalVariable('f', null);
    assertSuggestMethod('foo', 'C', null);
    assertSuggestClass('C');
    assertSuggestFunction('F2', null);
    assertSuggestTopLevelVar('T2', 'int');
    assertNotSuggested('A');
    assertNotSuggested('F1');
    // TODO (danrubel) getter is being suggested instead of top level var
    //assertNotSuggested('T1');
  }

  Future<void> test_ConditionalExpression_thenExpression() async {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addSource('/home/test/lib/a.dart', '''
int T1;
F1() { }
class A {int x;}''');
    addTestSource('''
import "a.dart";
int T2;
F2() { }
class B {int x;}
class C {foo(){var f; {var x;} return a ? T^ : c}}''');
    await computeSuggestions();

    // top level results are partially filtered based on first char
    assertSuggestTopLevelVar('T2', 'int');
    // TODO (danrubel) getter is being suggested instead of top level var
    //assertNotSuggested('T1');
  }

  Future<void> test_constructor_parameters_mixed_required_and_named() async {
    addTestSource('class A {A(x, {int y}) {^}}');
    await computeSuggestions();
    assertSuggestParameter('x', null);
    assertSuggestParameter('y', 'int');
  }

  Future<void>
      test_constructor_parameters_mixed_required_and_positional() async {
    addTestSource('class A {A(x, [int y]) {^}}');
    await computeSuggestions();
    assertSuggestParameter('x', null);
    assertSuggestParameter('y', 'int');
  }

  Future<void> test_constructor_parameters_named() async {
    addTestSource('class A {A({x, int y}) {^}}');
    await computeSuggestions();
    assertSuggestParameter('x', null);
    assertSuggestParameter('y', 'int');
  }

  Future<void> test_constructor_parameters_positional() async {
    addTestSource('class A {A([x, int y]) {^}}');
    await computeSuggestions();
    assertSuggestParameter('x', null);
    assertSuggestParameter('y', 'int');
  }

  Future<void> test_constructor_parameters_required() async {
    addTestSource('class A {A(x, int y) {^}}');
    await computeSuggestions();
    assertSuggestParameter('x', null);
    assertSuggestParameter('y', 'int');
  }

  Future<void> test_ConstructorFieldInitializer_name() async {
    addTestSource('''
class A {
  final int foo;
  A() : ^
}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestField('foo', 'int');
  }

  Future<void> test_ConstructorFieldInitializer_value() async {
    addTestSource('''
var foo = 0;

class A {
  final int bar;
  A() : bar = ^
}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestTopLevelVar('foo', 'int');
  }

  Future<void> test_ConstructorName_importedClass() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addSource('/home/test/lib/b.dart', '''
lib B;
int T1;
F1() { }
class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
import "b.dart";
var m;
main() {new X.^}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    // Suggested by NamedConstructorContributor
    assertNotSuggested('c');
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('_d');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }

  Future<void> test_ConstructorName_importedFactory() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addSource('/home/test/lib/b.dart', '''
lib B;
int T1;
F1() { }
class X {factory X.c(); factory X._d(); z() {}}''');
    addTestSource('''
import "b.dart";
var m;
main() {new X.^}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    // Suggested by NamedConstructorContributor
    assertNotSuggested('c');
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('_d');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }

  Future<void> test_ConstructorName_importedFactory2() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addTestSource('''
        main() {new String.fr^omCharCodes([]);}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 2);
    expect(replacementLength, 13);
    // Suggested by NamedConstructorContributor
    assertNotSuggested('fromCharCodes');
    assertNotSuggested('isEmpty');
    assertNotSuggested('isNotEmpty');
    assertNotSuggested('length');
    assertNotSuggested('Object');
    assertNotSuggested('String');
  }

  Future<void> test_ConstructorName_localClass() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addTestSource('''
int T1;
F1() { }
class X {X.c(); X._d(); z() {}}
main() {new X.^}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    // Suggested by NamedConstructorContributor
    assertNotSuggested('c');
    assertNotSuggested('_d');
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }

  Future<void> test_ConstructorName_localFactory() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addTestSource('''
int T1;
F1() { }
class X {factory X.c(); factory X._d(); z() {}}
main() {new X.^}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    // Suggested by NamedConstructorContributor
    assertNotSuggested('c');
    assertNotSuggested('_d');
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }

  Future<void> test_DefaultFormalParameter_named_expression() async {
    // DefaultFormalParameter FormalParameterList MethodDeclaration
    addTestSource('''
foo() { }
void bar() { }
class A {a(blat: ^) { }}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestFunction('foo', null);
    assertSuggestMethod('a', 'A', null);
    assertSuggestClass('A');
    assertNotSuggested('String');
    assertNotSuggested('identical');
  }

  Future<void> test_doc_classMember() async {
    var docLines = r'''
  /// My documentation.
  /// Short description.
  ///
  /// Longer description.
''';
    void assertDoc(CompletionSuggestion suggestion) {
      expect(suggestion.docSummary, 'My documentation.\nShort description.');
      expect(suggestion.docComplete,
          'My documentation.\nShort description.\n\nLonger description.');
    }

    addTestSource('''
class C {
$docLines
  int myField;

$docLines
  myMethod() {}

$docLines
  int get myGetter => 0;

  main() {^}
}''');
    await computeSuggestions();
    {
      var suggestion = assertSuggestField('myField', 'int');
      assertDoc(suggestion);
    }
    {
      var suggestion = assertSuggestMethod('myMethod', 'C', null);
      assertDoc(suggestion);
    }
    {
      var suggestion = assertSuggestGetter('myGetter', 'int');
      assertDoc(suggestion);
    }
  }

  Future<void> test_doc_macro() async {
    dartdocInfo.addTemplateNamesAndValues([
      'template_name'
    ], [
      '''
Macro contents on
multiple lines.
'''
    ]);
    addTestSource('''
/// {@macro template_name}
///
/// With an additional line.
int x = 0;

void main() {^}
''');
    await computeSuggestions();
    var suggestion = assertSuggestTopLevelVar('x', 'int');
    expect(suggestion.docSummary, 'Macro contents on\nmultiple lines.');
    expect(suggestion.docComplete,
        'Macro contents on\nmultiple lines.\n\n\nWith an additional line.');
  }

  Future<void> test_doc_topLevel() async {
    var docLines = r'''
/// My documentation.
/// Short description.
///
/// Longer description.
''';
    void assertDoc(CompletionSuggestion suggestion) {
      expect(suggestion.docSummary, 'My documentation.\nShort description.');
      expect(suggestion.docComplete,
          'My documentation.\nShort description.\n\nLonger description.');
    }

    addTestSource('''
$docLines
class MyClass {}

$docLines
class MyMixinApplication = Object with MyClass;

$docLines
enum MyEnum {A, B, C}

$docLines
void myFunction() {}

$docLines
int myVariable;

main() {^}
''');
    await computeSuggestions();
    {
      var suggestion = assertSuggestClass('MyClass');
      assertDoc(suggestion);
    }
    {
      var suggestion = assertSuggestClass('MyMixinApplication');
      assertDoc(suggestion);
    }
    {
      var suggestion = assertSuggestEnum('MyEnum');
      assertDoc(suggestion);
    }
    {
      var suggestion = assertSuggestFunction('myFunction', 'void');
      assertDoc(suggestion);
    }
    {
      var suggestion = assertSuggestTopLevelVar('myVariable', 'int');
      assertDoc(suggestion);
    }
  }

  Future<void> test_enum() async {
    addTestSource('enum E { one, two } main() {^}');
    await computeSuggestions();
    assertSuggestEnum('E');
    assertSuggestEnumConst('E.one');
    assertSuggestEnumConst('E.two');
    assertNotSuggested('one');
    assertNotSuggested('two');
  }

  Future<void> test_enum_deprecated() async {
    addTestSource('@deprecated enum E { one, two } main() {^}');
    await computeSuggestions();
    assertSuggestEnum('E', isDeprecated: true);
    assertSuggestEnumConst('E.one', isDeprecated: true);
    assertSuggestEnumConst('E.two', isDeprecated: true);
    assertNotSuggested('one');
    assertNotSuggested('two');
  }

  Future<void> test_enum_filter() async {
    addTestSource('''
enum E { one, two }
enum F { three, four }

void foo({E e}) {}

main() {
  foo(e: ^);
}
''');
    await computeSuggestions();

    assertSuggestEnum('E');
    assertSuggestEnumConst('E.one');
    assertSuggestEnumConst('E.two');

    assertSuggestEnum('F');
    assertSuggestEnumConst('F.three');
    assertSuggestEnumConst('F.four');
  }

  Future<void> test_enum_filter_assignment() async {
    addTestSource('''
enum E { one, two }
enum F { three, four }

main() {
  E e;
  e = ^;
}
''');
    await computeSuggestions();

    assertSuggestEnum('E');
    assertSuggestEnumConst('E.one');
    assertSuggestEnumConst('E.two');

    assertSuggestEnum('F');
    assertSuggestEnumConst('F.three');
    assertSuggestEnumConst('F.four');
  }

  Future<void> test_enum_filter_binaryEquals() async {
    addTestSource('''
enum E { one, two }
enum F { three, four }

main(E e) {
  e == ^;
}
''');
    await computeSuggestions();

    assertSuggestEnum('E');
    assertSuggestEnumConst('E.one');
    assertSuggestEnumConst('E.two');

    assertSuggestEnum('F');
    assertSuggestEnumConst('F.three');
    assertSuggestEnumConst('F.four');
  }

  Future<void> test_enum_filter_switchCase() async {
    addTestSource('''
enum E { one, two }
enum F { three, four }

main(E e) {
  switch (e) {
    case ^
  }
}
''');
    await computeSuggestions();

    assertSuggestEnum('E');
    assertSuggestEnumConst('E.one');
    assertSuggestEnumConst('E.two');

    assertSuggestEnum('F');
    assertSuggestEnumConst('F.three');
    assertSuggestEnumConst('F.four');
  }

  Future<void> test_enum_filter_variableDeclaration() async {
    addTestSource('''
enum E { one, two }
enum F { three, four }

main() {
  E e = ^;
}
''');
    await computeSuggestions();

    assertSuggestEnum('E');
    assertSuggestEnumConst('E.one');
    assertSuggestEnumConst('E.two');

    assertSuggestEnum('F');
    assertSuggestEnumConst('F.three');
    assertSuggestEnumConst('F.four');
  }

  Future<void> test_enum_shadowed() async {
    addTestSource('''
enum E { one, two }
main() {
  int E = 0;
  ^
}
''');
    await computeSuggestions();

    assertSuggest('E', elemKind: ElementKind.LOCAL_VARIABLE);

    // Enum and all its constants are shadowed by the local variable.
    assertNotSuggested('E', elemKind: ElementKind.ENUM);
    assertNotSuggested('E.one', elemKind: ElementKind.ENUM_CONSTANT);
    assertNotSuggested('E.two', elemKind: ElementKind.ENUM_CONSTANT);
  }

  Future<void> test_expression_localVariable() async {
    addTestSource('''
void f() {
  var v = 0;
  ^
}
''');
    await computeSuggestions();
    assertSuggestLocalVariable('v', 'int');
  }

  Future<void> test_expression_parameter() async {
    addTestSource('''
void f(int a) {
  ^
}
''');
    await computeSuggestions();
    assertSuggestParameter('a', 'int');
  }

  Future<void> test_expression_typeParameter_classDeclaration() async {
    addTestSource('''
class A<T> {
  void m() {
    ^
  }
}
class B<U> {}
''');
    await computeSuggestions();
    assertSuggestTypeParameter('T');
    assertNotSuggested('U');
  }

  Future<void> test_expression_typeParameter_classTypeAlias() async {
    addTestSource('''
class A<U> {}
class B<T> = A<^>;
''');
    await computeSuggestions();
    assertSuggestTypeParameter('T');
    assertNotSuggested('U');
  }

  Future<void> test_expression_typeParameter_functionDeclaration() async {
    addTestSource('''
void f<T>() {
  ^
}
void g<U>() {}
''');
    await computeSuggestions();
    assertSuggestTypeParameter('T');
    assertNotSuggested('U');
  }

  Future<void> test_expression_typeParameter_functionDeclaration_local() async {
    addTestSource('''
void f() {
  void g2<U>() {}
  void g<T>() {
    ^
  }
}
''');
    await computeSuggestions();
    assertSuggestTypeParameter('T');
    assertNotSuggested('U');
  }

  Future<void> test_expression_typeParameter_functionTypeAlias() async {
    addTestSource('''
typedef void F<T>(^);
''');
    await computeSuggestions();
    assertSuggestTypeParameter('T');
  }

  Future<void> test_expression_typeParameter_genericTypeAlias() async {
    addTestSource('''
typedef F<T> = void Function<U>(^);
''');
    await computeSuggestions();
    assertSuggestTypeParameter('T');
    assertSuggestTypeParameter('U');
  }

  Future<void> test_expression_typeParameter_methodDeclaration() async {
    addTestSource('''
class A {
  void m<T>() {
    ^
  }
  void m2<U>() {}
}
''');
    await computeSuggestions();
    assertSuggestTypeParameter('T');
    assertNotSuggested('U');
  }

  Future<void> test_expression_typeParameter_mixinDeclaration() async {
    addTestSource('''
mixin M<T> {
  void m() {
    ^
  }
}
class B<U> {}
''');
    await computeSuggestions();
    assertSuggestTypeParameter('T');
    assertNotSuggested('U');
  }

  Future<void> test_ExpressionStatement_identifier() async {
    // SimpleIdentifier  ExpressionStatement  Block
    addSource('/home/test/lib/a.dart', '''
_B F1() { }
class A {int x;}
class _B { }''');
    addTestSource('''
import "a.dart";
typedef int F2(int blat);
class Clz = Object with Object;
class C {foo(){^} void bar() {}}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('A');
    assertNotSuggested('F1');
    assertSuggestClass('C');
    assertSuggestMethod('foo', 'C', null);
    assertSuggestMethod('bar', 'C', 'void');
    assertSuggestFunctionTypeAlias('F2', 'int');
    assertSuggestClass('Clz');
    assertSuggestClass('C');
    assertNotSuggested('x');
    assertNotSuggested('_B');
  }

  Future<void> test_ExpressionStatement_name() async {
    // ExpressionStatement  Block  BlockFunctionBody  MethodDeclaration
    addSource('/home/test/lib/a.dart', '''
        B T1;
        class B{}''');
    addTestSource('''
        import "a.dart";
        class C {a() {C ^}}''');
    await computeSuggestions();

    assertNoSuggestions();
  }

  Future<void> test_ExtendsClause() async {
    addTestSource('''
class A {}
mixin M {}
class B extends ^
''');
    await computeSuggestions();
    assertSuggestClass('A');
    assertNotSuggested('M');
  }

  Future<void> test_ExtensionDeclaration_extendedType() async {
    addTestSource('''
class A {}
extension E on ^
''');
    await computeSuggestions();
    assertSuggestClass('A');
    assertNotSuggested('E');
  }

  Future<void> test_ExtensionDeclaration_extendedType2() async {
    addTestSource('''
class A {}
extension E on ^ {}
''');
    await computeSuggestions();
    assertSuggestClass('A');
    assertNotSuggested('E');
  }

  Future<void> test_extensionDeclaration_inMethod() async {
    // ExtensionDeclaration  CompilationUnit
    addTestSource('''
extension E on int {}
class C {
  void m() {
    ^
  }
}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggest('E');
  }

  Future<void> test_ExtensionDeclaration_member() async {
    addTestSource('''
class A {}
extension E on A { ^ }
''');
    await computeSuggestions();
    assertSuggestClass('A');
  }

  Future<void> test_extensionDeclaration_notInBody() async {
    // ExtensionDeclaration  CompilationUnit
    addSource('/home/test/lib/b.dart', '''
class B { }''');
    addTestSource('''
import "b.dart" as x;
extension E on int {^}
class _B {}
A T;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    var suggestionB = assertSuggestClass('_B');
    if (suggestionB != null) {
      expect(suggestionB.element.isDeprecated, isFalse);
      expect(suggestionB.element.isPrivate, isTrue);
    }
    assertNotSuggested('Object');
    assertNotSuggested('T');
    assertNotSuggested('E');
    // Suggested by LibraryPrefixContributor
    assertNotSuggested('x');
  }

  Future<void> test_ExtensionDeclaration_shadowed() async {
    // ExtensionDeclaration  CompilationUnit
    addTestSource('''
extension E on int {
  void m() {
    int E = 1;
    ^
  }
}
''');
    await computeSuggestions();

    assertNotSuggested('E', elemKind: ElementKind.EXTENSION);
    assertSuggest('E', elemKind: ElementKind.LOCAL_VARIABLE);
  }

  Future<void> test_ExtensionDeclaration_unnamed() async {
    // ExtensionDeclaration  CompilationUnit
    addTestSource('''
extension on String {
  void something() => this.^
}
''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_FieldDeclaration_name_typed() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // FieldDeclaration
    addSource('/home/test/lib/a.dart', 'class A { }');
    addTestSource('''
        import "a.dart";
        class C {A ^}''');
    await computeSuggestions();

    assertNoSuggestions();
  }

  Future<void> test_FieldDeclaration_name_var() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // FieldDeclaration
    addSource('/home/test/lib/a.dart', 'class A { }');
    addTestSource('''
        import "a.dart";
        class C {var ^}''');
    await computeSuggestions();

    assertNoSuggestions();
  }

  Future<void> test_FieldDeclaration_shadowed() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // FieldDeclaration
    addTestSource('''
class A {
  int foo;
  void bar() {
    int foo; ^
  }
}
''');
    await computeSuggestions();

    assertNotSuggested('foo', elemKind: ElementKind.FIELD);
    assertSuggest('foo', elemKind: ElementKind.LOCAL_VARIABLE);
  }

  Future<void> test_FieldFormalParameter_in_non_constructor() async {
    // SimpleIdentifier  FieldFormalParameter  FormalParameterList
    addTestSource('class A {B(this.^foo) {}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 3);
    assertNoSuggestions();
  }

  Future<void> test_flutter_setState_hasPrefix() async {
    var spaces_4 = ' ' * 4;
    var spaces_6 = ' ' * 6;
    await _check_flutter_setState(
        '    setSt',
        '''
setState(() {
$spaces_6
$spaces_4});''',
        20);
  }

  Future<void> test_flutter_setState_longPrefix() async {
    var spaces_6 = ' ' * 6;
    var spaces_8 = ' ' * 8;
    await _check_flutter_setState(
        '      setSt',
        '''
setState(() {
$spaces_8
$spaces_6});''',
        22);
  }

  Future<void> test_flutter_setState_noPrefix() async {
    var spaces_4 = ' ' * 4;
    var spaces_6 = ' ' * 6;
    await _check_flutter_setState(
        '    ',
        '''
setState(() {
$spaces_6
$spaces_4});''',
        20);
  }

  Future<void> test_forEachPartsWithIdentifier_class() async {
    addTestSource('''
class C {}

main() {
 for(C in [0, 1, 2]) {
   ^
 }
}
''');
    await computeSuggestions();
    // Using `C` in for-each is invalid, but we should not crash.
  }

  Future<void> test_forEachPartsWithIdentifier_localLevelVariable() async {
    addTestSource('''
main() {
  int v;
 for(v in [0, 1, 2]) {
   ^
 }
}
''');
    await computeSuggestions();
    // We don't actually use anything from the `for`, and `v` is suggested
    // just because it is a visible top-level declaration.
    assertSuggestLocalVariable('v', 'int');
  }

  Future<void> test_forEachPartsWithIdentifier_topLevelVariable() async {
    addTestSource('''
int v;
main() {
 for(v in [0, 1, 2]) {
   ^
 }
}
''');
    await computeSuggestions();
    // We don't actually use anything from the `for`, and `v` is suggested
    // just because it is a visible top-level declaration.
    assertSuggestTopLevelVar('v', 'int');
  }

  Future<void> test_ForEachStatement() async {
    // SimpleIdentifier  ForEachStatement
    addTestSource('main() {List<int> values; for (int index in ^)}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLocalVariable('values', 'List<int>');
    assertNotSuggested('index');
  }

  Future<void> test_ForEachStatement2() async {
    // SimpleIdentifier  ForEachStatement
    addTestSource('main() {List<int> values; for (int index in i^)}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestLocalVariable('values', 'List<int>');
    assertNotSuggested('index');
  }

  Future<void> test_ForEachStatement3() async {
    // SimpleIdentifier ParenthesizedExpression  ForEachStatement
    addTestSource('main() {List<int> values; for (int index in (i^))}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestLocalVariable('values', 'List<int>');
    assertNotSuggested('index');
  }

  Future<void> test_ForEachStatement_body_typed() async {
    // Block  ForEachStatement
    addTestSource('main(args) {for (int foo in bar) {^}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestParameter('args', null);
    assertSuggestLocalVariable('foo', 'int');
    assertNotSuggested('Object');
  }

  Future<void> test_ForEachStatement_body_untyped() async {
    // Block  ForEachStatement
    addTestSource('main(args) {for (var foo in bar) {^}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestParameter('args', null);
    assertSuggestLocalVariable('foo', null);
    assertNotSuggested('Object');
  }

  Future<void> test_ForEachStatement_iterable() async {
    // SimpleIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (int foo in ^) {}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestParameter('args', null);
    assertNotSuggested('Object');
  }

  Future<void> test_ForEachStatement_loopVariable() async {
    // SimpleIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (^ in args) {}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('args');
    assertNotSuggested('String');
  }

  Future<void> test_ForEachStatement_loopVariable_type() async {
    // SimpleIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (^ foo in args) {}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('args');
    assertNotSuggested('foo');
    assertNotSuggested('String');
  }

  Future<void> test_ForEachStatement_loopVariable_type2() async {
    // DeclaredIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (S^ foo in args) {}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('args');
    assertNotSuggested('foo');
    assertNotSuggested('String');
  }

  @failingTest
  Future<void> test_ForEachStatement_statement_typed() async {
    // Statement  ForEachStatement
    addTestSource('main(args) {for (int foo in bar) ^}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestParameter('args', null);
    assertSuggestLocalVariable('foo', 'int');
    assertNotSuggested('Object');
  }

  @failingTest
  Future<void> test_ForEachStatement_statement_untyped() async {
    // Statement  ForEachStatement
    addTestSource('main(args) {for (var foo in bar) ^}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestParameter('args', null);
    assertSuggestLocalVariable('foo', null);
    assertNotSuggested('Object');
  }

  Future<void> test_forElement_body() async {
    addTestSource('var x = [for (int i; i < 10; ++i) ^];');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLocalVariable('i', 'int');
    assertNotSuggested('Object');
  }

  Future<void> test_forElement_condition() async {
    addTestSource('var x = [for (int index = 0; i^)];');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestLocalVariable('index', 'int');
  }

  Future<void> test_forElement_initializer() async {
    addTestSource('var x = [for (^)];');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertNotSuggested('int');
  }

  Future<void> test_forElement_updaters() async {
    addTestSource('var x = [for (int index = 0; index < 10; i^)];');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestLocalVariable('index', 'int');
  }

  Future<void> test_forElement_updaters_prefix_expression() async {
    addTestSource('''
var x = [for (int index = 0; index < 10; ++i^)];
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestLocalVariable('index', 'int');
  }

  Future<void> test_FormalParameterList() async {
    // FormalParameterList MethodDeclaration
    addTestSource('''
foo() { }
void bar() { }
class A {a(^) { }}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('foo');
    assertNotSuggested('a');
    assertSuggestClass('A');
    assertNotSuggested('String');
    assertNotSuggested('identical');
    assertNotSuggested('bar');
  }

  Future<void> test_ForStatement_body() async {
    // Block  ForStatement
    addTestSource('main(args) {for (int i; i < 10; ++i) {^}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLocalVariable('i', 'int');
    assertNotSuggested('Object');
  }

  Future<void> test_ForStatement_condition() async {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {for (int index = 0; i^)}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestLocalVariable('index', 'int');
  }

  Future<void> test_ForStatement_initializer() async {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {List a; for (^)}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
    assertNotSuggested('Object');
    assertNotSuggested('int');
  }

  Future<void> test_ForStatement_updaters() async {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {for (int index = 0; index < 10; i^)}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestLocalVariable('index', 'int');
  }

  Future<void> test_ForStatement_updaters_prefix_expression() async {
    // SimpleIdentifier  PrefixExpression  ForStatement
    addTestSource('''
void bar() { }
main() {for (int index = 0; index < 10; ++i^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestLocalVariable('index', 'int');
    assertSuggestFunction('main', null);
    assertNotSuggested('bar');
  }

  Future<void> test_function_parameters_mixed_required_and_named() async {
    addTestSource('''
void m(x, {int y}) {}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestFunction('m', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 1);
    expect(suggestion.hasNamedParameters, true);
  }

  Future<void> test_function_parameters_mixed_required_and_positional() async {
    addTestSource('''
void m(x, [int y]) {}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestFunction('m', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 1);
    expect(suggestion.hasNamedParameters, false);
  }

  Future<void> test_function_parameters_named() async {
    addTestSource('''
void m({x, int y}) {}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestFunction('m', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 0);
    expect(suggestion.hasNamedParameters, true);
  }

  Future<void> test_function_parameters_none() async {
    addTestSource('''
void m() {}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestFunction('m', 'void');
    expect(suggestion.parameterNames, isEmpty);
    expect(suggestion.parameterTypes, isEmpty);
    expect(suggestion.requiredParameterCount, 0);
    expect(suggestion.hasNamedParameters, false);
  }

  Future<void> test_function_parameters_positional() async {
    addTestSource('''
void m([x, int y]) {}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestFunction('m', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 0);
    expect(suggestion.hasNamedParameters, false);
  }

  Future<void> test_function_parameters_required() async {
    addTestSource('''
void m(x, int y) {}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestFunction('m', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 2);
    expect(suggestion.hasNamedParameters, false);
  }

  Future<void> test_functionDeclaration_parameter() async {
    addTestSource('''
void f<T>(^) {}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestTypeParameter('T');
  }

  Future<void> test_FunctionDeclaration_returnType_afterComment() async {
    // ClassDeclaration  CompilationUnit
    addSource('/home/test/lib/a.dart', '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "a.dart";
int T2;
F2() { }
typedef D2();
class C2 { }
/* */ ^ zoo(z) { } String name;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertNotSuggested('T1');
    assertNotSuggested('F1');
    assertNotSuggested('D1');
    assertNotSuggested('C1');
    assertNotSuggested('T2');
    assertNotSuggested('F2');
    assertSuggestFunctionTypeAlias('D2', 'dynamic');
    assertSuggestClass('C2');
    assertNotSuggested('name');
  }

  Future<void> test_FunctionDeclaration_returnType_afterComment2() async {
    // FunctionDeclaration  ClassDeclaration  CompilationUnit
    addSource('/home/test/lib/a.dart', '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "a.dart";
int T2;
F2() { }
typedef D2();
class C2 { }
/** */ ^ zoo(z) { } String name;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertNotSuggested('T1');
    assertNotSuggested('F1');
    assertNotSuggested('D1');
    assertNotSuggested('C1');
    assertNotSuggested('T2');
    assertNotSuggested('F2');
    assertSuggestFunctionTypeAlias('D2', 'dynamic');
    assertSuggestClass('C2');
    assertNotSuggested('name');
  }

  Future<void> test_FunctionDeclaration_returnType_afterComment3() async {
    // FunctionDeclaration  ClassDeclaration  CompilationUnit
    addSource('/home/test/lib/a.dart', '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "a.dart";
int T2;
F2() { }
typedef D2();
/// some dartdoc
class C2 { }
^ zoo(z) { } String name;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertNotSuggested('T1');
    assertNotSuggested('F1');
    assertNotSuggested('D1');
    assertNotSuggested('C1');
    assertNotSuggested('T2');
    assertNotSuggested('F2');
    assertSuggestFunctionTypeAlias('D2', 'dynamic');
    assertSuggestClass('C2');
    assertNotSuggested('name');
  }

  Future<void> test_FunctionDeclaration_shadowed() async {
    // Block  BlockFunctionBody  FunctionDeclaration
    addTestSource('''
void bar() {
  int bar = 1;
  ^
}
''');
    await computeSuggestions();

    assertNotSuggested('bar', elemKind: ElementKind.FUNCTION);
    assertSuggest('bar', elemKind: ElementKind.LOCAL_VARIABLE);
  }

  Future<void> test_functionDeclaration_typeParameterBounds() async {
    addTestSource('''
void f<T extends C<^>>() {}
class C<E> {}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestTypeParameter('T');
  }

  Future<void> test_FunctionExpression_body_function() async {
    // Block  BlockFunctionBody  FunctionExpression
    addTestSource('''
void bar() { }
String foo(List args) {
  x.then((R b) {^});
}
class R {}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    var f = assertSuggestFunction('foo', 'String', isDeprecated: false);
    if (f != null) {
      expect(f.element.isPrivate, isFalse);
    }
    assertSuggestFunction('bar', 'void');
    assertSuggestParameter('args', 'List<dynamic>');
    assertSuggestParameter('b', 'R');
    assertNotSuggested('Object');
  }

  @failingTest
  Future<void> test_functionExpression_expressionBody() async {
    // This test fails because the OpType at the completion location doesn't
    // allow for functions that return `void`. But because the expected return
    // type is `dynamic` we probably want to allow it.
    addTestSource('''
void f() {
  g(() => ^);
}
void g(dynamic Function() h) {}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestFunction('f', 'void');
    assertSuggestFunction('g', 'void');
  }

  Future<void> test_functionExpression_parameterList() async {
    addTestSource('''
var c = <T>(^) {};
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestTypeParameter('T');
  }

  Future<void> test_functionTypeAlias_genericTypeAlias() async {
    addTestSource(r'''
typedef F = void Function();
main() {
  ^
}
''');
    await computeSuggestions();
    assertSuggestFunctionTypeAlias('F', 'void');
  }

  Future<void> test_functionTypeAlias_genericTypeAlias_incomplete() async {
    addTestSource(r'''
typedef F = int;
main() {
  ^
}
''');
    await computeSuggestions();
    assertSuggestFunctionTypeAlias('F', 'dynamic');
  }

  Future<void> test_functionTypeAlias_old() async {
    addTestSource(r'''
typedef void F();
main() {
  ^
}
''');
    await computeSuggestions();
    assertSuggestFunctionTypeAlias('F', 'void');
  }

  Future<void> test_genericFunctionType_parameterList() async {
    addTestSource('''
void f(int Function<T>(^) g) {}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestTypeParameter('T');
  }

  Future<void> test_IfStatement() async {
    // SimpleIdentifier  IfStatement
    addTestSource('''
class A {
  var b;
  X _c;
  foo() {
    A a; if (true) ^
  }
}
class X {}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestField('b', null);
    assertSuggestField('_c', 'X');
    assertNotSuggested('Object');
    assertSuggestClass('A');
    assertNotSuggested('==');
  }

  Future<void> test_IfStatement_condition() async {
    // SimpleIdentifier  IfStatement  Block  BlockFunctionBody
    addTestSource('''
class A {int x; int y() => 0;}
main(){var a; if (^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLocalVariable('a', null);
    assertSuggestFunction('main', null);
    assertSuggestClass('A');
    assertNotSuggested('Object');
  }

  Future<void> test_IfStatement_empty() async {
    // SimpleIdentifier  IfStatement
    addTestSource('''
class A {
  var b;
  X _c;
  foo() {
    A a;
    if (^) something
  }
}
class X {}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestField('b', null);
    assertSuggestField('_c', 'X');
    assertNotSuggested('Object');
    assertSuggestClass('A');
    assertNotSuggested('==');
  }

  Future<void> test_IfStatement_empty_private() async {
    // SimpleIdentifier  IfStatement
    addTestSource('''
class A {
  var b;
  X _c;
  foo() {
    A a;
    if (_^) something
  }
}
class X {}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestField('b', null);
    assertSuggestField('_c', 'X');
    assertNotSuggested('Object');
    assertSuggestClass('A');
    assertNotSuggested('==');
  }

  Future<void> test_IfStatement_invocation() async {
    // SimpleIdentifier  PrefixIdentifier  IfStatement
    addTestSource('''
main() {var a; if (a.^) something}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('toString');
    assertNotSuggested('Object');
    assertNotSuggested('A');
    assertNotSuggested('==');
  }

  Future<void> test_ignore_symbol_being_completed() async {
    addTestSource('class MyClass { } main(MC^) { }');
    await computeSuggestions();
    assertSuggestClass('MyClass');
    assertNotSuggested('MC');
  }

  Future<void> test_implementsClause() async {
    addTestSource('''
class A {}
mixin M {}
class B implements ^
''');
    await computeSuggestions();
    assertSuggestClass('A');
    assertSuggestMixin('M');
  }

  Future<void> test_ImportDirective_dart() async {
    // SimpleStringLiteral  ImportDirective
    addTestSource('''
import "dart^";
main() {}''');
    await computeSuggestions();

    assertNoSuggestions();
  }

  Future<void> test_inDartDoc_reference3() async {
    addTestSource('''
/// The [^]
main(aaa, bbb) {}''');
    await computeSuggestions();
    assertSuggestFunction('main', null,
        kind: CompletionSuggestionKind.IDENTIFIER);
  }

  Future<void> test_inDartDoc_reference4() async {
    addTestSource('''
/// The [m^]
main(aaa, bbb) {}''');
    await computeSuggestions();
    assertSuggestFunction('main', null,
        kind: CompletionSuggestionKind.IDENTIFIER);
  }

  Future<void> test_IndexExpression() async {
    // ExpressionStatement  Block
    addSource('/home/test/lib/a.dart', '''
int T1;
F1() { }
class A {int x;}''');
    addTestSource('''
import "a.dart";
int T2;
F2() { }
class B {int x;}
class C {foo(){var f; {var x;} f[^]}}''');
    await computeSuggestions();

    assertNotSuggested('x');
    assertSuggestLocalVariable('f', null);
    assertSuggestMethod('foo', 'C', null);
    assertSuggestClass('C');
    assertSuggestFunction('F2', null);
    assertSuggestTopLevelVar('T2', 'int');
    assertNotSuggested('A');
    assertNotSuggested('F1');
    // TODO (danrubel) getter is being suggested instead of top level var
    //assertNotSuggested('T1');
  }

  Future<void> test_IndexExpression2() async {
    // SimpleIdentifier IndexExpression ExpressionStatement  Block
    addSource('/home/test/lib/a.dart', '''
int T1;
F1() { }
class A {int x;}''');
    addTestSource('''
import "a.dart";
int T2;
F2() { }
class B {int x;}
class C {foo(){var f; {var x;} f[T^]}}''');
    await computeSuggestions();

    // top level results are partially filtered based on first char
    assertSuggestTopLevelVar('T2', 'int');
    // TODO (danrubel) getter is being suggested instead of top level var
    //assertNotSuggested('T1');
  }

  Future<void> test_inferredType() async {
    addTestSource('main() { var v = 42; ^ }');
    await computeSuggestions();
    assertSuggestLocalVariable('v', 'int');
  }

  Future<void> test_inherited() async {
    resolveSource('/home/test/lib/b.dart', '''
lib libB;
class A2 {
  int x;
  int y() {return 0;}
  int x2;
  int y2() {return 0;}
}''');
    addTestSource('''
import "b.dart";
class A1 {
  int x;
  int y() {return 0;}
  int x1;
  int y1() {return 0;}
}
class B extends A1 with A2 {
  int a;
  int b() {return 0;}
  foo() {^}
}
''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertSuggest('B', elemKind: ElementKind.CLASS);
    assertSuggestField('a', 'int');
    assertSuggestMethod('b', 'B', 'int');
    assertSuggestMethod('foo', 'B', 'dynamic');
    assertNotSuggested('A2');
    assertSuggestField('x', 'int');
    assertSuggestMethod('y', 'A1', 'int');
    assertSuggestField('x1', 'int');
    assertSuggestMethod('y1', 'A1', 'int');
    assertSuggestField('x2', 'int');
    assertSuggestMethod('y2', 'A2', 'int');
  }

  Future<void> test_InstanceCreationExpression() async {
    addTestSource('''
class A {foo(){var f; {var x;}}}
class B {B(this.x, [String boo]) { } int x;}
class C {C.bar({boo: 'hoo', int z: 0}) { } }
main() {new ^ String x = "hello";}''');
    await computeSuggestions();
    CompletionSuggestion suggestion;

    suggestion = assertSuggestConstructor('A', elemOffset: -1);
    expect(suggestion.element.parameters, '()');
    expect(suggestion.element.returnType, 'A');
    expect(suggestion.declaringType, 'A');
    expect(suggestion.parameterNames, hasLength(0));
    expect(suggestion.requiredParameterCount, 0);
    expect(suggestion.hasNamedParameters, false);

    suggestion = assertSuggestConstructor('B');
    expect(suggestion.element.parameters, '(int x, [String boo])');
    expect(suggestion.element.returnType, 'B');
    expect(suggestion.declaringType, 'B');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'int');
    expect(suggestion.parameterNames[1], 'boo');
    expect(suggestion.parameterTypes[1], 'String');
    expect(suggestion.requiredParameterCount, 1);
    expect(suggestion.hasNamedParameters, false);

    suggestion = assertSuggestConstructor('C.bar');
    expect(
        suggestion.element.parameters, '({dynamic boo = \'hoo\', int z = 0})');
    expect(suggestion.element.returnType, 'C');
    expect(suggestion.declaringType, 'C');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'boo');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'z');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 0);
    expect(suggestion.hasNamedParameters, true);
  }

  Future<void> test_InstanceCreationExpression_abstractClass() async {
    addTestSource('''
abstract class A {
  A();
  A.generative();
  factory A.factory() => A();
}

main() {
  new ^;
}''');
    await computeSuggestions();

    assertNotSuggested('A');
    assertNotSuggested('A.generative');
    assertSuggestConstructor('A.factory');
  }

  Future<void>
      test_InstanceCreationExpression_abstractClass_implicitConstructor() async {
    addTestSource('''
abstract class A {}

main() {
  new ^;
}''');
    await computeSuggestions();

    assertNotSuggested('A');
  }

  Future<void>
      test_InstanceCreationExpression_assignment_expression_filter() async {
    addTestSource('''
class A {} class B extends A {} class C implements A {} class D {}
main() {
  A a;
  a = new ^
}''');
    await computeSuggestions();

    assertSuggestConstructor('A', elemOffset: -1);
    assertSuggestConstructor('B', elemOffset: -1);
    assertSuggestConstructor('C', elemOffset: -1);
    assertSuggestConstructor('D', elemOffset: -1);
  }

  Future<void>
      test_InstanceCreationExpression_assignment_expression_filter2() async {
    addTestSource('''
class A {} class B extends A {} class C implements A {} class D {}
main() {
  A a;
  a = new ^;
}''');
    await computeSuggestions();

    assertSuggestConstructor('A', elemOffset: -1);
    assertSuggestConstructor('B', elemOffset: -1);
    assertSuggestConstructor('C', elemOffset: -1);
    assertSuggestConstructor('D', elemOffset: -1);
  }

  Future<void> test_InstanceCreationExpression_imported() async {
    // SimpleIdentifier  TypeName  ConstructorName  InstanceCreationExpression
    addSource('/home/test/lib/a.dart', '''
int T1;
F1() { }
class A {A(this.x) { } int x;}''');
    addTestSource('''
import "a.dart";
import "dart:async";
int T2;
F2() { }
class B {B(this.x, [String boo]) { } int x;}
class C {foo(){var f; {var x;} new ^}}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertNotSuggested('Future');
    assertNotSuggested('A');
    assertSuggestConstructor('B');
    assertSuggestConstructor('C');
    assertNotSuggested('f');
    assertNotSuggested('x');
    assertNotSuggested('foo');
    assertNotSuggested('F1');
    assertNotSuggested('F2');
    assertNotSuggested('T1');
    assertNotSuggested('T2');
  }

  Future<void> test_InstanceCreationExpression_invocationArgument() async {
    addTestSource('''
class A {} class B extends A {} class C {}
void foo(A a) {}
main() {
  foo(new ^);
}''');
    await computeSuggestions();

    assertSuggestConstructor('A', elemOffset: -1);
    assertSuggestConstructor('B', elemOffset: -1);
    assertSuggestConstructor('C', elemOffset: -1);
  }

  Future<void>
      test_InstanceCreationExpression_invocationArgument_named() async {
    addTestSource('''
class A {} class B extends A {} class C {}
void foo({A a}) {}
main() {
  foo(a: new ^);
}''');
    await computeSuggestions();

    assertSuggestConstructor('A', elemOffset: -1);
    assertSuggestConstructor('B', elemOffset: -1);
    assertSuggestConstructor('C', elemOffset: -1);
  }

  Future<void> test_InstanceCreationExpression_unimported() async {
    // SimpleIdentifier  TypeName  ConstructorName  InstanceCreationExpression
    addSource('/testAB.dart', 'class Foo { }');
    addTestSource('class C {foo(){new F^}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('Future');
    assertNotSuggested('Foo');
  }

  Future<void>
      test_InstanceCreationExpression_variable_declaration_filter() async {
    addTestSource('''
class A {} class B extends A {} class C implements A {} class D {}
main() {
  A a = new ^
}''');
    await computeSuggestions();

    assertSuggestConstructor('A', elemOffset: -1);
    assertSuggestConstructor('B', elemOffset: -1);
    assertSuggestConstructor('C', elemOffset: -1);
    assertSuggestConstructor('D', elemOffset: -1);
  }

  Future<void>
      test_InstanceCreationExpression_variable_declaration_filter2() async {
    addTestSource('''
class A {} class B extends A {} class C implements A {} class D {}
main() {
  A a = new ^;
}''');
    await computeSuggestions();

    assertSuggestConstructor('A', elemOffset: -1);
    assertSuggestConstructor('B', elemOffset: -1);
    assertSuggestConstructor('C', elemOffset: -1);
    assertSuggestConstructor('D', elemOffset: -1);
  }

  Future<void> test_InterpolationExpression_block() async {
    // SimpleIdentifier  InterpolationExpression  StringInterpolation
    addSource('/home/test/lib/a.dart', '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "a.dart";
int T2;
F2() { }
typedef D2();
class C2 { }
main() {String name; print("hello \${^}");}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertNotSuggested('T1');
    assertNotSuggested('F1');
    assertNotSuggested('D1');
    assertNotSuggested('C1');
    assertSuggestTopLevelVar('T2', 'int');
    assertSuggestFunction('F2', null);
    assertSuggestFunctionTypeAlias('D2', 'dynamic');
    assertSuggestClass('C2');
    assertSuggestLocalVariable('name', 'String');
  }

  Future<void> test_InterpolationExpression_block2() async {
    // SimpleIdentifier  InterpolationExpression  StringInterpolation
    addTestSource('main() {String name; print("hello \${n^}");}');
    await computeSuggestions();

    assertSuggestLocalVariable('name', 'String');
    // top level results are partially filtered
    //assertNotSuggested('Object');
  }

  Future<void> test_InterpolationExpression_prefix_selector() async {
    // SimpleIdentifier  PrefixedIdentifier  InterpolationExpression
    addTestSource('main() {String name; print("hello \${name.^}");}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('length');
    assertNotSuggested('name');
    assertNotSuggested('Object');
    assertNotSuggested('==');
  }

  Future<void> test_InterpolationExpression_prefix_selector2() async {
    // SimpleIdentifier  PrefixedIdentifier  InterpolationExpression
    addTestSource('main() {String name; print("hello \$name.^");}');
    await computeSuggestions();

    assertNoSuggestions();
  }

  Future<void> test_InterpolationExpression_prefix_target() async {
    // SimpleIdentifier  PrefixedIdentifier  InterpolationExpression
    addTestSource('main() {String name; print("hello \${nam^e.length}");}');
    await computeSuggestions();

    assertSuggestLocalVariable('name', 'String');
    // top level results are partially filtered
    //assertNotSuggested('Object');
    assertNotSuggested('length');
  }

  Future<void> test_IsExpression() async {
    // SimpleIdentifier  TypeName  IsExpression  IfStatement
    addSource('/home/test/lib/b.dart', '''
lib B;
foo() { }
class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
import "b.dart";
class Y {Y.c(); Y._d(); z() {}}
main() {var x; if (x is ^) { }}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('X');
    assertSuggestClass('Y');
    assertNotSuggested('x');
    assertNotSuggested('main');
    assertNotSuggested('foo');
  }

  Future<void> test_IsExpression_target() async {
    // IfStatement  Block  BlockFunctionBody
    addTestSource('''
foo() { }
void bar() { }
class A {int x; int y() => 0;}
main(){var a; if (^ is A)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLocalVariable('a', null);
    assertSuggestFunction('main', null);
    assertSuggestFunction('foo', null);
    assertNotSuggested('bar');
    assertSuggestClass('A');
    assertNotSuggested('Object');
  }

  Future<void> test_IsExpression_type() async {
    // SimpleIdentifier  TypeName  IsExpression  IfStatement
    addTestSource('''
class A {int x; int y() => 0;}
main(){var a; if (a is ^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
    assertNotSuggested('main');
    assertSuggestClass('A');
    assertNotSuggested('Object');
  }

  @failingTest
  Future<void> test_IsExpression_type_filter_extends() async {
    // This test fails because we are not filtering out the class `A` when
    // suggesting types. We ought to do so because there's no reason to cast a
    // value to the type it already has.

    // SimpleIdentifier  TypeName  IsExpression  IfStatement
    addTestSource('''
class A {} class B extends A {} class C extends A {} class D {}
f(A a){ if (a is ^) {}}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('B');
    assertSuggestClass('C');
    assertNotSuggested('A');
    assertNotSuggested('D');
    assertNotSuggested('Object');
  }

  @failingTest
  Future<void> test_IsExpression_type_filter_implements() async {
    // This test fails because we are not filtering out the class `A` when
    // suggesting types. We ought to do so because there's no reason to cast a
    // value to the type it already has.

    // SimpleIdentifier  TypeName  IsExpression  IfStatement
    addTestSource('''
class A {} class B implements A {} class C implements A {} class D {}
f(A a){ if (a is ^) {}}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('B');
    assertSuggestClass('C');
    assertNotSuggested('A');
    assertNotSuggested('D');
    assertNotSuggested('Object');
  }

  Future<void> test_IsExpression_type_filter_undefined_type() async {
    // SimpleIdentifier  TypeName  AsExpression
    addTestSource('''
class A {}
f(U u){ (u as ^) }''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('A');
  }

  Future<void> test_IsExpression_type_partial() async {
    // SimpleIdentifier  TypeName  IsExpression  IfStatement
    addTestSource('''
class A {int x; int y() => 0;}
main(){var a; if (a is Obj^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 3);
    expect(replacementLength, 3);
    assertNotSuggested('a');
    assertNotSuggested('main');
    assertSuggestClass('A');
    assertNotSuggested('Object');
  }

  Future<void> test_keyword() async {
    addSource('/home/test/lib/b.dart', '''
lib B;
int newT1;
int T1;
nowIsIt() { }
class X {factory X.c(); factory X._d(); z() {}}''');
    addTestSource('''
import "b.dart";
String newer() {}
var m;
main() {new^ X.c();}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 3);
    expect(replacementLength, 3);
    assertNotSuggested('c');
    assertNotSuggested('_d');
    // Imported suggestion are filtered by 1st character
    assertNotSuggested('nowIsIt');
    assertNotSuggested('T1');
    assertNotSuggested('newT1');
    assertNotSuggested('z');
    assertSuggestTopLevelVar('m', 'dynamic');
    assertSuggestFunction('newer', 'String');
  }

  Future<void> test_Literal_list() async {
    // ']'  ListLiteral  ArgumentList  MethodInvocation
    addTestSource('main() {var Some; print([^]);}');
    await computeSuggestions();

    assertSuggestLocalVariable('Some', null);
    assertNotSuggested('String');
  }

  Future<void> test_Literal_list2() async {
    // SimpleIdentifier ListLiteral  ArgumentList  MethodInvocation
    addTestSource('main() {var Some; print([S^]);}');
    await computeSuggestions();

    assertSuggestLocalVariable('Some', null);
    assertNotSuggested('String');
  }

  Future<void> test_Literal_string() async {
    // SimpleStringLiteral  ExpressionStatement  Block
    addTestSource('class A {a() {"hel^lo"}}');
    await computeSuggestions();

    assertNoSuggestions();
  }

  Future<void> test_localConstructor() async {
    writeTestPackageConfig(meta: true);
    addTestSource('''
import 'package:meta/meta.dart';

class A {
  A(int bar, {bool boo, @required int baz});
  baz() {
    new ^
  }
}''');
    await computeSuggestions();
    assertSuggestConstructor('A', defaultArgListString: 'bar, baz: baz');
  }

  Future<void> test_localConstructor2() async {
    writeTestPackageConfig(meta: true);
    addTestSource('''class A {A.named();} main() {^}}''');
    await computeSuggestions();
    assertSuggestConstructor('A.named');
  }

  Future<void> test_localConstructor_abstract() async {
    writeTestPackageConfig(meta: true);
    addTestSource('''
abstract class A {
  A();
  baz() {
    ^
  }
}''');
    await computeSuggestions();
    assertNotSuggested('A', elemKind: ElementKind.CONSTRUCTOR);
  }

  Future<void> test_localConstructor_defaultConstructor() async {
    writeTestPackageConfig(meta: true);
    addTestSource('''class A {} main() {^}}''');
    await computeSuggestions();
    assertSuggestConstructor('A');
  }

  Future<void> test_localConstructor_factory() async {
    writeTestPackageConfig(meta: true);
    addTestSource('''
abstract class A {
  factory A();
  baz() {
    ^
  }
}''');
    await computeSuggestions();
    assertSuggestConstructor('A');
  }

  Future<void> test_localConstructor_optionalNew() async {
    writeTestPackageConfig(meta: true);
    addTestSource('''
import 'package:meta/meta.dart';

class A {
  A(int bar, {bool boo, @required int baz});
  baz() {
    ^
  }
}''');
    await computeSuggestions();
    assertSuggestConstructor('A', defaultArgListString: 'bar, baz: baz');
  }

  Future<void> test_localConstructor_shadowed() async {
    addTestSource('''
class A {
  A();
  A.named();
}
main() {
  int A = 0;
  ^
}
''');
    await computeSuggestions();

    assertSuggest('A');

    // Class and all its constructors are shadowed by the local variable.
    assertNotSuggested('A', elemKind: ElementKind.CLASS);
    assertNotSuggested('A', elemKind: ElementKind.CONSTRUCTOR);
    assertNotSuggested('A.named', elemKind: ElementKind.CONSTRUCTOR);
  }

  Future<void> test_localVariableDeclarationName() async {
    addTestSource('main() {String m^}');
    await computeSuggestions();

    assertNotSuggested('main');
    assertNotSuggested('min');
  }

  Future<void> test_MapLiteralEntry() async {
    // MapLiteralEntry  MapLiteral  VariableDeclaration
    addSource('/home/test/lib/a.dart', '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "a.dart";
int T2;
F2() { }
typedef D2();
class C2 { }
foo = {^''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertNotSuggested('T1');
    assertNotSuggested('F1');
    assertNotSuggested('D1');
    assertNotSuggested('C1');
    assertSuggestTopLevelVar('T2', 'int');
    assertSuggestFunction('F2', null);
    assertSuggestFunctionTypeAlias('D2', 'dynamic');
    assertSuggestClass('C2');
  }

  Future<void> test_MapLiteralEntry1() async {
    // MapLiteralEntry  MapLiteral  VariableDeclaration
    addSource('/home/test/lib/a.dart', '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "a.dart";
int T2;
F2() { }
typedef D2();
class C2 { }
foo = {T^''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('T1');
    assertSuggestTopLevelVar('T2', 'int');
  }

  Future<void> test_MapLiteralEntry2() async {
    // SimpleIdentifier  MapLiteralEntry  MapLiteral  VariableDeclaration
    addSource('/home/test/lib/a.dart', '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "a.dart";
int T2;
F2() { }
typedef D2();
class C2 { }
foo = {7:T^};''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('T1');
    assertSuggestTopLevelVar('T2', 'int');
  }

  Future<void> test_method_inClass() async {
    addTestSource('''
class A {
  void m(x, int y) {}
  main() {^}
}
''');
    await computeSuggestions();
    assertSuggestMethod('m', 'A', 'void');
  }

  Future<void> test_method_inMixin() async {
    addTestSource('''
mixin A {
  void m(x, int y) {}
  main() {^}
}
''');
    await computeSuggestions();
    assertSuggestMethod('m', 'A', 'void');
  }

  Future<void> test_method_inMixin_fromSuperclassConstraint() async {
    addTestSource('''
class C {
  void c(x, int y) {}
}
mixin M on C {
  m() {^}
}
''');
    await computeSuggestions();
    assertSuggestMethod('c', 'C', 'void');
  }

  Future<void> test_method_parameters_mixed_required_and_named() async {
    resolveSource('/home/test/lib/a.dart', '''
class A {
  void m(x, {int y}) {}
}
''');
    addTestSource('''
import 'a.dart';
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 1);
    expect(suggestion.hasNamedParameters, true);
  }

  Future<void> test_method_parameters_mixed_required_and_named_local() async {
    addTestSource('''
class A {
  void m(x, {int y}) {}
}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 1);
    expect(suggestion.hasNamedParameters, true);
  }

  Future<void> test_method_parameters_mixed_required_and_positional() async {
    resolveSource('/home/test/lib/a.dart', '''
class A {
  void m(x, [int y]) {}
}
''');
    addTestSource('''
import 'a.dart';
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 1);
    expect(suggestion.hasNamedParameters, false);
  }

  Future<void>
      test_method_parameters_mixed_required_and_positional_local() async {
    addTestSource('''
class A {
  void m(x, [int y]) {}
}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 1);
    expect(suggestion.hasNamedParameters, false);
  }

  Future<void> test_method_parameters_named() async {
    resolveSource('/home/test/lib/a.dart', '''
class A {
  void m({x, int y}) {}
}
''');
    addTestSource('''
import 'a.dart';
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 0);
    expect(suggestion.hasNamedParameters, true);
  }

  Future<void> test_method_parameters_named_local() async {
    addTestSource('''
class A {
  void m({x, int y}) {}
}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 0);
    expect(suggestion.hasNamedParameters, true);
  }

  Future<void> test_method_parameters_none() async {
    resolveSource('/home/test/lib/a.dart', '''
class A {
  void m() {}
}
''');
    addTestSource('''
import 'a.dart';
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, isEmpty);
    expect(suggestion.parameterTypes, isEmpty);
    expect(suggestion.requiredParameterCount, 0);
    expect(suggestion.hasNamedParameters, false);
  }

  Future<void> test_method_parameters_none_local() async {
    addTestSource('''
class A {
  void m() {}
}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, isEmpty);
    expect(suggestion.parameterTypes, isEmpty);
    expect(suggestion.requiredParameterCount, 0);
    expect(suggestion.hasNamedParameters, false);
  }

  Future<void> test_method_parameters_positional() async {
    resolveSource('/home/test/lib/a.dart', '''
class A {
  void m([x, int y]) {}
}
''');
    addTestSource('''
import 'a.dart';
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 0);
    expect(suggestion.hasNamedParameters, false);
  }

  Future<void> test_method_parameters_positional_local() async {
    addTestSource('''
class A {
  void m([x, int y]) {}
}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 0);
    expect(suggestion.hasNamedParameters, false);
  }

  Future<void> test_method_parameters_required() async {
    resolveSource('/home/test/lib/a.dart', '''
class A {
  void m(x, int y) {}
}
''');
    addTestSource('''
import 'a.dart';
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 2);
    expect(suggestion.hasNamedParameters, false);
  }

  Future<void> test_MethodDeclaration_body_getters() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('''
class A {
  @deprecated
  X get f => 0;
  Z a() {^}
  get _g => 1;
}
class X {}
class Z {}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    var methodA = assertSuggestMethod('a', 'A', 'Z');
    if (methodA != null) {
      expect(methodA.element.isDeprecated, isFalse);
      expect(methodA.element.isPrivate, isFalse);
    }
    var getterF = assertSuggestGetter('f', 'X', isDeprecated: true);
    if (getterF != null) {
      expect(getterF.element.isDeprecated, isTrue);
      expect(getterF.element.isPrivate, isFalse);
    }
    var getterG = assertSuggestGetter('_g', null);
    if (getterG != null) {
      expect(getterG.element.isDeprecated, isFalse);
      expect(getterG.element.isPrivate, isTrue);
    }
  }

  Future<void> test_MethodDeclaration_body_static() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addSource('/home/test/lib/c.dart', '''
class C {
  c1() {}
  var c2;
  static c3() {}
  static var c4;}''');
    addTestSource('''
import "c.dart";
class B extends C {
  b1() {}
  var b2;
  static b3() {}
  static var b4;}
class A extends B {
  a1() {}
  var a2;
  static a3() {}
  static var a4;
  static a() {^}}''');
    await computeSuggestions();

    assertNotSuggested('a1');
    assertNotSuggested('a2');
    assertSuggestMethod('a3', 'A', null);
    assertSuggestField('a4', null);
    assertNotSuggested('b1');
    assertNotSuggested('b2');
    assertNotSuggested('b3');
    assertNotSuggested('b4');
    assertNotSuggested('c1');
    assertNotSuggested('c2');
    assertNotSuggested('c3');
    assertNotSuggested('c4');
  }

  Future<void> test_MethodDeclaration_members() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('''
class A {
  @deprecated X f;
  Z _a() {^}
  var _g;
}
class X {}
class Z {}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    var methodA = assertSuggestMethod('_a', 'A', 'Z');
    if (methodA != null) {
      expect(methodA.element.isDeprecated, isFalse);
      expect(methodA.element.isPrivate, isTrue);
    }
    var getterF = assertSuggestField('f', 'X', isDeprecated: true);
    if (getterF != null) {
      expect(getterF.element.isDeprecated, isTrue);
      expect(getterF.element.isPrivate, isFalse);
      expect(getterF.element.parameters, isNull);
    }
    // If user did not type '_' then relevance of private members is not raised
    var getterG = assertSuggestField('_g', null);
    if (getterG != null) {
      expect(getterG.element.isDeprecated, isFalse);
      expect(getterG.element.isPrivate, isTrue);
      expect(getterF.element.parameters, isNull);
    }
    assertNotSuggested('bool');
  }

  Future<void> test_MethodDeclaration_members_private() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('''
class A {
  @deprecated
  X f;
  Z _a() {_^}
  var _g;
}
class X {}
class Z {}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    var methodA = assertSuggestMethod('_a', 'A', 'Z');
    if (methodA != null) {
      expect(methodA.element.isDeprecated, isFalse);
      expect(methodA.element.isPrivate, isTrue);
    }
    var getterF = assertSuggestField('f', 'X', isDeprecated: true);
    if (getterF != null) {
      expect(getterF.element.isDeprecated, isTrue);
      expect(getterF.element.isPrivate, isFalse);
      expect(getterF.element.parameters, isNull);
    }
    // If user prefixed completion with '_' then suggestion of private members
    // should be the same as public members
    var getterG = assertSuggestField('_g', null);
    if (getterG != null) {
      expect(getterG.element.isDeprecated, isFalse);
      expect(getterG.element.isPrivate, isTrue);
      expect(getterF.element.parameters, isNull);
    }
    assertNotSuggested('bool');
  }

  Future<void> test_methodDeclaration_parameter() async {
    addTestSource('''
class C<E> {}
extension E<S> on C<S> {
  void m<T>(^) {}
}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestTypeParameter('S');
    assertSuggestTypeParameter('T');
    assertNotSuggested('E');
  }

  Future<void> test_MethodDeclaration_parameters_named() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('''
class A {
  @deprecated
  Z a(X x, _, b, {y: boo}) {^}
}
class X {}
class Z {}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    var methodA = assertSuggestMethod('a', 'A', 'Z', isDeprecated: true);
    if (methodA != null) {
      expect(methodA.element.isDeprecated, isTrue);
      expect(methodA.element.isPrivate, isFalse);
    }
    assertSuggestParameter('x', 'X');
    assertSuggestParameter('y', null);
    assertSuggestParameter('b', null);
    assertNotSuggested('int');
    assertNotSuggested('_');
  }

  Future<void> test_MethodDeclaration_parameters_positional() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('''
foo() { }
void bar() { }
class A {
  Z a(X x, [int y=1]) {^}
}
class X {}
class Z {}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestFunction('foo', null);
    assertSuggestFunction('bar', 'void');
    assertSuggestMethod('a', 'A', 'Z');
    assertSuggestParameter('x', 'X');
    assertSuggestParameter('y', 'int');
    assertNotSuggested('String');
  }

  Future<void> test_MethodDeclaration_returnType() async {
    // ClassDeclaration  CompilationUnit
    addSource('/home/test/lib/a.dart', '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "a.dart";
int T2;
F2() { }
typedef D2();
class C2 {^ zoo(z) { } String name; }''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertNotSuggested('T1');
    assertNotSuggested('F1');
    assertNotSuggested('D1');
    assertNotSuggested('C1');
    assertNotSuggested('T2');
    assertNotSuggested('F2');
    assertSuggestFunctionTypeAlias('D2', 'dynamic');
    assertSuggestClass('C2');
    assertNotSuggested('name');
  }

  Future<void> test_MethodDeclaration_returnType_afterComment() async {
    // ClassDeclaration  CompilationUnit
    addSource('/home/test/lib/a.dart', '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "a.dart";
int T2;
F2() { }
typedef D2();
class C2 {/* */ ^ zoo(z) { } String name; }''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertNotSuggested('T1');
    assertNotSuggested('F1');
    assertNotSuggested('D1');
    assertNotSuggested('C1');
    assertNotSuggested('T2');
    assertNotSuggested('F2');
    assertSuggestFunctionTypeAlias('D2', 'dynamic');
    assertSuggestClass('C2');
    assertNotSuggested('name');
  }

  Future<void> test_MethodDeclaration_returnType_afterComment2() async {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    addSource('/home/test/lib/a.dart', '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "a.dart";
int T2;
F2() { }
typedef D2();
class C2 {/** */ ^ zoo(z) { } String name; }''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertNotSuggested('T1');
    assertNotSuggested('F1');
    assertNotSuggested('D1');
    assertNotSuggested('C1');
    assertNotSuggested('T2');
    assertNotSuggested('F2');
    assertSuggestFunctionTypeAlias('D2', 'dynamic');
    assertSuggestClass('C2');
    assertNotSuggested('name');
  }

  Future<void> test_MethodDeclaration_returnType_afterComment3() async {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    addSource('/home/test/lib/a.dart', '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "a.dart";
int T2;
F2() { }
typedef D2();
class C2 {
  /// some dartdoc
  ^ zoo(z) { } String name; }''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertNotSuggested('T1');
    assertNotSuggested('F1');
    assertNotSuggested('D1');
    assertNotSuggested('C1');
    assertNotSuggested('T2');
    assertNotSuggested('F2');
    assertSuggestFunctionTypeAlias('D2', 'dynamic');
    assertSuggestClass('C2');
    assertNotSuggested('name');
  }

  Future<void> test_MethodDeclaration_shadowed() async {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('''
class A {
  void foo() {}
  void bar(List list) {
    for (var foo in list) {
      ^
    }
  }
}
''');
    await computeSuggestions();

    assertNotSuggested('foo', elemKind: ElementKind.METHOD);
    assertSuggest('foo', elemKind: ElementKind.LOCAL_VARIABLE);
  }

  Future<void> test_MethodDeclaration_shadowed2() async {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    addTestSource('''
class A {
  void foo() {}
}
class B extends A{
  void foo() {}
  void bar(List list) {
    for (var foo in list) {
      ^
    }
  }
}
''');
    await computeSuggestions();

    assertNotSuggested('foo', elemKind: ElementKind.METHOD);
    assertSuggest('foo', elemKind: ElementKind.LOCAL_VARIABLE);
  }

  Future<void> test_methodDeclaration_typeParameterBounds() async {
    addTestSource('''
class C<E> {}
extension E<S> on C<S> {
  void m<T extends C<^>>() {}
}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestTypeParameter('S');
    assertSuggestTypeParameter('T');
    assertNotSuggested('E');
  }

  Future<void> test_MethodInvocation_no_semicolon() async {
    // MethodInvocation  ExpressionStatement  Block
    addTestSource('''
main() { }
class I {X get f => new A();get _g => new A();}
class A implements I {
  var b; X _c;
  X get d => new A();get _e => new A();
  // no semicolon between completion point and next statement
  set s1(I x) {} set _s2(I x) {x.^ m(null);}
  m(X x) {} I _n(X x) {}}
class X{}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('f');
    assertNotSuggested('_g');
    assertNotSuggested('b');
    assertNotSuggested('_c');
    assertNotSuggested('d');
    assertNotSuggested('_e');
    assertNotSuggested('s1');
    assertNotSuggested('_s2');
    assertNotSuggested('m');
    assertNotSuggested('_n');
    assertNotSuggested('a');
    assertNotSuggested('A');
    assertNotSuggested('X');
    assertNotSuggested('Object');
    assertNotSuggested('==');
  }

  Future<void> test_missing_params_constructor() async {
    addTestSource('class C1{C1{} main(){C^}}');
    await computeSuggestions();
  }

  Future<void> test_missing_params_function() async {
    addTestSource('int f1{} main(){f^}');
    await computeSuggestions();
  }

  Future<void> test_missing_params_method() async {
    addTestSource('class C1{int f1{} main(){f^}}');
    await computeSuggestions();
  }

  Future<void> test_mixin_ordering() async {
    resolveSource('/home/test/lib/a.dart', '''
class B {}
class M1 {
  void m() {}
}
class M2 {
  void m() {}
}
''');
    addTestSource('''
import 'a.dart';
class C extends B with M1, M2 {
  void f() {
    ^
  }
}
''');
    await computeSuggestions();
    assertSuggestMethod('m', 'M1', 'void');
  }

  Future<void> test_MixinDeclaration_body() async {
    // MixinDeclaration  CompilationUnit
    addSource('/home/test/lib/b.dart', '''
class B { }''');
    addTestSource('''
import "b.dart" as x;
mixin M {^}
class _B {}
A T;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    var suggestionM = assertSuggestMixin('M');
    if (suggestionM != null) {
      expect(suggestionM.element.isDeprecated, isFalse);
      expect(suggestionM.element.isPrivate, isFalse);
    }
    var suggestionB = assertSuggestClass('_B');
    if (suggestionB != null) {
      expect(suggestionB.element.isDeprecated, isFalse);
      expect(suggestionB.element.isPrivate, isTrue);
    }
    assertNotSuggested('Object');
    assertNotSuggested('T');
    // Suggested by LibraryPrefixContributor
    assertNotSuggested('x');
  }

  Future<void> test_MixinDeclaration_method_access() async {
    // MixinDeclaration  CompilationUnit
    addTestSource(r'''
class A { }

mixin X on A {
  int _x() => 0;
  int get x => ^
}
''');
    await computeSuggestions();
    assertSuggestMethod('_x', 'X', 'int');
  }

  Future<void> test_MixinDeclaration_property_access() async {
    // MixinDeclaration  CompilationUnit
    addTestSource(r'''
class A { }

mixin X on A {
  int _x;
  int get x => ^
}
''');
    await computeSuggestions();
    assertSuggestField('_x', 'int');
  }

  Future<void> test_MixinDeclaration_shadowed() async {
    // MixinDeclaration  CompilationUnit
    addTestSource('''
mixin foo on Object {
  void bar() {
    int foo;
    ^
  }
}
''');
    await computeSuggestions();

    assertNotSuggested('foo', elemKind: ElementKind.MIXIN);
    assertSuggest('foo', elemKind: ElementKind.LOCAL_VARIABLE);
  }

  Future<void> test_new_instance() async {
    addTestSource('import "dart:math"; class A {x() {new Random().^}}');
    await computeSuggestions();

    assertNotSuggested('nextBool');
    assertNotSuggested('nextDouble');
    assertNotSuggested('nextInt');
    assertNotSuggested('Random');
    assertNotSuggested('Object');
    assertNotSuggested('A');
  }

  Future<void> test_no_parameters_field() async {
    resolveSource('/home/test/lib/a.dart', '''
class A {
  int x;
}
''');
    addTestSource('''
import 'a.dart';
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestField('x', 'int');
    assertHasNoParameterInfo(suggestion);
  }

  Future<void> test_no_parameters_getter() async {
    resolveSource('/home/test/lib/a.dart', '''
class A {
  int get x => null;
}
''');
    addTestSource('''
import 'a.dart';
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestGetter('x', 'int');
    assertHasNoParameterInfo(suggestion);
  }

  Future<void> test_no_parameters_setter() async {
    resolveSource('/home/test/lib/a.dart', '''
class A {
  set x(int value) {};
}
''');
    addTestSource('''
import 'a.dart';
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestSetter('x');
    assertHasNoParameterInfo(suggestion);
  }

  Future<void> test_outside_class() async {
    resolveSource('/home/test/lib/b.dart', '''
lib libB;
class A2 {
  int x;
  int y() {return 0;}
  int x2;
  int y2() {return 0;}
}''');
    addTestSource('''
import "b.dart";
class A1 {
  int x;
  int y() {return 0;}
  int x1;
  int y1() {return 0;}
}
class B extends A1 with A2 {
  int a;
  int b() {return 0;}
}
foo() {^}
''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertSuggestClass('B');
    assertNotSuggested('a');
    assertNotSuggested('b');
    assertSuggestFunction('foo', 'dynamic');
    assertSuggestClass('A1');
    assertSuggestConstructor('A1');
    assertNotSuggested('x');
    assertNotSuggested('y');
    assertNotSuggested('x1');
    assertNotSuggested('y1');
    assertNotSuggested('x2');
    assertNotSuggested('y2');
  }

  Future<void> test_overrides() async {
    addTestSource('''
class A {m() {}}
class B extends A {m() {^}}
''');
    await computeSuggestions();
    assertSuggestMethod('m', 'B', null);
  }

  @failingTest
  Future<void> test_parameterList_genericFunctionType() async {
    // This test fails because we don't suggest `void` as the type of a
    // parameter, but we should for the case of `void Function()`.
    addTestSource('''
void f(^) {}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggest('void');
  }

  Future<void> test_parameterName_excludeTypes() async {
    addTestSource('m(int ^) {}');
    await computeSuggestions();

    assertNotSuggested('int');
    assertNotSuggested('bool');
  }

  Future<void> test_parameterName_shadowed() async {
    addTestSource('''
foo(int bar) {
  int bar;
  ^
}
''');
    await computeSuggestions();

    assertNotSuggested('bar', elemKind: ElementKind.PARAMETER);
    assertSuggest('bar', elemKind: ElementKind.LOCAL_VARIABLE);
  }

  Future<void> test_PrefixedIdentifier_class_const() async {
    // SimpleIdentifier PrefixedIdentifier ExpressionStatement Block
    addSource('/home/test/lib/b.dart', '''
lib B;
class I {
  static const scI = 'boo';
  X get f => new A();
  get _g => new A();}
class B implements I {
  static const int scB = 12;
  var b; X _c;
  X get d => new A();get _e => new A();
  set s1(I x) {} set _s2(I x) {}
  m(X x) {} I _n(X x) {}}
class X{}''');
    addTestSource('''
import "b.dart";
class A extends B {
  static const String scA = 'foo';
  w() { }}
main() {A.^}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    // Suggested by StaticMemberContributor
    assertNotSuggested('scA');
    assertNotSuggested('scB');
    assertNotSuggested('scI');
    assertNotSuggested('b');
    assertNotSuggested('_c');
    assertNotSuggested('d');
    assertNotSuggested('_e');
    assertNotSuggested('f');
    assertNotSuggested('_g');
    assertNotSuggested('s1');
    assertNotSuggested('_s2');
    assertNotSuggested('m');
    assertNotSuggested('_n');
    assertNotSuggested('a');
    assertNotSuggested('A');
    assertNotSuggested('X');
    assertNotSuggested('w');
    assertNotSuggested('Object');
    assertNotSuggested('==');
  }

  Future<void> test_PrefixedIdentifier_class_imported() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource('/home/test/lib/b.dart', '''
lib B;
class I {X get f => new A();get _g => new A();}
class A implements I {
  static const int sc = 12;
  @deprecated var b; X _c;
  X get d => new A();get _e => new A();
  set s1(I x) {} set _s2(I x) {}
  m(X x) {} I _n(X x) {}}
class X{}''');
    addTestSource('''
import "b.dart";
main() {A a; a.^}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('sc');
    assertNotSuggested('b');
    assertNotSuggested('_c');
    assertNotSuggested('d');
    assertNotSuggested('_e');
    assertNotSuggested('f');
    assertNotSuggested('_g');
    assertNotSuggested('s1');
    assertNotSuggested('_s2');
    assertNotSuggested('m');
    assertNotSuggested('_n');
    assertNotSuggested('a');
    assertNotSuggested('A');
    assertNotSuggested('X');
    assertNotSuggested('Object');
    assertNotSuggested('==');
  }

  Future<void> test_PrefixedIdentifier_class_local() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('''
main() {A a; a.^}
class I {X get f => new A();get _g => new A();}
class A implements I {
  static const int sc = 12;
  var b; X _c;
  X get d => new A();get _e => new A();
  set s1(I x) {} set _s2(I x) {}
  m(X x) {} I _n(X x) {}}
class X{}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('sc');
    assertNotSuggested('b');
    assertNotSuggested('_c');
    assertNotSuggested('d');
    assertNotSuggested('_e');
    assertNotSuggested('f');
    assertNotSuggested('_g');
    assertNotSuggested('s1');
    assertNotSuggested('_s2');
    assertNotSuggested('m');
    assertNotSuggested('_n');
    assertNotSuggested('a');
    assertNotSuggested('A');
    assertNotSuggested('X');
    assertNotSuggested('Object');
    assertNotSuggested('==');
  }

  Future<void> test_PrefixedIdentifier_getter() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('String get g => "one"; f() {g.^}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  Future<void> test_PrefixedIdentifier_library() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource('/home/test/lib/b.dart', '''
lib B;
var T1;
class X { }
class Y { }''');
    addTestSource('''
import "b.dart" as b;
var T2;
class A { }
main() {b.^}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    // Suggested by LibraryMemberContributor
    assertNotSuggested('X');
    assertNotSuggested('Y');
    assertNotSuggested('T1');
    assertNotSuggested('T2');
    assertNotSuggested('Object');
    assertNotSuggested('b');
    assertNotSuggested('A');
    assertNotSuggested('==');
  }

  Future<void> test_PrefixedIdentifier_library_typesOnly() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName
    addSource('/home/test/lib/b.dart', '''
lib B;
var T1;
class X { }
class Y { }''');
    addTestSource('''
import "b.dart" as b;
var T2;
class A { }
foo(b.^ f) {}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    // Suggested by LibraryMemberContributor
    assertNotSuggested('X');
    assertNotSuggested('Y');
    assertNotSuggested('T1');
    assertNotSuggested('T2');
    assertNotSuggested('Object');
    assertNotSuggested('b');
    assertNotSuggested('A');
    assertNotSuggested('==');
  }

  Future<void> test_PrefixedIdentifier_library_typesOnly2() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName
    addSource('/home/test/lib/b.dart', '''
lib B;
var T1;
class X { }
class Y { }''');
    addTestSource('''
import "b.dart" as b;
var T2;
class A { }
foo(b.^) {}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    // Suggested by LibraryMemberContributor
    assertNotSuggested('X');
    assertNotSuggested('Y');
    assertNotSuggested('T1');
    assertNotSuggested('T2');
    assertNotSuggested('Object');
    assertNotSuggested('b');
    assertNotSuggested('A');
    assertNotSuggested('==');
  }

  Future<void> test_PrefixedIdentifier_parameter() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource('/home/test/lib/b.dart', '''
lib B;
class _W {M y; var _z;}
class X extends _W {}
class M{}''');
    addTestSource('''
import "b.dart";
foo(X x) {x.^}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('y');
    assertNotSuggested('_z');
    assertNotSuggested('==');
  }

  Future<void> test_PrefixedIdentifier_prefix() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource('/home/test/lib/a.dart', '''
class A {static int bar = 10;}
_B() {}''');
    addTestSource('''
import "a.dart";
class X {foo(){A^.bar}}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('A');
    assertSuggestClass('X');
    assertSuggestMethod('foo', 'X', null);
    assertNotSuggested('bar');
    assertNotSuggested('_B');
  }

  Future<void> test_PrefixedIdentifier_propertyAccess() async {
    // PrefixedIdentifier  ExpressionStatement  Block  BlockFunctionBody
    addTestSource('class A {String x; int get foo {x.^}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('isEmpty');
    assertNotSuggested('compareTo');
  }

  Future<void> test_PrefixedIdentifier_propertyAccess_newStmt() async {
    // PrefixedIdentifier  ExpressionStatement  Block  BlockFunctionBody
    addTestSource('class A {String x; int get foo {x.^ int y = 0;}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('isEmpty');
    assertNotSuggested('compareTo');
  }

  Future<void> test_PrefixedIdentifier_trailingStmt_const() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('const String g = "hello"; f() {g.^ int y = 0;}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  Future<void> test_PrefixedIdentifier_trailingStmt_field() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('class A {String g; f() {g.^ int y = 0;}}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  Future<void> test_PrefixedIdentifier_trailingStmt_function() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('String g() => "one"; f() {g.^ int y = 0;}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  Future<void> test_PrefixedIdentifier_trailingStmt_functionTypeAlias() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('typedef String g(); f() {g.^ int y = 0;}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  Future<void> test_PrefixedIdentifier_trailingStmt_getter() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('String get g => "one"; f() {g.^ int y = 0;}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  Future<void> test_PrefixedIdentifier_trailingStmt_local_typed() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('f() {String g; g.^ int y = 0;}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  Future<void> test_PrefixedIdentifier_trailingStmt_local_untyped() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('f() {var g = "hello"; g.^ int y = 0;}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  Future<void> test_PrefixedIdentifier_trailingStmt_method() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('class A {String g() {}; f() {g.^ int y = 0;}}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  Future<void> test_PrefixedIdentifier_trailingStmt_param() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('class A {f(String g) {g.^ int y = 0;}}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  Future<void> test_PrefixedIdentifier_trailingStmt_param2() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('f(String g) {g.^ int y = 0;}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  Future<void> test_PrefixedIdentifier_trailingStmt_topLevelVar() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('String g; f() {g.^ int y = 0;}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  Future<void> test_prioritization() async {
    addTestSource('main() {var ab; var _ab; ^}');
    await computeSuggestions();
    assertSuggestLocalVariable('ab', null);
    assertSuggestLocalVariable('_ab', null);
  }

  Future<void> test_prioritization_private() async {
    addTestSource('main() {var ab; var _ab; _^}');
    await computeSuggestions();
    assertSuggestLocalVariable('ab', null);
    assertSuggestLocalVariable('_ab', null);
  }

  Future<void> test_prioritization_public() async {
    addTestSource('main() {var ab; var _ab; a^}');
    await computeSuggestions();
    assertSuggestLocalVariable('ab', null);
    assertSuggestLocalVariable('_ab', null);
  }

  Future<void> test_PropertyAccess_expression() async {
    // SimpleIdentifier  MethodInvocation  PropertyAccess  ExpressionStatement
    addTestSource('class A {a() {"hello".to^String().length}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 2);
    expect(replacementLength, 8);
    assertNotSuggested('length');
    assertNotSuggested('A');
    assertNotSuggested('a');
    assertNotSuggested('Object');
    assertNotSuggested('==');
  }

  Future<void> test_PropertyAccess_noTarget() async {
    // SimpleIdentifier  PropertyAccess  ExpressionStatement
    addSource('/home/test/lib/ab.dart', 'class Foo { }');
    addTestSource('class C {foo(){.^}}');
    await computeSuggestions();

    assertNoSuggestions();
  }

  Future<void> test_PropertyAccess_noTarget2() async {
    // SimpleIdentifier  PropertyAccess  ExpressionStatement
    addSource('/home/test/lib/ab.dart', 'class Foo { }');
    addTestSource('main() {.^}');
    await computeSuggestions();

    assertNoSuggestions();
  }

  Future<void> test_PropertyAccess_selector() async {
    // SimpleIdentifier  PropertyAccess  ExpressionStatement  Block
    addTestSource('class A {a() {"hello".length.^}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('isEven');
    assertNotSuggested('A');
    assertNotSuggested('a');
    assertNotSuggested('Object');
    assertNotSuggested('==');
  }

  Future<void> test_shadowed_name() async {
    addTestSource('var a; class A { var a; m() { ^ } }');
    await computeSuggestions();
    assertSuggestField('a', null);
  }

  Future<void> test_static_field() async {
    resolveSource('/home/test/lib/b.dart', '''
lib libB;
class A2 {
  int x;
  int y() {return 0;}
  int x2;
  int y2() {return 0;}
}''');
    addTestSource('''
import "b.dart";
class A1 {
  int x;
  int y() {return 0;}
  int x1;
  int y1() {return 0;}
}
class B extends A1 with A2 {
  int a;
  int b() {return 0;}
  static foo = ^
}
''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertSuggestClass('B');
    assertSuggestField('a', 'int');
    assertSuggestMethod('b', 'B', 'int');
    assertSuggestField('foo', 'dynamic');
    assertSuggestClass('A1');
    assertSuggestConstructor('A1');
    assertNotSuggested('x');
    assertNotSuggested('y');
    assertNotSuggested('x1');
    assertNotSuggested('y1');
    assertNotSuggested('x2');
    assertNotSuggested('y2');
  }

  Future<void> test_static_method() async {
    resolveSource('/home/test/lib/b.dart', '''
lib libB;
class A2 {
  int x;
  int y() {return 0;}
  int x2;
  int y2() {return 0;}
}''');
    addTestSource('''
import "b.dart";
class A1 {
  int x;
  int y() {return 0;}
  int x1;
  int y1() {return 0;}
}
class B extends A1 with A2 {
  int a;
  int b() {return 0;}
  static foo() {^}
}
''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertSuggestClass('B');
    assertNotSuggested('a');
    assertNotSuggested('b');
    assertSuggestMethod('foo', 'B', 'dynamic');
    assertSuggestClass('A1');
    assertSuggestConstructor('A1');
    assertNotSuggested('x');
    assertNotSuggested('y');
    assertNotSuggested('x1');
    assertNotSuggested('y1');
    assertNotSuggested('x2');
    assertNotSuggested('y2');
  }

  Future<void> test_stringInterpolation() async {
    addTestSource(r'''
class C<T> {
  String m() => 'abc $^ xyz';
}
''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestTypeParameter('T');
  }

  Future<void> test_SwitchStatement_c() async {
    // SwitchStatement  Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class A {String g(int x) {switch(x) {c^}}}');
    await computeSuggestions();

    assertNoSuggestions();
  }

  Future<void> test_SwitchStatement_case() async {
    // SwitchStatement  Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class A {String g(int x) {var t; switch(x) {case 0: ^}}}');
    await computeSuggestions();

    assertSuggestClass('A');
    assertSuggestMethod('g', 'A', 'String');
    assertSuggestLocalVariable('t', null);
    assertNotSuggested('String');
  }

  Future<void> test_SwitchStatement_case_var() async {
    // SwitchStatement  Block  BlockFunctionBody  MethodDeclaration
    addTestSource('g(int x) {var t; switch(x) {case 0: var bar; b^}}');
    await computeSuggestions();

    assertSuggestFunction('g', 'dynamic');
    assertSuggestLocalVariable('t', 'dynamic');
    assertSuggestParameter('x', 'int');
    assertSuggestLocalVariable('bar', 'dynamic');
    assertNotSuggested('String');
  }

  Future<void> test_SwitchStatement_empty() async {
    // SwitchStatement  Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class A {String g(int x) {switch(x) {^}}}');
    await computeSuggestions();

    assertNoSuggestions();
  }

  Future<void> test_ThisExpression_block() async {
    // MethodInvocation  ExpressionStatement  Block
    addTestSource('''
main() { }
class I {X get f => new A();get _g => new A();}
class A implements I {
  A() {}
  A.z() {}
  var b; X _c;
  X get d => new A();get _e => new A();
  // no semicolon between completion point and next statement
  set s1(I x) {} set _s2(I x) {this.^ m(null);}
  m(X x) {} I _n(X x) {}}
class X{}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('b');
    assertNotSuggested('_c');
    assertNotSuggested('d');
    assertNotSuggested('_e');
    assertNotSuggested('f');
    assertNotSuggested('_g');
    assertNotSuggested('m');
    assertNotSuggested('_n');
    assertNotSuggested('s1');
    assertNotSuggested('_s2');
    assertNotSuggested('z');
    assertNotSuggested('I');
    assertNotSuggested('A');
    assertNotSuggested('X');
    assertNotSuggested('Object');
    assertNotSuggested('==');
  }

  Future<void> test_ThisExpression_constructor() async {
    // MethodInvocation  ExpressionStatement  Block
    addTestSource('''
main() { }
class I {X get f => new A();get _g => new A();}
class A implements I {
  A() {this.^}
  A.z() {}
  var b; X _c;
  X get d => new A();get _e => new A();
  // no semicolon between completion point and next statement
  set s1(I x) {} set _s2(I x) {m(null);}
  m(X x) {} I _n(X x) {}}
class X{}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('b');
    assertNotSuggested('_c');
    assertNotSuggested('d');
    assertNotSuggested('_e');
    assertNotSuggested('f');
    assertNotSuggested('_g');
    assertNotSuggested('m');
    assertNotSuggested('_n');
    assertNotSuggested('s1');
    assertNotSuggested('_s2');
    assertNotSuggested('z');
    assertNotSuggested('I');
    assertNotSuggested('A');
    assertNotSuggested('X');
    assertNotSuggested('Object');
    assertNotSuggested('==');
  }

  Future<void> test_ThisExpression_constructor_param() async {
    // SimpleIdentifier  FieldFormalParameter  FormalParameterList
    addTestSource('''
main() { }
class I {X get f => new A();get _g => new A();}
class A implements I {
  A(this.^) {}
  A.z() {}
  var b; X _c; static sb;
  X get d => new A();get _e => new A();
  // no semicolon between completion point and next statement
  set s1(I x) {} set _s2(I x) {m(null);}
  m(X x) {} I _n(X x) {}}
class X{}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    // Contributed by FieldFormalContributor
    assertNotSuggested('b');
    assertNotSuggested('_c');
    assertNotSuggested('sb');
    assertNotSuggested('d');
    assertNotSuggested('_e');
    assertNotSuggested('f');
    assertNotSuggested('_g');
    assertNotSuggested('m');
    assertNotSuggested('_n');
    assertNotSuggested('s1');
    assertNotSuggested('_s2');
    assertNotSuggested('z');
    assertNotSuggested('I');
    assertNotSuggested('A');
    assertNotSuggested('X');
    assertNotSuggested('Object');
    assertNotSuggested('==');
  }

  Future<void> test_ThisExpression_constructor_param2() async {
    // SimpleIdentifier  FieldFormalParameter  FormalParameterList
    addTestSource('''
main() { }
class I {X get f => new A();get _g => new A();}
class A implements I {
  A(this.b^) {}
  A.z() {}
  var b; X _c;
  X get d => new A();get _e => new A();
  // no semicolon between completion point and next statement
  set s1(I x) {} set _s2(I x) {m(null);}
  m(X x) {} I _n(X x) {}}
class X{}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    // Contributed by FieldFormalContributor
    assertNotSuggested('b');
    assertNotSuggested('_c');
    assertNotSuggested('d');
    assertNotSuggested('_e');
    assertNotSuggested('f');
    assertNotSuggested('_g');
    assertNotSuggested('m');
    assertNotSuggested('_n');
    assertNotSuggested('s1');
    assertNotSuggested('_s2');
    assertNotSuggested('z');
    assertNotSuggested('I');
    assertNotSuggested('A');
    assertNotSuggested('X');
    assertNotSuggested('Object');
    assertNotSuggested('==');
  }

  Future<void> test_ThisExpression_constructor_param3() async {
    // SimpleIdentifier  FieldFormalParameter  FormalParameterList
    addTestSource('''
main() { }
class I {X get f => new A();get _g => new A();}
class A implements I {
  A(this.^b) {}
  A.z() {}
  var b; X _c;
  X get d => new A();get _e => new A();
  // no semicolon between completion point and next statement
  set s1(I x) {} set _s2(I x) {m(null);}
  m(X x) {} I _n(X x) {}}
class X{}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 1);
    // Contributed by FieldFormalContributor
    assertNotSuggested('b');
    assertNotSuggested('_c');
    assertNotSuggested('d');
    assertNotSuggested('_e');
    assertNotSuggested('f');
    assertNotSuggested('_g');
    assertNotSuggested('m');
    assertNotSuggested('_n');
    assertNotSuggested('s1');
    assertNotSuggested('_s2');
    assertNotSuggested('z');
    assertNotSuggested('I');
    assertNotSuggested('A');
    assertNotSuggested('X');
    assertNotSuggested('Object');
    assertNotSuggested('==');
  }

  Future<void> test_ThisExpression_constructor_param4() async {
    // SimpleIdentifier  FieldFormalParameter  FormalParameterList
    addTestSource('''
main() { }
class I {X get f => new A();get _g => new A();}
class A implements I {
  A(this.b, this.^) {}
  A.z() {}
  var b; X _c;
  X get d => new A();get _e => new A();
  // no semicolon between completion point and next statement
  set s1(I x) {} set _s2(I x) {m(null);}
  m(X x) {} I _n(X x) {}}
class X{}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('b');
    // Contributed by FieldFormalContributor
    assertNotSuggested('_c');
    assertNotSuggested('d');
    assertNotSuggested('_e');
    assertNotSuggested('f');
    assertNotSuggested('_g');
    assertNotSuggested('m');
    assertNotSuggested('_n');
    assertNotSuggested('s1');
    assertNotSuggested('_s2');
    assertNotSuggested('z');
    assertNotSuggested('I');
    assertNotSuggested('A');
    assertNotSuggested('X');
    assertNotSuggested('Object');
    assertNotSuggested('==');
  }

  Future<void> test_TopLevelVariableDeclaration_shadow() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // TopLevelVariableDeclaration
    addTestSource('''
var foo;
void bar() {
  var foo;
  ^
}
''');
    await computeSuggestions();

    assertNotSuggested('foo', elemKind: ElementKind.TOP_LEVEL_VARIABLE);
    assertSuggest('foo', elemKind: ElementKind.LOCAL_VARIABLE);
  }

  Future<void> test_TopLevelVariableDeclaration_typed_name() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // TopLevelVariableDeclaration
    addTestSource('class A {} B ^');
    await computeSuggestions();

    assertNoSuggestions();
  }

  Future<void> test_TopLevelVariableDeclaration_untyped_name() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // TopLevelVariableDeclaration
    addTestSource('class A {} var ^');
    await computeSuggestions();

    assertNoSuggestions();
  }

  Future<void> test_TypeArgumentList() async {
    // SimpleIdentifier  BinaryExpression  ExpressionStatement
    addSource('/home/test/lib/a.dart', '''
class C1 {int x;}
F1() => 0;
typedef String T1(int blat);''');
    addTestSource('''
import "a.dart";'
class C2 {int x;}
F2() => 0;
typedef int T2(int blat);
class C<E> {}
main() { C<^> c; }''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertNotSuggested('C1');
    assertNotSuggested('T1');
    assertSuggestClass('C2');
    assertSuggestFunctionTypeAlias('T2', 'int');
    assertNotSuggested('F1');
    assertNotSuggested('F2');
  }

  Future<void> test_TypeArgumentList2() async {
    // TypeName  TypeArgumentList  TypeName
    addSource('/home/test/lib/a.dart', '''
class C1 {int x;}
F1() => 0;
typedef String T1(int blat);''');
    addTestSource('''
import "a.dart";'
class C2 {int x;}
F2() => 0;
typedef int T2(int blat);
class C<E> {}
main() { C<C^> c; }''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('C1');
    assertSuggestClass('C2');
  }

  Future<void> test_TypeParameter_classDeclaration() async {
    addTestSource('''
class A<T> {
  ^ m() {}
}
''');
    await computeSuggestions();
    assertSuggestTypeParameter('T');
  }

  Future<void> test_TypeParameter_shadowed() async {
    addTestSource('''
class A<T> {
  m() {
    int T;
    ^
  }
}
''');
    await computeSuggestions();
    assertNotSuggested('T', elemKind: ElementKind.TYPE_PARAMETER);
    assertSuggest('T', elemKind: ElementKind.LOCAL_VARIABLE);
  }

  Future<void> test_VariableDeclaration_name() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addSource('/home/test/lib/b.dart', '''
lib B;
foo() { }
class _B { }
class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
import "b.dart";
class Y {Y.c(); Y._d(); z() {}}
main() {var ^}''');
    await computeSuggestions();

    assertNoSuggestions();
  }

  Future<void> test_VariableDeclarationList_final() async {
    // VariableDeclarationList  VariableDeclarationStatement  Block
    addTestSource('main() {final ^} class C { }');
    await computeSuggestions();

    assertNotSuggested('Object');
    assertSuggestClass('C');
    assertNotSuggested('==');
  }

  Future<void> test_VariableDeclarationStatement_RHS() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement
    addSource('/home/test/lib/b.dart', '''
lib B;
foo() { }
class _B { }
class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
import "b.dart";
class Y {Y.c(); Y._d(); z() {}}
class C {bar(){var f; {var x;} var e = ^}}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('X');
    assertNotSuggested('_B');
    assertSuggestClass('Y');
    assertSuggestClass('C');
    assertSuggestLocalVariable('f', null);
    assertNotSuggested('x');
    assertNotSuggested('e');
  }

  Future<void> test_VariableDeclarationStatement_RHS_missing_semicolon() async {
    // VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement
    addSource('/home/test/lib/b.dart', '''
lib B;
foo1() { }
void bar1() { }
class _B { }
class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
import "b.dart";
foo2() { }
void bar2() { }
class Y {Y.c(); Y._d(); z() {}}
class C {bar(){var f; {var x;} var e = ^ var g}}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('X');
    assertNotSuggested('foo1');
    assertNotSuggested('bar1');
    assertSuggestFunction('foo2', null);
    assertNotSuggested('bar2');
    assertNotSuggested('_B');
    assertSuggestClass('Y');
    assertSuggestClass('C');
    assertSuggestLocalVariable('f', null);
    assertNotSuggested('x');
    assertNotSuggested('e');
  }

  Future<void> test_withClause_mixin() async {
    addTestSource('''
class A {}
mixin M {}
class B extends A with ^
''');
    await computeSuggestions();
    assertSuggestMixin('M');
  }

  Future<void> test_YieldStatement() async {
    addTestSource('''
void main() async* {
  var value;
  yield v^
}
''');
    await computeSuggestions();

    assertSuggestLocalVariable('value', null);
  }

  Future<void> _check_flutter_setState(
      String line, String completion, int selectionOffset) async {
    writeTestPackageConfig(flutter: true);
    addTestSource('''
import 'package:flutter/widgets.dart';

class TestWidget extends StatefulWidget {
  @override
  TestWidgetState createState() {
    return new TestWidgetState();
  }
}

class TestWidgetState extends State<TestWidget> {
  @override
  Widget build(BuildContext context) {
$line^
  }
}
''');
    await computeSuggestions();
    var cs = assertSuggest(completion, selectionOffset: selectionOffset);
    expect(cs.selectionLength, 0);

    // It is an invocation, but we don't need any additional info for it.
    // So, all parameter information is absent.
    expect(cs.parameterNames, isNull);
    expect(cs.parameterTypes, isNull);
    expect(cs.requiredParameterCount, isNull);
    expect(cs.hasNamedParameters, isNull);
  }
}
