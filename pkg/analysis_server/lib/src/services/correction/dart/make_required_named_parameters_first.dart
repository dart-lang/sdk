// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/range_factory.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class MakeRequiredNamedParametersFirst extends ResolvedCorrectionProducer {
  MakeRequiredNamedParametersFirst({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.makeRequiredNamedParametersFirst;

  @override
  FixKind? get multiFixKind =>
      DartFixKind.makeRequiredNamedParametersFirstMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var parent = node.parent;
    if (parent == null) return;
    var parameterList = parent.parent;
    if (parameterList is! FormalParameterList) return;

    int? firstOptionalParameter;
    var requiredParameterIndices = <int>[];

    var parameters = parameterList.parameters;
    for (var i = 0; i < parameters.length; i++) {
      var parameter = parameters[i];
      if (parameter.isNamed) {
        if (parameter.isOptional) {
          firstOptionalParameter ??= i;
        } else {
          if (firstOptionalParameter != null) {
            // compute changes for only the first required parameter
            if (parent == parameter && requiredParameterIndices.isNotEmpty) {
              return;
            }
            requiredParameterIndices.add(i);
          }
        }
      }
    }
    if (firstOptionalParameter == null) return;

    await builder.addDartFileEdit(file, (builder) {
      var firstParameter = parameters[firstOptionalParameter!];
      var firstComments = firstParameter.beginToken.precedingComments;
      var offset = firstComments?.offset ?? firstParameter.offset;
      var lineInfo = unitResult.lineInfo;
      builder.addInsertion(offset, (builder) {
        for (var index in requiredParameterIndices) {
          var nodeRange = range.nodeWithComments(lineInfo, parameters[index]);
          var text = utils.getRangeText(nodeRange);
          builder.write('$text, ');
        }
      });
      SourceRange? lastRange;
      for (var index in requiredParameterIndices) {
        var sourceRange = range.nodeInListWithComments(
          lineInfo,
          parameters,
          parameters[index],
        );
        if (sourceRange.offset >= (lastRange?.end ?? 0)) {
          builder.addDeletion(sourceRange);
        }
        lastRange = sourceRange;
      }
    });
  }
}
