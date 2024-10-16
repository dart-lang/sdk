// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterTest);
  });
}

@reflectiveTest
class FlutterTest extends AbstractSingleUnitTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  Future<void> test_enclosingWidgetExpression_node_instanceCreation() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  MyWidget(1234);
  MyWidget.named(5678);
}

class MyWidget extends StatelessWidget {
  MyWidget(int a);
  MyWidget.named(int a);
  Widget build(BuildContext context) => Text('');
}
''');
    var f = testUnit.declarations[0] as FunctionDeclaration;
    var body = f.functionExpression.body as BlockFunctionBody;
    var statements = body.block.statements;

    // MyWidget(1234);
    {
      var statement = statements[0] as ExpressionStatement;
      var creation = statement.expression as InstanceCreationExpression;
      var constructorName = creation.constructorName;
      var namedType = constructorName.type;
      var argumentList = creation.argumentList;
      expect(creation.findWidgetExpression, creation);
      expect(constructorName.findWidgetExpression, creation);
      expect(namedType.findWidgetExpression, creation);
      expect(argumentList.findWidgetExpression, isNull);
      expect(argumentList.arguments[0].findWidgetExpression, isNull);
    }

    // MyWidget.named(5678);
    {
      var statement = statements[1] as ExpressionStatement;
      var creation = statement.expression as InstanceCreationExpression;
      var constructorName = creation.constructorName;
      var namedType = constructorName.type;
      var argumentList = creation.argumentList;
      expect(creation.findWidgetExpression, creation);
      expect(constructorName.findWidgetExpression, creation);
      expect(namedType.findWidgetExpression, creation);
      expect(constructorName.name.findWidgetExpression, creation);
      expect(argumentList.findWidgetExpression, isNull);
      expect(argumentList.arguments[0].findWidgetExpression, isNull);
    }
  }

  Future<void> test_enclosingWidgetExpression_node_invocation() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  createEmptyText();
  createText('xyz');
}

Text createEmptyText() => Text('');
Text createText(String txt) => Text(txt);
''');
    {
      var invocation = findNode.methodInvocation('createEmptyText();');
      expect(invocation.findWidgetExpression, invocation);
      var argumentList = invocation.argumentList;
      expect(argumentList.findWidgetExpression, isNull);
    }

    {
      var invocation = findNode.methodInvocation("createText('xyz');");
      expect(invocation.findWidgetExpression, invocation);
      var argumentList = invocation.argumentList;
      expect(argumentList.findWidgetExpression, isNull);
      expect(argumentList.arguments[0].findWidgetExpression, isNull);
    }
  }

  Future<void> test_enclosingWidgetExpression_node_namedExpression() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  Container(child: Text(''));
}

Text createEmptyText() => Text('');
''');
    var childExpression = findNode.namedExpression('child: ');
    expect(childExpression.findWidgetExpression, isNull);
  }

  Future<void>
      test_enclosingWidgetExpression_node_prefixedIdentifier_identifier() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

abstract class Foo extends Widget {
  Widget bar;

  Foo(this.bar);
}

void f(Foo foo) {
  foo.bar; // ref
}
''');
    var bar = findNode.simple('bar; // ref');
    expect(bar.findWidgetExpression, bar.parent);
  }

  Future<void>
      test_enclosingWidgetExpression_node_prefixedIdentifier_prefix() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

abstract class Foo extends Widget {
  Widget bar;

  Foo(this.bar);
}

void f(Foo foo) {
  foo.bar; // ref
}
''');
    var foo = findNode.simple('foo.bar');
    expect(foo.findWidgetExpression, foo.parent);
  }

  Future<void> test_enclosingWidgetExpression_node_simpleIdentifier() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(Widget widget) {
  widget; // ref
}
''');
    var expression = findNode.simple('widget; // ref');
    expect(expression.findWidgetExpression, expression);
  }

  Future<void> test_enclosingWidgetExpression_node_switchExpression() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

Widget f() => switch (1) {
  _ => Container(),
};
''');
    var expression = findNode.instanceCreation('Container');
    expect(expression.findWidgetExpression, expression);
  }

  Future<void> test_enclosingWidgetExpression_null() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  var intVariable = 42;
  intVariable;
}

Text createEmptyText() => Text('');
''');
    expect(null.findWidgetExpression, isNull);
    {
      var expression = findNode.integerLiteral('42;');
      expect(expression.findWidgetExpression, isNull);
    }

    {
      var expression = findNode.simple('intVariable;');
      expect(expression.findWidgetExpression, isNull);
    }
  }

  Future<void> test_enclosingWidgetExpression_parent_argumentList() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  var text = Text('abc');
  useWidget(text); // ref
}

void useWidget(Widget w) {}
''');
    var expression = findNode.simple('text); // ref');
    expect(expression.findWidgetExpression, expression);
  }

  Future<void>
      test_enclosingWidgetExpression_parent_assignmentExpression() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  Widget text;
  text = Text('abc');
}

void useWidget(Widget w) {}
''');
    // Assignment itself.
    {
      var expression = findNode.simple('text =');
      expect(expression.findWidgetExpression, isNull);
    }

    // Left hand side.
    {
      var expression = findNode.assignment('text =');
      expect(expression.findWidgetExpression, isNull);
    }

    // Right hand side.
    {
      var expression = findNode.instanceCreation('Text(');
      expect(expression.findWidgetExpression, expression);
    }
  }

  Future<void>
      test_enclosingWidgetExpression_parent_conditionalExpression() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(bool condition, Widget w1, Widget w2) {
  condition ? w1 : w2;
}
''');
    var thenWidget = findNode.simple('w1 :');
    expect(thenWidget.findWidgetExpression, thenWidget);

    var elseWidget = findNode.simple('w2;');
    expect(elseWidget.findWidgetExpression, elseWidget);
  }

  Future<void>
      test_enclosingWidgetExpression_parent_expressionFunctionBody() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(Widget widget) => widget; // ref
''');
    var expression = findNode.simple('widget; // ref');
    expect(expression.findWidgetExpression, expression);
  }

  Future<void>
      test_enclosingWidgetExpression_parent_expressionStatement() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(Widget widget) {
  widget; // ref
}
''');
    var expression = findNode.simple('widget; // ref');
    expect(expression.findWidgetExpression, expression);
  }

  Future<void> test_enclosingWidgetExpression_parent_forElement() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(bool b) {
  [
    for (var v in [0, 1, 2]) Container()
  ];
}

void useWidget(Widget w) {}
''');
    var expression = findNode.instanceCreation('Container()');
    expect(expression.findWidgetExpression, expression);
  }

  Future<void> test_enclosingWidgetExpression_parent_ifElement() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(bool b) {
  [
    if (b)
      Text('then')
    else
      Text('else')
  ];
}

void useWidget(Widget w) {}
''');
    var thenExpression = findNode.instanceCreation("Text('then')");
    expect(thenExpression.findWidgetExpression, thenExpression);

    var elseExpression = findNode.instanceCreation("Text('else')");
    expect(elseExpression.findWidgetExpression, elseExpression);
  }

  Future<void> test_enclosingWidgetExpression_parent_listLiteral() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

List<Widget> f(Widget widget) {
  return [widget]; // ref
}
''');
    var expression = findNode.simple('widget]; // ref');
    expect(expression.findWidgetExpression, expression);
  }

  Future<void> test_enclosingWidgetExpression_parent_namedExpression() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  var text = Text('abc');
  useWidget(child: text); // ref
}

void useWidget({required Widget child}) {}
''');
    var expression = findNode.simple('text); // ref');
    expect(expression.findWidgetExpression, expression);
  }

  Future<void> test_enclosingWidgetExpression_parent_returnStatement() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

Widget f(Widget widget) {
  return widget; // ref
}
''');
    var expression = findNode.simple('widget; // ref');
    expect(expression.findWidgetExpression, expression);
  }

  Future<void> test_getWidgetPresentationText_icon() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
var w = const Icon(Icons.book);
''');
    var widget = _getTopVariableCreation('w');
    expect(widget.widgetPresentationText, 'Icon(Icons.book)');
  }

  Future<void> test_getWidgetPresentationText_icon_withoutArguments() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
import 'package:flutter/material.dart';
var w = const Icon();
''');
    var widget = _getTopVariableCreation('w');
    expect(widget.widgetPresentationText, 'Icon');
  }

  Future<void> test_getWidgetPresentationText_notWidget() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
var w = Object();
''');
    var widget = _getTopVariableCreation('w');
    expect(widget.widgetPresentationText, isNull);
  }

  Future<void> test_getWidgetPresentationText_text() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
var w = const Text('foo');
''');
    var widget = _getTopVariableCreation('w');
    expect(widget.widgetPresentationText, "Text('foo')");
  }

  Future<void> test_getWidgetPresentationText_text_longText() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
var w = const Text('${'abc' * 100}');
''');
    var widget = _getTopVariableCreation('w');
    expect(
      widget.widgetPresentationText,
      "Text('abcabcabcabcab...cabcabcabcabc')",
    );
  }

  Future<void> test_getWidgetPresentationText_text_withoutArguments() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
import 'package:flutter/material.dart';
var w = const Text();
''');
    var widget = _getTopVariableCreation('w');
    expect(widget.widgetPresentationText, 'Text');
  }

  Future<void> test_getWidgetPresentationText_unresolved() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
import 'package:flutter/material.dart';
var w = new Foo();
''');
    var widget = _getTopVariableCreation('w');
    expect(widget.widgetPresentationText, isNull);
  }

  Future<void> test_isWidget() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyStatelessWidget extends StatelessWidget {}
class MyStatefulWidget extends StatefulWidget {}
class MyContainer extends Container {}
class NotFlutter {}
class NotWidget extends State {}
''');
    var myStatelessWidget = testUnitElement.getClass('MyStatelessWidget');
    expect(myStatelessWidget.isWidget, isTrue);

    var myStatefulWidget = testUnitElement.getClass('MyStatefulWidget');
    expect(myStatefulWidget.isWidget, isTrue);

    var myContainer = testUnitElement.getClass('MyContainer');
    expect(myContainer.isWidget, isTrue);

    var notFlutter = testUnitElement.getClass('NotFlutter');
    expect(notFlutter.isWidget, isFalse);

    var notWidget = testUnitElement.getClass('NotWidget');
    expect(notWidget.isWidget, isFalse);
  }

  Future<void> test_isWidgetCreation() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

var a = Object();
var b = Text('bbb');
''');

    var a = _getTopVariableCreation('a');
    expect(a.isWidgetCreation, isFalse);

    var b = _getTopVariableCreation('b');
    expect(b.isWidgetCreation, isTrue);
  }

  Future<void> test_isWidgetExpression() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  MyWidget.named(); // use
  var text = Text('abc');
  text;
  createEmptyText();
  Container(child: text);
  var intVariable = 42;
  intVariable;
}

class MyWidget extends StatelessWidget {
  MyWidget.named();
}

Text createEmptyText() => new Text('');
''');
    {
      var expression = findNode.simple('named(); // use');
      expect(expression.isWidgetExpression, isFalse);
      var creation = expression.parent?.parent as InstanceCreationExpression;
      expect(creation.isWidgetExpression, isTrue);
    }

    {
      var expression = findNode.instanceCreation("Text('abc')");
      expect(expression.isWidgetExpression, isTrue);
    }

    {
      var expression = findNode.simple('text;');
      expect(expression.isWidgetExpression, isTrue);
    }

    {
      var expression = findNode.methodInvocation('createEmptyText();');
      expect(expression.isWidgetExpression, isTrue);
    }

    {
      var expression = findNode.namedType('Container(');
      expect(expression.isWidgetExpression, isFalse);
    }

    {
      var expression = findNode.namedExpression('child: ');
      expect(expression.isWidgetExpression, isFalse);
    }

    {
      var expression = findNode.integerLiteral('42;');
      expect(expression.isWidgetExpression, isFalse);
    }

    {
      var expression = findNode.simple('intVariable;');
      expect(expression.isWidgetExpression, isFalse);
    }
  }

  VariableDeclaration _getTopVariable(String name, [CompilationUnit? unit]) {
    unit ??= testUnit;
    for (var topDeclaration in unit.declarations) {
      if (topDeclaration is TopLevelVariableDeclaration) {
        for (var variable in topDeclaration.variables.variables) {
          if (variable.name.lexeme == name) {
            return variable;
          }
        }
      }
    }
    fail('Not found $name in $unit');
  }

  InstanceCreationExpression _getTopVariableCreation(String name,
      [CompilationUnit? unit]) {
    return _getTopVariable(name, unit).initializer
        as InstanceCreationExpression;
  }
}
