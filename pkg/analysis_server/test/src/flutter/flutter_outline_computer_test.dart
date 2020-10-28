// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/flutter/flutter_outline_computer.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterOutlineComputerTest);
  });
}

@reflectiveTest
class FlutterOutlineComputerTest extends AbstractContextTest {
  String testPath;
  String testCode;
  ResolvedUnitResult resolveResult;
  FlutterOutlineComputer computer;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
    testPath = convertPath('/home/test/lib/test.dart');
  }

  Future<void> test_attribute_namedExpression() async {
    var unitOutline = await _computeOutline('''
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
    _assertLocation(attribute.nameLocation, 75, 5);
    _assertLocation(attribute.valueLocation, 82, 2);
  }

  Future<void> test_attributes_bool() async {
    var attribute = await _getAttribute('test', 'true');
    expect(attribute.label, 'true');
    expect(attribute.literalValueBoolean, true);
  }

  Future<void>
      test_attributes_functionExpression_hasParameters_blockExpression() async {
    var attribute = await _getAttribute('test', '(a) {}');
    expect(attribute.label, '(…) { … }');
  }

  Future<void>
      test_attributes_functionExpression_hasParameters_bodyExpression() async {
    var attribute = await _getAttribute('test', '(a) => 1');
    expect(attribute.label, '(…) => …');
  }

  Future<void>
      test_attributes_functionExpression_noParameters_blockExpression() async {
    var attribute = await _getAttribute('test', '() {}');
    expect(attribute.label, '() { … }');
  }

  Future<void>
      test_attributes_functionExpression_noParameters_bodyExpression() async {
    var attribute = await _getAttribute('test', '() => 1');
    expect(attribute.label, '() => …');
  }

  Future<void> test_attributes_int() async {
    var attribute = await _getAttribute('test', '42');
    expect(attribute.label, '42');
    expect(attribute.literalValueInteger, 42);
  }

  Future<void> test_attributes_listLiteral() async {
    var attribute = await _getAttribute('test', '[1, 2, 3]');
    expect(attribute.label, '[…]');
  }

  Future<void> test_attributes_mapLiteral() async {
    var attribute = await _getAttribute('test', '{1: 10, 2: 20}');
    expect(attribute.label, '{…}');
  }

  Future<void> test_attributes_multiLine() async {
    var attribute = await _getAttribute('test', '1 +\n 2');
    expect(attribute.label, '…');
  }

  Future<void> test_attributes_setLiteral() async {
    var attribute = await _getAttribute('test', '{1, 2}');
    expect(attribute.label, '{…}');
  }

  Future<void> test_attributes_string_interpolation() async {
    var unitOutline = await _computeOutline(r'''
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

    var attribute = textOutline.attributes[0];
    expect(attribute.name, 'data');
    expect(attribute.label, r"'Hello, $name!'");
    expect(attribute.literalValueString, isNull);
  }

  Future<void> test_attributes_string_literal() async {
    var attribute = await _getAttribute('test', "'my text'");
    expect(attribute.label, "'my text'");
    expect(attribute.literalValueString, 'my text');
  }

  Future<void> test_attributes_unresolved() async {
    var unitOutline = await _computeOutline('''
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

  Future<void> test_children() async {
    var unitOutline = await _computeOutline('''
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
      var offset = testCode.indexOf('new Column');
      var length = testCode.indexOf('; // Column') - offset;
      expect(columnOutline.offset, offset);
      expect(columnOutline.length, length);
    }

    {
      var textOutline = columnOutline.children[0];
      var text = "const Text('aaa')";
      var offset = testCode.indexOf(text);
      expect(textOutline.offset, offset);
      expect(textOutline.length, text.length);
    }

    {
      var textOutline = columnOutline.children[1];
      var text = "const Text('bbb')";
      var offset = testCode.indexOf(text);
      expect(textOutline.offset, offset);
      expect(textOutline.length, text.length);
    }
  }

  Future<void> test_children_closure_blockBody() async {
    newFile('/home/test/lib/a.dart', content: r'''
import 'package:flutter/widgets.dart';

class WidgetA extends StatelessWidget {
  final Widget Function(bool) factory;

  WidgetA(this.factory);
}
''');
    var unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';
import 'a.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new WidgetA((b) {
      if (b) {
        return const Text('aaa'),
      } else {
        return const Container(),
      }
    }); // WidgetA
  }
}
''');
    expect(_toText(unitOutline), r'''
(D) MyWidget
  (D) build
    WidgetA
      Text
      Container
''');
  }

  Future<void> test_children_closure_expressionBody() async {
    newFile('/home/test/lib/a.dart', content: r'''
import 'package:flutter/widgets.dart';

class WidgetA extends StatelessWidget {
  final Widget Function() factory;

  WidgetA(this.factory);
}
''');
    var unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';
import 'a.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new WidgetA(
      () => const Text('aaa'),
    ); // WidgetA
  }
}
''');
    expect(_toText(unitOutline), r'''
(D) MyWidget
  (D) build
    WidgetA
      Text
''');
  }

  Future<void> test_children_withCollectionElements() async {
    var unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    bool includeB = true;
    return new Column(children: [
      const Text('aaa'),
      if (includeB) const Text('bbb'),
      for (int s in ['ccc', 'ddd'] const Text(s),
    ]);
  }
}
''');

    expect(_toText(unitOutline), r'''
(D) MyWidget
  (D) build
    Column
      Text
      Text
      Text
''');
  }

  Future<void> test_codeOffsetLength() async {
    var unitOutline = await _computeOutline('''
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

  Future<void> test_genericLabel_invocation() async {
    var unitOutline = await _computeOutline(r'''
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

  Future<void> test_parentAssociationLabel() async {
    newFile('/home/test/lib/a.dart', content: r'''
import 'package:flutter/widgets.dart';

class WidgetA extends StatelessWidget {
  final Widget top;
  final Widget bottom;
  
  WidgetA({this.top, this.bottom});
}
''');
    var unitOutline = await _computeOutline('''
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

  Future<void> test_variableName() async {
    var unitOutline = await _computeOutline('''
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

  void _assertLocation(
      Location actual, int expectedOffset, int expectedLength) {
    expect(actual.offset, expectedOffset);
    expect(actual.length, expectedLength);
  }

  Future<FlutterOutline> _computeOutline(String code) async {
    testCode = code;
    newFile(testPath, content: code);
    resolveResult = await session.getResolvedUnit(testPath);
    computer = FlutterOutlineComputer(resolveResult);
    return computer.compute();
  }

  Future<FlutterOutlineAttribute> _getAttribute(
      String name, String value) async {
    var unitOutline = await _computeOutline('''
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
    expect(attribute.nameLocation, isNull);
    _assertLocation(attribute.valueLocation, 64, value.length);

    return attribute;
  }

  static String _toText(FlutterOutline outline) {
    var buffer = StringBuffer();

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
