// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterWrapCenterTest);
  });
}

@reflectiveTest
class FlutterWrapCenterTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.FLUTTER_WRAP_CENTER;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  Future<void> test_aroundCenter() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return /*caret*/Center();
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_aroundContainer() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return /*caret*/Container();
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return Center(child: Container());
  }
}
''');
  }

  Future<void> test_aroundNamedConstructor() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  MyWidget.named();

  Widget build(BuildContext context) => Text('');
}

Widget f() {
  return MyWidget./*caret*/named();
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  MyWidget.named();

  Widget build(BuildContext context) => Text('');
}

Widget f() {
  return Center(child: MyWidget.named());
}
''');
  }

  Future<void> test_assignment() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  Widget w;
  w = /*caret*/Container();
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

void f() {
  Widget w;
  w = Center(child: Container());
}
''');
  }

  Future<void> test_expressionFunctionBody() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() => /*caret*/Container();
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() => Center(child: Container());
}
''');
  }

  Future<void> test_selection() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return /*caret*/Container();
  }
}
''');
    var expected = '''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return Center(child: Container());
  }
}
''';

    var assist = await assertHasAssist(expected);

    expect(
      assist.selection!.offset,
      normalizeSource(expected).indexOf('child: '),
    );
    expect(assist.selectionLength, 0);
  }

  Future<void> test_switchExpression() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
Widget f(int i) => /*caret*/switch (i) {
  0 => Row(),
  _ => Column(),
};
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
Widget f(int i) => Center(
  child: switch (i) {
    0 => Row(),
    _ => Column(),
  },
);
''');
  }

  Future<void> test_switchExpression_case() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
Widget f() => switch (1) {
  _ => /*caret*/Container(),
};
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
Widget f() => switch (1) {
  _ => Center(child: Container()),
};
''');
  }

  Future<void> test_variableDeclaration() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  Widget w = /*caret*/Container();
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

void f() {
  Widget w = Center(child: Container());
}
''');
  }

  Future<void> test_variableDeclaration_name() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  Widget /*caret*/w = Container();
}
''');
    await assertNoAssist();
  }
}
