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
    Folder libFolder = configureFlutterPackage(provider);
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
    InstanceCreationExpression a = _getTopVariableCreation('a');
    expect(isWidgetCreation(a), isFalse);

    InstanceCreationExpression b = _getTopVariableCreation('b');
    expect(isWidgetCreation(b), isTrue);
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

  InstanceCreationExpression _getTopVariableCreation(String name,
      [CompilationUnit unit]) {
    return _getTopVariable(name, unit).initializer
        as InstanceCreationExpression;
  }
}
