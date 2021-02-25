// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/flutter/flutter_correction.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterCorrectionTest);
  });
}

@reflectiveTest
class FlutterCorrectionTest extends AbstractSingleUnitTest {
  int offset;
  int length = 0;
  FlutterCorrections corrections;

  @override
  int findOffset(String search) {
    var offset = testCode.indexOf(search);
    expect(offset, isNonNegative, reason: "Not found '$search' in\n$testCode");
    return offset;
  }

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

//  void _assertChange(SourceChange change, String expectedCode) {
//    expect(change, isNotNull);
//
//    List<SourceFileEdit> files = change.edits;
//    expect(files, hasLength(1));
//    expect(files[0].file, testFile);
//
//    List<SourceEdit> fileEdits = files[0].edits;
//    String resultCode = SourceEdit.applySequence(testCode, fileEdits);
//    if (resultCode != expectedCode) {
//      print(resultCode);
//    }
//    expect(resultCode, expectedCode);
//  }
//
//  void _createCorrections() {
//    corrections = new FlutterCorrections(
//      resolveResult: testAnalysisResult,
//      selectionOffset: offset,
//      selectionLength: length,
//    );
//  }
}
