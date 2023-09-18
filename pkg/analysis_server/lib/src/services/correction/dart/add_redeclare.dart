// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddRedeclare extends ResolvedCorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.ADD_REDECLARE;

  @override
  FixKind get multiFixKind => DartFixKind.ADD_REDECLARE_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var member = node.thisOrAncestorOfType<ClassMember>();
    if (member == null) return;

    var token = member.firstTokenAfterCommentAndMetadata;
    var indent = utils.getIndent(1);
    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(token.offset, (builder) {
        builder.write('@');
        builder.writeImportedName(
            [Uri.parse('package:meta/meta.dart')], 'redeclare');
        builder.write('$eol$indent');
      });
    });
  }
}
