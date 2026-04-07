// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class CreateNoSuchMethod extends ResolvedCorrectionProducer {
  CreateNoSuchMethod({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.createNoSuchMethod;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var targetClass = node.parent;
    if (targetClass is! ClassDeclaration) {
      return;
    }

    var invocationType = (await sessionHelper.getClass(
      'dart:core',
      'Invocation',
    ))?.thisType;

    await builder.addDartFileEdit(file, (builder) {
      builder.insertIntoUnitMember(targetClass, (builder) {
        builder.selectHere();
        // append method
        builder.write('@override');
        builder.writeln();
        builder.write(utils.oneIndent);
        builder.writeFunctionDeclaration(
          'noSuchMethod',
          returnType: DynamicTypeImpl.instance,
          parameterWriter: () {
            builder.writeParameter('invocation', type: invocationType);
          },
          bodyWriter: () => builder.write('=> super.noSuchMethod(invocation);'),
        );
      });
    });
  }
}
