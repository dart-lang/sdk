// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentHighlightsTest);
  });
}

@reflectiveTest
class DocumentHighlightsTest extends AbstractLspAnalysisServerTest {
  Future<void> test_forInLoop() => _testMarkedContent('''
void f() {
  for (final /*[0*/x^/*0]*/ in []) {
    /*[1*/x/*1]*/;
  }
}
''');

  Future<void> test_functions() => _testMarkedContent('''
/*[0*/main/*0]*/() {
  /*[1*/mai^n/*1]*/();
}
''');

  Future<void> test_invalidLineByOne() async {
    // Test that requesting a line that's too high by one returns a valid
    // error response instead of throwing.
    const content = '// single line';

    await initialize();
    await openFile(mainFileUri, content);

    // Lines are zero-based so 1 is invalid.
    final pos = Position(line: 1, character: 0);
    final request = getDocumentHighlights(mainFileUri, pos);

    await expectLater(
        request, throwsA(isResponseError(ServerErrorCodes.InvalidFileLineCol)));
  }

  Future<void> test_localVariable() => _testMarkedContent('''
void f() {
  var /*[0*/f^oo/*0]*/ = 1;
  print(/*[1*/foo/*1]*/);
  /*[2*/foo/*2]*/ = 2;
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
void f() {
  // This one is in a ^ comment!
}
''');

  Future<void> test_onlySelf() => _testMarkedContent('''
void f() {
  /*[0*/prin^t/*0]*/();
}
''');

  Future<void> test_shadow_inner() => _testMarkedContent('''
void f() {
  var foo = 1;
  func() {
    var /*[0*/fo^o/*0]*/ = 2;
    print(/*[1*/foo/*1]*/);
  }
}
''');

  Future<void> test_shadow_outer() => _testMarkedContent('''
void f() {
  var /*[0*/foo/*0]*/ = 1;
  func() {
    var foo = 2;
    print(foo);
  }
  print(/*[1*/fo^o/*1]*/);
}
''');

  Future<void> test_topLevelVariable() => _testMarkedContent('''
String /*[0*/foo/*0]*/ = 'bar';
void f() {
  print(/*[1*/foo/*1]*/);
  /*[2*/fo^o/*2]*/ = 2;
}
''');

  /// Tests highlights in a Dart file using the provided content.
  ///
  /// The content should be marked up using the [TestCode] format.
  ///
  /// If the content does not include any ranges then the response is expected
  /// to be `null`.
  Future<void> _testMarkedContent(String content) async {
    final code = TestCode.parse(content);

    await initialize();
    await openFile(mainFileUri, code.code);

    final pos = code.position.position;
    final highlights = await getDocumentHighlights(mainFileUri, pos);

    if (code.ranges.isEmpty) {
      expect(highlights, isNull);
    } else {
      final highlightRanges = highlights!.map((h) => h.range).toList();
      expect(highlightRanges, equals(code.ranges.map((r) => r.range)));
    }
  }
}
