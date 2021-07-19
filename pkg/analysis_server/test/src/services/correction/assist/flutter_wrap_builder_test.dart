// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterWrapBuilderTest);
  });
}

@reflectiveTest
class FlutterWrapBuilderTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.FLUTTER_WRAP_BUILDER;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  Future<void> test_aroundBuilder() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

main() {
  /*caret*/Builder(
    builder: (context) => Text(''),
  );
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

main() {
  return MyWidget./*caret*/named();
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  MyWidget.named();

  Widget build(BuildContext context) => Text('');
}

main() {
  return Builder(
    builder: (context) {
      return MyWidget.named();
    }
  );
}
''');
  }

  Future<void> test_aroundText() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

main() {
  /*caret*/Text('a');
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

main() {
  Builder(
    builder: (context) {
      return Text('a');
    }
  );
}
''');
  }

  Future<void> test_assignment() async {
    await resolveTestCode('''
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
  w = Builder(
    builder: (context) {
      return Container();
    }
  );
}
''');
  }

  Future<void> test_expressionFunctionBody() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  main() => /*caret*/Container();
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  main() => Builder(
    builder: (context) {
      return Container();
    }
  );
}
''');
  }
}
