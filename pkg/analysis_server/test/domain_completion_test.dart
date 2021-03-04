// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
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

  Future<void>
      test_ArgumentList_function_named_fromPositionalNumeric_withoutSpace() async {
    addTestFile('void f(int a, {int b = 0}) {}'
        'void g() { f(2, ^3); }');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'b: ');
    expect(suggestions, hasLength(1));
    // Ensure we don't try to replace the following arg.
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
  }

  Future<void>
      test_ArgumentList_function_named_fromPositionalNumeric_withSpace() async {
    addTestFile('void f(int a, {int b = 0}) {}'
        'void g() { f(2, ^ 3); }');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'b: ');
    expect(suggestions, hasLength(1));
    // Ensure we don't try to replace the following arg.
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
  }

  Future<void>
      test_ArgumentList_function_named_fromPositionalVariable_withoutSpace() async {
    addTestFile('void f(int a, {int b = 0}) {}'
        'var foo = 1;'
        'void g() { f(2, ^foo); }');
    await getSuggestions();
    expect(suggestions, hasLength(1));

    // The named arg "b: " should not replace anything.
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'b: ',
        replacementOffset: null, replacementLength: 0);
  }

  Future<void>
      test_ArgumentList_function_named_fromPositionalVariable_withSpace() async {
    addTestFile('void f(int a, {int b = 0}) {}'
        'var foo = 1;'
        'void g() { f(2, ^ foo); }');
    await getSuggestions();
    assertHasResult(CompletionSuggestionKind.NAMED_ARGUMENT, 'b: ');
    expect(suggestions, hasLength(1));
    // Ensure we don't try to replace the following arg.
    expect(replacementOffset, equals(completionOffset));
    expect(replacementLength, equals(0));
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
    await analysisHandler.server.onAnalysisComplete;
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
    await analysisHandler.server.onAnalysisComplete;
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

  Future<void> test_inComment_endOfFile() async {
    addTestFile('''
    // text ^
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
