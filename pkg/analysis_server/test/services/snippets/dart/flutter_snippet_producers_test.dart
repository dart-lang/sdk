// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/flutter_snippet_producers.dart';
import 'package:analysis_server/src/services/snippets/dart/snippet_manager.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_single_unit.dart';
import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterStatelessWidgetSnippetProducerTest);
  });
}

class FlutterSnippetProducerTest extends AbstractSingleUnitTest {
  Future<void> expectNotValidSnippet(
    SnippetProducerGenerator generator,
    String code,
  ) async {
    await resolveTestCode(withoutMarkers(code));
    final request = DartSnippetRequest(
      unit: testAnalysisResult,
      offset: offsetFromMarker(code),
    );

    final producer = generator(request);
    expect(await producer.isValid(), isFalse);
  }

  Future<Snippet> expectValidSnippet(
      SnippetProducerGenerator generator, String code) async {
    await resolveTestCode(withoutMarkers(code));
    final request = DartSnippetRequest(
      unit: testAnalysisResult,
      offset: offsetFromMarker(code),
    );

    final producer = generator(request);
    expect(await producer.isValid(), isTrue);
    return producer.compute();
  }
}

@reflectiveTest
class FlutterStatelessWidgetSnippetProducerTest
    extends FlutterSnippetProducerTest {
  Future<void> test_notValid_notFlutterProject() async {
    writeTestPackageConfig();

    await expectNotValidSnippet(
      FlutterStatelessWidgetSnippetProducer.newInstance,
      '^',
    );
  }

  Future<void> test_notValid_notTopLevel() async {
    writeTestPackageConfig();

    await expectNotValidSnippet(
      FlutterStatelessWidgetSnippetProducer.newInstance,
      'class A { ^ }',
    );
  }

  Future<void> test_valid() async {
    writeTestPackageConfig(flutter: true);

    final snippet = await expectValidSnippet(
      FlutterStatelessWidgetSnippetProducer.newInstance,
      '^',
    );
    expect(snippet.prefix, 'stless');
    expect(snippet.label, 'Flutter Stateless Widget');
    expect(snippet.change.toJson(), {
      'message': '',
      'edits': [
        {
          'file': testFile,
          'fileStamp': 0,
          'edits': [
            {
              'offset': 0,
              'length': 0,
              'replacement':
                  'import \'package:flutter/src/foundation/key.dart\';\n'
                      'import \'package:flutter/src/widgets/framework.dart\';\n'
            },
            {
              'offset': 0,
              'length': 0,
              'replacement': 'class MyWidget extends StatelessWidget {\n'
                  '  const MyWidget({Key? key}) : super(key: key);\n'
                  '\n'
                  '  @override\n'
                  '  Widget build(BuildContext context) {\n'
                  '    \n'
                  '  }\n'
                  '}'
            }
          ]
        }
      ],
      'linkedEditGroups': [
        {
          'positions': [
            {'file': testFile, 'offset': 109},
            {'file': testFile, 'offset': 152}
          ],
          'length': 8,
          'suggestions': []
        }
      ],
      'selection': {'file': testFile, 'offset': 248}
    });
  }
}
