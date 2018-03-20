// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/flutter/flutter_outline_computer.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
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
  AnalysisResult analysisResult;
  FlutterOutlineComputer computer;

  @override
  void setUp() {
    super.setUp();
    testPath = resourceProvider.convertPath('/test.dart');
    Folder libFolder = configureFlutterPackage(resourceProvider);
    packageMap['flutter'] = [libFolder];
  }

  test_attribute_namedExpression() async {
    FlutterOutline unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

main() {
  return new WidgetA(
    value: 42,
  ); // WidgetA
}

class WidgetA extends StatelessWidget {
  WidgetA({int value});
}
''');
    var main = unitOutline.children[0];
    var widget = main.children[0];
    expect(widget.attributes, hasLength(1));

    var attribute = widget.attributes[0];
    expect(attribute.name, 'value');
    expect(attribute.label, '42');
  }

  test_attributes_bool() async {
    var attribute = await _getAttribute('test', 'true');
    expect(attribute.label, 'true');
    expect(attribute.literalValueBoolean, true);
  }

  test_attributes_functionExpression_hasParameters_blockExpression() async {
    var attribute = await _getAttribute('test', '(a) {}');
    expect(attribute.label, '(…) { … }');
  }

  test_attributes_functionExpression_hasParameters_bodyExpression() async {
    var attribute = await _getAttribute('test', '(a) => 1');
    expect(attribute.label, '(…) => …');
  }

  test_attributes_functionExpression_noParameters_blockExpression() async {
    var attribute = await _getAttribute('test', '() {}');
    expect(attribute.label, '() { … }');
  }

  test_attributes_functionExpression_noParameters_bodyExpression() async {
    var attribute = await _getAttribute('test', '() => 1');
    expect(attribute.label, '() => …');
  }

  test_attributes_int() async {
    var attribute = await _getAttribute('test', '42');
    expect(attribute.label, '42');
    expect(attribute.literalValueInteger, 42);
  }

  test_attributes_listLiteral() async {
    var attribute = await _getAttribute('test', '[1, 2, 3]');
    expect(attribute.label, '[…]');
  }

  test_attributes_mapLiteral() async {
    var attribute = await _getAttribute('test', '{1: 10, 2: 20}');
    expect(attribute.label, '{…}');
  }

  test_attributes_multiLine() async {
    var attribute = await _getAttribute('test', '1 +\n 2');
    expect(attribute.label, '…');
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
    var attribute = await _getAttribute('test', "'my text'");
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
      expect(columnOutline.offset, offset);
      expect(columnOutline.length, length);
    }

    {
      var textOutline = columnOutline.children[0];
      String text = "const Text('aaa')";
      int offset = testCode.indexOf(text);
      expect(textOutline.offset, offset);
      expect(textOutline.length, text.length);
    }

    {
      var textOutline = columnOutline.children[1];
      String text = "const Text('bbb')";
      int offset = testCode.indexOf(text);
      expect(textOutline.offset, offset);
      expect(textOutline.length, text.length);
    }
  }

  test_codeOffsetLength() async {
    FlutterOutline unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

/// Comment
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}
''');
    var myWidget = unitOutline.children[0];
    expect(myWidget.offset, 40);
    expect(myWidget.length, 137);
    expect(myWidget.codeOffset, 52);
    expect(myWidget.codeLength, 125);

    var build = myWidget.children[0];
    expect(build.offset, 95);
    expect(build.length, 80);
    expect(build.codeOffset, 107);
    expect(build.codeLength, 68);

    var container = build.children[0];
    expect(container.offset, 155);
    expect(container.length, 15);
    expect(container.codeOffset, 155);
    expect(container.codeLength, 15);
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

  test_render_BAD_noDesignTimeConstructor() async {
    FlutterOutline unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Row();
  }
}
''');
    var myWidget = unitOutline.children[0];
    expect(myWidget.renderConstructor, isNull);
    expect(myWidget.stateOffset, isNull);
    expect(myWidget.stateLength, isNull);

    expect(computer.instrumentedCode, isNull);
  }

  test_render_BAD_part() async {
    // Use test.dart as a part of a library.
    // Add the library to the driver so that it is analyzed before the part.
    var libPath = newFile('/test_lib.dart', content: r'''
part 'test.dart';
import 'package:flutter/widgets.dart';
''').path;
    driver.addFile(libPath);

    FlutterOutline unitOutline = await _computeOutline('''
part of 'test_lib.dart';

class MyWidget extends StatelessWidget {
  MyWidget.forDesignTime();

  @override
  Widget build(BuildContext context) {
    return new Row();
  }
}
''');

    // Analysis is successful, no errors.
    expect(analysisResult.errors, isEmpty);

    // No instrumentation, because not a library.
    expect(computer.instrumentedCode, isNull);

    // There is forDesignTime() constructor, but we don't handle parts.
    var myWidget = unitOutline.children[0];
    expect(myWidget.renderConstructor, isNull);
  }

  test_render_instrumentedCode_registerWidgets() async {
    await _computeOutline('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  MyWidget.forDesignTime();

  @override
  Widget build(BuildContext context) {
    return new Row(
      children: <Widget>[
        new Text('aaa'),
        new Text('bbb'),
      ],
    );
  }
}
''');
    expect(
        computer.instrumentedCode,
        r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  MyWidget.forDesignTime();

  @override
  Widget build(BuildContext context) {
    return _registerWidgetInstance(0, new Row(
      children: <Widget>[
        _registerWidgetInstance(1, new Text('aaa')),
        _registerWidgetInstance(2, new Text('bbb')),
      ],
    ));
  }
}
''' +
            FlutterOutlineComputer.RENDER_APPEND);
  }

  test_render_instrumentedCode_rewriteUri_file() async {
    testPath = resourceProvider.convertPath('/home/user/test/test.dart');
    var libFile = newFile('/home/user/test/my_lib.dart', content: '');

    await _computeOutline('''
import 'package:flutter/widgets.dart';
import 'my_lib.dart';

class MyWidget extends StatelessWidget {
  MyWidget.forDesignTime();

  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}
''');
    expect(
        computer.instrumentedCode,
        '''
import 'package:flutter/widgets.dart';
import '${libFile.toUri()}';

class MyWidget extends StatelessWidget {
  MyWidget.forDesignTime();

  @override
  Widget build(BuildContext context) {
    return _registerWidgetInstance(0, new Container());
  }
}
''' +
            FlutterOutlineComputer.RENDER_APPEND);
  }

  test_render_instrumentedCode_rewriteUri_package() async {
    packageMap['test'] = [newFolder('/home/user/test/lib')];

    testPath = resourceProvider.convertPath('/home/user/test/lib/test.dart');
    newFile('/home/user/test/lib/my_lib.dart', content: '');

    await _computeOutline('''
import 'package:flutter/widgets.dart';
import 'my_lib.dart';

class MyWidget extends StatelessWidget {
  MyWidget.forDesignTime();

  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}
''');
    expect(
        computer.instrumentedCode,
        '''
import 'package:flutter/widgets.dart';
import 'package:test/my_lib.dart';

class MyWidget extends StatelessWidget {
  MyWidget.forDesignTime();

  @override
  Widget build(BuildContext context) {
    return _registerWidgetInstance(0, new Container());
  }
}
''' +
            FlutterOutlineComputer.RENDER_APPEND);
  }

  test_render_stateful_createState_blockBody() async {
    FlutterOutline unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  MyWidget.forDesignTime();

  @override
  MyWidgetState createState() {
    return new MyWidgetState();
  }
}

class MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return new Container(),
  }
}
''');
    var myWidget = unitOutline.children[0];
    expect(myWidget.renderConstructor, 'forDesignTime');
    expect(myWidget.stateOffset, 192);
    expect(myWidget.stateLength, 130);
  }

  test_render_stateful_createState_expressionBody() async {
    FlutterOutline unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  MyWidget.forDesignTime();

  @override
  MyWidgetState createState() => new MyWidgetState();
}

class MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return new Container(),
  }
}
''');
    var myWidget = unitOutline.children[0];
    expect(myWidget.renderConstructor, 'forDesignTime');
    expect(myWidget.stateOffset, 178);
    expect(myWidget.stateLength, 130);
  }

  test_render_stateless() async {
    FlutterOutline unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  MyWidget.forDesignTime();

  @override
  Widget build(BuildContext context) {
    return new Row(
      children: <Widget>[
        new Text('aaa'),
        new Text('bbb'),
      ],
    );
  }
}
''');
    var myWidget = unitOutline.children[0];
    expect(myWidget.renderConstructor, 'forDesignTime');
    expect(myWidget.stateOffset, isNull);
    expect(myWidget.stateLength, isNull);

    var build = myWidget.children[1];

    var row = build.children[0];
    expect(row.className, 'Row');
    expect(row.id, 0);

    var textA = row.children[0];
    expect(textA.className, 'Text');
    expect(textA.id, 1);

    var textB = row.children[1];
    expect(textB.className, 'Text');
    expect(textB.id, 2);
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
    analysisResult = await driver.getResult(testPath);
    computer = new FlutterOutlineComputer(
        testPath, testCode, analysisResult.lineInfo, analysisResult.unit);
    return computer.compute();
  }

  Future<FlutterOutlineAttribute> _getAttribute(
      String name, String value) async {
    FlutterOutline unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

main() {
  new MyWidget($value);
}

class MyWidget extends StatelessWidget {
  MyWidget($name);

  @override
  Widget build(BuildContext context) {
    return const Text('')
  }
}
''');
    var main = unitOutline.children[0];
    var newMyWidget = main.children[0];

    expect(newMyWidget.attributes, hasLength(1));

    var attribute = newMyWidget.attributes[0];
    expect(attribute.name, name);
    return attribute;
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
