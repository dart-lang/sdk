// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/cider/completion.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show CompletionSuggestion, ElementKind;
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
    var context = _updateFile(r'''
class A {}

int a = 0;

main(int b) {
  int c = 0;
  ^
}
''');

    // ignore: deprecated_member_use_from_same_package
    _suggestions = await _newComputer().compute(
      convertPath(testPath),
      context.offset,
    );

    _assertHasCompletion(text: 'a');
    _assertHasCompletion(text: 'b');
    _assertHasCompletion(text: 'c');
    _assertHasClass(text: 'A');
    _assertHasClass(text: 'String');

    _assertNoClass(text: 'Random');
  }

  Future<void> test_compute2() async {
    await _compute2(r'''
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

  Future<void> test_compute2_sameSignature_sameResult() async {
    _createFileResolver();
    await _compute2(r'''
var a = ^;
''');
    var lastResult = _completionResult;

    // Ask for completion using new resolver and computer.
    // But the file signature is the same, so the same result.
    _createFileResolver();
    await _compute2(r'''
var a = ^;
''');
    expect(_completionResult, same(lastResult));
  }

  Future<void> test_compute2_updateImportedLibrary() async {
    var corePath = convertPath('/sdk/lib/core/core.dart');

    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, content: r'''
class A {}
''');

    var content = r'''
import 'a.dart';
^
''';

    _createFileResolver();
    await _compute2(content);
    _assertComputedImportedLibraries([corePath, aPath]);
    _assertHasClass(text: 'A');

    // Repeat the query, still has 'A'.
    _createFileResolver();
    await _compute2(content);
    _assertComputedImportedLibraries([]);
    _assertHasClass(text: 'A');

    // Update the imported library, has 'B', but not 'A'.
    newFile(aPath, content: r'''
class B {}
''');
    _createFileResolver();
    await _compute2(content);
    _assertComputedImportedLibraries([aPath]);
    _assertHasClass(text: 'B');
    _assertNoClass(text: 'A');
  }

  Future<void> test_compute2_updateImports() async {
    var corePath = convertPath('/sdk/lib/core/core.dart');

    var aPath = convertPath('/workspace/dart/test/lib/a.dart');
    newFile(aPath, content: r'''
class A {}
''');

    _createFileResolver();
    await _compute2(r'''
var a = ^;
''');
    _assertComputedImportedLibraries([corePath]);
    _assertHasClass(text: 'String');

    // Repeat the query, still has 'A'.
    _createFileResolver();
    await _compute2(r'''
import 'a.dart';
var a = ^;
''');
    _assertComputedImportedLibraries([aPath]);
    _assertHasClass(text: 'A');
    _assertHasClass(text: 'String');
  }

  void _assertComputedImportedLibraries(List<String> expected) {
    expected = expected.map(convertPath).toList();
    expect(
      _computer.computedImportedLibraries,
      unorderedEquals(expected),
    );
  }

  void _assertHasClass({@required String text}) {
    var matching = _matchingCompletions(
      text: text,
      elementKind: ElementKind.CLASS,
    );
    expect(matching, hasLength(1), reason: 'Expected exactly one completion');
  }

  void _assertHasCompletion({@required String text}) {
    var matching = _matchingCompletions(text: text);
    expect(matching, hasLength(1), reason: 'Expected exactly one completion');
  }

  void _assertNoClass({@required String text}) {
    var matching = _matchingCompletions(
      text: text,
      elementKind: ElementKind.CLASS,
    );
    expect(matching, isEmpty, reason: 'Expected zero completions');
  }

  Future _compute2(String content) async {
    var context = _updateFile(content);

    _completionResult = await _newComputer().compute2(
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

  CiderCompletionComputer _newComputer() {
    return _computer = CiderCompletionComputer(
      logger,
      _completionCache,
      fileResolver,
    );
  }

  _CompletionContext _updateFile(String content) {
    newFile(testPath, content: content);

    var offset = content.indexOf('^');
    expect(offset, isPositive, reason: 'Expected to find ^');
    expect(content.indexOf('^', offset + 1), -1, reason: 'Expected only one ^');

    var lineInfo = LineInfo.fromContent(content);
    var location = lineInfo.getLocation(offset);

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
