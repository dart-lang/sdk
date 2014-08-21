// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.edit.refactoring;

import 'dart:async';

import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/protocol2.dart' show
    EditGetAvailableRefactoringsParams, EditGetAvailableRefactoringsResult,
    RefactoringKind;
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart' hide ERROR;

import '../analysis_abstract.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(GetAvailableRefactoringsTest);
}


@ReflectiveTestCase()
class GetAvailableRefactoringsTest extends AbstractAnalysisTest {
  /**
   * Tests that there is a RENAME refactoring available at the [search] offset.
   */
  Future assertHasRenameRefactoring(String code, String search) {
    addTestFile(code);
    return waitForTasksFinished().then((_) {
      List<RefactoringKind> kinds = getRefactoringsAtString(search);
      expect(kinds, contains(RefactoringKind.RENAME));
    });
  }

  /**
   * Returns the list of available refactorings for the given [offset] and
   * [length].
   */
  List<RefactoringKind> getRefactorings(int offset, int length) {
    Request request = new EditGetAvailableRefactoringsParams(
        testFile,
        offset,
        length).toRequest('0');
    Response response = handleSuccessfulRequest(request);
    var result = new EditGetAvailableRefactoringsResult.fromResponse(response);
    return result.kinds;
  }

  /**
   * Returns the list of available refactorings at the offset of [search].
   */
  List<RefactoringKind> getRefactoringsAtString(String search) {
    int offset = findOffset(search);
    return getRefactorings(offset, 0);
  }

  List<RefactoringKind> getRefactoringsForString(String search) {
    int offset = findOffset(search);
    return getRefactorings(offset, search.length);
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
    handler = new EditDomainHandler(server);
  }

  Future test_extractLocal() {
    addTestFile('''
main() {
  var a = 1 + 2;
}
''');
    return waitForTasksFinished().then((_) {
      var search = '1 + 2';
      List<RefactoringKind> kinds = getRefactoringsForString(search);
      expect(kinds, contains(RefactoringKind.EXTRACT_LOCAL_VARIABLE));
      expect(kinds, contains(RefactoringKind.EXTRACT_METHOD));
    });
  }

  Future test_rename_hasElement_class() {
    return assertHasRenameRefactoring('''
class Test {}
main() {
  Test v;
}
''', 'Test v');
  }

  Future test_rename_hasElement_constructor() {
    return assertHasRenameRefactoring('''
class A {
  A.test() {}
}
main() {
  new A.test();
}
''', 'test();');
  }

  Future test_rename_hasElement_function() {
    return assertHasRenameRefactoring('''
main() {
  test();
}
test() {}
''', 'test();');
  }

  Future test_rename_hasElement_importElement_directive() {
    return assertHasRenameRefactoring('''
import 'dart:math' as math;
main() {
  math.PI;
}
''', 'import ');
  }

  Future test_rename_hasElement_importElement_prefixDecl() {
    return assertHasRenameRefactoring('''
import 'dart:math' as math;
main() {
  math.PI;
}
''', 'math;');
  }

  Future test_rename_hasElement_importElement_prefixRef() {
    return assertHasRenameRefactoring('''
import 'dart:async' as test;
import 'dart:math' as test;
main() {
  test.PI;
}
''', 'test.PI;');
  }

  Future test_rename_hasElement_instanceGetter() {
    return assertHasRenameRefactoring('''
class A {
  get test => 0;
}
main(A a) {
  a.test;
}
''', 'test;');
  }

  Future test_rename_hasElement_instanceSetter() {
    return assertHasRenameRefactoring('''
class A {
  set test(x) {}
}
main(A a) {
  a.test = 2;
}
''', 'test = 2;');
  }

  Future test_rename_hasElement_library() {
    return assertHasRenameRefactoring('''
library my.lib;
''', 'library ');
  }

  Future test_rename_hasElement_localVariable() {
    return assertHasRenameRefactoring('''
main() {
  int test = 0;
  print(test);
}
''', 'test = 0;');
  }

  Future test_rename_hasElement_method() {
    return assertHasRenameRefactoring('''
class A {
  test() {}
}
main(A a) {
  a.test();
}
''', 'test();');
  }

  Future test_rename_noElement() {
    addTestFile('''
main() {
  // not an element
}
''');
    return waitForTasksFinished().then((_) {
      List<RefactoringKind> kinds =
          getRefactoringsAtString('// not an element');
      expect(kinds, isNot(contains(RefactoringKind.RENAME)));
    });
  }
}
