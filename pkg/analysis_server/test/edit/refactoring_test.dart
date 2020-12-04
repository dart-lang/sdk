// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';
import '../mocks.dart';
import '../src/utilities/mock_packages.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertGetterMethodToMethodTest);
    defineReflectiveTests(ConvertMethodToGetterTest);
    defineReflectiveTests(ExtractLocalVariableTest);
    defineReflectiveTests(ExtractMethodTest);
    defineReflectiveTests(GetAvailableRefactoringsTest);
    defineReflectiveTests(InlineLocalTest);
    defineReflectiveTests(InlineMethodTest);
    defineReflectiveTests(MoveFileTest);
    defineReflectiveTests(RenameTest);
  });
}

/// Wrapper around the test package's `fail` function.
///
/// Unlike the test package's `fail` function, this function is not annotated
/// with @alwaysThrows, so we can call it at the top of a test method without
/// causing the rest of the method to be flagged as dead code.
void _fail(String message) {
  fail(message);
}

@reflectiveTest
class ConvertGetterMethodToMethodTest extends _AbstractGetRefactoring_Test {
  Future<void> test_function() {
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

  Future<void> test_init_fatalError_notExplicit() {
    addTestFile('''
int test = 42;
main() {
  var v = test;
}
''');
    return getRefactoringResult(() {
      return _sendConvertRequest('test;');
    }).then((result) {
      assertResultProblemsFatal(result.initialProblems,
          'Only explicit getters can be converted to methods.');
      // ...there is no any change
      expect(result.change, isNull);
    });
  }

  Future<void> test_method() {
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
    var request = EditGetRefactoringParams(
            RefactoringKind.CONVERT_GETTER_TO_METHOD,
            testFile,
            findOffset(search),
            0,
            false)
        .toRequest('0');
    return serverChannel.sendRequest(request);
  }
}

@reflectiveTest
class ConvertMethodToGetterTest extends _AbstractGetRefactoring_Test {
  Future<void> test_function() {
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

  Future<void> test_init_fatalError_hasParameters() {
    addTestFile('''
int test(p) => p + 1;
main() {
  var v = test(2);
}
''');
    return getRefactoringResult(() {
      return _sendConvertRequest('test(p)');
    }).then((result) {
      assertResultProblemsFatal(result.initialProblems,
          'Only methods without parameters can be converted to getters.');
      // ...there is no any change
      expect(result.change, isNull);
    });
  }

  Future<void> test_init_fatalError_notExecutableElement() {
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
          result.initialProblems, 'Unable to create a refactoring');
      // ...there is no any change
      expect(result.change, isNull);
    });
  }

  Future<void> test_method() {
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
    var request = EditGetRefactoringParams(
            RefactoringKind.CONVERT_METHOD_TO_GETTER,
            testFile,
            findOffset(search),
            0,
            false)
        .toRequest('0');
    return serverChannel.sendRequest(request);
  }
}

@reflectiveTest
class ExtractLocalVariableTest extends _AbstractGetRefactoring_Test {
  Future<Response> sendExtractRequest(
      int offset, int length, String name, bool extractAll) {
    var kind = RefactoringKind.EXTRACT_LOCAL_VARIABLE;
    var options =
        name != null ? ExtractLocalVariableOptions(name, extractAll) : null;
    return sendRequest(kind, offset, length, options, false);
  }

  Future<Response> sendStringRequest(
      String search, String name, bool extractAll) {
    var offset = findOffset(search);
    var length = search.length;
    return sendExtractRequest(offset, length, name, extractAll);
  }

  Future<Response> sendStringSuffixRequest(
      String search, String suffix, String name, bool extractAll) {
    var offset = findOffset(search + suffix);
    var length = search.length;
    return sendExtractRequest(offset, length, name, extractAll);
  }

  @override
  void tearDown() {
    test_simulateRefactoringException_init = false;
    test_simulateRefactoringException_final = false;
    test_simulateRefactoringException_change = false;
    super.tearDown();
  }

  Future<void> test_analysis_onlyOneFile() async {
    shouldWaitForFullAnalysis = false;
    newFile(join(testFolder, 'other.dart'), content: r'''
foo(int myName) {}
''');
    addTestFile('''
import 'other.dart';
main() {
  foo(1 + 2);
}
''');
    // Start refactoring.
    var result = await getRefactoringResult(() {
      return sendStringRequest('1 + 2', 'res', true);
    });
    // We get the refactoring feedback....
    ExtractLocalVariableFeedback feedback = result.feedback;
    expect(feedback.names, contains('myName'));
  }

  Future<void> test_coveringExpressions() {
    addTestFile('''
main() {
  var v = 111 + 222 + 333;
}
''');
    return getRefactoringResult(() {
      return sendExtractRequest(testCode.indexOf('222 +'), 0, 'res', true);
    }).then((result) {
      ExtractLocalVariableFeedback feedback = result.feedback;
      expect(feedback.coveringExpressionOffsets, [
        testCode.indexOf('222 +'),
        testCode.indexOf('111 +'),
        testCode.indexOf('111 +')
      ]);
      expect(feedback.coveringExpressionLengths,
          ['222'.length, '111 + 222'.length, '111 + 222 + 333'.length]);
    });
  }

  Future<void> test_extractAll() {
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

  Future<void> test_extractOne() {
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

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request = EditGetRefactoringParams(
            RefactoringKind.EXTRACT_LOCAL_VARIABLE, 'test.dart', 0, 0, true)
        .toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request = EditGetRefactoringParams(
            RefactoringKind.EXTRACT_LOCAL_VARIABLE,
            convertPath('/foo/../bar/test.dart'),
            0,
            0,
            true)
        .toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_names() async {
    addTestFile('''
class TreeItem {}
TreeItem getSelectedItem() => null;
main() {
  var a = getSelectedItem();
}
''');
    var result = await getRefactoringResult(() {
      return sendStringSuffixRequest('getSelectedItem()', ';', null, true);
    });
    ExtractLocalVariableFeedback feedback = result.feedback;
    expect(
        feedback.names, unorderedEquals(['treeItem', 'item', 'selectedItem']));
    expect(result.change, isNull);
  }

  Future<void> test_nameWarning() async {
    addTestFile('''
main() {
  print(1 + 2);
}
''');
    var result = await getRefactoringResult(() {
      return sendStringRequest('1 + 2', 'Name', true);
    });
    assertResultProblemsWarning(result.optionsProblems,
        'Variable name should start with a lowercase letter.');
    // ...but there is still a change
    assertTestRefactoringResult(result, '''
main() {
  var Name = 1 + 2;
  print(Name);
}
''');
  }

  Future<void> test_offsetsLengths() {
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

  Future<void> test_resetOnAnalysisSetChanged_overlay() async {
    addTestFile('''
main() {
  print(1 + 2); // 0
}
''');

    Future<void> checkUpdate(void Function() doUpdate) async {
      await getRefactoringResult(() {
        return sendStringRequest('1 + 2', 'res', true);
      });
      var initialResetCount = test_resetCount;
      doUpdate();
      await pumpEventQueue();
      expect(test_resetCount, initialResetCount + 1);
    }

    await checkUpdate(() {
      server.updateContent('u1', {
        testFile: AddContentOverlay('''
main() {
  print(1 + 2); // 1
}
''')
      });
    });

    await checkUpdate(() {
      server.updateContent('u2', {
        testFile: ChangeContentOverlay([
          SourceEdit(0, 0, '''
main() {
  print(1 + 2); // 2
}
''')
        ])
      });
    });

    await checkUpdate(() {
      server.updateContent('u3', {testFile: RemoveContentOverlay()});
    });
  }

  Future<void> test_resetOnAnalysisSetChanged_watch_otherFile() async {
    var otherFile = join(testFolder, 'other.dart');
    newFile(otherFile, content: '// other 1');
    addTestFile('''
main() {
  foo(1 + 2);
}
foo(int myName) {}
''');
    // Send the first request.
    {
      var result = await getRefactoringResult(() {
        return sendStringRequest('1 + 2', 'res', true);
      });
      ExtractLocalVariableFeedback feedback = result.feedback;
      expect(feedback.names, contains('myName'));
    }
    var initialResetCount = test_resetCount;
    // Update the other.dart file.
    // The refactoring is reset, even though it's a different file. It is up to
    // analyzer to track dependencies and provide resolved units fast when
    // possible.
    newFile(otherFile, content: '// other 2');
    await pumpEventQueue();
    expect(test_resetCount, initialResetCount + 1);
  }

  Future<void> test_resetOnAnalysisSetChanged_watch_thisFile() async {
    addTestFile('''
main() {
  foo(1 + 2);
}
foo(int myName) {}
''');
    // Send the first request.
    {
      var result = await getRefactoringResult(() {
        return sendStringRequest('1 + 2', 'res', true);
      });
      ExtractLocalVariableFeedback feedback = result.feedback;
      expect(feedback.names, contains('myName'));
    }
    var initialResetCount = test_resetCount;
    // Update the test.dart file.
    modifyTestFile('''
main() {
  foo(1 + 2);
}
foo(int otherName) {}
''');
    // The refactoring was reset.
    await pumpEventQueue();
    expect(test_resetCount, initialResetCount + 1);
    // Send the second request, with the same kind, file and offset.
    {
      var result = await getRefactoringResult(() {
        return sendStringRequest('1 + 2', 'res', true);
      });
      ExtractLocalVariableFeedback feedback = result.feedback;
      // The refactoring was reset, so we don't get stale results.
      expect(feedback.names, contains('otherName'));
    }
  }

  Future<void> test_serverError_change() {
    test_simulateRefactoringException_change = true;
    addTestFile('''
main() {
  print(1 + 2);
}
''');
    return waitForTasksFinished().then((_) {
      return sendStringRequest('1 + 2', 'res', true).then((response) {
        expect(response.error, isNotNull);
        expect(response.error.code, RequestErrorCode.SERVER_ERROR);
      });
    });
  }

  Future<void> test_serverError_final() {
    test_simulateRefactoringException_final = true;
    addTestFile('''
main() {
  print(1 + 2);
}
''');
    return waitForTasksFinished().then((_) {
      return sendStringRequest('1 + 2', 'res', true).then((response) {
        expect(response.error, isNotNull);
        expect(response.error.code, RequestErrorCode.SERVER_ERROR);
      });
    });
  }

  Future<void> test_serverError_init() {
    test_simulateRefactoringException_init = true;
    addTestFile('''
main() {
  print(1 + 2);
}
''');
    return waitForTasksFinished().then((_) {
      return sendStringRequest('1 + 2', 'res', true).then((response) {
        expect(response.error, isNotNull);
        expect(response.error.code, RequestErrorCode.SERVER_ERROR);
      });
    });
  }
}

@reflectiveTest
class ExtractMethodTest extends _AbstractGetRefactoring_Test {
  int offset;
  int length;
  String name = 'res';
  ExtractMethodOptions options;

  Future<void> test_expression() {
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

  Future<void> test_expression_hasParameters() {
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

  Future<void> test_expression_updateParameters() async {
    addTestFile('''
main() {
  int a = 1;
  int b = 2;
  print(a + b);
  print(a + b);
}
''');
    _setOffsetLengthForString('a + b');
    var result = await getRefactoringResult(_computeChange);
    ExtractMethodFeedback feedback = result.feedback;
    var parameters = feedback.parameters;
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
  }

  Future<void> test_init_fatalError_invalidStatement() {
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
      var result = EditGetRefactoringResult.fromResponse(response);
      assertResultProblemsFatal(result.initialProblems);
      // ...there is no any feedback
      expect(result.feedback, isNull);
    });
  }

  Future<void> test_long_expression() {
    addTestFile('''
main() {
  print(1 +
    2);
}
''');
    _setOffsetLengthForString('1 +\n    2');
    return assertSuccessfulRefactoring(_computeChange, '''
main() {
  print(res());
}

int res() {
  return 1 +
  2;
}
''');
  }

  Future<void> test_names() {
    addTestFile('''
class TreeItem {}
TreeItem getSelectedItem() => null;
main() {
  var a = getSelectedItem( );
}
''');
    _setOffsetLengthForString('getSelectedItem( )');
    return _computeInitialFeedback().then((feedback) {
      expect(feedback.names,
          unorderedEquals(['treeItem', 'item', 'selectedItem']));
      expect(feedback.returnType, 'TreeItem');
    });
  }

  Future<void> test_offsetsLengths() {
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

  Future<void> test_statements() {
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

  Future<Response> _computeChange() async {
    await _prepareOptions();
    // send request with the options
    return _sendExtractRequest();
  }

  Future<ExtractMethodFeedback> _computeInitialFeedback() async {
    await waitForTasksFinished();
    var response = await _sendExtractRequest();
    var result = EditGetRefactoringResult.fromResponse(response);
    return result.feedback;
  }

  Future _prepareOptions() {
    return getRefactoringResult(() {
      // get initial feedback
      return _sendExtractRequest();
    }).then((result) {
      assertResultProblemsOK(result);
      // fill options from result
      ExtractMethodFeedback feedback = result.feedback;
      options = ExtractMethodOptions(
          feedback.returnType, false, name, feedback.parameters, true);
      // done
      return Future.value();
    });
  }

  Future<Response> _sendExtractRequest() {
    var kind = RefactoringKind.EXTRACT_METHOD;
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

@reflectiveTest
class GetAvailableRefactoringsTest extends AbstractAnalysisTest {
  List<RefactoringKind> kinds;

  void addFlutterPackage() {
    var libFolder = MockPackages.instance.addFlutter(resourceProvider);
    // Create .packages in the project.
    newFile(join(projectPath, '.packages'), content: '''
flutter:${libFolder.toUri()}
''');
  }

  /// Tests that there is refactoring of the given [kind] is available at the
  /// [search] offset.
  Future assertHasKind(
      String code, String search, RefactoringKind kind, bool expected) async {
    addTestFile(code);
    await waitForTasksFinished();
    await getRefactoringsAtString(search);
    // verify
    var matcher = contains(kind);
    if (!expected) {
      matcher = isNot(matcher);
    }
    expect(kinds, matcher);
  }

  /// Tests that there is a RENAME refactoring available at the [search] offset.
  Future assertHasRenameRefactoring(String code, String search) async {
    return assertHasKind(code, search, RefactoringKind.RENAME, true);
  }

  /// Returns the list of available refactorings for the given [offset] and
  /// [length].
  Future getRefactorings(int offset, int length) async {
    var request = EditGetAvailableRefactoringsParams(testFile, offset, length)
        .toRequest('0');
    serverChannel.sendRequest(request);
    var response = await serverChannel.waitForResponse(request);
    var result = EditGetAvailableRefactoringsResult.fromResponse(response);
    kinds = result.kinds;
  }

  /// Returns the list of available refactorings at the offset of [search].
  Future getRefactoringsAtString(String search) {
    var offset = findOffset(search);
    return getRefactorings(offset, 0);
  }

  Future getRefactoringsForString(String search) {
    var offset = findOffset(search);
    return getRefactorings(offset, search.length);
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
    handler = EditDomainHandler(server);
    server.handlers = [handler];
  }

  Future test_convertMethodToGetter_hasElement() {
    return assertHasKind('''
int getValue() => 42;
''', 'getValue', RefactoringKind.CONVERT_METHOD_TO_GETTER, true);
  }

  Future test_extractLocal() async {
    addTestFile('''
main() {
  var a = 1 + 2;
}
''');
    await waitForTasksFinished();
    await getRefactoringsForString('1 + 2');
    expect(kinds, contains(RefactoringKind.EXTRACT_LOCAL_VARIABLE));
    expect(kinds, contains(RefactoringKind.EXTRACT_METHOD));
  }

  Future test_extractLocal_withoutSelection() async {
    addTestFile('''
main() {
  var a = 1 + 2;
}
''');
    await waitForTasksFinished();
    await getRefactoringsAtString('1 + 2');
    expect(kinds, contains(RefactoringKind.EXTRACT_LOCAL_VARIABLE));
    expect(kinds, contains(RefactoringKind.EXTRACT_METHOD));
  }

  Future test_extractWidget() async {
    addFlutterPackage();
    addTestFile('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Text('AAA');
  }
}
''');
    await waitForTasksFinished();
    await getRefactoringsForString('new Text');
    expect(kinds, contains(RefactoringKind.EXTRACT_WIDGET));
  }

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request =
        EditGetAvailableRefactoringsParams('test.dart', 0, 0).toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request = EditGetAvailableRefactoringsParams(
            convertPath('/foo/../bar/test.dart'), 0, 0)
        .toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
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
  test.pi;
}
''', 'test.pi;');
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

  Future test_rename_noElement() async {
    addTestFile('''
main() {
  // not an element
}
''');
    await waitForTasksFinished();
    await getRefactoringsAtString('// not an element');
    expect(kinds, isNot(contains(RefactoringKind.RENAME)));
  }
}

@reflectiveTest
class InlineLocalTest extends _AbstractGetRefactoring_Test {
  Future<void> test_analysis_onlyOneFile() async {
    shouldWaitForFullAnalysis = false;
    var otherFile = join(testFolder, 'other.dart');
    newFile(otherFile, content: r'''
foo(int p) {}
''');
    addTestFile('''
import 'other.dart';
main() {
  int res = 1 + 2;
  foo(res);
  foo(res);
}
''');
    // Start refactoring.
    var result = await getRefactoringResult(() {
      return _sendInlineRequest('res =');
    });
    // We get the refactoring feedback....
    InlineLocalVariableFeedback feedback = result.feedback;
    expect(feedback.occurrences, 2);
  }

  Future<void> test_feedback() {
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

  Future<void> test_init_fatalError_notVariable() {
    addTestFile('main() {}');
    return getRefactoringResult(() {
      return _sendInlineRequest('main() {}');
    }).then((result) {
      assertResultProblemsFatal(result.initialProblems,
          'Local variable declaration or reference must be selected to activate this refactoring.');
      // ...there is no any change
      expect(result.change, isNull);
    });
  }

  Future<void> test_OK() {
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

  Future<void> test_resetOnAnalysisSetChanged() async {
    newFile(join(testFolder, 'other.dart'), content: '// other 1');
    addTestFile('''
main() {
  int res = 1 + 2;
  print(res);
}
''');
    // Send the first request.
    await getRefactoringResult(() {
      return _sendInlineRequest('res = ');
    });
    var initialResetCount = test_resetCount;
    // Update the test.dart file.
    modifyTestFile('''
main() {
  print(1 + 2);
}
''');
    // The refactoring was reset.
    await pumpEventQueue();
    expect(test_resetCount, initialResetCount + 1);
  }

  Future<Response> _sendInlineRequest(String search) {
    var request = EditGetRefactoringParams(
            RefactoringKind.INLINE_LOCAL_VARIABLE,
            testFile,
            findOffset(search),
            0,
            false)
        .toRequest('0');
    return serverChannel.sendRequest(request);
  }
}

@reflectiveTest
class InlineMethodTest extends _AbstractGetRefactoring_Test {
  InlineMethodOptions options = InlineMethodOptions(true, true);

  Future<void> test_feedback() {
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

  Future<void> test_init_fatalError_noMethod() {
    addTestFile('// nothing to inline');
    return getRefactoringResult(() {
      return _sendInlineRequest('// nothing');
    }).then((result) {
      assertResultProblemsFatal(result.initialProblems,
          'Method declaration or reference must be selected to activate this refactoring.');
      // ...there is no any change
      expect(result.change, isNull);
    });
  }

  Future<void> test_method() {
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

  Future<void> test_topLevelFunction() {
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

  Future<void> test_topLevelFunction_oneInvocation() {
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
    var request = EditGetRefactoringParams(RefactoringKind.INLINE_METHOD,
            testFile, findOffset(search), 0, false,
            options: options)
        .toRequest('0');
    return serverChannel.sendRequest(request);
  }
}

@reflectiveTest
class MoveFileTest extends _AbstractGetRefactoring_Test {
  MoveFileOptions options;

  @failingTest
  Future<void> test_OK() {
    _fail('The move file refactoring is not supported under the new driver');
    newFile('/project/bin/lib.dart');
    addTestFile('''
import 'dart:math';
import 'lib.dart';
''');
    _setOptions('/project/test.dart');
    return assertSuccessfulRefactoring(() {
      return _sendMoveRequest();
    }, '''
import 'dart:math';
import 'bin/lib.dart';
''');
  }

  Future<Response> _sendMoveRequest() {
    var request = EditGetRefactoringParams(
            RefactoringKind.MOVE_FILE, testFile, 0, 0, false,
            options: options)
        .toRequest('0');
    return serverChannel.sendRequest(request);
  }

  void _setOptions(String newFile) {
    options = MoveFileOptions(newFile);
  }
}

@reflectiveTest
class RenameTest extends _AbstractGetRefactoring_Test {
  Future<Response> sendRenameRequest(String search, String newName,
      {String id = '0', bool validateOnly = false}) {
    var options = newName != null ? RenameOptions(newName) : null;
    var request = EditGetRefactoringParams(RefactoringKind.RENAME, testFile,
            findOffset(search), 0, validateOnly,
            options: options)
        .toRequest(id);
    return serverChannel.sendRequest(request);
  }

  @override
  void tearDown() {
    test_simulateRefactoringReset_afterInitialConditions = false;
    test_simulateRefactoringReset_afterFinalConditions = false;
    test_simulateRefactoringReset_afterCreateChange = false;
    super.tearDown();
  }

  Future<void> test_cancelPendingRequest() async {
    addTestFile('''
main() {
  int test = 0;
  print(test);
}
''');
    // send the "1" request, but don't wait for it
    var futureA = sendRenameRequest('test =', 'nameA', id: '1');
    // send the "2" request and wait for it
    var responseB = await sendRenameRequest('test =', 'nameB', id: '2');
    // wait for the (delayed) "1" response
    var responseA = await futureA;
    // "1" was cancelled
    // "2" is successful
    expect(responseA,
        isResponseFailure('1', RequestErrorCode.REFACTORING_REQUEST_CANCELLED));
    expect(responseB, isResponseSuccess('2'));
  }

  Future<void> test_class() {
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

  Future<void> test_class_fromFactoryRedirectingConstructor() {
    addTestFile('''
class A {
  A() = Test.named;
}
class Test {
  Test.named() {}
}
''');
    return assertSuccessfulRefactoring(
      () {
        return sendRenameRequest('Test.named;', 'NewName');
      },
      '''
class A {
  A() = NewName.named;
}
class NewName {
  NewName.named() {}
}
''',
      feedbackValidator: (feedback) {
        RenameFeedback renameFeedback = feedback;
        expect(renameFeedback.offset, 18);
        expect(renameFeedback.length, 4);
      },
    );
  }

  Future<void> test_class_fromInstanceCreation() {
    addTestFile('''
class Test {
  Test() {}
}
main() {
  new Test();
}
''');
    return assertSuccessfulRefactoring(
      () {
        return sendRenameRequest('Test();', 'NewName');
      },
      '''
class NewName {
  NewName() {}
}
main() {
  new NewName();
}
''',
      feedbackValidator: (feedback) {
        RenameFeedback renameFeedback = feedback;
        expect(renameFeedback.offset, 42);
        expect(renameFeedback.length, 4);
      },
    );
  }

  Future<void> test_class_fromInstanceCreation_namedConstructor() {
    addTestFile('''
class Test {
  Test.named() {}
}
main() {
  new Test.named();
}
''');
    return assertSuccessfulRefactoring(
      () {
        return sendRenameRequest('Test.named();', 'NewName');
      },
      '''
class NewName {
  NewName.named() {}
}
main() {
  new NewName.named();
}
''',
      feedbackValidator: (feedback) {
        RenameFeedback renameFeedback = feedback;
        expect(renameFeedback.offset, 48);
        expect(renameFeedback.length, 4);
      },
    );
  }

  Future<void> test_class_fromInstanceCreation_onNew() {
    addTestFile('''
class Test {
  Test() {}
}
main() {
  new Test();
}
''');
    return assertSuccessfulRefactoring(
      () {
        return sendRenameRequest('new Test();', 'NewName');
      },
      '''
class NewName {
  NewName() {}
}
main() {
  new NewName();
}
''',
      feedbackValidator: (feedback) {
        RenameFeedback renameFeedback = feedback;
        expect(renameFeedback.offset, 42);
        expect(renameFeedback.length, 4);
      },
    );
  }

  Future<void> test_class_fromInstanceCreation_onNew_namedConstructor() {
    addTestFile('''
class Test {
  Test.named() {}
}
main() {
  new Test.named();
}
''');
    return assertSuccessfulRefactoring(
      () {
        return sendRenameRequest('new Test.named();', 'NewName');
      },
      '''
class NewName {
  NewName.named() {}
}
main() {
  new NewName.named();
}
''',
      feedbackValidator: (feedback) {
        RenameFeedback renameFeedback = feedback;
        expect(renameFeedback.offset, 48);
        expect(renameFeedback.length, 4);
      },
    );
  }

  Future<void> test_class_options_fatalError() {
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
          result.optionsProblems, 'Class name must not be empty.');
      // ...there is no any change
      expect(result.change, isNull);
    });
  }

  Future<void> test_class_validateOnly() {
    addTestFile('''
class Test {}
main() {
  Test v;
}
''');
    return getRefactoringResult(() {
      return sendRenameRequest('Test {}', 'NewName', validateOnly: true);
    }).then((result) {
      RenameFeedback feedback = result.feedback;
      assertResultProblemsOK(result);
      expect(feedback.elementKindName, 'class');
      expect(feedback.oldName, 'Test');
      expect(result.change, isNull);
    });
  }

  Future<void> test_class_warning() {
    addTestFile('''
class Test {}
main() {
  Test v;
}
''');
    return getRefactoringResult(() {
      return sendRenameRequest('Test {}', 'newName');
    }).then((result) {
      assertResultProblemsWarning(result.optionsProblems,
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

  Future<void> test_classMember_field() {
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

  Future<void> test_classMember_field_onFieldFormalParameter() {
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

  Future<void> test_classMember_field_onFieldFormalParameter_named() {
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

  Future<void> test_classMember_getter() {
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

  Future<void> test_classMember_method() {
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

  Future<void> test_classMember_method_potential() {
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
      var potentialIds = result.potentialEdits;
      expect(potentialIds, hasLength(1));
      var potentialId = potentialIds[0];
      // find potential edit
      var change = result.change;
      var potentialEdit = _findEditWithId(change, potentialId);
      expect(potentialEdit, isNotNull);
      expect(potentialEdit.offset, findOffset('test(); // a2'));
      expect(potentialEdit.length, 4);
    });
  }

  Future<void> test_classMember_setter() {
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

  Future<void> test_constructor_fromFactoryRedirectingConstructor() {
    addTestFile('''
class A {
  A() = B.test;
}
class B {
  B.test() {}
}
''');
    return assertSuccessfulRefactoring(
      () {
        return sendRenameRequest('test;', 'newName');
      },
      '''
class A {
  A() = B.newName;
}
class B {
  B.newName() {}
}
''',
      feedbackValidator: (feedback) {
        RenameFeedback renameFeedback = feedback;
        expect(renameFeedback.offset, 20);
        expect(renameFeedback.length, 4);
      },
    );
  }

  Future<void> test_constructor_fromInstanceCreation() {
    addTestFile('''
class A {
  A.test() {}
}
main() {
  new A.test();
}
''');
    return assertSuccessfulRefactoring(
      () {
        return sendRenameRequest('test();', 'newName');
      },
      '''
class A {
  A.newName() {}
}
main() {
  new A.newName();
}
''',
      feedbackValidator: (feedback) {
        RenameFeedback renameFeedback = feedback;
        expect(renameFeedback.offset, 43);
        expect(renameFeedback.length, 4);
      },
    );
  }

  Future<void> test_feedback() {
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

  Future<void> test_formalParameter_named_ofConstructor_genericClass() {
    addTestFile('''
class A<T> {
  A({T test});
}

main() {
  A(test: 0);
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test: 0', 'newName');
    }, '''
class A<T> {
  A({T newName});
}

main() {
  A(newName: 0);
}
''');
  }

  Future<void> test_formalParameter_named_ofMethod_genericClass() {
    addTestFile('''
class A<T> {
  void foo({T test}) {}
}

main(A<int> a) {
  a.foo(test: 0);
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test: 0', 'newName');
    }, '''
class A<T> {
  void foo({T newName}) {}
}

main(A<int> a) {
  a.foo(newName: 0);
}
''');
  }

  Future<void> test_function() {
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

  Future<void> test_importPrefix_add() {
    addTestFile('''
import 'dart:math';
import 'dart:async';
main() {
  Random r;
  Future f;
}
''');
    return assertSuccessfulRefactoring(
        () {
          return sendRenameRequest("import 'dart:async';", 'new_name');
        },
        '''
import 'dart:math';
import 'dart:async' as new_name;
main() {
  Random r;
  new_name.Future f;
}
''',
        feedbackValidator: (feedback) {
          RenameFeedback renameFeedback = feedback;
          expect(renameFeedback.offset, -1);
          expect(renameFeedback.length, 0);
        });
  }

  Future<void> test_importPrefix_remove() {
    addTestFile('''
import 'dart:math' as test;
import 'dart:async' as test;
main() {
  test.Random r;
  test.Future f;
}
''');
    return assertSuccessfulRefactoring(
        () {
          return sendRenameRequest("import 'dart:async' as test;", '');
        },
        '''
import 'dart:math' as test;
import 'dart:async';
main() {
  test.Random r;
  Future f;
}
''',
        feedbackValidator: (feedback) {
          RenameFeedback renameFeedback = feedback;
          expect(renameFeedback.offset, 51);
          expect(renameFeedback.length, 4);
        });
  }

  Future<void> test_init_fatalError_noElement() {
    addTestFile('// nothing to rename');
    return getRefactoringResult(() {
      return sendRenameRequest('// nothing', null);
    }).then((result) {
      assertResultProblemsFatal(
          result.initialProblems, 'Unable to create a refactoring');
      // ...there is no any change
      expect(result.change, isNull);
    });
  }

  Future<void> test_library_libraryDirective() {
    addTestFile('''
library aaa.bbb.ccc;
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('library aaa', 'my.new_name');
    }, '''
library my.new_name;
''');
  }

  Future<void> test_library_libraryDirective_name() {
    addTestFile('''
library aaa.bbb.ccc;
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('aaa', 'my.new_name');
    }, '''
library my.new_name;
''');
  }

  Future<void> test_library_libraryDirective_nameDot() {
    addTestFile('''
library aaa.bbb.ccc;
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('.bbb', 'my.new_name');
    }, '''
library my.new_name;
''');
  }

  Future<void> test_library_partOfDirective() {
    newFile(join(testFolder, 'my_lib.dart'), content: '''
library aaa.bbb.ccc;
part 'test.dart';
''');
    addTestFile('''
part of aaa.bbb.ccc;
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('aaa.bb', 'my.new_name');
    }, '''
part of my.new_name;
''');
  }

  Future<void> test_localVariable() {
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

  Future<void> test_localVariable_finalCheck_shadowError() {
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
      var problems = result.finalProblems;
      expect(problems, hasLength(1));
      assertResultProblemsError(
          problems, "Duplicate local variable 'newName'.");
    });
  }

  Future<void> test_reset_afterCreateChange() {
    test_simulateRefactoringReset_afterCreateChange = true;
    addTestFile('''
test() {}
main() {
  test();
}
''');
    return waitForTasksFinished().then((_) {
      return sendRenameRequest('test() {}', 'newName').then((response) {
        _expectRefactoringRequestCancelled(response);
      });
    });
  }

  Future<void> test_reset_afterFinalConditions() {
    test_simulateRefactoringReset_afterFinalConditions = true;
    addTestFile('''
test() {}
main() {
  test();
}
''');
    return waitForTasksFinished().then((_) {
      return sendRenameRequest('test() {}', 'newName').then((response) {
        _expectRefactoringRequestCancelled(response);
      });
    });
  }

  Future<void> test_reset_afterInitialConditions() {
    test_simulateRefactoringReset_afterInitialConditions = true;
    addTestFile('''
test() {}
main() {
  test();
}
''');
    return waitForTasksFinished().then((_) {
      return sendRenameRequest('test() {}', 'newName').then((response) {
        _expectRefactoringRequestCancelled(response);
      });
    });
  }

  Future<void> test_resetOnAnalysis() async {
    addTestFile('''
main() {
  int initialName = 0;
  print(initialName);
}
''');
    // send the first request
    var result = await getRefactoringResult(() {
      return sendRenameRequest('initialName =', 'newName', validateOnly: true);
    });
    _validateFeedback(result, oldName: 'initialName');
    // update the file
    modifyTestFile('''
main() {
  int otherName = 0;
  print(otherName);
}
''');
    server.getAnalysisDriver(testFile).getResult(testFile);
    // send the second request, with the same kind, file and offset
    await waitForTasksFinished();
    result = await getRefactoringResult(() {
      return sendRenameRequest('otherName =', 'newName', validateOnly: true);
    });
    // the refactoring was reset, so we don't get a stale result
    _validateFeedback(result, oldName: 'otherName');
  }

  void _expectRefactoringRequestCancelled(Response response) {
    expect(response.error, isNotNull);
    expect(response,
        isResponseFailure('0', RequestErrorCode.REFACTORING_REQUEST_CANCELLED));
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

  void _validateFeedback(EditGetRefactoringResult result, {String oldName}) {
    RenameFeedback feedback = result.feedback;
    expect(feedback, isNotNull);
    if (oldName != null) {
      expect(feedback.oldName, oldName);
    }
  }
}

@reflectiveTest
class _AbstractGetRefactoring_Test extends AbstractAnalysisTest {
  bool shouldWaitForFullAnalysis = true;

  /// Asserts that [problems] has a single ERROR problem.
  void assertResultProblemsError(List<RefactoringProblem> problems,
      [String message]) {
    var problem = problems[0];
    expect(problem.severity, RefactoringProblemSeverity.ERROR,
        reason: problem.toString());
    if (message != null) {
      expect(problem.message, message);
    }
  }

  /// Asserts that [result] has a single FATAL problem.
  void assertResultProblemsFatal(List<RefactoringProblem> problems,
      [String message]) {
    var problem = problems[0];
    expect(problems, hasLength(1));
    expect(problem.severity, RefactoringProblemSeverity.FATAL,
        reason: problem.toString());
    if (message != null) {
      expect(problem.message, message);
    }
  }

  /// Asserts that [result] has no problems at all.
  void assertResultProblemsOK(EditGetRefactoringResult result) {
    expect(result.initialProblems, isEmpty);
    expect(result.optionsProblems, isEmpty);
    expect(result.finalProblems, isEmpty);
  }

  /// Asserts that [result] has a single WARNING problem.
  void assertResultProblemsWarning(List<RefactoringProblem> problems,
      [String message]) {
    var problem = problems[0];
    expect(problems, hasLength(1));
    expect(problem.severity, RefactoringProblemSeverity.WARNING,
        reason: problem.toString());
    if (message != null) {
      expect(problem.message, message);
    }
  }

  Future assertSuccessfulRefactoring(
      Future<Response> Function() requestSender, String expectedCode,
      {void Function(RefactoringFeedback) feedbackValidator}) async {
    var result = await getRefactoringResult(requestSender);
    assertResultProblemsOK(result);
    if (feedbackValidator != null) {
      feedbackValidator(result.feedback);
    }
    assertTestRefactoringResult(result, expectedCode);
  }

  /// Asserts that the given [EditGetRefactoringResult] has a [testFile] change
  /// which results in the [expectedCode].
  void assertTestRefactoringResult(
      EditGetRefactoringResult result, String expectedCode) {
    var change = result.change;
    expect(change, isNotNull);
    for (var fileEdit in change.edits) {
      if (fileEdit.file == testFile) {
        var actualCode = SourceEdit.applySequence(testCode, fileEdit.edits);
        expect(actualCode, expectedCode);
        return;
      }
    }
    fail('No SourceFileEdit for $testFile in $change');
  }

  Future<EditGetRefactoringResult> getRefactoringResult(
      Future<Response> Function() requestSender) async {
    if (shouldWaitForFullAnalysis) {
      await waitForTasksFinished();
    }
    var response = await requestSender();
    return EditGetRefactoringResult.fromResponse(response);
  }

  Future<Response> sendRequest(
      RefactoringKind kind, int offset, int length, RefactoringOptions options,
      [bool validateOnly = false]) {
    var request = EditGetRefactoringParams(
            kind, testFile, offset, length, validateOnly,
            options: options)
        .toRequest('0');
    return serverChannel.sendRequest(request);
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
    handler = EditDomainHandler(server);
    server.handlers = [handler];
  }
}
