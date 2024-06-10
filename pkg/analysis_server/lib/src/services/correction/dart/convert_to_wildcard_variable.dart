// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToWildcardVariable extends ResolvedCorrectionProducer {
  ConvertToWildcardVariable({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_WILDCARD_VARIABLE;

  bool get wildcardVariablesEnabled =>
      libraryElement.featureSet.isEnabled(Feature.wildcard_variables);

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (!wildcardVariablesEnabled) return;

    var node = this.node;
    if (node is! VariableDeclaration) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.token(node.name), '_');
    });
  }
}
