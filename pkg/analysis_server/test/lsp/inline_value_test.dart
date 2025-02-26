// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InlineValueTest);
  });
}

@reflectiveTest
class InlineValueTest extends AbstractLspAnalysisServerTest {
  late TestCode code;

  Future<void> test_parameter_declaration() async {
    code = TestCode.parse(r'''
void f(int /*[0*/aaa/*0]*/, int /*[1*/bbb/*1]*/) {
  ^
  aaa + bbb;
}
''');

    await verify_variables(code);
  }

  Future<void> test_parameter_read() async {
    code = TestCode.parse(r'''
void f(int aaa, int bbb) {
  ^/*[0*/aaa/*0]*/ + /*[1*/bbb/*1]*/;
}
''');

    await verify_variables(code);
  }

  Future<void> test_parameter_write() async {
    code = TestCode.parse(r'''
void f(int aaa, int bbb, int ccc) {
  /*[0*/aaa/*0]*/++;
  /*[1*/bbb/*1]*/ = 1;
  /*[2*/ccc/*2]*/ += 1;
  ^
}
''');

    await verify_variables(code);
  }

  Future<void> test_parameters_scope() async {
    // We should only get the parameters declared in the current function.
    code = TestCode.parse(r'''
void f(int aaa, int bbb, int ccc) {
  void b(int /*[0*/aaa/*0]*/, int /*[1*/bbb/*1]*/) {

    var _ = (aaa, bbb, ccc) => null;
    var _ = () {
      var aaa = 1, bbb = 1, ccc = 1;
    };

    ^
  }
}
''');

    await verify_variables(code);
  }

  Future<void> test_variable_declaration() async {
    code = TestCode.parse(r'''
void f() {
  int /*[0*/aaa/*0]*/ = 1;
  int /*[1*/bbb/*1]*/ = 1, /*[2*/ccc/*2]*/ = 1;
  ^
  aaa + bbb;
  ccc;
}
''');

    await verify_variables(code);
  }

  Future<void> test_variable_read() async {
    code = TestCode.parse(r'''
void f() {
  int aaa = 1;
  int bbb = 1, ccc = 1;
  ^/*[0*/aaa/*0]*/ + /*[1*/bbb/*1]*/ + /*[2*/ccc/*2]*/;
}
''');

    await verify_variables(code);
  }

  Future<void> test_variable_write() async {
    code = TestCode.parse(r'''
void f() {
  int aaa = 0, bbb = 0, ccc = 0;
  /*[0*/aaa/*0]*/ = 1;
  /*[1*/bbb/*1]*/++;
  /*[2*/ccc/*2]*/ += 1;
  ^
}
''');

    await verify_variables(code);
  }

  Future<void> test_variables_scope() async {
    // We should not get the top-levels or the nested functions.
    code = TestCode.parse(r'''
var aaa = 1;
var bbb = 1;

void f() {
  int /*[0*/aaa/*0]*/ = 0, /*[1*/ccc/*1]*/ = 0;

  var _ = (aaa, bbb, ccc) => null;
  var _ = () {
    var aaa = 1, bbb = 1, ccc = 1;
  };

  ^
}
''');

    await verify_variables(code);
  }

  /// Verifies [code] produces the [expected] variables (and only those
  /// variables).
  Future<void> verify_variables(TestCode code) async {
    await initialize();
    await openFile(mainFileUri, code.code);
    await initialAnalysis;

    var actualValues = await getInlineValues(
      mainFileUri,
      visibleRange: rangeOfWholeContent(code.code),
      stoppedAt: code.position.position,
    );

    var expectedValues = code.ranges.ranges.map(
      (range) => InlineValue.t3(
        InlineValueVariableLookup(caseSensitiveLookup: true, range: range),
      ),
    );

    expect(actualValues, unorderedEquals(expectedValues));
  }
}
