// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterWrapGenericTest);
  });
}

@reflectiveTest
class FlutterWrapGenericTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.flutterWrapGeneric;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_editGroup() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return Te^xt('');
  }
}
''');
    var expected = '''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return widget(child: Text(''));
  }
}
''';
    var assist = await assertHasAssist(expected);

    expect(assist.selection, isNull);
    expect(assist.selectionLength, isNull);

    var editGroup = assist.linkedEditGroups.first;
    expect(editGroup.length, 'widget'.length);
    var pos = editGroup.positions.single;
    expect(pos.offset, normalizeSource(expected).indexOf('widget('));
  }

  Future<void> test_minimal() async {
    await resolveTestCode('''
^x(){}
''');
    await assertNoAssist();
  }

  Future<void> test_multiLine() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
build() {
  return Container(
    child: Row(
      children: [^
        Text('111'),
        Text('222'),
        Container(),
      ],
    ),
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
build() {
  return Container(
    child: Row(
      children: [
        widget(
          children: [
            Text('111'),
            Text('222'),
            Container(),
          ],
        ),
      ],
    ),
  );
}
''');
  }

  Future<void> test_multiLine_inListLiteral() async {
    verifyNoTestUnitErrors = false;

    await resolveTestCode('''
import 'package:flutter/widgets.dart';
build() {
  return Container(
    child: Row(
      children: [
        [!Transform(),
        Object(),
        AspectRatio(),!]
      ],
    ),
  );
}
''');
    await assertNoAssist();
  }

  Future<void> test_multiLines() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return Container(
      child: ^DefaultTextStyle(
        style: TextStyle(),
        child: Row(
          children: [
            Container(
            ),
          ],
        ),
      ),
    );
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return Container(
      child: widget(
        child: DefaultTextStyle(
          style: TextStyle(),
          child: Row(
            children: [
              Container(
              ),
            ],
          ),
        ),
      ),
    );
  }
}
''');
  }

  Future<void> test_multiLines_eol2() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';\r
class FakeFlutter {\r
  Widget f() {\r
    return Container(\r
      child: ^DefaultTextStyle(\r
        style: TextStyle(),\r
        child: Row(\r
          children: [\r
            Container(\r
            ),\r
          ],\r
        ),\r
      ),\r
    );\r
  }\r
}\r
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';\r
class FakeFlutter {\r
  Widget f() {\r
    return Container(\r
      child: widget(\r
        child: DefaultTextStyle(\r
          style: TextStyle(),\r
          child: Row(\r
            children: [\r
              Container(\r
              ),\r
            ],\r
          ),\r
        ),\r
      ),\r
    );\r
  }\r
}\r
''');
  }

  Future<void> test_prefixedIdentifier_identifier() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

abstract class Foo extends Widget {
  final Widget bar = Text('');
}

Widget f(Foo foo) {
  return foo.^bar;
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

abstract class Foo extends Widget {
  final Widget bar = Text('');
}

Widget f(Foo foo) {
  return widget(child: foo.bar);
}
''');
  }

  Future<void> test_prefixedIdentifier_prefix() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

abstract class Foo extends Widget {
  final Widget bar = Text('');
}

Widget f(Foo foo) {
  return ^foo.bar;
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

abstract class Foo extends Widget {
  final Widget bar = Text('');
}

Widget f(Foo foo) {
  return widget(child: foo.bar);
}
''');
  }

  Future<void> test_singleLine() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    var obj;
    return Row(children: [^ Container()]);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_singleLine1() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return ^Container();
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return widget(child: Container());
  }
}
''');
  }

  Future<void> test_singleLine2() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return ClipRect.^new();
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return widget(child: ClipRect.new());
  }
}
''');
  }

  Future<void> test_variable() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    var container = Container();
    return ^container;
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    var container = Container();
    return widget(child: container);
  }
}
''');
  }
}
