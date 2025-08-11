// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterWrapFlexibleTest);
  });
}

@reflectiveTest
class FlutterWrapFlexibleTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.flutterWrapFlexible;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_aroundContainer() async {
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
    return Flexible(child: Container());
  }
}
''');
  }

  Future<void> test_aroundFlexible() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return ^Flexible(child: Container());
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_aroundNamedConstructor() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  MyWidget.named();

  Widget build(BuildContext context) => Text('');
}

Widget f() {
  return MyWidget.^named();
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  MyWidget.named();

  Widget build(BuildContext context) => Text('');
}

Widget f() {
  return Flexible(child: MyWidget.named());
}
''');
  }

  Future<void> test_assignment() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  Widget w;
  w = ^Container();
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

void f() {
  Widget w;
  w = Flexible(child: Container());
}
''');
  }

  Future<void> test_expressionFunctionBody() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() => ^Container();
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() => Flexible(child: Container());
}
''');
  }

  Future<void> test_insideColumn() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return Column(
      children: [^Text('aaa')],
    );
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return Column(
      children: [Flexible(child: Text('aaa'))],
    );
  }
}
''');
  }

  Future<void> test_insideContainer() async {
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
    await assertNoAssist();
  }

  Future<void> test_insideFlex() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return Flex(
      children: [^Text('aaa')],
    );
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return Flex(
      children: [Flexible(child: Text('aaa'))],
    );
  }
}
''');
  }

  Future<void> test_insideRow() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return Row(
      children: [
        ^Text('aaa'),
      ],
    );
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return Row(
      children: [
        Flexible(child: Text('aaa')),
      ],
    );
  }
}
''');
  }

  Future<void> test_insideStack() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return Stack(
      children: [^Text('aaa')],
    );
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_selection() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return ^Container();
  }
}
''');
    var expected = '''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  Widget f() {
    return Flexible(child: Container());
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
Widget f(int i) => ^switch (i) {
  0 => Row(),
  _ => Column(),
};
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
Widget f(int i) => Flexible(
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
  _ => ^Container(),
};
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
Widget f() => switch (1) {
  _ => Flexible(child: Container()),
};
''');
  }

  Future<void> test_variableDeclaration() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  Widget w = ^Container();
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

void f() {
  Widget w = Flexible(child: Container());
}
''');
  }

  Future<void> test_variableDeclaration_name() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  Widget ^w = Container();
}
''');
    await assertNoAssist();
  }
}
