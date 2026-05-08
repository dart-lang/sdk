// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoLogicInCreateStateTest);
  });
}

@reflectiveTest
class NoLogicInCreateStateTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get lintRule => LintNames.no_logic_in_create_state;

  test_abstract() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract class MyWidget extends StatefulWidget {
  @override
  MyState createState();
}

abstract class MyState extends State<MyWidget> {
  int field = 0;
}
''');
  }

  test_arrowBody_returnsState() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  MyState createState() => MyState();
}

class MyState extends State<MyWidget> {
  int field = 0;

  late BuildContext context;
  bool get mounted => false;
  Widget build(_) => MyWidget();
}
''');
  }

  test_arrowBody_returnsState_dotShorthand() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  MyState createState() => .new();
}

class MyState extends State<MyWidget> {
  int field = 0;

  late BuildContext context;
  bool get mounted => false;
  Widget build(_) => MyWidget();
}
''');
  }

  test_arrowBody_returnsState_passingArguments() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  MyState createState() => MyState(1);
}

class MyState extends State<MyWidget> {
  int field;
  MyState(this.field);

  late BuildContext context;
  bool get mounted => false;
  Widget build(_) => MyWidget();
}
''',
      [lint(119, 10)],
    );
  }

  test_arrowBody_returnsState_passingArguments_dotShorthand() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  MyState createState() => .new(1);
}

class MyState extends State<MyWidget> {
  int field;
  MyState(this.field);

  late BuildContext context;
  bool get mounted => false;
  Widget build(_) => MyWidget();
}
''',
      [lint(119, 7)],
    );
  }

  test_arrowBody_returnsState_withCascade() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  MyState createState() => MyState()..field = 0;
}

class MyState extends State<MyWidget> {
  int field = 0;

  late BuildContext context;
  bool get mounted => false;
  Widget build(_) => MyWidget();
}
''',
      [lint(119, 20)],
    );
  }

  test_arrowBody_returnsState_withCascade_dotShorthand() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  MyState createState() => .new()..field = 0;
}

class MyState extends State<MyWidget> {
  int field = 0;

  late BuildContext context;
  bool get mounted => false;
  Widget build(_) => MyWidget();
}
''',
      [lint(119, 17)],
    );
  }

  test_blockBodyWithSingleStatement_returnsInstanceField() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  MyState instance = MyState();
  @override
  MyState createState() {
    return instance;
  }
}

class MyState extends State<MyWidget> {
  int field = 0;

  late BuildContext context;
  bool get mounted => false;
  Widget build(_) => MyWidget();
}
''',
      [lint(161, 8)],
    );
  }

  test_blockBodyWithSingleStatement_returnsState() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  MyState createState() {
    return MyState();
  }
}

class MyState extends State<MyWidget> {
  int field = 0;

  late BuildContext context;
  bool get mounted => false;
  Widget build(_) => MyWidget();
}
''');
  }

  test_blockBodyWithSingleStatement_returnsState_dotShorthand() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  MyState createState() {
    return .new();
  }
}

class MyState extends State<MyWidget> {
  int field = 0;

  late BuildContext context;
  bool get mounted => false;
  Widget build(_) => MyWidget();
}
''');
  }

  test_blockBodyWithSingleStatement_returnsState_withCascade() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  MyState createState() {
    return MyState()..field = 0;
  }
}

class MyState extends State<MyWidget> {
  int field = 0;

  late BuildContext context;
  bool get mounted => false;
  Widget build(_) => MyWidget();
}
''',
      [lint(129, 20)],
    );
  }

  test_blockBodyWithSingleStatement_returnsState_withCascade_dotShorthand() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  MyState createState() {
    return .new()..field = 0;
  }
}

class MyState extends State<MyWidget> {
  int field = 0;

  late BuildContext context;
  bool get mounted => false;
  Widget build(_) => MyWidget();
}
''',
      [lint(129, 17)],
    );
  }

  test_instantiateTopLevel_returnTopLevel() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyStatefulBad extends StatefulWidget {
  @override
  MyState createState() {
    global = MyState();
    return global;
  }
}

class MyState extends State<MyStatefulBad> {
  int field = 0;

  late BuildContext context;
  bool get mounted => false;
  Widget build(_) => MyStatefulBad();
}

var global = MyState();
''',
      [lint(121, 48)],
    );
  }

  test_instantiateTopLevel_returnTopLevel_dotShorthand() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

class MyStatefulBad extends StatefulWidget {
  @override
  MyState createState() {
    global = .new();
    return global;
  }
}

class MyState extends State<MyStatefulBad> {
  int field = 0;

  late BuildContext context;
  bool get mounted => false;
  Widget build(_) => MyStatefulBad();
}

var global = MyState();
''',
      [lint(121, 45)],
    );
  }
}
