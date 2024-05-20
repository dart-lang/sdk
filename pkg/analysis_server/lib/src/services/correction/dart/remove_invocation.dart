// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveInvocation extends ResolvedCorrectionProducer {
  String _methodName = '';

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  List<String> get fixArguments => [_methodName];

  @override
  FixKind get fixKind => DartFixKind.REMOVE_INVOCATION;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_INVOCATION_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var id = node;
    if (id is! SimpleIdentifier) return;

    var invocation = id.parent;
    if (invocation is! MethodInvocation) return;

    _methodName = id.name;

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(
          range.startEnd(invocation.operator!, invocation.argumentList));
    });
  }
}
