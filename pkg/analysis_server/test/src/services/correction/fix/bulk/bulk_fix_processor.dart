// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';
import 'package:test/test.dart';

import '../../../../../abstract_single_unit.dart';
import '../../../../../utils/test_instrumentation_service.dart';

/// A base class defining support for writing bulk fix processor tests.
abstract class BulkFixProcessorTest extends AbstractSingleUnitTest {
  /// The source change associated with the fix that was found, or `null` if
  /// neither [assertHasFix] nor [assertHasFixAllFix] has been invoked.
  SourceChange change;

  /// The result of applying the [change] to the file content, or `null` if
  /// neither [assertHasFix] nor [assertHasFixAllFix] has been invoked.
  String resultCode;

  /// Return a list of the experiments that are to be enabled for tests in this
  /// class, or `null` if there are no experiments that should be enabled.
  List<String> get experiments => null;

  /// Return the lint code being tested.
  String get lintCode => null;

  /// The workspace in which fixes contributor operates.
  ChangeWorkspace get workspace {
    return DartChangeWorkspace([session]);
  }

  Future<void> assertHasFix(String expected) async {
    change = await _computeSourceChange();

    // apply to "file"
    var fileEdits = change.edits;
    expect(fileEdits, hasLength(1));

    var fileContent = testCode;
    resultCode = SourceEdit.applySequence(fileContent, change.edits[0].edits);
    expect(resultCode, expected);
  }

  Future<void> assertNoFix() async {
    change = await _computeSourceChange();
    var fileEdits = change.edits;
    expect(fileEdits, isEmpty);
  }

  /// Computes fixes for the specified [testUnit].
  Future<BulkFixProcessor> computeFixes() async {
    var tracker = DeclarationsTracker(MemoryByteStore(), resourceProvider);
    var analysisContext = contextFor(testFile);
    tracker.addContext(analysisContext);
    var processor = BulkFixProcessor(TestInstrumentationService(), workspace);
    await processor.fixErrors([analysisContext]);
    return processor;
  }

  @override
  void setUp() {
    super.setUp();
    verifyNoTestUnitErrors = false;
    _createAnalysisOptionsFile();
  }

  /// Returns the source change for computed fixes in the specified [testUnit].
  Future<SourceChange> _computeSourceChange() async {
    var processor = await computeFixes();
    return processor.builder.sourceChange;
  }

  /// Create the analysis options file needed in order to correctly analyze the
  /// test file.
  void _createAnalysisOptionsFile() {
    var code = lintCode;
    if (code == null) {
      createAnalysisOptionsFile(experiments: experiments);
    } else {
      createAnalysisOptionsFile(experiments: experiments, lints: [code]);
    }
  }
}
