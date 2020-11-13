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
var w = new Object();
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

main() {
  new MyWidget(1234);
  new MyWidget.named(5678);
}

class MyWidget extends StatelessWidget {
  MyWidget(int a);
  MyWidget.named(int a);
  Widget build(BuildContext context) => null;
}
''');
    FunctionDeclaration main = testUnit.declarations[0];
    BlockFunctionBody body = main.functionExpression.body;
    List<Statement> statements = body.block.statements;

    // new MyWidget(1234);
    {
      ExpressionStatement statement = statements[0];
      InstanceCreationExpression creation = statement.expression;
      var constructorName = creation.constructorName;
      var typeName = constructorName.type;
      var argumentList = creation.argumentList;
      expect(_flutter.identifyWidgetExpression(creation), creation);
      expect(_flutter.identifyWidgetExpression(constructorName), creation);
      expect(_flutter.identifyWidgetExpression(typeName), creation);
      expect(_flutter.identifyWidgetExpression(argumentList), isNull);
      expect(
        _flutter.identifyWidgetExpression(argumentList.arguments[0]),
        isNull,
      );
    }

    // new MyWidget.named(5678);
    {
      ExpressionStatement statement = statements[1];
      InstanceCreationExpression creation = statement.expression;
      var constructorName = creation.constructorName;
      var typeName = constructorName.type;
      var argumentList = creation.argumentList;
      expect(_flutter.identifyWidgetExpression(creation), creation);
      expect(_flutter.identifyWidgetExpression(constructorName), creation);
      expect(_flutter.identifyWidgetExpression(typeName), creation);
      expect(_flutter.identifyWidgetExpression(typeName.name), creation);
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

main() {
  createEmptyText();
  createText('xyz');
}

Text createEmptyText() => new Text('');
Text createText(String txt) => new Text(txt);
''');
    {
      MethodInvocation invocation = findNodeAtString(
          'createEmptyText();', (node) => node is MethodInvocation);
      expect(_flutter.identifyWidgetExpression(invocation), invocation);
      var argumentList = invocation.argumentList;
      expect(_flutter.identifyWidgetExpression(argumentList), isNull);
    }

    {
      MethodInvocation invocation = findNodeAtString(
          "createText('xyz');", (node) => node is MethodInvocation);
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

main() {
  new Container(child: new Text(''));
}

Text createEmptyText() => new Text('');
''');
    Expression childExpression = findNodeAtString('child: ');
    expect(_flutter.identifyWidgetExpression(childExpression), isNull);
  }

  Future<void>
      test_identifyWidgetExpression_node_prefixedIdentifier_identifier() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

abstract class Foo extends Widget {
  Widget bar;
}

main(Foo foo) {
  foo.bar; // ref
}
''');
    SimpleIdentifier bar = findNodeAtString('bar; // ref');
    expect(_flutter.identifyWidgetExpression(bar), bar.parent);
  }

  Future<void>
      test_identifyWidgetExpression_node_prefixedIdentifier_prefix() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

abstract class Foo extends Widget {
  Widget bar;
}

main(Foo foo) {
  foo.bar; // ref
}
''');
    SimpleIdentifier foo = findNodeAtString('foo.bar');
    expect(_flutter.identifyWidgetExpression(foo), foo.parent);
  }

  Future<void> test_identifyWidgetExpression_node_simpleIdentifier() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

main(Widget widget) {
  widget; // ref
}
''');
    Expression expression = findNodeAtString('widget; // ref');
    expect(_flutter.identifyWidgetExpression(expression), expression);
  }

  Future<void> test_identifyWidgetExpression_null() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

main() {
  var intVariable = 42;
  intVariable;
}

Text createEmptyText() => new Text('');
''');
    expect(_flutter.identifyWidgetExpression(null), isNull);
    {
      Expression expression = findNodeAtString('42;');
      expect(_flutter.identifyWidgetExpression(expression), isNull);
    }

    {
      Expression expression = findNodeAtString('intVariable;');
      expect(_flutter.identifyWidgetExpression(expression), isNull);
    }
  }

  Future<void> test_identifyWidgetExpression_parent_argumentList() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

main() {
  var text = new Text('abc');
  useWidget(text); // ref
}

void useWidget(Widget w) {}
''');
    Expression expression = findNodeAtString('text); // ref');
    expect(_flutter.identifyWidgetExpression(expression), expression);
  }

  Future<void>
      test_identifyWidgetExpression_parent_assignmentExpression() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

main() {
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

main(bool condition, Widget w1, Widget w2) {
  condition ? w1 : w2;
}
''');
    Expression thenWidget = findNodeAtString('w1 :');
    expect(_flutter.identifyWidgetExpression(thenWidget), thenWidget);

    Expression elseWidget = findNodeAtString('w2;');
    expect(_flutter.identifyWidgetExpression(elseWidget), elseWidget);
  }

  Future<void>
      test_identifyWidgetExpression_parent_expressionFunctionBody() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

main(Widget widget) => widget; // ref
''');
    Expression expression = findNodeAtString('widget; // ref');
    expect(_flutter.identifyWidgetExpression(expression), expression);
  }

  Future<void>
      test_identifyWidgetExpression_parent_expressionStatement() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

main(Widget widget) {
  widget; // ref
}
''');
    Expression expression = findNodeAtString('widget; // ref');
    expect(_flutter.identifyWidgetExpression(expression), expression);
  }

  Future<void> test_identifyWidgetExpression_parent_forElement() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

main(bool b) {
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

main(bool b) {
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

main(Widget widget) {
  return [widget]; // ref
}
''');
    Expression expression = findNodeAtString('widget]; // ref');
    expect(_flutter.identifyWidgetExpression(expression), expression);
  }

  Future<void> test_identifyWidgetExpression_parent_namedExpression() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

main() {
  var text = new Text('abc');
  useWidget(child: text); // ref
}

void useWidget({Widget child}) {}
''');
    Expression expression = findNodeAtString('text); // ref');
    expect(_flutter.identifyWidgetExpression(expression), expression);
  }

  Future<void> test_identifyWidgetExpression_parent_returnStatement() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

main(Widget widget) {
  return widget; // ref
}
''');
    Expression expression = findNodeAtString('widget; // ref');
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
    var myStatelessWidget = testUnitElement.getType('MyStatelessWidget');
    expect(_flutter.isWidget(myStatelessWidget), isTrue);

    var myStatefulWidget = testUnitElement.getType('MyStatefulWidget');
    expect(_flutter.isWidget(myStatefulWidget), isTrue);

    var myContainer = testUnitElement.getType('MyContainer');
    expect(_flutter.isWidget(myContainer), isTrue);

    var notFlutter = testUnitElement.getType('NotFlutter');
    expect(_flutter.isWidget(notFlutter), isFalse);

    var notWidget = testUnitElement.getType('NotWidget');
    expect(_flutter.isWidget(notWidget), isFalse);
  }

  Future<void> test_isWidgetCreation() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

var a = new Object();
var b = new Text('bbb');
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

main() {
  MyWidget.named(); // use
  var text = new Text('abc');
  text;
  createEmptyText();
  new Container(child: text);
  var intVariable = 42;
  intVariable;
}

class MyWidget extends StatelessWidget {
  MyWidget.named();
}

Text createEmptyText() => new Text('');
''');
    {
      Expression expression = findNodeAtString('named(); // use');
      expect(_flutter.isWidgetExpression(expression), isFalse);
      var creation = expression.parent.parent as InstanceCreationExpression;
      expect(_flutter.isWidgetExpression(creation), isTrue);
    }

    {
      Expression expression = findNodeAtString("new Text('abc')");
      expect(_flutter.isWidgetExpression(expression), isTrue);
    }

    {
      Expression expression = findNodeAtString('text;');
      expect(_flutter.isWidgetExpression(expression), isTrue);
    }

    {
      Expression expression = findNodeAtString(
          'createEmptyText();', (node) => node is MethodInvocation);
      expect(_flutter.isWidgetExpression(expression), isTrue);
    }

    {
      SimpleIdentifier expression = findNodeAtString('Container(');
      expect(_flutter.isWidgetExpression(expression), isFalse);
    }

    {
      NamedExpression expression =
          findNodeAtString('child: ', (n) => n is NamedExpression);
      expect(_flutter.isWidgetExpression(expression), isFalse);
    }

    {
      Expression expression = findNodeAtString('42;');
      expect(_flutter.isWidgetExpression(expression), isFalse);
    }

    {
      Expression expression = findNodeAtString('intVariable;');
      expect(_flutter.isWidgetExpression(expression), isFalse);
    }
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
  }

  InstanceCreationExpression _getTopVariableCreation(String name,
      [CompilationUnit unit]) {
    return _getTopVariable(name, unit).initializer
        as InstanceCreationExpression;
  }
}
