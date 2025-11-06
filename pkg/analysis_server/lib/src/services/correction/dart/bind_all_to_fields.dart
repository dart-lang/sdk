// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/bind_to_field.dart'
    show BindToField;
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

import 'create_constructor.dart';

/// Binds a constructor parameter to a newly created field.
///
/// This assist is useful for simplifying constructor declarations by
/// automatically converting a regular parameter into a `this.` field formal
/// parameter and declaring the corresponding field. This matches a workflow
/// with the [CreateConstructor] assist.
class BindAllToFields extends ResolvedCorrectionProducer {
  BindAllToFields({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.bindAllToFields;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var parameterList = node.thisOrAncestorOfType<FormalParameterList>();
    if (parameterList != null) {
      for (var parameter in parameterList.parameters) {
        await BindToField.tryReplacingParameter(
          file,
          builder,
          parameter,
          libraryElement2,
        );
      }
    }
  }
}
