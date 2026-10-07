// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_testing/src/single_unit.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../find_element.dart';
import '../../find_node.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterTest);
    defineReflectiveTests(FlutterV2Test);
  });
}

@reflectiveTest
class FlutterTest extends SingleUnitTest with FindElementMixin, FindNodeMixin {
  @override
  bool get addFlutterPackageDep => true;

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
    var childExpression = findNode.namedArgument('child: ');
    expect(childExpression.findWidgetExpression, isNull);
  }

  Future<void>
  test_enclosingWidgetExpression_node_prefixedIdentifier_identifier() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

abstract class Foo extends Widget {
  final Widget bar;

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
  final Widget bar;

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
abstract class MyStatefulWidget extends StatefulWidget {}
class MyContainer extends Container {}
class NotFlutter {}
abstract class NotWidget extends State {}
''');

    var myStatelessWidget = findElement.class_('MyStatelessWidget');
    expect(myStatelessWidget.isWidget, isTrue);

    var myStatefulWidget = findElement.class_('MyStatefulWidget');
    expect(myStatefulWidget.isWidget, isTrue);

    var myContainer = findElement.class_('MyContainer');
    expect(myContainer.isWidget, isTrue);

    var notFlutter = findElement.class_('NotFlutter');
    expect(notFlutter.isWidget, isFalse);

    var notWidget = findElement.class_('NotWidget');
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
      var expression = findNode.namedArgument('child: ');
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

  InstanceCreationExpression _getTopVariableCreation(
    String name, [
    CompilationUnit? unit,
  ]) {
    return _getTopVariable(name, unit).initializer
        as InstanceCreationExpression;
  }
}

/// Tests for the V2 AST helpers in `AstNodeExtension2`.
@reflectiveTest
class FlutterV2Test extends SingleUnitTest {
  @override
  bool get addFlutterPackageDep => true;

  FindNode2 get findNode => FindNode2(testCode, testUnit);

  Future<void> test_findArgumentNamed2() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  Container(child: Text(''));
  g(child: 0);
}

void g({required int child}) {}
''');
    {
      var argument = findNode.namedArgument('child: Text');
      expect(argument.findArgumentNamed2('child'), argument);
      expect(argument.findArgumentNamed2('other'), isNull);

      var value = findNode.constructorInvocation("Text('')");
      expect(value.findArgumentNamed2('child'), argument);
      expect(value.argumentList.findArgumentNamed2('child'), isNull);
    }

    // Not a widget creation.
    {
      var argument = findNode.namedArgument('child: 0');
      expect(argument.findArgumentNamed2('child'), isNull);
    }

    expect(null.findArgumentNamed2('child'), isNull);
  }

  Future<void> test_findConstructorInvocation() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A();
  A.named();
}
''');
    await resolveTestCode('''
import 'a.dart' as prefix;

void f() {
  prefix.A.named();
}
''');
    var invocation = findNode.singleConstructorInvocation;
    var constructorReference = invocation.constructorReference;
    var typeReference = constructorReference.typeReference;
    expect(invocation.findConstructorInvocation, invocation);
    expect(constructorReference.findConstructorInvocation, invocation);
    expect(typeReference.findConstructorInvocation, invocation);
    expect(typeReference.importPrefix.findConstructorInvocation, invocation);
    expect(constructorReference.selector.findConstructorInvocation, invocation);
    expect(invocation.argumentList.findConstructorInvocation, isNull);
    expect(null.findConstructorInvocation, isNull);
  }

  Future<void> test_findWidgetExpression2_node_constructorInvocation() async {
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
    {
      var invocation = findNode.constructorInvocation('MyWidget(1234)');
      var constructorReference = invocation.constructorReference;
      var argumentList = invocation.argumentList;
      expect(invocation.findWidgetExpression2, invocation);
      expect(constructorReference.findWidgetExpression2, invocation);
      expect(
        constructorReference.typeReference.findWidgetExpression2,
        invocation,
      );
      expect(argumentList.findWidgetExpression2, isNull);
      expect(findNode.integerLiteral('1234').findWidgetExpression2, isNull);
    }

    {
      var invocation = findNode.constructorInvocation('MyWidget.named(5678)');
      var constructorReference = invocation.constructorReference;
      var argumentList = invocation.argumentList;
      expect(invocation.findWidgetExpression2, invocation);
      expect(constructorReference.findWidgetExpression2, invocation);
      expect(
        constructorReference.typeReference.findWidgetExpression2,
        invocation,
      );
      expect(constructorReference.selector.findWidgetExpression2, invocation);
      expect(argumentList.findWidgetExpression2, isNull);
      expect(findNode.integerLiteral('5678').findWidgetExpression2, isNull);
    }
  }

  Future<void> test_findWidgetExpression2_node_namedArgument() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  Container(child: Text(''));
}
''');
    var argument = findNode.singleNamedArgument;
    expect(argument.findWidgetExpression2, isNull);
  }

  Future<void>
  test_findWidgetExpression2_node_receiverPropertyExtraction() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

abstract class Foo extends Widget {
  final Widget bar;

  Foo(this.bar);
}

void f(Foo foo) {
  foo.bar;
}
''');
    var extraction = findNode.singleReceiverPropertyExtraction;
    expect(extraction.findWidgetExpression2, extraction);
    expect(extraction.receiver.findWidgetExpression2, extraction);
  }

  Future<void>
  test_findWidgetExpression2_node_unqualifiedFunctionInvocation() async {
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
      var invocation = findNode.unqualifiedFunctionInvocation(
        'createEmptyText();',
      );
      expect(invocation.findWidgetExpression2, invocation);
      expect(invocation.argumentList.findWidgetExpression2, isNull);
    }

    {
      var invocation = findNode.unqualifiedFunctionInvocation(
        "createText('xyz');",
      );
      var argumentList = invocation.argumentList;
      expect(invocation.findWidgetExpression2, invocation);
      expect(argumentList.findWidgetExpression2, isNull);
      expect(
        findNode.simpleStringLiteral("'xyz'").findWidgetExpression2,
        isNull,
      );
    }
  }

  Future<void>
  test_findWidgetExpression2_node_unqualifiedNameExpression() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(Widget widget) {
  widget;
}
''');
    var expression = findNode.singleUnqualifiedNameExpression;
    expect(expression.findWidgetExpression2, expression);
  }

  Future<void> test_findWidgetExpression2_null() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  var intVariable = 42;
  intVariable;
}
''');
    expect(null.findWidgetExpression2, isNull);
    expect(findNode.singleIntegerLiteral.findWidgetExpression2, isNull);
    expect(
      findNode.singleUnqualifiedNameExpression.findWidgetExpression2,
      isNull,
    );
  }

  Future<void> test_findWidgetExpression2_parent_argumentList() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(Widget text) {
  useWidget(text);
}

void useWidget(Widget w) {}
''');
    var expression = findNode.singleUnqualifiedNameExpression;
    expect(expression.findWidgetExpression2, expression);
  }

  Future<void> test_findWidgetExpression2_parent_conditionalExpression() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(bool condition, Widget w1, Widget w2) {
  condition ? w1 : w2;
}
''');
    var thenWidget = findNode.unqualifiedNameExpression('w1 :');
    expect(thenWidget.findWidgetExpression2, thenWidget);

    var elseWidget = findNode.unqualifiedNameExpression('w2;');
    expect(elseWidget.findWidgetExpression2, elseWidget);
  }

  Future<void> test_findWidgetExpression2_parent_directAssignment() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  Widget text;
  text = Text('abc');
}
''');
    var assignment = findNode.singleDirectAssignment;
    expect(assignment.findWidgetExpression2, isNull);
    expect(assignment.target.findWidgetExpression2, isNull);

    var value = findNode.singleConstructorInvocation;
    expect(value.findWidgetExpression2, value);
  }

  Future<void>
  test_findWidgetExpression2_parent_directAssignment_inArgumentList() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(Widget text) {
  useWidget(text = Text('abc'));
}

void useWidget(Widget w) {}
''');
    var assignment = findNode.singleDirectAssignment;
    expect(assignment.findWidgetExpression2, isNull);
    expect(assignment.target.findWidgetExpression2, isNull);

    var value = findNode.singleConstructorInvocation;
    expect(value.findWidgetExpression2, value);
  }

  Future<void>
  test_findWidgetExpression2_parent_directAssignment_widgetReceiver() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

abstract class Holder extends Widget {
  set child(Widget value);
}

void f(Holder holder) {
  holder.child = Text('');
}
''');
    var assignment = findNode.singleDirectAssignment;
    var target = assignment.target;
    expect(target.findWidgetExpression2, isNull);

    // The receiver is a widget expression, but it is part of the target.
    var receiver = findNode.singleUnqualifiedNameExpression;
    expect(receiver.isWidgetExpression2, isTrue);
    expect(receiver.findWidgetExpression2, isNull);

    var value = findNode.singleConstructorInvocation;
    expect(value.findWidgetExpression2, value);
  }

  Future<void>
  test_findWidgetExpression2_parent_expressionFunctionBody() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(Widget widget) => widget;
''');
    var expression = findNode.singleUnqualifiedNameExpression;
    expect(expression.findWidgetExpression2, expression);
  }

  Future<void> test_findWidgetExpression2_parent_forElement() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  [
    for (var v in [0, 1, 2]) Container()
  ];
}
''');
    var expression = findNode.singleConstructorInvocation;
    expect(expression.findWidgetExpression2, expression);
  }

  Future<void> test_findWidgetExpression2_parent_ifElement() async {
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
''');
    var thenExpression = findNode.constructorInvocation("Text('then')");
    expect(thenExpression.findWidgetExpression2, thenExpression);

    var elseExpression = findNode.constructorInvocation("Text('else')");
    expect(elseExpression.findWidgetExpression2, elseExpression);
  }

  Future<void> test_findWidgetExpression2_parent_ifNullAssignment() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(Widget? text) {
  text ??= Text('abc');
}
''');
    var assignment = findNode.singleIfNullAssignment;
    expect(assignment.findWidgetExpression2, isNull);
    expect(assignment.target.findWidgetExpression2, isNull);

    var value = findNode.singleConstructorInvocation;
    expect(value.findWidgetExpression2, value);
  }

  Future<void> test_findWidgetExpression2_parent_listLiteral() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

List<Widget> f(Widget widget) {
  return [widget];
}
''');
    var expression = findNode.singleUnqualifiedNameExpression;
    expect(expression.findWidgetExpression2, expression);
  }

  Future<void> test_findWidgetExpression2_parent_namedArgument() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(Widget text) {
  useWidget(child: text);
}

void useWidget({required Widget child}) {}
''');
    var expression = findNode.singleUnqualifiedNameExpression;
    expect(expression.findWidgetExpression2, expression);
  }

  Future<void> test_findWidgetExpression2_parent_returnStatement() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

Widget f(Widget widget) {
  return widget;
}
''');
    var expression = findNode.singleUnqualifiedNameExpression;
    expect(expression.findWidgetExpression2, expression);
  }

  Future<void> test_findWidgetExpression2_parent_switchExpressionCase() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

Widget f() => switch (1) {
  _ => Container(),
};
''');
    var expression = findNode.singleConstructorInvocation;
    expect(expression.findWidgetExpression2, expression);
  }

  Future<void> test_findWidgetExpression2_parent_variableDeclaration() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f() {
  var text = Text('abc');
}
''');
    var expression = findNode.singleConstructorInvocation;
    expect(expression.findWidgetExpression2, expression);
  }

  Future<void> test_isWidgetExpression2() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

void f(Widget text) {
  MyWidget.named(); // use
  Text('abc');
  text;
  createEmptyText();
  Container(child: text);
  var intVariable = 42;
  intVariable;
}

class MyWidget extends StatelessWidget {
  MyWidget.named();
}

Text createEmptyText() => Text('');
''');
    expect(null.isWidgetExpression2, isFalse);

    {
      var invocation = findNode.constructorInvocation(
        'MyWidget.named(); // use',
      );
      var constructorReference = invocation.constructorReference;
      expect(invocation.isWidgetExpression2, isTrue);
      expect(constructorReference.isWidgetExpression2, isFalse);
      expect(constructorReference.typeReference.isWidgetExpression2, isFalse);
      expect(constructorReference.selector.isWidgetExpression2, isFalse);
    }

    {
      var expression = findNode.constructorInvocation("Text('abc')");
      expect(expression.isWidgetExpression2, isTrue);
    }

    {
      var expression = findNode.unqualifiedNameExpression('text;');
      expect(expression.isWidgetExpression2, isTrue);
    }

    {
      var expression = findNode.unqualifiedFunctionInvocation(
        'createEmptyText();',
      );
      expect(expression.isWidgetExpression2, isTrue);
    }

    {
      var argument = findNode.singleNamedArgument;
      expect(argument.isWidgetExpression2, isFalse);
    }

    {
      var expression = findNode.singleIntegerLiteral;
      expect(expression.isWidgetExpression2, isFalse);
    }

    {
      var expression = findNode.unqualifiedNameExpression('intVariable;');
      expect(expression.isWidgetExpression2, isFalse);
    }
  }
}
