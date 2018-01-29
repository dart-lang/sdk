// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/flutter/flutter_correction.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';
import '../utilities/flutter_util.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterCorrectionTest);
  });
}

@reflectiveTest
class FlutterCorrectionTest extends AbstractSingleUnitTest {
  int offset;
  int length;

  int findOffset(String search) {
    int offset = testCode.indexOf(search);
    expect(offset, isNonNegative, reason: "Not found '$search' in\n$testCode");
    return offset;
  }

  @override
  void setUp() {
    super.setUp();
    packageMap['flutter'] = [configureFlutterPackage(resourceProvider)];
  }

  test_wrapWidget_OK_multiLine() async {
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return /*start*/new Row(
      children: [
        new Text('aaa'),
        new Text('bbb'),
      ],
    )/*end*/;
  }
}
''');
    _setStartEndSelection();

    InterfaceType parentType = await _getContainerType();
    SourceChange change = await _wrapWidget(parentType);

    _assertChange(change, r'''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return new Container(
      child: /*start*/new Row(
        children: [
          new Text('aaa'),
          new Text('bbb'),
        ],
      )/*end*/,
    );
  }
}
''');
  }

  test_wrapWidget_OK_multiLine_subChild() async {
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return new Container(
      child: /*start*/new Row(
        children: [
          new Text('aaa'),
          new Text('bbb'),
        ],
      )/*end*/,
    );
  }
}
''');
    _setStartEndSelection();

    InterfaceType parentType = await _getContainerType();
    SourceChange change = await _wrapWidget(parentType);

    _assertChange(change, r'''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return new Container(
      child: new Container(
        child: /*start*/new Row(
          children: [
            new Text('aaa'),
            new Text('bbb'),
          ],
        )/*end*/,
      ),
    );
  }
}
''');
  }

  test_wrapWidget_OK_oneLine_newInstance() async {
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return /*start*/new Text('abc')/*end*/;
  }
}
''');
    _setStartEndSelection();

    InterfaceType parentType = await _getContainerType();
    SourceChange change = await _wrapWidget(parentType);

    _assertChange(change, r'''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return new Container(child: /*start*/new Text('abc')/*end*/);
  }
}
''');
  }

  test_wrapWidget_OK_oneLine_variable() async {
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    var text = new Text('abc');
    return /*start*/text/*end*/;
  }
}
''');
    _setStartEndSelection();

    InterfaceType parentType = await _getContainerType();
    SourceChange change = await _wrapWidget(parentType);

    _assertChange(change, r'''
import 'package:flutter/widgets.dart';
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    var text = new Text('abc');
    return new Container(child: /*start*/text/*end*/);
  }
}
''');
  }

  void _assertChange(SourceChange change, String expectedCode) {
    expect(change, isNotNull);

    List<SourceFileEdit> files = change.edits;
    expect(files, hasLength(1));
    expect(files[0].file, testFile);

    List<SourceEdit> fileEdits = files[0].edits;
    String resultCode = SourceEdit.applySequence(testCode, fileEdits);
    if (resultCode != expectedCode) {
      print(resultCode);
    }
    expect(resultCode, expectedCode);
  }

  Future<InterfaceType> _getContainerType() async {
    LibraryElement widgetsLibrary = await testAnalysisResult.session
        .getLibraryByUri('package:flutter/widgets.dart');
    ClassElement containerElement =
        widgetsLibrary.exportNamespace.get('Container');
    return containerElement.type;
  }

  void _setStartEndSelection() {
    offset = findOffset('/*start*/');
    length = findOffset('/*end*/') + '/*end*/'.length - offset;
  }

  Future<SourceChange> _wrapWidget(InterfaceType parentType) async {
    var corrections = new FlutterCorrections(
        file: testFile,
        fileContent: testCode,
        selectionOffset: offset,
        selectionLength: length,
        session: testAnalysisResult.session,
        unit: testUnit);
    return await corrections.wrapWidget(parentType);
  }
}
