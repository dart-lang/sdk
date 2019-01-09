// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterWrapColumnTest);
  });
}

@reflectiveTest
class FlutterWrapColumnTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.FLUTTER_WRAP_COLUMN;

  test_coveredByWidget() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';

class FakeFlutter {
  main() {
    return new Container(
      child: new /*caret*/Text('aaa'),
    );
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

class FakeFlutter {
  main() {
    return new Container(
      child: Column(
        children: <Widget>[
          new /*caret*/Text('aaa'),
        ],
      ),
    );
  }
}
''');
  }

  test_coversWidgets() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';

class FakeFlutter {
  main() {
    return new Row(children: [
      new Text('aaa'),
// start
      new Text('bbb'),
      new Text('ccc'),
// end
      new Text('ddd'),
    ]);
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

class FakeFlutter {
  main() {
    return new Row(children: [
      new Text('aaa'),
// start
      Column(
        children: <Widget>[
          new Text('bbb'),
          new Text('ccc'),
        ],
      ),
// end
      new Text('ddd'),
    ]);
  }
}
''');
  }
}
