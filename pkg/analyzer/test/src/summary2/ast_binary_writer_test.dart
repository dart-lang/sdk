// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/summary2/ast_binary_reader.dart';
import 'package:analyzer/src/summary2/ast_binary_writer.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AstBinaryWriterTest);
  });
}

/// Just a very simple test that at least something works.
@reflectiveTest
class AstBinaryWriterTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  test_simple() async {
    _assertUnresolvedCode('''
const zero = 0;

@zero
class A<T extends num> {}

class B extends A<int> {}

void f() { // ref
  1 + 2.0;
  <double>[1, 2];
}
''');
  }

  void _assertUnresolvedCode(String inputCode) {
    var path = convertPath('/test/lib/test.dart');
    newFile(path, content: inputCode);

    var parseResult = driver.parseFileSync(path);
    var originalUnit = parseResult.unit;
    var originalCode = originalUnit.toSource();

    var writer = new AstBinaryWriter();
    var builder = writer.writeNode(originalUnit);
    writer.writeReferences();

    var reader = AstBinaryReader(
      Reference.root(),
      writer.referenceBuilder,
      writer.tokens,
    );
    var deserializedUnit = reader.readNode(builder);
    var deserializedCode = deserializedUnit.toSource();

    expect(deserializedCode, originalCode);
  }
}
