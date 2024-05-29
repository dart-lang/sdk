// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveConst extends _RemoveConst {
  @override
  CorrectionApplicability get applicability =>
      // Not predictably the correct action.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_CONST;
}

class RemoveUnnecessaryConst extends _RemoveConst {
  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNNECESSARY_CONST;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_UNNECESSARY_CONST_MULTI;
}

abstract class _RemoveConst extends ParsedCorrectionProducer {
  @override
  Future<void> compute(ChangeBuilder builder) async {
    var expression = node;

    Token? constToken;
    if (expression is InstanceCreationExpression) {
      constToken = expression.keyword;
    } else if (expression is TypedLiteral) {
      constToken = expression.constKeyword;
    } else if (expression is CompilationUnit) {
      await _deleteRangeFromError(builder);
      return;
    } else if (expression is ClassDeclaration) {
      constToken = expression.firstTokenAfterCommentAndMetadata.previous;
    } else if (expression is ConstructorDeclaration) {
      constToken = expression.constKeyword;
    }

    // Might be an implicit `const`.
    if (constToken == null) return;

    var constToken_final = constToken;
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(
        range.startStart(
          constToken_final,
          constToken_final.next!,
        ),
      );
    });
  }

  Future<void> _deleteRangeFromError(ChangeBuilder builder) async {
    // In the case of a `const class` declaration, the `const` keyword is
    // not part of the class so we have to use the diagnostic offset.
    var diagnostic = this.diagnostic;
    if (diagnostic is! AnalysisError) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(
          // TODO(pq): consider ensuring that any extra whitespace is removed.
          SourceRange(diagnostic.offset, diagnostic.length + 1));
    });
  }
}
