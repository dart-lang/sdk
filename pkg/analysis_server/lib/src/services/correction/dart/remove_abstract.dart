// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class RemoveAbstract extends CorrectionProducerWithDiagnostic {
  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_ABSTRACT;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_ABSTRACT_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // 'abstract' keyword does not exist in AST
    var offset = diagnostic.problemMessage.offset;
    var content = resolvedResult.content;
    var i = offset + 'abstract '.length;
    while (content[i].trim().isEmpty) {
      i++;
    }
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(SourceRange(offset, i - offset));
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveAbstract newInstance() => RemoveAbstract();
}
