// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/cider/completion.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show CompletionSuggestion, CompletionSuggestionKind, ElementKind;
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'cider_service.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CiderCompletionComputerTest);
  });
}

@reflectiveTest
class CiderCompletionComputerTest extends CiderServiceTest {
  final CiderCompletionCache _completionCache = CiderCompletionCache();

  CiderCompletionComputer _computer;
  CiderCompletionResult _completionResult;
  List<CompletionSuggestion> _suggestions;

  @override
  void setUp() {
    super.setUp();
  }

  Future<void> test_compute() async {
    await _compute(r'''
class A {}

int a = 0;

main(int b) {
  int c = 0;
  ^
}
''');

    _assertHasCompletion(text: 'a');
    _assertHasCompletion(text: 'b');
    _assertHasCompletion(text: 'c');
    _assertHasClass(text: 'A');
    _assertHasClass(text: 'String');

    _assertNoClass(text: 'Random');
  }

  Future<void> test_compute_prefixStart_hasPrefix() async {
    await _compute('''
class A {
  String foobar;
}

main(A a) {
  a.foo^
}
''');
    expect(_completionResult.prefixStart.line, 5);
    expect(_completionResult.prefixStart.column, 4);
  }

  Future<void> test_compute_prefixStart_noPrefix() async {
    await _compute(r'''
import 'dart:math';
^
''');
    expect(_completionResult.prefixStart.line, 1);
    expect(_completionResult.prefixStart.column, 0);
  }

  Future<void> test_compute_updateImportedLibrary() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, content: r'''
class A {}
''');

    var content = r'''
import 'a.dart';
^
''';

    await _compute(content);
    _assertComputedImportedLibraries([aPath], hasCore: true);
    _assertHasClass(text: 'A');

    // Repeat the query, still has 'A'.
    _createFileResolver();
    await _compute(content);
    _assertComputedImportedLibraries([]);
    _assertHasClass(text: 'A');

    // Update the imported library, has 'B', but not 'A'.
    newFile(aPath, content: r'''
class B {}
''');
    _createFileResolver();
    await _compute(content);
    _assertComputedImportedLibraries([aPath]);
    _assertHasClass(text: 'B');
    _assertNoClass(text: 'A');
  }

  Future<void> test_compute_updateImports() async {
    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, content: r'''
class A {}
''');

    await _compute(r'''
var a = ^;
''');
    _assertComputedImportedLibraries([], hasCore: true);
    _assertHasClass(text: 'String');

    // Repeat the query, still has 'A'.
    _createFileResolver();
    await _compute(r'''
import 'a.dart';
var a = ^;
''');
    _assertComputedImportedLibraries([aPath]);
    _assertHasClass(text: 'A');
    _assertHasClass(text: 'String');
  }

  Future<void> test_filterSort_byPattern_excludeNotMatching() async {
    await _compute(r'''
var a = F^;
''');

    _assertHasClass(text: 'Future');
    _assertNoClass(text: 'String');
  }

  Future<void> test_filterSort_byPattern_location_beforeMethod() async {
    await _compute(r'''
class A {
  F^
  void foo() {}
}
''');

    _assertHasClass(text: 'Future');
    _assertNoClass(text: 'String');
  }

  Future<void> test_filterSort_byPattern_location_functionReturnType() async {
    await _compute(r'''
F^ foo() {}
''');

    _assertHasClass(text: 'Future');
    _assertNoClass(text: 'String');
  }

  Future<void> test_filterSort_byPattern_location_methodReturnType() async {
    await _compute(r'''
class A {
  F^ foo() {}
}
''');

    _assertHasClass(text: 'Future');
    _assertNoClass(text: 'String');
  }

  Future<void> test_filterSort_byPattern_location_parameterType() async {
    await _compute(r'''
void foo(F^ a) {}
''');

    _assertHasClass(text: 'Future');
    _assertNoClass(text: 'String');
  }

  Future<void> test_filterSort_byPattern_location_parameterType2() async {
    await _compute(r'''
void foo(^a) {}
''');

    _assertHasClass(text: 'Future');
    _assertHasClass(text: 'String');
  }

  Future<void> test_filterSort_byPattern_location_statement() async {
    await _compute(r'''
main() {
  F^
  0;
}
''');

    _assertHasClass(text: 'Future');
    _assertNoClass(text: 'String');
  }

  Future<void> test_filterSort_byPattern_preferPrefix() async {
    await _compute(r'''
class Foobar {}
class Falcon {}
var a = Fo^;
''');

    _assertOrder([
      _assertHasClass(text: 'Foobar'),
      _assertHasClass(text: 'Falcon'),
    ]);
  }

  Future<void> test_filterSort_namedArgument_hasPrefix() async {
    await _compute(r'''
void foo({int aaa, int bbb});

void f() {
  foo(a^);
}
''');

    _assertHasNamedArgument(name: 'aaa');
    _assertNoNamedArgument(name: 'bbb');
  }

  Future<void> test_filterSort_namedArgument_noPrefix() async {
    await _compute(r'''
void foo({int aaa, int bbb});

void f() {
  foo(^);
}
''');

    _assertHasNamedArgument(name: 'aaa');
    _assertHasNamedArgument(name: 'bbb');
  }

  Future<void> test_filterSort_preferLocal() async {
    await _compute(r'''
var a = 0;
main() {
  var b = 0;
  var v = ^;
}
''');

    _assertOrder([
      _assertHasLocalVariable(text: 'b'),
      _assertHasTopLevelVariable(text: 'a'),
    ]);
  }

  Future<void> test_filterSort_sortByName() async {
    await _compute(r'''
main() {
  var a = 0;
  var b = 0;
  var v = ^;
}
''');

    _assertOrder([
      _assertHasLocalVariable(text: 'a'),
      _assertHasLocalVariable(text: 'b'),
    ]);
  }

  void _assertComputedImportedLibraries(
    List<String> expected, {
    bool hasCore = false,
  }) {
    expected = expected.map(convertPath).toList();

    if (hasCore) {
      var corePath = convertPath('/sdk/lib/core/core.dart');
      expected.add(corePath);
    }

    expect(
      _computer.computedImportedLibraries,
      unorderedEquals(expected),
    );
  }

  CompletionSuggestion _assertHasClass({@required String text}) {
    var matching = _matchingCompletions(
      text: text,
      elementKind: ElementKind.CLASS,
    );
    expect(matching, hasLength(1), reason: 'Expected exactly one completion');
    return matching.single;
  }

  void _assertHasCompletion({@required String text}) {
    var matching = _matchingCompletions(text: text);
    expect(matching, hasLength(1), reason: 'Expected exactly one completion');
  }

  CompletionSuggestion _assertHasLocalVariable({@required String text}) {
    var matching = _matchingCompletions(
      text: text,
      elementKind: ElementKind.LOCAL_VARIABLE,
    );
    expect(
      matching,
      hasLength(1),
      reason: 'Expected exactly one completion in $_suggestions',
    );
    return matching.single;
  }

  CompletionSuggestion _assertHasNamedArgument({@required String name}) {
    var matching = _matchingNamedArgumentSuggestions(name: name);
    expect(matching, hasLength(1), reason: 'Expected exactly one completion');
    return matching.single;
  }

  CompletionSuggestion _assertHasTopLevelVariable({@required String text}) {
    var matching = _matchingCompletions(
      text: text,
      elementKind: ElementKind.TOP_LEVEL_VARIABLE,
    );
    expect(
      matching,
      hasLength(1),
      reason: 'Expected exactly one completion in $_suggestions',
    );
    return matching.single;
  }

  void _assertNoClass({@required String text}) {
    var matching = _matchingCompletions(
      text: text,
      elementKind: ElementKind.CLASS,
    );
    expect(matching, isEmpty, reason: 'Expected zero completions');
  }

  void _assertNoNamedArgument({@required String name}) {
    var matching = _matchingNamedArgumentSuggestions(name: name);
    expect(matching, isEmpty, reason: 'Expected zero completions');
  }

  void _assertOrder(List<CompletionSuggestion> suggestions) {
    var lastIndex = -2;
    for (var suggestion in suggestions) {
      var index = _suggestions.indexOf(suggestion);
      expect(index, isNonNegative, reason: '$suggestion');
      expect(index, greaterThan(lastIndex), reason: '$suggestion');
      lastIndex = index;
    }
  }

  Future _compute(String content) async {
    var context = _updateFile(content);

    _completionResult = await _newComputer().compute(
      path: convertPath(testPath),
      line: context.line,
      column: context.character,
    );
    _suggestions = _completionResult.suggestions;
  }

  /// TODO(scheglov) Implement incremental updating
  void _createFileResolver() {
    createFileResolver();
  }

  List<CompletionSuggestion> _matchingCompletions({
    @required String text,
    ElementKind elementKind,
  }) {
    return _suggestions.where((e) {
      if (e.completion != text) {
        return false;
      }

      if (elementKind != null && e.element.kind != elementKind) {
        return false;
      }

      return true;
    }).toList();
  }

  List<CompletionSuggestion> _matchingNamedArgumentSuggestions({
    @required String name,
  }) {
    return _suggestions.where((e) {
      if (e.kind != CompletionSuggestionKind.NAMED_ARGUMENT) {
        return false;
      }

      if (!e.completion.startsWith('$name:')) {
        return false;
      }

      return true;
    }).toList();
  }

  CiderCompletionComputer _newComputer() {
    return _computer = CiderCompletionComputer(
      logger,
      _completionCache,
      fileResolver,
    );
  }

  _CompletionContext _updateFile(String content) {
    var offset = content.indexOf('^');
    expect(offset, isPositive, reason: 'Expected to find ^');
    expect(content.indexOf('^', offset + 1), -1, reason: 'Expected only one ^');

    var lineInfo = LineInfo.fromContent(content);
    var location = lineInfo.getLocation(offset);

    content = content.substring(0, offset) + content.substring(offset + 1);
    newFile(testPath, content: content);

    return _CompletionContext(
      content,
      offset,
      location.lineNumber - 1,
      location.columnNumber - 1,
    );
  }
}

class _CompletionContext {
  final String content;
  final int offset;
  final int line;
  final int character;

  _CompletionContext(this.content, this.offset, this.line, this.character);
}
