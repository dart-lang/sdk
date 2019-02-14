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
  return new Container(
    child: new Row(
// start
      children: [/*caret*/
        new Text('111'),
        new Text('222'),
        new Container(),
      ],
// end
    ),
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
build() {
  return new Container(
    child: new Row(
// start
      children: [
        new widget(
          children: [/*caret*/
            new Text('111'),
            new Text('222'),
            new Container(),
          ],
        ),
      ],
// end
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
  return new Container(
    child: new Row(
      children: [/*caret*/
// start
        new Transform(),
        new Object(),
        new AspectRatio(),
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
    return new Container(
// start
      child: new /*caret*/DefaultTextStyle(
        child: new Row(
          children: <Widget>[
            new Container(
            ),
          ],
        ),
      ),
// end
    );
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  main() {
    return new Container(
// start
      child: widget(
        child: new /*caret*/DefaultTextStyle(
          child: new Row(
            children: <Widget>[
              new Container(
              ),
            ],
          ),
        ),
      ),
// end
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
    return new Container(\r
// start\r
      child: new /*caret*/DefaultTextStyle(\r
        child: new Row(\r
          children: <Widget>[\r
            new Container(\r
            ),\r
          ],\r
        ),\r
      ),\r
// end\r
    );\r
  }\r
}\r
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {\r
  main() {\r
    return new Container(\r
// start\r
      child: widget(\r
        child: new /*caret*/DefaultTextStyle(\r
          child: new Row(\r
            children: <Widget>[\r
              new Container(\r
              ),\r
            ],\r
          ),\r
        ),\r
      ),\r
// end\r
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
  return widget(child: foo./*caret*/bar);
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
  return /*caret*/widget(child: foo.bar);
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
// start
    return new Row(children: [/*caret*/ new Container()]);
// end
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
// start
    return /*caret*/new Container();
// end
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  main() {
// start
    return /*caret*/widget(child: new Container());
// end
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
    return new ClipRect./*caret*/rect();
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  main() {
    return widget(child: new ClipRect./*caret*/rect());
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
    var container = new Container();
    return /*caret*/container;
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
class FakeFlutter {
  main() {
    var container = new Container();
    return /*caret*/widget(child: container);
  }
}
''');
  }
}
