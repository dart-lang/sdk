// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterWrapGenericTest);
  });
}

@reflectiveTest
class FlutterWrapGenericTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.FLUTTER_WRAP_GENERIC;

  test_minimal() async {
    addFlutterPackage();
    await resolveTestUnit('''
/*caret*/x(){}
''');
    await assertNoAssist();
  }

  test_multiLine() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
build() {
  return Container(
    child: Row(
      children: [/*caret*/
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

  test_multiLine_inListLiteral() async {
    verifyNoTestUnitErrors = false;
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
build() {
  return Container(
    child: Row(
      children: [/*caret*/
// start
        Transform(),
        Object(),
        AspectRatio(),
// end
      ],
    ),
  );
}
''');
    await assertNoAssist();
  }

  test_multiLines() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  main() {
    return Container(
      child: /*caret*/DefaultTextStyle(
        child: Row(
          children: <Widget>[
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
  main() {
    return Container(
      child: widget(
        child: DefaultTextStyle(
          child: Row(
            children: <Widget>[
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

  test_multiLines_eol2() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
class FakeFlutter {\r
  main() {\r
    return Container(\r
      child: /*caret*/DefaultTextStyle(\r
        child: Row(\r
          children: <Widget>[\r
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
import 'package:flutter/widgets.dart';
class FakeFlutter {\r
  main() {\r
    return Container(\r
      child: widget(\r
        child: DefaultTextStyle(\r
          child: Row(\r
            children: <Widget>[\r
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

  test_prefixedIdentifier_identifier() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';

abstract class Foo extends Widget {
  Widget bar;
}

main(Foo foo) {
  return foo./*caret*/bar;
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

abstract class Foo extends Widget {
  Widget bar;
}

main(Foo foo) {
  return widget(child: foo.bar);
}
''');
  }

  test_prefixedIdentifier_prefix() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';

abstract class Foo extends Widget {
  Widget bar;
}

main(Foo foo) {
  return /*caret*/foo.bar;
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

abstract class Foo extends Widget {
  Widget bar;
}

main(Foo foo) {
  return widget(child: foo.bar);
}
''');
  }

  test_singleLine() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  main() {
  var obj;
    return Row(children: [/*caret*/ Container()]);
  }
}
''');
    await assertNoAssist();
  }

  test_singleLine1() async {
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
    return widget(child: Container());
  }
}
''');
  }

  test_singleLine2() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  main() {
    return ClipRect./*caret*/rect();
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  main() {
    return widget(child: ClipRect.rect());
  }
}
''');
  }

  test_variable() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  main() {
    var container = Container();
    return /*caret*/container;
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  main() {
    var container = Container();
    return widget(child: container);
  }
}
''');
  }
}
