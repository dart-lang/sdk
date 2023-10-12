// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldDeclarationInClassTest1);
    defineReflectiveTests(FieldDeclarationInClassTest2);
    defineReflectiveTests(FieldDeclarationInExtensionTest1);
    defineReflectiveTests(FieldDeclarationInExtensionTest2);
  });
}

@reflectiveTest
class FieldDeclarationInClassTest1 extends AbstractCompletionDriverTest
    with FieldDeclarationInClassTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class FieldDeclarationInClassTest2 extends AbstractCompletionDriverTest
    with FieldDeclarationInClassTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin FieldDeclarationInClassTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterStatic_beforeEnd_partial_c() async {
    await computeSuggestions('''
class C {
  static c^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
    kind: override
    selection: 62 14
  @override
  // TODO: implement runtimeType
  Type get runtimeType => super.runtimeType;
    kind: override
    selection: 69 17
  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
    kind: override
    selection: 68 24
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
    kind: override
    selection: 75 22
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    return super.noSuchMethod(invocation);
  }
    kind: override
    selection: 90 38
  const
    kind: keyword
  dynamic
    kind: keyword
  external
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_afterStatic_beforeEnd_partial_f() async {
    await computeSuggestions('''
class C {
  static f^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  final
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
    kind: override
    selection: 62 14
  @override
  // TODO: implement runtimeType
  Type get runtimeType => super.runtimeType;
    kind: override
    selection: 69 17
  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
    kind: override
    selection: 68 24
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
    kind: override
    selection: 75 22
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    return super.noSuchMethod(invocation);
  }
    kind: override
    selection: 90 38
  const
    kind: keyword
  dynamic
    kind: keyword
  external
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_initializer() async {
    await computeSuggestions('''
class A {var foo = ^}
''');
    assertResponse(r'''
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
  }

  Future<void> test_initializer_partial() async {
    await computeSuggestions('''
class A {var foo = n^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  null
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  false
    kind: keyword
  null
    kind: keyword
  switch
    kind: keyword
  true
    kind: keyword
''');
    }
  }
}

@reflectiveTest
class FieldDeclarationInExtensionTest1 extends AbstractCompletionDriverTest
    with FieldDeclarationInExtensionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class FieldDeclarationInExtensionTest2 extends AbstractCompletionDriverTest
    with FieldDeclarationInExtensionTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin FieldDeclarationInExtensionTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterStatic_partial_c() async {
    await computeSuggestions('''
extension E on int {
  static c^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  dynamic
    kind: keyword
  external
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
    }
  }

  Future<void> test_afterStatic_partial_f() async {
    await computeSuggestions('''
extension E on int {
  static f^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  final
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  const
    kind: keyword
  dynamic
    kind: keyword
  external
    kind: keyword
  final
    kind: keyword
  var
    kind: keyword
  void
    kind: keyword
''');
    }
  }
}
