// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveConstructorName extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_CONSTRUCTOR_NAME;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_CONSTRUCTOR_NAME_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final identifier = node;
    if (identifier is! SimpleIdentifier) return;

    // The '.' in ".new"
    var dotToken = identifier.token.previous!;
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.startStart(dotToken, identifier.token.next!));
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveConstructorName newInstance() => RemoveConstructorName();
}
