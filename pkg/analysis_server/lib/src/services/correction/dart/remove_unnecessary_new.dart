// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveNew extends _RemoveNew {
  @override
  FixKind get fixKind => DartFixKind.REMOVE_NEW;
}

class RemoveUnnecessaryNew extends _RemoveNew {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNNECESSARY_NEW;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_UNNECESSARY_NEW_MULTI;
}

class _RemoveNew extends ParsedCorrectionProducer {
  @override
  Future<void> compute(ChangeBuilder builder) async {
    final creation = node;
    if (creation is! InstanceCreationExpression) {
      return;
    }

    final newToken = creation.keyword;
    if (newToken == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.startStart(newToken, newToken.next!));
    });
  }
}
