// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonErrorParserTest);
  });
}

@reflectiveTest
class NonErrorParserTest extends ParserDiagnosticsTest {
  void test_annotationOnEnumConstant_first() {
    var parseResult = parseStringWithErrors("enum E { @override C }");
    parseResult.assertNoErrors();
  }

  void test_annotationOnEnumConstant_middle() {
    var parseResult = parseStringWithErrors("enum E { C, @override D, E }");
    parseResult.assertNoErrors();
  }

  void test_staticMethod_notParsingFunctionBodies() {
    var parseResult = parseStringWithErrors('class C { static void m() {} }');
    parseResult.assertNoErrors();
  }
}
