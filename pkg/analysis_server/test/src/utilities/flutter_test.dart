// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';
import 'flutter_util.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterTest);
  });
}

@reflectiveTest
class FlutterTest extends AbstractSingleUnitTest {
  @override
  void setUp() {
    super.setUp();
    Folder libFolder = configureFlutterPackage(resourceProvider);
    packageMap['flutter'] = [libFolder];
  }

  test_getWidgetPresentationText_icon() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';
var w = const Icon(Icons.book);
''');
    var w = _getTopVariableCreation('w');
    expect(getWidgetPresentationText(w), "Icon(Icons.book)");
  }

  test_getWidgetPresentationText_icon_withoutArguments() async {
    verifyNoTestUnitErrors = false;
    await resolveTestUnit('''
import 'package:flutter/material.dart';
var w = const Icon();
''');
    var w = _getTopVariableCreation('w');
    expect(getWidgetPresentationText(w), "Icon");
  }

  test_getWidgetPresentationText_notWidget() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';
var w = new Object();
''');
    var w = _getTopVariableCreation('w');
    expect(getWidgetPresentationText(w), isNull);
  }

  test_getWidgetPresentationText_text() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';
var w = const Text('foo');
''');
    var w = _getTopVariableCreation('w');
    expect(getWidgetPresentationText(w), "Text('foo')");
  }

  test_getWidgetPresentationText_text_longText() async {
    await resolveTestUnit('''
import 'package:flutter/material.dart';
var w = const Text('${'abc' * 100}');
''');
    var w = _getTopVariableCreation('w');
    expect(
        getWidgetPresentationText(w), "Text('abcabcabcabcab...cabcabcabcabc')");
  }

  test_getWidgetPresentationText_text_withoutArguments() async {
    verifyNoTestUnitErrors = false;
    await resolveTestUnit('''
import 'package:flutter/material.dart';
var w = const Text();
''');
    var w = _getTopVariableCreation('w');
    expect(getWidgetPresentationText(w), "Text");
  }

  test_getWidgetPresentationText_unresolved() async {
    verifyNoTestUnitErrors = false;
    await resolveTestUnit('''
import 'package:flutter/material.dart';
var w = new Foo();
''');
    var w = _getTopVariableCreation('w');
    expect(getWidgetPresentationText(w), isNull);
  }

  test_identifyWidgetExpression_identifier() async {
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';

main() {
  var text = new Text('abc');
  text;
}
''');
    {
      Expression expression = findNodeAtString("text;");
      expect(identifyWidgetExpression(expression), expression);
    }
  }

  test_identifyWidgetExpression_instanceCreation() async {
    await resolveTestUnit('''
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
      ConstructorName constructorName = creation.constructorName;
      TypeName typeName = constructorName.type;
      ArgumentList argumentList = creation.argumentList;
      expect(identifyWidgetExpression(creation), creation);
      expect(identifyWidgetExpression(constructorName), creation);
      expect(identifyWidgetExpression(typeName), creation);
      expect(identifyWidgetExpression(argumentList), isNull);
      expect(identifyWidgetExpression(argumentList.arguments[0]), isNull);
    }

    // new MyWidget.named(5678);
    {
      ExpressionStatement statement = statements[1];
      InstanceCreationExpression creation = statement.expression;
      ConstructorName constructorName = creation.constructorName;
      TypeName typeName = constructorName.type;
      ArgumentList argumentList = creation.argumentList;
      expect(identifyWidgetExpression(creation), creation);
      expect(identifyWidgetExpression(constructorName), creation);
      expect(identifyWidgetExpression(typeName), creation);
      expect(identifyWidgetExpression(typeName.name), creation);
      expect(identifyWidgetExpression(constructorName.name), creation);
      expect(identifyWidgetExpression(argumentList), isNull);
      expect(identifyWidgetExpression(argumentList.arguments[0]), isNull);
    }
  }

  test_identifyWidgetExpression_invocation() async {
    await resolveTestUnit('''
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
          "createEmptyText();", (node) => node is MethodInvocation);
      expect(identifyWidgetExpression(invocation), invocation);
      ArgumentList argumentList = invocation.argumentList;
      expect(identifyWidgetExpression(argumentList), isNull);
    }

    {
      MethodInvocation invocation = findNodeAtString(
          "createText('xyz');", (node) => node is MethodInvocation);
      expect(identifyWidgetExpression(invocation), invocation);
      ArgumentList argumentList = invocation.argumentList;
      expect(identifyWidgetExpression(argumentList), isNull);
      expect(identifyWidgetExpression(argumentList.arguments[0]), isNull);
    }
  }

  test_identifyWidgetExpression_namedExpression() async {
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';

main() {
  new Container(child: new Text(''));
}

Text createEmptyText() => new Text('');
''');
    Expression childExpression = findNodeAtString('child: ');
    expect(identifyWidgetExpression(childExpression), isNull);
  }

  test_identifyWidgetExpression_null() async {
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';

main() {
  var intVariable = 42;
  intVariable;
}

Text createEmptyText() => new Text('');
''');
    expect(identifyWidgetExpression(null), isNull);
    {
      Expression expression = findNodeAtString("42;");
      expect(identifyWidgetExpression(expression), isNull);
    }

    {
      Expression expression = findNodeAtString("intVariable;");
      expect(identifyWidgetExpression(expression), isNull);
    }
  }

  test_isWidget() async {
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';

class MyStatelessWidget extends StatelessWidget {}
class MyStatefulWidget extends StatefulWidget {}
class MyContainer extends Container {}
class NotFlutter {}
class NotWidget extends State {}
''');
    var myStatelessWidget = testUnitElement.getType('MyStatelessWidget');
    expect(isWidget(myStatelessWidget), isTrue);

    var myStatefulWidget = testUnitElement.getType('MyStatefulWidget');
    expect(isWidget(myStatefulWidget), isTrue);

    var myContainer = testUnitElement.getType('MyContainer');
    expect(isWidget(myContainer), isTrue);

    var notFlutter = testUnitElement.getType('NotFlutter');
    expect(isWidget(notFlutter), isFalse);

    var notWidget = testUnitElement.getType('NotWidget');
    expect(isWidget(notWidget), isFalse);
  }

  test_isWidgetCreation() async {
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';

var a = new Object();
var b = new Text('bbb');
''');
    expect(isWidgetCreation(null), isFalse);

    InstanceCreationExpression a = _getTopVariableCreation('a');
    expect(isWidgetCreation(a), isFalse);

    InstanceCreationExpression b = _getTopVariableCreation('b');
    expect(isWidgetCreation(b), isTrue);
  }

  test_isWidgetExpression() async {
    await resolveTestUnit('''
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
      expect(isWidgetExpression(expression), isFalse);
      var creation = expression.parent.parent as InstanceCreationExpression;
      expect(isWidgetExpression(creation), isTrue);
    }

    {
      Expression expression = findNodeAtString("new Text('abc')");
      expect(isWidgetExpression(expression), isTrue);
    }

    {
      Expression expression = findNodeAtString("text;");
      expect(isWidgetExpression(expression), isTrue);
    }

    {
      Expression expression = findNodeAtString(
          "createEmptyText();", (node) => node is MethodInvocation);
      expect(isWidgetExpression(expression), isTrue);
    }

    {
      SimpleIdentifier expression = findNodeAtString('Container(');
      expect(isWidgetExpression(expression), isFalse);
    }

    {
      NamedExpression expression =
          findNodeAtString('child: ', (n) => n is NamedExpression);
      expect(isWidgetExpression(expression), isFalse);
    }

    {
      Expression expression = findNodeAtString("42;");
      expect(isWidgetExpression(expression), isFalse);
    }

    {
      Expression expression = findNodeAtString("intVariable;");
      expect(isWidgetExpression(expression), isFalse);
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
