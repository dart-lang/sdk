// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class CreateFunction extends ResolvedCorrectionProducer {
  String _functionName = '';

  CreateFunction({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_functionName];

  @override
  FixKind get fixKind => DartFixKind.createFunction;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // should be the name of the invocation
    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
    } else {
      return;
    }
    _functionName = (node as SimpleIdentifier).name;
    var invocation = node.parent as MethodInvocation;
    // function invocation has no target
    var target = invocation.realTarget;
    if (target != null) {
      return;
    }

    // prepare environment
    var enclosingMember = node.thisOrAncestorOfType<CompilationUnitMember>();
    if (enclosingMember == null) {
      return;
    }
    var returnType = inferUndefinedExpressionType(invocation);
    if (returnType is InvalidType) {
      return;
    }
    // Build method source.
    await builder.addDartFileEdit(file, (builder) {
      var eol = builder.eol;
      var sourcePrefix = '$eol$eol';
      builder.addInsertion(enclosingMember.end, (builder) {
        builder.write(sourcePrefix);
        builder.writeFunctionDeclaration(
          _functionName,
          nameGroupName: 'NAME',
          returnType: returnType,
          returnTypeGroupName: 'RETURN_TYPE',
          parameterWriter: () =>
              builder.writeParametersMatchingArguments(invocation.argumentList),
          bodyWriter: () => builder.write('{$eol}'),
        );
      });
    });
  }
}
