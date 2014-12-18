// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.edit.refactoring;

import 'dart:async';

import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/local_memory_index.dart';
import 'package:unittest/unittest.dart' hide ERROR;

import '../analysis_abstract.dart';
import '../reflective_tests.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(ConvertGetterMethodToMethodTest);
  runReflectiveTests(ConvertMethodToGetterTest);
  runReflectiveTests(ExtractLocalVariableTest);
  runReflectiveTests(ExtractMethodTest);
  runReflectiveTests(GetAvailableRefactoringsTest);
  runReflectiveTests(InlineLocalTest);
  runReflectiveTests(InlineMethodTest);
  runReflectiveTests(MoveFileTest);
  runReflectiveTests(RenameTest);
}


@ReflectiveTestCase()
class ConvertGetterMethodToMethodTest extends _AbstractGetRefactoring_Test {
  test_function() {
    addTestFile('''
int get test => 42;
main() {
  var a = 1 + test;
  var b = 2 + test;
}
''');
    return assertSuccessfulRefactoring(() {
      return _sendConvertRequest('test =>');
    }, '''
int test() => 42;
main() {
  var a = 1 + test();
  var b = 2 + test();
}
''');
  }

  test_init_fatalError_notExplicit() {
    addTestFile('''
int test = 42;
main() {
  var v = test;
}
''');
    return getRefactoringResult(() {
      return _sendConvertRequest('test;');
    }).then((result) {
      assertResultProblemsFatal(
          result.initialProblems,
          'Only explicit getters can be converted to methods.');
      // ...there is no any change
      expect(result.change, isNull);
    });
  }

  test_method() {
    addTestFile('''
class A {
  int get test => 1;
}
class B extends A {
  int get test => 2;
}
class C extends B {
  int get test => 3;
}
class D extends A {
  int get test => 4;
}
main(A a, B b, C c, D d) {
  var va = a.test;
  var vb = b.test;
  var vc = c.test;
  var vd = d.test;
}
''');
    return assertSuccessfulRefactoring(() {
      return _sendConvertRequest('test => 2');
    }, '''
class A {
  int test() => 1;
}
class B extends A {
  int test() => 2;
}
class C extends B {
  int test() => 3;
}
class D extends A {
  int test() => 4;
}
main(A a, B b, C c, D d) {
  var va = a.test();
  var vb = b.test();
  var vc = c.test();
  var vd = d.test();
}
''');
  }

  Future<Response> _sendConvertRequest(String search) {
    Request request = new EditGetRefactoringParams(
        RefactoringKind.CONVERT_GETTER_TO_METHOD,
        testFile,
        findOffset(search),
        0,
        false).toRequest('0');
    return serverChannel.sendRequest(request);
  }
}


@ReflectiveTestCase()
class ConvertMethodToGetterTest extends _AbstractGetRefactoring_Test {
  test_function() {
    addTestFile('''
int test() => 42;
main() {
  var a = 1 + test();
  var b = 2 + test();
}
''');
    return assertSuccessfulRefactoring(() {
      return _sendConvertRequest('test() =>');
    }, '''
int get test => 42;
main() {
  var a = 1 + test;
  var b = 2 + test;
}
''');
  }

  test_init_fatalError_hasParameters() {
    addTestFile('''
int test(p) => p + 1;
main() {
  var v = test(2);
}
''');
    return getRefactoringResult(() {
      return _sendConvertRequest('test(p)');
    }).then((result) {
      assertResultProblemsFatal(
          result.initialProblems,
          'Only methods without parameters can be converted to getters.');
      // ...there is no any change
      expect(result.change, isNull);
    });
  }

  test_init_fatalError_notExecutableElement() {
    addTestFile('''
main() {
  int abc = 1;
  print(abc);
}
''');
    return getRefactoringResult(() {
      return _sendConvertRequest('abc');
    }).then((result) {
      assertResultProblemsFatal(
          result.initialProblems,
          'Unable to create a refactoring');
      // ...there is no any change
      expect(result.change, isNull);
    });
  }

  test_method() {
    addTestFile('''
class A {
  int test() => 1;
}
class B extends A {
  int test() => 2;
}
class C extends B {
  int test() => 3;
}
class D extends A {
  int test() => 4;
}
main(A a, B b, C c, D d) {
  var va = a.test();
  var vb = b.test();
  var vc = c.test();
  var vd = d.test();
}
''');
    return assertSuccessfulRefactoring(() {
      return _sendConvertRequest('test() => 2');
    }, '''
class A {
  int get test => 1;
}
class B extends A {
  int get test => 2;
}
class C extends B {
  int get test => 3;
}
class D extends A {
  int get test => 4;
}
main(A a, B b, C c, D d) {
  var va = a.test;
  var vb = b.test;
  var vc = c.test;
  var vd = d.test;
}
''');
  }

  Future<Response> _sendConvertRequest(String search) {
    Request request = new EditGetRefactoringParams(
        RefactoringKind.CONVERT_METHOD_TO_GETTER,
        testFile,
        findOffset(search),
        0,
        false).toRequest('0');
    return serverChannel.sendRequest(request);
  }
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
      ExtractLocalVariableFeedback feedback = result.feedback;
      expect(
          feedback.names,
          unorderedEquals(['treeItem', 'item', 'selectedItem']));
      expect(result.change, isNull);
    });
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
          result.optionsProblems,
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
      ExtractLocalVariableFeedback feedback = result.feedback;
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
      ExtractMethodFeedback feedback = result.feedback;
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

  test_init_fatalError_invalidStatement() {
    addTestFile('''
main(bool b) {
// start
  if (b) {
    print(1);
// end
    print(2);
  }
}
''');
    _setOffsetLengthForStartEnd();
    return waitForTasksFinished().then((_) {
      return _sendExtractRequest();
    }).then((Response response) {
      var result = new EditGetRefactoringResult.fromResponse(response);
      assertResultProblemsFatal(result.initialProblems);
      // ...there is no any feedback
      expect(result.feedback, isNull);
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
      return result.feedback;
    });
  }

  Future _prepareOptions() {
    return getRefactoringResult(() {
      // get initial feedback
      return _sendExtractRequest();
    }).then((result) {
      assertResultProblemsOK(result);
      // fill options from result
      ExtractMethodFeedback feedback = result.feedback;
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
class InlineLocalTest extends _AbstractGetRefactoring_Test {
  test_feedback() {
    addTestFile('''
main() {
  int test = 42;
  print(test);
  print(test);
}
''');
    return getRefactoringResult(() {
      return _sendInlineRequest('test =');
    }).then((result) {
      InlineLocalVariableFeedback feedback = result.feedback;
      expect(feedback.name, 'test');
      expect(feedback.occurrences, 2);
    });
  }

  test_init_fatalError_notVariable() {
    addTestFile('main() {}');
    return getRefactoringResult(() {
      return _sendInlineRequest('main() {}');
    }).then((result) {
      assertResultProblemsFatal(
          result.initialProblems,
          'Local variable declaration or reference must be selected to activate this refactoring.');
      // ...there is no any change
      expect(result.change, isNull);
    });
  }

  test_OK() {
    addTestFile('''
main() {
  int test = 42;
  int a = test + 2;
  print(test);
}
''');
    return assertSuccessfulRefactoring(() {
      return _sendInlineRequest('test + 2');
    }, '''
main() {
  int a = 42 + 2;
  print(42);
}
''');
  }

  Future<Response> _sendInlineRequest(String search) {
    Request request = new EditGetRefactoringParams(
        RefactoringKind.INLINE_LOCAL_VARIABLE,
        testFile,
        findOffset(search),
        0,
        false).toRequest('0');
    return serverChannel.sendRequest(request);
  }
}


@ReflectiveTestCase()
class InlineMethodTest extends _AbstractGetRefactoring_Test {
  InlineMethodOptions options = new InlineMethodOptions(true, true);

  test_feedback() {
    addTestFile('''
class A {
  int f;
  test(int p) {
    print(f + p);
  }
  main() {
    test(1);
  }
}
''');
    return getRefactoringResult(() {
      return _sendInlineRequest('test(int p)');
    }).then((result) {
      InlineMethodFeedback feedback = result.feedback;
      expect(feedback.className, 'A');
      expect(feedback.methodName, 'test');
      expect(feedback.isDeclaration, isTrue);
    });
  }

  test_init_fatalError_noMethod() {
    addTestFile('// nothing to inline');
    return getRefactoringResult(() {
      return _sendInlineRequest('// nothing');
    }).then((result) {
      assertResultProblemsFatal(
          result.initialProblems,
          'Method declaration or reference must be selected to activate this refactoring.');
      // ...there is no any change
      expect(result.change, isNull);
    });
  }

  test_method() {
    addTestFile('''
class A {
  int f;
  test(int p) {
    print(f + p);
  }
  main() {
    test(1);
  }
}
main(A a) {
  a.test(2);
}
''');
    return assertSuccessfulRefactoring(() {
      return _sendInlineRequest('test(int p)');
    }, '''
class A {
  int f;
  main() {
    print(f + 1);
  }
}
main(A a) {
  print(a.f + 2);
}
''');
  }

  test_topLevelFunction() {
    addTestFile('''
test(a, b) {
  print(a + b);
}
main() {
  test(1, 2);
  test(10, 20);
}
''');
    return assertSuccessfulRefactoring(() {
      return _sendInlineRequest('test(a');
    }, '''
main() {
  print(1 + 2);
  print(10 + 20);
}
''');
  }

  test_topLevelFunction_oneInvocation() {
    addTestFile('''
test(a, b) {
  print(a + b);
}
main() {
  test(1, 2);
  test(10, 20);
}
''');
    options.deleteSource = false;
    options.inlineAll = false;
    return assertSuccessfulRefactoring(() {
      return _sendInlineRequest('test(10,');
    }, '''
test(a, b) {
  print(a + b);
}
main() {
  test(1, 2);
  print(10 + 20);
}
''');
  }

  Future<Response> _sendInlineRequest(String search) {
    Request request = new EditGetRefactoringParams(
        RefactoringKind.INLINE_METHOD,
        testFile,
        findOffset(search),
        0,
        false,
        options: options).toRequest('0');
    return serverChannel.sendRequest(request);
  }
}


@ReflectiveTestCase()
class MoveFileTest extends _AbstractGetRefactoring_Test {
  MoveFileOptions options = new MoveFileOptions(null);

  test_OK() {
    resourceProvider.newFile('/project/bin/lib.dart', '');
    addTestFile('''
import 'dart:math';
import 'lib.dart';
''');
    options.newFile = '/project/test.dart';
    return assertSuccessfulRefactoring(() {
      return _sendMoveRequest();
    }, '''
import 'dart:math';
import 'bin/lib.dart';
''');
  }

  Future<Response> _sendMoveRequest() {
    Request request = new EditGetRefactoringParams(
        RefactoringKind.MOVE_FILE,
        testFile,
        0,
        0,
        false,
        options: options).toRequest('0');
    return serverChannel.sendRequest(request);
  }
}


@ReflectiveTestCase()
class RenameTest extends _AbstractGetRefactoring_Test {
  Future<Response> sendRenameRequest(String search, String newName,
      [bool validateOnly = false]) {
    RenameOptions options = newName != null ? new RenameOptions(newName) : null;
    Request request = new EditGetRefactoringParams(
        RefactoringKind.RENAME,
        testFile,
        findOffset(search),
        0,
        validateOnly,
        options: options).toRequest('0');
    return serverChannel.sendRequest(request);
  }

  test_class() {
    addTestFile('''
class Test {
  Test() {}
  Test.named() {}
}
main() {
  Test v;
  new Test();
  new Test.named();
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('Test {', 'NewName');
    }, '''
class NewName {
  NewName() {}
  NewName.named() {}
}
main() {
  NewName v;
  new NewName();
  new NewName.named();
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
      assertResultProblemsFatal(
          result.optionsProblems,
          'Class name must not be empty.');
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
      RenameFeedback feedback = result.feedback;
      assertResultProblemsOK(result);
      expect(feedback.elementKindName, 'class');
      expect(feedback.oldName, 'Test');
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
          result.optionsProblems,
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

  test_classMember_field() {
    addTestFile('''
class A {
  var test = 0;
  A(this.test);
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
  A(this.newName);
  main() {
    print(newName);
  }
}
''');
  }

  test_classMember_field_onFieldFormalParameter() {
    addTestFile('''
class A {
  var test = 0;
  A(this.test);
  main() {
    print(test);
  }
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test);', 'newName');
    }, '''
class A {
  var newName = 0;
  A(this.newName);
  main() {
    print(newName);
  }
}
''');
  }

  test_classMember_field_onFieldFormalParameter_named() {
    addTestFile('''
class A {
  final int test;
  A({this.test: 0});
}
main() {
  new A(test: 42);
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test: 42', 'newName');
    }, '''
class A {
  final int newName;
  A({this.newName: 0});
}
main() {
  new A(newName: 42);
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

  test_classMember_method() {
    addTestFile('''
class A {
  test() {}
  main() {
    test();
  }
}
main(A a) {
  a.test();
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test() {}', 'newName');
    }, '''
class A {
  newName() {}
  main() {
    newName();
  }
}
main(A a) {
  a.newName();
}
''');
  }

  test_classMember_method_potential() {
    addTestFile('''
class A {
  test() {}
}
main(A a, a2) {
  a.test();
  a2.test(); // a2
}
''');
    return getRefactoringResult(() {
      return sendRenameRequest('test() {}', 'newName');
    }).then((result) {
      assertResultProblemsOK(result);
      // prepare potential edit ID
      List<String> potentialIds = result.potentialEdits;
      expect(potentialIds, hasLength(1));
      String potentialId = potentialIds[0];
      // find potential edit
      SourceChange change = result.change;
      SourceEdit potentialEdit = _findEditWithId(change, potentialId);
      expect(potentialEdit, isNotNull);
      expect(potentialEdit.offset, findOffset('test(); // a2'));
      expect(potentialEdit.length, 4);
    });
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

  test_constructor_fromInstanceCreation() {
    addTestFile('''
class A {
  A.test() {}
}
main() {
  new A.test();
}
''');
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

  test_constructor_fromInstanceCreation_default_onClassName() {
    addTestFile('''
class A {
  A() {}
}
main() {
  new A();
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('A();', 'newName');
    }, '''
class A {
  A.newName() {}
}
main() {
  new A.newName();
}
''');
  }

  test_constructor_fromInstanceCreation_default_onNew() {
    addTestFile('''
class A {
  A() {}
}
main() {
  new A();
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('new A();', 'newName');
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

  test_importPrefix_add() {
    addTestFile('''
import 'dart:math';
import 'dart:async';
main() {
  Random r;
  Future f;
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest("import 'dart:async';", 'new_name');
    }, '''
import 'dart:math';
import 'dart:async' as new_name;
main() {
  Random r;
  new_name.Future f;
}
''');
  }

  test_importPrefix_remove() {
    addTestFile('''
import 'dart:math' as test;
import 'dart:async' as test;
main() {
  test.Random r;
  test.Future f;
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest("import 'dart:async' as test;", '');
    }, '''
import 'dart:math' as test;
import 'dart:async';
main() {
  test.Random r;
  Future f;
}
''');
  }

  test_init_fatalError_noElement() {
    addTestFile('// nothing to rename');
    return getRefactoringResult(() {
      return sendRenameRequest('// nothing', null);
    }).then((result) {
      assertResultProblemsFatal(
          result.initialProblems,
          'Unable to create a refactoring');
      // ...there is no any change
      expect(result.change, isNull);
    });
  }

  test_library_libraryDirective() {
    addTestFile('''
library aaa.bbb.ccc;
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('library aaa', 'my.new_name');
    }, '''
library my.new_name;
''');
  }

  test_library_libraryDirective_name() {
    addTestFile('''
library aaa.bbb.ccc;
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('aaa', 'my.new_name');
    }, '''
library my.new_name;
''');
  }

  test_library_libraryDirective_nameDot() {
    addTestFile('''
library aaa.bbb.ccc;
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('.bbb', 'my.new_name');
    }, '''
library my.new_name;
''');
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
      return sendRenameRequest('test = 0', 'newName', false);
    }).then((result) {
      List<RefactoringProblem> problems = result.finalProblems;
      expect(problems, hasLength(1));
      assertResultProblemsError(
          problems,
          "Duplicate local variable 'newName'.");
    });
  }

  test_resetOnAnalysis() {
    addTestFile('''
main() {
  int initialName = 0;
  print(initialName);
}
''');
    // send the first request
    return getRefactoringResult(() {
      return sendRenameRequest('initialName =', 'newName', true);
    }).then((result) {
      RenameFeedback feedback = result.feedback;
      expect(feedback.oldName, 'initialName');
      // update the file
      modifyTestFile('''
main() {
  int otherName = 0;
  print(otherName);
}
''');
      // send the second request, with the same kind, file and offset
      return waitForTasksFinished().then((_) {
        return getRefactoringResult(() {
          return sendRenameRequest('otherName =', 'newName', true);
        }).then((result) {
          RenameFeedback feedback = result.feedback;
          // the refactoring was reset, so we don't get a stale result
          expect(feedback.oldName, 'otherName');
        });
      });
    });
  }

  SourceEdit _findEditWithId(SourceChange change, String id) {
    SourceEdit potentialEdit;
    change.edits.forEach((fileEdit) {
      fileEdit.edits.forEach((edit) {
        if (edit.id == id) {
          potentialEdit = edit;
        }
      });
    });
    return potentialEdit;
  }
}


@ReflectiveTestCase()
class _AbstractGetRefactoring_Test extends AbstractAnalysisTest {
  /**
   * Asserts that [problems] has a single ERROR problem.
   */
  void assertResultProblemsError(List<RefactoringProblem> problems,
      [String message]) {
    RefactoringProblem problem = problems[0];
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
  void assertResultProblemsFatal(List<RefactoringProblem> problems,
      [String message]) {
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
    expect(result.initialProblems, isEmpty);
    expect(result.optionsProblems, isEmpty);
    expect(result.finalProblems, isEmpty);
  }

  /**
   * Asserts that [result] has a single WARNING problem.
   */
  void assertResultProblemsWarning(List<RefactoringProblem> problems,
      [String message]) {
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
      RefactoringOptions options, [bool validateOnly = false]) {
    Request request = new EditGetRefactoringParams(
        kind,
        testFile,
        offset,
        length,
        validateOnly,
        options: options).toRequest('0');
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
