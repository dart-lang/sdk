// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

class SortCombinators extends ResolvedCorrectionProducer {
  SortCombinators({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.sortCombinators;

  @override
  FixKind get multiFixKind => DartFixKind.sortCombinatorsMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;

    NodeList<SimpleIdentifier> names;
    if (node is ShowCombinator) {
      names = node.shownNames;
    } else if (node is HideCombinator) {
      names = node.hiddenNames;
    } else {
      return;
    }

    var sorted = names.map((e) => e.name).sorted();

    await builder.addDartFileEdit(file, (builder) {
      for (var i = 0; i < names.length; i++) {
        builder.addSimpleReplacement(range.node(names[i]), sorted[i]);
      }
    });
  }
}
