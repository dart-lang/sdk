// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferenceFailureOnInstanceCreationTest);
  });
}

@reflectiveTest
class InferenceFailureOnInstanceCreationTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(experiments: experiments, strictInference: true),
    );
  }

  test_constructorNames_named() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:collection';
void f() {
  HashMap.from({1: 1, 2: 2, 3: 3});
//^^^^^^^^^^^^
// [diag.inferenceFailureOnInstanceCreation] The type argument(s) of the constructor 'HashMap.from' can't be inferred.
}
''');
  }

  test_constructorNames_named_importPrefix() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:collection' as c;
void f() {
  c.HashMap.from({1: 1, 2: 2, 3: 3});
//^^^^^^^^^^^^^^
// [diag.inferenceFailureOnInstanceCreation] The type argument(s) of the constructor 'c.HashMap.from' can't be inferred.
}
''');
  }

  test_constructorNames_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:collection';
void f() {
  HashMap();
//^^^^^^^
// [diag.inferenceFailureOnInstanceCreation] The type argument(s) of the constructor 'HashMap' can't be inferred.
}
''');
  }

  test_constructorNames_unnamed_importPrefix() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:collection' as c;
void f() {
  c.HashMap();
//^^^^^^^^^
// [diag.inferenceFailureOnInstanceCreation] The type argument(s) of the constructor 'c.HashMap' can't be inferred.
}
''');
  }

  test_explicitTypeArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:collection';
void f() {
  HashMap<int, int>();
}
''');
  }

  test_extensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E<T>(int i) {}
void f() {
  E(1);
//^
// [diag.inferenceFailureOnInstanceCreation] The type argument(s) of the constructor 'E' can't be inferred.
}
''');
  }

  test_genericMetadata_missingTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  const C();
}

@C()
// [diag.inferenceFailureOnInstanceCreation][column 1][length 4] The type argument(s) of the constructor 'C' can't be inferred.
void f() {}
''');
  }

  test_genericMetadata_missingTypeArg_withoutGenericMetadata() async {
    writeTestPackageConfig(PackageConfigFileBuilder(), languageVersion: '2.12');
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  const C();
}

@C()
void f() {}
''');
  }

  test_genericMetadata_upwardsInference() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  final T f;
  const C(this.f);
}

@C(7)
void g() {}
''');
  }

  test_genericMetadata_withTypeArg() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  const C();
}

@C<int>()
void f() {}
''');
  }

  test_missingTypeArgument_downwardInference() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:collection';
HashMap<int, int> f() {
  return HashMap();
}
''');
  }

  test_missingTypeArgument_interfaceTypeTypedef_noInference() async {
    // `typedef A = HashMap;` means `typedef A = HashMap<dynamic, dynamic>;`.
    // So, there is no inference failure on `new A();`.
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:collection';
typedef A = HashMap;
void f() {
  A();
}
''');
  }

  test_missingTypeArgument_noInference() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:collection';
void f() {
  HashMap();
//^^^^^^^
// [diag.inferenceFailureOnInstanceCreation] The type argument(s) of the constructor 'HashMap' can't be inferred.
}
''');
  }

  test_missingTypeArgument_noInference_optionalTypeArgs() async {
    writeTestPackageConfigWithMeta();
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@optionalTypeArgs
class C<T> {}
void f() {
  C();
}
''');
  }

  test_missingTypeArgument_noInference_topLevel() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:collection';
var m = HashMap();
//      ^^^^^^^
// [diag.inferenceFailureOnInstanceCreation] The type argument(s) of the constructor 'HashMap' can't be inferred.
''');
  }

  test_missingTypeArgument_upwardInference() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:collection';
void f() {
  HashMap.of({1: 1, 2: 2, 3: 3});
}
''');
  }
}
