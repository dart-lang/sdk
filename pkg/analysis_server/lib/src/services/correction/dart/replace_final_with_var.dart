// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceFinalWithVar extends ResolvedCorrectionProducer {
  /// A flag indicating that a type is specified and `final` should be
  /// removed rather than replaced.
  final bool _removeFinal;

  final Token? _finalKeyword;

  final bool _canBeBulkApplied;

  factory ReplaceFinalWithVar({required CorrectionProducerContext context}) {
    if (context is StubCorrectionProducerContext) {
      return ReplaceFinalWithVar._(
        context: context,
        finalKeyword: null,
        removeFinal: false,
        canBeBulkApplied: true,
      );
    }

    var (finalKeyword, removeFinal, canBeBulkApplied) = switch (context.node) {
      VariableDeclarationList node => (node.keyword, node.type != null, true),
      PatternVariableDeclaration node => (node.keyword, false, true),
      DeclaredIdentifier node => (node.keyword, node.type != null, true),
      DeclaredVariablePattern node => (node.keyword, node.type != null, true),
      ForEachPartsWithPattern node => (node.keyword, false, true),
      SimpleFormalParameter node => (node.keyword, node.type != null, false),
      _ => (null, true, false),
    };

    return ReplaceFinalWithVar._(
      context: context,
      finalKeyword: finalKeyword,
      removeFinal: removeFinal,
      canBeBulkApplied: canBeBulkApplied,
    );
  }

  ReplaceFinalWithVar._({
    required super.context,
    required this._finalKeyword,
    required this._removeFinal,
    required this._canBeBulkApplied,
  });

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => _removeFinal
      ? DartFixKind.removeUnnecessaryFinal
      : DartFixKind.replaceFinalWithVar;

  @override
  FixKind? get multiFixKind => _canBeBulkApplied
      ? _removeFinal
            ? DartFixKind.removeUnnecessaryFinalMulti
            : DartFixKind.replaceFinalWithVarMulti
      : null;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (applyingBulkFixes && !_canBeBulkApplied) return;
    if (_finalKeyword case var finalKeyword?) {
      assert(finalKeyword.keyword == Keyword.FINAL);
      if (_removeFinal) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(
            range.startStart(finalKeyword, finalKeyword.next!),
          );
        });
      } else {
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleReplacement(range.token(finalKeyword), 'var');
        });
      }
    }
  }
}
