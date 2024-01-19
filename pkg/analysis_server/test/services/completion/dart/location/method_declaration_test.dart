// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MethodDeclarationTest);
  });
}

mixin MethodDeclarationInClassTestCases on AbstractCompletionDriverTest {
  Future<void> test__afterParameterList_beforeRightBrace_partial() async {
    await computeSuggestions('''
class A { foo() a^}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  async
    kind: keyword
  async*
    kind: keyword
''');
  }

  Future<void> test_afterAnnotation_beforeName() async {
    await computeSuggestions('''
class A { @override ^ foo() {}}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterAnnotation_beforeName_partial() async {
    await computeSuggestions('''
class A { @override d^ foo() {}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  dynamic
    kind: keyword
''');
  }

  Future<void> test_afterArrow_beforeField_async() async {
    await computeSuggestions('''
class A { foo() async => ^ Foo foo;}
''');
    assertResponse(r'''
suggestions
  await
    kind: keyword
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_afterArrow_beforeField_sync() async {
    await computeSuggestions('''
class A { foo() => ^ Foo foo;}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_afterArrow_beforeRightBrace_async() async {
    await computeSuggestions('''
class A { foo() async => ^}
''');
    assertResponse(r'''
suggestions
  await
    kind: keyword
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_afterArrow_beforeRightBrace_sync() async {
    await computeSuggestions('''
class A { foo() => ^}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_afterArrow_beforeSemicolon_async() async {
    await computeSuggestions('''
class A { foo() async => ^;}
''');
    assertResponse(r'''
suggestions
  await
    kind: keyword
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_afterArrow_beforeSemicolon_sync() async {
    await computeSuggestions('''
class A { foo() => ^;}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  super
    kind: keyword
  switch
    kind: keyword
  this
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_afterLeftBrace_beforeName_partial() async {
    await computeSuggestions('''
class A { ^foo() {}}
''');
    assertResponse(r'''
replacement
  right: 3
suggestions
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterParameterList_beforeArrow() async {
    await computeSuggestions('''
class A { foo() ^ => Foo foo;}
''');
    assertResponse(r'''
suggestions
  async
    kind: keyword
''');
  }

  Future<void> test_afterParameterList_beforeBody() async {
    await computeSuggestions('''
class A { foo() ^{}}
''');
    assertResponse(r'''
suggestions
  async
    kind: keyword
  async*
    kind: keyword
  sync*
    kind: keyword
''');
  }

  Future<void> test_afterParameterList_beforeBody_partial() async {
    await computeSuggestions('''
class A { foo() a^{}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  async
    kind: keyword
  async*
    kind: keyword
  sync*
    kind: keyword
''');
  }

  Future<void> test_afterParameterList_beforeField() async {
    await computeSuggestions('''
class A { foo() ^ Foo foo;}
''');
    assertResponse(r'''
suggestions
  async
    kind: keyword
  async*
    kind: keyword
  const
    kind: keyword
  covariant
    kind: keyword
  dynamic
    kind: keyword
  factory
    kind: keyword
  final
    kind: keyword
  get
    kind: keyword
  late
    kind: keyword
  operator
    kind: keyword
  set
    kind: keyword
  static
    kind: keyword
  sync*
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
  }

  Future<void> test_afterParameterList_beforeField_partial_a() async {
    await computeSuggestions('''
class A { foo() a^ Foo foo;}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  abstract
    kind: keyword
  async
    kind: keyword
  async*
    kind: keyword
''');
  }

  Future<void> test_afterParameterList_beforeRightBrace() async {
    await computeSuggestions('''
class A { foo() ^}
''');
    assertResponse(r'''
suggestions
''');
  }
}

@reflectiveTest
class MethodDeclarationTest extends AbstractCompletionDriverTest
    with MethodDeclarationInClassTestCases {}
