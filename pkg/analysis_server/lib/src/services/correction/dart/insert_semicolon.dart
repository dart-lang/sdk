// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class InsertSemicolon extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.INSERT_SEMICOLON;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var message = diagnostic.problemMessage;
    if (message.message.contains("';'")) {
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

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static InsertSemicolon newInstance() => InsertSemicolon();
}
