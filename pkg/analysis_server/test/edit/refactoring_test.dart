// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring_manager.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';
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

@reflectiveTest
class ConvertGetterMethodToMethodTest extends _AbstractGetRefactoring_Test {
  Future<void> test_function() {
    addTestFile('''
int get test => 42;
void f() {
  var a = 1 + test;
  var b = 2 + test;
}
''');
    return assertSuccessfulRefactoring(() {
      return _sendConvertRequest('test =>');
    }, '''
int test() => 42;
void f() {
  var a = 1 + test();
  var b = 2 + test();
}
''');
  }

  Future<void> test_init_fatalError_notExplicit() {
    addTestFile('''
int test = 42;
void f() {
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
void f(A a, B b, C c, D d) {
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
void f(A a, B b, C c, D d) {
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
            testFile.path,
            findOffset(search),
            0,
            false)
        .toRequest('0');
    return serverChannel.simulateRequestFromClient(request);
  }
}

@reflectiveTest
class ConvertMethodToGetterTest extends _AbstractGetRefactoring_Test {
  Future<void> test_function() {
    addTestFile('''
int test() => 42;
void f() {
  var a = 1 + test();
  var b = 2 + test();
}
''');
    return assertSuccessfulRefactoring(() {
      return _sendConvertRequest('test() =>');
    }, '''
int get test => 42;
void f() {
  var a = 1 + test;
  var b = 2 + test;
}
''');
  }

  Future<void> test_init_fatalError_hasParameters() {
    addTestFile('''
int test(p) => p + 1;
void f() {
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
void f() {
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
void f(A a, B b, C c, D d) {
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
void f(A a, B b, C c, D d) {
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
            testFile.path,
            findOffset(search),
            0,
            false)
        .toRequest('0');
    return serverChannel.simulateRequestFromClient(request);
  }
}

@reflectiveTest
class ExtractLocalVariableTest extends _AbstractGetRefactoring_Test {
  Future<Response> sendExtractRequest(
      int offset, int length, String? name, bool extractAll) {
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
      String search, String suffix, String? name, bool extractAll) {
    var offset = findOffset(search + suffix);
    var length = search.length;
    return sendExtractRequest(offset, length, name, extractAll);
  }

  @override
  Future<void> tearDown() async {
    test_simulateRefactoringException_init = false;
    test_simulateRefactoringException_final = false;
    test_simulateRefactoringException_change = false;
    await super.tearDown();
  }

  Future<void> test_analysis_onlyOneFile() async {
    shouldWaitForFullAnalysis = false;
    newFile('$testPackageLibPath/other.dart', r'''
foo(int myName) {}
''');
    addTestFile('''
import 'other.dart';
void f() {
  foo(1 + 2);
}
''');
    // Start refactoring.
    var result = await getRefactoringResult(() {
      return sendStringRequest('1 + 2', 'res', true);
    });
    // We get the refactoring feedback....
    var feedback = result.feedback as ExtractLocalVariableFeedback;
    expect(feedback.names, contains('myName'));
  }

  Future<void> test_coveringExpressions() {
    addTestFile('''
void f() {
  var v = 111 + 222 + 333;
}
''');
    return getRefactoringResult(() {
      return sendExtractRequest(
          testFileContent.indexOf('222 +'), 0, 'res', true);
    }).then((result) {
      var feedback = result.feedback as ExtractLocalVariableFeedback;
      expect(feedback.coveringExpressionOffsets, [
        testFileContent.indexOf('222 +'),
        testFileContent.indexOf('111 +'),
        testFileContent.indexOf('111 +')
      ]);
      expect(feedback.coveringExpressionLengths,
          ['222'.length, '111 + 222'.length, '111 + 222 + 333'.length]);
    });
  }

  Future<void> test_extractAll() {
    addTestFile('''
void f() {
  print(1 + 2);
  print(1 + 2);
}
''');
    return assertSuccessfulRefactoring(() {
      return sendStringRequest('1 + 2', 'res', true);
    }, '''
void f() {
  var res = 1 + 2;
  print(res);
  print(res);
}
''');
  }

  Future<void> test_extractOne() {
    addTestFile('''
void f() {
  print(1 + 2);
  print(1 + 2); // marker
}
''');
    return assertSuccessfulRefactoring(() {
      return sendStringSuffixRequest('1 + 2', '); // marker', 'res', false);
    }, '''
void f() {
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
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
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
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_names() async {
    addTestFile('''
class TreeItem {}
TreeItem getSelectedItem() => null;
void f() {
  var a = getSelectedItem();
}
''');
    var result = await getRefactoringResult(() {
      return sendStringSuffixRequest('getSelectedItem()', ';', null, true);
    });
    var feedback = result.feedback as ExtractLocalVariableFeedback;
    expect(
        feedback.names, unorderedEquals(['treeItem', 'item', 'selectedItem']));
    expect(result.change, isNull);
  }

  Future<void> test_nameWarning() async {
    addTestFile('''
void f() {
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
void f() {
  var Name = 1 + 2;
  print(Name);
}
''');
  }

  Future<void> test_offsetsLengths() {
    addTestFile('''
void f() {
  print(1 + 2);
  print(1 +  2);
}
''');
    return getRefactoringResult(() {
      return sendStringRequest('1 + 2', 'res', true);
    }).then((result) {
      var feedback = result.feedback as ExtractLocalVariableFeedback;
      expect(feedback.offsets, [findOffset('1 + 2'), findOffset('1 +  2')]);
      expect(feedback.lengths, [5, 6]);
    });
  }

  Future<void> test_resetOnAnalysisSetChanged_overlay() async {
    addTestFile('''
void f() {
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
        testFile.path: AddContentOverlay('''
void f() {
  print(1 + 2); // 1
}
''')
      });
    });

    await checkUpdate(() {
      server.updateContent('u2', {
        testFile.path: ChangeContentOverlay([
          SourceEdit(0, 0, '''
void f() {
  print(1 + 2); // 2
}
''')
        ])
      });
    });

    await checkUpdate(() {
      server.updateContent('u3', {testFile.path: RemoveContentOverlay()});
    });
  }

  Future<void> test_resetOnAnalysisSetChanged_watch_otherFile() async {
    var otherFile = join('$testPackageLibPath/other.dart');
    newFile(otherFile, '// other 1');
    addTestFile('''
void f() {
  foo(1 + 2);
}
foo(int myName) {}
''');
    // Send the first request.
    {
      var result = await getRefactoringResult(() {
        return sendStringRequest('1 + 2', 'res', true);
      });
      var feedback = result.feedback as ExtractLocalVariableFeedback;
      expect(feedback.names, contains('myName'));
    }
    var initialResetCount = test_resetCount;
    // Update the other.dart file.
    // The refactoring is reset, even though it's a different file. It is up to
    // analyzer to track dependencies and provide resolved units fast when
    // possible.
    newFile(otherFile, '// other 2');
    await pumpEventQueue();
    expect(test_resetCount, initialResetCount + 1);
  }

  Future<void> test_resetOnAnalysisSetChanged_watch_thisFile() async {
    addTestFile('''
void f() {
  foo(1 + 2);
}
foo(int myName) {}
''');
    // Send the first request.
    {
      var result = await getRefactoringResult(() {
        return sendStringRequest('1 + 2', 'res', true);
      });
      var feedback = result.feedback as ExtractLocalVariableFeedback;
      expect(feedback.names, contains('myName'));
    }
    var initialResetCount = test_resetCount;
    // Update the test.dart file.
    modifyTestFile('''
void f() {
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
      var feedback = result.feedback as ExtractLocalVariableFeedback;
      // The refactoring was reset, so we don't get stale results.
      expect(feedback.names, contains('otherName'));
    }
  }

  Future<void> test_serverError_change() {
    test_simulateRefactoringException_change = true;
    addTestFile('''
void f() {
  print(1 + 2);
}
''');
    return waitForTasksFinished().then((_) {
      return sendStringRequest('1 + 2', 'res', true).then((response) {
        var error = response.error!;
        expect(error.code, RequestErrorCode.SERVER_ERROR);
      });
    });
  }

  Future<void> test_serverError_final() {
    test_simulateRefactoringException_final = true;
    addTestFile('''
void f() {
  print(1 + 2);
}
''');
    return waitForTasksFinished().then((_) {
      return sendStringRequest('1 + 2', 'res', true).then((response) {
        var error = response.error!;
        expect(error.code, RequestErrorCode.SERVER_ERROR);
      });
    });
  }

  Future<void> test_serverError_init() {
    test_simulateRefactoringException_init = true;
    addTestFile('''
void f() {
  print(1 + 2);
}
''');
    return waitForTasksFinished().then((_) {
      return sendStringRequest('1 + 2', 'res', true).then((response) {
        var error = response.error!;
        expect(error.code, RequestErrorCode.SERVER_ERROR);
      });
    });
  }
}

@reflectiveTest
class ExtractMethodTest extends _AbstractGetRefactoring_Test {
  late int offset;
  late int length;
  String name = 'res';
  ExtractMethodOptions? options;

  Future<void> test_expression() {
    addTestFile('''
void f() {
  print(1 + 2);
  print(1 + 2);
}
''');
    _setOffsetLengthForString('1 + 2');
    return assertSuccessfulRefactoring(_computeChange, '''
void f() {
  print(res());
  print(res());
}

int res() => 1 + 2;
''');
  }

  Future<void> test_expression_hasParameters() {
    addTestFile('''
void f() {
  int a = 1;
  int b = 2;
  print(a + b);
  print(a +  b);
}
''');
    _setOffsetLengthForString('a + b');
    return assertSuccessfulRefactoring(_computeChange, '''
void f() {
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
void f() {
  int a = 1;
  int b = 2;
  print(a + b);
  print(a + b);
}
''');
    _setOffsetLengthForString('a + b');
    var result = await getRefactoringResult(_computeChange);
    var feedback = result.feedback as ExtractMethodFeedback;
    var parameters = feedback.parameters;
    parameters[0].name = 'aaa';
    parameters[1].name = 'bbb';
    parameters[1].type = 'num';
    parameters.insert(0, parameters.removeLast());
    options!.parameters = parameters;
    return assertSuccessfulRefactoring(_sendExtractRequest, '''
void f() {
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
void f(bool b) {
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
void f() {
  print(1 +
    2);
}
''');
    _setOffsetLengthForString('1 +\n    2');
    return assertSuccessfulRefactoring(_computeChange, '''
void f() {
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
void f() {
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
void f() {
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
void f() {
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
void f() {
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

  Future<void> test_statements_nullableReturnType() {
    addTestFile('''
void foo(int b) {
// start
  int? x;
  if (b < 2) {
    x = 42;
  }
  if (b >= 2) {
    x = 43;
  }
// end
  print(x!);
}
''');
    _setOffsetLengthForStartEnd();
    return assertSuccessfulRefactoring(_computeChange, '''
void foo(int b) {
// start
  int? x = res(b);
// end
  print(x!);
}

int? res(int b) {
  int? x;
  if (b < 2) {
    x = 42;
  }
  if (b >= 2) {
    x = 43;
  }
  return x;
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
    return result.feedback as ExtractMethodFeedback;
  }

  Future<void> _prepareOptions() {
    return getRefactoringResult(() {
      // get initial feedback
      return _sendExtractRequest();
    }).then((result) {
      assertResultProblemsOK(result);
      // fill options from result
      var feedback = result.feedback as ExtractMethodFeedback;
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
class GetAvailableRefactoringsTest extends PubPackageAnalysisServerTest {
  late List<RefactoringKind> kinds;

  void addFlutterPackage() {
    var flutterLib = MockPackages.instance.addFlutter(resourceProvider);
    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'flutter', rootPath: flutterLib.parent.path),
    );
  }

  /// Tests that there is refactoring of the given [kind] is available at the
  /// [search] offset.
  Future<void> assertHasKind(
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
  Future<void> assertHasRenameRefactoring(String code, String search) async {
    return assertHasKind(code, search, RefactoringKind.RENAME, true);
  }

  /// Returns the list of available refactorings for the given [offset] and
  /// [length].
  Future<void> getRefactorings(int offset, int length) async {
    var request =
        EditGetAvailableRefactoringsParams(testFile.path, offset, length)
            .toRequest('0');
    var response = await serverChannel.simulateRequestFromClient(request);
    var result = EditGetAvailableRefactoringsResult.fromResponse(response);
    kinds = result.kinds;
  }

  /// Returns the list of available refactorings at the offset of [search].
  Future<void> getRefactoringsAtString(String search) {
    var offset = findOffset(search);
    return getRefactorings(offset, 0);
  }

  Future<void> getRefactoringsForString(String search) {
    var offset = findOffset(search);
    return getRefactorings(offset, search.length);
  }

  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<void> test_convertMethodToGetter_hasElement() {
    return assertHasKind('''
int getValue() => 42;
''', 'getValue', RefactoringKind.CONVERT_METHOD_TO_GETTER, true);
  }

  Future<void> test_extractLocal() async {
    addTestFile('''
void f() {
  var a = 1 + 2;
}
''');
    await waitForTasksFinished();
    await getRefactoringsForString('1 + 2');
    expect(kinds, contains(RefactoringKind.EXTRACT_LOCAL_VARIABLE));
    expect(kinds, contains(RefactoringKind.EXTRACT_METHOD));
  }

  Future<void> test_extractLocal_withoutSelection() async {
    addTestFile('''
void f() {
  var a = 1 + 2;
}
''');
    await waitForTasksFinished();
    await getRefactoringsAtString('1 + 2');
    expect(kinds, contains(RefactoringKind.EXTRACT_LOCAL_VARIABLE));
    expect(kinds, contains(RefactoringKind.EXTRACT_METHOD));
  }

  Future<void> test_extractWidget() async {
    addFlutterPackage();
    addTestFile('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('AAA');
  }
}
''');
    await waitForTasksFinished();
    await getRefactoringsForString('Text');
    expect(kinds, contains(RefactoringKind.EXTRACT_WIDGET));
  }

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request =
        EditGetAvailableRefactoringsParams('test.dart', 0, 0).toRequest('0');
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request = EditGetAvailableRefactoringsParams(
            convertPath('/foo/../bar/test.dart'), 0, 0)
        .toRequest('0');
    var response = await handleRequest(request);
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_FILE_PATH_FORMAT,
    );
  }

  Future<void> test_rename_hasElement_class() {
    return assertHasRenameRefactoring('''
class Test {}
void f() {
  Test v;
}
''', 'Test v');
  }

  Future<void> test_rename_hasElement_constructor() {
    return assertHasRenameRefactoring('''
class A {
  A.test() {}
}
void f() {
  A.test();
}
''', 'test();');
  }

  Future<void> test_rename_hasElement_function() {
    return assertHasRenameRefactoring('''
void f() {
  test();
}
test() {}
''', 'test();');
  }

  Future<void> test_rename_hasElement_importElement_directive() {
    return assertHasRenameRefactoring('''
import 'dart:math' as math;
void f() {
  math.PI;
}
''', 'import ');
  }

  Future<void> test_rename_hasElement_importElement_prefixDecl() {
    return assertHasRenameRefactoring('''
import 'dart:math' as math;
void f() {
  math.PI;
}
''', 'math;');
  }

  Future<void> test_rename_hasElement_importElement_prefixRef() {
    return assertHasRenameRefactoring('''
import 'dart:async' as test;
import 'dart:math' as test;
void f() {
  test.pi;
}
''', 'test.pi;');
  }

  Future<void> test_rename_hasElement_instanceGetter() {
    return assertHasRenameRefactoring('''
class A {
  get test => 0;
}
void f(A a) {
  a.test;
}
''', 'test;');
  }

  Future<void> test_rename_hasElement_instanceSetter() {
    return assertHasRenameRefactoring('''
class A {
  set test(x) {}
}
void f(A a) {
  a.test = 2;
}
''', 'test = 2;');
  }

  Future<void> test_rename_hasElement_library() {
    return assertHasRenameRefactoring('''
library my.lib;
''', 'library ');
  }

  Future<void> test_rename_hasElement_localVariable() {
    return assertHasRenameRefactoring('''
void f() {
  int test = 0;
  print(test);
}
''', 'test = 0;');
  }

  Future<void> test_rename_hasElement_localVariable_forEach_statement() {
    return assertHasRenameRefactoring('''
void f(List<int> values) {
  for (final value in values) {
    value;
  }
}
''', 'value in');
  }

  Future<void> test_rename_hasElement_method() {
    return assertHasRenameRefactoring('''
class A {
  test() {}
}
void f(A a) {
  a.test();
}
''', 'test();');
  }

  Future<void> test_rename_hasElement_typeParameter_class() {
    return assertHasRenameRefactoring('''
class A<T> {}
''', 'T> {}');
  }

  Future<void> test_rename_noElement() async {
    addTestFile('''
void f() {
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
    newFile('$testPackageLibPath/other.dart', r'''
foo(int p) {}
''');
    addTestFile('''
import 'other.dart';
void f() {
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
    var feedback = result.feedback as InlineLocalVariableFeedback;
    expect(feedback.occurrences, 2);
  }

  Future<void> test_feedback() {
    addTestFile('''
void f() {
  int test = 42;
  print(test);
  print(test);
}
''');
    return getRefactoringResult(() {
      return _sendInlineRequest('test =');
    }).then((result) {
      var feedback = result.feedback as InlineLocalVariableFeedback;
      expect(feedback.name, 'test');
      expect(feedback.occurrences, 2);
    });
  }

  Future<void> test_init_fatalError_notVariable() {
    addTestFile('void f() {}');
    return getRefactoringResult(() {
      return _sendInlineRequest('void f() {}');
    }).then((result) {
      assertResultProblemsFatal(result.initialProblems,
          'Local variable declaration or reference must be selected to activate this refactoring.');
      // ...there is no any change
      expect(result.change, isNull);
    });
  }

  Future<void> test_OK() {
    addTestFile('''
void f() {
  int test = 42;
  int a = test + 2;
  print(test);
}
''');
    return assertSuccessfulRefactoring(() {
      return _sendInlineRequest('test + 2');
    }, '''
void f() {
  int a = 42 + 2;
  print(42);
}
''');
  }

  Future<void> test_resetOnAnalysisSetChanged() async {
    newFile('$testPackageLibPath/other.dart', '// other 1');
    addTestFile('''
void f() {
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
void f() {
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
            testFile.path,
            findOffset(search),
            0,
            false)
        .toRequest('0');
    return serverChannel.simulateRequestFromClient(request);
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
  void f() {
    test(1);
  }
}
''');
    return getRefactoringResult(() {
      return _sendInlineRequest('test(int p)');
    }).then((result) {
      var feedback = result.feedback as InlineMethodFeedback;
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
  void f() {
    test(1);
  }
}
void f(A a) {
  a.test(2);
}
''');
    return assertSuccessfulRefactoring(() {
      return _sendInlineRequest('test(int p)');
    }, '''
class A {
  int f;
  void f() {
    print(f + 1);
  }
}
void f(A a) {
  print(a.f + 2);
}
''');
  }

  Future<void> test_topLevelFunction() {
    addTestFile('''
test(a, b) {
  print(a + b);
}
void f() {
  test(1, 2);
  test(10, 20);
}
''');
    return assertSuccessfulRefactoring(() {
      return _sendInlineRequest('test(a');
    }, '''
void f() {
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
void f() {
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
void f() {
  test(1, 2);
  print(10 + 20);
}
''');
  }

  Future<Response> _sendInlineRequest(String search) {
    var request = EditGetRefactoringParams(RefactoringKind.INLINE_METHOD,
            testFile.path, findOffset(search), 0, false,
            options: options)
        .toRequest('0');
    return serverChannel.simulateRequestFromClient(request);
  }
}

@reflectiveTest
class MoveFileTest extends _AbstractGetRefactoring_Test {
  late MoveFileOptions options;

  Future<void> test_file_OK() {
    newFile('$testPackageLibPath/a.dart', '');
    addTestFile('''
import 'dart:math';
import 'a.dart';
''');
    _setOptions('$testPackageRootPath/test.dart');
    return assertSuccessfulRefactoring(() {
      return _sendMoveRequest(testFile.path);
    }, '''
import 'dart:math';
import 'lib/a.dart';
''');
  }

  Future<void> test_folder_cancel() {
    newFile('$testPackageLibPath/original_folder/file.dart', '');
    addTestFile('''
import 'dart:math';
import 'original_folder/file.dart';
''');
    _setOptions('$testPackageLibPath/new_folder');
    return assertEmptySuccessfulRefactoring(() async {
      return _sendAndCancelMoveRequest(
          getFolder('$testPackageLibPath/original_folder').path);
    });
  }

  Future<void> test_folder_OK() {
    newFile('$testPackageLibPath/original_folder/file.dart', '');
    addTestFile('''
import 'dart:math';
import 'original_folder/file.dart';
''');
    _setOptions('$testPackageLibPath/new_folder');
    return assertSuccessfulRefactoring(() async {
      return _sendMoveRequest(
          getFolder('$testPackageLibPath/original_folder').path);
    }, '''
import 'dart:math';
import 'new_folder/file.dart';
''');
  }

  Future<Response> _cancelMoveRequest() {
    // 0 is the id from _sendMoveRequest
    // 1 is another arbitrary id for the cancel request
    var request = ServerCancelRequestParams('0').toRequest('1');
    return serverChannel.simulateRequestFromClient(request);
  }

  Future<Response> _sendAndCancelMoveRequest(String item) async {
    final responses = await Future.wait([
      _sendMoveRequest(item),
      _cancelMoveRequest(),
    ]);
    return responses.first;
  }

  Future<Response> _sendMoveRequest(String item) {
    var request = EditGetRefactoringParams(
            RefactoringKind.MOVE_FILE, item, 0, 0, false,
            options: options)
        .toRequest('0');
    return serverChannel.simulateRequestFromClient(request);
  }

  void _setOptions(String newFile) {
    options = MoveFileOptions(convertPath(newFile));
  }
}

@reflectiveTest
class RenameTest extends _AbstractGetRefactoring_Test {
  Future<Response> sendRenameRequest(String search, String? newName,
      {String id = '0', bool validateOnly = false}) {
    var options = newName != null ? RenameOptions(newName) : null;
    var request = EditGetRefactoringParams(RefactoringKind.RENAME,
            testFile.path, findOffset(search), 0, validateOnly,
            options: options)
        .toRequest(id);
    return serverChannel.simulateRequestFromClient(request);
  }

  @override
  Future<void> tearDown() async {
    test_simulateRefactoringReset_afterInitialConditions = false;
    test_simulateRefactoringReset_afterFinalConditions = false;
    test_simulateRefactoringReset_afterCreateChange = false;
    await super.tearDown();
  }

  Future<void> test_cancelPendingRequest() async {
    addTestFile('''
void f() {
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
void f() {
  Test v;
  Test();
  Test.named();
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('Test {', 'NewName');
    }, '''
class NewName {
  NewName() {}
  NewName.named() {}
}
void f() {
  NewName v;
  NewName();
  NewName.named();
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
        var renameFeedback = feedback as RenameFeedback;
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
void f() {
  Test();
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
void f() {
  NewName();
}
''',
      feedbackValidator: (feedback) {
        var renameFeedback = feedback as RenameFeedback;
        expect(renameFeedback.offset, 40);
        expect(renameFeedback.length, 4);
      },
    );
  }

  Future<void> test_class_fromInstanceCreation_namedConstructor() {
    addTestFile('''
class Test {
  Test.named() {}
}
void f() {
  Test.named();
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
void f() {
  NewName.named();
}
''',
      feedbackValidator: (feedback) {
        var renameFeedback = feedback as RenameFeedback;
        expect(renameFeedback.offset, 46);
        expect(renameFeedback.length, 4);
      },
    );
  }

  Future<void> test_class_fromInstanceCreation_onNew() {
    addTestFile('''
class Test {
  Test() {}
}
void f() {
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
void f() {
  new NewName();
}
''',
      feedbackValidator: (feedback) {
        var renameFeedback = feedback as RenameFeedback;
        expect(renameFeedback.offset, 44);
        expect(renameFeedback.length, 4);
      },
    );
  }

  Future<void> test_class_fromInstanceCreation_onNew_namedConstructor() {
    addTestFile('''
class Test {
  Test.named() {}
}
void f() {
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
void f() {
  new NewName.named();
}
''',
      feedbackValidator: (feedback) {
        var renameFeedback = feedback as RenameFeedback;
        expect(renameFeedback.offset, 50);
        expect(renameFeedback.length, 4);
      },
    );
  }

  Future<void> test_class_getter_in_objectPattern() {
    addTestFile('''
void f(Object? x) {
  if (x case A(test: 0)) {}
  if (x case A(: var test)) {}
}

class A {
  int get test => 0;
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test =>', 'newName');
    }, '''
void f(Object? x) {
  if (x case A(newName: 0)) {}
  if (x case A(newName: var test)) {}
}

class A {
  int get newName => 0;
}
''');
  }

  Future<void> test_class_method_in_objectPattern() {
    addTestFile('''
void f(Object? x) {
  if (x case A(test: _)) {}
  if (x case A(: var test)) {}
}

class A {
  void test() {}
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test() {}', 'newName');
    }, '''
void f(Object? x) {
  if (x case A(newName: _)) {}
  if (x case A(newName: var test)) {}
}

class A {
  void newName() {}
}
''');
  }

  Future<void> test_class_options_fatalError() {
    addTestFile('''
class Test {}
void f() {
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

  Future<void> test_class_typeParameter_atDeclaration() {
    addTestFile('''
class A<Test> {
  void foo(Test a) {}
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('Test> {', 'NewName');
    }, '''
class A<NewName> {
  void foo(NewName a) {}
}
''');
  }

  Future<void> test_class_typeParameter_atReference() {
    addTestFile('''
class A<Test> {
  final List<Test> values = [];
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('Test> values', 'NewName');
    }, '''
class A<NewName> {
  final List<NewName> values = [];
}
''');
  }

  Future<void> test_class_validateOnly() {
    addTestFile('''
class Test {}
void f() {
  Test v;
}
''');
    return getRefactoringResult(() {
      return sendRenameRequest('Test {}', 'NewName', validateOnly: true);
    }).then((result) {
      var feedback = result.feedback as RenameFeedback;
      assertResultProblemsOK(result);
      expect(feedback.elementKindName, 'class');
      expect(feedback.oldName, 'Test');
      expect(result.change, isNull);
    });
  }

  Future<void> test_class_warning() {
    addTestFile('''
class Test {}
void f() {
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
void f() {
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
void f() {
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
  void f() {
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
  void f() {
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
  void f() {
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
  void f() {
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
void f() {
  A(test: 42);
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test: 42', 'newName');
    }, '''
class A {
  final int newName;
  A({this.newName: 0});
}
void f() {
  A(newName: 42);
}
''');
  }

  Future<void> test_classMember_field_onFieldFormalParameter_named_private() {
    addTestFile('''
class A {
  final int test;
  A({this.test = 0});
}
void f() {
  A(test: 42);
}
''');

    return getRefactoringResult(() {
      return sendRenameRequest('test: 42', '_new');
    }).then((result) {
      var problems = result.finalProblems;
      expect(problems, hasLength(1));
      assertResultProblemsError(
          problems, "The parameter 'test' is named and can not be private.");
    });
  }

  Future<void> test_classMember_getter() {
    addTestFile('''
class A {
  get test => 0;
  void f() {
    print(test);
  }
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test =>', 'newName');
    }, '''
class A {
  get newName => 0;
  void f() {
    print(newName);
  }
}
''');
  }

  Future<void> test_classMember_method() {
    addTestFile('''
class A {
  test() {}
  void f() {
    test();
  }
}
void f(A a) {
  a.test();
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test() {}', 'newName');
    }, '''
class A {
  newName() {}
  void f() {
    newName();
  }
}
void f(A a) {
  a.newName();
}
''');
  }

  Future<void> test_classMember_method_potential() {
    addTestFile('''
class A {
  test() {}
}
void f(A a, a2) {
  a.test();
  a2.test(); // a2
}
''');
    return getRefactoringResult(() {
      return sendRenameRequest('test() {}', 'newName');
    }).then((result) {
      assertResultProblemsOK(result);
      // prepare potential edit ID
      var potentialIds = result.potentialEdits!;
      expect(potentialIds, hasLength(1));
      var potentialId = potentialIds[0];
      // find potential edit
      var change = result.change!;
      var potentialEdit = _findEditWithId(change, potentialId)!;
      expect(potentialEdit.offset, findOffset('test(); // a2'));
      expect(potentialEdit.length, 4);
    });
  }

  Future<void> test_classMember_setter() {
    addTestFile('''
class A {
  set test(x) {}
  void f() {
    test = 0;
  }
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test = 0', 'newName');
    }, '''
class A {
  set newName(x) {}
  void f() {
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
        var renameFeedback = feedback as RenameFeedback;
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
void f() {
  A.test();
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
void f() {
  A.newName();
}
''',
      feedbackValidator: (feedback) {
        var renameFeedback = feedback as RenameFeedback;
        expect(renameFeedback.offset, 41);
        expect(renameFeedback.length, 4);
      },
    );
  }

  Future<void> test_enum_constructor_add_toSynthetic() {
    addTestFile('''
enum E {
  v1, v2.new()
}
''');
    return assertSuccessfulRefactoring(
      () {
        return sendRenameRequest('new()', 'newName');
      },
      '''
enum E {
  v1.newName(), v2.newName();

  const E.newName();
}
''',
      feedbackValidator: (feedback) {
        var renameFeedback = feedback as RenameFeedback;
        expect(renameFeedback.offset, 17);
        expect(renameFeedback.length, 4);
      },
    );
  }

  Future<void> test_enum_constructor_change() {
    addTestFile('''
enum E {
  v1.test(), v2.test();

  const E.test();
}
''');
    return assertSuccessfulRefactoring(
      () {
        return sendRenameRequest('test();', 'newName');
      },
      '''
enum E {
  v1.newName(), v2.newName();

  const E.newName();
}
''',
      feedbackValidator: (feedback) {
        var renameFeedback = feedback as RenameFeedback;
        expect(renameFeedback.offset, 24);
        expect(renameFeedback.length, 5);
      },
    );
  }

  Future<void> test_enum_typeParameter_atDeclaration() {
    addTestFile('''
enum E2<Test> {
  v<int>();
  void foo(Test a) {}
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('Test> {', 'NewName');
    }, '''
enum E2<NewName> {
  v<int>();
  void foo(NewName a) {}
}
''');
  }

  Future<void> test_extension_atDeclaration() {
    addTestFile('''
extension Test on int {
  void foo() {}
}
void f() {
  Test(0).foo();
}
''');
    return assertSuccessfulRefactoring(
      () {
        return sendRenameRequest('Test on int', 'NewName');
      },
      '''
extension NewName on int {
  void foo() {}
}
void f() {
  NewName(0).foo();
}
''',
      feedbackValidator: (feedback) {
        var renameFeedback = feedback as RenameFeedback;
        expect(renameFeedback.offset, 10);
        expect(renameFeedback.length, 4);
      },
    );
  }

  Future<void> test_extension_atReference() {
    addTestFile('''
extension Test on int {
  void foo() {}
}
void f() {
  Test(0).foo();
}
''');
    return assertSuccessfulRefactoring(
      () {
        return sendRenameRequest('Test(0)', 'NewName');
      },
      '''
extension NewName on int {
  void foo() {}
}
void f() {
  NewName(0).foo();
}
''',
      feedbackValidator: (feedback) {
        var renameFeedback = feedback as RenameFeedback;
        expect(renameFeedback.offset, 55);
        expect(renameFeedback.length, 4);
      },
    );
  }

  Future<void> test_extension_typeParameter_atDeclaration() {
    addTestFile('''
extension E<Test> on int {
  void foo(Test a) {}
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('Test> on', 'NewName');
    }, '''
extension E<NewName> on int {
  void foo(NewName a) {}
}
''');
  }

  Future<void> test_extensionType_field_representation() {
    addTestFile('''
extension type E(int test) {}

void f(E e) {
  e.test;
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test) {}', 'newName');
    }, '''
extension type E(int newName) {}

void f(E e) {
  e.newName;
}
''');
  }

  Future<void> test_extensionType_method() {
    addTestFile('''
extension type E(int it) {
  void test() {}
}

void f(E e) {
  e.test();
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test() {}', 'newName');
    }, '''
extension type E(int it) {
  void newName() {}
}

void f(E e) {
  e.newName();
}
''');
  }

  Future<void> test_extensionType_name_end() {
    addTestFile('''
extension type Test(int it) {}

void f(Test x) {}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('(int', 'NewName');
    }, '''
extension type NewName(int it) {}

void f(NewName x) {}
''');
  }

  Future<void> test_extensionType_name_inside() {
    addTestFile('''
extension type Test(int it) {}

void f(Test x) {}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('est(int', 'NewName');
    }, '''
extension type NewName(int it) {}

void f(NewName x) {}
''');
  }

  Future<void> test_extensionType_name_start() {
    addTestFile('''
extension type Test(int it) {}

void f(Test x) {}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('Test(int', 'NewName');
    }, '''
extension type NewName(int it) {}

void f(NewName x) {}
''');
  }

  Future<void> test_extensionType_primaryConstructor_atDeclaration() {
    addTestFile('''
extension type E.test(int it) {}

void f() {
  E.test(0);
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test(int', 'newName');
    }, '''
extension type E.newName(int it) {}

void f() {
  E.newName(0);
}
''');
  }

  Future<void> test_extensionType_primaryConstructor_atInvocation() {
    addTestFile('''
extension type E.test(int it) {}

void f() {
  E.test(0);
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test(0', 'newName');
    }, '''
extension type E.newName(int it) {}

void f() {
  E.newName(0);
}
''');
  }

  Future<void> test_feedback() {
    addTestFile('''
class Test {}
void f() {
  Test v;
}
''');
    return getRefactoringResult(() {
      return sendRenameRequest('st v;', 'NewName');
    }).then((result) {
      var feedback = result.feedback as RenameFeedback;
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

void f() {
  A(test: 0);
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test: 0', 'newName');
    }, '''
class A<T> {
  A({T newName});
}

void f() {
  A(newName: 0);
}
''');
  }

  Future<void> test_formalParameter_named_ofMethod_genericClass() {
    addTestFile('''
class A<T> {
  void foo({T test}) {}
}

void f(A<int> a) {
  a.foo(test: 0);
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test: 0', 'newName');
    }, '''
class A<T> {
  void foo({T newName}) {}
}

void f(A<int> a) {
  a.foo(newName: 0);
}
''');
  }

  Future<void> test_function() {
    addTestFile('''
test() {}
void f() {
  test();
  print(test);
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test() {}', 'newName');
    }, '''
newName() {}
void f() {
  newName();
  print(newName);
}
''');
  }

  Future<void> test_importPrefix_add() {
    addTestFile('''
import 'dart:math';
import 'dart:async';
void f() {
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
void f() {
  Random r;
  new_name.Future f;
}
''',
        feedbackValidator: (feedback) {
          var renameFeedback = feedback as RenameFeedback;
          expect(renameFeedback.offset, -1);
          expect(renameFeedback.length, 0);
        });
  }

  Future<void> test_importPrefix_remove() {
    addTestFile('''
import 'dart:math' as test;
import 'dart:async' as test;
void f() {
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
void f() {
  test.Random r;
  Future f;
}
''',
        feedbackValidator: (feedback) {
          var renameFeedback = feedback as RenameFeedback;
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
    newFile('$testPackageLibPath/my_lib.dart', '''
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
void f() {
  int test = 0;
  test = 1;
  test += 2;
  print(test);
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test = 1', 'newName');
    }, '''
void f() {
  int newName = 0;
  newName = 1;
  newName += 2;
  print(newName);
}
''');
  }

  Future<void> test_localVariable_finalCheck_shadowError() {
    addTestFile('''
void f() {
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

  Future<void> test_mixin_typeParameter_atDeclaration() {
    addTestFile('''
mixin M<Test> {
  final List<Test> values = [];
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('Test> {', 'NewName');
    }, '''
mixin M<NewName> {
  final List<NewName> values = [];
}
''');
  }

  Future<void> test_parameter_onDefaultParameter() {
    addTestFile('''
class A {
  final int test;
  A({int t = 0}) : test = t;
}
void f() {
  A(t: 42);
}
''');

    return getRefactoringResult(() {
      return sendRenameRequest('t: 42', '_new');
    }).then((result) {
      var problems = result.finalProblems;
      expect(problems, hasLength(1));
      assertResultProblemsError(
          problems, "The parameter 't' is named and can not be private.");
    });
  }

  Future<void> test_patternVariable_ifCase() {
    addTestFile('''
void f(Object? x) {
  if (x case int test) {
    test;
    test = 1;
    test += 2;
  }
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test) {', 'newName');
    }, '''
void f(Object? x) {
  if (x case int newName) {
    newName;
    newName = 1;
    newName += 2;
  }
}
''');
  }

  Future<void> test_patternVariable_patternAssignment() {
    addTestFile('''
void f(Object? x) {
  int test;
  (test, _) = (0, 1);
  test;
}
''');
    return assertSuccessfulRefactoring(() {
      return sendRenameRequest('test,', 'newName');
    }, '''
void f(Object? x) {
  int newName;
  (newName, _) = (0, 1);
  newName;
}
''');
  }

  Future<void> test_reset_afterCreateChange() {
    test_simulateRefactoringReset_afterCreateChange = true;
    addTestFile('''
test() {}
void f() {
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
void f() {
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
void f() {
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
void f() {
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
void f() {
  int otherName = 0;
  print(otherName);
}
''');
    unawaited(
        server.getAnalysisDriver(testFile.path)!.getResult(testFile.path));
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

  SourceEdit? _findEditWithId(SourceChange change, String id) {
    SourceEdit? potentialEdit;
    for (var fileEdit in change.edits) {
      for (var edit in fileEdit.edits) {
        if (edit.id == id) {
          potentialEdit = edit;
        }
      }
    }
    return potentialEdit;
  }

  void _validateFeedback(EditGetRefactoringResult result, {String? oldName}) {
    var feedback = result.feedback as RenameFeedback;
    if (oldName != null) {
      expect(feedback.oldName, oldName);
    }
  }
}

@reflectiveTest
class _AbstractGetRefactoring_Test extends PubPackageAnalysisServerTest {
  bool shouldWaitForFullAnalysis = true;

  Future<void> assertEmptySuccessfulRefactoring(
      Future<Response> Function() requestSender,
      {void Function(RefactoringFeedback?)? feedbackValidator}) async {
    var result = await getRefactoringResult(requestSender);
    assertResultProblemsOK(result);
    if (feedbackValidator != null) {
      feedbackValidator(result.feedback);
    }
    assertNoTestRefactoringResult(result);
  }

  /// Asserts that the given [EditGetRefactoringResult] does not have a change
  /// for [testFile].
  void assertNoTestRefactoringResult(EditGetRefactoringResult result) {
    var change = result.change!;
    if (change.edits.any((edit) => edit.file == testFile.path)) {
      fail('Found a SourceFileEdit for $testFile in $change');
    }
  }

  /// Asserts that [problems] has a single ERROR problem.
  void assertResultProblemsError(List<RefactoringProblem> problems,
      [String? message]) {
    var problem = problems[0];
    expect(problem.severity, RefactoringProblemSeverity.ERROR,
        reason: problem.toString());
    if (message != null) {
      expect(problem.message, message);
    }
  }

  /// Asserts that [result] has a single FATAL problem.
  void assertResultProblemsFatal(List<RefactoringProblem> problems,
      [String? message]) {
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
      [String? message]) {
    var problem = problems[0];
    expect(problems, hasLength(1));
    expect(problem.severity, RefactoringProblemSeverity.WARNING,
        reason: problem.toString());
    if (message != null) {
      expect(problem.message, message);
    }
  }

  Future<void> assertSuccessfulRefactoring(
      Future<Response> Function() requestSender, String expectedCode,
      {void Function(RefactoringFeedback?)? feedbackValidator}) async {
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
    var change = result.change!;
    for (var fileEdit in change.edits) {
      if (fileEdit.file == testFile.path) {
        var actualCode =
            SourceEdit.applySequence(testFileContent, fileEdit.edits);
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
      RefactoringKind kind, int offset, int length, RefactoringOptions? options,
      [bool validateOnly = false]) {
    var request = EditGetRefactoringParams(
            kind, testFile.path, offset, length, validateOnly,
            options: options)
        .toRequest('0');
    return serverChannel.simulateRequestFromClient(request);
  }

  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }
}
