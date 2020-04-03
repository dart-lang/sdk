// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OutlineTest);
  });
}

@reflectiveTest
class OutlineTest extends AbstractLspAnalysisServerTest {
  Future<void> test_afterChange() async {
    final initialContent = 'class A {}';
    final updatedContent = 'class B {}';
    await initialize(initializationOptions: {'outline': true});

    final outlineUpdateBeforeChange = waitForOutline(mainFileUri);
    openFile(mainFileUri, initialContent);
    final outlineBeforeChange = await outlineUpdateBeforeChange;

    final outlineUpdateAfterChange = waitForOutline(mainFileUri);
    replaceFile(1, mainFileUri, updatedContent);
    final outlineAfterChange = await outlineUpdateAfterChange;

    expect(outlineBeforeChange, isNotNull);
    expect(outlineBeforeChange.children, hasLength(1));
    expect(outlineBeforeChange.children[0].element.name, equals('A'));

    expect(outlineAfterChange, isNotNull);
    expect(outlineAfterChange.children, hasLength(1));
    expect(outlineAfterChange.children[0].element.name, equals('B'));
  }

  Future<void> test_extensions() async {
    final initialContent = '''
extension StringExtensions on String {}
extension on String {}
    ''';
    await initialize(initializationOptions: {'outline': true});

    final outlineUpdate = waitForOutline(mainFileUri);
    openFile(mainFileUri, initialContent);
    final outline = await outlineUpdate;

    expect(outline, isNotNull);
    expect(outline.children, hasLength(2));
    expect(outline.children[0].element.name, equals('StringExtensions'));
    expect(outline.children[1].element.name, equals('<unnamed extension>'));
  }

  Future<void> test_initial() async {
    final content = '''
/// a
class A {
  /// b
  b() {
    /// c
    c() {}
  }

  /// d
  num get d => 1;
}
''';
    await initialize(initializationOptions: {'outline': true});

    final outlineNotification = waitForOutline(mainFileUri);
    openFile(mainFileUri, content);
    final outline = await outlineNotification;

    expect(outline, isNotNull);

    // Root node is entire document
    expect(outline.range, equals(Range(Position(0, 0), Position(11, 0))));
    expect(outline.children, hasLength(1));

    // class A
    final classA = outline.children[0];
    expect(classA.element.name, equals('A'));
    expect(classA.element.kind, equals('CLASS'));
    expect(classA.element.range, equals(Range(Position(1, 6), Position(1, 7))));
    expect(classA.range, equals(Range(Position(0, 0), Position(10, 1))));
    expect(classA.codeRange, equals(Range(Position(1, 0), Position(10, 1))));
    expect(classA.children, hasLength(2));

    // b()
    final methodB = classA.children[0];
    expect(methodB.element.name, equals('b'));
    expect(methodB.element.kind, equals('METHOD'));
    expect(
        methodB.element.range, equals(Range(Position(3, 2), Position(3, 3))));
    expect(methodB.range, equals(Range(Position(2, 2), Position(6, 3))));
    expect(methodB.codeRange, equals(Range(Position(3, 2), Position(6, 3))));
    expect(methodB.children, hasLength(1));

    // c()
    final methodC = methodB.children[0];
    expect(methodC.element.name, equals('c'));
    expect(methodC.element.kind, equals('FUNCTION'));
    expect(
        methodC.element.range, equals(Range(Position(5, 4), Position(5, 5))));
    // TODO(dantup): This one seems to be excluding its dartdoc?
    // should be line 4 for the starting range.
    // https://github.com/dart-lang/sdk/issues/39746
    expect(methodC.range, equals(Range(Position(5, 4), Position(5, 10))));
    expect(methodC.codeRange, equals(Range(Position(5, 4), Position(5, 10))));
    expect(methodC.children, isNull);

    // num get d
    final fieldD = classA.children[1];
    expect(fieldD.element.name, equals('d'));
    expect(fieldD.element.kind, equals('GETTER'));
    expect(
        fieldD.element.range, equals(Range(Position(9, 10), Position(9, 11))));
    expect(fieldD.range, equals(Range(Position(8, 2), Position(9, 17))));
    expect(fieldD.codeRange, equals(Range(Position(9, 2), Position(9, 17))));
    expect(fieldD.children, isNull);
  }
}
