// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddEolAtEndOfFile extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.ADD_EOL_AT_END_OF_FILE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var content = unitResult.content;
    if (!content.endsWith(eol)) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(content.length, eol);
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
            SourceRange(index, content.length - index), eol);
      });
    }
  }
}
