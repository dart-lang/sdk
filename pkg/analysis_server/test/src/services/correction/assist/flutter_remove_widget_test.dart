// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterRemoveWidgetTest);
  });
}

@reflectiveTest
class FlutterRemoveWidgetTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.FLUTTER_REMOVE_WIDGET;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  Future<void> test_childIntoChild_multiLine() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
main() {
  Column(
    children: [
      Center(
        child: /*caret*/Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            heightFactor: 0.5,
            child: Text('foo'),
          ),
        ),
      ),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
main() {
  Column(
    children: [
      Center(
        child: Center(
          heightFactor: 0.5,
          child: Text('foo'),
        ),
      ),
    ],
  );
}
''');
  }

  Future<void> test_childIntoChild_singleLine() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
main() {
  Padding(
    padding: const EdgeInsets.all(8.0),
    child: /*caret*/Center(
      heightFactor: 0.5,
      child: Text('foo'),
    ),
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
main() {
  Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text('foo'),
  );
}
''');
  }

  Future<void> test_childIntoChildren() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
main() {
  Column(
    children: [
      Text('foo'),
      /*caret*/Center(
        heightFactor: 0.5,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('bar'),
        ),
      ),
      Text('baz'),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
main() {
  Column(
    children: [
      Text('foo'),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('bar'),
      ),
      Text('baz'),
    ],
  );
}
''');
  }

  Future<void> test_childrenMultipleIntoChild() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
main() {
  Center(
    child: /*caret*/Row(
      children: [
        Text('aaa'),
        Text('bbb'),
      ],
    ),
  );
}
''');
    await assertNoAssist();
  }

  Future<void> test_childrenOneIntoChild() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
main() {
  Center(
    child: /*caret*/Column(
      children: [
        Text('foo'),
      ],
    ),
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
main() {
  Center(
    child: Text('foo'),
  );
}
''');
  }

  Future<void> test_childrenOneIntoReturn() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
main() {
  return /*caret*/Column(
    children: [
      Text('foo'),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
main() {
  return Text('foo');
}
''');
  }

  Future<void> test_intoChildren() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
main() {
  Column(
    children: [
      Text('aaa'),
      /*caret*/Column(
        children: [
          Row(
            children: [
              Text('bbb'),
              Text('ccc'),
            ],
          ),
          Row(
            children: [
              Text('ddd'),
              Text('eee'),
            ],
          ),
        ],
      ),
      Text('fff'),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
main() {
  Column(
    children: [
      Text('aaa'),
      Row(
        children: [
          Text('bbb'),
          Text('ccc'),
        ],
      ),
      Row(
        children: [
          Text('ddd'),
          Text('eee'),
        ],
      ),
      Text('fff'),
    ],
  );
}
''');
  }
}
