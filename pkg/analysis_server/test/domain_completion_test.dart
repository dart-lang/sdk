// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/contribution_sorter.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'domain_completion_util.dart';
import 'mocks.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompletionDomainHandlerGetSuggestionsTest);
    defineReflectiveTests(CompletionDomainHandlerListTokenDetailsTest);
  });
}

@reflectiveTest
class CompletionDomainHandlerGetSuggestionsTest
    extends AbstractCompletionDomainTest {
  test_ArgumentList_constructor_named_fieldFormalParam() async {
    // https://github.com/dart-lang/sdk/issues/31023
    addTestFile('''
main() { new A(field: ^);}
class A {
  A({this.field: -1}) {}
}
''');
    await getSuggestions();
  }

  test_ArgumentList_constructor_named_param_label() async {
    addTestFile('main() { new A(^);}'
        'class A { A({one, two}) {} }');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'one: ',
        relevance: DART_RELEVANCE_NAMED_PARAMETER);
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'two: ',
        relevance: DART_RELEVANCE_NAMED_PARAMETER);
    expect(suggestions, hasLength(2));
  }

  test_ArgumentList_factory_named_param_label() async {
    addTestFile('main() { new A(^);}'
        'class A { factory A({one, two}) => null; }');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'one: ',
        relevance: DART_RELEVANCE_NAMED_PARAMETER);
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'two: ',
        relevance: DART_RELEVANCE_NAMED_PARAMETER);
    expect(suggestions, hasLength(2));
  }

  test_ArgumentList_imported_function_named_param() async {
    addTestFile('main() { int.parse("16", ^);}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'radix: ',
        relevance: DART_RELEVANCE_NAMED_PARAMETER);
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'onError: ',
        relevance: DART_RELEVANCE_NAMED_PARAMETER);
    expect(suggestions, hasLength(2));
  }

  test_ArgumentList_imported_function_named_param1() async {
    addTestFile('main() { foo(o^);} foo({one, two}) {}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'one: ',
        relevance: DART_RELEVANCE_NAMED_PARAMETER);
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'two: ',
        relevance: DART_RELEVANCE_NAMED_PARAMETER);
    expect(suggestions, hasLength(2));
  }

  test_ArgumentList_imported_function_named_param2() async {
    addTestFile('mainx() {A a = new A(); a.foo(one: 7, ^);}'
        'class A { foo({one, two}) {} }');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'two: ',
        relevance: DART_RELEVANCE_NAMED_PARAMETER);
    expect(suggestions, hasLength(1));
  }

  test_ArgumentList_imported_function_named_param_label1() async {
    addTestFile('main() { int.parse("16", r^: 16);}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'radix',
        relevance: DART_RELEVANCE_NAMED_PARAMETER);
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'onError',
        relevance: DART_RELEVANCE_NAMED_PARAMETER);
    expect(suggestions, hasLength(2));
  }

  test_ArgumentList_imported_function_named_param_label3() async {
    addTestFile('main() { int.parse("16", ^: 16);}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'radix: ',
        relevance: DART_RELEVANCE_NAMED_PARAMETER);
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'onError: ',
        relevance: DART_RELEVANCE_NAMED_PARAMETER);
    expect(suggestions, hasLength(2));
  }

  test_catch() async {
    addTestFile('main() {try {} ^}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'on',
        relevance: DART_RELEVANCE_KEYWORD);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'catch',
        relevance: DART_RELEVANCE_KEYWORD);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'finally',
        relevance: DART_RELEVANCE_KEYWORD);
    expect(suggestions, hasLength(3));
  }

  test_catch2() async {
    addTestFile('main() {try {} on Foo {} ^}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'on',
        relevance: DART_RELEVANCE_KEYWORD);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'catch',
        relevance: DART_RELEVANCE_KEYWORD);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'finally',
        relevance: DART_RELEVANCE_KEYWORD);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'for',
        relevance: DART_RELEVANCE_KEYWORD);
    suggestions.firstWhere(
        (CompletionSuggestion suggestion) =>
            suggestion.kind != CompletionSuggestionKind.KEYWORD, orElse: () {
      fail('Expected suggestions other than keyword suggestions');
    });
  }

  test_catch3() async {
    addTestFile('main() {try {} catch (e) {} finally {} ^}');
    await getSuggestions();
    assertNoResult('on');
    assertNoResult('catch');
    assertNoResult('finally');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'for',
        relevance: DART_RELEVANCE_KEYWORD);
    suggestions.firstWhere(
        (CompletionSuggestion suggestion) =>
            suggestion.kind != CompletionSuggestionKind.KEYWORD, orElse: () {
      fail('Expected suggestions other than keyword suggestions');
    });
  }

  test_catch4() async {
    addTestFile('main() {try {} finally {} ^}');
    await getSuggestions();
    assertNoResult('on');
    assertNoResult('catch');
    assertNoResult('finally');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'for',
        relevance: DART_RELEVANCE_KEYWORD);
    suggestions.firstWhere(
        (CompletionSuggestion suggestion) =>
            suggestion.kind != CompletionSuggestionKind.KEYWORD, orElse: () {
      fail('Expected suggestions other than keyword suggestions');
    });
  }

  test_catch5() async {
    addTestFile('main() {try {} ^ finally {}}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'on',
        relevance: DART_RELEVANCE_KEYWORD);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'catch',
        relevance: DART_RELEVANCE_KEYWORD);
    expect(suggestions, hasLength(2));
  }

  test_constructor() async {
    addTestFile('class A {bool foo; A() : ^;}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super',
        relevance: DART_RELEVANCE_KEYWORD);
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'foo',
        relevance: DART_RELEVANCE_LOCAL_FIELD);
  }

  test_constructor2() async {
    addTestFile('class A {bool foo; A() : s^;}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super',
        relevance: DART_RELEVANCE_KEYWORD);
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'foo',
        relevance: DART_RELEVANCE_LOCAL_FIELD);
  }

  test_constructor3() async {
    addTestFile('class A {bool foo; A() : a=7,^;}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super',
        relevance: DART_RELEVANCE_KEYWORD);
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'foo',
        relevance: DART_RELEVANCE_LOCAL_FIELD);
  }

  test_constructor4() async {
    addTestFile('class A {bool foo; A() : a=7,s^;}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super',
        relevance: DART_RELEVANCE_KEYWORD);
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'foo',
        relevance: DART_RELEVANCE_LOCAL_FIELD);
  }

  test_constructor5() async {
    addTestFile('class A {bool foo; A() : a=7,s^}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super',
        relevance: DART_RELEVANCE_KEYWORD);
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'foo',
        relevance: DART_RELEVANCE_LOCAL_FIELD);
  }

  test_constructor6() async {
    addTestFile('class A {bool foo; A() : a=7,^ void bar() {}}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super',
        relevance: DART_RELEVANCE_KEYWORD);
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'foo',
        relevance: DART_RELEVANCE_LOCAL_FIELD);
  }

  test_html() {
    //
    // We no longer support the analysis of non-dart files.
    //
    testFile = convertPath('/project/web/test.html');
    addTestFile('''
      <html>^</html>
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      expect(suggestions, hasLength(0));
    });
  }

  test_import_uri_with_trailing() {
    final filePath = '/project/bin/testA.dart';
    final incompleteImportText = toUriStr('/project/bin/t');
    newFile(filePath, content: 'library libA;');
    addTestFile('''
    import "$incompleteImportText^.dart";
    main() {}''');
    return getSuggestions().then((_) {
      expect(replacementOffset,
          equals(completionOffset - incompleteImportText.length));
      expect(replacementLength, equals(5 + incompleteImportText.length));
      assertHasResult(CompletionSuggestionKind.IMPORT, toUriStr(filePath));
      assertNoResult('test');
    });
  }

  test_imports() {
    addTestFile('''
      import 'dart:html';
      main() {^}
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'Object',
          elementKind: ElementKind.CLASS);
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'HtmlElement',
          elementKind: ElementKind.CLASS);
      assertNoResult('test');
    });
  }

  test_imports_aborted_new_request() async {
    addTestFile('''
        class foo { }
        c^''');

    // Make a request for suggestions
    Request request1 =
        new CompletionGetSuggestionsParams(testFile, completionOffset)
            .toRequest('7');
    Future<Response> responseFuture1 = waitResponse(request1);

    // Make another request before the first request completes
    Request request2 =
        new CompletionGetSuggestionsParams(testFile, completionOffset)
            .toRequest('8');
    Future<Response> responseFuture2 = waitResponse(request2);

    // Await first response
    Response response1 = await responseFuture1;
    var result1 = new CompletionGetSuggestionsResult.fromResponse(response1);
    assertValidId(result1.id);

    // Await second response
    Response response2 = await responseFuture2;
    var result2 = new CompletionGetSuggestionsResult.fromResponse(response2);
    assertValidId(result2.id);

    // Wait for all processing to be complete
    await analysisHandler.server.analysisDriverScheduler.waitForIdle();
    await pumpEventQueue();

    // Assert that first request has been aborted
    expect(allSuggestions[result1.id], hasLength(0));

    // Assert valid results for the second request
    expect(allSuggestions[result2.id], same(suggestions));
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'class',
        relevance: DART_RELEVANCE_HIGH);
  }

  @failingTest
  test_imports_aborted_source_changed() async {
    // TODO(brianwilkerson) Figure out whether this test makes sense when
    // running the new driver. It waits for an initial empty notification then
    // waits for a new notification. But I think that under the driver we only
    // ever send one notification.
    addTestFile('''
        class foo { }
        c^''');

    // Make a request for suggestions
    Request request =
        new CompletionGetSuggestionsParams(testFile, completionOffset)
            .toRequest('0');
    Future<Response> responseFuture = waitResponse(request);

    // Simulate user deleting text after request but before suggestions returned
    server.updateContent('uc1', {testFile: new AddContentOverlay(testCode)});
    server.updateContent('uc2', {
      testFile: new ChangeContentOverlay(
          [new SourceEdit(completionOffset - 1, 1, '')])
    });

    // Await a response
    Response response = await responseFuture;
    completionId = response.id;
    assertValidId(completionId);

    // Wait for all processing to be complete
    await analysisHandler.server.analysisDriverScheduler.waitForIdle();
    await pumpEventQueue();

    // Assert that request has been aborted
    expect(suggestionsDone, isTrue);
    expect(suggestions, hasLength(0));
  }

  test_imports_incremental() async {
    addTestFile('''library foo;
      e^
      import "dart:async";
      import "package:foo/foo.dart";
      class foo { }''');
    await waitForTasksFinished();
    server.updateContent('uc1', {testFile: new AddContentOverlay(testCode)});
    server.updateContent('uc2', {
      testFile:
          new ChangeContentOverlay([new SourceEdit(completionOffset, 0, 'xp')])
    });
    completionOffset += 2;
    await getSuggestions();
    expect(replacementOffset, completionOffset - 3);
    expect(replacementLength, 3);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'export \'\';',
        selectionOffset: 8, relevance: DART_RELEVANCE_HIGH);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'import \'\';',
        selectionOffset: 8, relevance: DART_RELEVANCE_HIGH);
    assertNoResult('extends');
    assertNoResult('library');
  }

  test_imports_partial() async {
    addTestFile('''^
      import "package:foo/foo.dart";
      import "package:bar/bar.dart";
      class Baz { }''');

    // Wait for analysis then edit the content
    await waitForTasksFinished();
    String revisedContent = testCode.substring(0, completionOffset) +
        'i' +
        testCode.substring(completionOffset);
    ++completionOffset;
    server.handleRequest(new AnalysisUpdateContentParams(
        {testFile: new AddContentOverlay(revisedContent)}).toRequest('add1'));

    // Request code completion immediately after edit
    Response response = await waitResponse(
        new CompletionGetSuggestionsParams(testFile, completionOffset)
            .toRequest('0'));
    completionId = response.id;
    assertValidId(completionId);
    await waitForTasksFinished();
    // wait for response to arrive
    // because although the analysis is complete (waitForTasksFinished)
    // the response may not yet have been processed
    while (replacementOffset == null) {
      await new Future.delayed(new Duration(milliseconds: 5));
    }
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'library',
        relevance: DART_RELEVANCE_HIGH);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'import \'\';',
        selectionOffset: 8, relevance: DART_RELEVANCE_HIGH);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'export \'\';',
        selectionOffset: 8, relevance: DART_RELEVANCE_HIGH);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'part \'\';',
        selectionOffset: 6, relevance: DART_RELEVANCE_HIGH);
    assertNoResult('extends');
  }

  test_imports_prefixed() {
    addTestFile('''
      import 'dart:html' as foo;
      main() {^}
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'Object',
          elementKind: ElementKind.CLASS);
      assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'foo');
      assertNoResult('HtmlElement');
      assertNoResult('test');
    });
  }

  test_imports_prefixed2() {
    addTestFile('''
      import 'dart:html' as foo;
      main() {foo.^}
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'HtmlElement');
      assertNoResult('test');
    });
  }

  test_inComment_block_beforeNode() async {
    addTestFile('''
  main(aaa, bbb) {
    /* text ^ */
    print(42);
  }
  ''');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  test_inComment_endOfLine_beforeNode() async {
    addTestFile('''
  main(aaa, bbb) {
    // text ^
    print(42);
  }
  ''');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  test_inComment_endOfLine_beforeToken() async {
    addTestFile('''
  main(aaa, bbb) {
    // text ^
  }
  ''');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  test_inDartDoc1() async {
    addTestFile('''
  /// ^
  main(aaa, bbb) {}
  ''');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  test_inDartDoc2() async {
    addTestFile('''
  /// Some text^
  main(aaa, bbb) {}
  ''');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  test_inDartDoc_reference1() async {
    newFile('/testA.dart', content: '''
  part of libA;
  foo(bar) => 0;''');
    addTestFile('''
  library libA;
  part "${toUriStr('/testA.dart')}";
  import "dart:math";
  /// The [^]
  main(aaa, bbb) {}
  ''');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'main',
        relevance: DART_RELEVANCE_LOCAL_FUNCTION);
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'foo',
        relevance: DART_RELEVANCE_LOCAL_FUNCTION);
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'min');
  }

  test_inDartDoc_reference2() async {
    addTestFile('''
  /// The [m^]
  main(aaa, bbb) {}
  ''');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'main',
        relevance: DART_RELEVANCE_LOCAL_FUNCTION);
  }

  test_inherited() {
    addTestFile('''
class A {
  m() {}
}
class B extends A {
  x() {^}
}
''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'm');
    });
  }

  test_invalidFilePathFormat_notAbsolute() async {
    var request =
        new CompletionGetSuggestionsParams('test.dart', 0).toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  test_invalidFilePathFormat_notNormalized() async {
    var request = new CompletionGetSuggestionsParams(
            convertPath('/foo/../bar/test.dart'), 0)
        .toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  test_invocation() {
    addTestFile('class A {b() {}} main() {A a; a.^}');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'b');
    });
  }

  test_invocation_sdk_relevancy_off() {
    var originalSorter = DartCompletionManager.contributionSorter;
    var mockSorter = new MockRelevancySorter();
    DartCompletionManager.contributionSorter = mockSorter;
    addTestFile('main() {Map m; m.^}');
    return getSuggestions().then((_) {
      // Assert that the CommonUsageComputer has been replaced
      expect(suggestions.any((s) => s.relevance == DART_RELEVANCE_COMMON_USAGE),
          isFalse);
      DartCompletionManager.contributionSorter = originalSorter;
      mockSorter.enabled = false;
    });
  }

  test_invocation_sdk_relevancy_on() {
    addTestFile('main() {Map m; m.^}');
    return getSuggestions().then((_) {
      // Assert that the CommonUsageComputer is working
      expect(suggestions.any((s) => s.relevance == DART_RELEVANCE_COMMON_USAGE),
          isTrue);
    });
  }

  test_invocation_withTrailingStmt() {
    addTestFile('class A {b() {}} main() {A a; a.^ int x = 7;}');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'b');
    });
  }

  test_is_asPrefixedIdentifierStart() async {
    addTestFile('''
class A { var isVisible;}
main(A p) { var v1 = p.is^; }''');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'isVisible',
        relevance: DART_RELEVANCE_DEFAULT);
  }

  test_keyword() {
    addTestFile('library A; cl^');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset - 2));
      expect(replacementLength, equals(2));
      assertHasResult(CompletionSuggestionKind.KEYWORD, 'export \'\';',
          selectionOffset: 8, relevance: DART_RELEVANCE_HIGH);
      assertHasResult(CompletionSuggestionKind.KEYWORD, 'class',
          relevance: DART_RELEVANCE_HIGH);
    });
  }

  test_local_implicitCreation() async {
    addTestFile('''
class A {
  A();
  A.named();
}
main() {
  ^
}
''');
    await getSuggestions();

    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));

    // The class is suggested.
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'A',
        elementKind: ElementKind.CLASS);

    // Both constructors - default and named, are suggested.
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'A',
        elementKind: ElementKind.CONSTRUCTOR);
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'A.named',
        elementKind: ElementKind.CONSTRUCTOR);
  }

  test_local_named_constructor() {
    addTestFile('class A {A.c(); x() {new A.^}}');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'c');
      assertNoResult('A');
    });
  }

  test_local_override() {
    newFile('/project/bin/a.dart', content: 'class A {m() {}}');
    addTestFile('''
import 'a.dart';
class B extends A {
  m() {}
  x() {^}
}
''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'm',
          relevance: DART_RELEVANCE_LOCAL_METHOD);
    });
  }

  test_local_shadowClass() async {
    addTestFile('''
class A {
  A();
  A.named();
}
main() {
  int A = 0;
  ^
}
''');
    await getSuggestions();

    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));

    // The class is suggested.
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'A',
        relevance: DART_RELEVANCE_LOCAL_VARIABLE);

    // Class and all its constructors are shadowed by the local variable.
    assertNoResult('A', elementKind: ElementKind.CLASS);
    assertNoResult('A', elementKind: ElementKind.CONSTRUCTOR);
    assertNoResult('A.named', elementKind: ElementKind.CONSTRUCTOR);
  }

  test_locals() {
    addTestFile('class A {var a; x() {var b;^}} class DateTime { }');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'A',
          elementKind: ElementKind.CLASS);
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'a',
          relevance: DART_RELEVANCE_LOCAL_FIELD);
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'b',
          relevance: DART_RELEVANCE_LOCAL_VARIABLE);
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'x',
          relevance: DART_RELEVANCE_LOCAL_METHOD);
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'DateTime',
          elementKind: ElementKind.CLASS);
    });
  }

  test_offset_past_eof() async {
    addTestFile('main() { }', offset: 300);
    Request request =
        new CompletionGetSuggestionsParams(testFile, completionOffset)
            .toRequest('0');
    Response response = await waitResponse(request);
    expect(response.id, '0');
    expect(response.error.code, RequestErrorCode.INVALID_PARAMETER);
  }

  test_overrides() {
    newFile('/project/bin/a.dart', content: 'class A {m() {}}');
    addTestFile('''
import 'a.dart';
class B extends A {m() {^}}
''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'm',
          relevance: DART_RELEVANCE_LOCAL_METHOD);
    });
  }

  test_partFile() {
    newFile('/project/bin/a.dart', content: '''
      library libA;
      import 'dart:html';
      part 'test.dart';
      class A { }
    ''');
    addTestFile('''
      part of libA;
      main() {^}''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'Object',
          elementKind: ElementKind.CLASS);
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'HtmlElement',
          elementKind: ElementKind.CLASS);
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'A',
          elementKind: ElementKind.CLASS);
      assertNoResult('test');
    });
  }

  test_partFile2() {
    newFile('/project/bin/a.dart', content: '''
      part of libA;
      class A { }''');
    addTestFile('''
      library libA;
      part "a.dart";
      import 'dart:html';
      main() {^}
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'Object',
          elementKind: ElementKind.CLASS);
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'HtmlElement',
          elementKind: ElementKind.CLASS);
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'A',
          elementKind: ElementKind.CLASS);
      assertNoResult('test');
    });
  }

  test_sentToPlugins() async {
    addTestFile('''
      void main() {
        ^
      }
    ''');
    PluginInfo info = new DiscoveredPluginInfo('a', 'b', 'c', null, null);
    plugin.CompletionGetSuggestionsResult result =
        new plugin.CompletionGetSuggestionsResult(
            testFile.indexOf('^'), 0, <CompletionSuggestion>[
      new CompletionSuggestion(CompletionSuggestionKind.IDENTIFIER,
          DART_RELEVANCE_DEFAULT, 'plugin completion', 3, 0, false, false)
    ]);
    pluginManager.broadcastResults = <PluginInfo, Future<plugin.Response>>{
      info: new Future.value(result.toResponse('-', 1))
    };
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'plugin completion',
        selectionOffset: 3);
  }

  test_simple() {
    addTestFile('''
      void main() {
        ^
      }
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'Object',
          elementKind: ElementKind.CLASS);
      assertNoResult('HtmlElement');
      assertNoResult('test');
    });
  }

  test_static() {
    addTestFile('class A {static b() {} c() {}} main() {A.^}');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'b');
      assertNoResult('c');
    });
  }

  test_topLevel() {
    addTestFile('''
      typedef foo();
      var test = '';
      main() {tes^t}
    ''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset - 3));
      expect(replacementLength, equals(4));
      // Suggestions based upon imported elements are partially filtered
      //assertHasResult(CompletionSuggestionKind.INVOCATION, 'Object');
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'test',
          relevance: DART_RELEVANCE_LOCAL_TOP_LEVEL_VARIABLE);
      assertNoResult('HtmlElement');
    });
  }
}

@reflectiveTest
class CompletionDomainHandlerListTokenDetailsTest
    extends AbstractCompletionDomainTest {
  String testFileUri;

  void expectTokens(String content, List<TokenDetails> expectedTokens) async {
    newFile(testFile, content: content);
    Request request =
        new CompletionListTokenDetailsParams(testFile).toRequest('0');
    Response response = await waitResponse(request);
    List<Map<String, dynamic>> tokens = response.result['tokens'];
    _compareTokens(tokens, expectedTokens);
  }

  @override
  void setUp() {
    super.setUp();
    testFileUri = toUriStr(testFile);
  }

  test_classDeclaration() async {
    await expectTokens('''
class A {}
class B extends A {}
class C implements B {}
class D with C {}
''', [
      token('class', null, null),
      token('A', 'dart:core;Type', ['declaration']),
      token('{', null, null),
      token('}', null, null),
      token('class', null, null),
      token('B', 'dart:core;Type', ['declaration']),
      token('extends', null, null),
      token('A', 'dart:core;Type<$testFileUri;A>', ['reference']),
      token('{', null, null),
      token('}', null, null),
      token('class', null, null),
      token('C', 'dart:core;Type', ['declaration']),
      token('implements', null, null),
      token('B', 'dart:core;Type<$testFileUri;B>', ['reference']),
      token('{', null, null),
      token('}', null, null),
      token('class', null, null),
      token('D', 'dart:core;Type', ['declaration']),
      token('with', null, null),
      token('C', 'dart:core;Type<$testFileUri;C>', ['reference']),
      token('{', null, null),
      token('}', null, null),
    ]);
  }

  test_genericType() async {
    await expectTokens('''
List<int> x = null;
''', [
      token('List', 'dart:core;Type<dart:core;List>', ['reference']),
      token('<', null, null),
      token('int', 'dart:core;Type<dart:core;int>', ['reference']),
      token('>', null, null),
      token('x', 'dart:core;List', ['declaration']),
      token('=', null, null),
      token('null', null, null),
      token(';', null, null),
    ]);
  }

  test_getterInvocation() async {
    await expectTokens('''
var x = 'a'.length;
''', [
      token('var', null, null),
      token('x', 'dart:core;int', ['declaration']),
      token('=', null, null),
      token("'a'", 'dart:core;String', null),
      token('.', null, null),
      token('length', 'dart:core;int', ['reference']),
      token(';', null, null),
    ]);
  }

  test_literal_bool() async {
    await expectTokens('''
var x = true;
''', [
      token('var', null, null),
      token('x', 'dart:core;bool', ['declaration']),
      token('=', null, null),
      token('true', 'dart:core;bool', null),
      token(';', null, null),
    ]);
  }

  test_literal_double() async {
    await expectTokens('''
var x = 3.4;
''', [
      token('var', null, null),
      token('x', 'dart:core;double', ['declaration']),
      token('=', null, null),
      token('3.4', 'dart:core;double', null),
      token(';', null, null),
    ]);
  }

  test_literal_int() async {
    await expectTokens('''
var x = 7;
''', [
      token('var', null, null),
      token('x', 'dart:core;int', ['declaration']),
      token('=', null, null),
      token('7', 'dart:core;int', null),
      token(';', null, null),
    ]);
  }

  test_literal_list() async {
    await expectTokens('''
var x = <int>[];
''', [
      token('var', null, null),
      token('x', 'dart:core;List', ['declaration']),
      token('=', null, null),
      token('<', null, null),
      token("int", 'dart:core;Type<dart:core;int>', ['reference']),
      token('>', null, null),
      token('[', null, null),
      token(']', null, null),
      token(';', null, null),
    ]);
  }

  test_literal_map() async {
    await expectTokens('''
var x = <int, int>{};
''', [
      token('var', null, null),
      token('x', 'dart:core;Map', ['declaration']),
      token('=', null, null),
      token('<', null, null),
      token("int", 'dart:core;Type<dart:core;int>', ['reference']),
//      token(',', null, null),
      token("int", 'dart:core;Type<dart:core;int>', ['reference']),
      token('>', null, null),
      token('{', null, null),
      token('}', null, null),
      token(';', null, null),
    ]);
  }

  test_literal_null() async {
    await expectTokens('''
var x = null;
''', [
      token('var', null, null),
      token('x', 'dynamic', ['declaration']),
      token('=', null, null),
      token('null', null, null),
      token(';', null, null),
    ]);
  }

  test_literal_set() async {
    await expectTokens('''
var x = <int>{};
''', [
      token('var', null, null),
      token('x', 'dart:core;Set', ['declaration']),
      token('=', null, null),
      token('<', null, null),
      token("int", 'dart:core;Type<dart:core;int>', ['reference']),
      token('>', null, null),
      token('{', null, null),
      token('}', null, null),
      token(';', null, null),
    ]);
  }

  test_literal_string() async {
    await expectTokens('''
var x = 'a';
''', [
      token('var', null, null),
      token('x', 'dart:core;String', ['declaration']),
      token('=', null, null),
      token("'a'", 'dart:core;String', null),
      token(';', null, null),
    ]);
  }

  test_methodDeclaration() async {
    await expectTokens('''
class A {
  String c(int x, int y) {}
}
''', [
      token('class', null, null),
      token('A', 'dart:core;Type', ['declaration']),
      token('{', null, null),
      token('String', 'dart:core;Type<dart:core;String>', ['reference']),
      token('c', 'dart:core;String Function(dart:core;int, dart:core;int)',
          ['declaration']),
      token('(', null, null),
      token('int', 'dart:core;Type<dart:core;int>', ['reference']),
      token('x', 'dart:core;int', ['declaration']),
//      token(',', null, null),
      token('int', 'dart:core;Type<dart:core;int>', ['reference']),
      token('y', 'dart:core;int', ['declaration']),
      token(')', null, null),
      token('{', null, null),
      token('}', null, null),
      token('}', null, null),
    ]);
  }

  test_methodInvocation() async {
    await expectTokens('''
var x = 'radar'.indexOf('r', 1);
''', [
      token('var', null, null),
      token('x', 'dart:core;int', ['declaration']),
      token('=', null, null),
      token("'radar'", 'dart:core;String', null),
      token('.', null, null),
      token(
          'indexOf',
          'dart:core;int Function(dart:core;Pattern, dart:core;int)',
          ['reference']),
      token('(', null, null),
      token("'r'", 'dart:core;String', null),
//      token(',', null, null),
      token('1', 'dart:core;int', null),
      token(')', null, null),
      token(';', null, null),
    ]);
  }

  test_mixinDeclaration() async {
    await expectTokens('''
class A {}
class B {}
mixin D on A implements B {}
''', [
      token('class', null, null),
      token('A', 'dart:core;Type', ['declaration']),
      token('{', null, null),
      token('}', null, null),
      token('class', null, null),
      token('B', 'dart:core;Type', ['declaration']),
      token('{', null, null),
      token('}', null, null),
      token('mixin', null, null),
      token('D', 'dart:core;Type', ['declaration']),
      token('on', null, null),
      token('A', 'dart:core;Type<$testFileUri;A>', ['reference']),
      token('implements', null, null),
      token('B', 'dart:core;Type<$testFileUri;B>', ['reference']),
      token('{', null, null),
      token('}', null, null),
    ]);
  }

  test_parameterReference() async {
    await expectTokens('''
int f(int p) {
  return p;
}
''', [
      token('int', 'dart:core;Type<dart:core;int>', ['reference']),
      token('f', 'dart:core;int Function(dart:core;int)', ['declaration']),
      token('(', null, null),
      token('int', 'dart:core;Type<dart:core;int>', ['reference']),
      token('p', 'dart:core;int', ['declaration']),
      token(')', null, null),
      token('{', null, null),
      token('return', null, null),
      token('p', 'dart:core;int', ['reference']),
      token(';', null, null),
      token('}', null, null),
    ]);
  }

  TokenDetails token(String lexeme, String type, List<String> kinds) {
    return new TokenDetails(lexeme, type: type, validElementKinds: kinds);
  }

  void _compareTokens(List<Map<String, dynamic>> actualTokens,
      List<TokenDetails> expectedTokens) {
    int length = expectedTokens.length;
    expect(actualTokens, hasLength(length));
    List<String> errors = [];
    for (int i = 0; i < length; i++) {
      Map<String, dynamic> actual = actualTokens[i];
      TokenDetails expected = expectedTokens[i];
      if (actual['lexeme'] != expected.lexeme) {
        errors.add('Lexeme at $i: '
            'expected "${expected.lexeme}", '
            'actual "${actual['lexeme']}"');
      }
      if (actual['type'] != expected.type) {
        errors.add('Type at $i ("${expected.lexeme}"): '
            'expected "${expected.type}", '
            'actual "${actual['type']}"');
      }
      if (_differentKinds(
          actual['validElementKinds'], expected.validElementKinds)) {
        errors.add('Kinds at $i ("${expected.lexeme}"): '
            'expected "${expected.validElementKinds}", '
            'actual "${actual['validElementKinds']}"');
      }
    }
    expect(errors, isEmpty);
  }

  /// Return `true` if the two lists of kinds are different.
  bool _differentKinds(List<String> actual, List<String> expected) {
    if (actual == null) {
      return expected != null;
    } else if (expected == null) {
      return true;
    }
    int expectedLength = expected.length;
    if (actual.length != expectedLength) {
      return true;
    }
    for (int i = 0; i < expectedLength; i++) {
      if (actual[i] != expected[i]) {
        return true;
      }
    }
    return false;
  }
}

class MockRelevancySorter implements DartContributionSorter {
  bool enabled = true;

  @override
  Future sort(
      CompletionRequest request, Iterable<CompletionSuggestion> suggestions) {
    if (!enabled) {
      throw 'unexpected sort';
    }
    return new Future.value();
  }
}
