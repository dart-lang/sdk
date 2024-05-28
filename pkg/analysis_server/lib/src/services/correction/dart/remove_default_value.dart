// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveDefaultValue extends ResolvedCorrectionProducer {
  @override
  CorrectionApplicability get applicability =>
      // Not predictably the correct action.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_DEFAULT_VALUE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var defaultFormalParameter =
        node.thisOrAncestorOfType<DefaultFormalParameter>();
    if (defaultFormalParameter is! DefaultFormalParameter) return;
    var separator = defaultFormalParameter.separator;
    if (separator == null) return;
    var defaultValue = defaultFormalParameter.defaultValue;
    if (defaultValue == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(
          range.endStart(separator.previous!, defaultValue.endToken.next!));
    });
  }
}
