// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceFinalWithVar extends ResolvedCorrectionProducer {
  /// A flag indicating that a type is specified and `final` should be
  /// removed rather than replaced.
  bool _removeFinal = false;

  Token? _finalKeyword;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => _removeFinal
      ? DartFixKind.REMOVE_UNNECESSARY_FINAL
      : DartFixKind.REPLACE_FINAL_WITH_VAR;

  @override
  FixKind get multiFixKind => _removeFinal
      ? DartFixKind.REMOVE_UNNECESSARY_FINAL_MULTI
      : DartFixKind.REPLACE_FINAL_WITH_VAR_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (_finalKeyword case var finalKeyword?) {
      if (_removeFinal) {
        await builder.addDartFileEdit(file, (builder) {
          builder
              .addDeletion(range.startStart(finalKeyword, finalKeyword.next!));
        });
      } else {
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleReplacement(range.token(finalKeyword), 'var');
        });
      }
    }
  }

  @override
  void configure(CorrectionProducerContext<ResolvedUnitResult> context) {
    super.configure(context);

    // Ensure we have set `removeFinal` so that fixKind is accurate after
    // configure is completed.
    if (node
        case VariableDeclarationList(
          keyword: var keywordToken?,
          type: var type
        )) {
      if (type != null) {
        // If a type and keyword is present, the keyword is `final`.
        _finalKeyword = keywordToken;
        _removeFinal = true;
      } else if (keywordToken.keyword == Keyword.FINAL) {
        _finalKeyword = keywordToken;
      }
    } else if (node
        case PatternVariableDeclaration(keyword: var keywordToken)) {
      _finalKeyword = keywordToken;
    }
  }
}
