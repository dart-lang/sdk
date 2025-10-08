// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class RemoveVarKeyword extends ResolvedCorrectionProducer {
  RemoveVarKeyword({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.removeVarKeyword;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = coveringNode;
    if (node is DeclaredVariablePattern) {
      var keyword = node.keyword;
      if (keyword != null) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(SourceRange(keyword.offset, keyword.length + 1));
        });
      }
    }
  }
}
