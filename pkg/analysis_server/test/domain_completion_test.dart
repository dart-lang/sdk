// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/contribution_sorter.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'domain_completion_util.dart';
import 'mocks.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompletionDomainHandlerGetSuggestionsTest);
    defineReflectiveTests(CompletionDomainHandlerListTokenDetailsTest);
  });
}

@reflectiveTest
class CompletionDomainHandlerGetSuggestionsTest
    extends AbstractCompletionDomainTest {
  Future<void> test_ArgumentList_constructor_named_fieldFormalParam() async {
    // https://github.com/dart-lang/sdk/issues/31023
    addTestFile('''
main() { new A(field: ^);}
class A {
  A({this.field: -1}) {}
}
''');
    await getSuggestions();
  }

  Future<void> test_ArgumentList_constructor_named_param_label() async {
    addTestFile('main() { new A(^);}'
        'class A { A({one, two}) {} }');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'one: ');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'two: ');
    expect(suggestions, hasLength(2));
  }

  Future<void> test_ArgumentList_factory_named_param_label() async {
    addTestFile('main() { new A(^);}'
        'class A { factory A({one, two}) => throw 0; }');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'one: ');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'two: ');
    expect(suggestions, hasLength(2));
  }

  Future<void> test_ArgumentList_imported_function_named_param() async {
    addTestFile('main() { int.parse("16", ^);}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'radix: ');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'onError: ');
    expect(suggestions, hasLength(2));
  }

  Future<void> test_ArgumentList_imported_function_named_param1() async {
    addTestFile('main() { foo(o^);} foo({one, two}) {}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'one: ');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'two: ');
    expect(suggestions, hasLength(2));
  }

  Future<void> test_ArgumentList_imported_function_named_param2() async {
    addTestFile('mainx() {A a = new A(); a.foo(one: 7, ^);}'
        'class A { foo({one, two}) {} }');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'two: ');
    expect(suggestions, hasLength(1));
  }

  Future<void> test_ArgumentList_imported_function_named_param_label1() async {
    addTestFile('main() { int.parse("16", r^: 16);}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'radix');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'onError');
    expect(suggestions, hasLength(2));
  }

  Future<void> test_ArgumentList_imported_function_named_param_label3() async {
    addTestFile('main() { int.parse("16", ^: 16);}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'radix: ');
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'onError: ');
    expect(suggestions, hasLength(2));
  }

  Future<void> test_catch() async {
    addTestFile('main() {try {} ^}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'on');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'catch');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'finally');
    expect(suggestions, hasLength(3));
  }

  Future<void> test_catch2() async {
    addTestFile('main() {try {} on Foo {} ^}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'on');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'catch');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'finally');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'for');
    suggestions.firstWhere(
        (CompletionSuggestion suggestion) =>
            suggestion.kind != CompletionSuggestionKind.KEYWORD, orElse: () {
      fail('Expected suggestions other than keyword suggestions');
    });
  }

  Future<void> test_catch3() async {
    addTestFile('main() {try {} catch (e) {} finally {} ^}');
    await getSuggestions();
    assertNoResult('on');
    assertNoResult('catch');
    assertNoResult('finally');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'for');
    suggestions.firstWhere(
        (CompletionSuggestion suggestion) =>
            suggestion.kind != CompletionSuggestionKind.KEYWORD, orElse: () {
      fail('Expected suggestions other than keyword suggestions');
    });
  }

  Future<void> test_catch4() async {
    addTestFile('main() {try {} finally {} ^}');
    await getSuggestions();
    assertNoResult('on');
    assertNoResult('catch');
    assertNoResult('finally');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'for');
    suggestions.firstWhere(
        (CompletionSuggestion suggestion) =>
            suggestion.kind != CompletionSuggestionKind.KEYWORD, orElse: () {
      fail('Expected suggestions other than keyword suggestions');
    });
  }

  Future<void> test_catch5() async {
    addTestFile('main() {try {} ^ finally {}}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'on');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'catch');
    expect(suggestions, hasLength(2));
  }

  Future<void> test_constructor() async {
    addTestFile('class A {bool foo; A() : ^;}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super');
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'foo');
  }

  Future<void> test_constructor2() async {
    addTestFile('class A {bool foo; A() : s^;}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super');
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'foo');
  }

  Future<void> test_constructor3() async {
    addTestFile('class A {bool foo; A() : a=7,^;}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super');
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'foo');
  }

  Future<void> test_constructor4() async {
    addTestFile('class A {bool foo; A() : a=7,s^;}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super');
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'foo');
  }

  Future<void> test_constructor5() async {
    addTestFile('class A {bool foo; A() : a=7,s^}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super');
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'foo');
  }

  Future<void> test_constructor6() async {
    addTestFile('class A {bool foo; A() : a=7,^ void bar() {}}');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'super');
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'foo');
  }

  Future<void> test_html() {
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

  Future<void> test_import_uri_with_trailing() {
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

  Future<void> test_imports() {
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

  Future<void> test_imports_aborted_new_request() async {
    addTestFile('''
        class foo { }
        c^''');

    // Make a request for suggestions
    var request1 = CompletionGetSuggestionsParams(testFile, completionOffset)
        .toRequest('7');
    var responseFuture1 = waitResponse(request1);

    // Make another request before the first request completes
    var request2 = CompletionGetSuggestionsParams(testFile, completionOffset)
        .toRequest('8');
    var responseFuture2 = waitResponse(request2);

    // Await first response
    var response1 = await responseFuture1;
    var result1 = CompletionGetSuggestionsResult.fromResponse(response1);
    assertValidId(result1.id);

    // Await second response
    var response2 = await responseFuture2;
    var result2 = CompletionGetSuggestionsResult.fromResponse(response2);
    assertValidId(result2.id);

    // Wait for all processing to be complete
    await analysisHandler.server.analysisDriverScheduler.waitForIdle();
    await pumpEventQueue();

    // Assert that first request has been aborted
    expect(allSuggestions[result1.id], hasLength(0));

    // Assert valid results for the second request
    expect(allSuggestions[result2.id], same(suggestions));
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'class');
  }

  @failingTest
  Future<void> test_imports_aborted_source_changed() async {
    // TODO(brianwilkerson) Figure out whether this test makes sense when
    // running the new driver. It waits for an initial empty notification then
    // waits for a new notification. But I think that under the driver we only
    // ever send one notification.
    addTestFile('''
        class foo { }
        c^''');

    // Make a request for suggestions
    var request = CompletionGetSuggestionsParams(testFile, completionOffset)
        .toRequest('0');
    var responseFuture = waitResponse(request);

    // Simulate user deleting text after request but before suggestions returned
    server.updateContent('uc1', {testFile: AddContentOverlay(testCode)});
    server.updateContent('uc2', {
      testFile: ChangeContentOverlay([SourceEdit(completionOffset - 1, 1, '')])
    });

    // Await a response
    var response = await responseFuture;
    completionId = response.id;
    assertValidId(completionId);

    // Wait for all processing to be complete
    await analysisHandler.server.analysisDriverScheduler.waitForIdle();
    await pumpEventQueue();

    // Assert that request has been aborted
    expect(suggestionsDone, isTrue);
    expect(suggestions, hasLength(0));
  }

  Future<void> test_imports_incremental() async {
    addTestFile('''library foo;
      e^
      import "dart:async";
      import "package:foo/foo.dart";
      class foo { }''');
    await waitForTasksFinished();
    server.updateContent('uc1', {testFile: AddContentOverlay(testCode)});
    server.updateContent('uc2', {
      testFile: ChangeContentOverlay([SourceEdit(completionOffset, 0, 'xp')])
    });
    completionOffset += 2;
    await getSuggestions();
    expect(replacementOffset, completionOffset - 3);
    expect(replacementLength, 3);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'export \'\';',
        selectionOffset: 8);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'import \'\';',
        selectionOffset: 8);
    assertNoResult('extends');
    assertNoResult('library');
  }

  Future<void> test_imports_partial() async {
    addTestFile('''^
      import "package:foo/foo.dart";
      import "package:bar/bar.dart";
      class Baz { }''');

    // Wait for analysis then edit the content
    await waitForTasksFinished();
    var revisedContent = testCode.substring(0, completionOffset) +
        'i' +
        testCode.substring(completionOffset);
    ++completionOffset;
    server.handleRequest(AnalysisUpdateContentParams(
        {testFile: AddContentOverlay(revisedContent)}).toRequest('add1'));

    // Request code completion immediately after edit
    var response = await waitResponse(
        CompletionGetSuggestionsParams(testFile, completionOffset)
            .toRequest('0'));
    completionId = response.id;
    assertValidId(completionId);
    await waitForTasksFinished();
    // wait for response to arrive
    // because although the analysis is complete (waitForTasksFinished)
    // the response may not yet have been processed
    while (replacementOffset == null) {
      await Future.delayed(Duration(milliseconds: 5));
    }
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'library');
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'import \'\';',
        selectionOffset: 8);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'export \'\';',
        selectionOffset: 8);
    assertHasResult(CompletionSuggestionKind.KEYWORD, 'part \'\';',
        selectionOffset: 6);
    assertNoResult('extends');
  }

  Future<void> test_imports_prefixed() {
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

  Future<void> test_imports_prefixed2() {
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

  Future<void> test_inComment_block_beforeNode() async {
    addTestFile('''
  main(aaa, bbb) {
    /* text ^ */
    print(42);
  }
  ''');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  Future<void> test_inComment_endOfLine_beforeNode() async {
    addTestFile('''
  main(aaa, bbb) {
    // text ^
    print(42);
  }
  ''');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  Future<void> test_inComment_endOfLine_beforeToken() async {
    addTestFile('''
  main(aaa, bbb) {
    // text ^
  }
  ''');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  Future<void> test_inDartDoc1() async {
    addTestFile('''
  /// ^
  main(aaa, bbb) {}
  ''');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  Future<void> test_inDartDoc2() async {
    addTestFile('''
  /// Some text^
  main(aaa, bbb) {}
  ''');
    await getSuggestions();
    expect(suggestions, isEmpty);
  }

  Future<void> test_inDartDoc_reference1() async {
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
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'main');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'foo');
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'min');
  }

  Future<void> test_inDartDoc_reference2() async {
    addTestFile('''
  /// The [m^]
  main(aaa, bbb) {}
  ''');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'main');
  }

  Future<void> test_inherited() {
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

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request = CompletionGetSuggestionsParams('test.dart', 0).toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request =
        CompletionGetSuggestionsParams(convertPath('/foo/../bar/test.dart'), 0)
            .toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_invocation() {
    addTestFile('class A {b() {}} main() {A a; a.^}');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'b');
    });
  }

  Future<void> test_invocation_withTrailingStmt() {
    addTestFile('class A {b() {}} main() {A a; a.^ int x = 7;}');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'b');
    });
  }

  Future<void> test_is_asPrefixedIdentifierStart() async {
    addTestFile('''
class A { var isVisible;}
main(A p) { var v1 = p.is^; }''');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'isVisible');
  }

  Future<void> test_keyword() {
    addTestFile('library A; cl^');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset - 2));
      expect(replacementLength, equals(2));
      assertHasResult(CompletionSuggestionKind.KEYWORD, 'export \'\';',
          selectionOffset: 8);
      assertHasResult(CompletionSuggestionKind.KEYWORD, 'class');
    });
  }

  Future<void> test_local_implicitCreation() async {
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

  Future<void> test_local_named_constructor() {
    addTestFile('class A {A.c(); x() {new A.^}}');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'c');
      assertNoResult('A');
    });
  }

  Future<void> test_local_override() {
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
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'm');
    });
  }

  Future<void> test_local_shadowClass() async {
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
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'A');

    // Class and all its constructors are shadowed by the local variable.
    assertNoResult('A', elementKind: ElementKind.CLASS);
    assertNoResult('A', elementKind: ElementKind.CONSTRUCTOR);
    assertNoResult('A.named', elementKind: ElementKind.CONSTRUCTOR);
  }

  Future<void> test_locals() {
    addTestFile('class A {var a; x() {var b;^}} class DateTime { }');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'A',
          elementKind: ElementKind.CLASS);
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'a');
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'b');
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'x');
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'DateTime',
          elementKind: ElementKind.CLASS);
    });
  }

  Future<void> test_offset_past_eof() async {
    addTestFile('main() { }', offset: 300);
    var request = CompletionGetSuggestionsParams(testFile, completionOffset)
        .toRequest('0');
    var response = await waitResponse(request);
    expect(response.id, '0');
    expect(response.error.code, RequestErrorCode.INVALID_PARAMETER);
  }

  Future<void> test_overrides() {
    newFile('/project/bin/a.dart', content: 'class A {m() {}}');
    addTestFile('''
import 'a.dart';
class B extends A {m() {^}}
''');
    return getSuggestions().then((_) {
      expect(replacementOffset, equals(completionOffset));
      expect(replacementLength, equals(0));
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'm');
    });
  }

  Future<void> test_partFile() {
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

  Future<void> test_partFile2() {
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

  Future<void> test_sentToPlugins() async {
    addTestFile('''
      void main() {
        ^
      }
    ''');
    PluginInfo info = DiscoveredPluginInfo('a', 'b', 'c', null, null);
    var result = plugin.CompletionGetSuggestionsResult(
        testFile.indexOf('^'), 0, <CompletionSuggestion>[
      CompletionSuggestion(CompletionSuggestionKind.IDENTIFIER,
          DART_RELEVANCE_DEFAULT, 'plugin completion', 3, 0, false, false)
    ]);
    pluginManager.broadcastResults = <PluginInfo, Future<plugin.Response>>{
      info: Future.value(result.toResponse('-', 1))
    };
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.IDENTIFIER, 'plugin completion',
        selectionOffset: 3);
  }

  Future<void> test_simple() {
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

  Future<void> test_static() async {
    addTestFile('class A {static b() {} c() {}} main() {A.^}');
    await getSuggestions();
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
    assertHasResult(CompletionSuggestionKind.INVOCATION, 'b');
    assertNoResult('c');
  }

  Future<void> test_topLevel() {
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
      assertHasResult(CompletionSuggestionKind.INVOCATION, 'test');
      assertNoResult('HtmlElement');
    });
  }
}

@reflectiveTest
class CompletionDomainHandlerListTokenDetailsTest
    extends AbstractCompletionDomainTest {
  String testFileUri;

  Future<void> expectTokens(String content, List<TokenDetails> expected) async {
    newFile(testFile, content: content);
    var request = CompletionListTokenDetailsParams(testFile).toRequest('0');
    var response = await waitResponse(request);
    List<Map<String, dynamic>> tokens = response.result['tokens'];
    _compareTokens(tokens, expected);
  }

  @override
  void setUp() {
    super.setUp();
    testFileUri = toUriStr(testFile);
  }

  Future<void> test_classDeclaration() async {
    await expectTokens('''
class A {}
class B extends A {}
class C implements B {}
class D with C {}
''', [
      token('class', 0, null, null),
      token('A', 6, 'Type',
          ['declaration']), //token('A', 6, 'dart:core;Type', ['declaration']),
      token('{', 8, null, null),
      token('}', 9, null, null),
      token('class', 11, null, null),
      token('B', 17, 'Type',
          ['declaration']), //token('B', 17, 'dart:core;Type', ['declaration']),
      token('extends', 19, null, null),
      token('A', 27, 'dart:core;Type<A>', [
        'reference'
      ]), //token('A', 27, 'dart:core;Type<$testFileUri;A>', ['reference']),
      token('{', 29, null, null),
      token('}', 30, null, null),
      token('class', 32, null, null),
      token('C', 38, 'Type',
          ['declaration']), //token('C', 38, 'dart:core;Type', ['declaration']),
      token('implements', 40, null, null),
      token('B', 51, 'dart:core;Type<B>', [
        'reference'
      ]), //token('B', 51, 'dart:core;Type<$testFileUri;B>', ['reference']),
      token('{', 53, null, null),
      token('}', 54, null, null),
      token('class', 56, null, null),
      token('D', 62, 'Type',
          ['declaration']), //token('D', 62, 'dart:core;Type', ['declaration']),
      token('with', 64, null, null),
      token('C', 69, 'dart:core;Type<C>', [
        'reference'
      ]), //token('C', 69, 'dart:core;Type<$testFileUri;C>', ['reference']),
      token('{', 71, null, null),
      token('}', 72, null, null),
    ]);
  }

  Future<void> test_genericType() async {
    await expectTokens('''
List<int> x = null;
''', [
      token('List', 0, 'dart:core;Type<List>', [
        'reference'
      ]), //token('List', 0, 'dart:core;Type<dart:core;List>', ['reference']),
      token('<', 4, null, null),
      token('int', 5, 'dart:core;Type<int>', [
        'reference'
      ]), //token('int', 5, 'dart:core;Type<dart:core;int>', ['reference']),
      token('>', 8, null, null),
      token('x', 10, 'List',
          ['declaration']), //token('x', 10, 'dart:core;List', ['declaration']),
      token('=', 12, null, null),
      token('null', 14, null, null),
      token(';', 18, null, null),
    ]);
  }

  Future<void> test_getterInvocation() async {
    await expectTokens('''
var x = 'a'.length;
''', [
      token('var', 0, null, null),
      token('x', 4, 'int',
          ['declaration']), //token('x', 4, 'dart:core;int', ['declaration']),
      token('=', 6, null, null),
      token("'a'", 8, 'String',
          null), //token("'a'", 8, 'dart:core;String', null),
      token('.', 11, null, null),
      token('length', 12, 'int',
          ['reference']), //token('length', 12, 'dart:core;int', ['reference']),
      token(';', 18, null, null),
    ]);
  }

  Future<void> test_literal_bool() async {
    await expectTokens('''
var x = true;
''', [
      token('var', 0, null, null),
      token('x', 4, 'bool',
          ['declaration']), //token('x', 4, 'dart:core;bool', ['declaration']),
      token('=', 6, null, null),
      token(
          'true', 8, 'bool', null), //token('true', 8, 'dart:core;bool', null),
      token(';', 12, null, null),
    ]);
  }

  Future<void> test_literal_double() async {
    await expectTokens('''
var x = 3.4;
''', [
      token('var', 0, null, null),
      token('x', 4, 'double', [
        'declaration'
      ]), //token('x', 4, 'dart:core;double', ['declaration']),
      token('=', 6, null, null),
      token('3.4', 8, 'double',
          null), //token('3.4', 8, 'dart:core;double', null),
      token(';', 11, null, null),
    ]);
  }

  Future<void> test_literal_int() async {
    await expectTokens('''
var x = 7;
''', [
      token('var', 0, null, null),
      token('x', 4, 'int',
          ['declaration']), //token('x', 4, 'dart:core;int', ['declaration']),
      token('=', 6, null, null),
      token('7', 8, 'int', null), //token('7', 8, 'dart:core;int', null),
      token(';', 9, null, null),
    ]);
  }

  Future<void> test_literal_list() async {
    await expectTokens('''
var x = <int>[];
''', [
      token('var', 0, null, null),
      token('x', 4, 'List',
          ['declaration']), //token('x', 4, 'dart:core;List', ['declaration']),
      token('=', 6, null, null),
      token('<', 8, null, null),
      token('int', 9, 'dart:core;Type<int>', [
        'reference'
      ]), //token("int", 9, 'dart:core;Type<dart:core;int>', ['reference']),
      token('>', 12, null, null),
      token('[', 13, null, null),
      token(']', 14, null, null),
      token(';', 15, null, null),
    ]);
  }

  Future<void> test_literal_map() async {
    await expectTokens('''
var x = <int, int>{};
''', [
      token('var', 0, null, null),
      token('x', 4, 'Map',
          ['declaration']), //token('x', 4, 'dart:core;Map', ['declaration']),
      token('=', 6, null, null),
      token('<', 8, null, null),
      token('int', 9, 'dart:core;Type<int>', [
        'reference'
      ]), //token("int", 9, 'dart:core;Type<dart:core;int>', ['reference']),
//      token(',', null, null),
      token('int', 14, 'dart:core;Type<int>', [
        'reference'
      ]), //token("int", 14, 'dart:core;Type<dart:core;int>', ['reference']),
      token('>', 17, null, null),
      token('{', 18, null, null),
      token('}', 19, null, null),
      token(';', 20, null, null),
    ]);
  }

  Future<void> test_literal_null() async {
    await expectTokens('''
var x = null;
''', [
      token('var', 0, null, null),
      token('x', 4, 'dynamic', ['declaration']),
      token('=', 6, null, null),
      token('null', 8, null, null),
      token(';', 12, null, null),
    ]);
  }

  Future<void> test_literal_set() async {
    await expectTokens('''
var x = <int>{};
''', [
      token('var', 0, null, null),
      token('x', 4, 'Set',
          ['declaration']), //token('x', 4, 'dart:core;Set', ['declaration']),
      token('=', 6, null, null),
      token('<', 8, null, null),
      token('int', 9, 'dart:core;Type<int>', [
        'reference'
      ]), //token("int", 9, 'dart:core;Type<dart:core;int>', ['reference']),
      token('>', 12, null, null),
      token('{', 13, null, null),
      token('}', 14, null, null),
      token(';', 15, null, null),
    ]);
  }

  Future<void> test_literal_string() async {
    await expectTokens('''
var x = 'a';
''', [
      token('var', 0, null, null),
      token('x', 4, 'String', [
        'declaration'
      ]), //token('x', 4, 'dart:core;String', ['declaration']),
      token('=', 6, null, null),
      token("'a'", 8, 'String',
          null), //token("'a'", 8, 'dart:core;String', null),
      token(';', 11, null, null),
    ]);
  }

  Future<void> test_methodDeclaration() async {
    await expectTokens('''
class A {
  String c(int x, int y) {}
}
''', [
      token('class', 0, null, null),
      token('A', 6, 'Type', ['declaration']),
      //token('A', 6, 'dart:core;Type', ['declaration']),
      token('{', 8, null, null),
      token('String', 12, 'dart:core;Type<String>', ['reference']),
      //token('String', 12, 'dart:core;Type<dart:core;String>', ['reference']),
      token('c', 19, 'String Function(int, int)',
          //'dart:core;String Function(dart:core;int, dart:core;int)',
          ['declaration']),
      token('(', 20, null, null),
      token('int', 21, 'dart:core;Type<int>', ['reference']),
      //token('int', 21, 'dart:core;Type<dart:core;int>', ['reference']),
      token('x', 25, 'int', ['declaration']),
      //token('x', 25, 'dart:core;int', ['declaration']),
//      token(',', null, null),
      token('int', 28, 'dart:core;Type<int>', ['reference']),
      //token('int', 28, 'dart:core;Type<dart:core;int>', ['reference']),
      token('y', 32, 'int', ['declaration']),
      //token('y', 32, 'dart:core;int', ['declaration']),
      token(')', 33, null, null),
      token('{', 35, null, null),
      token('}', 36, null, null),
      token('}', 38, null, null),
    ]);
  }

  Future<void> test_methodInvocation() async {
    await expectTokens('''
var x = 'radar'.indexOf('r', 1);
''', [
      token('var', 0, null, null),
      token('x', 4, 'int',
          ['declaration']), //token('x', 4, 'dart:core;int', ['declaration']),
      token('=', 6, null, null),
      token("'radar'", 8, 'String',
          null), //token("'radar'", 8, 'dart:core;String', null),
      token('.', 15, null, null),
      token('indexOf', 16, 'int Function(Pattern, int)',
          //'dart:core;int Function(dart:core;Pattern, dart:core;int)',
          ['reference']),
      token('(', 23, null, null),
      token("'r'", 24, 'String',
          null), //token("'r'", 24, 'dart:core;String', null),
//      token(',', null, null),
      token('1', 29, 'int', null), //token('1', 29, 'dart:core;int', null),
      token(')', 30, null, null),
      token(';', 31, null, null),
    ]);
  }

  Future<void> test_mixinDeclaration() async {
    await expectTokens('''
class A {}
class B {}
mixin D on A implements B {}
''', [
      token('class', 0, null, null),
      token('A', 6, 'Type',
          ['declaration']), //token('A', 6, 'dart:core;Type', ['declaration']),
      token('{', 8, null, null),
      token('}', 9, null, null),
      token('class', 11, null, null),
      token('B', 17, 'Type',
          ['declaration']), //token('B', 17, 'dart:core;Type', ['declaration']),
      token('{', 19, null, null),
      token('}', 20, null, null),
      token('mixin', 22, null, null),
      token('D', 28, 'Type',
          ['declaration']), //token('D', 28, 'dart:core;Type', ['declaration']),
      token('on', 30, null, null),
      token('A', 33, 'dart:core;Type<A>', [
        'reference'
      ]), //token('A', 33, 'dart:core;Type<$testFileUri;A>', ['reference']),
      token('implements', 35, null, null),
      token('B', 46, 'dart:core;Type<B>', [
        'reference'
      ]), //token('B', 'dart:core;Type<$testFileUri;B>', ['reference']),
      token('{', 48, null, null),
      token('}', 49, null, null),
    ]);
  }

  Future<void> test_parameterReference() async {
    await expectTokens('''
int f(int p) {
  return p;
}
''', [
      token('int', 0, 'dart:core;Type<int>', ['reference']),
      //token('int', 0, 'dart:core;Type<dart:core;int>', ['reference']),
      token('f', 4, 'int Function(int)', ['declaration']),
      //token('f', 4, 'dart:core;int Function(dart:core;int)', ['declaration']),
      token('(', 5, null, null),
      token('int', 6, 'dart:core;Type<int>', ['reference']),
      //token('int', 6, 'dart:core;Type<dart:core;int>', ['reference']),
      token('p', 10, 'int', ['declaration']),
      //token('p', 10, 'dart:core;int', ['declaration']),
      token(')', 11, null, null),
      token('{', 13, null, null),
      token('return', 17, null, null),
      token('p', 24, 'int', ['reference']),
      //token('p', 24, 'dart:core;int', ['reference']),
      token(';', 25, null, null),
      token('}', 27, null, null),
    ]);
  }

  Future<void> test_topLevelVariable_withDocComment() async {
    await expectTokens('''
/// Doc comment [x] with reference.
int x;
''', [
      token('int', 36, 'dart:core;Type<int>', [
        'reference'
      ]), //token('int', 36, 'dart:core;Type<dart:core;int>', ['reference']),
      token('x', 40, 'int',
          ['declaration']), //token('x', 40, 'dart:core;int', ['declaration']),
      token(';', 41, null, null),
    ]);
  }

  TokenDetails token(
      String lexeme, int offset, String type, List<String> kinds) {
    return TokenDetails(lexeme, offset, type: type, validElementKinds: kinds);
  }

  void _compareTokens(List<Map<String, dynamic>> actualTokens,
      List<TokenDetails> expectedTokens) {
    var length = expectedTokens.length;
    expect(actualTokens, hasLength(length));
    var errors = <String>[];
    for (var i = 0; i < length; i++) {
      var actual = actualTokens[i];
      var expected = expectedTokens[i];
      if (actual['lexeme'] != expected.lexeme) {
        errors.add('Lexeme at $i: '
            'expected "${expected.lexeme}", '
            'actual "${actual['lexeme']}"');
      }
      if (actual['offset'] != expected.offset) {
        errors.add('Offset at $i: ("${expected.lexeme}"): '
            'expected "${expected.offset}", '
            'actual "${actual['offset']}"');
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
    var expectedLength = expected.length;
    if (actual.length != expectedLength) {
      return true;
    }
    for (var i = 0; i < expectedLength; i++) {
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
    return Future.value();
  }
}
