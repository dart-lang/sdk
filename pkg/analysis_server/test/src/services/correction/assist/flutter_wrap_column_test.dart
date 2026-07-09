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
  AssistKind get kind => DartAssistKind.flutterWrapColumn;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_controlFlowCollections_if() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

Widget build(bool b) {
  return Row(
    children: [
      Text('aaa'),
      if (b) ^Text('bbb'),
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
  Widget f() {
    return Container(
      child: ^Text('aaa'),
    );
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

class FakeFlutter {
  Widget f() {
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
  Widget f() {
    return Row(children: [
      Text('aaa'),
      [!Text('bbb'),
      Text('ccc'),!]
      Text('ddd'),
    ]);
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

class FakeFlutter {
  Widget f() {
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
  Widget f() {
    return Container(
      child: Text^('aaa'),
    );
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

class FakeFlutter {
  Widget f() {
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

  Future<void> test_selectedWidgetName() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class FakeFlutter {
  Widget f() {
    return Container(
      child: /*[0*/Text/*0]*/('aaa'),
    );
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

class FakeFlutter {
  Widget f() {
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
