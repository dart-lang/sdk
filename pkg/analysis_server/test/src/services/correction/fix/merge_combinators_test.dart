// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MergeCombinatorsPriorityTest);
    defineReflectiveTests(MergeHideUsingHideTest);
    defineReflectiveTests(MergeHideUsingShowTest);
    defineReflectiveTests(MergeShowUsingHideTest);
    defineReflectiveTests(MergeShowUsingShowTest);
  });
}

@reflectiveTest
class MergeCombinatorsPriorityTest extends FixPriorityTest {
  Future<void> test_atLeastOneShow() async {
    await resolveTestCode('''
import 'other.dart' show Stream, Future hide Stream;
''');
    await assertFixPriorityOrder(
      [
        DartFixKind.mergeCombinatorsShowShow,
        DartFixKind.mergeCombinatorsHideShow,
      ],
      filter: (error) {
        return error.diagnosticCode == WarningCode.multipleCombinators;
      },
    );
  }

  Future<void> test_onlyHide() async {
    await resolveTestCode('''
import 'other.dart' hide Stream hide Future;
''');
    await assertFixPriorityOrder(
      [
        DartFixKind.mergeCombinatorsHideHide,
        DartFixKind.mergeCombinatorsShowHide,
      ],
      filter: (error) {
        return error.diagnosticCode == WarningCode.multipleCombinators;
      },
    );
  }
}

@reflectiveTest
class MergeHideUsingHideTest extends _MergeCombinatorTest {
  @override
  DiagnosticCode get diagnosticCode => WarningCode.multipleCombinators;

  @override
  FixKind get kind => DartFixKind.mergeCombinatorsHideHide;

  Future<void> test_export_hide_hide() async {
    await resolveTestCode('''
export 'other.dart' hide Stream, Future hide Future;
''');
    await assertHasFix('''
export 'other.dart' hide Stream, Future;
''');
  }

  Future<void> test_export_hide_hide_lint() async {
    createAnalysisOptionsFile(lints: [LintNames.combinators_ordering]);
    await resolveTestCode('''
export 'other.dart' hide Stream, Future hide Future;
''');
    await assertHasFix('''
export 'other.dart' hide Future, Stream;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_export_hide_show() async {
    await resolveTestCode('''
export 'other.dart' hide Future, Stream show FutureOr;
''');
    await assertNoFix();
  }

  Future<void> test_export_show_hide() async {
    await resolveTestCode('''
export 'other.dart' show FutureOr, Stream, Future hide Stream;
''');
    await assertNoFix();
  }

  Future<void> test_export_show_show() async {
    await resolveTestCode('''
export 'other.dart' show Stream, FutureOr, Future show Stream, FutureOr;
''');
    await assertNoFix();
  }

  Future<void> test_import_hide() async {
    await resolveTestCode('''
import 'other.dart' hide Future, Stream;
''');
    await assertNoFix();
  }

  Future<void> test_import_hide_hide() async {
    await resolveTestCode('''
import 'other.dart' hide Stream, Future hide Future;
''');
    await assertHasFix('''
import 'other.dart' hide Stream, Future;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_import_hide_hide_hide() async {
    await resolveTestCode('''
import 'other.dart' hide Stream hide Future hide FutureOr;
''');
    await assertHasFix('''
import 'other.dart' hide Stream, Future, FutureOr;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_import_hide_hide_lint() async {
    createAnalysisOptionsFile(lints: [LintNames.combinators_ordering]);
    await resolveTestCode('''
import 'other.dart' hide Stream, Future hide Future;
''');
    await assertHasFix('''
import 'other.dart' hide Future, Stream;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_import_hide_show() async {
    await resolveTestCode('''
import 'other.dart' hide Stream, Future show FutureOr, Completer;
''');
    await assertNoFix(filter: diagnosticCodeFilter);
  }

  Future<void> test_import_show() async {
    await resolveTestCode('''
import 'other.dart' show Future, Stream;
''');
    await assertNoFix();
  }

  Future<void> test_import_show_hide() async {
    await resolveTestCode('''
import 'other.dart' show FutureOr, Stream, Future hide Stream;
''');
    await assertNoFix(filter: diagnosticCodeFilter);
  }

  Future<void> test_import_show_show() async {
    await resolveTestCode('''
import 'other.dart' show Stream, FutureOr, Future show Stream, FutureOr;
''');
    await assertNoFix(filter: diagnosticCodeFilter);
  }
}

@reflectiveTest
class MergeHideUsingShowTest extends _MergeCombinatorTest {
  @override
  DiagnosticCode get diagnosticCode => WarningCode.multipleCombinators;

  @override
  FixKind get kind => DartFixKind.mergeCombinatorsShowHide;

  Future<void> test_export_hide_hide() async {
    await resolveTestCode('''
export 'other.dart' hide Stream, Future hide Future;
''');
    await assertHasFix('''
export 'other.dart' show Completer, FutureOr, Timer;
''');
  }

  Future<void> test_export_hide_hide_lint() async {
    createAnalysisOptionsFile(lints: [LintNames.combinators_ordering]);
    await resolveTestCode('''
export 'other.dart' hide Stream, Future hide Future;
''');
    await assertHasFix('''
export 'other.dart' show Completer, FutureOr, Timer;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_export_hide_show() async {
    await resolveTestCode('''
export 'other.dart' hide Stream, Future show FutureOr, Completer;
''');
    await assertNoFix();
  }

  Future<void> test_export_show_hide() async {
    await resolveTestCode('''
export 'other.dart' show FutureOr, Stream, Future hide Stream;
''');
    await assertNoFix();
  }

  Future<void> test_export_show_show() async {
    await resolveTestCode('''
export 'other.dart' show Stream, FutureOr, Future show Stream, FutureOr;
''');
    await assertNoFix();
  }

  Future<void> test_import_hide() async {
    await resolveTestCode('''
import 'other.dart' hide Future, Stream;
''');
    await assertNoFix();
  }

  Future<void> test_import_hide_hide() async {
    await resolveTestCode('''
import 'other.dart' hide Stream, Future hide Future;
''');
    await assertHasFix('''
import 'other.dart' show Completer, FutureOr, Timer;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_import_hide_hide_hide() async {
    await resolveTestCode('''
import 'other.dart' hide Stream hide Future hide FutureOr;
''');
    await assertHasFix('''
import 'other.dart' show Completer, Timer;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_import_hide_hide_lint() async {
    createAnalysisOptionsFile(lints: [LintNames.combinators_ordering]);
    await resolveTestCode('''
import 'other.dart' hide Stream, Future hide Future;
''');
    await assertHasFix('''
import 'other.dart' show Completer, FutureOr, Timer;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_import_hide_show() async {
    await resolveTestCode('''
import 'other.dart' hide Stream, Future show FutureOr, Completer;
''');
    await assertNoFix(filter: diagnosticCodeFilter);
  }

  Future<void> test_import_show() async {
    await resolveTestCode('''
import 'other.dart' show Future, Stream;
''');
    await assertNoFix();
  }

  Future<void> test_import_show_hide() async {
    await resolveTestCode('''
import 'other.dart' show FutureOr, Stream, Future hide Stream;
''');
    await assertNoFix(filter: diagnosticCodeFilter);
  }

  Future<void> test_import_show_show() async {
    await resolveTestCode('''
import 'other.dart' show Stream, FutureOr, Future show Stream, FutureOr;
''');
    await assertNoFix(filter: diagnosticCodeFilter);
  }
}

@reflectiveTest
class MergeShowUsingHideTest extends _MergeCombinatorTest {
  @override
  DiagnosticCode get diagnosticCode => WarningCode.multipleCombinators;

  @override
  FixKind get kind => DartFixKind.mergeCombinatorsHideShow;

  Future<void> test_export_hide_hide() async {
    await resolveTestCode('''
export 'other.dart' hide Stream, Future hide Future;
''');
    await assertNoFix();
  }

  Future<void> test_export_hide_show() async {
    await resolveTestCode('''
export 'other.dart' hide Stream, Future show FutureOr, Completer;
''');
    await assertHasFix('''
export 'other.dart' hide Stream, Future, Timer;
''');
  }

  Future<void> test_export_hide_show_lint() async {
    createAnalysisOptionsFile(lints: [LintNames.combinators_ordering]);
    await resolveTestCode('''
export 'other.dart' hide Stream, Future show FutureOr, Completer;
''');
    await assertHasFix('''
export 'other.dart' hide Future, Stream, Timer;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_export_show_hide() async {
    await resolveTestCode('''
export 'other.dart' show FutureOr, Stream, Future hide Stream;
''');
    await assertHasFix('''
export 'other.dart' hide Stream, Completer, Timer;
''');
  }

  Future<void> test_export_show_hide_lint() async {
    createAnalysisOptionsFile(lints: [LintNames.combinators_ordering]);
    await resolveTestCode('''
export 'other.dart' show FutureOr, Stream, Future hide Stream;
''');
    await assertHasFix('''
export 'other.dart' hide Completer, Stream, Timer;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_export_show_show() async {
    await resolveTestCode('''
export 'other.dart' show Stream, FutureOr, Future show Stream, FutureOr;
''');
    await assertHasFix('''
export 'other.dart' hide Completer, Future, Timer;
''');
  }

  Future<void> test_import_hide() async {
    await resolveTestCode('''
import 'other.dart' hide Future, Stream;
''');
    await assertNoFix();
  }

  Future<void> test_import_hide_hide() async {
    await resolveTestCode('''
import 'other.dart' hide Stream, Future hide Future;
''');
    await assertNoFix(filter: diagnosticCodeFilter);
  }

  Future<void> test_import_hide_show() async {
    await resolveTestCode('''
import 'other.dart' hide Stream, Future show FutureOr, Completer;
''');
    await assertHasFix('''
import 'other.dart' hide Stream, Future, Timer;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_import_hide_show_lint() async {
    createAnalysisOptionsFile(lints: [LintNames.combinators_ordering]);
    await resolveTestCode('''
import 'other.dart' hide Stream, Future show FutureOr, Completer;
''');
    await assertHasFix('''
import 'other.dart' hide Future, Stream, Timer;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_import_hide_show_show() async {
    await resolveTestCode('''
import 'other.dart' hide Future show Stream, FutureOr show FutureOr;
''');
    await assertHasFix('''
import 'other.dart' hide Future, Completer, Stream, Timer;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_import_show() async {
    await resolveTestCode('''
import 'other.dart' show Future, Stream;
''');
    await assertNoFix();
  }

  Future<void> test_import_show_hide() async {
    await resolveTestCode('''
import 'other.dart' show FutureOr, Stream, Future hide Stream;
''');
    await assertHasFix('''
import 'other.dart' hide Stream, Completer, Timer;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_import_show_hide_lint() async {
    createAnalysisOptionsFile(lints: [LintNames.combinators_ordering]);
    await resolveTestCode('''
import 'other.dart' show FutureOr, Stream, Future hide Stream;
''');
    await assertHasFix('''
import 'other.dart' hide Completer, Stream, Timer;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_import_show_show() async {
    await resolveTestCode('''
import 'other.dart' show Stream, FutureOr, Future show Stream, FutureOr;
''');
    await assertHasFix('''
import 'other.dart' hide Completer, Future, Timer;
''', filter: diagnosticCodeFilter);
  }
}

@reflectiveTest
class MergeShowUsingShowTest extends _MergeCombinatorTest {
  @override
  DiagnosticCode get diagnosticCode => WarningCode.multipleCombinators;

  @override
  FixKind get kind => DartFixKind.mergeCombinatorsShowShow;

  Future<void> test_export_hide_hide() async {
    await resolveTestCode('''
export 'other.dart' hide Stream, Future hide Future;
''');
    await assertNoFix();
  }

  Future<void> test_export_hide_show() async {
    await resolveTestCode('''
export 'other.dart' hide Stream, Future show FutureOr, Completer;
''');
    await assertHasFix('''
export 'other.dart' show FutureOr, Completer;
''');
  }

  Future<void> test_export_hide_show_lint() async {
    createAnalysisOptionsFile(lints: [LintNames.combinators_ordering]);
    await resolveTestCode('''
export 'other.dart' hide Stream, Future show FutureOr, Completer;
''');
    await assertHasFix('''
export 'other.dart' show Completer, FutureOr;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_export_show_hide() async {
    await resolveTestCode('''
export 'other.dart' show FutureOr, Stream, Future hide Stream;
''');
    await assertHasFix('''
export 'other.dart' show FutureOr, Future;
''');
  }

  Future<void> test_export_show_hide_lint() async {
    createAnalysisOptionsFile(lints: [LintNames.combinators_ordering]);
    await resolveTestCode('''
export 'other.dart' show FutureOr, Stream, Future hide Stream;
''');
    await assertHasFix('''
export 'other.dart' show Future, FutureOr;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_export_show_show() async {
    await resolveTestCode('''
export 'other.dart' show Stream, FutureOr, Future show Stream, FutureOr;
''');
    await assertHasFix('''
export 'other.dart' show Stream, FutureOr;
''');
  }

  Future<void> test_export_show_show_lint() async {
    createAnalysisOptionsFile(lints: [LintNames.combinators_ordering]);
    await resolveTestCode('''
export 'other.dart' show Stream, FutureOr, Future show Stream, FutureOr;
''');
    await assertHasFix('''
export 'other.dart' show FutureOr, Stream;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_import_hide() async {
    await resolveTestCode('''
import 'other.dart' hide Future, Stream;
''');
    await assertNoFix();
  }

  Future<void> test_import_hide_hide() async {
    await resolveTestCode('''
import 'other.dart' hide Stream, Future hide Future;
''');
    await assertNoFix(filter: diagnosticCodeFilter);
  }

  Future<void> test_import_hide_show() async {
    await resolveTestCode('''
import 'other.dart' hide Stream, Future show FutureOr, Completer;
''');
    await assertHasFix('''
import 'other.dart' show FutureOr, Completer;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_import_hide_show_hide() async {
    await resolveTestCode('''
import 'other.dart' hide Stream show FutureOr, Completer, Timer hide Future;
''');
    await assertHasFix('''
import 'other.dart' show FutureOr, Completer, Timer;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_import_hide_show_lint() async {
    createAnalysisOptionsFile(lints: [LintNames.combinators_ordering]);
    await resolveTestCode('''
import 'other.dart' hide Stream, Future show FutureOr, Completer;
''');
    await assertHasFix('''
import 'other.dart' show Completer, FutureOr;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_import_show() async {
    await resolveTestCode('''
import 'other.dart' show Future, Stream;
''');
    await assertNoFix();
  }

  Future<void> test_import_show_hide() async {
    await resolveTestCode('''
import 'other.dart' show FutureOr, Stream, Future hide Stream;
''');
    await assertHasFix('''
import 'other.dart' show FutureOr, Future;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_import_show_hide_lint() async {
    createAnalysisOptionsFile(lints: [LintNames.combinators_ordering]);
    await resolveTestCode('''
import 'other.dart' show FutureOr, Stream, Future hide Stream;
''');
    await assertHasFix('''
import 'other.dart' show Future, FutureOr;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_import_show_show() async {
    await resolveTestCode('''
import 'other.dart' show Stream, FutureOr, Future show Stream, FutureOr;
''');
    await assertHasFix('''
import 'other.dart' show Stream, FutureOr;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_import_show_show_lint() async {
    createAnalysisOptionsFile(lints: [LintNames.combinators_ordering]);
    await resolveTestCode('''
import 'other.dart' show Stream, FutureOr, Future show Stream, FutureOr;
''');
    await assertHasFix('''
import 'other.dart' show FutureOr, Stream;
''', filter: diagnosticCodeFilter);
  }

  Future<void> test_import_show_show_show() async {
    await resolveTestCode('''
import 'other.dart' hide Stream show FutureOr, Completer, Timer hide Future;
''');
    await assertHasFix('''
import 'other.dart' show FutureOr, Completer, Timer;
''', filter: diagnosticCodeFilter);
  }
}

abstract class _MergeCombinatorTest extends FixProcessorErrorCodeTest
    with _MergeCombinatorTestMixin {}

mixin _MergeCombinatorTestMixin on FixProcessorErrorCodeTest {
  bool diagnosticCodeFilter(Diagnostic d) {
    return d.diagnosticCode == diagnosticCode;
  }

  @override
  void setUp() {
    super.setUp();
    newFile(join(testPackageLibPath, 'other.dart'), '''
class Completer {}
class Stream {}
class Future {}
class FutureOr {}
class Timer {}
''');
  }
}
