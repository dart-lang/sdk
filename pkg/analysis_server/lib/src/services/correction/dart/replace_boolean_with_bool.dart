// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceBooleanWithBool extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => false;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REPLACE_BOOLEAN_WITH_BOOL;

  @override
  FixKind get multiFixKind => DartFixKind.REPLACE_BOOLEAN_WITH_BOOL_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final analysisError = diagnostic;
    if (analysisError is! AnalysisError) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.error(analysisError), 'bool');
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ReplaceBooleanWithBool newInstance() => ReplaceBooleanWithBool();
}
