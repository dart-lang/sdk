// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/snippets/dart/flutter_stateless_widget.dart';
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

    final snippet = await expectValidSnippet('^');
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    var code = '';
    expect(snippet.change.edits, hasLength(1));
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
    expect(code, '''
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);

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

    final snippet = await expectValidSnippet('^');
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    var code = '';
    expect(snippet.change.edits, hasLength(1));
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
    expect(code, '''
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 244);
    expect(snippet.change.selectionLength, 19);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 115},
          {'file': testFile, 'offset': 158},
        ],
        'length': 8,
        'suggestions': []
      }
    ]);
  }
}
