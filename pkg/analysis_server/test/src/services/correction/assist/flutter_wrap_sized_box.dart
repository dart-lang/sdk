// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

// todo: update for SizedBox

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterWrapSizedBoxTest);
  });
}

@reflectiveTest
class FlutterWrapSizedBoxTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.FLUTTER_WRAP_SIZED_BOX;

  Future<void> test_aroundContainer() async {
    addFlutterPackage();
    await resolveTestUnit('''
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
    return SizedBox(child: Container());
  }
}
''');
  }

  Future<void> test_aroundNamedConstructor() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  MyWidget.named();

  Widget build(BuildContext context) => null;
}

main() {
  return MyWidget./*caret*/named();
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  MyWidget.named();

  Widget build(BuildContext context) => null;
}

main() {
  return SizedBox(child: MyWidget.named());
}
''');
  }

  Future<void> test_aroundSizedBox() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  main() {
    return /*caret*/SizedBox();
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_assignment() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';

main() {
  Widget w;
  w = /*caret*/Container();
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

main() {
  Widget w;
  w = SizedBox(child: Container());
}
''');
  }

  Future<void> test_expressionFunctionBody() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  main() => /*caret*/Container();
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  main() => SizedBox(child: Container());
}
''');
  }
}
