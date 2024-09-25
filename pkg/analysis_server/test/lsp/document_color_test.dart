// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentColorTest);
    defineReflectiveTests(DocumentColorPresentationTest);
  });
}

@reflectiveTest
class DocumentColorPresentationTest extends AbstractLspAnalysisServerTest {
  late TestCode code;
  late String testFilePath;
  final uiImportUri = 'package:ui/ui.dart';
  Range get colorRange => code.range.range;
  set content(String content) => code = TestCode.parse(content);
  Uri get testFileUri => pathContext.toUri(testFilePath);

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);

    content = '';
    testFilePath = mainFilePath;
  }

  /// Changing a const color to a const constructor call must add 'const'
  /// in a switch expression because non-const values are not allowed and
  /// const is not implied like in a const context.
  Future<void> test_colorConstant_addsConst_switchExpression() async {
    content = '''
import 'package:flutter/material.dart';

void f(Color color) {
  const x = Colors.red;
  var a = switch (color) {
    [!x!] => 'red',
    const Color.fromARGB(255, 100, 0, 0) => 'dark-red',
    _ => 'unknown',
  };
}
''';

    await _checkPresentations(
      select: Color(alpha: 1, red: 1, green: 0, blue: 0),
      expectPresentations: [
        _color('Color.fromARGB(255, 255, 0, 0)', withConst: true),
        _color('Color.fromRGBO(255, 0, 0, 1)', withConst: true),
        _color('Color.from(alpha: 1, red: 1, green: 0, blue: 0)',
            withConst: true),
        _color('Color(0xFFFF0000)', withConst: true),
      ],
    );
  }

  Future<void> test_colorConstant_constContext() async {
    content = '''
import 'package:flutter/material.dart';

const x = Colors.white;
const white = [!x!];
''';

    await _checkPresentations(
      select: Color(alpha: 1, red: 1, green: 0, blue: 0),
      expectPresentations: [
        _color('Color.fromARGB(255, 255, 0, 0)'),
        _color('Color.fromRGBO(255, 0, 0, 1)'),
        _color('Color.from(alpha: 1, red: 1, green: 0, blue: 0)'),
        _color('Color(0xFFFF0000)'),
      ],
    );
  }

  Future<void> test_colorConstant_nonConst() async {
    content = '''
import 'package:flutter/material.dart';

const x = Colors.white;
var white = [!x!];
''';

    await _checkPresentations(
      select: Color(alpha: 1, red: 1, green: 0, blue: 0),
      expectPresentations: [
        _color('Color.fromARGB(255, 255, 0, 0)', withConst: true),
        _color('Color.fromRGBO(255, 0, 0, 1)', withConst: true),
        _color('Color.from(alpha: 1, red: 1, green: 0, blue: 0)',
            withConst: true),
        _color('Color(0xFFFF0000)', withConst: true),
      ],
    );
  }

  /// Changing a const color to a const constructor call must add 'const'
  /// in a switch expression because non-const values are not allowed and
  /// const is not implied like in a const context.
  Future<void> test_colorConstant_prefixed_addsConst_switchExpression() async {
    content = '''
import 'package:flutter/material.dart';

void f(Color color) {
  var a = switch (color) {
    [!Colors.red!] => 'red',
    const Color.fromARGB(255, 100, 0, 0) => 'dark-red',
    _ => 'unknown',
  };
}
''';

    await _checkPresentations(
      select: Color(alpha: 1, red: 1, green: 0, blue: 0),
      expectPresentations: [
        _color('Color.fromARGB(255, 255, 0, 0)', withConst: true),
        _color('Color.fromRGBO(255, 0, 0, 1)', withConst: true),
        _color('Color.from(alpha: 1, red: 1, green: 0, blue: 0)',
            withConst: true),
        _color('Color(0xFFFF0000)', withConst: true),
      ],
    );
  }

  Future<void> test_colorConstant_prefixed_constContext() async {
    content = '''
import 'package:flutter/material.dart';

const white = [!Colors.white!];
''';

    await _checkPresentations(
      select: Color(alpha: 1, red: 1, green: 0, blue: 0),
      expectPresentations: [
        _color('Color.fromARGB(255, 255, 0, 0)'),
        _color('Color.fromRGBO(255, 0, 0, 1)'),
        _color('Color.from(alpha: 1, red: 1, green: 0, blue: 0)'),
        _color('Color(0xFFFF0000)'),
      ],
    );
  }

  Future<void> test_colorConstant_prefixed_nonConst() async {
    content = '''
import 'package:flutter/material.dart';

var white = [!Colors.white!];
''';

    await _checkPresentations(
      select: Color(alpha: 1, red: 1, green: 0, blue: 0),
      expectPresentations: [
        _color('Color.fromARGB(255, 255, 0, 0)', withConst: true),
        _color('Color.fromRGBO(255, 0, 0, 1)', withConst: true),
        _color('Color.from(alpha: 1, red: 1, green: 0, blue: 0)',
            withConst: true),
        _color('Color(0xFFFF0000)', withConst: true),
      ],
    );
  }

  /// If a color is in a const context, we should not insert 'const'.
  Future<void> test_colorConstructor_constContext() async {
    content = '''
import 'package:flutter/material.dart';

const white = [!Color(0xFFFFFFFF)!];
''';

    await _checkPresentations(
      select: Color(alpha: 1, red: 1, green: 0, blue: 0),
      expectPresentations: [
        _color('Color.fromARGB(255, 255, 0, 0)'),
        _color('Color.fromRGBO(255, 0, 0, 1)'),
        _color('Color.from(alpha: 1, red: 1, green: 0, blue: 0)'),
        _color('Color(0xFFFF0000)'),
      ],
    );
  }

  /// If a color is in a const context, we should not insert 'const'.
  Future<void> test_colorConstructor_constContext_withSeparators() async {
    content = '''
import 'package:flutter/material.dart';

const white = [!Color(0xFF_FF_FF_FF)!];
''';

    await _checkPresentations(
      select: Color(alpha: 1, red: 1, green: 0, blue: 0),
      expectPresentations: [
        _color('Color.fromARGB(255, 255, 0, 0)'),
        _color('Color.fromRGBO(255, 0, 0, 1)'),
        _color('Color.from(alpha: 1, red: 1, green: 0, blue: 0)'),
        _color('Color(0xFFFF0000)'),
      ],
    );
  }

  /// If a color already has 'const' ahead of it, we should include it in the
  /// replacement also.
  Future<void> test_colorConstructor_constKeyword() async {
    content = '''
import 'package:flutter/material.dart';

var white = [!const Color(0xFFFFFFFF)!];
''';

    await _checkPresentations(
      select: Color(alpha: 1, red: 1, green: 0, blue: 0),
      expectPresentations: [
        _color('Color.fromARGB(255, 255, 0, 0)', withConst: true),
        _color('Color.fromRGBO(255, 0, 0, 1)', withConst: true),
        _color('Color.from(alpha: 1, red: 1, green: 0, blue: 0)',
            withConst: true),
        _color('Color(0xFFFF0000)', withConst: true),
      ],
    );
  }

  Future<void> test_colorConstructor_nonConst() async {
    content = '''
import 'package:flutter/material.dart';

var white = [!Color(0xFFFFFFFF)!];
''';

    await _checkPresentations(
      select: Color(alpha: 1, red: 1, green: 0, blue: 0),
      expectPresentations: [
        _color('Color.fromARGB(255, 255, 0, 0)'),
        _color('Color.fromRGBO(255, 0, 0, 1)'),
        _color('Color.from(alpha: 1, red: 1, green: 0, blue: 0)'),
        _color('Color(0xFFFF0000)'),
      ],
    );
  }

  Future<void> test_colorConstructor_nonConst_withSeparators() async {
    content = '''
import 'package:flutter/material.dart';

var white = [!Color(0xFF_FF_FF_FF)!];
''';

    await _checkPresentations(
      select: Color(alpha: 1, red: 1, green: 0, blue: 0),
      expectPresentations: [
        _color('Color.fromARGB(255, 255, 0, 0)'),
        _color('Color.fromRGBO(255, 0, 0, 1)'),
        _color('Color.from(alpha: 1, red: 1, green: 0, blue: 0)'),
        _color('Color(0xFFFF0000)'),
      ],
    );
  }

  // Converting from ints to doubles should be rounded to 3 decimals to avoid
  // very large numbers (2 is not enough to represent 0-255 as it only allows
  // 100 numbers).
  Future<void> test_doubleRounding() async {
    content = '''
import 'package:flutter/material.dart';

var white = [!Color.fromRGBO(191, 128, 64, 1)!];
''';

    await _checkPresentations(
      select: Color(
        alpha: 1,
        red: 0.7490196078431373,
        green: 0.5019607843137255,
        blue: 0.25098039215686274,
      ),
      expectPresentations: [
        _color('Color.fromARGB(255, 191, 128, 64)'),
        _color('Color.fromRGBO(191, 128, 64, 1)'),
        _color('Color.from(alpha: 1, red: 0.749, green: 0.502, blue: 0.251)'),
        _color('Color(0xFFBF8040)'),
      ],
    );
  }

  Future<void> test_includesImportEdit() async {
    failTestOnErrorDiagnostic = false; // Tests with missing import.

    // We need to import `Colors` for a color range to be produced that would
    // allow a picker, but we want to ensure the generated code needs to add
    // an additional import to reference the `Color` class.
    content = '''
import 'package:flutter/material.dart' show Colors;^

const white = [!Colors.white!];
''';

    // Compute the expected additional edit to insert the import.
    var edits = [
      TextEdit(
        range: Range(
          start: code.position.position,
          end: code.position.position,
        ),
        newText: "\nimport '$uiImportUri';",
      )
    ];

    await _checkPresentations(
      select: Color(alpha: 1, red: 1, green: 1, blue: 1),
      expectPresentations: [
        _color('Color.fromARGB(255, 255, 255, 255)', additionalEdits: edits),
        _color('Color.fromRGBO(255, 255, 255, 1)', additionalEdits: edits),
        _color('Color.from(alpha: 1, red: 1, green: 1, blue: 1)',
            additionalEdits: edits),
        _color('Color(0xFFFFFFFF)', additionalEdits: edits),
      ],
    );
  }

  Future<void> test_nonDartFile() async {
    newFile(pubspecFilePath, simplePubspecContent);
    await initialize();

    var colors = await getColorPresentation(
      pubspecFileUri,
      startOfDocRange,
      Color(alpha: 1, red: 1, green: 1, blue: 1),
    );
    expect(colors, isEmpty);
  }

  Future<void> test_outsideAnalysisRoot() async {
    testFilePath = convertPath('/home/other/test.dart');
    content = '''
import 'package:flutter/material.dart';

const white = [!Color(0xFFFFFFFF)!];
''';

    await _checkPresentations(
      select: Color(alpha: 1, red: 1, green: 0, blue: 0),

      /// Because this file is not editable (it's outside the analysis roots) an
      /// empty result will be returned.
      expectPresentations: [],
    );
  }

  /// Tests that selecting [select] at the marked range in [content]
  /// provides the possible replacements from [expectPresentations].
  Future<void> _checkPresentations({
    required Color select,
    required List<ColorPresentation> expectPresentations,
  }) async {
    newFile(testFilePath, code.code);
    await initialize();

    // Verify that the region in the test actually matches a region that we
    // would product a range for when computing colours, otherwise the test
    // might verify something different to what the user would actually see.
    var colors = await getDocumentColors(testFileUri);
    expect(
      colors.map((color) => color.range),
      contains(colorRange),
      reason: 'Tests should only fetch colour presentations for ranges that '
          'would be computed by server',
    );

    var colorPresentations = await getColorPresentation(
      testFileUri,
      colorRange,
      select,
    );

    expect(colorPresentations, equals(expectPresentations));
  }

  /// Creates a [ColorPresentation] for comparing against actual results.
  ColorPresentation _color(
    String label, {
    String? colorCode,
    List<TextEdit>? additionalEdits,
    bool withConst = false,
  }) {
    colorCode ??= (withConst ? 'const $label' : label);
    var edit = TextEdit(range: colorRange, newText: colorCode);
    return ColorPresentation(
      label: label,
      textEdit: edit,
      additionalTextEdits: additionalEdits,
    );
  }
}

@reflectiveTest
class DocumentColorTest extends AbstractLspAnalysisServerTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_nonDartFile() async {
    newFile(pubspecFilePath, simplePubspecContent);
    await initialize();

    var colors = await getDocumentColors(pubspecFileUri);
    expect(colors, isEmpty);
  }

  Future<void> test_simpleColor() async {
    var content = '''
import 'package:flutter/material.dart';

const red = [!Colors.red!];
''';
    var code = TestCode.parse(content);
    newFile(mainFilePath, code.code);
    await initialize();

    var colors = await getDocumentColors(mainFileUri);
    expect(colors, hasLength(1));

    var color = colors[0];
    expect(color.range, code.range.range);
    expect(color.color.alpha, equals(1));
    expect(color.color.red, equals(1));
    expect(color.color.green, equals(0));
    expect(color.color.blue, equals(0));
  }
}
