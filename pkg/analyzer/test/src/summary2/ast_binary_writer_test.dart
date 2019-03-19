// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/summary2/ast_binary_reader.dart';
import 'package:analyzer/src/summary2/ast_binary_writer.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/linking_bundle_context.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/tokens_writer.dart';
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
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.non_nullable,
      EnableString.spread_collections,
    ];

  test_classTypeAlias() async {
    _assertUnresolvedCode('''
mixin M1 {}
mixin M2 {}

class I1 {}
class I2 {}

class X = Object with M1, M2 implements I1, I2;
''');
  }

  test_configuration() async {
    _assertUnresolvedCode('''
import 'dart:math'
  if (a.b.c == 'd1') 'e1'
  if (a.b.c == 'd2') 'e2';
''');
  }

  test_emptyStatement() async {
    _assertUnresolvedCode('''
main() {
  if (true);
}
''');
  }

  test_forElement() async {
    _assertUnresolvedCode('''
main() {
  return [1, for (var i = 0; i < 10; i++) i * i, 2];
}
''');
  }

  test_ifElement() async {
    _assertUnresolvedCode('''
main(bool b) {
  return [1, if (b) 2 else 3, 4];
}
''');
  }

  test_labeledStatement() async {
    _assertUnresolvedCode('''
main() {
  a: b: 42;
}
''');
  }

  test_scriptTag() async {
    _assertUnresolvedCode('''
#!/bin/dart

main() {}
''');
  }

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

  test_spreadElement() async {
    _assertUnresolvedCode('''
main() {
var a = [1, 2, 3];
  return [...a];
}
''');
  }

  void _assertUnresolvedCode(String inputCode) {
    var path = convertPath('/test/lib/test.dart');
    newFile(path, content: inputCode);

    var parseResult = driver.parseFileSync(path);
    var originalUnit = parseResult.unit;
    var originalCode = originalUnit.toSource();

    var tokensResult = TokensWriter().writeTokens(
      originalUnit.beginToken,
      originalUnit.endToken,
    );
    var tokensContext = tokensResult.toContext();

    var rootReference = Reference.root();
    var dynamicRef = rootReference.getChild('dart:core').getChild('dynamic');

    var linkingBundleContext = LinkingBundleContext(dynamicRef);
    var writer = new AstBinaryWriter(linkingBundleContext, tokensContext);
    var builder = writer.writeNode(originalUnit);

    var bundleContext = LinkedBundleContext(
      LinkedElementFactory(null, null, rootReference),
      linkingBundleContext.referencesBuilder,
    );
    var unitContext = LinkedUnitContext(bundleContext, tokensContext);

    var reader = AstBinaryReader(unitContext);
    var deserializedUnit = reader.readNode(builder);
    var deserializedCode = deserializedUnit.toSource();

    expect(deserializedCode, originalCode);
  }
}
