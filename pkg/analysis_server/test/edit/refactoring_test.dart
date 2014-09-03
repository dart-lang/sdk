// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.edit.refactoring;

import 'dart:async';

import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/local_memory_index.dart';
import 'package:analysis_server/src/services/json.dart';
import '../reflective_tests.dart';
import 'package:unittest/unittest.dart' hide ERROR;

import '../analysis_abstract.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(ExtractLocalVariableTest);
  runReflectiveTests(ExtractMethodTest);
  runReflectiveTests(GetAvailableRefactoringsTest);
  runReflectiveTests(RenameTest);
}


@ReflectiveTestCase()
class ExtractLocalVariableTest extends _AbstractGetRefactoring_Test {
  Future<Response> sendExtractRequest(int offset, int length, String name,
      bool extractAll) {
    RefactoringKind kind = RefactoringKind.EXTRACT_LOCAL_VARIABLE;
    ExtractLocalVariableOptions options =
        name != null ? new ExtractLocalVariableOptions(name, extractAll) : null;
    return sendRequest(kind, offset, length, options, false);
  }

  Future<Response> sendStringRequest(String search, String name,
      bool extractAll) {
    int offset = findOffset(search);
    int length = search.length;
    return sendExtractRequest(offset, length, name, extractAll);
  }

  Future<Response> sendStringSuffixRequest(String search, String suffix,
      String name, bool extractAll) {
    int offset = findOffset(search + suffix);
    int length = search.length;
    return sendExtractRequest(offset, length, name, extractAll);
  }

  test_extractAll() {
    addTestFile('''
main() {
  print(1 + 2);
  print(1 + 2);
}
''');
    return assertSuccessfulRefactoring(() {
      return sendStringRequest('1 + 2', 'res', true);
    }, '''
main() {
  var res = 1 + 2;
  print(res);
  print(res);
}
''');
  }

  test_extractOne() {
    addTestFile('''
main() {
  print(1 + 2);
  print(1 + 2); // marker
}
''');
    return assertSuccessfulRefactoring(() {
      return sendStringSuffixRequest('1 + 2', '); // marker', 'res', false);
    }, '''
main() {
  print(1 + 2);
  var res = 1 + 2;
  print(res); // marker
}
''');
  }

  test_nameWarning() {
    addTestFile('''
main() {
  print(1 + 2);
}
''');
    return getRefactoringResult(() {
      return sendStringRequest('1 + 2', 'Name', true);
    }).then((result) {
      assertResultProblemsWarning(
          result,
          'Variable name should start with a lowercase letter.');
      // ...but there is still a change
      assertTestRefactoringResult(result, '''
main() {
  var Name = 1 + 2;
  print(Name);
}
''');
    });
  }

  test_names() {
    addTestFile('''
class TreeItem {}
TreeItem getSelectedItem() => null;
main() {
  var a = getSelectedItem();
}
''');
    return getRefactoringResult(() {
      return sendStringSuffixRequest('getSelectedItem()', ';', null, true);
    }).then((result) {
      ExtractLocalVariableFeedback feedback =
          new ExtractLocalVariableFeedback.fromRefactoringResult(result);
      expect(
          feedback.names,
          unorderedEquals(['treeItem', 'item', 'selectedItem']));
      expect(result.change, isNull);
    });
  }

  test_offsetsLengths() {
    addTestFile('''
main() {
  print(1 + 2);
  print(1 +  2);
}
''');
    return getRefactoringResult(() {
      return sendStringRequest('1 + 2', 'res', true);
    }).then((result) {
      ExtractLocalVariableFeedback feedback =
          new ExtractLocalVariableFeedback.fromRefactoringResult(result);
      expect(feedback.offsets, [findOffset('1 + 2'), findOffset('1 +  2')]);
      expect(feedback.lengths, [5, 6]);
    });
  }
}


@ReflectiveTestCase()
class ExtractMethodTest extends _AbstractGetRefactoring_Test {
  int offset;
  int length;
  String name = 'res';
  ExtractMethodOptions options;

  test_expression() {
    addTestFile('''
main() {
  print(1 + 2);
  print(1 + 2);
}
''');
    _setOffsetLengthForString('1 + 2');
    return assertSuccessfulRefactoring(_computeChange, '''
main() {
  print(res());
  print(res());
}

int res() => 1 + 2;
''');
  }

  test_expression_hasParameters() {
    addTestFile('''
main() {
  int a = 1;
  int b = 2;
  print(a + b);
  print(a +  b);
}
''');
    _setOffsetLengthForString('a + b');
    return assertSuccessfulRefactoring(_computeChange, '''
main() {
  int a = 1;
  int b = 2;
  print(res(a, b));
  print(res(a, b));
}

int res(int a, int b) => a + b;
''');
  }

  test_expression_updateParameters() {
    addTestFile('''
main() {
  int a = 1;
  int b = 2;
  print(a + b);
  print(a + b);
}
''');
    _setOffsetLengthForString('a + b');
    return getRefactoringResult(_computeChange).then((result) {
      ExtractMethodFeedback feedback =
          new ExtractMethodFeedback.fromRefactoringResult(result);
      List<RefactoringMethodParameter> parameters = feedback.parameters;
      parameters[0].name = 'aaa';
      parameters[1].name = 'bbb';
      parameters[1].type = 'num';
      parameters.insert(0, parameters.removeLast());
      options.parameters = parameters;
      return assertSuccessfulRefactoring(_sendExtractRequest, '''
main() {
  int a = 1;
  int b = 2;
  print(res(b, a));
  print(res(b, a));
}

int res(num bbb, int aaa) => aaa + bbb;
''');
    });
  }

  test_names() {
    addTestFile('''
class TreeItem {}
TreeItem getSelectedItem() => null;
main() {
  var a = getSelectedItem( );
}
''');
    _setOffsetLengthForString('getSelectedItem( )');
    return _computeInitialFeedback().then((feedback) {
      expect(
          feedback.names,
          unorderedEquals(['treeItem', 'item', 'selectedItem']));
      expect(feedback.returnType, 'TreeItem');
    });
  }

  test_offsetsLengths() {
    addTestFile('''
class TreeItem {}
TreeItem getSelectedItem() => null;
main() {
  var a = 1 + 2;
  var b = 1 +  2;
}
''');
    _setOffsetLengthForString('1 + 2');
    return _computeInitialFeedback().then((feedback) {
      expect(feedback.offsets, [findOffset('1 + 2'), findOffset('1 +  2')]);
      expect(feedback.lengths, [5, 6]);
    });
  }

  test_statements() {
    addTestFile('''
main() {
  int a = 1;
  int b = 2;
// start
  print(a + b);
// end
  print(a + b);
}
''');
    _setOffsetLengthForStartEnd();
    return assertSuccessfulRefactoring(_computeChange, '''
main() {
  int a = 1;
  int b = 2;
// start
  res(a, b);
// end
  res(a, b);
}

void res(int a, int b) {
  print(a + b);
}
''');
  }

  Future<Response> _computeChange() {
    return _prepareOptions().then((_) {
      // send request with the options
      return _sendExtractRequest();
    });
  }

  Future<ExtractMethodFeedback> _computeInitialFeedback() {
    return waitForTasksFinished().then((_) {
      return _sendExtractRequest();
    }).then((Response response) {
      var result = new EditGetRefactoringResult.fromResponse(response);
      return new ExtractMethodFeedback.fromRefactoringResult(result);
    });
  }

  Future _prepareOptions() {
    return getRefactoringResult(() {
      // get initial feedback
      return _sendExtractRequest();
    }).then((result) {
      assertResultProblemsOK(result);
      // fill options from result
      var feedback = new ExtractMethodFeedback.fromRefactoringResult(result);
      options = new ExtractMethodOptions(
          feedback.returnType,
          false,
          name,
          feedback.parameters,
          true);
      // done
      return new Future.value();
    });
  }

  Future<Response> _sendExtractRequest() {
    RefactoringKind kind = RefactoringKind.EXTRACT_METHOD;
    return sendRequest(kind, offset, length, options, false);
  }

  void _setOffsetLengthForStartEnd() {
    offset = findOffset('// start') + '// start\n'.length;
    length = findOffset('// end') - offset;
  }

  void _setOffsetLengthForString(String search) {
    offset = findOffset(search);
    length = search.length;
  }
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
class RenameTest extends _AbstractGetRefactoring_Test {
  Future<Response> sendRenameRequest(String search, String newName,
      [bool validateOnly = false]) {
    Request request = new EditGetRefactoringParams(
        RefactoringKind.RENAME,
        testFile,
        findOffset(search),
        0,
        validateOnly,
        options: new RenameOptions(newName).toJson()).toRequest('0');
    return serverChannel.sendRequest(request);
  }

  test_class() {
    addTestFile('''
class Test {}
main() {
  Test v;
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('Test {}', 'NewName');
    }, '''
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
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test = 0', 'newName');
    }, '''
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
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test =>', 'newName');
    }, '''
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
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test = 0', 'newName');
    }, '''
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
    return getRefactoringResult(() {
      return sendRenameRequest('Test {}', '');
    }).then((result) {
      assertResultProblemsFatal(result, 'Class name must not be empty.');
      // ...there is no any change
      expect(result.change, isNull);
    });
  }

  test_class_validateOnly() {
    addTestFile('''
class Test {}
main() {
  Test v;
}
''');
    return getRefactoringResult(() {
      return sendRenameRequest('Test {}', 'NewName', true);
    }).then((result) {
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
    return getRefactoringResult(() {
      return sendRenameRequest('Test {}', 'newName');
    }).then((result) {
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
      // "NewName" is a perfectly valid name
      return getRefactoringResult(() {
        return sendRenameRequest('Test {}', 'NewName');
      }).then((result) {
        assertResultProblemsOK(result);
        // ...and there is a new change
        assertTestRefactoringResult(result, '''
class NewName {}
main() {
  NewName v;
}
''');
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
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test();', 'newName');
    }, '''
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
    return getRefactoringResult(() {
      return sendRenameRequest('st v;', 'NewName');
    }).then((result) {
      RenameFeedback feedback =
          new RenameFeedback.fromRefactoringResult(result);
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
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test() {}', 'newName');
    }, '''
newName() {}
main() {
  newName();
  print(newName);
}
''');
  }

  test_init_fatalError_noElement() {
    addTestFile('// nothing to rename');
    return getRefactoringResult(() {
      return sendRenameRequest('// nothing', null);
    }).then((result) {
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
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test = 1', 'newName');
    }, '''
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
    return getRefactoringResult(() {
      return sendRenameRequest('test = 0', 'newName');
    }).then((result) {
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

  Future assertSuccessfulRefactoring(Future<Response> requestSender(),
      String expectedCode) {
    return getRefactoringResult(requestSender).then((result) {
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

  Future<EditGetRefactoringResult> getRefactoringResult(Future<Response>
      requestSender()) {
    return waitForTasksFinished().then((_) {
      return requestSender().then((Response response) {
        return new EditGetRefactoringResult.fromResponse(response);
      });
    });
  }

  Future<Response> sendRequest(RefactoringKind kind, int offset, int length,
      HasToJson options, [bool validateOnly = false]) {
    Map optionsJson = options != null ? options.toJson() : null;
    Request request = new EditGetRefactoringParams(
        kind,
        testFile,
        offset,
        length,
        validateOnly,
        options: optionsJson).toRequest('0');
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
