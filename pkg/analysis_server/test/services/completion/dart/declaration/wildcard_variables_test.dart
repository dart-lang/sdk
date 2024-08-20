// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WildcardCatchClauseTest);
    defineReflectiveTests(WildcardFieldTest);
    defineReflectiveTests(WildcardForLoopTest);
    defineReflectiveTests(WildcardImportPrefixTest);
    defineReflectiveTests(WildcardLocalVariableTest);
    defineReflectiveTests(WildcardParameterTest);
    defineReflectiveTests(WildcardTopLevelVariableTest);
    defineReflectiveTests(WildcardTypeParameterTest);
  });
}

class AbstractWildCardTest extends AbstractCompletionDriverTest {
  @override
  Set<String> allowedIdentifiers = {'_', '__', '___', 'T'};

  @override
  bool get includeKeywords => false;
}

@reflectiveTest
class WildcardCatchClauseTest extends AbstractWildCardTest {
  Future<void> test_argumentList() async {
    await computeSuggestions('''
void p(Object o) {}

void f() {
  try {
  } catch(_, _) {
    p(^);
  }
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_argumentList_underscores() async {
    await computeSuggestions('''
void p(Object o) {}

void f() {
  try {
  } catch(__, ___) {
    p(^);
  }
}
''');
    assertResponse(r'''
suggestions
  __
    kind: localVariable
  ___
    kind: localVariable
''');
  }
}

/// Fields are binding so not technically wildcards but look just like them.
@reflectiveTest
class WildcardFieldTest extends AbstractWildCardTest {
  Future<void> test_argumentList() async {
    await computeSuggestions('''
void p(Object o) {}

class C {
  int _ = 0;
  void f() {
    p(^);
  }
''');
    assertResponse(r'''
suggestions
  _
    kind: field
''');
  }

  Future<void> test_argumentList_withLocal() async {
    await computeSuggestions('''
void p(Object o) {}

class C {
  int _ = 0;
  void f() {
    var _ = 0;
    p(^);
  }
''');
    assertResponse(r'''
suggestions
  _
    kind: field
''');
  }
}

@reflectiveTest
class WildcardForLoopTest extends AbstractWildCardTest {
  Future<void> test_forEach_argumentList() async {
    await computeSuggestions('''
void p(Object o) {}

void f() {
  for (var _ in []) {
    p(^);
  }
}
''');
    assertResponse('''
suggestions
''');
  }

  Future<void> test_forEach_argumentList_underscores() async {
    await computeSuggestions('''
void p(Object o) {}

void f() {
  for (var __ in []) {
    p(^);
  }
}
''');
    assertResponse('''
suggestions
  __
    kind: localVariable
''');
  }

  Future<void> test_forParts_argumentList() async {
    await computeSuggestions('''
void p(Object o) {}

void f() {
  for (var _ = 0; ;) {
    p(^);
  }
}
''');
    assertResponse('''
suggestions
''');
  }

  Future<void> test_forParts_argumentList_underscores() async {
    await computeSuggestions('''
void p(Object o) {}

void f() {
  for (var __ = 0; ;) {
    p(^);
  }
}
''');
    assertResponse('''
suggestions
  __
    kind: localVariable
''');
  }
}

@reflectiveTest
class WildcardImportPrefixTest extends AbstractWildCardTest {
  @override
  Future<void> setUp() async {
    await super.setUp();
    allowedIdentifiers.add('isBlank');
  }

  Future<void> test_argumentList() async {
    newFile('$testPackageLibPath/ext.dart', '''
extension ES on String {
  bool get isBlank => false;
}
''');

    await computeSuggestions('''
import 'ext.dart' as _;

void p(Object o) {}

void f() {
  p(^);
}
''');
    // `_` should not appear.
    assertResponse('''
suggestions
''');
  }

  Future<void> test_argumentList_underscores() async {
    newFile('$testPackageLibPath/ext.dart', '''
extension ES on String {
  bool get isBlank => false;
}
''');

    await computeSuggestions('''
import 'ext.dart' as __;

void p(Object o) {}

void f() {
  p(^);
}
''');
    assertResponse('''
suggestions
  __.ES
    kind: extensionInvocation
  __
    kind: library
''');
  }

  Future<void> test_stringExtension_argumentList() async {
    newFile('$testPackageLibPath/ext.dart', '''
extension ES on String {
  bool get isBlank => false;
}
''');

    await computeSuggestions('''
import 'ext.dart' as _;

void p(Object o) {}

void f() {
  p(''.^);
}
''');
    assertResponse('''
suggestions
  isBlank
    kind: getter
''');
  }
}

@reflectiveTest
class WildcardLocalVariableTest extends AbstractWildCardTest {
  Future<void> test_argumentList() async {
    await computeSuggestions('''
void p(Object o) {}

void f() {
  var _, b0 = 0;
  p(^);
}
''');
    assertResponse(r'''
suggestions
  b0
    kind: localVariable
''');
  }

  Future<void> test_argumentList_function() async {
    await computeSuggestions('''
void p(Object o) {}

void f() {
  _() {}
  p(^);
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_argumentList_underscores() async {
    await computeSuggestions('''
void p(Object o) {}

void f() {
  var __ = 0;
  p(^);
}
''');
    assertResponse(r'''
suggestions
  __
    kind: localVariable
''');
  }
}

@reflectiveTest
class WildcardParameterTest extends AbstractWildCardTest {
  Future<void> test_argumentList() async {
    await computeSuggestions('''
void p(Object o) {}

void f(int _, int b0) {
  p(^);
}
''');
    assertResponse('''
suggestions
  b0
    kind: parameter
''');
  }

  Future<void> test_argumentList_underscores() async {
    await computeSuggestions('''
void p(Object o) {}

void f(int __) {
  p(^);
}
''');
    assertResponse('''
suggestions
  __
    kind: parameter
''');
  }
}

/// Top level variables are binding so not technically wildcards but look just
/// like them.
@reflectiveTest
class WildcardTopLevelVariableTest extends AbstractWildCardTest {
  Future<void> test_argumentList() async {
    await computeSuggestions('''
int _ = 0;

void p(Object o) {}

void f() {
  p(^);
}
''');
    assertResponse(r'''
suggestions
  _
    kind: topLevelVariable
''');
  }
}

@reflectiveTest
class WildcardTypeParameterTest extends AbstractWildCardTest {
  Future<void> test_constructor_formalParameterList() async {
    await computeSuggestions('''
class C<T, _> {
  C(^);
}
''');
    assertResponse('''
suggestions
  T
    kind: typeParameter
''');
  }

  Future<void> test_extensionMethod_formalParameterList() async {
    await computeSuggestions('''
extension E<_, T> on List {
  void f(^) {}
}
''');
    assertResponse('''
suggestions
  T
    kind: typeParameter
''');
  }

  Future<void> test_extensionType__representationDeclaration() async {
    await computeSuggestions('''
extension type ET<_, T, _ extends num>(^) {}
''');
    assertResponse('''
suggestions
  T
    kind: typeParameter
''');
  }

  Future<void> test_extensionType_method_formalParameterList() async {
    await computeSuggestions('''
extension type ET<_, T, _ extends num>(num n) {
  f(^) {}
}
''');
    assertResponse('''
suggestions
  T
    kind: typeParameter
''');
  }

  Future<void> test_function_formalParameterList() async {
    await computeSuggestions('''
f<T,_>(^) {}
''');
    assertResponse('''
suggestions
  T
    kind: typeParameter
''');
  }

  Future<void> test_method_formalParameterList() async {
    await computeSuggestions('''
class C<T, _> {
  void m(^);
}
''');
    assertResponse('''
suggestions
  T
    kind: typeParameter
''');
  }
}
