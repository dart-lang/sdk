// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinDeclarationTest1);
    defineReflectiveTests(MixinDeclarationTest2);
  });
}

@reflectiveTest
class MixinDeclarationTest1 extends AbstractCompletionDriverTest
    with MixinDeclarationTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class MixinDeclarationTest2 extends AbstractCompletionDriverTest
    with MixinDeclarationTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin MixinDeclarationTestCases on AbstractCompletionDriverTest {
  Future<void> test_afterName_beforeBody_partial() async {
    await computeSuggestions('''
mixin M o^ { }
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  on
    kind: keyword
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  implements
    kind: keyword
  on
    kind: keyword
''');
    }
  }

  Future<void> test_afterOnClause_beforeBody_partial() async {
    await computeSuggestions('''
mixin M on A i^ { } class A {}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  implements
    kind: keyword
''');
  }
}
