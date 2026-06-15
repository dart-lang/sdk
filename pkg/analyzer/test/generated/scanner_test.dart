// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/error_token.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LineInfoTest);
    defineReflectiveTests(ScannerTest);
  });
}

@reflectiveTest
class LineInfoTest {
  final featureSet = FeatureSet.latestLanguageVersion();

  void test_lineInfo_multilineComment() {
    String source = "/*\r\n *\r\n */";
    _assertLineInfo(source, [
      ScannerTest_ExpectedLocation(0, 1, 1),
      ScannerTest_ExpectedLocation(5, 2, 2),
      ScannerTest_ExpectedLocation(source.length - 1, 3, 3),
    ]);
  }

  void test_lineInfo_multilineString() {
    String source = "'''a\r\nbc\r\nd'''";
    _assertLineInfo(source, [
      ScannerTest_ExpectedLocation(0, 1, 1),
      ScannerTest_ExpectedLocation(7, 2, 2),
      ScannerTest_ExpectedLocation(source.length - 1, 3, 4),
    ]);
  }

  void test_lineInfo_multilineString_raw() {
    String source = "var a = r'''\nblah\n''';\n\nfoo";
    _assertLineInfo(source, [
      ScannerTest_ExpectedLocation(0, 1, 1),
      ScannerTest_ExpectedLocation(14, 2, 2),
      ScannerTest_ExpectedLocation(source.length - 2, 5, 2),
    ]);
  }

  void test_lineInfo_simpleClass() {
    String source =
        "class Test {\r\n    String s = '...';\r\n    int get x => s.MISSING_GETTER;\r\n}";
    _assertLineInfo(source, [
      ScannerTest_ExpectedLocation(0, 1, 1),
      ScannerTest_ExpectedLocation(source.indexOf("MISSING_GETTER"), 3, 20),
      ScannerTest_ExpectedLocation(source.length - 1, 4, 1),
    ]);
  }

  void test_lineInfo_slashN() {
    String source = "class Test {\n}";
    _assertLineInfo(source, [
      ScannerTest_ExpectedLocation(0, 1, 1),
      ScannerTest_ExpectedLocation(source.indexOf("}"), 2, 1),
    ]);
  }

  void test_lineStarts() {
    String source = "var\r\ni\n=\n1;\n";
    var scanner = _newScanner(source);
    var token = scanner.tokenize();
    expect(token.lexeme, 'var');
    var lineStarts = scanner.lineStarts;
    expect(lineStarts, orderedEquals([0, 5, 7, 9, 12]));
  }

  void test_translate_missing_closing_gt_error() {
    // Ensure that the UnmatchedToken error for missing '>' is translated
    // to the correct analyzer error code.
    // See https://github.com/dart-lang/sdk/issues/30320
    String source = '<!-- @Component(';
    var scanner = _newScanner(source);
    Token token = scanner.tokenize();
    expect(token, TypeMatcher<UnmatchedToken>());
    token = token.next!;
    expect(token, TypeMatcher<UnmatchedToken>());
    token = token.next!;
    expect(token, isNot(TypeMatcher<ErrorToken>()));
  }

  void _assertLineInfo(
    String source,
    List<ScannerTest_ExpectedLocation> expectedLocations,
  ) {
    var info = _scanLineInfo(source);
    int count = expectedLocations.length;
    for (int i = 0; i < count; i++) {
      ScannerTest_ExpectedLocation expectedLocation = expectedLocations[i];
      var location = info.getLocation(expectedLocation._offset);
      expect(
        location.lineNumber,
        expectedLocation._lineNumber,
        reason: 'Line number in location $i',
      );
      expect(
        location.columnNumber,
        expectedLocation._columnNumber,
        reason: 'Column number in location $i',
      );
    }
  }

  Scanner _newScanner(String source) {
    return Scanner(
      inputText: source,
      reportError: (diagnostic) {
        fail('Unexpected diagnostic: $diagnostic');
      },
    )..configureFeatures(
      featureSetForOverriding: featureSet,
      featureSet: featureSet,
    );
  }

  LineInfo _scanLineInfo(String source) {
    var scanner = _newScanner(source);
    scanner.tokenize();
    return LineInfo(scanner.lineStarts);
  }
}

@reflectiveTest
class ScannerTest {
  test_featureSet() {
    var scanner = Scanner(
      inputText: r'''
// @dart = 2.0
''',
      reportError: (_) {},
    );
    var defaultFeatureSet = FeatureSet.latestLanguageVersion();
    expect(defaultFeatureSet.isEnabled(Feature.extension_methods), isTrue);

    scanner.configureFeatures(
      featureSetForOverriding: FeatureSet.latestLanguageVersion(),
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    scanner.tokenize();

    var featureSet = scanner.featureSet;
    expect(featureSet.isEnabled(Feature.extension_methods), isFalse);
  }

  test_featureSet_majorOverflow() {
    var scanner = Scanner(
      inputText: r'''
// @dart = 99999999999999999999999999999999.0
''',
      reportError: (_) {},
    );
    var featureSet = FeatureSet.latestLanguageVersion();
    scanner.configureFeatures(
      featureSetForOverriding: featureSet,
      featureSet: featureSet,
    );
    scanner.tokenize();
    // Don't check features, but should not crash.
  }

  test_featureSet_minorOverflow() {
    var scanner = Scanner(
      inputText: r'''
// @dart = 3.99999999999999999999999999999999
''',
      reportError: (_) {},
    );
    var featureSet = FeatureSet.latestLanguageVersion();
    scanner.configureFeatures(
      featureSetForOverriding: featureSet,
      featureSet: featureSet,
    );
    scanner.tokenize();
    // Don't check features, but should not crash.
  }
}

/// An `ExpectedLocation` encodes information about the expected location of a
/// given offset in source code.
class ScannerTest_ExpectedLocation {
  final int _offset;

  final int _lineNumber;

  final int _columnNumber;

  ScannerTest_ExpectedLocation(
    this._offset,
    this._lineNumber,
    this._columnNumber,
  );
}
