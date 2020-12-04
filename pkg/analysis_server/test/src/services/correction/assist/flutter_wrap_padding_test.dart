// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterWrapPaddingTest);
  });
}

@reflectiveTest
class FlutterWrapPaddingTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.FLUTTER_WRAP_PADDING;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  Future<void> test_aroundContainer() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  main() {
    return /*caret*/Container();
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  main() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(),
    );
  }
}
''');
  }

  Future<void> test_aroundPadding() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  main() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(),
    );
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_inConstantContext() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget build() {
    return const Center(
      child: /*caret*/Text('x'),
    );
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget build() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('x'),
      ),
    );
  }
}
''');
  }
}
