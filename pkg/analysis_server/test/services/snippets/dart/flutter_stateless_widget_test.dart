// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/flutter_stateless_widget.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterStatelessWidgetTest);
  });
}

@reflectiveTest
class FlutterStatelessWidgetTest extends FlutterSnippetProducerTest {
  @override
  final generator = FlutterStatelessWidget.new;

  @override
  String get label => FlutterStatelessWidget.label;

  @override
  String get prefix => FlutterStatelessWidget.prefix;

  Future<void> test_noSuperParams() async {
    writeTestPackageConfig(flutter: true, languageVersion: '2.16');

    final snippet = await expectValidSnippet(TestCode.empty);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    final expected = TestCode.parse('''
import 'package:flutter/widgets.dart';

class /*0*/MyWidget extends StatelessWidget {
  const /*1*/MyWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return /*[0*/const Placeholder()/*0]*/;
  }
}''');
    assertFlutterSnippetChange(snippet.change, 'MyWidget', expected);
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

class /*0*/MyWidget extends StatelessWidget {
  const /*1*/MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return /*[0*/const Placeholder()/*0]*/;
  }
}''');
    assertFlutterSnippetChange(snippet.change, 'MyWidget', expected);
  }
}
