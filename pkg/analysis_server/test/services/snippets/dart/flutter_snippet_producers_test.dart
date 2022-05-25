// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/snippets/dart/flutter_snippet_producers.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'dart_snippet_producers_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterStatefulWidgetSnippetProducerTest);
    defineReflectiveTests(
        FlutterStatefulWidgetWithAnimationControllerSnippetProducerTest);
    defineReflectiveTests(FlutterStatelessWidgetSnippetProducerTest);
  });
}

abstract class FlutterSnippetProducerTest extends DartSnippetProducerTest {
  /// Checks snippets can produce edits where the imports and snippet will be
  /// inserted at the same location.
  ///
  /// For example, when a document is completely empty besides the snippet
  /// prefix, the imports will be inserted at offset 0 and the snippet will
  /// replace from 0 to the end of the typed prefix.
  Future<void> test_valid_importsAndEditsOverlap() async {
    writeTestPackageConfig(flutter: true);

    final snippet = await expectValidSnippet('$prefix^');
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);

    // Main edits replace $prefix.length characters starting at $prefix
    final mainEdit = snippet.change.edits[0].edits[0];
    expect(mainEdit.offset, testCode.indexOf(prefix));
    expect(mainEdit.length, prefix.length);

    // Imports inserted at start of doc (0)
    final importEdit = snippet.change.edits[0].edits[1];
    expect(importEdit.offset, 0);
    expect(importEdit.length, 0);
  }

  Future<void> test_valid_suffixReplacement() async {
    writeTestPackageConfig(flutter: true);

    final snippet = await expectValidSnippet('''
class A {}

$prefix^
''');
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);

    // Main edits replace $prefix.length characters starting at $prefix
    final mainEdit = snippet.change.edits[0].edits[0];
    expect(mainEdit.offset, testCode.indexOf(prefix));
    expect(mainEdit.length, prefix.length);

    // Imports inserted at start of doc (0)
    final importEdit = snippet.change.edits[0].edits[1];
    expect(importEdit.offset, 0);
    expect(importEdit.length, 0);
  }
}

@reflectiveTest
class FlutterStatefulWidgetSnippetProducerTest
    extends FlutterSnippetProducerTest {
  @override
  final generator = FlutterStatefulWidgetSnippetProducer.newInstance;

  @override
  String get label => FlutterStatefulWidgetSnippetProducer.label;

  @override
  String get prefix => FlutterStatefulWidgetSnippetProducer.prefix;

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
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      
    );
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
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      
    );
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 373);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 113},
          {'file': testFile, 'offset': 155},
          {'file': testFile, 'offset': 199},
          {'file': testFile, 'offset': 227},
          {'file': testFile, 'offset': 254},
          {'file': testFile, 'offset': 282},
        ],
        'length': 8,
        'suggestions': []
      }
    ]);
  }
}

@reflectiveTest
class FlutterStatefulWidgetWithAnimationControllerSnippetProducerTest
    extends FlutterSnippetProducerTest {
  @override
  final generator =
      FlutterStatefulWidgetWithAnimationControllerSnippetProducer.newInstance;

  @override
  String get label =>
      FlutterStatefulWidgetWithAnimationControllerSnippetProducer.label;

  @override
  String get prefix =>
      FlutterStatefulWidgetWithAnimationControllerSnippetProducer.prefix;

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
import 'package:flutter/src/animation/animation_controller.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/ticker_provider.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      
    );
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
import 'package:flutter/src/animation/animation_controller.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/ticker_provider.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      
    );
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 776);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 238},
          {'file': testFile, 'offset': 280},
          {'file': testFile, 'offset': 324},
          {'file': testFile, 'offset': 352},
          {'file': testFile, 'offset': 379},
          {'file': testFile, 'offset': 407},
        ],
        'length': 8,
        'suggestions': []
      }
    ]);
  }
}

@reflectiveTest
class FlutterStatelessWidgetSnippetProducerTest
    extends FlutterSnippetProducerTest {
  @override
  final generator = FlutterStatelessWidgetSnippetProducer.newInstance;

  @override
  String get label => FlutterStatelessWidgetSnippetProducer.label;

  @override
  String get prefix => FlutterStatelessWidgetSnippetProducer.prefix;

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
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      
    );
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
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      
    );
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 259);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 113},
          {'file': testFile, 'offset': 156},
        ],
        'length': 8,
        'suggestions': []
      }
    ]);
  }
}
