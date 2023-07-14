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

  @override
  void setUp() {
    super.setUp();
    writePackageConfig(projectFolderPath, flutter: true);

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
        _color('Color(0xFFFF0000)'),
      ],
    );
  }

  /// If a color already has 'const' ahead of it, we should not insert another.
  Future<void> test_colorConstructor_constKeyword() async {
    content = '''
import 'package:flutter/material.dart';

var white = const [!Color(0xFFFFFFFF)!];
''';

    await _checkPresentations(
      select: Color(alpha: 1, red: 1, green: 0, blue: 0),
      expectPresentations: [
        _color('Color.fromARGB(255, 255, 0, 0)'),
        _color('Color.fromRGBO(255, 0, 0, 1)'),
        _color('Color(0xFFFF0000)'),
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
        _color('Color(0xFFFF0000)'),
      ],
    );
  }

  Future<void> test_includesImportEdit() async {
    // Create a file that doesn't already import the required library.
    content = '''
const white = [!Colors.white!];
''';

    await _checkPresentations(
      select: Color(alpha: 1, red: 1, green: 1, blue: 1),
      expectPresentations: [
        _color('Color.fromARGB(255, 255, 255, 255)', importUri: uiImportUri),
        _color('Color.fromRGBO(255, 255, 255, 1)', importUri: uiImportUri),
        _color('Color(0xFFFFFFFF)', importUri: uiImportUri),
      ],
    );
  }

  Future<void> test_nonDartFile() async {
    newFile(pubspecFilePath, simplePubspecContent);
    await initialize();

    final colors = await getColorPresentation(
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

    final colorPresentations = await getColorPresentation(
      pathContext.toUri(testFilePath),
      colorRange,
      select,
    );

    expect(colorPresentations, equals(expectPresentations));
  }

  /// Creates a [ColorPresentation] for comparing against actual results.
  ColorPresentation _color(
    String label, {
    String? colorCode,
    String? importUri,
    bool withConst = false,
  }) {
    colorCode ??= (withConst ? 'const $label' : label);
    final edit = TextEdit(range: colorRange, newText: colorCode);
    final additionalEdits = importUri != null
        ? [
            TextEdit(
              range: startOfDocRange,
              newText: "import '$importUri';\n\n",
            )
          ]
        : null;

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
    writePackageConfig(projectFolderPath, flutter: true);
  }

  Future<void> test_nonDartFile() async {
    newFile(pubspecFilePath, simplePubspecContent);
    await initialize();

    final colors = await getDocumentColors(pubspecFileUri);
    expect(colors, isEmpty);
  }

  Future<void> test_simpleColor() async {
    final content = '''
import 'package:flutter/material.dart';

const red = [!Colors.red!];
''';
    final code = TestCode.parse(content);
    newFile(mainFilePath, code.code);
    await initialize();

    final colors = await getDocumentColors(mainFileUri);
    expect(colors, hasLength(1));

    final color = colors[0];
    expect(color.range, code.range.range);
    expect(color.color.alpha, equals(1));
    expect(color.color.red, equals(1));
    expect(color.color.green, equals(0));
    expect(color.color.blue, equals(0));
  }
}
