// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterWrapStreamBuilderTest);
  });
}

@reflectiveTest
class FlutterWrapStreamBuilderTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.flutterWrapStreamBuilder;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_aroundBuilder() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(Stream<int> s) {
  ^Builder(
    builder: (context) => Text(''),
  );
}
''');
    await assertNoAssist();
  }

  Future<void> test_aroundStreamBuilder() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(Stream<int> s) {
  ^StreamBuilder(
    stream: s,
    builder: (context, asyncSnapshot) => Text(''),
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

void f(Stream<int> s) {
  StreamBuilder(
    stream: stream,
    builder: (context, asyncSnapshot) {
      return StreamBuilder(
        stream: s,
        builder: (context, asyncSnapshot) => Text(''),
      );
    }
  );
}
''');
  }

  Future<void> test_aroundText() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  ^Text('a');
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

void f() {
  StreamBuilder(
    stream: stream,
    builder: (context, asyncSnapshot) {
      return Text('a');
    }
  );
}
''');
  }

  Future<void> test_trailingComma_disabled() async {
    // No analysis options.
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class TestWidget extends StatelessWidget {
  const TestWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return const ^Text('hi');
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

class TestWidget extends StatelessWidget {
  const TestWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (context, asyncSnapshot) {
        return const Text('hi');
      }
    );
  }
}
''');
  }

  Future<void> test_trailingComma_enabled() async {
    createAnalysisOptionsFile(lints: [LintNames.require_trailing_commas]);
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class TestWidget extends StatelessWidget {
  const TestWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return const ^Text('hi');
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

class TestWidget extends StatelessWidget {
  const TestWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (context, asyncSnapshot) {
        return const Text('hi');
      },
    );
  }
}
''');
  }
}
