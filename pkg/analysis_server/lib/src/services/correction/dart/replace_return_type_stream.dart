// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceReturnTypeStream extends ResolvedCorrectionProducer {
  /// The text for the type argument to 'Stream'.
  String _typeArgument = '';

  ReplaceReturnTypeStream({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_typeArgument];

  @override
  FixKind get fixKind => DartFixKind.replaceReturnTypeStream;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // prepare the existing type
    var typeAnnotation = node.thisOrAncestorOfType<TypeAnnotation>();
    if (typeAnnotation == null) {
      return;
    }
    var type = typeAnnotation.type;
    if (type == null || type is DynamicType || type.isDartAsyncStream) {
      return;
    }
    _typeArgument = utils.getNodeText(typeAnnotation);

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(typeAnnotation), (builder) {
        builder.writeType(typeProvider.streamType(type));
      });
    });
  }
}
