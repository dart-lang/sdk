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
