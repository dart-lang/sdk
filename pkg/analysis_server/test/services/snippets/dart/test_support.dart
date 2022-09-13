// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart_snippet_request.dart';
import 'package:analysis_server/src/services/snippets/snippet.dart';
import 'package:analysis_server/src/services/snippets/snippet_manager.dart';
import 'package:test/test.dart';

import '../../../abstract_single_unit.dart';
import '../test_support.dart';

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

  Future<void> expectNotValidSnippet(
    String code,
  ) async {
    await resolveTestCode(withoutMarkers(code));
    final request = DartSnippetRequest(
      unit: testAnalysisResult,
      offset: offsetFromMarker(code),
    );

    final producer = generator(request);
    expect(await producer.isValid(), isFalse);
  }

  Future<Snippet> expectValidSnippet(String code) async {
    await resolveTestCode(withoutMarkers(code));
    final request = DartSnippetRequest(
      unit: testAnalysisResult,
      offset: offsetFromMarker(code),
    );

    final producer = generator(request);
    expect(await producer.isValid(), isTrue);
    return producer.compute();
  }
}

abstract class FlutterSnippetProducerTest extends DartSnippetProducerTest {
  /// Checks snippets can produce edits where the imports and snippet will be
  /// inserted at the same location.
  ///
  /// For example, when a document is completely empty besides the snippet
  /// prefix, the imports will be inserted at offset 0 and the snippet will
  /// replace from 0 to the end of the typed prefix.
  Future<void> test_valid_importsAndEditsOverlap() async {
    writeTestPackageConfig(flutter: true);

    final snippet = await expectValidSnippet('$prefix^');
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

    final snippet = await expectValidSnippet('''
class A {}

$prefix^
''');
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
