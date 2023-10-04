// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/ast/ast.dart';
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
  Flutter get _flutter => Flutter.instance;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  Future<void> test_getWidgetPresentationText_icon() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
var w = const Icon(Icons.book);
''');
    var w = _getTopVariableCreation('w');
    expect(_flutter.getWidgetPresentationText(w), 'Icon(Icons.book)');
  }

  Future<void> test_getWidgetPresentationText_icon_withoutArguments() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
import 'package:flutter/material.dart';
var w = const Icon();
''');
    var w = _getTopVariableCreation('w');
    expect(_flutter.getWidgetPresentationText(w), 'Icon');
  }

  Future<void> test_getWidgetPresentationText_notWidget() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
var w = Object();
''');
    var w = _getTopVariableCreation('w');
    expect(_flutter.getWidgetPresentationText(w), isNull);
  }

  Future<void> test_getWidgetPresentationText_text() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
var w = const Text('foo');
''');
    var w = _getTopVariableCreation('w');
    expect(_flutter.getWidgetPresentationText(w), "Text('foo')");
  }

  Future<void> test_getWidgetPresentationText_text_longText() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
var w = const Text('${'abc' * 100}');
''');
    var w = _getTopVariableCreation('w');
    expect(
      _flutter.getWidgetPresentationText(w),
      "Text('abcabcabcabcab...cabcabcabcabc')",
    );
  }

  Future<void> test_getWidgetPresentationText_text_withoutArguments() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
import 'package:flutter/material.dart';
var w = const Text();
''');
    var w = _getTopVariableCreation('w');
    expect(_flutter.getWidgetPresentationText(w), 'Text');
  }

  Future<void> test_getWidgetPresentationText_unresolved() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
import 'package:flutter/material.dart';
var w = new Foo();
''');
    var w = _getTopVariableCreation('w');
    expect(_flutter.getWidgetPresentationText(w), isNull);
  }

  Future<void> test_identifyWidgetExpression_node_instanceCreation() async {
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
      expect(_flutter.identifyWidgetExpression(creation), creation);
      expect(_flutter.identifyWidgetExpression(constructorName), creation);
      expect(_flutter.identifyWidgetExpression(namedType), creation);
      expect(_flutter.identifyWidgetExpression(argumentList), isNull);
      expect(
        _flutter.identifyWidgetExpression(argumentList.arguments[0]),
        isNull,
      );
    }

    // MyWidget.named(5678);
    {
      var statement = statements[1] as ExpressionStatement;
      var creation = statement.expression as InstanceCreationExpression;
      var constructorName = creation.constructorName;
      var namedType = constructorName.type;
      var argumentList = creation.argumentList;
      expect(_flutter.identifyWidgetExpression(creation), creation);
      expect(_flutter.identifyWidgetExpression(constructorName), creation);
      expect(_flutter.identifyWidgetExpression(namedType), creation);
      expect(_flutter.identifyWidgetExpression(constructorName.name), creation);
      expect(_flutter.identifyWidgetExpression(argumentList), isNull);
      expect(
        _flutter.identifyWidgetExpression(argumentList.arguments[0]),
        isNull,
      );
    }
  }

  Future<void> test_identifyWidgetExpression_node_invocation() async {
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
      expect(_flutter.identifyWidgetExpression(invocation), invocation);
      var argumentList = invocation.argumentList;
      expect(_flutter.identifyWidgetExpression(argumentList), isNull);
    }

    {
      var invocation = findNode.methodInvocation("createText('xyz');");
      expect(_flutter.identifyWidgetExpression(invocation), invocation);
      var argumentList = invocation.argumentList;
      expect(_flutter.identifyWidgetExpression(argumentList), isNull);
      expect(
        _flutter.identifyWidgetExpression(argumentList.arguments[0]),
        isNull,
      );
    }
  }

  Future<void> test_identifyWidgetExpression_node_namedExpression() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  Container(child: Text(''));
}

Text createEmptyText() => Text('');
''');
    var childExpression = findNode.namedExpression('child: ');
    expect(_flutter.identifyWidgetExpression(childExpression), isNull);
  }

  Future<void>
      test_identifyWidgetExpression_node_prefixedIdentifier_identifier() async {
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
    expect(_flutter.identifyWidgetExpression(bar), bar.parent);
  }

  Future<void>
      test_identifyWidgetExpression_node_prefixedIdentifier_prefix() async {
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
    expect(_flutter.identifyWidgetExpression(foo), foo.parent);
  }

  Future<void> test_identifyWidgetExpression_node_simpleIdentifier() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(Widget widget) {
  widget; // ref
}
''');
    var expression = findNode.simple('widget; // ref');
    expect(_flutter.identifyWidgetExpression(expression), expression);
  }

  Future<void> test_identifyWidgetExpression_node_switchExpression() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

Widget f() => switch (1) {
  _ => Container(),
};
''');
    var expression = findNode.instanceCreation('Container');
    expect(_flutter.identifyWidgetExpression(expression), expression);
  }

  Future<void> test_identifyWidgetExpression_null() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  var intVariable = 42;
  intVariable;
}

Text createEmptyText() => Text('');
''');
    expect(_flutter.identifyWidgetExpression(null), isNull);
    {
      var expression = findNode.integerLiteral('42;');
      expect(_flutter.identifyWidgetExpression(expression), isNull);
    }

    {
      var expression = findNode.simple('intVariable;');
      expect(_flutter.identifyWidgetExpression(expression), isNull);
    }
  }

  Future<void> test_identifyWidgetExpression_parent_argumentList() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  var text = Text('abc');
  useWidget(text); // ref
}

void useWidget(Widget w) {}
''');
    var expression = findNode.simple('text); // ref');
    expect(_flutter.identifyWidgetExpression(expression), expression);
  }

  Future<void>
      test_identifyWidgetExpression_parent_assignmentExpression() async {
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
      expect(_flutter.identifyWidgetExpression(expression), isNull);
    }

    // Left hand side.
    {
      var expression = findNode.assignment('text =');
      expect(_flutter.identifyWidgetExpression(expression), isNull);
    }

    // Right hand side.
    {
      var expression = findNode.instanceCreation('Text(');
      expect(_flutter.identifyWidgetExpression(expression), expression);
    }
  }

  Future<void>
      test_identifyWidgetExpression_parent_conditionalExpression() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(bool condition, Widget w1, Widget w2) {
  condition ? w1 : w2;
}
''');
    var thenWidget = findNode.simple('w1 :');
    expect(_flutter.identifyWidgetExpression(thenWidget), thenWidget);

    var elseWidget = findNode.simple('w2;');
    expect(_flutter.identifyWidgetExpression(elseWidget), elseWidget);
  }

  Future<void>
      test_identifyWidgetExpression_parent_expressionFunctionBody() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(Widget widget) => widget; // ref
''');
    var expression = findNode.simple('widget; // ref');
    expect(_flutter.identifyWidgetExpression(expression), expression);
  }

  Future<void>
      test_identifyWidgetExpression_parent_expressionStatement() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(Widget widget) {
  widget; // ref
}
''');
    var expression = findNode.simple('widget; // ref');
    expect(_flutter.identifyWidgetExpression(expression), expression);
  }

  Future<void> test_identifyWidgetExpression_parent_forElement() async {
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
    expect(_flutter.identifyWidgetExpression(expression), expression);
  }

  Future<void> test_identifyWidgetExpression_parent_ifElement() async {
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
    expect(_flutter.identifyWidgetExpression(thenExpression), thenExpression);

    var elseExpression = findNode.instanceCreation("Text('else')");
    expect(_flutter.identifyWidgetExpression(elseExpression), elseExpression);
  }

  Future<void> test_identifyWidgetExpression_parent_listLiteral() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

List<Widget> f(Widget widget) {
  return [widget]; // ref
}
''');
    var expression = findNode.simple('widget]; // ref');
    expect(_flutter.identifyWidgetExpression(expression), expression);
  }

  Future<void> test_identifyWidgetExpression_parent_namedExpression() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  var text = Text('abc');
  useWidget(child: text); // ref
}

void useWidget({required Widget child}) {}
''');
    var expression = findNode.simple('text); // ref');
    expect(_flutter.identifyWidgetExpression(expression), expression);
  }

  Future<void> test_identifyWidgetExpression_parent_returnStatement() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

Widget f(Widget widget) {
  return widget; // ref
}
''');
    var expression = findNode.simple('widget; // ref');
    expect(_flutter.identifyWidgetExpression(expression), expression);
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
    expect(_flutter.isWidget(myStatelessWidget), isTrue);

    var myStatefulWidget = testUnitElement.getClass('MyStatefulWidget');
    expect(_flutter.isWidget(myStatefulWidget), isTrue);

    var myContainer = testUnitElement.getClass('MyContainer');
    expect(_flutter.isWidget(myContainer), isTrue);

    var notFlutter = testUnitElement.getClass('NotFlutter');
    expect(_flutter.isWidget(notFlutter), isFalse);

    var notWidget = testUnitElement.getClass('NotWidget');
    expect(_flutter.isWidget(notWidget), isFalse);
  }

  Future<void> test_isWidgetCreation() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

var a = Object();
var b = Text('bbb');
''');
    expect(_flutter.isWidgetCreation(null), isFalse);

    var a = _getTopVariableCreation('a');
    expect(_flutter.isWidgetCreation(a), isFalse);

    var b = _getTopVariableCreation('b');
    expect(_flutter.isWidgetCreation(b), isTrue);
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
      expect(_flutter.isWidgetExpression(expression), isFalse);
      var creation = expression.parent?.parent as InstanceCreationExpression;
      expect(_flutter.isWidgetExpression(creation), isTrue);
    }

    {
      var expression = findNode.instanceCreation("Text('abc')");
      expect(_flutter.isWidgetExpression(expression), isTrue);
    }

    {
      var expression = findNode.simple('text;');
      expect(_flutter.isWidgetExpression(expression), isTrue);
    }

    {
      var expression = findNode.methodInvocation('createEmptyText();');
      expect(_flutter.isWidgetExpression(expression), isTrue);
    }

    {
      var expression = findNode.namedType('Container(');
      expect(_flutter.isWidgetExpression(expression), isFalse);
    }

    {
      var expression = findNode.namedExpression('child: ');
      expect(_flutter.isWidgetExpression(expression), isFalse);
    }

    {
      var expression = findNode.integerLiteral('42;');
      expect(_flutter.isWidgetExpression(expression), isFalse);
    }

    {
      var expression = findNode.simple('intVariable;');
      expect(_flutter.isWidgetExpression(expression), isFalse);
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
