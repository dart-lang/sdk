// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'error_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisErrorIntegrationTest_Driver);
  });
}

@reflectiveTest
class AnalysisErrorIntegrationTest_Driver
    extends AbstractAnalysisErrorIntegrationTest {
  @override
  bool get enableNewAnalysisDriver => true;

  @failingTest
  test_super_mixins_enabled() async {
    // We see errors here with the new driver (#28870).
    //  Expected: empty
    //    Actual: [
    //    AnalysisError:{"severity":"ERROR","type":"COMPILE_TIME_ERROR","location":{"file":"/var/folders/00/0w95r000h01000cxqpysvccm003j4q/T/analysisServerfbuOQb/test.dart","offset":31,"length":1,"startLine":1,"startColumn":32},"message":"The class 'C' can't be used as a mixin because it extends a class other than Object.","correction":"","code":"mixin_inherits_from_not_object","hasFix":false},
    //    AnalysisError:{"severity":"ERROR","type":"COMPILE_TIME_ERROR","location":{"file":"/var/folders/00/0w95r000h01000cxqpysvccm003j4q/T/analysisServerfbuOQb/test.dart","offset":31,"length":1,"startLine":1,"startColumn":32},"message":"The class 'C' can't be used as a mixin because it references 'super'.","correction":"","code":"mixin_references_super","hasFix":false}
    //  ]
    return super.test_super_mixins_enabled();
  }
}
