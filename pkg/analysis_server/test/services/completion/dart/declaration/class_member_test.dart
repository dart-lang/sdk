// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassMemberTest1);
    defineReflectiveTests(ClassMemberTest2);
  });
}

@reflectiveTest
class ClassMemberTest1 extends AbstractCompletionDriverTest
    with ClassMemberTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ClassMemberTest2 extends AbstractCompletionDriverTest
    with ClassMemberTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ClassMemberTestCases on AbstractCompletionDriverTest {
  @override
  bool get includeKeywords => false;

  Future<void> test_inheritedFromPrivateClass() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
class _W {
  M y0 = M();
  var _z0;
  m() {
    _z0;
  }
}
class X extends _W {}
class M {}
''');
    await computeSuggestions('''
import "b.dart";
foo(X x) {
  x.^
}
''');
    assertResponse(r'''
suggestions
  y0
    kind: field
''');
  }
}
