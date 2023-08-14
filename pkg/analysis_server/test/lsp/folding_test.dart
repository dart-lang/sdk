// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FoldingTest);
  });
}

@reflectiveTest
class FoldingTest extends AbstractLspAnalysisServerTest {
  /// A placeholder for folding range kinds that are unset to make it clearer
  /// what's being expected in tests.
  static const FoldingRangeKind? noFoldingKind = null;
  late TestCode code;
  List<FoldingRange> ranges = [];

  bool lineFoldingOnly = false;

  Future<void> computeRanges(String sourceContent,
      {Uri? uri, void Function()? initializePlugin}) async {
    uri ??= mainFileUri;

    code = TestCode.parse(sourceContent);
    final textDocCapabilities = lineFoldingOnly
        ? withLineFoldingOnly(emptyTextDocumentClientCapabilities)
        : emptyTextDocumentClientCapabilities;
    await initialize(textDocumentCapabilities: textDocCapabilities);
    await openFile(uri, code.code);

    initializePlugin?.call();

    ranges = await getFoldingRanges(uri);
  }

  void expectNoRanges() {
    expect(ranges, isEmpty);
  }

  void expectRanges(Map<int, FoldingRangeKind?> expected,
      {bool requireAll = true}) {
    final expectedRanges = expected.entries.map((entry) {
      final range = code.ranges[entry.key].range;
      return FoldingRange(
        startLine: range.start.line,
        startCharacter: lineFoldingOnly ? null : range.start.character,
        endLine: range.end.line,
        endCharacter: lineFoldingOnly ? null : range.end.character,
        // We (and VS Code) don't currently support this.
        collapsedText: null,
        kind: entry.value,
      );
    }).toSet();

    if (requireAll) {
      expect(ranges, expectedRanges);
    } else {
      expect(ranges, containsAll(expectedRanges));
    }
  }

  void expectRangesContain(Map<int, FoldingRangeKind?> expected) =>
      expectRanges(expected, requireAll: false);

  Future<void> test_class() async {
    final content = '''
    class MyClass2/*[0*/ {
      // Class content
    }/*0]*/
    ''';

    await computeRanges(content);
    expectRanges({
      0: noFoldingKind,
    });
  }

  Future<void> test_comments() async {
    final content = '''
    /// This is a comment[/*[0*/
    /// that spans many lines/*0]*/
    class MyClass2 {}
    ''';

    await computeRanges(content);
    expectRanges({
      0: FoldingRangeKind.Comment,
    });
  }

  Future<void> test_doLoop() async {
    final content = '''
    f/*[0*/(int i) {
      do {/*[1*/
        print('with statements');/*1]*/
      } while (i == 0)

      do {/*[2*/
        // only comments/*2]*/
      } while (i == 0)

      // empty
      do {
      } while (i == 0)

      // no body
      do;
    }/*0]*/
    ''';

    await computeRanges(content);
    expectRangesContain({
      0: noFoldingKind,
      1: noFoldingKind,
      2: noFoldingKind,
    });
  }

  Future<void> test_enum() async {
    final content = '''
    enum MyEnum {/*[0*/
      one,
      two,
      three
    /*0]*/}
    ''';

    await computeRanges(content);
    expectRanges({
      0: noFoldingKind,
    });
  }

  Future<void> test_fromPlugins_dartFile() async {
    final pluginAnalyzedFilePath = join(projectFolderPath, 'lib', 'foo.dart');
    final pluginAnalyzedUri = Uri.file(pluginAnalyzedFilePath);

    const content = '''
    // /*[0*/contributed by fake plugin/*0]*/

    class AnnotatedDartClass/*[1*/ {
      // content of dart class, contributed by server
    }/*1]*/
    ''';

    final pluginResult = plugin.AnalysisFoldingParams(
      pluginAnalyzedFilePath,
      [plugin.FoldingRegion(plugin.FoldingKind.DIRECTIVES, 7, 26)],
    );

    await computeRanges(
      content,
      uri: pluginAnalyzedUri,
      initializePlugin: () =>
          configureTestPlugin(notification: pluginResult.toNotification()),
    );
    expectRanges({
      0: FoldingRangeKind.Imports, // From plugin
      1: noFoldingKind, // From server
    });
  }

  Future<void> test_fromPlugins_nonDartFile() async {
    final pluginAnalyzedFilePath = join(projectFolderPath, 'lib', 'foo.sql');
    final pluginAnalyzedUri = Uri.file(pluginAnalyzedFilePath);

    const content = '''
      CREATE TABLE foo(
         /*[0*/-- some columns/*0]*/
      );
    ''';

    final pluginResult = plugin.AnalysisFoldingParams(
      pluginAnalyzedFilePath,
      [plugin.FoldingRegion(plugin.FoldingKind.CLASS_BODY, 33, 15)],
    );

    await computeRanges(
      content,
      uri: pluginAnalyzedUri,
      initializePlugin: () =>
          configureTestPlugin(notification: pluginResult.toNotification()),
    );
    expectRanges({
      0: noFoldingKind, // From plugin
    });
  }

  Future<void> test_headersImportsComments() async {
    final content = '''
    // Copyright some year by some people/*[0*/
    // See LICENCE etc./*0]*/

    import/*[1*/ 'dart:io';
    import 'dart:async';/*1]*/

    /// This is not the file header/*[2*/
    /// It's just a comment/*2]*/
    void f() {}
    ''';

    await computeRanges(content);
    expectRanges({
      0: FoldingRangeKind.Comment,
      1: FoldingRangeKind.Imports,
      2: FoldingRangeKind.Comment,
    });
  }

  Future<void> test_ifElseElseIf() async {
    final content = '''
    f(int i) {
      if (i == 0) {/*[0*/
        // only
        // comments/*0]*/
      } else if (i == 1) {/*[1*/
        print('statements');/*1]*/
      } else if (i == 2) {
      } else {/*[2*/
        // else
        // comments/*2]*/
      }
    }
    ''';

    await computeRanges(content);
    expectRangesContain({
      0: noFoldingKind,
      1: noFoldingKind,
      2: noFoldingKind,
    });
  }

  Future<void> test_nested() async {
    final content = '''
    class MyClass2/*[0*/ {
      void f/*[1*/() {
        void g/*[2*/() {
          //
        }/*2]*/
      }/*1]*/
    }/*0]*/
    ''';

    await computeRanges(content);
    expectRanges({
      0: noFoldingKind,
      1: noFoldingKind,
      2: noFoldingKind,
    });
  }

  Future<void> test_nested_lineFoldingOnly() async {
    lineFoldingOnly = true;
    final content = '''
    class MyClass2 {/*[0*/
      void f() {/*[1*/
        void g() {/*[2*/
          //
        /*2]*/}
      /*1]*/}
    /*0]*/}
    ''';

    await computeRanges(content);
    expectRanges({
      0: noFoldingKind,
      1: noFoldingKind,
      2: noFoldingKind,
    });
  }

  Future<void> test_nonDartFile() async {
    await computeRanges(simplePubspecContent, uri: pubspecFileUri);
    expectNoRanges();
  }

  /// When the client supports columns (not "lineFoldingOnly"), we can end
  /// one range on the same line as the next one starts.
  Future<void> test_overlapLines_columnsSupported() async {
    final content = '''
void f/*[0*/() {
  //
}/*0]*/ void g/*[1*/() {
  //
}/*1]*/
    ''';

    await computeRanges(content);
    expectRanges({
      0: noFoldingKind,
      1: noFoldingKind,
    });
  }

  /// When the client supports lineFoldingOnly, we cannot end a range on the
  /// same line that the next one starts. Instead, it should be shortened to end
  /// on the previous line.
  Future<void> test_overlapLines_lineFoldingOnly() async {
    lineFoldingOnly = true;
    final content = '''
void f/*[0*/() {
  ///*0]*/
} void g/*[1*/() {
  //
}/*1]*/
    ''';

    await computeRanges(content);
    expectRanges({
      0: noFoldingKind,
      1: noFoldingKind,
    });
  }

  Future<void> test_recordLiteral() async {
    final content = '''
    void f() {
      var r = (/*[0*/
        2,
        'string',
      /*0]*/);
    }
    ''';

    await computeRanges(content);
    expectRangesContain({
      0: noFoldingKind,
    });
  }

  Future<void> test_switchExpression() async {
    final content = '''
void f(int a) {
  var b = switch (a) {/*[0*/
    1 => '',
    2 =>/*[1*/ '1234567890'
        '1234567890'/*1]*/,
    _ =>/*[2*/ '1234567890'
        '1234567890'
        '1234567890'
        '1234567890'/*2]*/
  }/*0]*/;
}
    ''';

    await computeRanges(content);
    expectRanges(
      {
        0: noFoldingKind,
        1: noFoldingKind,
        2: noFoldingKind,
      },
      requireAll: false,
    );
  }

  Future<void> test_switchPattern() async {
    final content = '''
void f(int a) {
  switch (a) {/*[0*/
    case 0:/*[1*/
      print('');/*1]*/
    case 1:
    case 2:/*[2*/
      print('');/*2]*/
    default:/*[3*/
      print('');/*3]*/
  }/*0]*/
}
    ''';

    await computeRanges(content);
    expectRanges(
      {
        0: noFoldingKind,
        1: noFoldingKind,
        2: noFoldingKind,
        3: noFoldingKind,
      },
      requireAll: false,
    );
  }

  Future<void> test_switchStatement() async {
    final content = '''
// @dart = 2.19

void f(int a) {
  switch (a) {/*[0*/
    case 0:/*[1*/
      print('');
      break;/*1]*/
    case 1:
    case 2:/*[2*/
      print('');/*2]*/
    default:/*[3*/
      print('');/*3]*/
  }/*0]*/
}
    ''';

    await computeRanges(content);
    expectRanges(
      {
        0: noFoldingKind,
        1: noFoldingKind,
        2: noFoldingKind,
        3: noFoldingKind,
      },
      requireAll: false,
    );
  }

  Future<void> test_whileLoop() async {
    final content = '''
    f(int i) {
      while (i == 0) {/*[0*/
        print('with statements');/*0]*/
      }

      while (i == 0) {/*[1*/
        // only comments/*1]*/
      }

      // empty
      while (i == 0) {
      }

      // no body
      while (i == 0);
    }
    ''';

    await computeRanges(content);
    expectRangesContain({
      0: noFoldingKind,
      1: noFoldingKind,
    });
  }
}
