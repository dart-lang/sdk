// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterWrapRowTest);
  });
}

@reflectiveTest
class FlutterWrapRowTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.FLUTTER_WRAP_ROW;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  Future<void> test_twoWidgets() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class FakeFlutter {
  main() {
    return Column(children: [
      Text('aaa'),
// start
      Text('bbb'),
      Text('ccc'),
// end
      Text('ddd'),
    ]);
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

class FakeFlutter {
  main() {
    return Column(children: [
      Text('aaa'),
      Row(
        children: [
          Text('bbb'),
          Text('ccc'),
        ],
      ),
      Text('ddd'),
    ]);
  }
}
''');
  }
}
