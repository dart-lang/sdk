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

  factory ReplaceFinalWithVar({required CorrectionProducerContext context}) {
    if (context is StubCorrectionProducerContext) {
      return ReplaceFinalWithVar._(
        context: context,
        finalKeyword: null,
        removeFinal: false,
      );
    }

    var (finalKeyword, type) = switch (context.node) {
      VariableDeclarationList node => (node.keyword, node.type),
      PatternVariableDeclaration node => (node.keyword, null),
      DeclaredIdentifier node => (node.keyword, node.type),
      DeclaredVariablePattern node => (node.keyword, node.type),
      _ => (null, null),
    };

    return ReplaceFinalWithVar._(
      context: context,
      finalKeyword: finalKeyword,
      removeFinal: type != null,
    );
  }

  ReplaceFinalWithVar._({
    required super.context,
    required Token? finalKeyword,
    required bool removeFinal,
  }) : _finalKeyword = finalKeyword,
       _removeFinal = removeFinal;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => _removeFinal
      ? DartFixKind.removeUnnecessaryFinal
      : DartFixKind.replaceFinalWithVar;

  @override
  FixKind get multiFixKind => _removeFinal
      ? DartFixKind.removeUnnecessaryFinalMulti
      : DartFixKind.replaceFinalWithVarMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
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
