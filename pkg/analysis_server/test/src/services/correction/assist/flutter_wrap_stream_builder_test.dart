// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
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
  AssistKind get kind => DartAssistKind.FLUTTER_WRAP_STREAM_BUILDER;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  Future<void> test_aroundStreamBuilder() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

main() {
  /*caret*/StreamBuilder(
    stream: null,
    builder: (context, snapshot) => null,
  );
}
''');
    await assertNoAssist();
  }

  Future<void> test_aroundText() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

main() {
  /*caret*/Text('a');
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

main() {
  StreamBuilder<Object>(
    stream: null,
    builder: (context, snapshot) {
      return Text('a');
    }
  );
}
''');
  }
}
