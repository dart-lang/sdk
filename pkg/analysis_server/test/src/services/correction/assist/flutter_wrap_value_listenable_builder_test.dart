// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterWrapValueListenableBuilderTest);
  });
}

@reflectiveTest
class FlutterWrapValueListenableBuilderTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.flutterWrapValueListenableBuilder;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_aroundBuilder() async {
    await resolveTestCode('''
  import 'package:flutter/widgets.dart';

  void f(ValueListenable<int> v) {
    ^Builder(
      builder: (context) {
        return Text('a');
      },
    );
  }
  ''');
    await assertNoAssist();
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
  ValueListenableBuilder(
    valueListenable: valueListenable,
    builder: (context, value, child) {
      return Text('a');
    }
  );
}
''');
  }

  Future<void> test_aroundValueListenableBuilder() async {
    await resolveTestCode('''
  import 'package:flutter/widgets.dart';

  void f(ValueListenable<int> v) {
    ^ValueListenableBuilder<int>(
      valueListenable: v,
      builder: (context, value, _) {
        return Text('a');
      },
    );
  }
  ''');
    await assertHasAssist('''
  import 'package:flutter/widgets.dart';

  void f(ValueListenable<int> v) {
    ValueListenableBuilder(
      valueListenable: valueListenable,
      builder: (context, value, child) {
        return ValueListenableBuilder<int>(
          valueListenable: v,
          builder: (context, value, _) {
            return Text('a');
          },
        );
      }
    );
  }
  ''');
  }

  Future<void> test_insideValueListenableBuilder() async {
    await resolveTestCode('''
  import 'package:flutter/widgets.dart';

  void f(ValueListenable<int> v) {
    ValueListenableBuilder<int>(
      valueListenable: v,
      builder: (context, value, _) {
        return ^Text('a');
      }
    );
  }
  ''');
    await assertHasAssist('''
  import 'package:flutter/widgets.dart';

  void f(ValueListenable<int> v) {
    ValueListenableBuilder<int>(
      valueListenable: v,
      builder: (context, value, _) {
        return ValueListenableBuilder(
          valueListenable: valueListenable,
          builder: (context, value, child) {
            return Text('a');
          }
        );
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
    return ValueListenableBuilder(
      valueListenable: valueListenable,
      builder: (context, value, child) {
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
    return ValueListenableBuilder(
      valueListenable: valueListenable,
      builder: (context, value, child) {
        return const Text('hi');
      },
    );
  }
}
''');
  }
}
