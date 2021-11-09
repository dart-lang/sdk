// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveDeprecatedNewInCommentReference extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_DEPRECATED_NEW_IN_COMMENT_REFERENCE;

  @override
  FixKind get multiFixKind =>
      DartFixKind.REMOVE_DEPRECATED_NEW_IN_COMMENT_REFERENCE_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final comment = node;
    if (comment is! CommentReference) {
      return;
    }

    final newToken = comment.newKeyword;
    if (newToken == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.startStart(newToken, newToken.next!));
    });

    final identifier = comment.expression;
    if (identifier is Identifier) {
      final element = identifier.staticElement;
      if (identifier is SimpleIdentifier && element is ConstructorElement) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleInsertion(identifier.end, '.new');
        });
      } else {
        if (element is ClassElement) {
          if (element.unnamedConstructor != null) {
            await builder.addDartFileEdit(file, (builder) {
              builder.addSimpleInsertion(identifier.end, '.new');
            });
          }
        }
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveDeprecatedNewInCommentReference newInstance() =>
      RemoveDeprecatedNewInCommentReference();
}
