// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToOnType extends ResolvedCorrectionProducer {
  @override
  final List<String> fixArguments = [];

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_ON_TYPE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var exceptionParameter = node;
    if (exceptionParameter is CatchClauseParameter) {
      var catchClause = exceptionParameter.parent;
      if (catchClause is CatchClause) {
        var catchKeyword = catchClause.catchKeyword;
        var rightParenthesis = catchClause.rightParenthesis;
        if (catchKeyword != null &&
            catchClause.exceptionType == null &&
            catchClause.exceptionParameter == exceptionParameter &&
            rightParenthesis != null) {
          var exceptionTypeName = exceptionParameter.name;
          fixArguments.add(exceptionTypeName.toString());
          await builder.addDartFileEdit(file, (builder) {
            var stackTraceParameter = catchClause.stackTraceParameter;
            if (stackTraceParameter != null) {
              builder.addSimpleReplacement(
                range.startStart(catchKeyword, stackTraceParameter),
                'on $exceptionTypeName catch (_, ',
              );
            } else {
              builder.addSimpleReplacement(
                range.startEnd(catchKeyword, rightParenthesis),
                'on $exceptionTypeName',
              );
            }
          });
        }
      }
    }
  }
}
