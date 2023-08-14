// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_color.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ColorComputerTest);
  });
}

@reflectiveTest
class ColorComputerTest extends AbstractContextTest {
  /// A map of Dart source code that represents different types/formats
  /// that are valid in const contexts.
  ///
  /// Values are the color that should be discovered (in 0xAARRGGBB format).
  ///
  /// Color values may not match the actual Flutter framework but are
  /// values that are more identifiable for ease of testing. They are
  /// defined in:
  ///  - test/mock_packages/flutter/lib/src/material/colors.dart.
  ///  - test/mock_packages/flutter/lib/src/cupertino/colors.dart.
  ///
  /// These values will be iterated in tests and inserted into various
  /// code snippets for testing.
  static const colorCodesConst = {
    // dart:ui Colors
    'Colors.white': 0xFFFFFFFF,
    'Color(0xFF0000FF)': 0xFF0000FF,
    'Color.fromARGB(255, 0, 0, 255)': 0xFF0000FF,
    'Color.fromRGBO(0, 0, 255, 1)': 0xFF0000FF,
    'Color.fromRGBO(0, 0, 255, 1.0)': 0xFF0000FF,
    // Flutter Painting
    'ColorSwatch(0xFF89ABCD, {})': 0xFF89ABCD,
    // Flutter Material
    'Colors.red': 0xFFFF0000,
    'Colors.redAccent': 0xFFFFAA00,
    'MaterialAccentColor(0xFF89ABCD, {})': 0xFF89ABCD,
    // Flutter Cupertino
    'CupertinoColors.black': 0xFF000000,
    'CupertinoColors.systemBlue': 0xFF0000FF,
    'CupertinoColors.activeBlue': 0xFF0000FF,
  };

  /// A map of Dart source code that represents different types/formats
  /// that are not valid in const contexts.
  ///
  /// Values are the color that should be discovered (in 0xAARRGGBB format).
  static const colorCodesNonConst = {
    // Flutter Material
    'Colors.red.shade100': 0x10FF0000,
    'Colors.red[100]': 0x10FF0000,
    // Flutter Cupertino
    'CupertinoColors.systemBlue.color': 0xFF0000FF,
    'CupertinoColors.systemBlue.darkColor': 0xFF000099,
    'CupertinoColors.activeBlue.color': 0xFF0000FF,
    'CupertinoColors.activeBlue.darkColor': 0xFF000099,
    'CupertinoColors.activeBlue.highContrastColor': 0xFF000066,
    'CupertinoColors.activeBlue.darkHighContrastColor': 0xFF000033,
    'CupertinoColors.activeBlue.elevatedColor': 0xFF0000FF,
    'CupertinoColors.activeBlue.darkElevatedColor': 0xFF000099,
  };

  /// A map of Dart source code that creates multiple nested color references.
  ///
  /// The key is the source code, and the value is a map of the expressions and
  /// colors that should be produced (where the null key represents the
  /// entire expression).
  static const colorCodesNested = {
    // TODO(dantup): Remove this "const" when we can evaluate constructors
    // in non-const contexts.
    'const CupertinoDynamicColor.withBrightness(color: CupertinoColors.white, darkColor: CupertinoColors.black)':
        {
      null: 0xFFFFFFFF,
      'CupertinoColors.white': 0xFFFFFFFF,
      'CupertinoColors.black': 0xFF000000,
    },
  };

  late String testPath;
  late String otherPath;

  late ColorComputer computer;

  /// Tests that all of the known color codes replaced into [code] produce the
  /// expected nested color values.
  ///
  /// If [onlyConst] is `true`, only the test values that are const will be
  /// tested.
  Future<void> checkAllColors(String code, {bool onlyConst = false}) async {
    // Combine the flat and nested colours into the same format.
    final allColorCodes = <String, Map<String?, int>>{
      ...colorCodesConst.map((key, value) => MapEntry(key, {key: value})),
      if (!onlyConst)
        ...colorCodesNonConst.map((key, value) => MapEntry(key, {key: value})),
      ...colorCodesNested,
    };

    for (final entry in allColorCodes.entries) {
      final colorDartCode = entry.key;
      final expectedColorValues = entry.value.map(
        // A null key means we should expect the full code.
        (key, value) => MapEntry(key ?? colorDartCode, value),
      );

      await expectColors(
        code.replaceAll('[[COLOR]]', colorDartCode),
        expectedColorValues,
      );
    }
  }

  /// Checks that all of [expectedColorValues] are produced for [dartCode].
  Future<void> expectColors(
    String dartCode,
    Map<String, int> expectedColorValues, {
    String? otherCode,
  }) async {
    dartCode = _withCommonImports(dartCode);
    otherCode = otherCode != null ? _withCommonImports(otherCode) : null;

    newFile(testPath, dartCode);
    if (otherCode != null) {
      final otherFile = newFile(otherPath, otherCode);
      final otherResult = await getResolvedUnit(otherFile);
      expectNoErrors(otherResult);
    }

    final result = await getResolvedUnit(testFile);
    expectNoErrors(result);

    computer = ColorComputer(result);
    final colors = computer.compute();

    expect(
      colors,
      hasLength(expectedColorValues.length),
      reason: '${expectedColorValues.length} colors should be detected in:\n'
          '$dartCode',
    );

    for (final (i, expectedColor) in expectedColorValues.entries.indexed) {
      final color = colors[i];
      final expectedColorCode = expectedColor.key;
      final expectedColorValue = expectedColor.value;
      final expectedAlpha = (0xff000000 & expectedColorValue) >> 24;
      final expectedRed = (0x00ff0000 & expectedColorValue) >> 16;
      final expectedGreen = (0x0000ff00 & expectedColorValue) >> 8;
      final expectedBlue = (0x000000ff & expectedColorValue) >> 0;

      final regionText =
          dartCode.substring(color.offset, color.offset + color.length);
      expect(
        regionText,
        equals(expectedColorCode),
        reason: 'Color $i expected $expectedColorCode but was $regionText',
      );

      void expectComponent(int actual, int expected, String name) => expect(
            actual,
            expected,
            reason: '$name value for $expectedColorCode is not correct',
          );

      expectComponent(color.color.alpha, expectedAlpha, 'Alpha');
      expectComponent(color.color.red, expectedRed, 'Red');
      expectComponent(color.color.green, expectedGreen, 'Green');
      expectComponent(color.color.blue, expectedBlue, 'Blue');
    }
  }

  void expectNoErrors(ResolvedUnitResult result) {
    // If the test code has errors, generate a suitable failure to help debug.
    final errors = result.errors
        .where((error) => error.severity == Severity.error)
        .toList();
    if (errors.isNotEmpty) {
      throw 'Code has errors: $errors\n\n${result.content}';
    }
  }

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
    testPath = convertPath('$testPackageLibPath/test.dart');
    otherPath = convertPath('$testPackageLibPath/other_file.dart');
  }

  Future<void> test_collectionLiteral_const() async {
    const testCode = '''
void f() {
  const colors = [
    [[COLOR]],
  ];
}
''';
    await checkAllColors(testCode, onlyConst: true);
  }

  Future<void> test_collectionLiteral_nonConst() async {
    const testCode = '''
void f() {
  final colors = [
    [[COLOR]],
  ];
}
''';
    await checkAllColors(testCode);
  }

  Future<void> test_customClass() async {
    const testCode = '''
import 'other_file.dart';

void f() {
  final a1 = MyTheme.staticWhite;
  final a2 = MyTheme.staticMaterialRedAccent;
  const theme = MyTheme();
  final b1 = theme.instanceWhite;
  final b2 = theme.instanceMaterialRedAccent;
}
''';

    const otherCode = '''
class MyTheme {
  static const Color staticWhite = Colors.white;
  static const MaterialAccentColor staticMaterialRedAccent = Colors.redAccent;

  final Color instanceWhite;
  final MaterialAccentColor instanceMaterialRedAccent;

  const MyTheme()
      : instanceWhite = Colors.white,
        instanceMaterialRedAccent = Colors.redAccent;
}
''';
    await expectColors(
      testCode,
      {
        'MyTheme.staticWhite': 0xFFFFFFFF,
        'MyTheme.staticMaterialRedAccent': 0xFFFFAA00,
        'theme.instanceWhite': 0xFFFFFFFF,
        'theme.instanceMaterialRedAccent': 0xFFFFAA00,
      },
      otherCode: otherCode,
    );
  }

  Future<void> test_local_const() async {
    const testCode = '''
void f() {
  const a = [[COLOR]];
}
''';
    await checkAllColors(testCode, onlyConst: true);
  }

  Future<void> test_local_nonConst() async {
    const testCode = '''
void f() {
  final a = [[COLOR]];
}
''';
    await checkAllColors(testCode);
  }

  Future<void> test_namedParameter_const() async {
    const testCode = '''
void f() {
  const w = Widget(color: [[COLOR]]);
}

class Widget {
  final Color? color;
  const Widget({this.color});
}
''';
    await checkAllColors(testCode, onlyConst: true);
  }

  Future<void> test_namedParameter_nonConst() async {
    const testCode = '''
void f() {
  final w = Widget(color: [[COLOR]]);
}

class Widget {
  final Color? color;
  Widget({this.color});
}
''';
    await checkAllColors(testCode);
  }

  Future<void> test_nested_const() async {
    const testCode = '''
void f() {
  const a = [[COLOR]];
}
''';
    await checkAllColors(testCode, onlyConst: true);
  }

  Future<void> test_nested_nonConst() async {
    const testCode = '''
void f() {
  final a = [[COLOR]];
}
''';
    await checkAllColors(testCode);
  }

  Future<void> test_topLevel_const() async {
    const testCode = '''
const a = [[COLOR]];
''';
    await checkAllColors(testCode, onlyConst: true);
  }

  Future<void> test_topLevel_nonConst() async {
    const testCode = '''
final a = [[COLOR]];
''';
    await checkAllColors(testCode);
  }

  String _withCommonImports(String code) => '''
import 'package:flutter/cupertino.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/material.dart';

$code''';
}
