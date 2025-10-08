// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceWithUnicodeEscape extends ResolvedCorrectionProducer {
  ReplaceWithUnicodeEscape({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // Not predictably the correct action.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.replaceWithUnicodeEscape;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var problemMessage = diagnostic?.problemMessage;
    if (problemMessage == null) return;

    var offset = problemMessage.offset;
    var content = unitResult.content;
    var codeUnit = content.codeUnitAt(offset);
    var code = codeUnit.toRadixString(16).toUpperCase();
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.startOffsetEndOffset(offset, offset + 1),
        '\\u$code',
      );
    });
  }
}
