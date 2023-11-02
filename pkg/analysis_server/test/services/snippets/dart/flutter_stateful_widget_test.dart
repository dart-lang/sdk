// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/snippets/dart/flutter_stateful_widget.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterStatefulWidgetTest);
  });
}

@reflectiveTest
class FlutterStatefulWidgetTest extends FlutterSnippetProducerTest {
  @override
  final generator = FlutterStatefulWidget.new;

  @override
  String get label => FlutterStatefulWidget.label;

  @override
  String get prefix => FlutterStatefulWidget.prefix;

  Future<void> test_noSuperParams() async {
    writeTestPackageConfig(flutter: true, languageVersion: '2.16');

    final code = TestCode.empty;
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    var result = code.code;
    expect(snippet.change.edits, hasLength(1));
    for (var edit in snippet.change.edits) {
      result = SourceEdit.applySequence(result, edit.edits);
    }
    expect(result, '''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}''');
  }

  Future<void> test_notValid_notFlutterProject() async {
    writeTestPackageConfig();

    await expectNotValidSnippet('^');
  }

  Future<void> test_valid() async {
    writeTestPackageConfig(flutter: true);

    final snippet = await expectValidSnippet(TestCode.empty);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    final expected = TestCode.parse('''
import 'package:flutter/widgets.dart';

class /*0*/MyWidget extends StatefulWidget {
  const /*1*/MyWidget({super.key});

  @override
  State</*2*/MyWidget> createState() => _/*3*/MyWidgetState();
}

class _/*4*/MyWidgetState extends State</*5*/MyWidget> {
  @override
  Widget build(BuildContext context) {
    return /*[0*/const Placeholder()/*0]*/;
  }
}''');
    assertFlutterSnippetChange(snippet.change, 'MyWidget', expected);
  }
}
