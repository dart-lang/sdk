// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveDeprecatedNewInCommentReference extends ResolvedCorrectionProducer {
  RemoveDeprecatedNewInCommentReference({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_DEPRECATED_NEW_IN_COMMENT_REFERENCE;

  @override
  FixKind get multiFixKind =>
      DartFixKind.REMOVE_DEPRECATED_NEW_IN_COMMENT_REFERENCE_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var comment = node;
    if (comment is! CommentReference) {
      return;
    }

    var newToken = comment.newKeyword;
    if (newToken == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.startStart(newToken, newToken.next!));
    });

    var identifier = comment.expression;
    if (identifier is Identifier) {
      var element = identifier.element;
      if (identifier is SimpleIdentifier && element is ConstructorElement2) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleInsertion(identifier.end, '.new');
        });
      } else {
        if (element is ClassElement2) {
          if (element.unnamedConstructor2 != null) {
            await builder.addDartFileEdit(file, (builder) {
              builder.addSimpleInsertion(identifier.end, '.new');
            });
          }
        }
      }
    }
  }
}
