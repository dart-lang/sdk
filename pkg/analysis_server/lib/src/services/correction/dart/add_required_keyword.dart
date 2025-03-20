// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddRequiredKeyword extends ResolvedCorrectionProducer {
  AddRequiredKeyword({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.ADD_REQUIRED;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      var parameter = node.parent;
      if (parameter is! FormalParameter) {
        return;
      }

      var insertOffset = parameter.offset;

      // Check for redundant `@required` annotations.
      var metadata = parameter.metadata;
      if (metadata.isNotEmpty) {
        for (var annotation in metadata) {
          if (annotation.elementAnnotation!.isRequired) {
            var length = annotation.endToken.next!.offset - annotation.offset;
            builder.addDeletion(SourceRange(annotation.offset, length));
            break;
          }
        }
        insertOffset = metadata.endToken!.next!.offset;
      }

      builder.addSimpleInsertion(insertOffset, 'required ');
    });
  }
}
