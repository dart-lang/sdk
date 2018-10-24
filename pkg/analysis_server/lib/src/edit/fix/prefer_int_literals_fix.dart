// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/src/edit/edit_dartfix.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';

class PreferIntLiteralsFix extends LinterFix {
  final literalsToConvert = <DoubleLiteral>[];

  PreferIntLiteralsFix(EditDartFix dartFix) : super(dartFix);

  @override
  Future<void> applyLocalFixes(AnalysisResult result) async {
    while (literalsToConvert.isNotEmpty) {
      DoubleLiteral literal = literalsToConvert.removeLast();
      AssistProcessor processor = new AssistProcessor(
          new EditDartFixAssistContext(dartFix, source, result.unit, literal));
      List<Assist> assists =
          await processor.computeAssist(DartAssistKind.CONVERT_TO_INT_LITERAL);
      final location = dartFix.locationDescription(result, literal.offset);
      if (assists.isNotEmpty) {
        for (Assist assist in assists) {
          dartFix.addFix(
              'Replace a double literal with an int literal in $location',
              assist.change);
        }
      } else {
        // TODO(danrubel): If assists is empty, then determine why
        // assist could not be performed and report that in the description.
        dartFix.addRecommendation('Could not replace'
            ' a double literal with an int literal in $location');
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
