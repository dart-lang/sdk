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

  String applySnippet(TestCode code, Snippet snippet) {
    var result = code.code;
    for (var edit in snippet.change.edits) {
      result = SourceEdit.applySequence(result, edit.edits);
    }
    return result;
  }

  /// Verify a snippet is available and that applying it to [content] produces
  /// [expected].
  ///
  /// The marked position (`^`) in [content] is where snippets will be requested
  /// for.
  ///
  /// The marked position (`^`) in [expected] is where the resulting selection
  /// is expected to be. The marked ranges in [expected] are where linked edit
  /// groups / placeholders appear.
  Future<Snippet> assertSnippetResult(String content, String expected) async {
    var code = TestCode.parse(normalizeSource(content));
    var expectedCode = TestCode.parse(normalizeSource(expected));
    var snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));

    // Apply the edits and check the results.
    var codeResult = applySnippet(code, snippet);
    expect(codeResult, expectedCode.code);

    // Check selection/position.
    expect(snippet.change.selection!.file, testFile.path);
    if (expectedCode.positions.length == 1) {
      expect(snippet.change.selection!.offset, expectedCode.position.offset);
    }

    // And linked edits if the test is verifying them.
    if (expectedCode.ranges.isNotEmpty) {
      var expectedLinkedGroups =
          expectedCode.ranges
              .map(
                (range) => {
                  'positions': [
                    {'file': testFile.path, 'offset': range.sourceRange.offset},
                  ],
                  'length': range.sourceRange.length,
                  'suggestions': [],
                },
              )
              .toSet();
      var actualLinkedGroups =
          snippet.change.linkedEditGroups
              .map((group) => group.toJson())
              .toSet();
      expect(actualLinkedGroups, equals(expectedLinkedGroups));
    }

    return snippet;
  }

  Future<void> expectNotValidSnippet(String content) async {
    var code = TestCode.parse(content);
    await resolveTestCode(code.code);
    var request = DartSnippetRequest(
      unit: testAnalysisResult,
      offset: code.position.offset,
    );

    var producer = generator(request, elementImportCache: {});
    expect(await producer.isValid(), isFalse);
  }

  Future<Snippet> expectValidSnippet(TestCode code) async {
    await resolveTestCode(code.code);
    var request = DartSnippetRequest(
      unit: testAnalysisResult,
      offset: code.position.offset,
    );

    var producer = generator(request, elementImportCache: {});
    expect(await producer.isValid(), isTrue);
    return producer.compute();
  }
}

abstract class FlutterSnippetProducerTest extends DartSnippetProducerTest {
  /// A version of [assertSnippetResult] that expects all positions in
  /// [expectedCode] to match a single linked edit group for the text
  /// [linkedGroupText] and the selection to be at the marked range.
  Future<void> assertFlutterSnippetResult(
    String content,
    String expected,
    String linkedGroupText,
  ) async {
    var code = TestCode.parse(normalizeSource(content));
    var expectedCode = TestCode.parse(normalizeSource(expected));
    var expectedSelection = expectedCode.range.sourceRange;

    var snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));

    // Apply the edits and check the results.
    var codeResult = applySnippet(code, snippet);
    expect(codeResult, expectedCode.code);

    var change = snippet.change;
    expect(change.selection!.file, testFile.path);
    expect(change.selection!.offset, expectedSelection.offset);
    expect(change.selectionLength, expectedSelection.length);
    expect(change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          for (final position in expectedCode.positions)
            {'file': testFile.path, 'offset': position.offset},
        ],
        'length': linkedGroupText.length,
        'suggestions': [],
      },
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

    var snippet = await expectValidSnippet(TestCode.parse('$prefix^'));
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);

    // Main edits replace $prefix.length characters starting at $prefix
    var mainEdit = snippet.change.edits[0].edits[0];
    expect(mainEdit.offset, testCode.indexOf(prefix));
    expect(mainEdit.length, prefix.length);

    // Imports inserted at start of doc (0)
    var importEdit = snippet.change.edits[0].edits[1];
    expect(importEdit.offset, 0);
    expect(importEdit.length, 0);
  }

  Future<void> test_valid_suffixReplacement() async {
    writeTestPackageConfig(flutter: true);

    var snippet = await expectValidSnippet(
      TestCode.parse('''
class A {}

$prefix^
'''),
    );
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);

    // Main edits replace $prefix.length characters starting at $prefix
    var mainEdit = snippet.change.edits[0].edits[0];
    expect(mainEdit.offset, testCode.indexOf(prefix));
    expect(mainEdit.length, prefix.length);

    // Imports inserted at start of doc (0)
    var importEdit = snippet.change.edits[0].edits[1];
    expect(importEdit.offset, 0);
    expect(importEdit.length, 0);
  }
}
