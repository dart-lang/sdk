// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/organize_imports.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class OrganizeImports extends CorrectionProducer {
  @override
  // Bulk application is supported by a distinct import cleanup fix phase.
  bool get canBeAppliedInBulk => false;

  @override
  // The fix is to sort all the directives, which will already fix all of the
  // diagnostics in the file, so there's no value in providing a separate
  // fix-all option to the user.
  bool get canBeAppliedToFile => false;

  @override
  FixKind get fixKind => DartFixKind.ORGANIZE_IMPORTS;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var organizer =
        ImportOrganizer(unitResult.content, unit, unitResult.errors);
    // todo (pq): consider restructuring organizer to allow a passed-in change
    //  builder
    for (var edit in organizer.organize()) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(
            SourceRange(edit.offset, edit.length), edit.replacement);
      });
    }
  }
}
