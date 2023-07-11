// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceFinalWithVar extends ResolvedCorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REPLACE_FINAL_WITH_VAR;

  @override
  FixKind get multiFixKind => DartFixKind.REPLACE_FINAL_WITH_VAR_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    Token? keyword;
    if (node is VariableDeclarationList) {
      if (node.type == null) keyword = node.keyword;
    } else if (node is PatternVariableDeclaration) {
      keyword = node.keyword;
    }

    if (keyword != null) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.token(keyword!), 'var');
      });
    }
  }
}
