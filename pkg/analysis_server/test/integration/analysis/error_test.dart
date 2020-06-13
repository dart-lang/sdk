// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisErrorIntegrationTest);
  });
}

@reflectiveTest
class AnalysisErrorIntegrationTest
    extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_analysisRootDoesNotExist() async {
    var packagePath = sourcePath('package');
    var filePath = sourcePath('package/lib/test.dart');
    var content = '''
main() {
  print(null) // parse error: missing ';'
}''';
    await sendServerSetSubscriptions([ServerService.STATUS]);
    await sendAnalysisUpdateContent({filePath: AddContentOverlay(content)});
    await sendAnalysisSetAnalysisRoots([packagePath], []);
    await analysisFinished;

    expect(currentAnalysisErrors[filePath], isList);
    var errors = currentAnalysisErrors[filePath];
    expect(errors, hasLength(1));
    expect(errors[0].location.file, equals(filePath));
  }

  Future<void> test_detect_simple_error() {
    var pathname = sourcePath('test.dart');
    writeFile(pathname, '''
main() {
  print(null) // parse error: missing ';'
}''');
    standardAnalysisSetup();
    return analysisFinished.then((_) {
      expect(currentAnalysisErrors[pathname], isList);
      var errors = currentAnalysisErrors[pathname];
      expect(errors, hasLength(1));
      expect(errors[0].location.file, equals(pathname));
    });
  }

  @failingTest
  Future<void> test_super_mixins_enabled() async {
    // We see errors here with the new driver (#28870).
    //  Expected: empty
    //    Actual: [
    //    AnalysisError:{"severity":"ERROR","type":"COMPILE_TIME_ERROR","location":{"file":"/var/folders/00/0w95r000h01000cxqpysvccm003j4q/T/analysisServerfbuOQb/test.dart","offset":31,"length":1,"startLine":1,"startColumn":32},"message":"The class 'C' can't be used as a mixin because it extends a class other than Object.","correction":"","code":"mixin_inherits_from_not_object","hasFix":false},
    //    AnalysisError:{"severity":"ERROR","type":"COMPILE_TIME_ERROR","location":{"file":"/var/folders/00/0w95r000h01000cxqpysvccm003j4q/T/analysisServerfbuOQb/test.dart","offset":31,"length":1,"startLine":1,"startColumn":32},"message":"The class 'C' can't be used as a mixin because it references 'super'.","correction":"","code":"mixin_references_super","hasFix":false}
    //  ]

    var pathname = sourcePath('test.dart');
    writeFile(pathname, '''
class Test extends Object with C {
  void foo() {}
}
abstract class B {
  void foo() {}
}
abstract class C extends B {
  void bar() {
    super.foo();
  }
}
''');
    // ignore: deprecated_member_use_from_same_package
    await sendAnalysisUpdateOptions(
        AnalysisOptions()..enableSuperMixins = true);
    standardAnalysisSetup();
    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isList);
    var errors = currentAnalysisErrors[pathname];
    expect(errors, isEmpty);
  }
}
