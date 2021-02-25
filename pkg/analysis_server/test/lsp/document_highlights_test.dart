// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentHighlightsTest);
  });
}

@reflectiveTest
class DocumentHighlightsTest extends AbstractLspAnalysisServerTest {
  Future<void> test_functions() => _testMarkedContent('''
    [[main]]() {
      [[mai^n]]();
    }
    ''');

  Future<void> test_invalidLineByOne() async {
    // Test that requesting a line that's too high by one returns a valid
    // error response instead of throwing.
    const content = '// single line';

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    // Lines are zero-based so 1 is invalid.
    final pos = Position(line: 1, character: 0);
    final request = getDocumentHighlights(mainFileUri, pos);

    await expectLater(
        request, throwsA(isResponseError(ServerErrorCodes.InvalidFileLineCol)));
  }

  Future<void> test_localVariable() => _testMarkedContent('''
    main() {
      var [[f^oo]] = 1;
      print([[foo]]);
      [[foo]] = 2;
    }
    ''');

  Future<void> test_nonDartFile() async {
    await initialize();
    await openFile(pubspecFileUri, simplePubspecContent);

    final highlights =
        await getDocumentHighlights(pubspecFileUri, startOfDocPos);

    // Non-Dart files should return empty results, not errors.
    expect(highlights, isEmpty);
  }

  Future<void> test_noResult() => _testMarkedContent('''
    main() {
      // This one is in a ^ comment!
    }
    ''');

  Future<void> test_onlySelf() => _testMarkedContent('''
    main() {
      [[prin^t]]();
    }
    ''');

  Future<void> test_shadow_inner() => _testMarkedContent('''
    main() {
      var foo = 1;
      func() {
        var [[fo^o]] = 2;
        print([[foo]]);
      }
    }
    ''');

  Future<void> test_shadow_outer() => _testMarkedContent('''
    main() {
      var [[foo]] = 1;
      func() {
        var foo = 2;
        print(foo);
      }
      print([[fo^o]]);
    }
    ''');

  Future<void> test_topLevelVariable() => _testMarkedContent('''
    String [[foo]] = 'bar';
    main() {
      print([[foo]]);
      [[fo^o]] = 2;
    }
    ''');

  /// Tests highlights in a Dart file using the provided content.
  /// The content should be marked with a ^ where the highlights request should
  /// be invoked and with `[[double brackets]]` around each range expected to
  /// be highlighted (eg. all references to the symbol under ^).
  /// If the content does not include any `[[double brackets]]` then the response
  /// is expected to be `null`.
  Future<void> _testMarkedContent(String content) async {
    final expectedRanges = rangesFromMarkers(content);

    await initialize();
    await openFile(mainFileUri, withoutMarkers(content));

    final pos = positionFromMarker(content);
    final highlights = await getDocumentHighlights(mainFileUri, pos);

    if (expectedRanges.isEmpty) {
      expect(highlights, isNull);
    } else {
      final highlightRanges = highlights.map((h) => h.range).toList();
      expect(highlightRanges, equals(expectedRanges));
    }
  }
}
