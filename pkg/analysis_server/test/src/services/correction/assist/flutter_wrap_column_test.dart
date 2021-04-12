// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterWrapColumnTest);
  });
}

@reflectiveTest
class FlutterWrapColumnTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.FLUTTER_WRAP_COLUMN;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  Future<void> test_controlFlowCollections_if() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

Widget build(bool b) {
  return Row(
    children: [
      Text('aaa'),
      if (b) /*caret*/Text('bbb'),
      Text('ccc'),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

Widget build(bool b) {
  return Row(
    children: [
      Text('aaa'),
      if (b) Column(
        children: [
          Text('bbb'),
        ],
      ),
      Text('ccc'),
    ],
  );
}
''');
  }

  Future<void> test_coveredByWidget() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class FakeFlutter {
  main() {
    return Container(
      child: /*caret*/Text('aaa'),
    );
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

class FakeFlutter {
  main() {
    return Container(
      child: Column(
        children: [
          Text('aaa'),
        ],
      ),
    );
  }
}
''');
  }

  Future<void> test_coversWidgets() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class FakeFlutter {
  main() {
    return Row(children: [
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
    return Row(children: [
      Text('aaa'),
      Column(
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

  Future<void> test_endOfWidgetName() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class FakeFlutter {
  main() {
    return Container(
      child: Text/*caret*/('aaa'),
    );
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

class FakeFlutter {
  main() {
    return Container(
      child: Column(
        children: [
          Text('aaa'),
        ],
      ),
    );
  }
}
''');
  }
}
