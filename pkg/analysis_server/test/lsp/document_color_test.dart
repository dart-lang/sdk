// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentColorTest);
    defineReflectiveTests(DocumentColorPresentationTest);
  });
}

@reflectiveTest
class DocumentColorPresentationTest extends AbstractLspAnalysisServerTest {
  @override
  void setUp() {
    super.setUp();
    writePackageConfig(projectFolderPath, flutter: true);
  }

  Future<void> test_includesImportEdit() async {
    // Create a file that doesn't already import the required library.
    //
    // We don't need a real color reference in the file right now, as we're
    // calling colorPresentation directly to get the new code (and not fetching
    // colors already in the file).
    const content = '''
const white = [[]];
''';

    const expectedMainEdit = '''
const white = Color(0xFFFFFFFF);
''';

    const expectedAllEdits = '''
import 'package:ui/ui.dart';

const white = Color(0xFFFFFFFF);
''';

    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final colorPresentations = await getColorPresentation(
      mainFileUri.toString(),
      rangeFromMarkers(content),
      Color(alpha: 1, red: 1, green: 1, blue: 1),
    );
    expect(colorPresentations, hasLength(1));

    final colorPresentation = colorPresentations[0];
    expect(colorPresentation.label, 'Color(0xFFFFFFFF)');

    // Test the main edit just replaces the color.
    final contentWithMainEdit = applyTextEdits(
      withoutMarkers(content),
      [colorPresentation.textEdit!],
    );
    expect(contentWithMainEdit, equals(expectedMainEdit));

    // Test all of the edits also adds the import.
    final contentWithAllEdits = applyTextEdits(
      withoutMarkers(content),
      [colorPresentation.textEdit!, ...colorPresentation.additionalTextEdits!],
    );
    expect(contentWithAllEdits, equals(expectedAllEdits));
  }

  Future<void> test_nonDartFile() async {
    newFile(pubspecFilePath, content: simplePubspecContent);
    await initialize();

    final colors = await getColorPresentation(
      pubspecFileUri.toString(),
      startOfDocRange,
      Color(alpha: 1, red: 1, green: 1, blue: 1),
    );
    expect(colors, isEmpty);
  }

  Future<void> test_simpleColor() async {
    const content = '''
    import 'package:flutter/material.dart';

    const white = [[Color(0xFFFFFFFF)]];
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final colorPresentations = await getColorPresentation(
      mainFileUri.toString(),
      rangeFromMarkers(content),
      // Send a different color to what's in the source to simulate the user
      // having changed in the color picker. This is the one that we should be
      // creating a presentation for, not the one in the source.
      Color(alpha: 1, red: 1, green: 0, blue: 0),
    );
    expect(colorPresentations, hasLength(1));

    final colorPresentation = colorPresentations[0];
    expect(colorPresentation.label, 'Color(0xFFFF0000)');
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
    newFile(pubspecFilePath, content: simplePubspecContent);
    await initialize();

    final colors = await getDocumentColors(pubspecFileUri.toString());
    expect(colors, isEmpty);
  }

  Future<void> test_simpleColor() async {
    const content = '''
    import 'package:flutter/material.dart';

    const red = [[Colors.red]];
    ''';
    newFile(mainFilePath, content: withoutMarkers(content));
    await initialize();

    final colors = await getDocumentColors(mainFileUri.toString());
    expect(colors, hasLength(1));

    final color = colors[0];
    expect(color.range, rangeFromMarkers(content));
    expect(color.color.alpha, equals(1));
    expect(color.color.red, equals(1));
    expect(color.color.green, equals(0));
    expect(color.color.blue, equals(0));
  }
}
