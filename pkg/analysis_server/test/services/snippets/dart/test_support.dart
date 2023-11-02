// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/snippets/dart_snippet_request.dart';
import 'package:analysis_server/src/services/snippets/snippet.dart';
import 'package:analysis_server/src/services/snippets/snippet_manager.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';

import '../../../abstract_single_unit.dart';

export '../test_support.dart';

abstract class DartSnippetProducerTest extends AbstractSingleUnitTest {
  SnippetProducerGenerator get generator;
  String get label;
  String get prefix;

  /// Override the package root because it usually contains /test/ and some
  /// snippets behave differently for test files.
  @override
  String get testPackageRootPath => '$workspaceRootPath/my_package';

  @override
  bool get verifyNoTestUnitErrors => false;

  Future<void> assertSnippet(String content, String expected) async {
    final code = TestCode.parse(content);
    final expectedCode = TestCode.parse(expected);
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));

    // Apply the edits and check the results.
    var codeResult = code.code;
    for (var edit in snippet.change.edits) {
      codeResult = SourceEdit.applySequence(codeResult, edit.edits);
    }
    expect(codeResult, expectedCode.code);

    // Check selection/position.
    expect(snippet.change.selection!.file, testFile.path);
    expect(snippet.change.selection!.offset, expectedCode.position.offset);

    // And linked edits.
    final expectedLinkedGroups = expectedCode.ranges
        .map(
          (range) => {
            'positions': [
              {
                'file': testFile.path,
                'offset': range.sourceRange.offset,
              },
            ],
            'length': range.sourceRange.length,
            'suggestions': [],
          },
        )
        .toSet();
    final actualLinkedGroups =
        snippet.change.linkedEditGroups.map((group) => group.toJson()).toSet();
    expect(actualLinkedGroups, equals(expectedLinkedGroups));
  }

  Future<void> expectNotValidSnippet(String content) async {
    final code = TestCode.parse(content);
    await resolveTestCode(code.code);
    final request = DartSnippetRequest(
      unit: testAnalysisResult,
      offset: code.position.offset,
    );

    final producer = generator(request, elementImportCache: {});
    expect(await producer.isValid(), isFalse);
  }

  Future<Snippet> expectValidSnippet(TestCode code) async {
    await resolveTestCode(code.code);
    final request = DartSnippetRequest(
      unit: testAnalysisResult,
      offset: code.position.offset,
    );

    final producer = generator(request, elementImportCache: {});
    expect(await producer.isValid(), isTrue);
    return producer.compute();
  }
}

abstract class FlutterSnippetProducerTest extends DartSnippetProducerTest {
  /// Asserts that [change] matches the code in [expected], has a selection
  /// matching its range and a single linked edit group containing all of its
  /// positions.
  void assertFlutterSnippetChange(
    SourceChange change,
    String linkedGroupText,
    TestCode expected,
  ) {
    expect(change.edits, hasLength(1));
    final code = SourceEdit.applySequence('', change.edits.single.edits);
    expect(code, expected.code);

    expect(change.selection!.file, testFile.path);
    expect(change.selection!.offset, expected.range.sourceRange.offset);
    expect(change.selectionLength, expected.range.sourceRange.length);
    expect(change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          for (final position in expected.positions)
            {'file': testFile.path, 'offset': position.offset},
        ],
        'length': linkedGroupText.length,
        'suggestions': []
      }
    ]);
  }

  /// Checks snippets can produce edits where the imports and snippet will be
  /// inserted at the same location.
  ///
  /// For example, when a document is completely empty besides the snippet
  /// prefix, the imports will be inserted at offset 0 and the snippet will
  /// replace from 0 to the end of the typed prefix.
  Future<void> test_valid_importsAndEditsOverlap() async {
    writeTestPackageConfig(flutter: true);

    final snippet = await expectValidSnippet(TestCode.parse('$prefix^'));
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);

    // Main edits replace $prefix.length characters starting at $prefix
    final mainEdit = snippet.change.edits[0].edits[0];
    expect(mainEdit.offset, testCode.indexOf(prefix));
    expect(mainEdit.length, prefix.length);

    // Imports inserted at start of doc (0)
    final importEdit = snippet.change.edits[0].edits[1];
    expect(importEdit.offset, 0);
    expect(importEdit.length, 0);
  }

  Future<void> test_valid_suffixReplacement() async {
    writeTestPackageConfig(flutter: true);

    final snippet = await expectValidSnippet(TestCode.parse('''
class A {}

$prefix^
'''));
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);

    // Main edits replace $prefix.length characters starting at $prefix
    final mainEdit = snippet.change.edits[0].edits[0];
    expect(mainEdit.offset, testCode.indexOf(prefix));
    expect(mainEdit.length, prefix.length);

    // Imports inserted at start of doc (0)
    final importEdit = snippet.change.edits[0].edits[1];
    expect(importEdit.offset, 0);
    expect(importEdit.length, 0);
  }
}
