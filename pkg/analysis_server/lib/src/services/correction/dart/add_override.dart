// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AddOverride extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.ADD_OVERRIDE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var member = node.thisOrAncestorOfType<ClassMember>();
    if (member == null) {
      return;
    }

    //TODO(pq): migrate annotation edit building to change_builder

    // Handle doc comments.
    var token = member.beginToken;
    if (token is CommentToken) {
      token = (token as CommentToken).parent;
    }

    var exitPosition = Position(file, token.offset - 1);
    var indent = utils.getIndent(1);
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
          range.startLength(token, 0), '@override$eol$indent');
    });
    builder.setSelection(exitPosition);
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static AddOverride newInstance() => AddOverride();
}
