// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnusedImport extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNUSED_IMPORT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // prepare ImportDirective
    var importDirective = node.thisOrAncestorOfType<ImportDirective>();
    if (importDirective == null) {
      return;
    }
    // remove the whole line with import
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(utils.getLinesRange(range.node(importDirective)));
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveUnusedImport newInstance() => RemoveUnusedImport();
}
