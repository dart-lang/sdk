// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/flutter/flutter_correction.dart';
import 'package:analysis_server/src/protocol_server.dart';
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
  int length = 0;
  FlutterCorrections corrections;

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

  test_addForDesignTimeConstructor_BAD_notClass() async {
    await resolveTestUnit('var v = 42;');
    offset = findOffset('v =');
    _createCorrections();

    SourceChange change = await corrections.addForDesignTimeConstructor();
    expect(change, isNull);
  }

  test_addForDesignTimeConstructor_OK_hasConstructor() async {
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  MyWidget(String text);

  Widget build(BuildContext context) {
    return new Container();
  }
}
''');
    offset = findOffset('class MyWidget');
    _createCorrections();

    SourceChange change = await corrections.addForDesignTimeConstructor();
    _assertChange(change, r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  MyWidget(String text);

  factory MyWidget.forDesignTime() {
    // TODO: add arguments
    return new MyWidget();
  }

  Widget build(BuildContext context) {
    return new Container();
  }
}
''');
  }

  test_addForDesignTimeConstructor_OK_noConstructor() async {
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return new Container();
  }
}
''');
    offset = findOffset('class MyWidget');
    _createCorrections();

    SourceChange change = await corrections.addForDesignTimeConstructor();
    _assertChange(change, r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  MyWidget();

  factory MyWidget.forDesignTime() {
    // TODO: add arguments
    return new MyWidget();
  }

  Widget build(BuildContext context) {
    return new Container();
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

  void _createCorrections() {
    corrections = new FlutterCorrections(
        file: testFile,
        fileContent: testCode,
        selectionOffset: offset,
        selectionLength: length,
        session: testAnalysisResult.session,
        unit: testUnit);
  }
}
