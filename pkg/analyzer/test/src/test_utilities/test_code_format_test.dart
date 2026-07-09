// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TestCodeFormatTest);
  });
}

@reflectiveTest
class TestCodeFormatTest {
  void test_noMarkers() {
    var markedCode = '''
int a = 1;
''';
    var code = TestCode.parse(markedCode);
    expect(code.markedCode, markedCode);
    expect(code.code, markedCode); // no difference
    expect(code.positions, isEmpty);
    expect(code.ranges, isEmpty);
  }

  void test_positions() {
    var markedCode = '''
int /*0*/a = 1;/*1*/
int b/*2*/ = 2;
''';
    var expectedCode = '''
int a = 1;
int b = 2;
''';
    var code = TestCode.parse(markedCode);
    expect(code.markedCode, markedCode);
    expect(code.code, expectedCode);
    expect(code.ranges, isEmpty);

    expect(code.positions[0].offset, 4);
    expect(code.positions[1].offset, 10);
    expect(code.positions[2].offset, 16);
  }

  void test_positions_nonShorthandCaret() {
    var markedCode = '''
String /*0*/a = '^^^';
    ''';
    var expectedCode = '''
String a = '^^^';
    ''';
    var code = TestCode.parse(markedCode, positionShorthand: false);
    expect(code.markedCode, markedCode);
    expect(code.code, expectedCode);

    expect(code.positions, hasLength(1));
    expect(code.position.offset, 7);
    expect(code.position.offset, code.positions[0].offset);

    expect(code.ranges, isEmpty);
  }

  void test_positions_numberReused() {
    var markedCode = '''
/*0*/ /*1*/ /*0*/
''';
    expect(() => TestCode.parse(markedCode), throwsArgumentError);
  }

  void test_positions_shorthand() {
    var markedCode = '''
int ^a = 1
    ''';
    var expectedCode = '''
int a = 1
    ''';
    var code = TestCode.parse(markedCode);
    expect(code.markedCode, markedCode);
    expect(code.code, expectedCode);

    expect(code.positions, hasLength(1));
    expect(code.position.offset, 4);
    expect(code.position.offset, code.positions[0].offset);

    expect(code.ranges, isEmpty);
  }

  void test_positions_shorthandReused() {
    var markedCode = '''
^ ^
''';
    expect(() => TestCode.parse(markedCode), throwsArgumentError);
  }

  void test_positions_shorthandReusedNumber() {
    var markedCode = '''
/*0*/ ^
''';
    expect(() => TestCode.parse(markedCode), throwsArgumentError);
  }

  void test_ranges() {
    var markedCode = '''
int /*[0*/a = 1;/*0]*/
/*[1*/int b = 2;/*1]*/
''';
    var expectedCode = '''
int a = 1;
int b = 2;
''';
    var code = TestCode.parse(markedCode);
    expect(code.markedCode, markedCode);
    expect(code.code, expectedCode);
    expect(code.positions, isEmpty);

    expect(code.ranges, hasLength(2));
    expect(code.ranges[0].sourceRange, SourceRange(4, 6));
    expect(code.ranges[1].sourceRange, SourceRange(11, 10));

    expect(code.ranges[0].text, 'a = 1;');
    expect(code.ranges[1].text, 'int b = 2;');
  }

  void test_ranges_endReused() {
    var markedCode = '''
/*[0*/ /*0]*/
/*[1*/ /*0]*/
''';
    expect(() => TestCode.parse(markedCode), throwsArgumentError);
  }

  void test_ranges_endWithoutStart() {
    var markedCode = '''
/*0]*/
''';
    expect(() => TestCode.parse(markedCode), throwsArgumentError);
  }

  void test_ranges_nonShorthandMarkers() {
    var markedCode = '''
String a = '[!not markers!]';
    ''';
    var code = TestCode.parse(markedCode, rangeShorthand: false);
    expect(code.markedCode, markedCode);
    expect(code.code, markedCode); // No change.

    expect(code.positions, isEmpty);
    expect(code.ranges, isEmpty);
  }

  void test_ranges_shorthand() {
    var markedCode = '''
int [!a = 1;!]
int b = 2;
''';
    var expectedCode = '''
int a = 1;
int b = 2;
''';
    var code = TestCode.parse(markedCode);
    expect(code.markedCode, markedCode);
    expect(code.code, expectedCode);
    expect(code.positions, isEmpty);

    expect(code.ranges, hasLength(1));
    expect(code.ranges[0].sourceRange, SourceRange(4, 6));

    expect(code.ranges[0].text, 'a = 1;');
  }

  void test_ranges_shorthandReused() {
    var markedCode = '''
int [!a = 1;!]
int [!b = 2!];
''';
    expect(() => TestCode.parse(markedCode), throwsArgumentError);
  }

  void test_ranges_shorthandReusedNumber() {
    var markedCode = '''
int [!a = 1;!]
int /*[0*/b = 2/*0]*/;
''';
    expect(() => TestCode.parse(markedCode), throwsArgumentError);
  }

  void test_ranges_startReused() {
    var markedCode = '''
/*[0*/ /*0]*/
/*[0*/ /*1]*/
''';
    expect(() => TestCode.parse(markedCode), throwsArgumentError);
  }

  void test_ranges_startWithoutEnd() {
    var markedCode = '''
/*[0*/
''';
    expect(() => TestCode.parse(markedCode), throwsArgumentError);
  }
}
