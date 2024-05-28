// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class InsertSemicolon extends ResolvedCorrectionProducer {
  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.INSERT_SEMICOLON;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var diagnostic = this.diagnostic;
    if (diagnostic == null) {
      return;
    }

    var message = diagnostic.problemMessage;
    if (message.messageText(includeUrl: false).contains("';'")) {
      if (_isAwaitNode()) {
        return;
      }
      var insertOffset = message.offset + message.length;
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(insertOffset, ';');
      });
    }
  }

  bool _isAwaitNode() {
    var node = this.node;
    return node is SimpleIdentifier && node.name == 'await';
  }
}
