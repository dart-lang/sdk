// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoLogicInCreateStateTest);
  });
}

@reflectiveTest
class NoLogicInCreateStateTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get lintRule => 'no_logic_in_create_state';

  test_abstract() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract class MyWidget extends StatefulWidget {
  @override
  MyState createState();
}

class MyState extends State {
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

class MyState extends State {
  int field = 0;
}
''');
  }

  test_arrowBody_returnsState_passingArguments() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  MyState createState() => MyState(1);
}

class MyState extends State {
  int field;
  MyState(this.field);
}
''', [
      lint(119, 10),
    ]);
  }

  test_arrowBody_returnsState_withCascade() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  MyState createState() => MyState()..field = 0;
}

class MyState extends State {
  int field = 0;
}
''', [
      lint(119, 20),
    ]);
  }

  test_blockBodyWithSingleStatement_returnsInstanceField() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  MyState instance = MyState();
  @override
  MyState createState() {
    return instance;
  }
}

class MyState extends State {
  int field = 0;
}
''', [
      lint(161, 8),
    ]);
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

class MyState extends State {
  int field = 0;
}
''');
  }

  test_blockBodyWithSingleStatement_returnsState_withCascade() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  MyState createState() {
    return MyState()..field = 0;
  }
}

class MyState extends State {
  int field = 0;
}
''', [
      lint(129, 20),
    ]);
  }

  test_instantiateTopLevel_returnTopLevel() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

class MyStatefulBad extends StatefulWidget {
  @override
  MyState createState() {
    global = MyState();
    return global;
  }
}

class MyState extends State {
  int field = 0;
}

var global = MyState();
''', [
      lint(121, 48),
    ]);
  }
}
