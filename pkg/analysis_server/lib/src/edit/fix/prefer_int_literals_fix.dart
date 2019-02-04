// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/src/edit/edit_dartfix.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';

class PreferIntLiteralsFix extends LinterFix {
  final literalsToConvert = <DoubleLiteral>[];

  PreferIntLiteralsFix(EditDartFix dartFix) : super(dartFix);

  @override
  Future<void> applyLocalFixes(ResolvedUnitResult result) async {
    while (literalsToConvert.isNotEmpty) {
      DoubleLiteral literal = literalsToConvert.removeLast();
      AssistProcessor processor = new AssistProcessor(
        new DartAssistContextImpl(
          DartChangeWorkspace(dartFix.server.currentSessions),
          result,
          literal.offset,
          0,
        ),
      );
      List<Assist> assists =
          await processor.computeAssist(DartAssistKind.CONVERT_TO_INT_LITERAL);
      final location =
          dartFix.locationFor(result, literal.offset, literal.length);
      if (assists.isNotEmpty) {
        for (Assist assist in assists) {
          dartFix.addSourceChange(
              'Replace a double literal with an int literal',
              location,
              assist.change);
        }
      } else {
        // TODO(danrubel): If assists is empty, then determine why
        // assist could not be performed and report that in the description.
        dartFix.addRecommendation(
            'Could not replace a double literal with an int literal', location);
      }
    }
  }

  @override
  Future<void> applyRemainingFixes() {
    // All fixes applied in [applyLocalFixes]
    return null;
  }

  @override
  void reportErrorForNode(ErrorCode errorCode, AstNode node,
      [List<Object> arguments]) {
    String filePath = source.fullName;
    if (filePath != null && dartFix.isIncluded(filePath)) {
      literalsToConvert.add(node);
    }
  }
}
