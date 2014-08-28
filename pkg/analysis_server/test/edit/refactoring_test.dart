// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.edit.refactoring;

import 'dart:async';

import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/local_memory_index.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart' hide ERROR;

import '../analysis_abstract.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(GetAvailableRefactoringsTest);
  runReflectiveTests(GetRefactoring_Rename_Test);
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


@ReflectiveTestCase()
class GetRefactoring_Rename_Test extends _AbstractGetRefactoring_Test {
  test_class() {
    addTestFile('''
class Test {}
main() {
  Test v;
}
''');
    String search = 'Test {}';
    String newName = 'NewName';
    return assertSuccessfulRefactoring(search, newName, '''
class NewName {}
main() {
  NewName v;
}
''');
  }

  test_classMember_field() {
    addTestFile('''
class A {
  var test = 0;
  main() {
    print(test);
  }
}
''');
    String search = 'test = 0';
    String newName = 'newName';
    return assertSuccessfulRefactoring(search, newName, '''
class A {
  var newName = 0;
  main() {
    print(newName);
  }
}
''');
  }

  test_classMember_getter() {
    addTestFile('''
class A {
  get test => 0;
  main() {
    print(test);
  }
}
''');
    String search = 'test =>';
    String newName = 'newName';
    return assertSuccessfulRefactoring(search, newName, '''
class A {
  get newName => 0;
  main() {
    print(newName);
  }
}
''');
  }

  test_classMember_setter() {
    addTestFile('''
class A {
  set test(x) {}
  main() {
    test = 0;
  }
}
''');
    String search = 'test = 0';
    String newName = 'newName';
    return assertSuccessfulRefactoring(search, newName, '''
class A {
  set newName(x) {}
  main() {
    newName = 0;
  }
}
''');
  }

  test_class_options_fatalError() {
    addTestFile('''
class Test {}
main() {
  Test v;
}
''');
    return waitForTasksFinished().then((_) {
      String search = 'Test {}';
      return sendRenameRequest(search, '').then((Response response) {
        var result = new EditGetRefactoringResult.fromResponse(response);
        assertResultProblemsFatal(result, 'Class name must not be empty.');
        // ...there is no any change
        expect(result.change, isNull);
      });
    });
  }

  test_class_validateOnly() {
    addTestFile('''
class Test {}
main() {
  Test v;
}
''');
    String search = 'Test {}';
    String newName = 'NewName';
    return getRefactoringResult(
        search,
        newName,
        validateOnly: true).then((result) {
      assertResultProblemsOK(result);
      expect(result.change, isNull);
    });
  }

  test_class_warning() {
    addTestFile('''
class Test {}
main() {
  Test v;
}
''');
    return waitForTasksFinished().then((_) {
      String search = 'Test {}';
      return sendRenameRequest(search, 'newName').then((Response response) {
        var result = new EditGetRefactoringResult.fromResponse(response);
        assertResultProblemsWarning(
            result,
            'Class name should start with an uppercase letter.');
        // ...but there is still a change
        assertTestRefactoringResult(result, '''
class newName {}
main() {
  newName v;
}
''');
      }).then((_) {
        return sendRenameRequest(search, 'NewName').then((Response response) {
          var result = new EditGetRefactoringResult.fromResponse(response);
          // OK
          assertResultProblemsOK(result);
        });
      });
    });
  }

  test_constructor() {
    addTestFile('''
class A {
  A.test() {}
}
main() {
  new A.test();
}
''');
    String search = 'test();';
    String newName = 'newName';
    return assertSuccessfulRefactoring(search, newName, '''
class A {
  A.newName() {}
}
main() {
  new A.newName();
}
''');
  }

  test_feedback() {
    addTestFile('''
class Test {}
main() {
  Test v;
}
''');
    String search = 'st v;';
    String newName = 'NewName';
    return getRefactoringResult(search, newName).then((result) {
      RenameFeedback feedback = result.feedback;
      expect(feedback, isNotNull);
      expect(feedback.offset, findOffset('Test v;'));
      expect(feedback.length, 'Test'.length);
    });
  }

  test_function() {
    addTestFile('''
test() {}
main() {
  test();
  print(test);
}
''');
    String search = 'test() {}';
    String newName = 'newName';
    return assertSuccessfulRefactoring(search, newName, '''
newName() {}
main() {
  newName();
  print(newName);
}
''');
  }

  test_init_fatalError_noElement() {
    addTestFile('// nothing to rename');
    String search = '// nothing';
    return getRefactoringResult(search, null).then((result) {
      assertResultProblemsFatal(result, 'Unable to create a refactoring');
      // ...there is no any change
      expect(result.change, isNull);
    });
  }

  test_localVariable() {
    addTestFile('''
main() {
  int test = 0;
  test = 1;
  test += 2;
  print(test);
}
''');
    String search = 'test = 1';
    String newName = 'newName';
    return assertSuccessfulRefactoring(search, newName, '''
main() {
  int newName = 0;
  newName = 1;
  newName += 2;
  print(newName);
}
''');
  }

  test_localVariable_finalCheck_shadowError() {
    addTestFile('''
main() {
  var newName;
  int test = 0;
  print(test);
}
''');
    String search = 'test = 0';
    String newName = 'newName';
    return getRefactoringResult(search, newName).then((result) {
      assertResultProblemsError(result, "Duplicate local variable 'newName'.");
    });
  }
}


@ReflectiveTestCase()
class _AbstractGetRefactoring_Test extends AbstractAnalysisTest {
  /**
   * Asserts that [result] has a single ERROR problem.
   */
  void assertResultProblemsError(EditGetRefactoringResult result,
      [String message]) {
    List<RefactoringProblem> problems = result.problems;
    RefactoringProblem problem = problems[0];
    expect(problems, hasLength(1));
    expect(
        problem.severity,
        RefactoringProblemSeverity.ERROR,
        reason: problem.toString());
    if (message != null) {
      expect(problem.message, message);
    }
  }

  /**
   * Asserts that [result] has a single FATAL problem.
   */
  void assertResultProblemsFatal(EditGetRefactoringResult result,
      [String message]) {
    List<RefactoringProblem> problems = result.problems;
    RefactoringProblem problem = problems[0];
    expect(problems, hasLength(1));
    expect(
        problem.severity,
        RefactoringProblemSeverity.FATAL,
        reason: problem.toString());
    if (message != null) {
      expect(problem.message, message);
    }
  }

  /**
   * Asserts that [result] has no problems at all.
   */
  void assertResultProblemsOK(EditGetRefactoringResult result) {
    expect(result.problems, isEmpty);
  }

  /**
   * Asserts that [result] has a single WARNING problem.
   */
  void assertResultProblemsWarning(EditGetRefactoringResult result,
      [String message]) {
    List<RefactoringProblem> problems = result.problems;
    RefactoringProblem problem = problems[0];
    expect(problems, hasLength(1));
    expect(
        problem.severity,
        RefactoringProblemSeverity.WARNING,
        reason: problem.toString());
    if (message != null) {
      expect(problem.message, message);
    }
  }

  Future assertSuccessfulRefactoring(String search, String newName,
      String expectedCode) {
    return getRefactoringResult(search, newName).then((result) {
      assertResultProblemsOK(result);
      assertTestRefactoringResult(result, expectedCode);
    });
  }

  /**
   * Asserts that the given [EditGetRefactoringResult] has a [testFile] change
   * which results in the [expectedCode].
   */
  void assertTestRefactoringResult(EditGetRefactoringResult result,
      String expectedCode) {
    SourceChange change = result.change;
    expect(change, isNotNull);
    for (SourceFileEdit fileEdit in change.edits) {
      if (fileEdit.file == testFile) {
        String actualCode = SourceEdit.applySequence(testCode, fileEdit.edits);
        expect(actualCode, expectedCode);
        return;
      }
    }
    fail('No SourceFileEdit for $testFile in $change');
  }

  @override
  Index createIndex() {
    return createLocalMemoryIndex();
  }

  Future<EditGetRefactoringResult> getRefactoringResult(String search,
      String newName, {bool validateOnly: false}) {
    return waitForTasksFinished().then((_) {
      return sendRenameRequest(
          search,
          newName,
          validateOnly: validateOnly).then((Response response) {
        return new EditGetRefactoringResult.fromResponse(response);
      });
    });
  }

  Future sendRenameRequest(String search, String newName, {bool validateOnly:
      false}) {
    Request request = new EditGetRefactoringParams(
        RefactoringKind.RENAME,
        testFile,
        findOffset(search),
        0,
        validateOnly,
        options: new RenameOptions(newName)).toRequest('0');
    return serverChannel.sendRequest(request);
  }

  @override
  void setUp() {
    super.setUp();
    server.handlers = [new EditDomainHandler(server),];
    createProject();
    handler = new EditDomainHandler(server);
  }
}
