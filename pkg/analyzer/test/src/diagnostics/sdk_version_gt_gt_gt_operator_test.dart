// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkVersionGtGtGtOperatorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SdkVersionGtGtGtOperatorTest extends PubPackageResolutionTest {
  @override
  String get testPackageLanguageVersion =>
      '${ExperimentStatus.currentVersion.major}.'
      '${ExperimentStatus.currentVersion.minor}';

  test_const_equals() async {
    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.15.0'));
    await resolveTestCodeWithDiagnostics(r'''
const a = 42 >>> 3;
''');
  }

  test_const_lessThan() async {
    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.13.0'));
    await resolveTestCodeWithDiagnostics(r'''
const a = 42 >>> 3;
//           ^^^
// [diag.sdkVersionGtGtGtOperator] The operator '>>>' wasn't supported until version 2.14.0, but this code is required to be able to run on earlier versions.
''');
  }

  test_declaration_equals() async {
    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.15.0'));
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A operator >>>(A a) => this;
}
''');
  }

  test_declaration_lessThan() async {
    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.13.0'));
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A operator >>>(A a) => this;
//           ^^^
// [diag.sdkVersionGtGtGtOperator] The operator '>>>' wasn't supported until version 2.14.0, but this code is required to be able to run on earlier versions.
}
''');
  }

  test_nonConst_equals() async {
    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.15.0'));
    await resolveTestCodeWithDiagnostics(r'''
var a = 42 >>> 3;
''');
  }

  test_nonConst_lessThan() async {
    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.13.0'));
    await resolveTestCodeWithDiagnostics(r'''
var a = 42 >>> 3;
//         ^^^
// [diag.sdkVersionGtGtGtOperator] The operator '>>>' wasn't supported until version 2.14.0, but this code is required to be able to run on earlier versions.
''');
  }
}
