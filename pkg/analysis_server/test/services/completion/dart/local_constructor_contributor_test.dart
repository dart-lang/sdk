// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.contributor.dart.constructor;

import 'package:analysis_server/plugin/protocol/protocol.dart' as protocol
    show Element, ElementKind;
import 'package:analysis_server/plugin/protocol/protocol.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/local_constructor_contributor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalConstructorContributorTest);
    defineReflectiveTests(LocalConstructorContributorTest_Driver);
  });
}

@reflectiveTest
class LocalConstructorContributorTest extends DartCompletionContributorTest {
  CompletionSuggestion assertSuggestLocalVariable(
      String name, String returnType,
      {int relevance: DART_RELEVANCE_LOCAL_VARIABLE}) {
    // Local variables should only be suggested by LocalReferenceContributor
    CompletionSuggestion cs = assertSuggest(name,
        csKind: CompletionSuggestionKind.INVOCATION, relevance: relevance);
    expect(cs.returnType, returnType != null ? returnType : 'dynamic');
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.LOCAL_VARIABLE));
    expect(element.name, equals(name));
    expect(element.parameters, isNull);
    expect(element.returnType, returnType != null ? returnType : 'dynamic');
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestParameter(String name, String returnType,
      {int relevance: DART_RELEVANCE_PARAMETER}) {
    CompletionSuggestion cs = assertSuggest(name,
        csKind: CompletionSuggestionKind.INVOCATION, relevance: relevance);
    expect(cs.returnType, returnType != null ? returnType : 'dynamic');
    protocol.Element element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.PARAMETER));
    expect(element.name, equals(name));
    expect(element.parameters, isNull);
    expect(element.returnType,
        equals(returnType != null ? returnType : 'dynamic'));
    return cs;
  }

  @override
  DartCompletionContributor createContributor() {
    return new LocalConstructorContributor();
  }

  test_ArgumentList() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource(
        '/libA.dart',
        '''
library A;
bool hasLength(int expected) { }
void baz() { }''');
    addTestSource('''
import '/libA.dart';
class B { }
String bar() => true;
void main() {expect(^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNoSuggestions(kind: CompletionSuggestionKind.ARGUMENT_LIST);
    assertNotSuggested('bar');
    assertNotSuggested('hasLength');
    assertNotSuggested('identical');
    assertNotSuggested('B');
    assertNotSuggested('Object');
    assertNotSuggested('main');
    assertNotSuggested('baz');
    assertNotSuggested('print');
  }

  test_ArgumentList_imported_function() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource(
        '/libA.dart',
        '''
library A;
bool hasLength(int expected) { }
expect(arg) { }
void baz() { }''');
    addTestSource('''
import '/libA.dart'
class B { }
String bar() => true;
void main() {expect(^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNoSuggestions(kind: CompletionSuggestionKind.ARGUMENT_LIST);
    assertNotSuggested('bar');
    assertNotSuggested('hasLength');
    assertNotSuggested('identical');
    assertNotSuggested('B');
    assertNotSuggested('Object');
    assertNotSuggested('main');
    assertNotSuggested('baz');
    assertNotSuggested('print');
  }

  test_ArgumentList_InstanceCreationExpression_functionalArg() async {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement  Block
    addSource(
        '/libA.dart',
        '''
library A;
class A { A(f()) { } }
bool hasLength(int expected) { }
void baz() { }''');
    addTestSource('''
import 'dart:async';
import '/libA.dart';
class B { }
String bar() => true;
void main() {new A(^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNoSuggestions(kind: CompletionSuggestionKind.ARGUMENT_LIST);
    assertNotSuggested('bar');
    assertNotSuggested('hasLength');
    assertNotSuggested('identical');
    assertNotSuggested('B');
    assertNotSuggested('A');
    assertNotSuggested('Object');
    assertNotSuggested('main');
    assertNotSuggested('baz');
    assertNotSuggested('print');
  }

  test_ArgumentList_InstanceCreationExpression_typedefArg() async {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement  Block
    addSource(
        '/libA.dart',
        '''
library A;
typedef Funct();
class A { A(Funct f) { } }
bool hasLength(int expected) { }
void baz() { }''');
    addTestSource('''
import 'dart:async';
import '/libA.dart';
class B { }
String bar() => true;
void main() {new A(^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNoSuggestions(kind: CompletionSuggestionKind.ARGUMENT_LIST);
    assertNotSuggested('bar');
    assertNotSuggested('hasLength');
    assertNotSuggested('identical');
    assertNotSuggested('B');
    assertNotSuggested('A');
    assertNotSuggested('Object');
    assertNotSuggested('main');
    assertNotSuggested('baz');
    assertNotSuggested('print');
  }

  test_ArgumentList_local_function() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource(
        '/libA.dart',
        '''
library A;
bool hasLength(int expected) { }
void baz() { }''');
    addTestSource('''
import '/libA.dart'
expect(arg) { }
class B { }
String bar() => true;
void main() {expect(^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNoSuggestions(kind: CompletionSuggestionKind.ARGUMENT_LIST);
    assertNotSuggested('bar');
    assertNotSuggested('hasLength');
    assertNotSuggested('identical');
    assertNotSuggested('B');
    assertNotSuggested('Object');
    assertNotSuggested('main');
    assertNotSuggested('baz');
    assertNotSuggested('print');
  }

  test_ArgumentList_local_method() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource(
        '/libA.dart',
        '''
library A;
bool hasLength(int expected) { }
void baz() { }''');
    addTestSource('''
import '/libA.dart'
class B {
  expect(arg) { }
  void foo() {expect(^)}}
String bar() => true;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNoSuggestions(kind: CompletionSuggestionKind.ARGUMENT_LIST);
    assertNotSuggested('bar');
    assertNotSuggested('hasLength');
    assertNotSuggested('identical');
    assertNotSuggested('B');
    assertNotSuggested('Object');
    assertNotSuggested('main');
    assertNotSuggested('baz');
    assertNotSuggested('print');
  }

  test_ArgumentList_MethodInvocation_functionalArg() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource(
        '/libA.dart',
        '''
library A;
class A { A(f()) { } }
bool hasLength(int expected) { }
void baz() { }''');
    addTestSource('''
import 'dart:async';
import '/libA.dart';
class B { }
String bar(f()) => true;
void main() {bar(^);}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNoSuggestions(kind: CompletionSuggestionKind.ARGUMENT_LIST);
    assertNotSuggested('bar');
    assertNotSuggested('hasLength');
    assertNotSuggested('identical');
    assertNotSuggested('B');
    assertNotSuggested('A');
    assertNotSuggested('Object');
    assertNotSuggested('main');
    assertNotSuggested('baz');
    assertNotSuggested('print');
  }

  test_ArgumentList_MethodInvocation_methodArg() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource(
        '/libA.dart',
        '''
library A;
class A { A(f()) { } }
bool hasLength(int expected) { }
void baz() { }''');
    addTestSource('''
import 'dart:async';
import '/libA.dart';
class B { String bar(f()) => true; }
void main() {new B().bar(^);}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNoSuggestions(kind: CompletionSuggestionKind.ARGUMENT_LIST);
    assertNotSuggested('hasLength');
    assertNotSuggested('identical');
    assertNotSuggested('B');
    assertNotSuggested('A');
    assertNotSuggested('Object');
    assertNotSuggested('main');
    assertNotSuggested('baz');
    assertNotSuggested('print');
  }

  test_ArgumentList_namedParam() async {
    // SimpleIdentifier  NamedExpression  ArgumentList  MethodInvocation
    // ExpressionStatement
    addSource(
        '/libA.dart',
        '''
library A;
bool hasLength(int expected) { }''');
    addTestSource('''
import '/libA.dart'
String bar() => true;
void main() {expect(foo: ^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('bar');
    assertNotSuggested('hasLength');
    assertNotSuggested('main');
  }

  test_AsExpression() async {
    // SimpleIdentifier  TypeName  AsExpression
    addTestSource('''
        class A {var b; X _c; foo() {var a; (a as ^).foo();}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('b');
    assertNotSuggested('_c');
    assertNotSuggested('Object');
    assertNotSuggested('A');
    assertNotSuggested('==');
  }

  test_AssignmentExpression_name() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('class A {} main() {int a; int ^b = 1;}');
    await computeSuggestions();

    assertNoSuggestions();
  }

  test_AssignmentExpression_RHS() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addTestSource('class A {} main() {int a; int b = ^}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
    assertNotSuggested('main');
    assertNotSuggested('A');
    assertNotSuggested('Object');
  }

  test_AssignmentExpression_type() async {
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
    assertNotSuggested('A');
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

  test_AssignmentExpression_type_newline() async {
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
    assertNotSuggested('A');
    assertNotSuggested('int');
    // Allow non-types preceding an identifier on LHS of assignment
    // if newline follows first identifier
    // because user is probably starting a new statement
    assertNotSuggested('a');
    assertNotSuggested('main');
    assertNotSuggested('identical');
  }

  test_AssignmentExpression_type_partial() async {
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
    assertNotSuggested('A');
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

  test_AssignmentExpression_type_partial_newline() async {
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
    assertNotSuggested('A');
    assertNotSuggested('int');
    // Allow non-types preceding an identifier on LHS of assignment
    // if newline follows first identifier
    // because user is probably starting a new statement
    assertNotSuggested('a');
    assertNotSuggested('main');
    assertNotSuggested('identical');
  }

  test_AwaitExpression() async {
    // SimpleIdentifier  AwaitExpression  ExpressionStatement
    addTestSource('''
class A {int x; int y() => 0;}
main() async {A a; await ^}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
    assertNotSuggested('main');
    assertNotSuggested('A');
    assertNotSuggested('Object');
  }

  test_BinaryExpression_LHS() async {
    // SimpleIdentifier  BinaryExpression  VariableDeclaration
    // VariableDeclarationList  VariableDeclarationStatement
    addTestSource('main() {int a = 1, b = ^ + 2;}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
    assertNotSuggested('Object');
    assertNotSuggested('b');
  }

  test_BinaryExpression_RHS() async {
    // SimpleIdentifier  BinaryExpression  VariableDeclaration
    // VariableDeclarationList  VariableDeclarationStatement
    addTestSource('main() {int a = 1, b = 2 + ^;}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
    assertNotSuggested('Object');
    assertNotSuggested('b');
    assertNotSuggested('==');
  }

  test_Block() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addSource(
        '/testAB.dart',
        '''
export "dart:math" hide max;
class A {int x;}
@deprecated D1() {int x;}
class _B {boo() { partBoo() {}} }''');
    addSource(
        '/testCD.dart',
        '''
String T1;
var _T2;
class C { }
class D { }''');
    addSource(
        '/testEEF.dart',
        '''
class EE { }
class F { }''');
    addSource('/testG.dart', 'class G { }');
    addSource(
        '/testH.dart',
        '''
class H { }
int T3;
var _T4;'''); // not imported
    addTestSource('''
import "/testAB.dart";
import "/testCD.dart" hide D;
import "/testEEF.dart" show EE;
import "/testG.dart" as g;
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

    assertNotSuggested('X');
    assertNotSuggested('Z');
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

  test_Block_final() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addSource(
        '/testAB.dart',
        '''
export "dart:math" hide max;
class A {int x;}
@deprecated D1() {int x;}
class _B {boo() { partBoo() {}} }''');
    addSource(
        '/testCD.dart',
        '''
String T1;
var _T2;
class C { }
class D { }''');
    addSource(
        '/testEEF.dart',
        '''
class EE { }
class F { }''');
    addSource('/testG.dart', 'class G { }');
    addSource(
        '/testH.dart',
        '''
class H { }
int T3;
var _T4;'''); // not imported
    addTestSource('''
import "/testAB.dart";
import "/testCD.dart" hide D;
import "/testEEF.dart" show EE;
import "/testG.dart" as g;
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

    assertNotSuggested('X');
    assertNotSuggested('Z');
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

  test_Block_final2() async {
    addTestSource('main() {final S^ v;}');
    await computeSuggestions();

    assertNotSuggested('String');
  }

  test_Block_final3() async {
    addTestSource('main() {final ^ v;}');
    await computeSuggestions();

    assertNotSuggested('String');
  }

  test_Block_final_final() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addSource(
        '/testAB.dart',
        '''
export "dart:math" hide max;
class A {int x;}
@deprecated D1() {int x;}
class _B {boo() { partBoo() {}} }''');
    addSource(
        '/testCD.dart',
        '''
String T1;
var _T2;
class C { }
class D { }''');
    addSource(
        '/testEEF.dart',
        '''
class EE { }
class F { }''');
    addSource('/testG.dart', 'class G { }');
    addSource(
        '/testH.dart',
        '''
class H { }
int T3;
var _T4;'''); // not imported
    addTestSource('''
import "/testAB.dart";
import "/testCD.dart" hide D;
import "/testEEF.dart" show EE;
import "/testG.dart" as g;
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

    assertNotSuggested('X');
    assertNotSuggested('Z');
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

  test_Block_final_var() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addSource(
        '/testAB.dart',
        '''
export "dart:math" hide max;
class A {int x;}
@deprecated D1() {int x;}
class _B {boo() { partBoo() {}} }''');
    addSource(
        '/testCD.dart',
        '''
String T1;
var _T2;
class C { }
class D { }''');
    addSource(
        '/testEEF.dart',
        '''
class EE { }
class F { }''');
    addSource('/testG.dart', 'class G { }');
    addSource(
        '/testH.dart',
        '''
class H { }
int T3;
var _T4;'''); // not imported
    addTestSource('''
import "/testAB.dart";
import "/testCD.dart" hide D;
import "/testEEF.dart" show EE;
import "/testG.dart" as g;
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

    assertNotSuggested('X');
    assertNotSuggested('Z');
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

  test_Block_identifier_partial() async {
    addSource(
        '/testAB.dart',
        '''
export "dart:math" hide max;
class A {int x;}
@deprecated D1() {int x;}
class _B { }''');
    addSource(
        '/testCD.dart',
        '''
String T1;
var _T2;
class C { }
class D { }''');
    addSource(
        '/testEEF.dart',
        '''
class EE { }
class F { }''');
    addSource('/testG.dart', 'class G { }');
    addSource(
        '/testH.dart',
        '''
class H { }
class D3 { }
int T3;
var _T4;'''); // not imported
    addTestSource('''
import "/testAB.dart";
import "/testCD.dart" hide D;
import "/testEEF.dart" show EE;
import "/testG.dart" as g;
int T5;
var _T6;
Z D2() {int x;}
class X {a() {var f; {var x;} D^ var r;} void b() { }}
class Z { }''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);

    assertNotSuggested('X');
    assertNotSuggested('Z');
    assertNotSuggested('a');
    assertNotSuggested('b');
    assertNotSuggested('f');
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
    assertNotSuggested('D2');
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
    //assertNotSuggested('T5');
    //assertSuggestTopLevelVar('_T6', null);
    assertNotSuggested('==');
    // TODO (danrubel) suggest HtmlElement as low relevance
    assertNotSuggested('HtmlElement');
  }

  test_Block_inherited_imported() async {
    // Block  BlockFunctionBody  MethodDeclaration  ClassDeclaration
    addSource(
        '/testB.dart',
        '''
lib B;
class F { var f1; f2() { } get f3 => 0; set f4(fx) { } var _pf; }
class E extends F { var e1; e2() { } }
class I { int i1; i2() { } }
class M { var m1; int m2() { } }''');
    addTestSource('''
import "/testB.dart";
class A extends E implements I with M {a() {^}}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    // TODO (danrubel) prefer fields over getters
    // If add `get e1;` to interface I
    // then suggestions include getter e1 rather than field e1
    assertNotSuggested('e1');
    assertNotSuggested('f1');
    assertNotSuggested('i1');
    assertNotSuggested('m1');
    assertNotSuggested('f3');
    assertNotSuggested('f4');
    assertNotSuggested('e2');
    assertNotSuggested('f2');
    assertNotSuggested('i2');
    //assertNotSuggested('m2');
    assertNotSuggested('==');
  }

  test_Block_inherited_local() async {
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
    assertNotSuggested('e1');
    assertNotSuggested('f1');
    assertNotSuggested('i1');
    assertNotSuggested('m1');
    assertNotSuggested('f3');
    assertNotSuggested('f4');
    assertNotSuggested('e2');
    assertNotSuggested('f2');
    assertNotSuggested('i2');
    assertNotSuggested('m2');
  }

  test_Block_local_function() async {
    addSource(
        '/testAB.dart',
        '''
export "dart:math" hide max;
class A {int x;}
@deprecated D1() {int x;}
class _B {boo() { partBoo() {}} }''');
    addSource(
        '/testCD.dart',
        '''
String T1;
var _T2;
class C { }
class D { }''');
    addSource(
        '/testEEF.dart',
        '''
class EE { }
class F { }''');
    addSource('/testG.dart', 'class G { }');
    addSource(
        '/testH.dart',
        '''
class H { }
int T3;
var _T4;'''); // not imported
    addTestSource('''
import "/testAB.dart";
import "/testCD.dart" hide D;
import "/testEEF.dart" show EE;
import "/testG.dart" as g;
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

  test_Block_unimported() async {
    addPackageSource('myBar', 'bar.dart', 'class Foo2 { Foo2() { } }');
    addSource(
        '/proj/testAB.dart', 'import "package:myBar/bar.dart"; class Foo { }');
    testFile = '/proj/completionTest.dart';
    addTestSource('class C {foo(){F^}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('Foo');
    // TODO(danrubel) implement
    assertNotSuggested('Foo2');
    assertNotSuggested('Future');
  }

  test_CascadeExpression_selector1() async {
    // PropertyAccess  CascadeExpression  ExpressionStatement  Block
    addSource(
        '/testB.dart',
        '''
class B { }''');
    addTestSource('''
import "/testB.dart";
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

  test_CascadeExpression_selector2() async {
    // SimpleIdentifier  PropertyAccess  CascadeExpression  ExpressionStatement
    addSource(
        '/testB.dart',
        '''
class B { }''');
    addTestSource('''
import "/testB.dart";
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

  test_CascadeExpression_selector2_withTrailingReturn() async {
    // PropertyAccess  CascadeExpression  ExpressionStatement  Block
    addSource(
        '/testB.dart',
        '''
class B { }''');
    addTestSource('''
import "/testB.dart";
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

  test_CascadeExpression_target() async {
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
    assertNotSuggested('a');
    assertNotSuggested('A');
    assertNotSuggested('X');
    // top level results are partially filtered
    //assertNotSuggested('Object');
    assertNotSuggested('==');
  }

  test_CatchClause_onType() async {
    // TypeName  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} on ^ {}}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('A');
    assertNotSuggested('Object');
    assertNotSuggested('a');
    assertNotSuggested('x');
  }

  test_CatchClause_onType_noBrackets() async {
    // TypeName  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} on ^}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('A');
    assertNotSuggested('Object');
    assertNotSuggested('x');
  }

  test_CatchClause_typed() async {
    // Block  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} on E catch (e) {^}}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('e');
    assertNotSuggested('a');
    assertNotSuggested('Object');
    assertNotSuggested('x');
  }

  test_CatchClause_untyped() async {
    // Block  CatchClause  TryStatement
    addTestSource('class A {a() {try{var x;} catch (e, s) {^}}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('e');
    assertNotSuggested('s');
    assertNotSuggested('a');
    assertNotSuggested('Object');
    assertNotSuggested('x');
  }

  test_ClassDeclaration_body() async {
    // ClassDeclaration  CompilationUnit
    addSource(
        '/testB.dart',
        '''
class B { }''');
    addTestSource('''
import "testB.dart" as x;
@deprecated class A {^}
class _B {}
A T;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('A');
    assertNotSuggested('_B');
    assertNotSuggested('Object');
    assertNotSuggested('T');
    // Suggested by LibraryPrefixContributor
    assertNotSuggested('x');
  }

  test_ClassDeclaration_body_final() async {
    // ClassDeclaration  CompilationUnit
    addSource(
        '/testB.dart',
        '''
class B { }''');
    addTestSource('''
import "testB.dart" as x;
class A {final ^}
class _B {}
A T;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('A');
    assertNotSuggested('_B');
    assertNotSuggested('Object');
    assertNotSuggested('T');
    // Suggested by LibraryPrefixContributor
    assertNotSuggested('x');
  }

  test_ClassDeclaration_body_final_field() async {
    // ClassDeclaration  CompilationUnit
    addSource(
        '/testB.dart',
        '''
class B { }''');
    addTestSource('''
import "testB.dart" as x;
class A {final ^ A(){}}
class _B {}
A T;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('A');
    assertNotSuggested('_B');
    assertNotSuggested('String');
    assertNotSuggested('T');
    // Suggested by LibraryPrefixContributor
    assertNotSuggested('x');
  }

  test_ClassDeclaration_body_final_field2() async {
    // ClassDeclaration  CompilationUnit
    addSource(
        '/testB.dart',
        '''
class B { }''');
    addTestSource('''
import "testB.dart" as Soo;
class A {final S^ A();}
class _B {}
A Sew;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('A');
    assertNotSuggested('_B');
    assertNotSuggested('String');
    assertNotSuggested('Sew');
    // Suggested by LibraryPrefixContributor
    assertNotSuggested('Soo');
  }

  test_ClassDeclaration_body_final_final() async {
    // ClassDeclaration  CompilationUnit
    addSource(
        '/testB.dart',
        '''
class B { }''');
    addTestSource('''
import "testB.dart" as x;
class A {final ^ final foo;}
class _B {}
A T;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('A');
    assertNotSuggested('_B');
    assertNotSuggested('Object');
    assertNotSuggested('T');
    // Suggested by LibraryPrefixContributor
    assertNotSuggested('x');
  }

  test_ClassDeclaration_body_final_var() async {
    // ClassDeclaration  CompilationUnit
    addSource(
        '/testB.dart',
        '''
class B { }''');
    addTestSource('''
import "testB.dart" as x;
class A {final ^ var foo;}
class _B {}
A T;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('A');
    assertNotSuggested('_B');
    assertNotSuggested('Object');
    assertNotSuggested('T');
    // Suggested by LibraryPrefixContributor
    assertNotSuggested('x');
  }

  test_Combinator_hide() async {
    // SimpleIdentifier  HideCombinator  ImportDirective
    addSource(
        '/testAB.dart',
        '''
library libAB;
part '/partAB.dart';
class A { }
class B { }''');
    addSource(
        '/partAB.dart',
        '''
part of libAB;
var T1;
PB F1() => new PB();
class PB { }''');
    addSource(
        '/testCD.dart',
        '''
class C { }
class D { }''');
    addTestSource('''
import "/testAB.dart" hide ^;
import "/testCD.dart";
class X {}''');
    await computeSuggestions();

    assertNoSuggestions();
  }

  test_Combinator_show() async {
    // SimpleIdentifier  HideCombinator  ImportDirective
    addSource(
        '/testAB.dart',
        '''
library libAB;
part '/partAB.dart';
class A { }
class B { }''');
    addSource(
        '/partAB.dart',
        '''
part of libAB;
var T1;
PB F1() => new PB();
typedef PB2 F2(int blat);
class Clz = Object with Object;
class PB { }''');
    addSource(
        '/testCD.dart',
        '''
class C { }
class D { }''');
    addTestSource('''
import "/testAB.dart" show ^;
import "/testCD.dart";
class X {}''');
    await computeSuggestions();

    assertNoSuggestions();
  }

  test_ConditionalExpression_elseExpression() async {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
class A {int x;}''');
    addTestSource('''
import "/testA.dart";
int T2;
F2() { }
class B {int x;}
class C {foo(){var f; {var x;} return a ? T1 : T^}}''');
    await computeSuggestions();

    // top level results are partially filtered based on first char
    assertNotSuggested('T2');
    // TODO (danrubel) getter is being suggested instead of top level var
    //assertNotSuggested('T1');
  }

  test_ConditionalExpression_elseExpression_empty() async {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
class A {int x;}''');
    addTestSource('''
import "/testA.dart";
int T2;
F2() { }
class B {int x;}
class C {foo(){var f; {var x;} return a ? T1 : ^}}''');
    await computeSuggestions();

    assertNotSuggested('x');
    assertNotSuggested('f');
    assertNotSuggested('foo');
    assertNotSuggested('C');
    assertNotSuggested('F2');
    assertNotSuggested('T2');
    assertNotSuggested('A');
    assertNotSuggested('F1');
    // TODO (danrubel) getter is being suggested instead of top level var
    //assertNotSuggested('T1');
  }

  test_ConditionalExpression_partial_thenExpression() async {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
class A {int x;}''');
    addTestSource('''
import "/testA.dart";
int T2;
F2() { }
class B {int x;}
class C {foo(){var f; {var x;} return a ? T^}}''');
    await computeSuggestions();

    // top level results are partially filtered based on first char
    assertNotSuggested('T2');
    // TODO (danrubel) getter is being suggested instead of top level var
    //assertNotSuggested('T1');
  }

  test_ConditionalExpression_partial_thenExpression_empty() async {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
class A {int x;}''');
    addTestSource('''
import "/testA.dart";
int T2;
F2() { }
class B {int x;}
class C {foo(){var f; {var x;} return a ? ^}}''');
    await computeSuggestions();

    assertNotSuggested('x');
    assertNotSuggested('f');
    assertNotSuggested('foo');
    assertNotSuggested('C');
    assertNotSuggested('F2');
    assertNotSuggested('T2');
    assertNotSuggested('A');
    assertNotSuggested('F1');
    // TODO (danrubel) getter is being suggested instead of top level var
    //assertNotSuggested('T1');
  }

  test_ConditionalExpression_thenExpression() async {
    // SimpleIdentifier  ConditionalExpression  ReturnStatement
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
class A {int x;}''');
    addTestSource('''
import "/testA.dart";
int T2;
F2() { }
class B {int x;}
class C {foo(){var f; {var x;} return a ? T^ : c}}''');
    await computeSuggestions();

    // top level results are partially filtered based on first char
    assertNotSuggested('T2');
    // TODO (danrubel) getter is being suggested instead of top level var
    //assertNotSuggested('T1');
  }

  test_constructor_parameters_mixed_required_and_named() async {
    addTestSource('class A {A(x, {int y}) {^}}');
    await computeSuggestions();
    assertNotSuggested('x');
    assertNotSuggested('y');
  }

  test_constructor_parameters_mixed_required_and_positional() async {
    addTestSource('class A {A(x, [int y]) {^}}');
    await computeSuggestions();
    assertNotSuggested('x');
    assertNotSuggested('y');
  }

  test_constructor_parameters_named() async {
    addTestSource('class A {A({x, int y}) {^}}');
    await computeSuggestions();
    assertNotSuggested('x');
    assertNotSuggested('y');
  }

  test_constructor_parameters_positional() async {
    addTestSource('class A {A([x, int y]) {^}}');
    await computeSuggestions();
    assertNotSuggested('x');
    assertNotSuggested('y');
  }

  test_constructor_parameters_required() async {
    addTestSource('class A {A(x, int y) {^}}');
    await computeSuggestions();
    assertNotSuggested('x');
    assertNotSuggested('y');
  }

  test_ConstructorName_importedClass() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addSource(
        '/testB.dart',
        '''
lib B;
int T1;
F1() { }
class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
import "/testB.dart";
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

  test_ConstructorName_importedFactory() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName  ConstructorName
    // InstanceCreationExpression
    addSource(
        '/testB.dart',
        '''
lib B;
int T1;
F1() { }
class X {factory X.c(); factory X._d(); z() {}}''');
    addTestSource('''
import "/testB.dart";
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

  test_ConstructorName_importedFactory2() async {
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

  test_ConstructorName_localClass() async {
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

  test_ConstructorName_localFactory() async {
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

  test_DefaultFormalParameter_named_expression() async {
    // DefaultFormalParameter FormalParameterList MethodDeclaration
    addTestSource('''
foo() { }
void bar() { }
class A {a(blat: ^) { }}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('foo');
    assertNotSuggested('a');
    assertNotSuggested('A');
    assertNotSuggested('String');
    assertNotSuggested('identical');
    assertNotSuggested('bar');
  }

  test_enum() async {
    addTestSource('enum E { one, two } main() {^}');
    await computeSuggestions();
    assertNotSuggested('E');
    assertNotSuggested('one');
    assertNotSuggested('two');
  }

  test_enum_deprecated() async {
    addTestSource('@deprecated enum E { one, two } main() {^}');
    await computeSuggestions();
    assertNotSuggested('E');
    assertNotSuggested('one');
    assertNotSuggested('two');
  }

  test_ExpressionStatement_identifier() async {
    // SimpleIdentifier  ExpressionStatement  Block
    addSource(
        '/testA.dart',
        '''
_B F1() { }
class A {int x;}
class _B { }''');
    addTestSource('''
import "/testA.dart";
typedef int F2(int blat);
class Clz = Object with Object;
class C {foo(){^} void bar() {}}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('A');
    assertNotSuggested('F1');
    assertNotSuggested('C');
    assertNotSuggested('foo');
    assertNotSuggested('bar');
    assertNotSuggested('F2');
    assertNotSuggested('Clz');
    assertNotSuggested('C');
    assertNotSuggested('x');
    assertNotSuggested('_B');
  }

  test_ExpressionStatement_name() async {
    // ExpressionStatement  Block  BlockFunctionBody  MethodDeclaration
    addSource(
        '/testA.dart',
        '''
        B T1;
        class B{}''');
    addTestSource('''
        import "/testA.dart";
        class C {a() {C ^}}''');
    await computeSuggestions();

    assertNoSuggestions();
  }

  test_FieldDeclaration_name_typed() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // FieldDeclaration
    addSource('/testA.dart', 'class A { }');
    addTestSource('''
        import "/testA.dart";
        class C {A ^}''');
    await computeSuggestions();

    assertNoSuggestions();
  }

  test_FieldDeclaration_name_var() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // FieldDeclaration
    addSource('/testA.dart', 'class A { }');
    addTestSource('''
        import "/testA.dart";
        class C {var ^}''');
    await computeSuggestions();

    assertNoSuggestions();
  }

  test_FieldFormalParameter_in_non_constructor() async {
    // SimpleIdentifer  FieldFormalParameter  FormalParameterList
    addTestSource('class A {B(this.^foo) {}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 3);
    assertNoSuggestions();
  }

  test_ForEachStatement_body_typed() async {
    // Block  ForEachStatement
    addTestSource('main(args) {for (int foo in bar) {^}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('args');
    assertNotSuggested('foo');
    assertNotSuggested('Object');
  }

  test_ForEachStatement_body_untyped() async {
    // Block  ForEachStatement
    addTestSource('main(args) {for (foo in bar) {^}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('args');
    assertNotSuggested('foo');
    assertNotSuggested('Object');
  }

  test_ForEachStatement_iterable() async {
    // SimpleIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (int foo in ^) {}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('args');
    assertNotSuggested('Object');
  }

  test_ForEachStatement_loopVariable() async {
    // SimpleIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (^ in args) {}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('args');
    assertNotSuggested('String');
  }

  test_ForEachStatement_loopVariable_type() async {
    // SimpleIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (^ foo in args) {}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('args');
    assertNotSuggested('foo');
    assertNotSuggested('String');
  }

  test_ForEachStatement_loopVariable_type2() async {
    // DeclaredIdentifier  ForEachStatement  Block
    addTestSource('main(args) {for (S^ foo in args) {}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('args');
    assertNotSuggested('foo');
    assertNotSuggested('String');
  }

  test_FormalParameterList() async {
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
    assertNotSuggested('A');
    assertNotSuggested('String');
    assertNotSuggested('identical');
    assertNotSuggested('bar');
  }

  test_ForStatement_body() async {
    // Block  ForStatement
    addTestSource('main(args) {for (int i; i < 10; ++i) {^}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('i');
    assertNotSuggested('Object');
  }

  test_ForStatement_condition() async {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {for (int index = 0; i^)}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('index');
  }

  test_ForStatement_initializer() async {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {List a; for (^)}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
    assertNotSuggested('Object');
    assertNotSuggested('int');
  }

  test_ForStatement_updaters() async {
    // SimpleIdentifier  ForStatement
    addTestSource('main() {for (int index = 0; index < 10; i^)}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('index');
  }

  test_ForStatement_updaters_prefix_expression() async {
    // SimpleIdentifier  PrefixExpression  ForStatement
    addTestSource('''
void bar() { }
main() {for (int index = 0; index < 10; ++i^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('index');
    assertNotSuggested('main');
    assertNotSuggested('bar');
  }

  test_function_parameters_mixed_required_and_named() async {
    addTestSource('''
void m(x, {int y}) {}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    assertNotSuggested('m');
  }

  test_function_parameters_mixed_required_and_positional() async {
    addTestSource('''
void m(x, [int y]) {}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    assertNotSuggested('m');
  }

  test_function_parameters_named() async {
    addTestSource('''
void m({x, int y}) {}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    assertNotSuggested('m');
  }

  test_function_parameters_none() async {
    addTestSource('''
void m() {}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    assertNotSuggested('m');
  }

  test_function_parameters_positional() async {
    addTestSource('''
void m([x, int y]) {}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    assertNotSuggested('m');
  }

  test_function_parameters_required() async {
    addTestSource('''
void m(x, int y) {}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    assertNotSuggested('m');
  }

  test_FunctionDeclaration_returnType_afterComment() async {
    // ClassDeclaration  CompilationUnit
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "/testA.dart";
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
    assertNotSuggested('D2');
    assertNotSuggested('C2');
    assertNotSuggested('name');
  }

  test_FunctionDeclaration_returnType_afterComment2() async {
    // FunctionDeclaration  ClassDeclaration  CompilationUnit
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "/testA.dart";
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
    assertNotSuggested('D2');
    assertNotSuggested('C2');
    assertNotSuggested('name');
  }

  test_FunctionDeclaration_returnType_afterComment3() async {
    // FunctionDeclaration  ClassDeclaration  CompilationUnit
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "/testA.dart";
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
    assertNotSuggested('D2');
    assertNotSuggested('C2');
    assertNotSuggested('name');
  }

  test_FunctionExpression_body_function() async {
    // Block  BlockFunctionBody  FunctionExpression
    addTestSource('''
        void bar() { }
        String foo(List args) {x.then((R b) {^});}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('foo');
    assertNotSuggested('bar');
    assertNotSuggested('args');
    assertNotSuggested('b');
    assertNotSuggested('Object');
  }

  test_IfStatement() async {
    // SimpleIdentifier  IfStatement
    addTestSource('''
        class A {var b; X _c; foo() {A a; if (true) ^}}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('b');
    assertNotSuggested('_c');
    assertNotSuggested('Object');
    assertNotSuggested('A');
    assertNotSuggested('==');
  }

  test_IfStatement_condition() async {
    // SimpleIdentifier  IfStatement  Block  BlockFunctionBody
    addTestSource('''
class A {int x; int y() => 0;}
main(){var a; if (^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
    assertNotSuggested('main');
    assertNotSuggested('A');
    assertNotSuggested('Object');
  }

  test_IfStatement_empty() async {
    // SimpleIdentifier  IfStatement
    addTestSource('''
        class A {var b; X _c; foo() {A a; if (^) something}}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('b');
    assertNotSuggested('_c');
    assertNotSuggested('Object');
    assertNotSuggested('A');
    assertNotSuggested('==');
  }

  test_IfStatement_invocation() async {
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

  test_ignore_symbol_being_completed() async {
    addTestSource('class MyClass { } main(MC^) { }');
    await computeSuggestions();
    assertNotSuggested('MyClass');
    assertNotSuggested('MC');
  }

  test_ImportDirective_dart() async {
    // SimpleStringLiteral  ImportDirective
    addTestSource('''
import "dart^";
main() {}''');
    await computeSuggestions();

    assertNoSuggestions();
  }

  test_inDartDoc_reference1() async {
    addTestSource('''
/// The [^
main(aaa, bbb) {}''');
    await computeSuggestions();
    assertNotSuggested('main');
  }

  test_inDartDoc_reference2() async {
    addTestSource('''
/// The [m^
main(aaa, bbb) {}''');
    await computeSuggestions();
    assertNotSuggested('main');
  }

  test_inDartDoc_reference3() async {
    addTestSource('''
/// The [^]
main(aaa, bbb) {}''');
    await computeSuggestions();
    assertNotSuggested('main');
  }

  test_inDartDoc_reference4() async {
    addTestSource('''
/// The [m^]
main(aaa, bbb) {}''');
    await computeSuggestions();
    assertNotSuggested('main');
  }

  test_IndexExpression() async {
    // ExpressionStatement  Block
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
class A {int x;}''');
    addTestSource('''
import "/testA.dart";
int T2;
F2() { }
class B {int x;}
class C {foo(){var f; {var x;} f[^]}}''');
    await computeSuggestions();

    assertNotSuggested('x');
    assertNotSuggested('f');
    assertNotSuggested('foo');
    assertNotSuggested('C');
    assertNotSuggested('F2');
    assertNotSuggested('T2');
    assertNotSuggested('A');
    assertNotSuggested('F1');
    // TODO (danrubel) getter is being suggested instead of top level var
    //assertNotSuggested('T1');
  }

  test_IndexExpression2() async {
    // SimpleIdentifier IndexExpression ExpressionStatement  Block
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
class A {int x;}''');
    addTestSource('''
import "/testA.dart";
int T2;
F2() { }
class B {int x;}
class C {foo(){var f; {var x;} f[T^]}}''');
    await computeSuggestions();

    // top level results are partially filtered based on first char
    assertNotSuggested('T2');
    // TODO (danrubel) getter is being suggested instead of top level var
    //assertNotSuggested('T1');
  }

  test_InstanceCreationExpression() async {
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
    expect(suggestion.element.parameters, '({dynamic boo: \'hoo\', int z: 0})');
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

  test_InstanceCreationExpression_assignment_expression_filter() async {
    addTestSource('''
class A {} class B extends A {} class C implements A {} class D {}
main() {
  A a;
  a = new ^
}''');
    await computeSuggestions();

    assertSuggestConstructor('A',
        elemOffset: -1,
        relevance: DART_RELEVANCE_DEFAULT + DART_RELEVANCE_INCREMENT);
    assertSuggestConstructor('B',
        elemOffset: -1, relevance: DART_RELEVANCE_DEFAULT);
    assertSuggestConstructor('C',
        elemOffset: -1, relevance: DART_RELEVANCE_DEFAULT);
    assertNotSuggested('D');
  }

  test_InstanceCreationExpression_assignment_expression_filter2() async {
    addTestSource('''
class A {} class B extends A {} class C implements A {} class D {}
main() {
  A a;
  a = new ^;
}''');
    await computeSuggestions();

    assertSuggestConstructor('A',
        elemOffset: -1,
        relevance: DART_RELEVANCE_DEFAULT + DART_RELEVANCE_INCREMENT);
    assertSuggestConstructor('B',
        elemOffset: -1, relevance: DART_RELEVANCE_DEFAULT);
    assertSuggestConstructor('C',
        elemOffset: -1, relevance: DART_RELEVANCE_DEFAULT);
    assertNotSuggested('D');
  }

  test_InstanceCreationExpression_imported() async {
    // SimpleIdentifier  TypeName  ConstructorName  InstanceCreationExpression
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
class A {A(this.x) { } int x;}''');
    addTestSource('''
import "/testA.dart";
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

  test_InstanceCreationExpression_unimported() async {
    // SimpleIdentifier  TypeName  ConstructorName  InstanceCreationExpression
    addSource('/testAB.dart', 'class Foo { }');
    addTestSource('class C {foo(){new F^}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('Future');
    assertNotSuggested('Foo');
  }

  test_InstanceCreationExpression_variable_declaration_filter() async {
    addTestSource('''
class A {} class B extends A {} class C implements A {} class D {}
main() {
  A a = new ^
}''');
    await computeSuggestions();

    assertSuggestConstructor('A',
        elemOffset: -1,
        relevance: DART_RELEVANCE_DEFAULT + DART_RELEVANCE_INCREMENT);
    assertSuggestConstructor('B',
        elemOffset: -1, relevance: DART_RELEVANCE_DEFAULT);
    assertSuggestConstructor('C',
        elemOffset: -1, relevance: DART_RELEVANCE_DEFAULT);
    assertNotSuggested('D');
  }

  test_InstanceCreationExpression_variable_declaration_filter2() async {
    addTestSource('''
class A {} class B extends A {} class C implements A {} class D {}
main() {
  A a = new ^;
}''');
    await computeSuggestions();

    assertSuggestConstructor('A',
        elemOffset: -1,
        relevance: DART_RELEVANCE_DEFAULT + DART_RELEVANCE_INCREMENT);
    assertSuggestConstructor('B',
        elemOffset: -1, relevance: DART_RELEVANCE_DEFAULT);
    assertSuggestConstructor('C',
        elemOffset: -1, relevance: DART_RELEVANCE_DEFAULT);
    assertNotSuggested('D');
  }

  test_InterpolationExpression() async {
    // SimpleIdentifier  InterpolationExpression  StringInterpolation
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "/testA.dart";
int T2;
F2() { }
typedef D2();
class C2 { }
main() {String name; print("hello \$^");}''');
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
    assertNotSuggested('D2');
    assertNotSuggested('C2');
    assertNotSuggested('name');
  }

  test_InterpolationExpression_block() async {
    // SimpleIdentifier  InterpolationExpression  StringInterpolation
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "/testA.dart";
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
    assertNotSuggested('T2');
    assertNotSuggested('F2');
    assertNotSuggested('D2');
    assertNotSuggested('C2');
    assertNotSuggested('name');
  }

  test_InterpolationExpression_block2() async {
    // SimpleIdentifier  InterpolationExpression  StringInterpolation
    addTestSource('main() {String name; print("hello \${n^}");}');
    await computeSuggestions();

    assertNotSuggested('name');
    // top level results are partially filtered
    //assertNotSuggested('Object');
  }

  test_InterpolationExpression_prefix_selector() async {
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

  test_InterpolationExpression_prefix_selector2() async {
    // SimpleIdentifier  PrefixedIdentifier  InterpolationExpression
    addTestSource('main() {String name; print("hello \$name.^");}');
    await computeSuggestions();

    assertNoSuggestions();
  }

  test_InterpolationExpression_prefix_target() async {
    // SimpleIdentifier  PrefixedIdentifier  InterpolationExpression
    addTestSource('main() {String name; print("hello \${nam^e.length}");}');
    await computeSuggestions();

    assertNotSuggested('name');
    // top level results are partially filtered
    //assertNotSuggested('Object');
    assertNotSuggested('length');
  }

  test_IsExpression() async {
    // SimpleIdentifier  TypeName  IsExpression  IfStatement
    addSource(
        '/testB.dart',
        '''
lib B;
foo() { }
class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
import "/testB.dart";
class Y {Y.c(); Y._d(); z() {}}
main() {var x; if (x is ^) { }}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('X');
    assertNotSuggested('Y');
    assertNotSuggested('x');
    assertNotSuggested('main');
    assertNotSuggested('foo');
  }

  test_IsExpression_target() async {
    // IfStatement  Block  BlockFunctionBody
    addTestSource('''
foo() { }
void bar() { }
class A {int x; int y() => 0;}
main(){var a; if (^ is A)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
    assertNotSuggested('main');
    assertNotSuggested('foo');
    assertNotSuggested('bar');
    assertNotSuggested('A');
    assertNotSuggested('Object');
  }

  test_IsExpression_type() async {
    // SimpleIdentifier  TypeName  IsExpression  IfStatement
    addTestSource('''
class A {int x; int y() => 0;}
main(){var a; if (a is ^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
    assertNotSuggested('main');
    assertNotSuggested('A');
    assertNotSuggested('Object');
  }

  test_IsExpression_type_partial() async {
    // SimpleIdentifier  TypeName  IsExpression  IfStatement
    addTestSource('''
class A {int x; int y() => 0;}
main(){var a; if (a is Obj^)}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 3);
    expect(replacementLength, 3);
    assertNotSuggested('a');
    assertNotSuggested('main');
    assertNotSuggested('A');
    assertNotSuggested('Object');
  }

  test_keyword() async {
    addSource(
        '/testB.dart',
        '''
lib B;
int newT1;
int T1;
nowIsIt() { }
class X {factory X.c(); factory X._d(); z() {}}''');
    addTestSource('''
import "/testB.dart";
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
    assertNotSuggested('m');
    assertNotSuggested('newer');
  }

  test_Literal_list() async {
    // ']'  ListLiteral  ArgumentList  MethodInvocation
    addTestSource('main() {var Some; print([^]);}');
    await computeSuggestions();

    assertNotSuggested('Some');
    assertNotSuggested('String');
  }

  test_Literal_list2() async {
    // SimpleIdentifier ListLiteral  ArgumentList  MethodInvocation
    addTestSource('main() {var Some; print([S^]);}');
    await computeSuggestions();

    assertNotSuggested('Some');
    assertNotSuggested('String');
  }

  test_Literal_string() async {
    // SimpleStringLiteral  ExpressionStatement  Block
    addTestSource('class A {a() {"hel^lo"}}');
    await computeSuggestions();

    assertNoSuggestions();
  }

  test_localVariableDeclarationName() async {
    addTestSource('main() {String m^}');
    await computeSuggestions();

    assertNotSuggested('main');
    assertNotSuggested('min');
  }

  test_MapLiteralEntry() async {
    // MapLiteralEntry  MapLiteral  VariableDeclaration
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "/testA.dart";
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
    assertNotSuggested('T2');
    assertNotSuggested('F2');
    assertNotSuggested('D2');
    assertNotSuggested('C2');
  }

  test_MapLiteralEntry1() async {
    // MapLiteralEntry  MapLiteral  VariableDeclaration
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "/testA.dart";
int T2;
F2() { }
typedef D2();
class C2 { }
foo = {T^''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('T1');
    assertNotSuggested('T2');
  }

  test_MapLiteralEntry2() async {
    // SimpleIdentifier  MapLiteralEntry  MapLiteral  VariableDeclaration
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "/testA.dart";
int T2;
F2() { }
typedef D2();
class C2 { }
foo = {7:T^};''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('T1');
    assertNotSuggested('T2');
  }

  test_method_parameters_mixed_required_and_named() async {
    addTestSource('''
class A {
  void m(x, {int y}) {}
}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    assertNotSuggested('m');
  }

  test_method_parameters_mixed_required_and_positional() async {
    addTestSource('''
class A {
  void m(x, [int y]) {}
}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    assertNotSuggested('m');
  }

  test_method_parameters_named() async {
    addTestSource('''
class A {
  void m({x, int y}) {}
}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    assertNotSuggested('m');
  }

  test_method_parameters_none() async {
    addTestSource('''
class A {
  void m() {}
}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    assertNotSuggested('m');
  }

  test_method_parameters_positional() async {
    addTestSource('''
class A {
  void m([x, int y]) {}
}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    assertNotSuggested('m');
  }

  test_method_parameters_required() async {
    addTestSource('''
class A {
  void m(x, int y) {}
}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    assertNotSuggested('m');
  }

  test_MethodDeclaration_body_getters() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class A {@deprecated X get f => 0; Z a() {^} get _g => 1;}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
    assertNotSuggested('f');
    assertNotSuggested('_g');
  }

  test_MethodDeclaration_body_static() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addSource(
        '/testC.dart',
        '''
class C {
  c1() {}
  var c2;
  static c3() {}
  static var c4;}''');
    addTestSource('''
import "/testC.dart";
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
    assertNotSuggested('a3');
    assertNotSuggested('a4');
    assertNotSuggested('b1');
    assertNotSuggested('b2');
    assertNotSuggested('b3');
    assertNotSuggested('b4');
    assertNotSuggested('c1');
    assertNotSuggested('c2');
    assertNotSuggested('c3');
    assertNotSuggested('c4');
  }

  test_MethodDeclaration_members() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class A {@deprecated X f; Z _a() {^} var _g;}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);

    assertNotSuggested('_a');
    assertNotSuggested('f');
    assertNotSuggested('_g');
    assertNotSuggested('bool');
  }

  test_MethodDeclaration_parameters_named() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class A {@deprecated Z a(X x, _, b, {y: boo}) {^}}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
    assertNotSuggested('x');
    assertNotSuggested('y');
    assertNotSuggested('b');
    assertNotSuggested('int');
    assertNotSuggested('_');
  }

  test_MethodDeclaration_parameters_positional() async {
    // Block  BlockFunctionBody  MethodDeclaration
    addTestSource('''
foo() { }
void bar() { }
class A {Z a(X x, [int y=1]) {^}}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('foo');
    assertNotSuggested('bar');
    assertNotSuggested('a');
    assertNotSuggested('x');
    assertNotSuggested('y');
    assertNotSuggested('String');
  }

  test_MethodDeclaration_returnType() async {
    // ClassDeclaration  CompilationUnit
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "/testA.dart";
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
    assertNotSuggested('D2');
    assertNotSuggested('C2');
    assertNotSuggested('name');
  }

  test_MethodDeclaration_returnType_afterComment() async {
    // ClassDeclaration  CompilationUnit
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "/testA.dart";
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
    assertNotSuggested('D2');
    assertNotSuggested('C2');
    assertNotSuggested('name');
  }

  test_MethodDeclaration_returnType_afterComment2() async {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "/testA.dart";
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
    assertNotSuggested('D2');
    assertNotSuggested('C2');
    assertNotSuggested('name');
  }

  test_MethodDeclaration_returnType_afterComment3() async {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    addSource(
        '/testA.dart',
        '''
int T1;
F1() { }
typedef D1();
class C1 {C1(this.x) { } int x;}''');
    addTestSource('''
import "/testA.dart";
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
    assertNotSuggested('D2');
    assertNotSuggested('C2');
    assertNotSuggested('name');
  }

  test_MethodInvocation_no_semicolon() async {
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

  test_missing_params_constructor() async {
    addTestSource('class C1{C1{} main(){C^}}');
    await computeSuggestions();
  }

  test_missing_params_function() async {
    addTestSource('int f1{} main(){f^}');
    await computeSuggestions();
  }

  test_missing_params_method() async {
    addTestSource('class C1{int f1{} main(){f^}}');
    await computeSuggestions();
  }

  test_new_instance() async {
    addTestSource('import "dart:math"; class A {x() {new Random().^}}');
    await computeSuggestions();

    assertNotSuggested('nextBool');
    assertNotSuggested('nextDouble');
    assertNotSuggested('nextInt');
    assertNotSuggested('Random');
    assertNotSuggested('Object');
    assertNotSuggested('A');
  }

  test_overrides() async {
    addTestSource('''
class A {m() {}}
class B extends A {m() {^}}
''');
    await computeSuggestions();
    assertNotSuggested('m');
  }

  test_parameterName_excludeTypes() async {
    addTestSource('m(int ^) {}');
    await computeSuggestions();

    assertNotSuggested('int');
    assertNotSuggested('bool');
  }

  test_partFile_TypeName() async {
    // SimpleIdentifier  TypeName  ConstructorName
    addSource(
        '/testB.dart',
        '''
lib B;
int T1;
F1() { }
class X {X.c(); X._d(); z() {}}''');
    addSource(
        '/testA.dart',
        '''
library libA;
import "/testB.dart";
part "$testFile";
class A { }
var m;''');
    addTestSource('''
part of libA;
class B { factory B.bar(int x) => null; }
main() {new ^}''');
    await computeLibrariesContaining();
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestConstructor('B.bar');
    assertNotSuggested('Object');
    assertNotSuggested('X.c');
    assertNotSuggested('X._d');
    assertNotSuggested('A');
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('_d');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }

  test_partFile_TypeName2() async {
    // SimpleIdentifier  TypeName  ConstructorName
    addSource(
        '/testB.dart',
        '''
lib B;
int T1;
F1() { }
class X {X.c(); X._d(); z() {}}''');
    addSource(
        '/testA.dart',
        '''
part of libA;
class B { }''');
    addTestSource('''
library libA;
import "/testB.dart";
part "/testA.dart";
class A { A({String boo: 'hoo'}) { } }
main() {new ^}
var m;''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestConstructor('A');
    assertNotSuggested('Object');
    assertNotSuggested('X.c');
    assertNotSuggested('X._d');
    assertNotSuggested('B');
    assertNotSuggested('F1');
    assertNotSuggested('T1');
    assertNotSuggested('_d');
    assertNotSuggested('z');
    assertNotSuggested('m');
  }

  test_PrefixedIdentifier_class_const() async {
    // SimpleIdentifier PrefixedIdentifier ExpressionStatement Block
    addSource(
        '/testB.dart',
        '''
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
import "/testB.dart";
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

  test_PrefixedIdentifier_class_imported() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource(
        '/testB.dart',
        '''
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
import "/testB.dart";
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

  test_PrefixedIdentifier_class_local() async {
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

  test_PrefixedIdentifier_getter() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('String get g => "one"; f() {g.^}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  test_PrefixedIdentifier_library() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource(
        '/testB.dart',
        '''
lib B;
var T1;
class X { }
class Y { }''');
    addTestSource('''
import "/testB.dart" as b;
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

  test_PrefixedIdentifier_library_typesOnly() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName
    addSource(
        '/testB.dart',
        '''
lib B;
var T1;
class X { }
class Y { }''');
    addTestSource('''
import "/testB.dart" as b;
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

  test_PrefixedIdentifier_library_typesOnly2() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName
    addSource(
        '/testB.dart',
        '''
lib B;
var T1;
class X { }
class Y { }''');
    addTestSource('''
import "/testB.dart" as b;
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

  test_PrefixedIdentifier_parameter() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource(
        '/testB.dart',
        '''
lib B;
class _W {M y; var _z;}
class X extends _W {}
class M{}''');
    addTestSource('''
import "/testB.dart";
foo(X x) {x.^}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('y');
    assertNotSuggested('_z');
    assertNotSuggested('==');
  }

  test_PrefixedIdentifier_prefix() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addSource(
        '/testA.dart',
        '''
class A {static int bar = 10;}
_B() {}''');
    addTestSource('''
import "/testA.dart";
class X {foo(){A^.bar}}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('A');
    assertNotSuggested('X');
    assertNotSuggested('foo');
    assertNotSuggested('bar');
    assertNotSuggested('_B');
  }

  test_PrefixedIdentifier_propertyAccess() async {
    // PrefixedIdentifier  ExpressionStatement  Block  BlockFunctionBody
    addTestSource('class A {String x; int get foo {x.^}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('isEmpty');
    assertNotSuggested('compareTo');
  }

  test_PrefixedIdentifier_propertyAccess_newStmt() async {
    // PrefixedIdentifier  ExpressionStatement  Block  BlockFunctionBody
    addTestSource('class A {String x; int get foo {x.^ int y = 0;}');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('isEmpty');
    assertNotSuggested('compareTo');
  }

  test_PrefixedIdentifier_trailingStmt_const() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('const String g = "hello"; f() {g.^ int y = 0;}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  test_PrefixedIdentifier_trailingStmt_field() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('class A {String g; f() {g.^ int y = 0;}}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  test_PrefixedIdentifier_trailingStmt_function() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('String g() => "one"; f() {g.^ int y = 0;}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  test_PrefixedIdentifier_trailingStmt_functionTypeAlias() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('typedef String g(); f() {g.^ int y = 0;}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  test_PrefixedIdentifier_trailingStmt_getter() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('String get g => "one"; f() {g.^ int y = 0;}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  test_PrefixedIdentifier_trailingStmt_local_typed() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('f() {String g; g.^ int y = 0;}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  test_PrefixedIdentifier_trailingStmt_local_untyped() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('f() {var g = "hello"; g.^ int y = 0;}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  test_PrefixedIdentifier_trailingStmt_method() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('class A {String g() {}; f() {g.^ int y = 0;}}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  test_PrefixedIdentifier_trailingStmt_param() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('class A {f(String g) {g.^ int y = 0;}}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  test_PrefixedIdentifier_trailingStmt_param2() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('f(String g) {g.^ int y = 0;}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  test_PrefixedIdentifier_trailingStmt_topLevelVar() async {
    // SimpleIdentifier  PrefixedIdentifier  ExpressionStatement
    addTestSource('String g; f() {g.^ int y = 0;}');
    await computeSuggestions();

    assertNotSuggested('length');
  }

  test_prioritization() async {
    addTestSource('main() {var ab; var _ab; ^}');
    await computeSuggestions();
    assertNotSuggested('ab');
    assertNotSuggested('_ab');
  }

  test_prioritization_private() async {
    addTestSource('main() {var ab; var _ab; _^}');
    await computeSuggestions();
    assertNotSuggested('ab');
    assertNotSuggested('_ab');
  }

  test_prioritization_public() async {
    addTestSource('main() {var ab; var _ab; a^}');
    await computeSuggestions();
    assertNotSuggested('ab');
    assertNotSuggested('_ab');
  }

  test_PropertyAccess_expression() async {
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

  test_PropertyAccess_noTarget() async {
    // SimpleIdentifier  PropertyAccess  ExpressionStatement
    addSource('/testAB.dart', 'class Foo { }');
    addTestSource('class C {foo(){.^}}');
    await computeSuggestions();

    assertNoSuggestions();
  }

  test_PropertyAccess_noTarget2() async {
    // SimpleIdentifier  PropertyAccess  ExpressionStatement
    addSource('/testAB.dart', 'class Foo { }');
    addTestSource('main() {.^}');
    await computeSuggestions();

    assertNoSuggestions();
  }

  test_PropertyAccess_selector() async {
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

  test_shadowed_name() async {
    addTestSource('var a; class A { var a; m() { ^ } }');
    await computeSuggestions();
    assertNotSuggested('a');
  }

  test_SwitchStatement_c() async {
    // SwitchStatement  Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class A {String g(int x) {switch(x) {c^}}}');
    await computeSuggestions();

    assertNoSuggestions();
  }

  test_SwitchStatement_case() async {
    // SwitchStatement  Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class A {String g(int x) {var t; switch(x) {case 0: ^}}}');
    await computeSuggestions();

    assertNotSuggested('A');
    assertNotSuggested('g');
    assertNotSuggested('t');
    assertNotSuggested('String');
  }

  test_SwitchStatement_empty() async {
    // SwitchStatement  Block  BlockFunctionBody  MethodDeclaration
    addTestSource('class A {String g(int x) {switch(x) {^}}}');
    await computeSuggestions();

    assertNoSuggestions();
  }

  test_ThisExpression_block() async {
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

  test_ThisExpression_constructor() async {
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

  test_ThisExpression_constructor_param() async {
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
    // Contributed by FieldFormalConstructorContributor
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

  test_ThisExpression_constructor_param2() async {
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
    // Contributed by FieldFormalConstructorContributor
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

  test_ThisExpression_constructor_param3() async {
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
    // Contributed by FieldFormalConstructorContributor
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

  test_ThisExpression_constructor_param4() async {
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
    // Contributed by FieldFormalConstructorContributor
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

  test_TopLevelVariableDeclaration_typed_name() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // TopLevelVariableDeclaration
    addTestSource('class A {} B ^');
    await computeSuggestions();

    assertNoSuggestions();
  }

  test_TopLevelVariableDeclaration_untyped_name() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // TopLevelVariableDeclaration
    addTestSource('class A {} var ^');
    await computeSuggestions();

    assertNoSuggestions();
  }

  test_TypeArgumentList() async {
    // SimpleIdentifier  BinaryExpression  ExpressionStatement
    addSource(
        '/testA.dart',
        '''
class C1 {int x;}
F1() => 0;
typedef String T1(int blat);''');
    addTestSource('''
import "/testA.dart";'
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
    assertNotSuggested('C2');
    assertNotSuggested('T2');
    assertNotSuggested('F1');
    assertNotSuggested('F2');
  }

  test_TypeArgumentList2() async {
    // TypeName  TypeArgumentList  TypeName
    addSource(
        '/testA.dart',
        '''
class C1 {int x;}
F1() => 0;
typedef String T1(int blat);''');
    addTestSource('''
import "/testA.dart";'
class C2 {int x;}
F2() => 0;
typedef int T2(int blat);
class C<E> {}
main() { C<C^> c; }''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('C1');
    assertNotSuggested('C2');
  }

  test_VariableDeclaration_name() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement  Block
    addSource(
        '/testB.dart',
        '''
lib B;
foo() { }
class _B { }
class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
import "/testB.dart";
class Y {Y.c(); Y._d(); z() {}}
main() {var ^}''');
    await computeSuggestions();

    assertNoSuggestions();
  }

  test_VariableDeclarationList_final() async {
    // VariableDeclarationList  VariableDeclarationStatement  Block
    addTestSource('main() {final ^} class C { }');
    await computeSuggestions();

    assertNotSuggested('Object');
    assertNotSuggested('C');
    assertNotSuggested('==');
  }

  test_VariableDeclarationStatement_RHS() async {
    // SimpleIdentifier  VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement
    addSource(
        '/testB.dart',
        '''
lib B;
foo() { }
class _B { }
class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
import "/testB.dart";
class Y {Y.c(); Y._d(); z() {}}
class C {bar(){var f; {var x;} var e = ^}}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('X');
    assertNotSuggested('_B');
    assertNotSuggested('Y');
    assertNotSuggested('C');
    assertNotSuggested('f');
    assertNotSuggested('x');
    assertNotSuggested('e');
  }

  test_VariableDeclarationStatement_RHS_missing_semicolon() async {
    // VariableDeclaration  VariableDeclarationList
    // VariableDeclarationStatement
    addSource(
        '/testB.dart',
        '''
lib B;
foo1() { }
void bar1() { }
class _B { }
class X {X.c(); X._d(); z() {}}''');
    addTestSource('''
import "/testB.dart";
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
    assertNotSuggested('foo2');
    assertNotSuggested('bar2');
    assertNotSuggested('_B');
    assertNotSuggested('Y');
    assertNotSuggested('C');
    assertNotSuggested('f');
    assertNotSuggested('x');
    assertNotSuggested('e');
  }
}

@reflectiveTest
class LocalConstructorContributorTest_Driver
    extends LocalConstructorContributorTest {
  @override
  bool get enableNewAnalysisDriver => true;

  /// Sanity check.  Permutations tested in local_ref_contributor.
  test_ArgDefaults_cons_with_required_named() async {
    addMetaPackageSource();
    addTestSource('''
import 'package:meta/meta.dart';

class A {
  A(int bar, {bool boo, @required int baz});
  baz() {
    new A^
  }
}''');
    await computeSuggestions();

    assertSuggestConstructor('A', defaultArgListString: 'bar, baz: null');
  }
}
