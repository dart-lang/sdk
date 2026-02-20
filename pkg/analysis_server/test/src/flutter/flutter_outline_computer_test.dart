// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/flutter/flutter_outline_computer.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
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
  late String testPath;
  late TestCode testCode;
  late ResolvedUnitResult resolveResult;
  late FlutterOutlineComputer computer;

  Matcher hasCodeOffsetLength(TestCodeRange range) {
    return TypeMatcher<FlutterOutline>()
        .having(
          (outline) => outline.codeOffset,
          'codeOffset',
          range.sourceRange.offset,
        )
        .having(
          (outline) => outline.codeLength,
          'codeLength',
          range.sourceRange.length,
        );
  }

  Matcher hasOffsetLength(TestCodeRange range) {
    return TypeMatcher<FlutterOutline>()
        .having((outline) => outline.offset, 'offset', range.sourceRange.offset)
        .having(
          (outline) => outline.length,
          'length',
          range.sourceRange.length,
        );
  }

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
    testPath = convertPath('$testPackageLibPath/test.dart');
  }

  Future<void> test_attribute_namedExpression() async {
    var unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

void f() {
  return new WidgetA(
    /*[0*/value/*0]*/: /*[1*/42/*1]*/,
  ); // WidgetA
}

class WidgetA extends StatelessWidget {
  WidgetA({int value});
}
''');
    var main = unitOutline.children![0];
    var widget = main.children![0];
    expect(widget.attributes, hasLength(1));

    var attribute = widget.attributes![0];
    expect(attribute.name, 'value');
    expect(attribute.label, '42');
    _assertLocation(attribute.nameLocation!, testCode.ranges[0]);
    _assertLocation(attribute.valueLocation!, testCode.ranges[1]);
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
    var myWidget = unitOutline.children![0];
    var build = myWidget.children![0];
    var textOutline = build.children![0];

    expect(textOutline.attributes, hasLength(1));

    var attribute = textOutline.attributes![0];
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
    var myWidget = unitOutline.children![0];
    var build = myWidget.children![0];

    var rowOutline = build.children![0];
    expect(rowOutline.attributes, isEmpty);
  }

  Future<void> test_child_conditionalExpression() async {
    var unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';


class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: true ? Text() : Container(),
    );
  }
}

''');
    expect(_toText(unitOutline), r'''
(D) MyWidget
  (D) build → Widget
    Container
      Text
      Container
''');
  }

  Future<void> test_children() async {
    var unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return /*[0*/new Column(children: [
      /*[1*/const Text('aaa')/*1]*/,
      /*[2*/const Text('bbb')/*2]*/,
    ])/*0]*/; // Column
  }
}
''');

    expect(_toText(unitOutline), r'''
(D) MyWidget
  (D) build → Widget
    Column
      Text
      Text
''');
    var myWidget = unitOutline.children![0];
    var build = myWidget.children![0];

    var columnOutline = build.children![0];
    expect(columnOutline, hasOffsetLength(testCode.ranges[0]));
    expect(columnOutline.children![0], hasOffsetLength(testCode.ranges[1]));
    expect(columnOutline.children![1], hasOffsetLength(testCode.ranges[2]));
  }

  Future<void> test_children_closure_blockBody() async {
    newFile('$testPackageLibPath/a.dart', r'''
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
  (D) build → Widget
    WidgetA
      Text
      Container
''');
  }

  Future<void> test_children_closure_expressionBody() async {
    newFile('$testPackageLibPath/a.dart', r'''
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
  (D) build → Widget
    WidgetA
      Text
''');
  }

  Future<void> test_children_conditionalExpression() async {
    var unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';


class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
          true ? Text() : Container(),
          Flex(),
      ],
    );
  }
}

''');
    expect(_toText(unitOutline), r'''
(D) MyWidget
  (D) build → Widget
    Column
      Text
      Container
      Flex
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
      for (int s in ['ccc', 'ddd']) const Text(s),
    ]);
  }
}
''');

    expect(_toText(unitOutline), r'''
(D) MyWidget
  (D) build → Widget
    Column
      Text
      Text
      Text
''');
  }

  Future<void> test_children_withNullAwareElements() async {
    var unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Column(children: [
      const Text('aaa'),
      ?const Text('bbb'),
    ]);
  }
}
''');

    expect(_toText(unitOutline), r'''
(D) MyWidget
  (D) build → Widget
    Column
      Text
      Text
''');
  }

  Future<void> test_codeOffsetLength() async {
    var unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

/*[0*//// Comment
/*[1*/class MyWidget extends StatelessWidget {
  /*[2*/@override
  /*[3*/Widget build(BuildContext context) {
    return /*[4*/new Container()/*4]*/;
  }/*3]*//*2]*/
}/*1]*//*0]*/
''');
    var myWidget = unitOutline.children![0];
    expect(myWidget, hasOffsetLength(testCode.ranges[0]));
    expect(myWidget, hasCodeOffsetLength(testCode.ranges[1]));

    var build = myWidget.children![0];
    expect(build, hasOffsetLength(testCode.ranges[2]));
    expect(build, hasCodeOffsetLength(testCode.ranges[3]));

    var container = build.children![0];
    expect(container, hasOffsetLength(testCode.ranges[4]));
    // Same range for element/code.
    expect(container, hasCodeOffsetLength(testCode.ranges[4]));
  }

  Future<void> test_enum() async {
    var unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

enum E {
  v;
  Widget build(BuildContext context) {
    return [!const Text('A')!];
  }
}
''');

    expect(_toText(unitOutline), r'''
(D) E
  (D) v
  (D) build → Widget
    Text
''');
    var E = unitOutline.children![0];
    var build = E.children![1];
    expect(build.children![0], hasOffsetLength(testCode.range));
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
    var myWidget = unitOutline.children![0];
    var build = myWidget.children![0];
    expect(build.children, hasLength(1));

    var row = build.children![0];
    expect(row.kind, FlutterOutlineKind.NEW_INSTANCE);
    expect(row.className, 'Row');
    expect(row.children, hasLength(3));

    {
      var text = row.children![0];
      expect(text.kind, FlutterOutlineKind.GENERIC);
      expect(text.className, 'Text');
      expect(text.label, 'createText(…)');
    }

    {
      var text = row.children![1];
      expect(text.kind, FlutterOutlineKind.GENERIC);
      expect(text.className, 'Text');
      expect(text.label, 'createEmptyText()');
    }

    {
      var text = row.children![2];
      expect(text.kind, FlutterOutlineKind.GENERIC);
      expect(text.className, 'Text');
      expect(text.label, 'WidgetFactory.createMyText()');
    }
  }

  Future<void> test_namedArgument_anywhere() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:flutter/widgets.dart';

class WidgetA extends StatelessWidget {
  final Widget top;
  final Widget bottom;
  final Widget left;
  final Widget right;

  WidgetA(this.top, this.bottom, {this.left, this.right});
}
''');
    var unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';
import 'a.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new WidgetA(
      const Container(),
      left: const Text('left'),
      const Flex(),
      right: const Text('right'),
    );
  }
}
''');
    expect(_toText(unitOutline), r'''
(D) MyWidget
  (D) build → Widget
    WidgetA
      Container
      left: Text
      Flex
      right: Text
''');
  }

  Future<void> test_parentAssociationLabel() async {
    newFile('$testPackageLibPath/a.dart', r'''
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
  (D) build → Widget
    WidgetA
      top: Text
      bottom: Text
''');
  }

  Future<void> test_primaryConstructor() async {
    var unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

class /*[0*/MyWidget/*0]*/(
    final int /*[1*/a/*1]*/, {
    required var int /*[2*/b/*2]*/,
    int? c
  }) extends StatelessWidget {
  this {}

  @override
  Widget build(BuildContext context) {
    return MyWidget(1, b: 2, c: 3);
  }
}
''');

    expect(_toText(unitOutline), r'''
(D) MyWidget
  (D) MyWidget
  (D) a → int
  (D) b → int
  (D) this
  (D) build → Widget
    MyWidget
''');

    var myWidget = unitOutline.children![0];
    var constructor = myWidget.children!.singleWhere(
      (child) => child.dartElement?.name == 'MyWidget',
    );
    var fieldA = myWidget.children!.singleWhere(
      (child) => child.dartElement?.name == 'a',
    );
    var fieldB = myWidget.children!.singleWhere(
      (child) => child.dartElement?.name == 'b',
    );
    var build = myWidget.children!.singleWhere(
      (child) => child.dartElement?.name == 'build',
    );
    var buildMyWidget = build.children![0];

    _assertLocation(myWidget.dartElement!.location!, testCode.ranges[0]);
    _assertLocation(constructor.dartElement!.location!, testCode.ranges[0]);
    _assertLocation(fieldA.dartElement!.location!, testCode.ranges[1]);
    _assertLocation(fieldB.dartElement!.location!, testCode.ranges[2]);

    expect(buildMyWidget.kind, FlutterOutlineKind.NEW_INSTANCE);
    expect(buildMyWidget.className, 'MyWidget');
    expect(buildMyWidget.attributes, hasLength(3));
    expect(buildMyWidget.attributes![0].name, 'a');
    expect(buildMyWidget.attributes![1].name, 'b');
    expect(buildMyWidget.attributes![2].name, 'c');
  }

  Future<void> test_primaryConstructor_named() async {
    var unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

class /*[0*/MyWidget/*0]*//*[1*/.named/*1]*/(
    final int /*[2*/a/*2]*/, {
    required var int /*[3*/b/*3]*/,
    int? c
  }) extends StatelessWidget {
  this {}

  @override
  Widget build(BuildContext context) {
    return MyWidget.named(1, b: 2, c: 3);
  }
}
''');

    expect(_toText(unitOutline), r'''
(D) MyWidget
  (D) MyWidget.named
  (D) a → int
  (D) b → int
  (D) this
  (D) build → Widget
    MyWidget
''');

    var myWidget = unitOutline.children![0];
    var constructor = myWidget.children!.singleWhere(
      (child) => child.dartElement?.name == 'MyWidget.named',
    );
    var fieldA = myWidget.children!.singleWhere(
      (child) => child.dartElement?.name == 'a',
    );
    var fieldB = myWidget.children!.singleWhere(
      (child) => child.dartElement?.name == 'b',
    );
    var build = myWidget.children!.singleWhere(
      (child) => child.dartElement?.name == 'build',
    );
    var buildMyWidget = build.children![0];

    _assertLocation(myWidget.dartElement!.location!, testCode.ranges[0]);
    _assertLocation(constructor.dartElement!.location!, testCode.ranges[1]);
    _assertLocation(fieldA.dartElement!.location!, testCode.ranges[2]);
    _assertLocation(fieldB.dartElement!.location!, testCode.ranges[3]);

    expect(buildMyWidget.kind, FlutterOutlineKind.NEW_INSTANCE);
    expect(buildMyWidget.className, 'MyWidget');
    expect(buildMyWidget.attributes, hasLength(3));
    expect(buildMyWidget.attributes![0].name, 'a');
    expect(buildMyWidget.attributes![1].name, 'b');
    expect(buildMyWidget.attributes![2].name, 'c');
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
    var myWidget = unitOutline.children![0];
    var build = myWidget.children![0];
    expect(build.children, hasLength(2));

    var textNew = build.children![0];
    expect(textNew.kind, FlutterOutlineKind.NEW_INSTANCE);
    expect(textNew.className, 'Text');

    var center = build.children![1];
    expect(center.kind, FlutterOutlineKind.NEW_INSTANCE);
    expect(center.className, 'Center');
    expect(center.children, hasLength(1));

    var textRef = center.children![0];
    expect(textRef.kind, FlutterOutlineKind.VARIABLE);
    expect(textRef.className, 'Text');
    expect(textRef.variableName, 'text');
  }

  void _assertLocation(Location actual, TestCodeRange range) {
    expect(actual.offset, range.sourceRange.offset);
    expect(actual.length, range.sourceRange.length);
  }

  Future<FlutterOutline> _computeOutline(String content) async {
    testCode = TestCode.parseNormalized(content);
    newFile(testPath, testCode.code);
    resolveResult = await getResolvedUnit(testFile);
    computer = FlutterOutlineComputer(resolveResult);
    return computer.compute();
  }

  Future<FlutterOutlineAttribute> _getAttribute(
    String name,
    String value,
  ) async {
    var unitOutline = await _computeOutline('''
import 'package:flutter/widgets.dart';

void f() {
  new MyWidget([!$value!]);
}

class MyWidget extends StatelessWidget {
  MyWidget($name);

  @override
  Widget build(BuildContext context) {
    return const Text('')
  }
}
''');
    var main = unitOutline.children![0];
    var newMyWidget = main.children![0];

    expect(newMyWidget.attributes, hasLength(1));

    var attribute = newMyWidget.attributes![0];
    expect(attribute.name, name);
    expect(attribute.nameLocation, isNull);
    _assertLocation(attribute.valueLocation!, testCode.range);

    return attribute;
  }

  static String _toText(FlutterOutline outline) {
    var buffer = StringBuffer();

    void writeOutline(FlutterOutline outline, String indent) {
      buffer.write(indent);

      if (outline.kind == FlutterOutlineKind.DART_ELEMENT) {
        var element = outline.dartElement!;
        buffer.write('(D) ');
        buffer.write(element.name);
        if (element.returnType != null) {
          buffer.write(' → ');
          buffer.write(element.returnType);
        }
        buffer.writeln();
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
        for (var child in outline.children!) {
          writeOutline(child, '$indent  ');
        }
      }
    }

    for (var child in outline.children!) {
      writeOutline(child, '');
    }
    return buffer.toString();
  }
}
