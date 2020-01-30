// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/utilities/mock_packages.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterOutlineTest);
  });
}

@reflectiveTest
class FlutterOutlineTest extends AbstractLspAnalysisServerTest {
  @override
  void setUp() {
    super.setUp();

    final flutterLibFolder = MockPackages.instance.addFlutter(resourceProvider);
    // Create .packages in the project.
    newFile(join(projectFolderPath, '.packages'), content: '''
flutter:${flutterLibFolder.toUri()}
''');
  }

  Future<void> test_afterChange() async {
    final initialContent = '''
import 'package:flutter/material.dart';

Widget build(BuildContext context) => Container();
''';
    final updatedContent = '''
import 'package:flutter/material.dart';

Widget build(BuildContext context) => Icon();
''';

    await initialize(initializationOptions: {'flutterOutline': true});

    final outlineUpdateBeforeChange = waitForFlutterOutline(mainFileUri);
    openFile(mainFileUri, initialContent);
    final outlineBeforeChange = await outlineUpdateBeforeChange;

    final outlineUpdateAfterChange = waitForFlutterOutline(mainFileUri);
    replaceFile(1, mainFileUri, updatedContent);
    final outlineAfterChange = await outlineUpdateAfterChange;

    expect(outlineBeforeChange, isNotNull);
    expect(outlineBeforeChange.children, hasLength(1));
    expect(outlineBeforeChange.children[0].children[0].className,
        equals('Container'));

    expect(outlineAfterChange, isNotNull);
    expect(outlineAfterChange.children, hasLength(1));
    expect(
        outlineAfterChange.children[0].children[0].className, equals('Icon'));
  }

  Future<void> test_initial() async {
    final content = '''
import 'package:flutter/material.dart';

/// My build method
Widget build(BuildContext context) => Container(
      child: DefaultTextStyle(
        child: SafeArea(
          child: Row(
            children: <Widget>[
              Container(child: Icon(Icons.ac_unit)),
              Expanded(child: Container()),
            ],
          ),
        ),
      ),
    );
''';
    await initialize(initializationOptions: {'flutterOutline': true});

    final outlineNotification = waitForFlutterOutline(mainFileUri);
    openFile(mainFileUri, content);
    final outline = await outlineNotification;

    expect(outline, isNotNull);

    // Root node is entire document
    expect(outline.range, equals(Range(Position(0, 0), Position(15, 0))));
    expect(outline.children, hasLength(1));

    final build = outline.children[0];
    expect(build.kind, equals('DART_ELEMENT'));
    expect(build.range, equals(Range(Position(2, 0), Position(14, 6))));
    expect(build.codeRange, equals(Range(Position(3, 0), Position(14, 6))));
    expect(build.dartElement.kind, equals('FUNCTION'));
    expect(build.dartElement.name, equals('build'));
    expect(build.dartElement.parameters, equals('(BuildContext context)'));
    expect(build.dartElement.range,
        equals(Range(Position(3, 7), Position(3, 12))));
    expect(build.dartElement.returnType, equals('Widget'));
    expect(build.children, hasLength(1));

    final icon =
        build.children[0].children[0].children[0].children[0].children[0];
    expect(icon.kind, equals('NEW_INSTANCE'));
    expect(icon.className, 'Icon');
    expect(icon.range, equals(Range(Position(8, 31), Position(8, 50))));
    expect(icon.codeRange, equals(icon.range));
    expect(icon.attributes, hasLength(1));
    expect(icon.attributes[0].name, equals('icon'));
    expect(icon.attributes[0].label, equals('Icons.ac_unit'));
    expect(icon.attributes[0].valueRange,
        equals(Range(Position(8, 36), Position(8, 49))));
    expect(icon.dartElement, isNull);
    expect(icon.children, hasLength(0));
  }
}
