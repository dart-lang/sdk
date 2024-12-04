// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/organize_imports.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class OrganizeImports extends ResolvedCorrectionProducer {
  OrganizeImports({required super.context});

  @override
  CorrectionApplicability get applicability =>
          // Bulk application is supported by a distinct import cleanup fix phase.
          CorrectionApplicability
          .singleLocation;

  @override
  FixKind get fixKind => DartFixKind.ORGANIZE_IMPORTS;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var organizer = ImportOrganizer(
      unitResult.content,
      unit,
      unitResult.errors,
    );
    // TODO(pq): consider restructuring organizer to allow a passed-in change
    //  builder
    for (var edit in organizer.organize()) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          SourceRange(edit.offset, edit.length),
          edit.replacement,
        );
      });
    }
  }
}
