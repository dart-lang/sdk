// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDriverTest_Kernel);
    defineReflectiveTests(AnalysisDriverResolutionTest_Kernel);
  });
}

/// Tests marked with this annotations fail because we either have not triaged
/// them, or know that this is an analyzer problem.
const potentialAnalyzerProblem = const Object();

@reflectiveTest
class AnalysisDriverResolutionTest_Kernel extends AnalysisDriverResolutionTest {
  @override
  bool get previewDart2 => true;
}

@reflectiveTest
class AnalysisDriverTest_Kernel extends AnalysisDriverTest {
  @override
  bool get previewDart2 => true;

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_addFile_shouldRefresh() async {
    await super.test_addFile_shouldRefresh();
  }

//  @failingTest
//  @potentialAnalyzerProblem
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

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_changeFile_selfConsistent() async {
    await super.test_changeFile_selfConsistent();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_const_annotation_withArgs() async {
    await super.test_const_annotation_withArgs();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_const_circular_reference() async {
    await super.test_const_circular_reference();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_const_externalConstFactory() async {
    await super.test_const_externalConstFactory();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_const_implicitSuperConstructorInvocation() async {
    await super.test_const_implicitSuperConstructorInvocation();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_errors_uriDoesNotExist_export() async {
    await super.test_errors_uriDoesNotExist_export();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_errors_uriDoesNotExist_import() async {
    await super.test_errors_uriDoesNotExist_import();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_errors_uriDoesNotExist_import_deferred() async {
    await super.test_errors_uriDoesNotExist_import_deferred();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_errors_uriDoesNotExist_part() async {
    await super.test_errors_uriDoesNotExist_part();
  }

  @override
  test_externalSummaries() {
    // Skipped by design.
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getErrors() async {
    await super.test_getErrors();
  }

  @potentialAnalyzerProblem
  @override
  test_getIndex() async {
    // TODO(scheglov) This test fails even with @failingTest
//    await super.test_getIndex();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_constants_defaultParameterValue_localFunction() async {
    await super.test_getResult_constants_defaultParameterValue_localFunction();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_errors() async {
    await super.test_getResult_errors();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_genericFunctionType_parameter_named() async {
    await super.test_getResult_genericFunctionType_parameter_named();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_importLibrary_thenRemoveIt() async {
    await super.test_getResult_importLibrary_thenRemoveIt();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_invalid_annotation_functionAsConstructor() async {
    await super.test_getResult_invalid_annotation_functionAsConstructor();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_invalidUri() async {
    await super.test_getResult_invalidUri();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_invalidUri_exports_dart() async {
    await super.test_getResult_invalidUri_exports_dart();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_invalidUri_imports_dart() async {
    await super.test_getResult_invalidUri_imports_dart();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_invalidUri_metadata() async {
    await super.test_getResult_invalidUri_metadata();
  }

  @failingTest
  @potentialAnalyzerProblem
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

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_getResult_selfConsistent() async {
    await super.test_getResult_selfConsistent();
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
    fail('This test fails even with @failingTest');
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
  @potentialAnalyzerProblem
  @override
  test_removeFile_invalidate_importers() async {
    await super.test_removeFile_invalidate_importers();
  }

  @failingTest
  @potentialAnalyzerProblem
  @override
  test_results_order() async {
    await super.test_results_order();
  }
}

/// Tests marked with this annotation fail because of a Fasta problem.
class FastaProblem {
  const FastaProblem(String issueUri);
}
