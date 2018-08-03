// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDriverTest_Kernel);
  });
}

/// Wrapper around the test package's `fail` function.
///
/// Unlike the test package's `fail` function, this function is not annotated
/// with @alwaysThrows, so we can call it at the top of a test method without
/// causing the rest of the method to be flagged as dead code.
void _fail(String message) {
  fail(message);
}

@reflectiveTest
class AnalysisDriverTest_Kernel extends AnalysisDriverTest {
  @override
  bool get useCFE => true;

  @override
  test_asyncChangesDuringAnalysis_getErrors() async {
    // TODO(brianwilkerson) Re-enable this test. It was disabled because it
    // appears to be flaky (possibly OS specific).
    //  Unexpected exceptions:
    //  Path: /test/lib/test.dart
    //  Exception: NoSuchMethodError: The getter 'iterator' was called on null.
    //  Receiver: null
    //  Tried calling: iterator
    //  #0      Object.noSuchMethod (dart:core-patch/dart:core/object_patch.dart:46)
    //  #1      _LibraryWalker.evaluateScc (package:front_end/src/incremental/file_state.dart:581:35)
    //  #2      _LibraryWalker.evaluate (package:front_end/src/incremental/file_state.dart:571:5)
    //  #3      DependencyWalker.walk.strongConnect (package:front_end/src/dependency_walker.dart:149:13)
    //  #4      DependencyWalker.walk (package:front_end/src/dependency_walker.dart:168:18)
    //  #5      FileState.topologicalOrder (package:front_end/src/incremental/file_state.dart:147:19)
    //  #6      KernelDriver.getKernelSequence.<anonymous closure>.<anonymous closure> (package:front_end/src/incremental/kernel_driver.dart:282:50)
    //  #7      PerformanceLog.run (package:front_end/src/base/performance_logger.dart:34:15)
    //  #8      KernelDriver.getKernelSequence.<anonymous closure> (package:front_end/src/incremental/kernel_driver.dart:281:43)
//    await super.test_asyncChangesDuringAnalysis_getErrors();
  }

  test_componentMetadata_incremental_merge() async {
    var a = _p('/a.dart');
    var b = _p('/b.dart');
    provider.newFile(a, r'''
class A {
  A.a();
}
''');
    provider.newFile(b, r'''
class B {
  B.b();
}
''');
    await driver.getResult(a);
    await driver.getResult(b);

    // This will fail if compilation of 'b' removed metadata for 'a'.
    // We use metadata to get constructor name offsets.
    await driver.getResult(a);

    // And check that 'b' still has its metadata as well.
    await driver.getResult(b);
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33719')
  test_errors_uriDoesNotExist_export() async {
    await super.test_errors_uriDoesNotExist_export();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33719')
  test_errors_uriDoesNotExist_import() async {
    await super.test_errors_uriDoesNotExist_import();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33719')
  test_errors_uriDoesNotExist_import_deferred() async {
    await super.test_errors_uriDoesNotExist_import_deferred();
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33719')
  test_errors_uriDoesNotExist_part() async {
    await super.test_errors_uriDoesNotExist_part();
  }

  @override
  test_externalSummaries() {
    // Skipped by design.
  }

  @override
  test_externalSummaries_partReuse() {
    // Skipped by design.
  }

  @override
  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/33719')
  test_getResult_doesNotExist() async {
    await super.test_getResult_doesNotExist();
  }

  @failingTest
  @override
  test_getResult_importLibrary_thenRemoveIt() async {
    await super.test_getResult_importLibrary_thenRemoveIt();
  }

  @failingTest
  @override
  test_getResult_invalid_annotation_functionAsConstructor() async {
    await super.test_getResult_invalid_annotation_functionAsConstructor();
  }

  @failingTest
  @override
  test_getResult_invalidUri() async {
    await super.test_getResult_invalidUri();
  }

  @failingTest
  @override
  test_getResult_invalidUri_exports_dart() async {
    await super.test_getResult_invalidUri_exports_dart();
  }

  @failingTest
  @override
  test_getResult_invalidUri_imports_dart() async {
    await super.test_getResult_invalidUri_imports_dart();
  }

  @failingTest
  @override
  test_getResult_invalidUri_metadata() async {
    await super.test_getResult_invalidUri_metadata();
  }

  @failingTest
  @override
  test_getResult_mix_fileAndPackageUris() async {
    await super.test_getResult_mix_fileAndPackageUris();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31409')
  @override
  test_getResult_nameConflict_local() async {
    await super.test_getResult_nameConflict_local();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/31409')
  @override
  test_getResult_nameConflict_local_typeInference() async {
    await super.test_getResult_nameConflict_local_typeInference();
  }

  @override
  @failingTest
  test_missingDartLibrary_async() {
    return super.test_missingDartLibrary_async();
  }

  @override
  @failingTest
  test_missingDartLibrary_core() {
    return super.test_missingDartLibrary_core();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30959')
  @override
  test_part_getResult_noLibrary() async {
    await super.test_part_getResult_noLibrary();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30959')
  @override
  test_part_getUnitElement_noLibrary() async {
    _fail('This test fails even with @failingTest');
    await super.test_part_getUnitElement_noLibrary();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30959')
  @override
  test_part_results_afterLibrary() async {
    await super.test_part_results_afterLibrary();
  }

  @failingTest
  @FastaProblem('https://github.com/dart-lang/sdk/issues/30959')
  @override
  test_part_results_noLibrary() async {
    await super.test_part_results_noLibrary();
  }

  @failingTest
  @override
  test_removeFile_invalidate_importers() async {
    await super.test_removeFile_invalidate_importers();
  }

  String _p(String path) => provider.convertPath(path);
}

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}
