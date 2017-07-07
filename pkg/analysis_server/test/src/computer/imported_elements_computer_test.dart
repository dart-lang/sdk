// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/imported_elements_computer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportElementsComputerTest);
  });
}

@reflectiveTest
class ImportElementsComputerTest extends AbstractContextTest {
  String sourcePath;

  setUp() {
    super.setUp();
    sourcePath = provider.convertPath('/p/lib/source.dart');
  }

  test_none() async {
    String selection = 'x + y + 1';
    String content = """
plusThree(int x) {
  int y = 2;
  print($selection);
}
""";
    List<ImportedElements> elements = await _computeElements(
        content, content.indexOf(selection), selection.length);
    expect(elements, hasLength(0));
  }

  Future<List<ImportedElements>> _computeElements(
      String sourceContent, int offset, int length) async {
    provider.newFile(sourcePath, sourceContent);
    ResolveResult result = await driver.getResult(sourcePath);
    ImportedElementsComputer computer =
        new ImportedElementsComputer(result.unit, offset, length);
    return computer.compute();
  }
}
