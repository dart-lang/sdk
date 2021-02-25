// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddRequiredKeyword extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.ADD_REQUIRED2;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      var insertOffset = node.parent.offset;

      var parent = node.parent;
      if (parent is FormalParameter) {
        var metadata = parent.metadata;
        // Check for redundant `@required` annotations.
        if (metadata.isNotEmpty) {
          for (var annotation in metadata) {
            if (annotation.elementAnnotation.isRequired) {
              var length = annotation.endToken.next.offset -
                  annotation.beginToken.offset;
              builder.addDeletion(SourceRange(annotation.offset, length));
              break;
            }
          }
          insertOffset = metadata.endToken.next.offset;
        }
      }
      builder.addSimpleInsertion(insertOffset, 'required ');
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static AddRequiredKeyword newInstance() => AddRequiredKeyword();
}
