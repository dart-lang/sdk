// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/object.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class InsertOnKeyword extends ResolvedCorrectionProducer {
  InsertOnKeyword({required super.context});

  @override
  CorrectionApplicability get applicability =>
          // Supports single instance and in file corrections
          CorrectionApplicability
          .acrossSingleFile;

  @override
  FixKind get fixKind => DartFixKind.INSERT_ON_KEYWORD;

  @override
  FixKind get multiFixKind => DartFixKind.INSERT_ON_KEYWORD_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var extension =
        node.ifTypeOrNull<ExtensionDeclaration>() ??
        node.parent.ifTypeOrNull<ExtensionDeclaration>();
    if (extension == null) {
      return;
    }

    var onClause = extension.onClause;
    if (onClause == null) {
      return;
    }

    var name = extension.name;
    var onKeyword = onClause.onKeyword;
    var extendedType = onClause.extendedType;

    // We don't expect this.
    if (name == null || name.isSynthetic) {
      return;
    }

    // Otherwise this is not our error to fix.
    if (!onKeyword.isSynthetic) {
      return;
    }

    // `extension int {}`
    // `extension E int {}`
    var insertOffset =
        extendedType.isSynthetic ? name.offset : extendedType.offset;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(insertOffset, 'on ');
    });
  }
}
