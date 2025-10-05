// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/src/utilities/extensions/string_extension.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddEolAtEndOfFile extends ResolvedCorrectionProducer {
  AddEolAtEndOfFile({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.addEolAtEndOfFile;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var content = unitResult.content;
    var eol = content.endOfLine;
    if (eol == null || !content.endsWith(eol)) {
      await builder.addDartFileEdit(file, (builder) {
        // Read the EOL off builder, because it is non-null and always has the
        // correct default, whereas the original variable could be null if the
        // file has no EOLs.
        builder.addSimpleInsertion(content.length, builder.eol);
      });
    } else {
      var index = content.length;
      while (index > 0) {
        var char = content[index - 1];
        if (char != '\r' && char != '\n') {
          break;
        }
        index--;
      }

      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          SourceRange(index, content.length - index),
          eol,
        );
      });
    }
  }
}
