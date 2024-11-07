// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterOutlineTest);
    defineReflectiveTests(FlutterOutlineNonFlutterProjectTest);
  });
}

@reflectiveTest
class FlutterOutlineNonFlutterProjectTest
    extends AbstractLspAnalysisServerTest {
  /// In a project that doesn't reference Flutter, no Flutter outlines should
  /// be sent.
  Future<void> test_noOutline() async {
    var content = 'void f() {}';
    await initialize(initializationOptions: {'flutterOutline': true});

    // Wait up to 1sec to ensure no error/log notifications were sent back.
    var didTimeout = false;
    var outlineNotification = waitForFlutterOutline(mainFileUri)
        // ignore: unnecessary_cast
        .then((outline) => outline as FlutterOutline?)
        .timeout(
          const Duration(seconds: 1),
          onTimeout: () {
            didTimeout = true;
            return null;
          },
        );
    // Only open files trigger outline notifications.
    await openFile(mainFileUri, content);

    expect(await outlineNotification, isNull);
    expect(didTimeout, isTrue);
  }
}

@reflectiveTest
class FlutterOutlineTest extends AbstractLspAnalysisServerTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_afterChange() async {
    var initialContent = '''
import 'package:flutter/material.dart';

Widget build(BuildContext context) => Container();
''';
    var updatedContent = '''
import 'package:flutter/material.dart';

Widget build(BuildContext context) => Icon(Icons.alarm);
''';

    await initialize(initializationOptions: {'flutterOutline': true});

    var outlineUpdateBeforeChange = waitForFlutterOutline(mainFileUri);
    await openFile(mainFileUri, initialContent);
    var outlineBeforeChange = await outlineUpdateBeforeChange;

    var outlineUpdateAfterChange = waitForFlutterOutline(mainFileUri);
    await replaceFile(1, mainFileUri, updatedContent);
    var outlineAfterChange = await outlineUpdateAfterChange;

    expect(outlineBeforeChange, isNotNull);
    expect(outlineBeforeChange.children, hasLength(1));
    expect(
      outlineBeforeChange.children![0].children![0].className,
      equals('Container'),
    );

    expect(outlineAfterChange, isNotNull);
    expect(outlineAfterChange.children, hasLength(1));
    expect(
      outlineAfterChange.children![0].children![0].className,
      equals('Icon'),
    );
  }

  /// Test inside a file in 'package:flutter' itself.
  Future<void> test_flutterPackage() async {
    newFile(mainFilePath, '');
    await initialize(initializationOptions: {'flutterOutline': true});

    // Find the path to our mock 'package:flutter/widgets.dart'.
    var driver = server.getAnalysisDriver(mainFilePath)!;
    var widgetsFilePath =
        driver.currentSession.uriConverter.uriToPath(Uri.parse(widgetsUri))!;
    var widgetsFileUri = Uri.file(widgetsFilePath);

    // We have to provide content to open a file so just read it.
    var widgetsFileContent =
        (driver.getFileSync(widgetsFilePath) as FileResult).content;
    var outlineNotification = waitForFlutterOutline(widgetsFileUri);
    await openFile(widgetsFileUri, widgetsFileContent);
    var outline = await outlineNotification;

    expect(outline, isNotNull);
  }

  Future<void> test_initial() async {
    var code = TestCode.parse('''
import 'package:flutter/material.dart';

/// My build method
Widget build(BuildContext context) {
  return Container(
    child: DefaultTextStyle(
      child: Row(
        children: <Widget>[
          Container(child: Icon(Icons.alarm)),
          Expanded(child: Container()),
        ],
      ),
    ),
  );
}
''');
    await initialize(initializationOptions: {'flutterOutline': true});

    var outlineNotification = waitForFlutterOutline(mainFileUri);
    await openFile(mainFileUri, code.code);
    var outline = await outlineNotification;

    expect(outline, isNotNull);

    // Root node is entire document
    expect(
      outline.range,
      equals(
        Range(
          start: Position(line: 0, character: 0),
          end: Position(line: 15, character: 0),
        ),
      ),
    );
    expect(outline.children, hasLength(1));

    var build = outline.children![0];
    expect(build.kind, equals('DART_ELEMENT'));
    expect(
      build.range,
      equals(
        Range(
          start: Position(line: 2, character: 0),
          end: Position(line: 14, character: 1),
        ),
      ),
    );
    expect(
      build.codeRange,
      equals(
        Range(
          start: Position(line: 3, character: 0),
          end: Position(line: 14, character: 1),
        ),
      ),
    );
    var dartElement = build.dartElement!;
    expect(dartElement.kind, equals('FUNCTION'));
    expect(dartElement.name, equals('build'));
    expect(dartElement.parameters, equals('(BuildContext context)'));
    expect(
      dartElement.range,
      equals(
        Range(
          start: Position(line: 3, character: 7),
          end: Position(line: 3, character: 12),
        ),
      ),
    );
    expect(dartElement.returnType, equals('Widget'));
    expect(build.children, hasLength(1));

    var icon =
        build.children![0].children![0].children![0].children![0].children![0];
    expect(icon.kind, equals('NEW_INSTANCE'));
    expect(icon.className, 'Icon');
    expect(
      icon.range,
      equals(
        Range(
          start: Position(line: 8, character: 27),
          end: Position(line: 8, character: 44),
        ),
      ),
    );
    expect(icon.codeRange, equals(icon.range));
    expect(icon.attributes, hasLength(1));
    var attributes = icon.attributes!;
    expect(attributes[0].name, equals('icon'));
    expect(attributes[0].label, equals('Icons.alarm'));
    expect(
      attributes[0].valueRange,
      equals(
        Range(
          start: Position(line: 8, character: 32),
          end: Position(line: 8, character: 43),
        ),
      ),
    );
    expect(icon.dartElement, isNull);
    expect(icon.children, hasLength(0));
  }
}
