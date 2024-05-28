// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class RemoveUnnecessaryRawString extends ResolvedCorrectionProducer {
  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNNECESSARY_RAW_STRING;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_UNNECESSARY_RAW_STRING_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var offset = diagnostic?.problemMessage.offset;
    if (offset == null) {
      return;
    }
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(SourceRange(offset, 1));
    });
  }
}
