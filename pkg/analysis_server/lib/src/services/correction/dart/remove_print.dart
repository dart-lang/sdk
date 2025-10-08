// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Generates corrections that remove print expression statements, but
/// not other usages of print.
class RemovePrint extends ResolvedCorrectionProducer {
  RemovePrint({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind => DartFixKind.removePrint;

  @override
  List<String> get multiFixArguments => [];

  @override
  FixKind get multiFixKind => DartFixKind.removePrintMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var printInvocation = node.findSimplePrintInvocation();
    if (printInvocation != null) {
      await builder.addDartFileEdit(file, (builder) {
        var start = utils.getLineContentStart(printInvocation.offset);
        var end = utils.getLineContentEnd(printInvocation.end);
        var nextLine = utils.getLineNext(printInvocation.end);
        if (nextLine != end) {
          // Preserve indent if there is more on the line after the print.
          start = printInvocation.offset;
        } else if (start != utils.getLineThis(printInvocation.offset)) {
          // Preserve newline if there is more on the line before the print.
          end = end - utils.endOfLine.length;
        }
        builder.addDeletion(SourceRange(start, end - start));
      });
    }
  }
}
