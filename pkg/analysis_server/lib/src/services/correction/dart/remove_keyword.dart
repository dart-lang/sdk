// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveKeyword extends ResolvedCorrectionProducer {
  /// The keyword to remove.
  final Keyword _keyword;

  RemoveKeyword.awaitKeyword({required super.context})
    : _keyword = Keyword.AWAIT;

  RemoveKeyword.covariantKeyword({required super.context})
    : _keyword = Keyword.COVARIANT;

  RemoveKeyword.varKeyword({required super.context}) : _keyword = Keyword.VAR;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  List<String>? get fixArguments => [_keyword.lexeme];

  @override
  FixKind get fixKind => DartFixKind.removeKeyword;

  @override
  FixKind get multiFixKind => DartFixKind.removeKeywordMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    for (var entity in node.childEntities) {
      if (entity is Token && entity.keyword == _keyword) {
        await builder.addDartFileEdit(file, (builder) {
          var next = entity.next!;
          var comment = next.precedingComments;
          if (comment != null) {
            next = comment;
          }
          builder.addDeletion(range.startStart(entity, next));
        });
        return;
      }
    }
  }
}
