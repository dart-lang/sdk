// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/node_text_expectations.dart';
import '../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonErrorParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonErrorParserTest extends ParserDiagnosticsTest {
  void test_annotationOnEnumConstant_first() {
    parseTestCodeWithDiagnostics("enum E { @override C }");
  }

  void test_annotationOnEnumConstant_middle() {
    parseTestCodeWithDiagnostics("enum E { C, @override D, E }");
  }

  void test_staticMethod_notParsingFunctionBodies() {
    parseTestCodeWithDiagnostics('class C { static void m() {} }');
  }
}
