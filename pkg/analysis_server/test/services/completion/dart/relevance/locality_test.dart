// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../completion_printer.dart';
import 'completion_relevance.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalityTest);
  });
}

@reflectiveTest
class LocalityTest extends CompletionRelevanceTest {
  @override
  Future<void> setUp() async {
    await super.setUp();

    printerConfiguration
      ..sorting = Sorting.relevanceThenCompletionThenKind
      ..withRelevance = true;
  }

  Future<void> test_catchClause() async {
    await computeSuggestions('''
void f(int v01) {
  var v02 = 0;
  try {} catch (v03, v04) {
    v0^
  }
}
''');

    assertResponse(r'''
replacement
  left: 2
suggestions
  v03
    kind: localVariable
    relevance: 575
  v04
    kind: localVariable
    relevance: 569
  v02
    kind: localVariable
    relevance: 564
  v01
    kind: parameter
    relevance: 546
''');
  }

  Future<void> test_forElement_forEachWithDeclaration() async {
    await computeSuggestions('''
void f(int v01) {
  [for (var v02 in [0]) v0^];
}
''');

    assertResponse(r'''
replacement
  left: 2
suggestions
  v02
    kind: localVariable
    relevance: 572
  v01
    kind: parameter
    relevance: 556
''');
  }

  Future<void> test_forElement_forEachWithPattern() async {
    await computeSuggestions('''
void f(int v01) {
  [for (var (v02, v03) in [(0, 1)]) v0^];
}
''');

    assertResponse(r'''
replacement
  left: 2
suggestions
  v02
    kind: localVariable
    relevance: 572
  v03
    kind: localVariable
    relevance: 566
  v01
    kind: parameter
    relevance: 551
''');
  }

  Future<void> test_formalParameter_higherThan_importedClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
class v01 {}
''');

    await computeSuggestions('''
import 'a.dart';

void f(int v02) {
  v0^
}
''');

    // `v02` is much closer to the body, so has higher relevance.
    assertResponse(r'''
replacement
  left: 2
suggestions
  v02
    kind: parameter
    relevance: 561
  v01
    kind: class
    relevance: 522
  v01
    kind: constructorInvocation
    relevance: 500
''');
  }

  Future<void> test_formalParameter_higherThan_importedFunction() async {
    newFile('$testPackageLibPath/a.dart', r'''
void v01() {}
''');

    await computeSuggestions('''
import 'a.dart';

void f(int v02) {
  v0^
}
''');

    // `v02` is much closer to the body, so has higher relevance.
    assertResponse(r'''
replacement
  left: 2
suggestions
  v02
    kind: parameter
    relevance: 561
  v01
    kind: functionInvocation
    relevance: 513
''');
  }

  Future<void> test_formalParameter_higherThan_unitFunction() async {
    await computeSuggestions('''
void v01() {}

void f(int v02) {
  v0^
}
''');

    // `v02` is much closer to the body, so has higher relevance.
    assertResponse(r'''
replacement
  left: 2
suggestions
  v02
    kind: parameter
    relevance: 561
  v01
    kind: functionInvocation
    relevance: 513
''');
  }

  Future<void> test_formalParameters_constructor() async {
    await computeSuggestions('''
class A {
  A(int v01, int v02) {
    v0^
  }
}
''');

    // The formal parameters are suggested in forward order.
    assertResponse(r'''
replacement
  left: 2
suggestions
  v01
    kind: parameter
    relevance: 561
  v02
    kind: parameter
    relevance: 555
''');
  }

  Future<void> test_formalParameters_function() async {
    await computeSuggestions('''
void f(int v01, int v02) {
  v0^
}
''');

    // The formal parameters are suggested in forward order.
    assertResponse(r'''
replacement
  left: 2
suggestions
  v01
    kind: parameter
    relevance: 561
  v02
    kind: parameter
    relevance: 555
''');
  }

  Future<void> test_formalParameters_function_local() async {
    await computeSuggestions('''
void f(int v01) {
  var v02 = 0;
  void f2(int v03, int v04) {
    v0^
  }
}
''');

    // TODO(scheglov): why `v02` is higher?
    assertResponse(r'''
replacement
  left: 2
suggestions
  v02
    kind: localVariable
    relevance: 564
  v03
    kind: parameter
    relevance: 561
  v04
    kind: parameter
    relevance: 555
  v01
    kind: parameter
    relevance: 546
''');
  }

  Future<void> test_formalParameters_method() async {
    await computeSuggestions('''
class A {
  void f(int v01, int v02) {
    v0^
  }
}
''');

    // The formal parameters are suggested in forward order.
    assertResponse(r'''
replacement
  left: 2
suggestions
  v01
    kind: parameter
    relevance: 561
  v02
    kind: parameter
    relevance: 555
''');
  }

  Future<void> test_forStatement_forEachWithDeclaration() async {
    await computeSuggestions('''
void f(int v01) {
  for (var v02 in [0]) {
    v0^
  }
}
''');

    assertResponse(r'''
replacement
  left: 2
suggestions
  v02
    kind: localVariable
    relevance: 575
  v01
    kind: parameter
    relevance: 555
''');
  }

  Future<void> test_forStatement_forEachWithPattern() async {
    await computeSuggestions('''
void f(int v01) {
  for (var (v02, v03) in [(0, 1)]) {
    v0^
  }
}
''');

    assertResponse(r'''
replacement
  left: 2
suggestions
  v02
    kind: localVariable
    relevance: 575
  v03
    kind: localVariable
    relevance: 569
  v01
    kind: parameter
    relevance: 550
''');
  }

  Future<void> test_forStatement_forLoopWithDeclarations() async {
    await computeSuggestions('''
void f(int v01) {
  for (var v02 = 0, v03 = 0;;) {
    v0^
  }
}
''');

    assertResponse(r'''
replacement
  left: 2
suggestions
  v02
    kind: localVariable
    relevance: 575
  v03
    kind: localVariable
    relevance: 569
  v01
    kind: parameter
    relevance: 550
''');
  }

  Future<void> test_ifCase() async {
    await computeSuggestions('''
void f(int v01) {
  if (0 case int v02) {
    v0^
  }
}
''');

    assertResponse(r'''
replacement
  left: 2
suggestions
  v02
    kind: localVariable
    relevance: 575
  v01
    kind: parameter
    relevance: 555
''');
  }

  Future<void> test_localVariable_higherThan_formalParameter() async {
    await computeSuggestions('''
void f(int v01) {
  final v02 = 0;
  v0^
}
''');

    // `v02`, as a local variable is closer to the completion location.
    // So, it has higher relevance than the formal parameter `v01`.
    assertResponse(r'''
replacement
  left: 2
suggestions
  v02
    kind: localVariable
    relevance: 575
  v01
    kind: parameter
    relevance: 555
''');
  }

  Future<void> test_localVariable_higherThan_importedClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
class v01 {}
''');

    await computeSuggestions('''
import 'a.dart';

void f() {
  final v02 = 0;
  v0^
}
''');

    // The local variable `v02` is much closer that the imported
    // class `v01` to the body, so has higher relevance.
    assertResponse(r'''
replacement
  left: 2
suggestions
  v02
    kind: localVariable
    relevance: 575
  v01
    kind: class
    relevance: 522
  v01
    kind: constructorInvocation
    relevance: 500
''');
  }

  Future<void> test_localVariable_higherThan_importedFunction() async {
    newFile('$testPackageLibPath/a.dart', r'''
void v01() {}
''');

    await computeSuggestions('''
import 'a.dart';

void f() {
  final v02 = 0;
  v0^
}
''');

    // The local variable `v02` is much closer that the imported
    // function `v01` to the body, so has higher relevance.
    assertResponse(r'''
replacement
  left: 2
suggestions
  v02
    kind: localVariable
    relevance: 575
  v01
    kind: functionInvocation
    relevance: 513
''');
  }

  Future<void> test_localVariables() async {
    await computeSuggestions('''
void f() {
  var v00 = 0;
  var v01 = 1;
  var v02 = 2;
  var v = v0^;
}
''');

    // Local variables `v00`, `v01`, and `v02` has the same properties.
    // But they have different distance from the completion location.
    // We suggest "closest" first.
    assertResponse(r'''
replacement
  left: 2
suggestions
  v02
    kind: localVariable
    relevance: 593
  v01
    kind: localVariable
    relevance: 587
  v00
    kind: localVariable
    relevance: 582
''');
  }

  Future<void> test_switchPatternCase() async {
    await computeSuggestions('''
void f(Object v01) {
  switch (v01) {
    case int v02:
      v0^
  }
}
''');

    assertResponse(r'''
replacement
  left: 2
suggestions
  v02
    kind: localVariable
    relevance: 576
  v01
    kind: parameter
    relevance: 551
''');
  }
}
