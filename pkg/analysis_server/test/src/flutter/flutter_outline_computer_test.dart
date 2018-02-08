// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/flutter/flutter_outline_computer.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';
import '../utilities/flutter_util.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterOutlineComputerTest);
  });
}

@reflectiveTest
class FlutterOutlineComputerTest extends AbstractContextTest {
  String testPath;
  String testCode;

  @override
  void setUp() {
    super.setUp();
    testPath = resourceProvider.convertPath('/test.dart');
    Folder libFolder = configureFlutterPackage(resourceProvider);
    packageMap['flutter'] = [libFolder];
  }

  test_attribute_namedExpression() async {
    newFile('/a.dart', content: r'''
import 'package:flutter/widgets.dart';

class WidgetA extends StatelessWidget {
  WidgetA({int value});
}
''');
    FlutterOutline unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';
import 'a.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new WidgetA(
      value: 42,
    ); // WidgetA
  }
}
''');
    var myWidget = unitOutline.children[0];
    var build = myWidget.children[0];

    var a = build.children[0];
    expect(a.attributes, hasLength(1));

    var attribute = a.attributes[0];
    expect(attribute.name, 'value');
    expect(attribute.label, '42');
  }

  test_attributes_bool() async {
    FlutterOutline unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(true)
  }
}
''');
    var myWidget = unitOutline.children[0];
    var build = myWidget.children[0];
    var textOutline = build.children[0];

    expect(textOutline.attributes, hasLength(1));

    FlutterOutlineAttribute attribute = textOutline.attributes[0];
    expect(attribute.name, 'data');
    expect(attribute.label, 'true');
    expect(attribute.literalValueBoolean, true);
  }

  test_attributes_int() async {
    FlutterOutline unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(42)
  }
}
''');
    var myWidget = unitOutline.children[0];
    var build = myWidget.children[0];
    var textOutline = build.children[0];

    expect(textOutline.attributes, hasLength(1));

    FlutterOutlineAttribute attribute = textOutline.attributes[0];
    expect(attribute.name, 'data');
    expect(attribute.label, '42');
    expect(attribute.literalValueInteger, 42);
  }

  test_attributes_string_interpolation() async {
    FlutterOutline unitOutline = await _computeOutline(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var name = 'Foo';
    return const Text('Hello, $name!')
  }
}
''');
    var myWidget = unitOutline.children[0];
    var build = myWidget.children[0];
    var textOutline = build.children[0];

    expect(textOutline.attributes, hasLength(1));

    FlutterOutlineAttribute attribute = textOutline.attributes[0];
    expect(attribute.name, 'data');
    expect(attribute.label, r"'Hello, $name!'");
    expect(attribute.literalValueString, isNull);
  }

  test_attributes_string_literal() async {
    FlutterOutline unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text('my text')
  }
}
''');
    var myWidget = unitOutline.children[0];
    var build = myWidget.children[0];
    var textOutline = build.children[0];

    expect(textOutline.attributes, hasLength(1));

    FlutterOutlineAttribute attribute = textOutline.attributes[0];
    expect(attribute.name, 'data');
    expect(attribute.label, "'my text'");
    expect(attribute.literalValueString, 'my text');
  }

  test_attributes_unresolved() async {
    FlutterOutline unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(1, foo: 2)
  }
}
''');
    var myWidget = unitOutline.children[0];
    var build = myWidget.children[0];

    var rowOutline = build.children[0];
    expect(rowOutline.attributes, isEmpty);
  }

  test_children() async {
    FlutterOutline unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Column(children: [
      const Text('aaa'),
      const Text('bbb'),
    ]); // Column
  }
}
''');

    expect(_toText(unitOutline), r'''
(D) MyWidget
  (D) build
    Column
      Text
      Text
''');
    var myWidget = unitOutline.children[0];
    var build = myWidget.children[0];

    var columnOutline = build.children[0];
    {
      int offset = testCode.indexOf('new Column');
      int length = testCode.indexOf('; // Column') - offset;
      _expect(columnOutline, offset: offset, length: length);
    }

    {
      var textOutline = columnOutline.children[0];
      String text = "const Text('aaa')";
      int offset = testCode.indexOf(text);
      _expect(textOutline, offset: offset, length: text.length);
    }

    {
      var textOutline = columnOutline.children[1];
      String text = "const Text('bbb')";
      int offset = testCode.indexOf(text);
      _expect(textOutline, offset: offset, length: text.length);
    }
  }

  test_genericLabel_invocation() async {
    FlutterOutline unitOutline = await _computeOutline(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Row(children: [
      createText(0),
      createEmptyText(),
      WidgetFactory.createMyText(),
    ]);
  }
  Text createEmptyText() {
    return new Text('');
  }
  Text createText(int index) {
    return new Text('index: $index');
  }
}

class WidgetFactory {
  static Text createMyText() => new Text('');
}
''');
    var myWidget = unitOutline.children[0];
    var build = myWidget.children[0];
    expect(build.children, hasLength(1));

    var row = build.children[0];
    expect(row.kind, FlutterOutlineKind.NEW_INSTANCE);
    expect(row.className, 'Row');
    expect(row.children, hasLength(3));

    {
      var text = row.children[0];
      expect(text.kind, FlutterOutlineKind.GENERIC);
      expect(text.className, 'Text');
      expect(text.label, 'createText(…)');
    }

    {
      var text = row.children[1];
      expect(text.kind, FlutterOutlineKind.GENERIC);
      expect(text.className, 'Text');
      expect(text.label, 'createEmptyText()');
    }

    {
      var text = row.children[2];
      expect(text.kind, FlutterOutlineKind.GENERIC);
      expect(text.className, 'Text');
      expect(text.label, 'WidgetFactory.createMyText()');
    }
  }

  test_parentAssociationLabel() async {
    newFile('/a.dart', content: r'''
import 'package:flutter/widgets.dart';

class WidgetA extends StatelessWidget {
  final Widget top;
  final Widget bottom;
  
  WidgetA({this.top, this.bottom});
}
''');
    FlutterOutline unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';
import 'a.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new WidgetA(
      top: const Text('aaa'),
      bottom: const Text('bbb'),
    ); // WidgetA
  }
}
''');
    expect(_toText(unitOutline), r'''
(D) MyWidget
  (D) build
    WidgetA
      top: Text
      bottom: Text
''');
  }

  test_variableName() async {
    FlutterOutline unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var text = new Text('aaa');
    return new Center(child: text); // Center
  }
}
''');
    var myWidget = unitOutline.children[0];
    var build = myWidget.children[0];
    expect(build.children, hasLength(2));

    var textNew = build.children[0];
    expect(textNew.kind, FlutterOutlineKind.NEW_INSTANCE);
    expect(textNew.className, 'Text');

    var center = build.children[1];
    expect(center.kind, FlutterOutlineKind.NEW_INSTANCE);
    expect(center.className, 'Center');
    expect(center.children, hasLength(1));

    var textRef = center.children[0];
    expect(textRef.kind, FlutterOutlineKind.VARIABLE);
    expect(textRef.className, 'Text');
    expect(textRef.variableName, 'text');
  }

  Future<FlutterOutline> _computeOutline(String code) async {
    testCode = code;
    newFile(testPath, content: code);
    AnalysisResult analysisResult = await driver.getResult(testPath);
    return new FlutterOutlineComputer(
            testPath, analysisResult.lineInfo, analysisResult.unit)
        .compute();
  }

  void _expect(FlutterOutline outline,
      {@required int offset, @required int length}) {
    expect(outline.offset, offset);
    expect(outline.length, length);
  }

  static String _toText(FlutterOutline outline) {
    var buffer = new StringBuffer();

    void writeOutline(FlutterOutline outline, String indent) {
      buffer.write(indent);

      if (outline.kind == FlutterOutlineKind.DART_ELEMENT) {
        buffer.write('(D) ');
        buffer.writeln(outline.dartElement.name);
      } else {
        if (outline.kind == FlutterOutlineKind.NEW_INSTANCE) {
          if (outline.parentAssociationLabel != null) {
            buffer.write(outline.parentAssociationLabel);
            buffer.write(': ');
          }
          buffer.writeln(outline.className);
        } else {
          fail('Unknown kind: ${outline.kind}');
        }
      }

      if (outline.children != null) {
        for (var child in outline.children) {
          writeOutline(child, '$indent  ');
        }
      }
    }

    for (var child in outline.children) {
      writeOutline(child, '');
    }
    return buffer.toString();
  }
}
