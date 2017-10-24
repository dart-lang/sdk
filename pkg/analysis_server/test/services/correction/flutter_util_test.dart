// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/flutter_util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterUtilTest);
  });
}

@reflectiveTest
class FlutterUtilTest extends AbstractSingleUnitTest {
  @override
  void setUp() {
    super.setUp();
    _configureFlutterPackage();
  }

  test_isFlutterWidget() async {
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';

class MyStatelessWidget extends StatelessWidget {}
class MyStatefulWidget extends StatefulWidget {}
class MyContainer extends Container {}
class NotFlutter {}
class NotWidget extends State {}
''');
    var myStatelessWidget = testUnitElement.getType('MyStatelessWidget');
    expect(isFlutterWidget(myStatelessWidget), isTrue);

    var myStatefulWidget = testUnitElement.getType('MyStatefulWidget');
    expect(isFlutterWidget(myStatefulWidget), isTrue);

    var myContainer = testUnitElement.getType('MyContainer');
    expect(isFlutterWidget(myContainer), isTrue);

    var notFlutter = testUnitElement.getType('NotFlutter');
    expect(isFlutterWidget(notFlutter), isFalse);

    var notWidget = testUnitElement.getType('NotWidget');
    expect(isFlutterWidget(notWidget), isFalse);
  }

  test_isFlutterWidgetCreation() async {
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';

var a = new Object();
var b = new Text('bbb');
''');
    InstanceCreationExpression a = _getTopVariable('a').initializer;
    expect(isFlutterWidgetCreation(a), isFalse);

    InstanceCreationExpression b = _getTopVariable('b').initializer;
    expect(isFlutterWidgetCreation(b), isTrue);
  }

  void _configureFlutterPackage() {
    packageMap['flutter'] = [newFolder('/flutter/lib')];

    newFile('/flutter/lib/widgets.dart', r'''
export 'src/widgets/container.dart';
export 'src/widgets/framework.dart';
export 'src/widgets/text.dart';
''');

    newFile('/flutter/lib/src/widgets/container.dart', r'''
import 'framework.dart';

class Container extends StatelessWidget {
  final Widget child;
  Container({
    Key key,
    double width,
    double height,
    this.child,
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) => child;
}
''');

    newFile('/flutter/lib/src/widgets/framework.dart', r'''
typedef void VoidCallback();

abstract class BuildContext {
  Widget get widget;
}

abstract class Key {
  const factory Key(String value) = ValueKey<String>;

  const Key._();
}

abstract class LocalKey extends Key {
  const LocalKey() : super._();
}

abstract class State<T extends StatefulWidget> {
  BuildContext get context => null;

  T get widget => null;

  Widget build(BuildContext context) {}

  void dispose() {}

  void setState(VoidCallback fn) {}
}

abstract class StatefulWidget extends Widget {
  const StatefulWidget({Key key}) : super(key: key);

  State createState() => null
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget({Key key}) : super(key: key);

  Widget build(BuildContext context) => null;
}

class ValueKey<T> extends LocalKey {
  final T value;

  const ValueKey(this.value);
}

class Widget {
  final Key key;

  const Widget({this.key});
}
''');

    newFile('/flutter/lib/src/widgets/text.dart', r'''
import 'framework.dart';

class Text extends StatelessWidget {
  final String data;
  const Text(
    this.data, {
    Key key,
  })
      : super(key: key);
}
''');
  }

  VariableDeclaration _getTopVariable(String name, [CompilationUnit unit]) {
    unit ??= testUnit;
    for (var topDeclaration in unit.declarations) {
      if (topDeclaration is TopLevelVariableDeclaration) {
        for (var variable in topDeclaration.variables.variables) {
          if (variable.name.name == name) {
            return variable;
          }
        }
      }
    }
    fail('Not found $name in $unit');
    return null;
  }
}
